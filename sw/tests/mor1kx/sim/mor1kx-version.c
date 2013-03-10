/* Software to print out version and implementation information */

#include <spr-defs.h>
#include "mor1kx-defs.h"
#include "printf.h"
#include "cpu-utils.h"

int main(void)
{
  unsigned long reg;

  printf("mor1kx version check software\n");

  // Check if we have the AVR
  reg = mfspr(SPR_CPUCFGR);
    
  if (reg & SPR_CPUCFGR_AVRP)
    {
      reg = mfspr(SPR_AVR);
      printf("OR1K %d.%d rev%d compliant CPU detected\n", 
	     (reg & SPR_AVR_MAJ)>>SPR_AVR_MAJ_OFF,
	     (reg & SPR_AVR_MIN)>>SPR_AVR_MIN_OFF,
	     (reg & SPR_AVR_REV)>>SPR_AVR_REV_OFF);
    }
  

  // Check for the version regsiter
  reg = mfspr(SPR_VR);

  if (!(reg & SPR_VR_UVRP))
    {
      printf("No updated version register detected\n");
      printf("This probably means your CPU doesn't conform to the OR1K 1.0 spec and doesn't have useful version registers.\n");
      printf("Dumping VR and exiting\n");
      printf("VR = %08x\n", reg);
      return 0;
    }

  /* Check the CPUID */
  reg = mfspr(SPR_VR2);
  
  switch(((reg & SPR_VR2_CPUID)>>SPR_VR2_CPUID_OFF)&0xff)
    {
    case SPR_VR2_CPUID_OR1KSIM:
      printf("or1ksim CPU detected. Version field: %06x\n", reg & SPR_VR2_VER);
      break;
    case SPR_VR2_CPUID_MOR1KX:
      printf("mor1kx CPU detected. Version field: %06x\n", reg & SPR_VR2_VER);
      break;
    case SPR_VR2_CPUID_OR1200:
      printf("OR1200 CPU detected. Version field: %06x\n", reg & SPR_VR2_VER);
      break;
    case SPR_VR2_CPUID_ALTOR32:
      printf("AltOr32 CPU detected. Version field: %06x\n", reg & SPR_VR2_VER);
      break;
    case SPR_VR2_CPUID_OR10:
      printf("OR10 CPU detected. Version field: %06x\n", reg & SPR_VR2_VER);
      break;
    default:
      printf("Unknown CPU detected. Version field: %06x\n", reg & SPR_VR2_VER);
      break;
    }

  // If it was an mor1kx CPU implementation we can check the details
  if ((((reg & SPR_VR2_CPUID)>>SPR_VR2_CPUID_OFF)&0xff)==SPR_VR2_CPUID_MOR1KX)
    {
      // The following defines come from mor1kx-defs.h
      printf("mor1kx ");
      switch (reg & MOR1KX_VR2_PIPEID)
	{
	case MOR1KX_VR2_PIPEID_CAPPUCCINO:
	  printf("cappuccino");
	  break;
	case MOR1KX_VR2_PIPEID_ESPRESSO:
	  printf("espresso");
	  break;
	case MOR1KX_VR2_PIPEID_PRONTOESPRESSO:
	  printf("prontoespresso");
	  break;
	default:
	  printf("unknown");
	  break;
	}
      printf(" pipeline implementation detected\n");
    }

  // Check if the implementation-specific registers (ISRs) are present
  reg = mfspr(SPR_CPUCFGR);
  /*
  if (reg & SPR_CPUCFGR_ISRP)
    {
    }
  */
  report(0x8000000d);
  return 0;
  
}
