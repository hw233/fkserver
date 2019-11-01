#include "MyObjectManager.h"
#include <algorithm>
#include "MyObjectFactory.h"
#include "common.h"

MyObjMgr::MyObjMgr() {}

MyObjMgr::~MyObjMgr() { Clear(); }

void MyObjMgr::Lock(void) { m_lock.lock(); }

void MyObjMgr::Unlock(void) { m_lock.unlock(); }

template<class T>
std::shared_ptr<T> MyObjMgr::Find(uint32_t nID) {
  std::lock_guard<std::recursive_mutex> l(m_lock);
  obj_table_iter it = m_mapObject.find(nID);
  if (it != m_mapObject.end()) {
    return std::dynamic_pointer_cast<T>(it->second);
  }

  return 0;
}

template<class T>
void MyObjMgr::Add(std::shared_ptr<T> pObj) {
  if (!pObj) {
    return;
  }

  std::lock_guard<std::recursive_mutex> l(m_lock);
  pObj->SetMgr(this);
  m_mapObject[pObj->GetId()] = std::dynamic_pointer_cast<T>(pObj);
}

template<class T>
void MyObjMgr::Remove(std::shared_ptr<T> pObj) { Remove(pObj->GetId()); }

void MyObjMgr::Remove(uint32_t nID) {
  std::lock_guard<std::recursive_mutex> l(m_lock);
  obj_table_iter it = m_mapObject.find(nID);
  if (it != m_mapObject.end()) {
    auto pObj = it->second;
    m_mapObject.erase(it);
    pObj->ClearComponent();
    MyObjFactory::instance()->Recovery(pObj->GetObjType(), pObj);
  }
}

obj_table_iter MyObjMgr::Begin() { return m_mapObject.begin(); }

obj_table_iter MyObjMgr::End() { return m_mapObject.end(); }

void MyObjMgr::OnUpdate(uint32_t ms) {
  for (obj_table_iter it = m_mapObject.begin(); it != m_mapObject.end(); ++it) {
    (it->second)->OnUpdate(ms);
  }
}

void MyObjMgr::Clear() {
  std::lock_guard<std::recursive_mutex> l(m_lock);
  for (obj_table_iter it = m_mapObject.begin(); it != m_mapObject.end(); ++it) {
    it->second->ClearComponent();
    MyObjFactory::instance()->Recovery((it->second)->GetObjType(), it->second);
  }
  m_mapObject.clear();
}

int MyObjMgr::CountObject() {
  std::lock_guard<std::recursive_mutex> l(m_lock);
  return m_mapObject.size();
}
