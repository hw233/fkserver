#ifndef __EFFECT_H__
#define __EFFECT_H__

#include <list>
#include <vector>
#include "common.h"

class MyObject;

enum EffectType {
  ETP_ADDMONEY = 0,  //增加金币
  ETP_KILL,          //杀死其它鱼
  ETP_ADDBUFFER,     //增加BUFFER
  ETP_PRODUCE,       //生成其它鱼
  ETP_BLACKWATER,    //乌贼喷墨汁效果
  ETP_AWARD,         //抽奖
};

class CEffect {
 public:
  CEffect();
  virtual ~CEffect();

  EffectType GetEffectType() { return m_nType; }
  void SetEffectType(EffectType etp) { m_nType = etp; }

  int GetParam(int pos);
  void SetParam(int pos, int p);

  void ClearParam();

  int GetParamSize() { return m_nParam.size(); }

  virtual int64_t Execute(MyObject* pSelf, MyObject* pTarget,
                            std::list<MyObject*>& list, bool bPretreating) = 0;

 protected:
  EffectType m_nType;
  std::vector<int> m_nParam;
};

//增加金币
//参数１为０时表示增加固定的金币数，参数２表示钱数
//参数１为１时表示增加一定倍数的钱数，参数２表示倍数
class CEffectAddMoney : public CEffect {
 public:
  CEffectAddMoney();
  virtual int64_t Execute(MyObject* pSelf, MyObject* pTarget,
                            std::list<MyObject*>& list, bool bPretreating);
  int64_t lSco;
};

//杀死杀死其它鱼
//参数１为０时表示杀死全部的鱼
//参数１为１时表示杀死指定范围内的鱼，参数２表示半径
//参数１为２时表示杀死指定类型的鱼，参数２表示指定类型
//参数１为３时表示杀死同一批次刷出来的鱼。
class CEffectKill : public CEffect {
 public:
  CEffectKill();
  virtual int64_t Execute(MyObject* pSelf, MyObject* pTarget,
                            std::list<MyObject*>& list, bool bPretreating);
};

//增加ＢＵＦＦ
//参数１表示要增加的ＢＵＦＦ的范围，
//０表示全部的鱼,１表示范围内的鱼,２表示指定类型的鱼
//参数１为１时表示杀死指定范围内的鱼，参数２表示半径;参数１为２时表示指定类型的鱼，参数２表示指定类型
//参数３表示要增加的ＢＵＦＦＥＲ类型
//参数４表示要增加的ＢＵＦＦＥＲ的参数
//参数５表示要增加的ＢＵＦＦＥＲ的时长
class CEffectAddBuffer : public CEffect {
 public:
  CEffectAddBuffer();
  virtual int64_t Execute(MyObject* pSelf, MyObject* pTarget,
                            std::list<MyObject*>& list, bool bPretreating);
};

//生成鱼
//参数１表示要生成的鱼的ＩＤ
//参数２表示要生成的鱼的批次
//参数３表示每个批次要生成的鱼的数量
//参数４表示每个批次之间的时间间隔
class CEffectProduce : public CEffect {
 public:
  CEffectProduce();
  virtual int64_t Execute(MyObject* pSelf, MyObject* pTarget,
                            std::list<MyObject*>& list, bool bPretreating);
};

//乌贼墨汁效果
class CEffectBlackWater : public CEffect {
 public:
  CEffectBlackWater();
  virtual int64_t Execute(MyObject* pSelf, MyObject* pTarget,
                            std::list<MyObject*>& list, bool bPretreating);
};

//抽奖效果展示
//参数１表示奖项, 0-7
//参数２表示实际效果 ０加金币　　１加ＢＵＦＦＥＲ
//参数３ 在加金币时　３为０表示加固定的钱，参数４表示钱的数量
//					 ３为１表示加倍返钱，参数４表示钱的倍数
//在加ＢＵＦＦＥＲ时　３表示ＢＵＦＦＥＲ类型　４表示ＢＵＦＦＥＲ时间
class CEffectAward : public CEffect {
 public:
  CEffectAward();
  virtual int64_t Execute(MyObject* pSelf, MyObject* pTarget,
                            std::list<MyObject*>& list, bool bPretreating);
};
#endif
