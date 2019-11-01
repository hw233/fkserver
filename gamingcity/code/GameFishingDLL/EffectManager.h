#ifndef __EFFECT_MANAGER_H__
#define __EFFECT_MANAGER_H__

#include <list>
#include "Effect.h"
#include "MyComponent.h"
#include <stdint.h>

enum EEffectMgrComType {
  EECT_MGR = (ECF_EFFECTMGR << 8),
};

class EffectMgr : public MyComponent {
 public:
  EffectMgr();
  virtual ~EffectMgr();

  const uint32_t GetFamilyID() const { return ECF_EFFECTMGR; }

  void Add(CEffect* pObj);
  void Clear();
  template<class T1,class T2>
  int64_t Execute(std::shared_ptr<T1> pTarget, std::list<std::shared_ptr<T2>>& list,
                    bool bPretreating);

  virtual void OnDetach() { Clear(); }

 protected:
  typedef std::list<CEffect*> obj_table_t;
  typedef obj_table_t::iterator obj_table_iter;

  obj_table_t m_effects;
};

#endif
