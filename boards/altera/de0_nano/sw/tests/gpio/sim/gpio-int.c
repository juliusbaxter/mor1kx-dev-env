#include "cpu-utils.h"
#include "board.h"
#include "gpio.h"
#include "printf.h"

volatile int int_fired = 0;

#define PUSHBUTTON_LINE_NUM 8
#define PUSHBUTTON_LINE ( 1 << PUSHBUTTON_LINE_NUM )

static int led_data = PUSHBUTTON_LINE;

static void leds_on(int core)
{
  gpio_write(core, led_data);  
}

static void leds_off(int core)
{
  gpio_write(core, 0);  
}

void gpio_pushbutton_int(void)
{
 
  int_fired = 0x1;

  gpio_write(0,0x80);

  gpio_clear_ints(0, PUSHBUTTON_LINE_NUM);

  printf("Interrupt received\n");
  
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

  printf("GPIO%d interrupt test\n", core);
  
  gpio_init(core);
  
  // Set outputs to zero
  gpio_write(core, 0);

  // Bottom half out, rest in
  set_gpio_direction(core, 0x000000ff);

  gpio_set_up_pushbutton_int(core);

  // Now write 1 - this will come back on the pushbutton pin after a delay
  gpio_write(core, 1);

  int i=0, loop_limit = 30;
  
  while(1)
    {
      if (int_fired)
	{
	  report(0x8000000d);
	  break;
	}
      i++;
      if (i>=loop_limit)
	exit(1);
    }

  exit(0);

}
