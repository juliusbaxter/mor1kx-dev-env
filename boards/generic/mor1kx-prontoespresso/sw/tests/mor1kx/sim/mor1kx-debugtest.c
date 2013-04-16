/*
 *
 * Test to wait for external testbench stimulus to change a 
 * memory value to non-zero
 *
 */
 

#include "cpu-utils.h"

int main()
{
  volatile int * test_loc = (volatile int*) 0x4;
  while(test_loc[0] == 0);
  report(test_loc[0]);
  exit(0);
}
