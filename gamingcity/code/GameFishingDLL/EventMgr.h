#ifndef __EVENT_MGR_H__
#define __EVENT_MGR_H__

#include <algorithm>
#include <list>
#include <map>
#include "Callback.h"
#include "Event.h"
#include "Singleton.h"
#include "MyObject.h"

class CEventMgr : public Singleton<CEventMgr> {
 public:
  CEventMgr();
  ~CEventMgr();

  FriendBaseSingleton(CEventMgr);

 protected:
  typedef std::list<TemplateCallback<std::shared_ptr<CMyEvent>>*> list_handler_t;
  typedef std::map<EventID, list_handler_t> map_handler_t;  //事件map
                      //对象为list的事件处理方法列表（一个事件请求会被多种方法进行不同处理？）

  map_handler_t mapHandler_;  //事件map
  bool bEnabled_;             //是否运行

 public:
  //注册事件
  void RegisterEvent(const EventID& id, TemplateCallback<CMyEvent*>* handler);
  //删除事件
  void UnregisterEvent(const EventID& id, TemplateCallback<CMyEvent*>* handler);
  //立即处理事件请求
  void ProcessEvent(std::shared_ptr<CMyEvent> pEvent);
  //投递事件 处理后删除 此输入事件将在下一个循环被处理,然后被删除
  void PostEvent(std::shared_ptr<CMyEvent> pEvent);
  //通过名字立即处理事件
  void RaiseEvent(const EventID& szEventName);
  //可优
  void Enable(bool bEnabled);
  //更新事件
  void Update(int ms);

 protected:
  std::list<std::shared_ptr<CMyEvent>> m_listEvent;  //被投递事件请求列表(Update执行并清除）
};

#define Register_Event_Handler(event_, func_) \
  { CEventMgr::instance()->RegisterEvent((event_), (func_)); }

#define Bind_Event_Handler(event_, module_, func_)                       \
  {                                                                      \
    CEventMgr::instance()->RegisterEvent(                             \
        (event_),                                                        \
        new TemplateMemFunc<module_, CMyEvent*>(this, &module_::func_)); \
  }

template<class TParam = void,class TSource = MyObject,class TTarget = MyObject>
inline void RaiseEvent(const EventID& i_strEventName, 
                       std::shared_ptr<TParam> i_pParam = nullptr,
                       std::shared_ptr<TSource> i_pSource = nullptr, 
                       std::shared_ptr<TTarget> i_pTarget = nullptr) {
  auto ie = std::make_shared<CMyEvent>();
  ie->SetName(i_strEventName);
  ie->SetParam(i_pParam);
  ie->SetSource(i_pSource);
  ie->SetTarget(i_pTarget);
  CEventMgr::instance()->ProcessEvent(ie);
}

template<class TParam = void,class TSource = MyObject,class TTarget = MyObject>
inline void PostEvent(const EventID& strEventName, 
                      std::shared_ptr<TParam> pParam = nullptr,
                      std::shared_ptr<TSource> pSource = nullptr, 
                      std::shared_ptr<TTarget> pTarget = nullptr) {
  auto pEvent = std::make_shared<CMyEvent>();
  pEvent->SetName(strEventName);
  pEvent->SetParam(pParam);
  pEvent->SetSource(pSource);
  pEvent->SetTarget(pTarget);
  CEventMgr::instance()->PostEvent(pEvent);
}

#endif  //__EVENT_MGR_H__
