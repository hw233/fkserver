#include "GameLog.h"
#if defined(_DEBUG) && defined(PLATFORM_WINDOWS)
#include "WindowsConsole.h"
#endif

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

#include "lua_tinker.h"
#include "LuaRuntime.h"
#include "common.h"

template<class...TArgs>
void log_info(const char* file,const int line,const char* func,const char* fmt,const TArgs&...args){
  static char buf[2048] = {0};
  sprintf(buf,fmt,args...);
  
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),"log_info",fmt::tostring(buf,"(",file,":",line," ",func,")"));
}

template<class...TArgs>
void log_error(const char* file,const int line,const char* func,const char* fmt,const TArgs&...args){
  static char buf[2048] = {0};
  sprintf(buf,fmt,args...);

  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),"log_error",fmt::tostring(buf,"(",file,":",line," ",func,")"));
}

template<class...TArgs>
void log_warning(const char* file,const int line,const char* func,const char* fmt,const TArgs&...args){
  static char buf[2048] = {0};
  sprintf(buf,fmt,args...);
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),"log_warning",fmt::tostring(buf,"(",file,":",line," ",func,")"));
}

template<class...TArgs>
void log_debug(const char* file,const int line,const char* func,const char* fmt,const TArgs&...args){
  static char buf[2048] = {0};
  sprintf(buf,fmt,args...);
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),"log_debug",fmt::tostring(buf,"(",file,":",line," ",func,")"));
}