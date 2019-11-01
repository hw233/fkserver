#ifndef __COMMON_LOGIC_H__
#define __COMMON_LOGIC_H__

#include "Bullet.h"
#include "Fish.h"
#include "GameConfig.h"

class CommonLogic {
 public:
  static std::shared_ptr<CFish> CreateFish(Fish& finf, float x, float y, float dir, float delay,
                           int speed, int pathid, bool bTroop = false,
                           int ft = ESFT_NORMAL);

  static std::shared_ptr<CBullet> CreateBullet(Bullet binf, const MyPoint& pos,
                               float fDirection, int CannonType, int CannonMul,
                               bool bForward = false);

  static int64_t GetFishEffect(std::shared_ptr<CBullet> pBullet, std::shared_ptr<CFish> pFish,
                                 std::list<std::shared_ptr<MyObject>>& list,
                                 bool bPretreating = false);

  static const char* ReplaceString(unsigned int wChairID, std::string& str);
};

#endif
