////
#ifndef __MY_COMPONENT_FACTORY_H__
#define __MY_COMPONENT_FACTORY_H__

#include "Factory.h"
#include "MyComponent.h"
#include "Singleton.h"

class MyComponentFactory : public Factory<int, MyComponent>,
                           public Singleton<MyComponentFactory> {
 public:
  MyComponentFactory();
  ~MyComponentFactory(){};
  FriendBaseSingleton(MyComponentFactory);

 public:
  virtual std::shared_ptr<MyComponent> Create(int soc_id) {
    auto soc = Factory<int, MyComponent>::Create(soc_id);
    if (soc) soc->SetID(soc_id);
    return soc;
  }
};

template <class _Ty>
class MyComponentCreator : public Creator<MyComponent> {
 public:
  virtual _Ty* Create() { return new _Ty; }
};

#define REGISTER_MYCOMPONENT_TYPE(typeID, type)            \
  {                                                        \
    std::shared_ptr<Creator<MyComponent> > ptr(            \
        new MyComponentCreator<type>());                   \
    MyComponentFactory::instance()->Register(typeID, ptr); \
  }

template<class T>
inline std::shared_ptr<T> CreateComponent() {
  return nullptr;
}

template<>
inline std::shared_ptr<BufferMgr> CreateComponent() {
  return std::dynamic_pointer_cast<BufferMgr>(MyComponentFactory::instance()->Create(EBCT_BUFFERMGR));
}

template<>
inline std::shared_ptr<MoveCompent> CreateComponent() {
  return std::dynamic_pointer_cast<MoveCompent>(MyComponentFactory::instance()->Create(ECF_MOVE));
}

template<>
inline std::shared_ptr<MoveByPath> CreateComponent() {
  return std::dynamic_pointer_cast<MoveByPath>(MyComponentFactory::instance()->Create(EMCT_PATH));
}

template<>
inline std::shared_ptr<MoveByDirection> CreateComponent() {
  return std::dynamic_pointer_cast<MoveByDirection>(MyComponentFactory::instance()->Create(EMCT_DIRECTION));
}

template<>
inline std::shared_ptr<EffectMgr> CreateComponent() {
  return std::dynamic_pointer_cast<EffectMgr>(MyComponentFactory::instance()->Create(EECT_MGR));
}

#endif  //__CLIENT_COMPONENT_FACTORY_H__
