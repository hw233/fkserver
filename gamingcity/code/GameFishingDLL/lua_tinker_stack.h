#pragma once

extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
}

#include <string>

namespace lua_tinker {
int on_error(lua_State* L);
void print_error(lua_State* L, const char* fmt, ...);

struct table;

template <class T>
T pop(lua_State* L);

namespace stack{

class value {
 public:
  value(value& R) = delete;
  value& operator=(value& R) = delete;
  value& operator=(const value& R) = delete;

  value() : L_(nullptr), index_(0) {}

  value(lua_State* L, int index) : L_(L), index_(index) {
    if (index_ < 0) {
      index_ = lua_gettop(L) + index_ + 1;
    }
  }

  value(value&& R) {
    L_ = R.L_;
    index_ = R.index_;
    R.L_ = nullptr;
    R.index_ = 0;
  }

  ~value() {
    remove();
  }

  value& operator=(value&& R) {
    L_ = R.L_;
    index_ = R.index_;
    R.L_ = 0;
    R.index_ = 0;

    return *this;
  }

  explicit operator void(){}
  explicit operator table();

  template<class T>
  operator T(){ return std::move(as<T>());}

  template <class T>
  T as();

  void remove() {
    if(L_ && index_){
      lua_remove(L_, index_);
    }
  }

  template <class TRVal, class... TArgs>
  TRVal operator()(const TArgs&... args);

  lua_State* L_;
  int index_;
};

}

}  // namespace lua_tinker