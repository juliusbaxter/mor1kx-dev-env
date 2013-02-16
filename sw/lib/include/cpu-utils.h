#ifndef _CPU_UTILS_H_
#define _CPU_UTILS_H_

#if OPENRISC_CPU_TYPE==mor1kx
# include "mor1kx-utils.h"
#else
# if OPENRISC_CPU_TYPE==or1200
#  include "or1200-utils.h"
# endif
#endif


#endif
