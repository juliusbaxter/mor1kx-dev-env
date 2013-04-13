
// This software demonstrates interrupt-enabled pushbutton trigger of LEDs

#include "cpu-utils.h"
#include "board.h"
#include "gpio.h"
//#include "printf.h"

volatile int int_fired = 0;

#define PUSHBUTTON_LINE_NUM 8
#define PUSHBUTTON_LINE ( 1 << PUSHBUTTON_LINE_NUM )

void gpio_pushbutton_int(void)
{
  gpio_clear_ints(0, PUSHBUTTON_LINE_NUM);

  if (!int_fired)
    {
      // Pushbutton been pressed down, put LED on
      int_fired = 1;
      gpio_write(0,0x01);
      // Set interrupt to trigger when it's released (rising edge)
      gpio_int_enable_line(0, PUSHBUTTON_LINE_NUM, 1); // Falling edge triggered line
    }
  else
    {
      // Pushbutton been pressed down, put LED on
      int_fired = 0;
      gpio_write(0,0x00);
      // Set interrupt to trigger when it's released (rising edge)
      gpio_int_enable_line(0, PUSHBUTTON_LINE_NUM, 0); // Falling edge triggered line

    }
}

static void gpio_set_up_pushbutton_int(int core)
{
  int_init();

  gpio_clear_ints(core, PUSHBUTTON_LINE_NUM);

  // Install interrupt handler
  int_add(GPIO0_IRQ, gpio_pushbutton_int, 0);

  // Enable this interrupt in PIC
  int_enable(GPIO0_IRQ);

  gpio_int_enable_line(core, PUSHBUTTON_LINE_NUM, 0); // Falling edge triggered line

  gpio_enable_ints(core);
  
  // Enable interrupts
  cpu_enable_user_interrupts();

}

int main()
{

  int core = 0;

  //printf("GPIO%d interrupt test\n", core);
  
  gpio_init(core);
  
  // Set outputs to zero
  gpio_write(core, 0);

  // Bottom half out, rest in
  set_gpio_direction(core, 0x000000ff);

  gpio_set_up_pushbutton_int(core);

  // Loop here - interrupts will turn LEDs on and off
  while(1);

  exit(0);

}
