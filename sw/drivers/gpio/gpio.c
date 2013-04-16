#include "cpu-utils.h"
#include "board.h"
#include "gpio.h"


#ifdef GPIO_NUM_CORES
const int GPIO_BASE_ADR[GPIO_NUM_CORES] = {GPIO_BASE_ADDRESSES_CSV};
#else
const int GPIO_BASE_ADR[1] = {0};
#endif


void gpio_init(int core)
{
	// interrupt setup
	// global interrupt disable
	REG32(GPIO_BASE_ADR[core] + GPIO_CTRL	) = 0x0;

	// mask all input interrupt
	REG32(GPIO_BASE_ADR[core] + GPIO_INTE	) = 0x0;

	// clear interrupt interrupt
	REG32(GPIO_BASE_ADR[core] + GPIO_INTS	) = 0x0;
	
	// set input interrupt posedge trigering mode
	REG32(GPIO_BASE_ADR[core] + GPIO_PTRIG	) = 0xFFFFFFFF;

	// I/O setup
	// clear all GPIO output
	REG32(GPIO_BASE_ADR[core] + GPIO_OUT	) = 0x0;
	
	// set all GPIO is input
	REG32(GPIO_BASE_ADR[core] + GPIO_OE		) = 0xFFFFFFFF;
	
	// disable AUX input 
	REG32(GPIO_BASE_ADR[core] + GPIO_AUX	) = 0x0;


	// Input sampling mode setup
	// use system bus clock to sampling GPIO inputs
	REG32(GPIO_BASE_ADR[core] + GPIO_ECLK	) = 0x0;

	// ECLK active posedge
	REG32(GPIO_BASE_ADR[core] + GPIO_NEC	) = 0x0;
}

void set_gpio_direction(int core, unsigned int dirs) 
{
	REG32(GPIO_BASE_ADR[core] + GPIO_OE		) = dirs;
}

unsigned int gpio_read(int core) 
{
	return REG32(GPIO_BASE_ADR[core] + GPIO_IN	);
}

void gpio_write(int core, unsigned int value) 
{
	REG32(GPIO_BASE_ADR[core] + GPIO_OUT	) = value;
}

void gpio_enable_ints(int core)
{
  REG32(GPIO_BASE_ADR[core] + GPIO_CTRL	) = GPIO_CTRL_INTE;
}

void gpio_disable_ints(int core)
{
  REG32(GPIO_BASE_ADR[core] + GPIO_CTRL	) = 0;
}

void gpio_int_enable_line(int core, unsigned int line_num, int trigger)
{
  REG32(GPIO_BASE_ADR[core] + GPIO_INTE	) |= (1<<line_num);

  // Trigger - 1 for rising, 0 for falling edge
  if (trigger)
    REG32(GPIO_BASE_ADR[core] + GPIO_PTRIG	) |= (1<<line_num);
  else
    REG32(GPIO_BASE_ADR[core] + GPIO_PTRIG	) &= ~(1<<line_num);
}

void gpio_int_disable_line(int core, unsigned int line_num)
{
  REG32(GPIO_BASE_ADR[core] + GPIO_INTE	) &= ~(1<<line_num);
}

unsigned int gpio_get_ints(int core)
{
  return (unsigned int)REG32(GPIO_BASE_ADR[core] + GPIO_INTS	);
}

void gpio_clear_ints(int core, unsigned int line_num)
{
  // Clear the line in the INTS reg
  REG32(GPIO_BASE_ADR[core] + GPIO_INTS	) &= ~(1<<line_num);

  // Clear the global interrupt signal
  REG32(GPIO_BASE_ADR[core] + GPIO_CTRL	) &= ~GPIO_CTRL_INTS;
}


  
