#ifndef __FISH_H__
#define __FISH_H__

#include "MyObject.h"

class CFish : public MyObject {
 public:
  CFish();
  virtual ~CFish();

  void SetBroadCast(bool bbc) { m_bBroadCast = bbc; }
  bool BroadCast() { return m_bBroadCast; }

  void SetBoundingBox(int n) { m_nBoundingBoxID = n; }
  int GetBoundingBoxID() { return m_nBoundingBoxID; }

  int GetLockLevel() { return m_nLockLevel; }
  void SetLockLevel(int n) { m_nLockLevel = n; }

  void SetName(const std::string& sn) {
    m_szName = sn;
  }

  const std::string& GetName() { return m_szName; }

  void SetFishType(int type) { m_FishType = type; }
  int GetFishType() { return m_FishType; }

  void SetRefershID(uint32_t id) { m_nRefershID = id; }
  uint32_t GetRefershID() { return m_nRefershID; }

 protected:
  bool m_bBroadCast;      // 可优
  int m_nBoundingBoxID;   // 绑定身体ID
  int m_nLockLevel;       // 锁定等级
  std::string m_szName;  // 可优
  int m_FishType;         // 鱼类型
  uint32_t m_nRefershID;  // 刷新ID
};

#endif
