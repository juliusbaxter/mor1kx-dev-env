/*
 *
 * Test to wait for external testbench stimulus to change a 
 * memory value to non-zero
 *
 */
 

#include "cpu-utils.h"

int main()
{
  int * test_loc = (int*) 0x4;
  while(test_loc[0] == 0);
  report(test_loc[0]);
  exit(0);
}
