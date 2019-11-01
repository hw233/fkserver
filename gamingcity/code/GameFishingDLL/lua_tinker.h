// lua_tinker.h
//
// LuaTinker - Simple and light C++ wrapper for Lua.
//
// Copyright (c) 2005-2007 Kwon-il Lee (zupet@hitel.net)
//
// please check Licence.txt file for licence and legal issues.

#ifndef _LUA_TINKER_H_
#define _LUA_TINKER_H_

extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
};

#include <string.h>
#include <memory>
#include <new>
#include "lua_tinker_stack.h"
#include "lua_tinker_global.h"
#include "common.h"

namespace lua_tinker {
// string-buffer excution
void dofile(lua_State* L, const char* filename);
void dostring(lua_State* L, const char* buff);
void dobuffer(lua_State* L, const char* buff, size_t sz);

// debug helpers
void enum_stack(lua_State* L);
int on_error(lua_State* L);
void print_error(lua_State* L, const char* fmt, ...);

struct lua_object {
 public:
  lua_object() {}
  lua_object(lua_State* L, int index) : L_(L), index_(index) {}

  virtual ~lua_object() {}

  virtual void to_lua() { lua_pushvalue(L_, index_); }

 public:
  int index_;
  lua_State* L_;
};

struct registry_object : public lua_object {
  registry_object(lua_State* L, int index) : lua_object() {
    L_ = L;
    lua_pushvalue(L_, index);
    index_ = luaL_ref(L_, LUA_REGISTRYINDEX);
  }

  ~registry_object() {
    if (index_ != LUA_NOREF) {
      luaL_unref(L_, LUA_REGISTRYINDEX, index_);
    }
  }

  virtual void to_lua() {
    if (index_ == LUA_NOREF) {
      print_error(
          L_, "registry_object::to_lua() attempt to push `NOREF` index value.");
    }
    lua_rawgeti(L_, LUA_REGISTRYINDEX, index_);
  }

  template <class RVal, class... TArgs>
  RVal call(const TArgs&... args) {
    lua_pushcclosure(L_, on_error, 0);
    int errfunc = lua_gettop(L_);

    to_lua();
    if (lua_isfunction(L_, -1)) {
      push(L_, args...);
      lua_pcall(L_, sizeof...(args), 1, errfunc);
    } else {
      print_error(L_,
                  "registry_object::call() attempt to call registry_index `%d' "
                  "(not a function)",
                  index_);
    }

    lua_remove(L_, errfunc);
    return pop<RVal>(L_);
  }
};


struct table;


// type trait
template <typename T>
struct class_name;

template <typename T>
struct class_type {
  typedef typename std::remove_const<typename std::remove_reference<
      typename std::remove_pointer<T>::type>::type>::type type;
};

template <class T>
struct base_type {
  typedef typename std::remove_const<typename std::remove_reference<
      typename std::remove_pointer<T>::type>::type>::type type;
};

template <class T>
struct fast_type {
  typedef
      typename std::remove_reference<typename std::remove_const<T>::type>::type
          type;
};

template <class T>
struct remove_std_auto_ptr {
  typedef T type;
};
template <class T>
struct remove_std_auto_ptr<std::shared_ptr<T>> {
  typedef T type;
};
template <class T>
struct remove_std_auto_ptr<std::unique_ptr<T>> {
  typedef T type;
};

template <class T>
struct is_lua_object
    : std::conditional<
          std::is_base_of<lua_object,
                          typename remove_std_auto_ptr<
                              typename base_type<T>::type>::type>::value,
          std::true_type, std::false_type>::type {};

template <class T>
struct is_std_auto_ptr : std::false_type {};
template <class T>
struct is_std_auto_ptr<std::shared_ptr<T>> : std::true_type {};
template <class T>
struct is_std_auto_ptr<std::unique_ptr<T>> : std::true_type {};

template <class T>
struct is_char_ptr : std::false_type {};
template <>
struct is_char_ptr<char*> : std::true_type {};
template <>
struct is_char_ptr<const char*> : std::true_type {};

template <class T>
struct is_string_class : std::false_type {};
template <>
struct is_string_class<std::string> : std::true_type {};

template <class T>
struct is_std_string : is_string_class<typename base_type<T>::type>::type {};

template <class T>
struct is_std_string_ptr
    : std::conditional<
          !std::is_pointer<T>::value, std::false_type,
          typename std::conditional<is_std_string<T>::value, std::true_type,
                                    std::false_type>::type>::type {};

template <class T>
struct is_string
    : std::conditional<
          is_char_ptr<T>::value, std::true_type,
          typename std::conditional<
              is_std_string_ptr<T>::value, std::true_type,
              typename std::conditional<is_std_string<T>::value, std::true_type,
                                        std::false_type>::type>::type>::type {};

template <class T>
struct is_boolean : std::false_type {};
template <>
struct is_boolean<bool> : std::true_type {};
template <>
struct is_boolean<const bool> : std::true_type {};

template <class T>
struct is_obj
    : std::conditional<
          std::is_integral<typename base_type<T>::type>::value, std::false_type,
          typename std::conditional<
              std::is_floating_point<typename base_type<T>::type>::value,
              std::false_type,
              typename std::conditional<
                  is_string<typename base_type<T>::type>::value,
                  std::false_type,
                  typename std::conditional<
                      is_lua_object<typename base_type<T>::type>::value,
                      std::false_type, std::true_type>::type>::type>::type>::
          type {};

template <>
struct is_obj<table> : std::false_type {};

// class helper
int meta_get(lua_State* L);
int meta_set(lua_State* L);
void push_meta(lua_State* L, const char* name);

// from lua
template <typename T>
struct void2val {
  static inline T invoke(void* input) { return *(T*)input; }
};

template <typename T>
struct void2ptr {
  static inline T* invoke(void* input) { return (T*)input; }
};

template <typename T>
struct void2ref {
  static inline T& invoke(void* input) { return *(T*)input; }
};

template <typename T>
struct void2type {
  static T invoke(void* ptr) {
    return std::conditional<
        std::is_pointer<T>::value, void2ptr<typename base_type<T>::type>,
        typename std::conditional<
            std::is_reference<T>::value, void2ref<typename base_type<T>::type>,
            void2val<typename base_type<T>::type>>::type>::type::invoke(ptr);
  }
};

struct user {
  user(void* p) : m_p(p) {}
  virtual ~user() {}
  void* m_p;
};

template <typename T>
struct user2type {
  static T invoke(lua_State* L, int index) {
    if (!lua_isuserdata(L, index)) {
      lua_pushfstring(
          L, "no class [%d] at first argument. (forgot ':' expression ?)",
          lua_type(L, index));
      lua_error(L);
    }

    return void2type<T>::invoke(lua_touserdata(L, index));
  }
};

template <typename T>
struct lua2enum {
  static T invoke(lua_State* L, int index) {
    return (T)(int)lua_tonumber(L, index);
  }
};

template <typename T>
struct lua2object {
  static T invoke(lua_State* L, int index) {
    if (!lua_isuserdata(L, index)) {
      lua_pushfstring(
          L, "no class [%d] at first argument. (forgot ':' expression ?)",
          lua_type(L, index));

      lua_error(L);
    }

    return void2type<T>::invoke(user2type<user*>::invoke(L, index)->m_p);
  }
};

template <class T>
struct lua2integer {
  static T invoke(lua_State* L, int index) {
    if (!lua_isnumber(L, index)) {
      lua_pushfstring(L, "not number [%d],but get number value.",
                      lua_type(L, index));
      lua_error(L);
    }

    return T(lua_tonumber(L, index));
  }
};

template <class T>
struct lua2float {
  static T invoke(lua_State* L, int index) {
    if (!lua_isnumber(L, index)) {
      lua_pushfstring(L, "not float [%d],but get float value.",
                      lua_type(L, index));
      lua_error(L);
    }

    return T(lua_tonumber(L, index));
  }
};

template <class T>
struct lua2std_string {
  typedef typename base_type<T>::type string_type;
  static string_type invoke(lua_State* L, int index) {
    if (!lua_isstring(L, index)) {
      lua_pushfstring(L, "not std::string [%d],but get std::string value.",
                      lua_type(L, index));
      lua_error(L);
    }
    size_t len = 0;
    const char* str = lua_tolstring(L, index, &len);
    return std::move(string_type(str, len));
  }
};

template <class T>
struct lua2char_ptr {
  static T invoke(lua_State* L, int index) {
    if (!lua_isstring(L, index)) {
      lua_pushfstring(L, "not char* [%d],but get char* value.",
                      lua_type(L, index));
      lua_error(L);
    }

    return T(lua_tostring(L, index));
  }
};

template <class T>
struct lua2string {
  static T invoke(lua_State* L, int index) {
    return std::move(
        std::conditional<is_char_ptr<T>::value, lua2char_ptr<T>,
                         lua2std_string<T>>::type::invoke(L, index));
  }
};

template <class T>
struct lua2boolean {
  static T invoke(lua_State* L, int index) {
    if (!lua_isboolean(L, index)) {
      lua_pushfstring(L, "not boolean [%d],but get boolean value.",
                      lua_type(L, index));
      lua_error(L);
    }

    return lua_toboolean(L, index) != 0;
  }
};

template <typename T>
struct lua2value {
  static T invoke(lua_State* L, int index) {
    return std::move(
        std::conditional<
            is_boolean<T>::value, lua2boolean<T>,
            typename std::conditional<
                std::is_integral<T>::value, lua2integer<T>,
                typename std::conditional<
                    std::is_floating_point<T>::value, lua2float<T>,
                    typename std::conditional<
                        std::is_enum<T>::value, lua2enum<T>,
                        typename std::conditional<
                            is_string<T>::value, lua2string<T>, lua2object<T>>::
                            type>::type>::type>::type>::type::invoke(L, index));
  }
};

template <class T>
struct lua2value<std::shared_ptr<T>> {
  static std::shared_ptr<T> invoke(lua_State* L, int index) {
    if (!std::is_base_of<lua_object, T>::value) {
      lua_pushstring(
          L, "user std::shared_ptr fetch none lua_object based object.");
      lua_error(L);
    }
    return std::make_shared<T>(L, index);
  }
};



template <typename T>
T lua2type(lua_State* L, int index) {
  return std::move(lua2value<T>::invoke(L, index));
}

template <typename T>
struct val2user : user {
  template <class... TArgs>
  val2user(const TArgs&... args) : user(new T(args...)) {}

  ~val2user() { delete ((T*)m_p); }
};

template <typename T>
struct ptr2user : user {
  ptr2user(const T* t) : user((void*)t) {}
};

template <typename T>
struct ref2user : user {
  ref2user(const T& t) : user(&t) {}
};

// to lua
template <typename T>
struct val2lua {
  typedef typename base_type<T>::type base_type;
  static void invoke(lua_State* L, const base_type& input) {
    new (lua_newuserdata(L, sizeof(val2user<base_type>)))
        val2user<base_type>(input);
  }
};

template <typename T>
struct ptr2lua {
  typedef typename base_type<T>::type base_type;
  static void invoke(lua_State* L, base_type* input) {
    if (input)
      new (lua_newuserdata(L, sizeof(ptr2user<base_type>)))
          ptr2user<base_type>(input);
    else
      lua_pushnil(L);
  }
};

template <typename T>
struct ref2lua {
  typedef typename base_type<T>::type base_type;
  static void invoke(lua_State* L, const base_type& input) {
    new (lua_newuserdata(L, sizeof(ref2user<base_type>)))
        ref2user<base_type>(input);
  }
};

template <typename T>
struct enum2lua {
  static void invoke(lua_State* L, T val) { lua_pushnumber(L, (int)val); }
};

template <typename T>
struct object2lua {
  static void invoke(lua_State* L, T val) {
    std::conditional<
        std::is_pointer<T>::value, ptr2lua<T>,
        typename std::conditional<std::is_reference<T>::value, ref2lua<T>,
                                  val2lua<T>>::type>::type::invoke(L, val);

    push_meta(L, class_name<typename base_type<T>::type>::name());
    lua_setmetatable(L, -2);
  }
};

template <class T>
struct integer2lua {
  static void invoke(lua_State* L, T val) { lua_pushnumber(L, val); }
};

template <class T>
struct float2lua {
  static void invoke(lua_State* L, T val) { lua_pushnumber(L, val); }
};

template <class T>
struct std_string_ptr2lua {
  typedef typename base_type<T>::type string_type;
  static void invoke(lua_State* L, const string_type* val) {
    lua_pushlstring(L, (*val).c_str(), (*val).size());
  }
};

template <class T>
struct std_string2lua {
  typedef typename base_type<T>::type base_type;
  static void invoke(lua_State* L, const base_type& val) {
    lua_pushlstring(L, val.c_str(), val.size());
  }
};

template <class T>
struct char_ptr2lua {
  typedef typename base_type<T>::type base_char;
  static void invoke(lua_State* L, const base_char* val) {
    lua_pushstring(L, val);
  }
};

template <class T>
struct string2lua {
  typedef typename fast_type<T>::type fast_type;

  static void invoke(lua_State* L, const fast_type val) {
    std::conditional<
        std::is_pointer<T>::value,
        typename std::conditional<is_std_string_ptr<T>::value,
                                  std_string_ptr2lua<T>, char_ptr2lua<T>>::type,
        std_string2lua<T>>::type::invoke(L, val);
  }
};

template <class T>
struct boolean2lua {
  static void invoke(lua_State* L, T val) { lua_pushboolean(L, val ? 1 : 0); }
};

template <class T>
struct value2lua {
  static void invoke(lua_State* L, T& val) {
    std::conditional<
        is_boolean<T>::value, boolean2lua<T>,
        typename std::conditional<
            std::is_enum<T>::value, enum2lua<T>,
            typename std::conditional<
                std::is_integral<T>::value, integer2lua<T>,
                typename std::conditional<
                    std::is_floating_point<T>::value, float2lua<T>,
                    typename std::conditional<is_string<T>::value,
                                              string2lua<T>, object2lua<T>>::
                        type>::type>::type>::type>::type::invoke(L, val);
  }
};

template <class T>
struct value2lua<std::shared_ptr<T>> {
  static void invoke(lua_State* L, std::shared_ptr<T> v) {
    if (std::is_base_of<lua_object, T>::value) {
      v->to_lua();
    } else {
      object2lua<T>::invoke(L, v.get());
    }
  }
};

template <typename T>
void type2lua(lua_State* L, T val) {
  value2lua<T>::invoke(L, val);
}

// get value from cclosure
template <typename T>
T upvalue_(lua_State* L) {
  return user2type<T>::invoke(L, lua_upvalueindex(1));
}

// read a value from lua stack
template <typename T>
T read(lua_State* L, int index) {
  return std::move(lua2type<T>(L, index));
}

// push a value to lua stack
template <typename T>
void push(lua_State* L, T ret) {
  type2lua<T>(L, ret);
}

template <>
void push(lua_State* L, std::shared_ptr<registry_object> v);

template <class Arg1, class... Args>
void push(lua_State* L, Arg1 arg1, Args... args) {
  push(L, std::forward<Arg1>(arg1));
  push(L, std::forward<Args>(args)...);
}

inline void push(lua_State* L) {}

inline void push_nil(lua_State* L) { lua_pushnil(L); }

// pop a value from lua stack
template <typename T>
T pop(lua_State* L) {
  T t = read<T>(L, -1);
  lua_pop(L, 1);
  return t;
}

template <>
void pop(lua_State* L);

// Table Object on Stack
struct table_obj : lua_object {
  table_obj(lua_State* L, int index);
  ~table_obj();

  void inc_ref();
  void dec_ref();

  bool validate();

  template <typename T>
  void set(const char* name, T object) {
    if (validate()) {
      lua_pushstring(L_, name);
      push(L_, object);
      lua_settable(L_, index_);
    }
  }

  void set_nil(const char* name) {
    if (validate()) {
      lua_pushstring(L_, name);
      lua_pushnil(L_);
      lua_settable(L_, index_);
    }
  }

  template <typename T>
  T get(const char* name) {
    if (validate()) {
      lua_pushstring(L_, name);
      lua_gettable(L_, index_);
    } else {
      lua_pushnil(L_);
    }

    return pop<T>(L_);
  }

  template <typename T>
  void seti(int index, T object) {
    if (validate()) {
      lua_pushinteger(L_, index);
      push(L_, object);
      lua_settable(L_, index_);
    }
  }

  void seti_nil(int index) {
    if (validate()) {
      lua_pushinteger(L_, index);
      lua_pushnil(L_);
      lua_settable(L_, index_);
    }
  }

  template <typename T>
  T geti(int index) {
    if (validate()) {
      lua_pushinteger(L_, index);
      lua_gettable(L_, index_);
    } else {
      lua_pushnil(L_);
    }

    return pop<T>(L_);
  }

  int getlen() {
    if (validate()) {
      // return (int)lua_objlen(m_L, m_index); // lua 5.1
      return (int)luaL_len(L_, index_);
    }
    return 0;
  }

  int size() { return getlen(); }

  stack::value operator[](const char* name) {
    if (validate()) {
      lua_pushstring(L_, name);
      lua_gettable(L_, index_);
    } else {
      lua_pushnil(L_);
    }

    return std::move(stack::value(L_, -1));
  }

  stack::value operator[](int index) {
    if (validate()) {
      lua_pushinteger(L_, index);
      lua_gettable(L_, index_);
    } else {
      lua_pushnil(L_);
    }

    return std::move(stack::value(L_, -1));
  }

  const void* m_pointer;
  int m_ref;
};

// Table Object Holder
struct table {
  table(lua_State* L);
  table(lua_State* L, int index);
  table(lua_State* L, const char* name);
  table(const table& input);
  ~table();

  inline void to_lua() { m_obj->to_lua(); }

  struct iterator {
    iterator(const table& t) {
      if (!t.m_obj->validate()) {
        L = nullptr;
        index = 0;
        return;
      }

      L = t.m_obj->L_;
      index = t.m_obj->index_;
      lua_pushnil(L);
      if (lua_next(L, index) == 0) {
        key_index = lua_gettop(L) - 2 + 1;
        value_index = lua_gettop(L) - 1 + 1;
      }else{
        key_index = value_index = 0;
      }
    }

    iterator(iterator& R)
        : L(R.L),
          index(R.index),
          key_index(R.key_index),
          value_index(R.value_index) {}

    ~iterator() {
      remove();
    }

    operator bool() {
      return index != 0 && key_index != 0 && value_index != 0;
    }

    void operator++(int inc) {
      std::cout << "iterator table index:" << index << std::endl;
      remove();
      if (lua_next(L, index) == 0) {
        key_index = lua_gettop(L) - 2 + 1;
        value_index = lua_gettop(L) - 1 + 1;
      }else{
        key_index = value_index = 0;
      }
    }

    void remove(){ 
      if(key_index && value_index){
        lua_remove(L,key_index);
        lua_remove(L,value_index);
      }
    }

    inline stack::value key() { 
      return std::move(stack::value(L,key_index)); 
    }
    
    inline stack::value value() { 
      return std::move(stack::value(L,value_index)); 
    }

    lua_State* L;
    int index;
    int key_index;
    int value_index;
  };

  template <typename T>
  void set(const char* name, T object) {
    m_obj->set(name, object);
  }

  void set_nil(const char* name) { m_obj->set_nil(name); }

  template <typename T>
  T get(const char* name) {
    return m_obj->get<T>(name);
  }

  template <typename T>
  void seti(int index, T object) {
    m_obj->seti(index, object);
  }

  void seti_nil(int index) { m_obj->seti_nil(index); }

  template <typename T>
  T geti(int index) {
    return m_obj->geti<T>(index);
  }

  int getlen() { return m_obj->getlen(); }

  int size() { return getlen(); }

  stack::value operator[](const char* name) {
    return std::move(m_obj->operator[](name));
  }

  stack::value operator[](int index) {
    return std::move(m_obj->operator[](index));
  }

  table_obj* m_obj;
};

typedef table lua_table;

template <>
struct lua2value<table> {
  static table invoke(lua_State* L, int index) {
    if (!lua_istable(L, index)) {
      lua_pushfstring(L, "not table [%d],but get table value.",
                      lua_type(L, index));
      lua_error(L);
    }

    return table(L, index);
  }
};

template <>
struct value2lua<table> {
  static void invoke(lua_State* L, table& v) { v.to_lua(); }
};

template <>
void push(lua_State* L, table ret);

template <>
table pop(lua_State* L);

template <size_t...>
struct index_seq {};
template <size_t N, size_t... indexes>
struct make_indexes : make_indexes<N - 1, N - 1, indexes...> {};
template <size_t... indexes>
struct make_indexes<0, indexes...> {
  typedef index_seq<indexes...> type;
};

template <size_t index, class... Args>
struct type_of_index;
template <size_t index, class First, class... Args>
struct type_of_index<index, First, Args...>
    : type_of_index<index - 1, Args...> {};
template <class T, class... Args>
struct type_of_index<0, T, Args...> {
  typedef T type;
};

template <size_t TypeIndex, size_t StackIndex, class... TArgs>
struct lua_argment2value {
  typedef typename type_of_index<TypeIndex, TArgs...>::type RVal;
  static RVal get(lua_State* L) {
    return std::move(lua2type<RVal>(L, StackIndex));
  }
};

template <class RVal, class... TArgs>
struct functor_with_index {
  template <size_t... Index>
  static int invoke(lua_State* L, const index_seq<Index...>&) {
    push(L, upvalue_<RVal (*)(TArgs...)>(L)(
                std::forward<typename type_of_index<Index, TArgs...>::type>(
                    lua_argment2value<Index, Index + 1, TArgs...>::get(L))...));
    return 1;
  }
};

template <class... TArgs>
struct functor_with_index<void, TArgs...> {
  template <size_t... Index>
  static int invoke(lua_State* L, const index_seq<Index...>&) {
    upvalue_<void (*)(TArgs...)>(L)(
        std::forward<typename type_of_index<Index, TArgs...>::type>(
            lua_argment2value<Index, Index + 1, TArgs...>::get(L))...);
    return 1;
  }
};

template <class RVal, class T, class... TArgs>
struct class_functor_with_index {
  template <size_t... Index>
  static int invoke(lua_State* L, const index_seq<Index...>&) {
    push(L, (lua2type<T*>(L, 1)->*upvalue_<RVal (T::*)(TArgs...)>(L))(
                std::forward<typename type_of_index<Index, TArgs...>::type>(
                    lua_argment2value<Index, Index + 2, TArgs...>::get(L))...));
    return 1;
  }
};

template <class T, class... TArgs>
struct class_functor_with_index<void, T, TArgs...> {
  template <size_t... Index>
  static int invoke(lua_State* L, const index_seq<Index...>&) {
    (lua2type<T*>(L, 1)->*upvalue_<void (T::*)(TArgs...)>(L))(
        std::forward<typename type_of_index<Index, TArgs...>::type>(
            lua_argment2value<Index, Index + 2, TArgs...>::get(L))...);
    return 1;
  }
};

template <class RVal, class... TArgs>
struct functor {
  typedef typename make_indexes<sizeof...(TArgs)>::type index_type;
  static int invoke(lua_State* L) {
    return functor_with_index<RVal, TArgs...>::invoke(L, index_type());
  }
};

template <class RVal, class T, class... TArgs>
struct class_functor {
  typedef typename make_indexes<sizeof...(TArgs)>::type index_type;
  static int invoke(lua_State* L) {
    return class_functor_with_index<RVal, T, TArgs...>::invoke(L, index_type());
  }
};

template <class RVal, class... TArgs>
void push_functor(lua_State* L, RVal (*)(TArgs...)) {
  lua_pushcclosure(L, functor<RVal, TArgs...>::invoke, 1);
}

template <class RVal, class T, class... TArgs>
void push_functor(lua_State* L, RVal (T::*)(TArgs...)) {
  lua_pushcclosure(L, class_functor<RVal, T, TArgs...>::invoke, 1);
}

// member variable
struct var_base {
  virtual void get(lua_State* L) = 0;
  virtual void set(lua_State* L) = 0;
};

template <typename T, typename V>
struct mem_var : var_base {
  V T::*_var;
  mem_var(V T::*val) : _var(val) {}

  void get(lua_State* L) {
    push<std::conditional<is_obj<V>::value, V&, V>::type>(
        L, lua2type<T*>(L, 1)->*(_var));
  }

  void set(lua_State* L) { lua2type<T*>(L, 1)->*(_var) = lua2type<V>(L, 3); }
};

template <class T, class... TArgs>
struct construction_with_index {
  template <size_t... Index>
  static int invoke(lua_State* L, const index_seq<Index...>&) {
    new (lua_newuserdata(L, sizeof(val2user<T>)))
        val2user<T>(lua_argment2value<Index, Index + 2, TArgs...>::get(L)...);
    push_meta(L, class_name<typename class_type<T>::type>::name());
    lua_setmetatable(L, -2);

    return 1;
  }
};

template <class T, class... TArgs>
struct construction {
  typedef typename make_indexes<sizeof...(TArgs)>::type index_type;
  static int invoke(lua_State* L) {
    return construction_with_index<T, TArgs...>::invoke(L, index_type());
  }
};

template <class T, class... TArgs>
int constructor(lua_State* L) {
  return construction<T, TArgs...>::invoke(L);
}

// destroyer
template <typename T>
int destroyer(lua_State* L) {
  ((user*)lua_touserdata(L, 1))->~user();
  return 0;
}

// global function
template <typename F>
void def(lua_State* L, const char* name, F func) {
  lua_pushlightuserdata(L, (void*)func);
  push_functor(L, func);
  lua_setglobal(L, name);
}

// global variable
template <typename T>
void set(lua_State* L, const char* name, T object) {
  push(L, std::forward<T>(object));
  lua_setglobal(L, name);
}

template <typename T>
T get(lua_State* L, const char* name) {
  lua_getglobal(L, name);
  return pop<T>(L);
}

template <typename T>
void decl(lua_State* L, const char* name, T object) {
  set(L, name, object);
}

template <class RVal, class... TArgs>
RVal call(lua_State* L, const std::string& name, const TArgs&... args) {
  lua_pushcclosure(L, on_error, 0);
  int errfunc = lua_gettop(L);

  lua_getglobal(L, name.c_str());

  if (lua_isfunction(L, -1)) {
    push(L, args...);
    lua_pcall(L, sizeof...(args), 1, errfunc);
  } else {
    print_error(
        L, "lua_tinker::call() attempt to call global `%s' (not a function)",
        name.c_str());
  }

  lua_remove(L, errfunc);
  return pop<RVal>(L);
}

template <typename T>
struct class_name {
  // global name
  static const char* name(const char* name = 0) {
    static char temp[256] = "";
#ifdef PLATFORM_WINDOWS
    if (name) strcpy_s(temp, name);
#else
    if (name) strcpy(temp, name);
#endif
    return temp;
  }
};

template<class T>
struct class_def{
  class_def(lua_State* L,const char* name):L_(L){
    class_name<T>::name(name);
    lua_newtable(L_);

    lua_pushstring(L_, "__name");
    lua_pushstring(L_, name);
    lua_rawset(L_, -3);

    lua_pushstring(L_, "__index");
    lua_pushcclosure(L_, meta_get, 0);
    lua_rawset(L_, -3);

    lua_pushstring(L_, "__newindex");
    lua_pushcclosure(L_, meta_set, 0);
    lua_rawset(L_, -3);

    lua_pushstring(L_, "__gc");
    lua_pushcclosure(L_, destroyer<T>, 0);
    lua_rawset(L_, -3);

    lua_setglobal(L_, name);
  }

  template<class P>
  class_def& inh(){ 
    push_meta(L_, class_name<T>::name());
    if (lua_istable(L_, -1)) {
      lua_pushstring(L_, "__parent");
      push_meta(L_, class_name<P>::name());
      lua_rawset(L_, -3);
    }
    lua_pop(L_, 1);
    return *this;
  }

  template<class...TArgs>
  class_def& constructor(){ 
    push_meta(L_, class_name<T>::name());
    if (lua_istable(L_, -1)) {
      lua_newtable(L_);
      lua_pushstring(L_, "__call");
      lua_pushcclosure(L_, lua_tinker::constructor<T,TArgs...>, 0);
      lua_rawset(L_, -3);
      lua_setmetatable(L_, -2);
    }
    lua_pop(L_, 1);
    return *this;
  }

  template<class F>
  class_def& function(const char* name,F func){
    push_meta(L_, class_name<T>::name());
    if (lua_istable(L_, -1)) {
      lua_pushstring(L_, name);
      new (lua_newuserdata(L_, sizeof(F))) F(func);
      push_functor(L_, func);
      lua_rawset(L_, -3);
    }
    lua_pop(L_, 1);
    return *this;
  }

  template <class BASE, class VAR>
  class_def& variable(const char* name, VAR BASE::*val) {
    push_meta(L_, class_name<T>::name());
    if (lua_istable(L_, -1)) {
      lua_pushstring(L_, name);
      new (lua_newuserdata(L_, sizeof(mem_var<BASE, VAR>)))
          mem_var<BASE, VAR>(val);
      lua_rawset(L_, -3);
    }
    lua_pop(L_, 1);
    return *this;
  }

  lua_State* L_;
};

}  // namespace lua_tinker

#endif  //_LUA_TINKER_H_
