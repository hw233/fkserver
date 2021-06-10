#include "Bullet.h"
#include "GameConfig.h"
#include "MathAide.h"
#include "MoveCompent.h"
#include "common.h"

CBullet::CBullet()
    : m_nMaxCatch(1),
      m_nCatchRadio(50),
      m_nCannonType(0),
      m_wChairID(0),
      m_nSize(20),
      m_bDouble(false)
{
  SetObjType(EOT_BULLET);
}

CBullet::~CBullet() { ProbabilitySet.clear(); }

void CBullet::AddProbilitySet(int ftp, float pp) { ProbabilitySet[ftp] = pp; }

float CBullet::GetProbilitySet(int ftp) {
  std::map<int, float>::iterator it = ProbabilitySet.find(ftp);
  if (it != ProbabilitySet.end()) return it->second;

  return MAX_PROBABILITY;
}

void CBullet::OnUpdate(int msElapsed) { MyObject::OnUpdate(msElapsed); }

bool CBullet::HitTest(std::shared_ptr<CFish> pFish) {
  if (pFish != NULL && pFish->GetState() < EOS_DEAD) {
    MyPoint pos;
    auto pMove = this->GetComponent<MoveCompent>(ECF_MOVE);
    if (pMove != NULL) {
      if (pMove->GetTargetID() != 0 && pFish->GetId() != pMove->GetTargetID())
        return false;

      pos = GetPosition();
    }

    MyPoint fpos = pFish->GetPosition();
    float fdir = pFish->GetDirection();
    int bdx = pFish->GetBoundingBoxID();
    std::map<int, BBX>::iterator it = CGameConfig::instance()->BBXMap.find(bdx);
    if (it != CGameConfig::instance()->BBXMap.end()) {
      BBX& bx = it->second;
      std::list<BB>::iterator ib = bx.BBList.begin();
      while (ib != bx.BBList.end()) {
        MyPoint bps = CMathAide::GetRotationPosByOffest(
            fpos.x_, fpos.y_, ib->nOffestX, ib->nOffestY, fdir);

        if (CMathAide::CalcDistance(bps.x_, bps.y_, pos.x_, pos.y_) <
            ib->fRadio + GetSize())
          return true;

        ++ib;
      }
    }
  }

  return false;
}

//无使用记录
bool CBullet::NetCatch(std::shared_ptr<CFish> pFish) {
  if (pFish != NULL && pFish->GetState() < EOS_DEAD) {
    MyPoint pos = GetPosition();
    auto pMove = this->GetComponent<MoveCompent>(ECF_MOVE);
    if (pMove != NULL) {
      if (pMove->GetTargetID() != 0 && pFish->GetId() != pMove->GetTargetID())
        return false;

      pos = GetPosition();
    }

    MyPoint fpos = pFish->GetPosition();
    float fdir = pFish->GetDirection();
    int bdx = pFish->GetBoundingBoxID();

    std::map<int, BBX>::iterator it = CGameConfig::instance()->BBXMap.find(bdx);
    if (it != CGameConfig::instance()->BBXMap.end()) {
      BBX& bx = it->second;
      std::list<BB>::iterator ib = bx.BBList.begin();
      while (ib != bx.BBList.end()) {
        MyPoint bps = CMathAide::GetRotationPosByOffest(
            fpos.x_, fpos.y_, ib->nOffestX, ib->nOffestY, fdir);

        if (CMathAide::CalcDistance(bps.x_, bps.y_, pos.x_, pos.y_) <
            GetCatchRadio() + ib->fRadio)
          return true;

        ++ib;
      }
    }
  }

  return false;
}
