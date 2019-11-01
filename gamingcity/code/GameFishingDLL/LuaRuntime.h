#pragma once

extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
};

class LuaRuntime {
 public:
  static LuaRuntime* instance(lua_State* L = nullptr) {
    if (!sInstance) {
      sInstance = new LuaRuntime(L);
    }

    return sInstance;
  }

  static void Destory() {
    delete sInstance;
    sInstance = nullptr;
  }

  lua_State* LuaState() { return sLuaState; }

  LuaRuntime(lua_State* L) { sLuaState = L; }

private:
  lua_State* sLuaState;
  static LuaRuntime* sInstance;
};