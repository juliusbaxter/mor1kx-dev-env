#include "cpu-utils.h"
#include "board.h"
#include "gpio.h"
#include "printf.h"


int main()
{

  int core = 0;

  printf("GPIO%d test\n", core);
  
  gpio_init(core);

  // Set the bottom byte out
  set_gpio_direction(core, 0x000000ff);

  // Write out some data
  gpio_write(core, 0xaa);

  // Should be able to read this back from bits [13:9], but inverted
  unsigned int data = gpio_read(core);

  report(data);

  exit(0);

}
