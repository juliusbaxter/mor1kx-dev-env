/*
  SPI controller simple test

  Use interrupts from the ADXL345 to indicate things.

  In this case the GPIO line comes through the GPIO controller.

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

void adxl345_enable_measure_mode(int full_res)
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
  
  leds_init();

  adxl345_update_range(3);

  while (1)
    {
      adxl345_read_xyz(xyz_samples);
      swapped_sample = SHORT_BYTE_SWAP (xyz_samples[0]);
      if (swapped_sample<0)
	swapped_sample *= -1;
      if (scale)
	byte_sample =  swapped_sample /=3;
      byte_sample = swapped_sample&0xff;
      dump_byte(byte_sample);
    }
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
  leds_init();

  adxl345_enable_measure_mode(0);

  while(1)
    {
      int orientation = get_orientation();

      // Map the orientation onto LEDs
      // LEDs[5:0] = {-y,-y,-x,z,y,x}
      if (orientation < 0)
	orientation = (orientation * -1) + 2;
      else
	orientation -= 1;

      set_LED(orientation);

    }
}

int double_tap_status = 0;

void adxl345_double_tap_interrupt(void)
{
  // Have a double tap interrupt
  double_tap_status = ~double_tap_status;

  dump_byte(double_tap_status);
  
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
  set_LED(5);
  if (gpio_ints & GPIO_ADXL345_INT_LINE)
    {
      // Interrupt from the accelerometer
      adxl345_interrupt();
  
      gpio_clear_ints(GPIO_CORE, GPIO_ADXL345_INT_BIT_NUM);
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

int main()
{
  int i;

  // Point to memory to store some data
  int* some_datas = (int*)0;
  
  some_datas[0] = adxl345_3wire_spi_init();
  some_datas[1] = adxl345_read_reg(0x2d);

  adxl345_enable_measure_mode(1);

 
  // Loop here, update LEDs
  //continuous_dump_data_to_LEDs();
  //dump_orientation_to_LEDS();

  configure_double_tap_interrupts(0x30, 0x12, 0x62, 0x80);

  while(1)
    {
      // Do something
      some_datas[8] = some_datas[31] / some_datas[22];
    }



  exit(0);
  
}
