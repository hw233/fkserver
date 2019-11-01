#ifndef __FACTORY_CREATOR_H__
#define __FACTORY_CREATOR_H__

#include <algorithm>
#include <deque>
#include <list>
#include <map>
#include <memory>
#include "MyFunctor.h"

template <class _Ty>
class Creator {
 public:
  virtual ~Creator(){};
  virtual std::shared_ptr<_Ty> Create() = 0;
};

template <typename _Tb, class _Ty>
class Factory {
 protected:
  typedef typename std::map<_Tb, std::shared_ptr<Creator<_Ty>>> MapCreator;
  typedef typename std::map<_Tb, std::shared_ptr<Creator<_Ty>>>::iterator MapCreatorIterator;
  typedef typename std::deque<_Ty*> FreeDeque;
  typedef typename std::map<_Tb, FreeDeque> FreeMap;

  FreeMap m_FreeMap;
  MapCreator mapCreator;

  int m_nPoolSize;

 public:
  Factory() { m_nPoolSize = 1000; };
  virtual ~Factory() {
    mapCreator.clear();
  }

  //根据类型创建一个对象
  virtual std::shared_ptr<_Ty> Create(const _Tb& objType) {
    MapCreatorIterator it = mapCreator.find(objType);
    if (it != mapCreator.end()) return it->second->Create();

    return 0;
  }

  void Recovery(const _Tb& objType, std::shared_ptr<_Ty> obj) {
    obj.reset();
  }

  //注册一个类型
  void Register(const _Tb& objType, std::shared_ptr<Creator<_Ty> >& pCreator) {
    mapCreator[objType] = pCreator;

    return;
  }

  //初始化，可以重载此函数来注册类型
  virtual void Initialize(){};
};

#endif  //__FACTORY_CREATOR_H__
