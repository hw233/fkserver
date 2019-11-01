//
#ifndef __BUFFER_H__
#define __BUFFER_H__

#include "MyObject.h"
#include "common.h"

class CComEvent;

enum BUFFER_TYPE {
  EBT_NONE = 0,
  EBT_CHANGESPEED,    //改变速度
  EBT_DOUBLE_CANNON,  //双倍炮
  EBT_ION_CANNON,     //离子炮
  EBT_ADDMUL_BYHIT,   //被击吃子弹
};

class CBuffer {
 public:
  CBuffer();
  virtual ~CBuffer();

  BUFFER_TYPE GetType() { return m_BTP; }
  void SetType(BUFFER_TYPE b) { m_BTP = b; }

  float GetLife() { return m_fLife; }
  void SetLife(float f) { m_fLife = f; }

  virtual bool OnUpdate(int ms);

  virtual void OnCCEvent(std::shared_ptr<CComEvent>) =0;

  void SetParam(float p) { m_param = p; }

  virtual void Clear() {}

  virtual void SetOwner(std::shared_ptr<MyObject> pobj) { m_pOwner = pobj; }

 protected:
  BUFFER_TYPE m_BTP;   //类型
  float m_fLife;       //时间
  std::shared_ptr<MyObject> m_pOwner;  //寄主指针
  float m_param;       //值
};

class CSpeedBuffer : public CBuffer {
 public:
  CSpeedBuffer();
  virtual ~CSpeedBuffer();

  virtual void OnCCEvent(std::shared_ptr<CComEvent>);

  virtual void Clear();
};

class CDoubleCannon : public CBuffer {
 public:
  CDoubleCannon();

  virtual ~CDoubleCannon();

  virtual void Clear();

  virtual void OnCCEvent(std::shared_ptr<CComEvent>);

  virtual void SetOwner(std::shared_ptr<MyObject> pobj);
};

class CIonCannon : public CBuffer {
 public:
  CIonCannon();

  virtual ~CIonCannon();

  virtual void Clear();

  virtual void OnCCEvent(std::shared_ptr<CComEvent>);

  virtual void SetOwner(std::shared_ptr<MyObject> pobj);
};

class CAddMulByHit : public CBuffer {
 public:
  int nCurMul;

  CAddMulByHit();

  virtual ~CAddMulByHit();

  virtual void Clear();

  virtual void OnCCEvent(std::shared_ptr<CComEvent>);

  virtual void SetOwner(std::shared_ptr<MyObject> pobj);
};

#endif
