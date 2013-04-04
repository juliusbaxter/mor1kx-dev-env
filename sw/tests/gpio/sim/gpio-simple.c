#include "cpu-utils.h"
#include "board.h"
#include "gpio.h"
#include "printf.h"


int main()
{

  int core = 0;

  printf("GPIO%d test\n", core);
  
  gpio_init(core);

  // Bottom half out, top half in
  set_gpio_direction(core, 0x0000ffff);

  unsigned long testdata = 0xbabe;

  // Write out some data
  gpio_write(core, testdata);

  report(gpio_read(core));

  if ((~gpio_read(core))>>16 != testdata)
    exit(1);

  report(0x8000000d);
  
  exit(0);

}
