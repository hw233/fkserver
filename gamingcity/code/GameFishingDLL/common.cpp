#include "common.h"

#ifdef PLATFORM_LINUX

#include <sys/timeb.h>
uint32_t timeGetTime()
{
	timeb tb_;
	ftime(&tb_);
	return 1000 * tb_.time + tb_.millitm;
}

#endif