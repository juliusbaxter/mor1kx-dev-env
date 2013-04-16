/*
  SPI controller simple test

  Talk to a ADXL345 accelerometer.

  Output some information to the LEDs.

*/


#include "cpu-utils.h"
#include "simple-spi.h"
#include "gpio.h"

#define SHORT_BYTE_SWAP(x) (((x&0xff)<<8)|(x>>8))

const int SPI_MASTER = 2;
const int GPIO_CORE = 0;

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

void adxl345_enable_measure_mode(void)
{
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

  adxl345_update_range(3);

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

static void dump_samples_to_mem(unsigned long mem_addr, int num_samples)
{
  int i;
  int* big_datas = (int*)mem_addr;
  short xyz_samples[3];
  
  for (i=0;i<num_samples;i++)
    {
      adxl345_read_xyz(xyz_samples);
      // Unpack the samples and dump them in memory
      big_datas[i*4+0] = SHORT_BYTE_SWAP (xyz_samples[0]);
      big_datas[i*4+1] = SHORT_BYTE_SWAP (xyz_samples[1]);
      big_datas[i*4+2] = SHORT_BYTE_SWAP (xyz_samples[2]);
      big_datas[i*4+3] = 0;
    }

}


int main()
{
  int i;

  // Point to memory to store some data
  int* some_datas = (int*)0;
  
  some_datas[0] = adxl345_3wire_spi_init();
  some_datas[1] = adxl345_read_reg(0x2d);

  adxl345_enable_measure_mode();

  dump_samples_to_mem(0x800000, 4096);

  // Loop here, update LEDs
  //continuous_dump_data_to_LEDs();
  dump_orientation_to_LEDS();

  exit(0);
  
}
