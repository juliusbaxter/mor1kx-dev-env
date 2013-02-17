/* Overflow and carry detection and exception tests

   Randomly generate numbers, test if they will trigger an overflow
   or carry condition, add them, make sure they do.

   Currently only:
   * Tests add
     * Non-exeception generating overflow (reading SR)
     * Exception generating overflow
     * Carry generation (non-exception only)
   * Tests add-with-carry
     * Reading SR

TODO: 
  * Add support to detecting if the AECSR is implemented and do appropriate tests

*/

#include "cpu-utils.h"
#include "spr-defs.h"
#include "printf.h"

#define NUM_TESTS 10000

int range_exception_occurred = 0;
unsigned long int last_esr = -1;

void range_exception_handler(void)
{
  range_exception_occurred = 1;
  // Get the ESR
  last_esr = current_exception_state_struct->esr;
  // Now remove these from the ESR incase they're set so we don't sit in a loop
  // with the exception being triggered again...
  current_exception_state_struct->esr = last_esr & ~(SPR_SR_CY | SPR_SR_OV);
  // Also step over the instruction which caused the exception
  current_exception_state_struct->epcr += 4;
}

// Exception enable/disable functions depending on the CPU's capabilities
void (* enable_add_overflow_exception) (void);
void (* disable_add_overflow_exception) (void);

void enable_add_overflow_exception_no_aecsr(void)
{
  // Simple case, old OR1K arch
  mtspr(SPR_SR, (mfspr(SPR_SR) & (~(SPR_SR_CY | SPR_SR_OV))) | SPR_SR_OVE);
}

void disable_add_overflow_exception_no_aecsr(void)
{
  // Simple case, old OR1K arch
  mtspr(SPR_SR, mfspr(SPR_SR) & ~SPR_SR_OVE);
}

void do_add_get_sr(unsigned long a, unsigned long b,
		   unsigned long* p_sr, int carry_in)
{
  unsigned long x, sr;
  // Do the add, ensure the very next instruction fishes out the SR register
  if (carry_in)
    {
      unsigned int c = 0x80000000;
      // Set carry in, then do l.addc
      asm volatile("l.add %0, %3, %3;\n"
		   // Carry should be set now
		   "l.addc %1,%4,%5;\n"
		   "l.mfspr  %2,r0,17" 
		   : "=r" (c), "=r" (x), "=r" (sr) 
		   : "r" (c), "r" (a), "r" (b));
    }
  else
    {
      asm volatile("l.add %0,%2,%3;\n"
		   "l.mfspr  %1,r0,17" 
		   : "=r" (x), "=r" (sr) 
		   : "r" (a), "r" (b));
    }
  
  // Set the SR value
  *p_sr = sr;

}

int do_add_get_sr_by_exception(unsigned long a, unsigned long b,
				unsigned long* p_sr, int carry_in,
				int expect_exception)
{
  unsigned long x;
  // Do the add, if we're expecting the exception,then get the
  // SR value from the global which will be set in the exception
  // handler. Otherwise just do a normal add:
  if (!expect_exception)
    {
      (*enable_add_overflow_exception)();
      do_add_get_sr(a, b, p_sr, carry_in);
      (*disable_add_overflow_exception)();
      // Used to check if exception was triggered here but
      // any number of things could have triggered it, so don't worry
      // about it.
      return 0;
    }

  // Enable exception - call the function pointer, is set up 
  // depending on the CPU's capabilities
  (*enable_add_overflow_exception)();
  range_exception_occurred = 0;

  
  // Note that here the assembly has been observed to have assigned the same 
  // register for x and a, eg. the disassembly had "l.add r2, r2, r5".
  // This then may mean that if the instruction is repeated then it will 
  // not have the same result. The exception handler will step over this
  // instruction anyway, by incrementing the EPCR.
  
  asm volatile("l.add %0,%1,%2;\n"
	       : "=r" (x)
	       : "r" (a), "r" (b));

  // Disable exception
  (*disable_add_overflow_exception)();

  // Now pass the exception SR value
  *p_sr = last_esr;

  // Ensure an exception occurred
  if (!range_exception_occurred)
    {
      // We were expecting one! So... 
      printf("Exception didn't trigger, and we were expecting it to!\n");
      return 1;
    }

  // Register that we saw this exception
  range_exception_occurred = 0;

  return 0;
  
}

// Take two values, a and b, see if they will set overflow or carry
// and then do the arithmetic and see what happens
int test_add(int a, int b, int carry_in, int exception)
{
  unsigned int ua, ub;
  int expected_carry, expected_ov;
  unsigned long sr;
  int wrong = 0;
  
  char* carry_in_string;
  char* carry_in_string_carry = " + c_in";
  char* carry_in_string_none  = "       ";

  ua = (unsigned int) a;
  ub = (unsigned int) b;

  // Addition
  // First set expected overflow. Subtract from the largest positive number
  // (convert to positive if negative) and check if the other number is 
  // greater than that. If so, we're going to overflow.
  if (a < 0 && b < 0)
    {
      if ((0x7fffffff-((~ua)+1)) < ((~ub)+1) + carry_in)
	expected_ov = 1;
      else
	expected_ov = 0;
    }
  else if (a > 0 && b > 0)
    {
      if ((0x7fffffff - ua) < ub + carry_in)
	expected_ov = 1;
      else
	expected_ov = 0;
    }
  else
    // One number is positive and one is negative, not going to
    // do signed overflow on add.
    expected_ov = 0;
  // Similar method to above, subtract a from largest possible number, if
  // b is bigger than the result, we know we're going to overflow.
  if ((0xffffffff-ua) <= ub + carry_in)
    expected_carry = 1;
  else
    expected_carry = 0;

  // Now let's do the add test.
  if (exception)
    {
      int error = do_add_get_sr_by_exception(a, b, &sr, carry_in, expected_ov);
      if (error)
	{
	  printf("   (%d,%d) Test with exception failed\n", expected_ov, expected_carry);
	  return error;
	}
    }
  else
    do_add_get_sr(a, b, &sr, carry_in);

  // Setup a string to indicate if we're in carry-in mode
  if (carry_in)
    carry_in_string = carry_in_string_carry;
  else
    carry_in_string = carry_in_string_none;

  // Test for OV and carry
  if ((expected_ov << 11) ^ (sr & SPR_SR_OV))
    {
      // Wrong!
      printf("%d + %d%s (0x%08x + 0x%08x) did not set OV to %d\n", a, b, 
	     carry_in_string, ua, ub, expected_ov);
      wrong = 1;
    }
  if ((expected_carry << 10) ^ (sr & SPR_SR_CY))
    {
      // Wrong!
      printf("%d + %d%s (0x%08x + 0x%08x) did not set CY to %d\n", a, b, 
	     carry_in_string, ua, ub, expected_carry);
      wrong = 1;
    }
  if (!wrong)
    {
      char exception_char = exception ? 'E' : ' ';
      printf ("OK (%d,%d) for %11d + %11d%s (0x%08x + 0x%08x%s) %c\n",expected_ov, 
	      expected_carry, a, b, carry_in_string, ua, ub, carry_in_string,
	      exception_char);
    }
  
  return wrong;
}

int main(void)
{
  
  int loops = 0;
  int a, b, x ,y;
  unsigned int ua, ub, ux, uy;
  int expected_carry, expected_ov;
  unsigned long sr, sr_addr = SPR_SR;
  int wrong = 0;
  int total_wrong = 0;
  
  // Initialise exception handlers for range exceptions
  add_handler(0xb, range_exception_handler);

  // Initialise execption enable-disable pointer functions
  // TODO - detection of AESR capability
  enable_add_overflow_exception = enable_add_overflow_exception_no_aecsr;
  disable_add_overflow_exception = disable_add_overflow_exception_no_aecsr;
  
  while (1)
    {

      // Generate two random operands, check what effect they will have on the
      // overflow and carry bits

      a = (int) rand();
      b = (int) rand();

      total_wrong += test_add(a, b, 0, 0);
      total_wrong += test_add(a, b, 1, 0);
      // Tests causing exception
      total_wrong += test_add(a, b, 0, 1);
      // Don't test carry one yet, it's annoying to set up as
      // as setting carry causes the exception to occur
      //total_wrong += test_add(a, b, 1, 1);

      loops++;

      if (loops == NUM_TESTS)
	break;
    }

  if (total_wrong)
    printf("Total wrong tests: %d\n", total_wrong);
  else
    printf("All tests OK\n");

  report(0x8000000d);
  return 0;
  
}
