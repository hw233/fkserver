#include "MyComponent.h"
#include "MyObject.h"

void MyComponent::RaiseEvent(std::shared_ptr<CComEvent> pEvent) {
  pEvent->SetSender(this);
  GetOwner()->ProcessCCEvent(pEvent);
}

void MyComponent::RaiseEvent(uint32_t idEvent, int64_t nParam1, void* pParam2) {
  auto se = std::make_shared<CComEvent>();
  se->SetID(idEvent);
  se->SetParam1(nParam1);
  se->SetParam2(pParam2);
  se->SetSender(this);

  GetOwner()->ProcessCCEvent(se);
}

void MyComponent::PostEvent(std::shared_ptr<CComEvent>& evnt) {
  evnt->SetSender(this);
  GetOwner()->PushCCEvent(evnt);
}

void MyComponent::PostEvent(uint32_t idEvent, int64_t nParam1, void* pParam2) {
  CComEvent* pEvent = new CComEvent;
  pEvent->SetID(idEvent);
  pEvent->SetParam1(nParam1);
  pEvent->SetParam2(pParam2);
  pEvent->SetSender(this);

  std::shared_ptr<CComEvent> autoDel(pEvent);
  GetOwner()->PushCCEvent(autoDel);
}
