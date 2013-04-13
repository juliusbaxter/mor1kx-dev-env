#include "cpu-utils.h"
#include "board.h"
#include "gpio.h"
//#include "printf.h"


#define LED_LSB 0x01
#define LED_MSB 0x80

#define PUSHBUTTON_LINE_NUM 8
#define PUSHBUTTON_LINE ( 1 << PUSHBUTTON_LINE_NUM )

volatile int int_fired = 0;

static int led_data = LED_LSB;

static int led_direction = 1; // 1 = LED to left, 0 LED to right

static void leds_on(int core)
{
  gpio_write(core, led_data);  
}

static void leds_off(int core)
{
  gpio_write(core, 0);  
}

static void led_direction_position_update(void)
{
  if (led_data==LED_MSB)
    led_direction = 0;
  else if (led_data==LED_LSB)
    led_direction = 1;
  
  if (led_direction)
    led_data <<= 1;
  else
    led_data >>= 1;
  
}

void gpio_pushbutton_int(void)
{
  gpio_clear_ints(0, PUSHBUTTON_LINE_NUM);

  if (!int_fired)
    {
      // Pushbutton been pressed down, put LED on
      int_fired = 1;

      // do something - change LED direction
      led_direction_position_update();

      // Set interrupt to trigger when it's released (rising edge)
      gpio_int_enable_line(0, PUSHBUTTON_LINE_NUM, 1); // Falling edge triggered line
    }
  else
    {
      // Pushbutton been pressed down, put LED on
      int_fired = 0;

      // do something - change LED direction
      led_direction_position_update();

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

  //printf("GPIO%d test\n", core);
  
  gpio_init(core);

  // Bottom half out, top half in
  set_gpio_direction(core, 0x000000ff);

  gpio_set_up_pushbutton_int(core);

  // Write out some data
  gpio_write(core, 0);

  int i;
  const int total_loops = 1200;
  int current_step = 0; // begin at 0% on
  const int step_percent = 1;
  const int step_max = 800;
  const int step_min = 0;
  const int step_resolution = 1000;
  int brightness_direction = 1; // 1 = up (getting brighter), 0 = down
  int on_boundary = step_max; // start with LED cycle at lowest brightness
  const int longer_at_lower = 0;//15;
  const int longer_at_lower_thresh = 20;
  int longer_at_lower_loop = 0;

  int just_keep_off_threshold = 10; // Below this step level, just keep the LEDs off

  while (1)
    {
      leds_off(core);

      for (i=0;i<total_loops;i++)
	if (i==on_boundary)
	  leds_on(core);

      leds_off(core);

      // Calculate amount we'll be on for next time
      if (current_step<=step_min && brightness_direction==0)
	{
          brightness_direction = 1;

	  // When the LED has dimmed back down, switch the LED we're dimming
	  led_direction_position_update();

	}
      else if (current_step>=step_max && brightness_direction==1)
	brightness_direction = 0;

      // Additional time spent at a particular brightness
      if (longer_at_lower && (current_step <= longer_at_lower_thresh))
	{
	  if (longer_at_lower_loop < longer_at_lower)
	    longer_at_lower_loop++;
	  else
	    {
	      longer_at_lower_loop = 0;
	      
	      // Adjust the brightness step
	      if (brightness_direction)
		current_step += step_percent;
	      else
		current_step -= step_percent;
	    }
	}
      else
	{
	  if (brightness_direction)
	    current_step += step_percent;
	  else
	    current_step -= step_percent;
	}


      if (just_keep_off_threshold && current_step <=just_keep_off_threshold)
	on_boundary = total_loops; // should keep LED off
      else
	// Calculate next on boundary
	on_boundary = total_loops - ((total_loops/step_resolution)*current_step);

    }

  exit(0);

}
