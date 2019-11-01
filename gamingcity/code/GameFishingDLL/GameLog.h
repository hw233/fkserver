#pragma once

#include "common.h"


template<class...TArgs>
void log_info(const char* file,const int line,const char* func,const char* fmt,TArgs...args);

template<class...TArgs>
void log_error(const char* file,const int line,const char* func,const char* fmt,TArgs...args);

template<class...TArgs>
void log_warning(const char* file,const int line,const char* func,const char* fmt,TArgs...args);

template<class...TArgs>
void log_debug(const char* file,const int line,const char* func,const char* fmt,TArgs...args);

#ifdef PLATFORM_LINUX

#define LOG_INFO(fmt, args...) log_info(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_ERR(fmt, args...) log_error(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_WARN(fmt, args...) log_warning(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_DEBUG(fmt, args...) log_debug(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)

#endif
