#ifndef _GPIO_H_
#define _GPIO_H_

#define GPIO_IN		0x00		/* GPIO input data */
#define GPIO_OUT	0x04		/* GPIO output data */
#define GPIO_OE		0x08		/* GPIO output driver enable */
#define GPIO_INTE	0x0C		/* Interrupt enable */
#define GPIO_PTRIG	0x10		/* Type of event that triggers an interrupt */
#define GPIO_AUX	0x14		/* Multiplex auxiliary inputs to GPIO outputs */
#define GPIO_CTRL	0x18		/* Control register */
#define GPIO_INTS	0x1C		/* Interrupt status */
#define GPIO_ECLK	0x20		/* Enable gpio_eclk to latch RGPIO_IN */
#define GPIO_NEC	0x24		/* Select active edge of gpio_eclk */

#define GPIO_CTRL_INTE		0x01
#define GPIO_CTRL_INTS		0x02

void gpio_init(int core);
void set_gpio_direction(int core, unsigned int dirs);
unsigned int gpio_read(int core);
void gpio_write(int core, unsigned int value);

#endif
