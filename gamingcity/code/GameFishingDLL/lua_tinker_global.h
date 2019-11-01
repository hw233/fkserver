#pragma once

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

#include "lua_tinker_stack.h"

namespace lua_tinker{

	class global{
	public:
		global(lua_State* L);
		global(global& R);

		global operator=(global& R);

		stack::value operator[](const char* name);

		lua_State* m_L;
	};

}