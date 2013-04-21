/*
  SPI controller simple test

  This demonstrates 3 modes of use of the ADXL325.

  Switch between them with pushbutton 1

  1st is tap detection to switch PWM patterns
  2nd is dumping the accelerometer sample to the LEDs
  3rd is dumping the orientation of the board to the LEDs

*/

#include "cpu-utils.h"
#include "board.h"
#include "simple-spi.h"
#include "gpio.h"

#define SHORT_BYTE_SWAP(x) (((x&0xff)<<8)|(x>>8))

const int SPI_MASTER = 2;
const int GPIO_CORE = 0;
#define  GPIO_ADXL345_INT_BIT_NUM 13
#define GPIO_ADXL345_INT_LINE (1<<GPIO_ADXL345_INT_BIT_NUM)
#define PUSHBUTTON_LINE_NUM 8
#define PUSHBUTTON_LINE ( 1 << PUSHBUTTON_LINE_NUM )

#define LED_LSB 0x01
#define LED_MSB 0x80

// LED style globals

static int LED_style = 0;

static int led_single_data = LED_LSB;

static int led_direction = 1; // 1 = LED to left, 0 LED to right

static int led_half_data = 0xaa;

static int led_full_data = 0xff;

static int led_random_data = LED_LSB;


unsigned char adxl345_read_reg(unsigned char addr)
{
  // Assert CS
  spi_core_slave_select(SPI_MASTER, 1);

  unsigned char cmd = 
    (1<<7) | // read
    (0<<6) | // multibyte = no
    (addr & 0x3f);

  // Write this byte out
  while (!spi_core_write_avail(SPI_MASTER));
  spi_core_write_data(SPI_MASTER, (char) cmd);
  while (!spi_core_data_avail(SPI_MASTER));
  report(spi_core_read_data(SPI_MASTER));

  // Write dummy byte
  spi_core_write_data(SPI_MASTER, 0);
  while (!spi_core_data_avail(SPI_MASTER));
  unsigned char data = spi_core_read_data(SPI_MASTER);

  // Deassert CS
  spi_core_slave_select(SPI_MASTER, 0);

  return data;
  
}

void adxl345_write_reg(unsigned char addr, unsigned char data)
{
  // Assert CS
  spi_core_slave_select(SPI_MASTER, 1);

  unsigned char cmd = 
    (0<<7) | // write
    (0<<6) | // multibyte = no
    (addr & 0x3f);

  // Write this byte out
  while (!spi_core_write_avail(SPI_MASTER));
  spi_core_write_data(SPI_MASTER, cmd);
  // Empty the read fifos
  while (!spi_core_data_avail(SPI_MASTER));
  spi_core_read_data(SPI_MASTER);


  while (!spi_core_write_avail(SPI_MASTER));
  spi_core_write_data(SPI_MASTER, data);
  // Empty the read fifos
  while (!spi_core_data_avail(SPI_MASTER));
  spi_core_read_data(SPI_MASTER);

  // Deassert CS
  spi_core_slave_select(SPI_MASTER, 0);
  
}

int adxl345_3wire_spi_init(void)
{

  // Deassert chip-select to the part while we configure
  spi_core_slave_select(SPI_MASTER, 0);

  // Init the SPI master block
  // Polarity,phase = 1,1
  // Divide the Wishbone clock by 64 to get 50/64 MHz SPI clock
  spi_core_clock_setup(SPI_MASTER, 1, 1, 1, 1);
  spi_core_enable(SPI_MASTER);

  // Drain FIFOs in case there's crap in them...
  while (spi_core_data_avail(SPI_MASTER))
    spi_core_read_data(SPI_MASTER);

  // Put the core into 3-bit SPI mode
  // Set bit 6 of the DATA_FORMAT register
  adxl345_write_reg(0x31, (1<<6));

  //Try reading the device ID
  if (adxl345_read_reg(0) == 0xe5)
    // Setup successful
    return 0;

  // Setup didn't work
  return 1;
}

// full_rese = 1 or 0; range = 0 to 3
void adxl345_enable_measure_mode(int full_res, int range)
{
  // Go into standby mode to configure
  adxl345_write_reg(0x2d, 0);

  // Set full resolution, +/-16g, 3-bit SPI
  adxl345_write_reg(0x31, (1<<6) | (full_res<<3) | (0x3));

  adxl345_write_reg(0x2d, (1<<3));
}

void adxl345_update_range(int range)
{
  adxl345_write_reg(0x31, (adxl345_read_reg(0x31)&0xfc) | range);
}

// Stream out the 3 16-bit samples (6, 8-bit registers)
void adxl345_read_xyz(short* buf)
{
  int i;
  char addr = 0x32;
  char * data = (char* ) buf;
  
  // Assert CS
  spi_core_slave_select(SPI_MASTER, 1);

  unsigned char cmd = 
    (1<<7) | // read
    (1<<6) | // multibyte = yes
    (addr & 0x3f);

  // Write this byte out
  while (!spi_core_write_avail(SPI_MASTER));
  spi_core_write_data(SPI_MASTER, (char) cmd);
  // Clear dummy data
  while (!spi_core_data_avail(SPI_MASTER));
  report(spi_core_read_data(SPI_MASTER));

  // Read out the 6 data sample bytes
  for (i=0;i<6;i++)
    {    
      // Write dummy byte
      spi_core_write_data(SPI_MASTER, 0);
      while (!spi_core_data_avail(SPI_MASTER));
      data[i] = spi_core_read_data(SPI_MASTER);
    }

  // Deassert CS
  spi_core_slave_select(SPI_MASTER, 0);

}

// Init our 8 LEDs
static void leds_init(void)
{
  
  gpio_init(GPIO_CORE);
  
  // Bottom half out, top half in
  set_gpio_direction(GPIO_CORE, 0x000000ff);
  
  gpio_write(GPIO_CORE, 0);

}

static void dump_byte(char data)
{
  gpio_write(GPIO_CORE, data);
}

static void set_LED(int LED_num)
{
  gpio_write(GPIO_CORE, (1<<LED_num));
}


static void continuous_dump_data_to_LEDs(void)
{
  short xyz_samples[3];

  short swapped_sample;
  char byte_sample;
  
  int scale = 2;
  
  //leds_init();

  //adxl345_update_range(3);

  //while (1)
  //{
      adxl345_read_xyz(xyz_samples);
      swapped_sample = SHORT_BYTE_SWAP (xyz_samples[0]);
      if (swapped_sample<0)
	swapped_sample *= -1;
      if (scale)
	byte_sample =  swapped_sample /=3;
      byte_sample = swapped_sample&0xff;
      dump_byte(byte_sample);
      //}
}


static int get_orientation(void)
{
  // Determine which direction the board is oriented
  short xyz_samples[3];

  short swapped_sample;
  
  short greatest_so_far = 0; // greatest reading
  int axis = 0; // 1 = x, 2 = y, 3 = z
  int was_negative;

  adxl345_read_xyz(xyz_samples);
  int i;
  for (i=0;i<3;i++)
    {
      swapped_sample = SHORT_BYTE_SWAP (xyz_samples[i]);
      was_negative = 0;
      if (swapped_sample < 0)
	{
	  swapped_sample *= -1;
	  was_negative = 1;
	}
      
      // Check which one is the greatest
      if (swapped_sample > greatest_so_far)
	{
	  greatest_so_far = swapped_sample;
	  axis = i+1;
	  if (was_negative)
	    axis *= -1;
	}
    }
  
  return axis;
  
}

static void dump_orientation_to_LEDS(void)
{
  //leds_init();

  //adxl345_enable_measure_mode(0);

  //while(1)
  //{
      int orientation = get_orientation();

      // Map the orientation onto LEDs
      // LEDs[5:0] = {-y,-y,-x,z,y,x}
      if (orientation < 0)
	orientation = (orientation * -1) + 2;
      else
	orientation -= 1;

      set_LED(orientation);

      //}
}

static volatile int mode = 0;

void pushbutton_interrupt(void)
{
  // Switch the mode
  mode++;
  if (mode==3)
    mode = 0;
}

void adxl345_double_tap_interrupt(void)
{
  // Have a double tap interrupt
  // Cycle the LED on/off style
  if (LED_style<3)
    {
      LED_style++;
    }
  else
    LED_style = 0;
}

void adxl345_interrupt(void)
{
  // Read the interrupt status register - this will clear the interrupt
  char int_source = adxl345_read_reg(0x30);
  
  if (int_source & (1<<5))
    {
      adxl345_double_tap_interrupt();
      adxl345_read_reg(0x30);
      adxl345_read_reg(0x30);
    }
}


void gpio_interrupt_handler(void* int_data)
{
  // Check what the interrupt was from
  unsigned int gpio_ints = gpio_get_ints(GPIO_CORE);
  if (gpio_ints & GPIO_ADXL345_INT_LINE)
    {
      // Interrupt from the accelerometer
      adxl345_interrupt();
  
      gpio_clear_ints(GPIO_CORE, GPIO_ADXL345_INT_BIT_NUM);
    }

  if (gpio_ints & PUSHBUTTON_LINE)
    {
      pushbutton_interrupt();
      gpio_clear_ints(GPIO_CORE, PUSHBUTTON_LINE_NUM);
    }

}


void configure_double_tap_interrupts(char thresh, char duration, char latency, char window)
{

  leds_init(); // This does basic GPIO interrupt configuration

  int_init();

  int_clear_all_pending();

  // Clear interrupts from device just incase they're still set
  adxl345_read_reg(0x30);
  adxl345_read_reg(0x30);
  adxl345_read_reg(0x30);

  gpio_clear_ints(GPIO_CORE, GPIO_ADXL345_INT_BIT_NUM);

  // Install interrupt handler
  int_add(GPIO0_IRQ, gpio_interrupt_handler, 0);

  // Enable this interrupt in PIC
  int_enable(GPIO0_IRQ);

  gpio_int_enable_line(GPIO_CORE, GPIO_ADXL345_INT_BIT_NUM, 1); // Rising edge triggered line

  gpio_enable_ints(GPIO_CORE);

  // Enable interrupts
  cpu_enable_user_interrupts();

  // Configure the double tap times
  adxl345_write_reg(0x1d, thresh);
  adxl345_write_reg(0x21, duration);
  adxl345_write_reg(0x22, latency);
  adxl345_write_reg(0x23, window);
  adxl345_write_reg(0x2a, 0x1); // enable Z-axis tap detection

  // Now configure the interrupt on the device
  // Read the interrupts register to clear it first
  adxl345_read_reg(0x30);
  // Write to INT_ENABLE and set d5 - double tap
  // Also, for debug, set the data ready flag
  adxl345_write_reg(0x2e, (1<<5));

}



static void leds_on(void)
{
  if (LED_style==0)
    gpio_write(GPIO_CORE, led_single_data);  
  else if (LED_style==1)
    gpio_write(GPIO_CORE, led_half_data);  
  else if (LED_style==2)
    gpio_write(GPIO_CORE, led_full_data);  
  else if (LED_style==3)
    gpio_write(GPIO_CORE, led_random_data);  

}

static void leds_off(void)
{
  gpio_write(GPIO_CORE, 0);  
}

static void led_direction_position_update(void)
{
  if (led_single_data==LED_MSB)
    led_direction = 0;
  else if (led_single_data==LED_LSB)
    led_direction = 1;
  
  if (led_direction)
    led_single_data <<= 1;
  else
    led_single_data >>= 1;

  // Also update the other style values
  led_half_data = ~led_half_data;

  led_full_data = ~led_full_data;

  led_random_data = (1<<(rand()&0x7));
  
}

static volatile int last_run_mode = -1;

void run_LED_patterns(void)
{

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

      if (mode==0)
	{

	  if (last_run_mode != mode)
	    {
	      adxl345_enable_measure_mode(1, 0x3);
	      last_run_mode = mode;
	    }

	  leds_off();

	  for (i=0;i<total_loops;i++)
	    if (i==on_boundary)
	      leds_on();

	  leds_off();

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
      else if (mode==1)
	{

	  if (last_run_mode != mode)
	    {
	      adxl345_enable_measure_mode(0, 0x1);
	      last_run_mode = mode;
	    }

	  continuous_dump_data_to_LEDs();

	}
      else if (mode==2)
	{
	  
	  if (last_run_mode != mode)
	    {
	      adxl345_enable_measure_mode(0, 0x0);
	      last_run_mode = mode;
	    }

	  dump_orientation_to_LEDS();
	}
    }
  
}


static void gpio_set_up_pushbutton_int(int core)
{
  // Assume general interrupt infrastructure already set up
  
  gpio_clear_ints(core, PUSHBUTTON_LINE_NUM);

  // Set falling edge triggered line on pushbutton
  gpio_int_enable_line(core, PUSHBUTTON_LINE_NUM, 0);

}


int main()
{
  int i;

  // Point to memory to store some data
  int* some_datas = (int*)0;
  
  some_datas[0] = adxl345_3wire_spi_init();
  some_datas[1] = adxl345_read_reg(0x2d);

  adxl345_enable_measure_mode(1, 0x3);
 
  // Loop here, update LEDs
  //continuous_dump_data_to_LEDs();
  //dump_orientation_to_LEDS();

  configure_double_tap_interrupts(0x30, 0x12, 0x62, 0x80);

  gpio_set_up_pushbutton_int(0);

  // Flash LEDs in fancy way, change if we get tap interrupt
  run_LED_patterns();

  exit(0);
  
}
