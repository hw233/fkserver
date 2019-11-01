#include "lua_tinker_stack.h"
#include "lua_tinker.h"

namespace lua_tinker {
namespace stack{

  template<class T>
  T value::as() {
    return std::move(lua2type<T>(L_, index_));
  }

  value::operator table(){ 
    table tb(L_,index_);
    L_ = 0;
    index_ = 0;
    return tb;
  }


  template <class TRVal, class... TArgs>
  TRVal value::operator()(const TArgs&... args) {
    lua_pushcclosure(L_, on_error, 0);
    int errfunc = lua_gettop(L_);

    lua_pushvalue(L_, index_);
    if (lua_isfunction(L_, -1)) {
      push(L_, args...);
      lua_pcall(L_, sizeof...(args), 1, errfunc);
    } else {
      print_error(L_, "stack::value() attempt to call (but not a function)");
    }

    lua_remove(L_, errfunc);
    return lua_tinker::pop<TRVal>(L_);
  }

}
}  // namespace lua_tinker
