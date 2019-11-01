////
#ifndef _MY_COMPONENT_H_
#define _MY_COMPONENT_H_

#include <memory>
#include "common.h"

class MyObject;
class MyComponent;
//组件事件
class CComEvent {
 public:
  CComEvent(){};
  virtual ~CComEvent(){};
  void SetID(uint32_t id) { id_ = id; }
  uint32_t GetID() const { return id_; };

  int64_t GetParam1() const { return param1_; }
  void SetParam1(int64_t param) { param1_ = param; }

  template <class T>
  T* GetParam2() const {
    return std::static_pointer_cast<T>(param2_);
  }

  template <class T>
  void SetParam2(T* param) {
    param2_ = std::static_pointer_cast<void>(param);
  }

  //事件的发起者
  MyComponent* GetSender() const { return sender_; }
  void SetSender(MyComponent* sender) { sender_ = sender; }

 protected:
  uint32_t id_;                   //事件ID
  MyComponent* sender_;           //组件指针
  int64_t param1_;                //类型参数
  void* param2_;  //事件对角
};

enum MyComponentType {
  ECF_NONE = 0,
  ECF_MOVE,       //移动组件
  ECF_VISUAL,     //可视化组件                     //前端使用
  ECF_EFFECTMGR,  //死亡效果管理器
  ECF_BUFFERMGR,  //ＢＵＦＦＥＲ管理器
};

//组件
class MyComponent {
 public:
  MyComponent() : owner_(0){};
  virtual ~MyComponent(){};

  const uint32_t GetID() const { return id_; };
  virtual const uint32_t GetFamilyID() const { return id_ >> 8; };

  //附加到对象后被调用
  virtual void OnAttach(){};
  //从对象移出前被调用
  virtual void OnDetach(){};

  //响应时间流逝
  virtual void OnUpdate(int ms){};

  //响应组件消息
  virtual void OnCCEvent(std::shared_ptr<CComEvent>){};

  template <class T = MyObject>
  void SetOwner(std::shared_ptr<T> owner) {
    owner_ = owner;
  };

  template <class T = MyObject>
  std::shared_ptr<T> GetOwner() const {
    return std::dynamic_pointer_cast<T>(owner_);
  };

 protected:
  //发起事件,该事件被立即响应
  void RaiseEvent(std::shared_ptr<CComEvent>);
  void RaiseEvent(uint32_t idEvent, int64_t nParam1 = 0, void* pParam2 = 0);
  //投递事件,该事件将被延后响应
  void PostEvent(std::shared_ptr<CComEvent>& evnt);
  void PostEvent(uint32_t idEvent, int64_t nParam1 = 0, void* pParam2 = 0);

 private:
  void SetID(uint32_t id) { id_ = id; }
  friend class MyComponentFactory;

 private:
  uint32_t id_;                      // ID
  std::shared_ptr<MyObject> owner_;  //组件所属对象
};

#endif
