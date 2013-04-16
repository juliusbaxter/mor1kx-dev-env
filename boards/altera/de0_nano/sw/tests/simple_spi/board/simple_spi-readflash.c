// Program that will read out some values from the flash and dump them in memory

#include "cpu-utils.h"

#include "board.h"
#include "simple-spi.h"

int spi_master;
char slave;

// Little program to dump the contents of the SPI flash memory it's connected 
// to on the board

void
spi_write_ignore_read(int core, char dat)
{
  spi_core_write_data(core,dat);
  while (!(spi_core_data_avail(core))); // Wait for the transaction (should 
                                        // generate a byte)
  spi_core_read_data(core);
}

char
spi_read_ignore_write(int core)
{
  spi_core_write_data(core, 0x00);
  while (!(spi_core_data_avail(core))); // Wait for the transaction (should 
                                        // generate a byte)
  return spi_core_read_data(core);
}


unsigned long
spi_read_epcs_silicon_id(int core, char slave_sel)
{
  unsigned long rdid;
  char* rdid_ptr = (char*) &rdid;
  int i;
  spi_core_slave_select(core, slave_sel); // Select slave
  rdid_ptr[3] = 0;
  // Send the RDID command
  spi_write_ignore_read(core,0xab); // 0xab is read silicon ID for Altera EPCS flash devices
  // Now we read the next 3 bytes
  for(i=0;i<3;i++)
    {
      rdid_ptr[i] = spi_read_ignore_write(core);
    }
  spi_core_slave_select(core, 0); // Deselect slave
  return rdid;
}


unsigned long
spi_read_id(int core, char slave_sel)
{
  unsigned long rdid;
  char* rdid_ptr = (char*) &rdid;
  int i;
  spi_core_slave_select(core, slave_sel); // Select slave
  rdid_ptr[3] = 0;
  // Send the RDID command
  spi_write_ignore_read(core,0x9f); // 0x9f is READ ID command
  // Now we read the next 3 bytes
  for(i=0;i<3;i++)
    {
      rdid_ptr[i] = spi_read_ignore_write(core);
    }
  spi_core_slave_select(core, 0); // Deselect slave
  return rdid;
}


// Read status regsiter
char
spi_read_sr(int core, char slave_sel)
{
  char rdsr;
  spi_core_slave_select(core, slave_sel); // Select slave
  // Send the RDSR command
  spi_write_ignore_read(core,0x05); // 0x05 is READ status register command
  rdsr = spi_read_ignore_write(core);
  spi_core_slave_select(core, 0); // Deselect slave  
  return rdsr;
}


void
spi_read_block(int core, char slave_sel, unsigned int addr, int num_bytes, 
	       char* buf)
{
  int i;
  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0x3); // READ command
  spi_write_ignore_read(core,((addr >> 16) & 0xff)); // addres high byte
  spi_write_ignore_read(core,((addr >> 8) & 0xff)); // addres middle byte
  spi_write_ignore_read(core,((addr >> 0) & 0xff)); // addres low byte
  for(i=0;i<num_bytes;i++)
    buf[i] = spi_read_ignore_write(core);
  
  spi_core_slave_select(core, 0); // Deselect slave  
}


void
spi_set_write_enable(int core, char slave_sel)
{
  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core,0x06); // 0x06 is to set write enable
  spi_core_slave_select(core, 0); // Deselect slave  
}


// Write up to 256 bytes of data to a page, always from offset 0
void
spi_page_program(int core, char slave_sel, short page_num, int num_bytes, 
		 char* buf)
{
  
  // Set WE latch
  spi_set_write_enable(core, slave_sel);
  while(!(spi_read_sr(core, slave_sel) & 0x2)); // Check it's set

  int i;
  if (!(num_bytes > 0)) return;
  if (num_bytes > 256) return;
  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0x2); // Page program command
  spi_write_ignore_read(core,((page_num >> 8) & 0xff)); // addres high byte
  spi_write_ignore_read(core,((page_num >> 0) & 0xff)); // addres middle byte
  spi_write_ignore_read(core,0); // addres low byte
  for(i=0;i<num_bytes;i++)
    spi_write_ignore_read(core, buf[i]);
  spi_core_slave_select(core, 0); // Deselect slave  

 // Now poll status reg for WIP bit
  while((spi_read_sr(core, slave_sel) & 0x1));
}


// Erase a sector - assumes 128KByte memory, so 4 sectors of 32KBytes each
void
spi_sector_erase(int core, char slave_sel, unsigned int sector)
{
  // Set WE latch
  spi_set_write_enable(core, slave_sel);
  while(!(spi_read_sr(core, slave_sel) & 0x2)); // Check it's set

  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0xd8); // Sector erase command
  spi_write_ignore_read(core,(sector>>1)&0x1); // sector select high bit (bit 
                                               // 16 of addr)
  spi_write_ignore_read(core,(sector&0x1)<<7); // sector select low bit (bit 15
                                               // of addr)
  spi_write_ignore_read(core,0); // addres low byte  
  spi_core_slave_select(core, 0); // Deselect slave  

  // Now poll status reg for WIP bit
  while((spi_read_sr(core, slave_sel) & 0x1));

}

// Erase entire device
void
spi_bulk_erase(int core, char slave_sel)
{
 // Set WE latch
  spi_set_write_enable(core, slave_sel);
  while(!(spi_read_sr(core, slave_sel) & 0x2)); // Check it's set

  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0xc7); // Bulk erase
  spi_core_slave_select(core, 0); // Deselect slave  

 // Now poll status reg for WIP bit
  while((spi_read_sr(core, slave_sel) & 0x1));
}


int 
main()
{

  char *buf = (char*)0x800000;
  int *wordbuf = (int*)0x800000;
  char c;
  int i,j;
  spi_master = 0;
  slave = 1;

  spi_core_slave_select(spi_master, 0); // Deselect slaves

  // Clear the read FIFO
  //while (spi_core_data_avail(spi_master))
  //    c = spi_core_read_data(spi_master);

  // Just dump some out
  //spi_read_block(spi_master, slave, /*0xb00000*/0, 0x100000, 
  //buf);

  spi_read_block(spi_master, slave, 0xb0000, 0x1000, 
  buf);

  //wordbuf[0] = spi_read_epcs_silicon_id(spi_master,1);
  

  // SPI core 0, should already be configured to read out data
  // when we reset.
  exit(0);

}
