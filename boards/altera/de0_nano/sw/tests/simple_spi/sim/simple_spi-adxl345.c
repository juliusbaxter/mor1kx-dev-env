/*
  SPI controller simple test

  Generate some transactions like we're talking to a 
  Analog Devices ADXL345 accelerometer.

*/


#include "cpu-utils.h"
#include "simple-spi.h"

const int SPI_MASTER = 2;


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

  // Now do another byte write, but really we'll read
  while (!spi_core_write_avail(SPI_MASTER));
  spi_core_write_data(SPI_MASTER, 0);

  while (!spi_core_data_avail(SPI_MASTER));
  report(spi_core_read_data(SPI_MASTER));

  while (!spi_core_data_avail(SPI_MASTER));
  report(spi_core_read_data(SPI_MASTER));

  // Deassert CS
  spi_core_slave_select(SPI_MASTER, 0);
  
}


unsigned char adxl345_write_reg(unsigned char addr, unsigned char data)
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

  // Now write the data
  while (!spi_core_write_avail(SPI_MASTER));
  spi_core_write_data(SPI_MASTER, data);

  while (!spi_core_data_avail(SPI_MASTER));
  spi_core_read_data(SPI_MASTER);

  while (!spi_core_data_avail(SPI_MASTER));
  spi_core_read_data(SPI_MASTER);

  // Deassert CS
  spi_core_slave_select(SPI_MASTER, 0);
  
}


int main()
{  
  // Init the masters
  
  spi_core_clock_setup(SPI_MASTER, 1, 1, 2, 1);
  spi_core_enable(SPI_MASTER);

  // Put the core into 3-bit SPI mode
  // Set bit 6 of the DATA_FORMAT register
  adxl345_write_reg(0x31, (1<<6));

  // Now read device ID
  adxl345_read_reg(0x0); //Device ID
  
  exit(0x8000000d);
  
}
