#include "MyObjectFactory.h"
#include "IDGenerator.h"

SingletonInstance(MyObjFactory);

MyObjFactory::MyObjFactory() { m_nPoolSize = 10003; }

MyObjFactory::~MyObjFactory() {}

std::shared_ptr<MyObject> MyObjFactory::Create(int objType) {
  auto obj = Factory<int, MyObject>::Create(objType);
  if (obj) {
    obj->SetObjType(objType);
    obj->SetId(IDGenerator::instance()->GetID64());
    obj->SetCreateTick(timeGetTime());
  }
  return obj;
}
