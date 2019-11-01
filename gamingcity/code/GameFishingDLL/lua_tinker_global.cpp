#include "lua_tinker_global.h"

namespace lua_tinker {
	global::global(lua_State* L)
		:m_L(L){

	}

	global::global(global& R)
		: m_L(R.m_L){

	}

	global global::operator=(global& R){
		m_L = R.m_L;
		return *this;
	}

	stack::value global::operator[](const char* name){
		lua_getglobal(m_L, name);
		return std::move(stack::value(m_L, -1));
	}

}