#ifndef __EFFECT_FACTORY_H__
#define __EFFECT_FACTORY_H__

#include "Effect.h"
#include "Factory.h"
#include "Singleton.h"

class EffectFactory : public Factory<int, CEffect>,
                      public Singleton<EffectFactory> {
public:
  EffectFactory();
  virtual ~EffectFactory();
  FriendBaseSingleton(EffectFactory);

 public:
  virtual std::shared_ptr<CEffect> Create(int effType);
};

template <class _Ty>
class EffectCreator : public Creator<CEffect> {
 public:
  virtual std::shared_ptr<_Ty> Create() { return std::make_shared<_Ty>(); }
};

#define REGISTER_EFFECT_TYPE(typeID, type)                           \
  {                                                                  \
    std::shared_ptr<Creator<CEffect> > ptr(new EffectCreator<type>()); \
    EffectFactory::instance()->Register(typeID, ptr);             \
  }

inline std::shared_ptr<CEffect> CreateEffect(int effType) {
  return EffectFactory::instance()->Create(effType);
}

#endif
