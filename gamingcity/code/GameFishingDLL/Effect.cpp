#include "Effect.h"
#include "BufferManager.h"
#include "Bullet.h"
#include "EffectManager.h"
#include "EventMgr.h"
#include "GameConfig.h"
#include "MathAide.h"
#include "MoveCompent.h"
#include "MyObjectManager.h"
#include "Player.h"
#include "common.h"
#include "RandomHelper.h"

CEffect::CEffect() : m_nType(ETP_ADDMONEY) {
  m_nParam.resize(2);
  ClearParam();
}

CEffect::~CEffect() {}

void CEffect::ClearParam() {
  for (int i = 0; i < m_nParam.size(); ++i) {
    m_nParam[i] = 0;
  }
}

int CEffect::GetParam(int pos) {
  if (pos >= m_nParam.size()) return 0;

  return m_nParam[pos];
}

void CEffect::SetParam(int pos, int p) {
  if (pos > m_nParam.size()) return;

  m_nParam[pos] = p;
}

CEffectAddMoney::CEffectAddMoney() : CEffect() {
  m_nParam.resize(3);
  ClearParam();
  lSco = 0;
}
int64_t CEffectAddMoney::Execute(MyObject* pSelf, MyObject* pTarget,
                                 std::list<MyObject*>& list,
                                 bool bPretreating) {
  if (pSelf == 0) return 0;

  int64_t lScore = 0;
  int mul = 1;

  //鱼的倍数
  if (lSco == 0) {
    lSco = GetParam(2) > GetParam(1) ? RandomHelper::rand<int>(GetParam(1), GetParam(2))
                                     : GetParam(1);
  }

  if (GetParam(0) == 0) {
    mul = 1;
  } else if (pTarget != 0) {
    //子弹的价格不参与鱼打爆概率计算
    // mul = pTarget->GetScore();
  }

  int n = -1;
  auto se = std::make_shared<CComEvent>();
  se->SetID(EME_QUERY_ADDMUL);
  se->SetParam1(0);
  se->SetParam2(&n);
  pSelf->ProcessCCEvent(se);

  if (n != -1) {
    lSco = CGameConfig::instance()->nAddMulBegin;

    if (n + lSco > GetParam(2)) n = GetParam(2) - lSco;

    if (!bPretreating) CGameConfig::instance()->nAddMulCur = 0;
  } else
    n = 0;

  lScore = (lSco + n) * mul;

  if (pTarget->GetObjType() == EOT_BULLET && ((CBullet*)pTarget)->bDouble())
    lScore *= 2;

  return lScore;
}

CEffectKill::CEffectKill() : CEffect() {
  m_nParam.resize(3);
  ClearParam();
}

int64_t CEffectKill::Execute(std::shared_ptr<MyObject> pSelf, std::shared_ptr<MyObject> pTarget,
                             std::list<std::shared_ptr<MyObject>>& list, bool bPretreating) {
  if (pSelf == 0) return 0;

  int64_t score = 0;

  if (!bPretreating) {
    RaiseEvent("AddChain", this, pSelf);  //无处理对应
  }

  auto pMgr = pSelf->GetMgr();
  if (pMgr != 0) {
    pMgr->Lock();
    for (obj_table_iter ifs = pMgr->Begin(); ifs != pMgr->End(); ++ifs) {
      auto pObj = ifs->second;
      if (pObj == pSelf) {
        continue;
      }

      auto pEm = pObj->GetComponent<EffectMgr>(ECF_EFFECTMGR);
      auto pMove = pObj->GetComponent<MoveCompent>(ECF_MOVE);
      if (pEm == 0 || pMove == 0) {
        continue;
      }

      if (GetParam(0) == 0 && pObj->InSideScreen() &&
          pMove->HasBeginMove())  //参数１为０时表示杀死全部的鱼
      {
        score += pEm->Execute(pTarget, list, bPretreating);
      } else if (
          GetParam(0) == 1 && pObj->InSideScreen() &&
          pMove
              ->HasBeginMove())  //参数１为１时表示杀死指定范围内的鱼，参数２表示半径
      {
        if (CMathAide::CalcDistance(pSelf->GetPosition().x_,
                                    pSelf->GetPosition().y_,
                                    pObj->GetPosition().x_,
                                    pObj->GetPosition().y_) <= GetParam(1)) {
          score += pEm->Execute(pTarget, list, bPretreating);
        }
      } else if (
          GetParam(0) == 2 && pObj->InSideScreen() &&
          pMove
              ->HasBeginMove())  //参数１为２时表示杀死指定类型的鱼，参数２表示指定类型
      {
        if (pObj->GetTypeID() == GetParam(1) &&
            std::dynamic_pointer_cast<CFish>(pObj)->GetFishType() == ESFT_NORMAL) {
          score += pEm->Execute(pTarget, list, bPretreating);
        }
      } else if (GetParam(0) == 3)  //参数１为３时表示杀死同一批次刷出来的鱼。
      {
        if (std::dynamic_pointer_cast<CFish>(pObj)->GetRefershID() == std::dynamic_pointer_cast<CFish>(pSelf)->GetRefershID()) {
          score += pEm->Execute(pTarget, list, bPretreating);
        }
      }
    }
    pMgr->Unlock();
  }

  if (score / pTarget->GetScore() > GetParam(2)) {
    score = pTarget->GetScore() * GetParam(2);
  }

  return score;
}

CEffectAddBuffer::CEffectAddBuffer() : CEffect() {
  m_nParam.resize(5);
  ClearParam();
}

int64_t CEffectAddBuffer::Execute(std::shared_ptr<MyObject> pSelf, std::shared_ptr<MyObject> pTarget,
                                  std::list<std::shared_ptr<MyObject>>& list,
                                  bool bPretreating) {
  if (pSelf == 0 || bPretreating) return 0;

  RaiseEvent("AddBuffer", this, pSelf);

  auto pMgr = pSelf->GetMgr();
  if (pMgr != 0) {
    for (obj_table_iter ifs = pMgr->Begin(); ifs != pMgr->End(); ++ifs) {
      auto pObj = ifs->second;

      if (pObj == pSelf /* && pObj->InSideScreen()*/) {
        continue;
      }

      auto pBM = pObj->GetComponent<BufferMgr>(ECF_BUFFERMGR);
      if (!pBM) {
        continue;
      }

      if (GetParam(0) == 0)  //参数１为０时表示全部的鱼
      {
        pBM->Add(GetParam(2), GetParam(3), GetParam(4));
      } else if (GetParam(0) ==
                 1)  //参数１为１时表示指定范围内的鱼，参数２表示半径
      {
        if (CMathAide::CalcDistance(pSelf->GetPosition().x_,
                                    pSelf->GetPosition().y_,
                                    pObj->GetPosition().x_,
                                    pObj->GetPosition().y_) <= GetParam(1)) {
          pBM->Add(GetParam(2), GetParam(3), GetParam(4));
        }
      } else if (GetParam(0) ==
                 2)  //参数１为２时表示指定类型的鱼，参数２表示指定类型
      {
        if (pObj->GetTypeID() == GetParam(1)) {
          pBM->Add(GetParam(2), GetParam(3), GetParam(4));
        }
      }
    }
  }

  return 0;
}

CEffectProduce::CEffectProduce() : CEffect() {
  m_nParam.resize(4);
  ClearParam();
}

int64_t CEffectProduce::Execute(std::shared_ptr<MyObject> pSelf, std::shared_ptr<MyObject> pTarget,
                                std::list<std::shared_ptr<MyObject>>& list, bool bPretreating) {
  if (pSelf == 0 || bPretreating) return 0;

  RaiseEvent("ProduceFish", this, pSelf);

  return 0;
}

CEffectBlackWater::CEffectBlackWater() : CEffect() {
  m_nParam.resize(0);
  m_nParam.clear();
}

int64_t CEffectBlackWater::Execute(std::shared_ptr<MyObject> pSelf, std::shared_ptr<MyObject> pTarget,
                                   std::list<std::shared_ptr<MyObject>>& list,
                                   bool bPretreating) {
  if (pSelf == 0 || bPretreating) return 0;

  RaiseEvent("BlackWater", this, pSelf);

  return 0;
}

CEffectAward::CEffectAward() {
  m_nParam.resize(4);
  ClearParam();
}

int64_t CEffectAward::Execute(std::shared_ptr<MyObject> pSelf, std::shared_ptr<MyObject> pTarget,
                              std::list<std::shared_ptr<MyObject>>& list, bool bPretreating) {
  if (pSelf == 0) return 0;

  int64_t lScore = 0;
  //如果是预处理，且 是增加金钱操作
  if (GetParam(1) == 0 && bPretreating) {
    if (GetParam(2) == 0)
      lScore = GetParam(3);
    else if (pTarget != 0)
      lScore = pTarget->GetScore() * GetParam(3);
  }
  //不是欲处理 则增加事件
  if (!bPretreating) RaiseEvent("AdwardEvent", this, pSelf, pTarget);

  return lScore;
}