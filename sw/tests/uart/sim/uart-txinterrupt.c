/*
 * UART interrupt test
 *
 * Demonstrates UART TX interrupt
 *
 * Julius Baxter, juliusbaxter@gmail.com
 *
*/


#include "cpu-utils.h"
#include "spr-defs.h"
#include "board.h"
#include "uart.h"
#include "printf.h"
#include "int.h"


#define UART_TX_BUF_MAX 256
struct uart_tx_ctrl
{
  char buf[UART_TX_BUF_MAX]; /* 256byte buffer to print */
  int buf_count;
  int tx_count;
};

volatile struct uart_tx_ctrl uart0_tx_ctrl;


/* Reset buffer counter */
void uart0_tx_buffer_init(void)
{
  uart0_tx_ctrl.buf_count = 0;
  uart0_tx_ctrl.tx_count = 0;
}

/* Add characters to be transmitted */
void uart0_tx_buffer_add(int numchars, char* buf)
{
  // If we're not currently transmitting, ie. nothign in the buffer, then
  // we should transmit after this.
  int start_tx = (numchars && !uart0_tx_ctrl.buf_count);
  while(numchars)
    {
      /* Not good if this gets used outside of interrupt. */
      uart0_tx_ctrl.buf[uart0_tx_ctrl.buf_count%UART_TX_BUF_MAX] = *buf++;
      uart0_tx_ctrl.buf_count++;
      numchars--;
    }
  
  if (start_tx)
    {
      uart_txint_enable(0);
      uart_putc_noblock(0, uart0_tx_ctrl.buf[uart0_tx_ctrl.tx_count%UART_TX_BUF_MAX]);
      uart0_tx_ctrl.tx_count++;
    }
}


void uart_int_handler(void* corenum);

void uart_int_handler(void* corenum)
{

  int core = *((int*)corenum);

  if (core)report(core);
  
  char iir = uart_get_iir(core);

  if ( (iir & UART_IIR_RLSI)  == UART_IIR_RLSI)
    uart_get_lsr(core); // Should clear this interrupt
  else if ( (iir & UART_IIR_RDI) == UART_IIR_RDI )
    {
      // Was potentially also a timeout. Do we care?
      
      // Data received. Pull from the fifo and echo back.
      char rxchar;
      while (uart_check_for_char(core))
	{
	  
	  rxchar = uart_getc(core);
	  report(0xff & rxchar);
	  //printf("RX char: %c\n",rxchar);
	  uart0_tx_buffer_add(1, &rxchar);

	  if (rxchar == 0x2a) // Exit simulation when RX char is '*'
	    {
	      report(0x8000000d);
	      exit(0);
	    }
	}
    }
  else if ( (iir & UART_IIR_THRI) ==  UART_IIR_THRI)
    {
      // Only trigered if we've set something to be transmitted
      // and enabled the interrupt.
      // Put next thing to be transmitted into buffer, check if it's
      // the last, if so, disable interrupts.
      if (uart0_tx_ctrl.buf_count == uart0_tx_ctrl.tx_count)
	{
	  uart_txint_disable(core);
	  // Also exit test after finished transmitting
	  exit(0);
	  
	}
      else // Transmit this byte
	{
	  uart_putc_noblock(0, uart0_tx_ctrl.buf[uart0_tx_ctrl.tx_count%UART_TX_BUF_MAX]);
	  uart0_tx_ctrl.tx_count++;
	}
    }
  else if ( (iir & UART_IIR_MSI) == UART_IIR_MSI )
    {
      // Just read the modem status register to clear this
      uart_get_msr(core);
    }
}

int main()
{
  int uart0_core = 0;
  
  /* Set up user interrupt handler */
  int_init();

  /* Install UART core 0 interrupt handler */
  int_add(UART0_IRQ, uart_int_handler,(void*) &uart0_core);
  
  /* Enable interrupts in supervisor register */
  mtspr (SPR_SR, mfspr (SPR_SR) | SPR_SR_IEE);
  
  uart_init(uart0_core);
  
  uart0_tx_buffer_init();

  uart0_tx_buffer_add(40, "Hello World from UART using interrupts!\n");

  uart_txint_enable(uart0_core);

  while(1);

}
