////
#ifndef _MY_OBJECT_FACTORY_H_
#define _MY_OBJECT_FACTORY_H_

#include "Factory.h"
#include "MyObject.h"
#include "Singleton.h"

class MyObjFactory : public Factory<int, MyObject>,
                     public Singleton<MyObjFactory> {
 public:
  MyObjFactory();
  virtual ~MyObjFactory();
  FriendBaseSingleton(MyObjFactory);

 public:
  virtual std::shared_ptr<MyObject> Create(int objType);
};

template <class _Ty>
class MyObjCreator : public Creator<MyObject> {
 public:
  virtual _Ty* Create() { return new _Ty; }
};

#define REGISTER_OBJ_TYPE(typeID, type)                              \
  {                                                                  \
    std::shared_ptr<Creator<MyObject> > ptr(new MyObjCreator<type>()); \
    MyObjFactory::instance()->Register(typeID, ptr);                 \
  }

template<class T>
inline std::shared_ptr<T> CreateObject(int objType) {
  return std::dynamic_pointer_cast<T>(MyObjFactory::instance()->Create(objType));
}

#endif
