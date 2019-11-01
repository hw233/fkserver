#include "MyObject.h"
#include <algorithm>
#include "GameConfig.h"
#include "MoveCompent.h"
#include "MyComponentFactory.h"
#include "MyFunctor.h"
#include "common.h"

MyObject::MyObject(void)
    : id_(0),
      objType_(0),
      m_Mgr(0),
      m_Score(0),
      m_fProbability(MAX_PROBABILITY),
      m_dwCreateTick(timeGetTime()),
      m_nState(EOS_LIVE),
      m_nTypeID(0) {}

MyObject::~MyObject(void) {
  ClearComponent();
}
//更新响应
void MyObject::OnUpdate(int msElapsed) {
  //处理事件列表事件
  while (ccevent_queue_.size() > 0) {
    auto pEvent = ccevent_queue_.front();
    ccevent_queue_.pop_front();
    ProcessCCEvent(pEvent);
  }
  //挂载组件调用OnUpdate
  std::for_each(components_.begin(), components_.end(),
                FuncMapUpdatePtr<Component_Table_t>(msElapsed));
}

template<class T>
std::shared_ptr<T> MyObject::GetComponent(const int family_id)) {
    Component_Table_t::iterator it = components_.find(id);
    if (it != components_.end()) return std::dynamic_pointer_cast<T>(it->second);

    return 0;
}

void MyObject::ProcessCCEvent(std::shared_ptr<CComEvent> pEvent) {
  //所有组件都执行一次事件(根据判断pEvent->GetID() 来决定是否执行或返回） 可优
  for (Component_Table_t::iterator it = components_.begin();
       it != components_.end(); ++it) {
    it->second->OnCCEvent(pEvent);
  }
}

void MyObject::ProcessCCEvent(uint32_t idEvent, int64_t nParam1 /* = 0 */,
                              void* pParam2 /* = 0 */) {
  auto se = std::make_shared<CComEvent>();
  se->SetID(idEvent);
  se->SetParam1(nParam1);
  se->SetParam2(pParam2);

  ProcessCCEvent(se);
}

void MyObject::PushCCEvent(std::shared_ptr<CComEvent>& evnt){
  ccevent_queue_.push_back(evnt);
}

void MyObject::PushCCEvent(uint32_t idEvent, int64_t nParam1 /* = 0 */,
                           void* pParam2 /* = 0 */) {
  CComEvent* pEvent = new CComEvent;
  pEvent->SetID(idEvent);
  pEvent->SetParam1(nParam1);
  pEvent->SetParam2(pParam2);

  std::shared_ptr<CComEvent> autoDel(pEvent);
  PushCCEvent(autoDel);
}

//设置组件
template<class T>
void MyObject::SetComponent(std::shared_ptr<T> newComponent) {
  Component_Table_t::iterator it =
      components_.find(newComponent->GetFamilyID());
  newComponent->SetOwner(this);
  if (it != components_.end()) {
    auto oldComponent = it->second;
    oldComponent->OnDetach();
    MyComponentFactory::instance()->Recovery(oldComponent->GetID(),
                                             oldComponent);
  } 

  components_[newComponent->GetFamilyID()] = std::dynamic_pointer_cast<MyComponent>(newComponent);

  if (newComponent) {
    newComponent->OnAttach();
  }
}

bool MyObject::DelComponent(const uint32_t& familyID) {
  MyComponent* oldSoc(0);
  Component_Table_t::iterator it = components_.find(familyID);
  if (it != components_.end()) {
    it->second->OnDetach();
    MyComponentFactory::instance()->Recovery((it->second)->GetID(), it->second);
    components_.erase(it);
    return true;
  }

  return false;
}

void MyObject::ClearComponent() {
  for (Component_Table_t::iterator it = components_.begin();
       it != components_.end(); ++it) {
    it->second->OnDetach();
    MyComponentFactory::instance()->Recovery((it->second)->GetID(), it->second);
  }

  components_.clear();
}

float MyObject::GetDirection() {
  auto pMove = std::dynamic_pointer_cast<MoveCompent>(this->GetComponent(ECF_MOVE));
  if (pMove) return pMove->GetDirection();

  return 0.0f;
}

MyPoint MyObject::GetPosition() {
  auto pMove = std::dynamic_pointer_cast<MoveCompent>(this->GetComponent(ECF_MOVE));
  if (pMove) return pMove->GetPostion();

  return MyPoint(-5000.0f, -5000.0f);
}

bool MyObject::InSideScreen() {
  auto pMove = std::dynamic_pointer_cast<MoveCompent>(this->GetComponent(ECF_MOVE));
  if (pMove)
    return pMove->GetPostion().x_ > 10 &&
           pMove->GetPostion().x_ <
               CGameConfig::instance()->nDefaultWidth - 10 &&
           pMove->GetPostion().y_ > 10 &&
           pMove->GetPostion().y_ <
               CGameConfig::instance()->nDefaultHeight - 10;
  return false;
}

void MyObject::SetState(int st, MyObject* pobj) {
  ProcessCCEvent(EME_STATE_CHANGED, st, pobj);
  m_nState = st;
}

int MyObject::GetState() { return m_nState; }
