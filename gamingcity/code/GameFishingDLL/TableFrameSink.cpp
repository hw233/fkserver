//
#include "TableFrameSink.h"
#include <math.h>
#include "BufferManager.h"
#include "CommonLogic.h"
#include "EventMgr.h"
#include "GameConfig.h"
#include "GameLog.h"
#include "IDGenerator.h"
#include "LuaRuntime.h"
#include "MathAide.h"
#include "MyComponentFactory.h"
#include "PathManager.h"
#include "RandomHelper.h"
#include "common.h"

#include <codecvt>
#include <iostream>

#define IDI_GAMELOOP 1
#define TIME_GAMELOOP 1000 / GAME_FPS
#define MAX_LIFE_TIME 30000

//构造函数
CTableFrameSink::CTableFrameSink() : m_cell_money(1) {
  m_nFishCount = 0;
  ResetTable();
  // m_L = lua_newthread(LuaRuntime::instance()->LuaState());
}

//析构函数
CTableFrameSink::~CTableFrameSink(void) { ResetTable(); }

//初始化
bool CTableFrameSink::Initialization(table luaTable) {
  m_TableID = luaTable["table_id_"];
  table room = luaTable["room_"];
  m_RoomID = room["id"];
  m_cell_money = room["cell_score_"];
  m_tax = room["tax_"];
  m_tax_show = room["tax_show_"];

  Bind_Event_Handler("ProduceFish", CTableFrameSink, OnProduceFish);
  Bind_Event_Handler("CannonSetChanaged", CTableFrameSink, OnCannonSetChange);
  Bind_Event_Handler("AddBuffer", CTableFrameSink, OnAddBuffer);
  Bind_Event_Handler("CatchFishBroadCast", CTableFrameSink,
                     OnCatchFishBroadCast);
  Bind_Event_Handler("FirstFire", CTableFrameSink, OnFirstFire);
  Bind_Event_Handler("AdwardEvent", CTableFrameSink, OnAdwardEvent);
  Bind_Event_Handler("FishMulChange", CTableFrameSink, OnMulChange);

  m_UserWinScore.clear();

  return true;
}

void CTableFrameSink::UpdateConfig(int cell_money, int tax, int tax_show) {
  m_cell_money = cell_money;
  m_tax = tax;
  m_tax_show = tax_show;
}

float CTableFrameSink::get_room_bullet_cell_money() {
  return ((float)m_cell_money) /
         CGameConfig::instance()->BulletVector.back().nMulriple;
}

int CTableFrameSink::getRoomWeight() {
  return lua_tinker::call<int>(LuaRuntime::instance()->LuaState(),
                               "get_room_weight");
}

int CTableFrameSink::getFishWeight(std::shared_ptr<CFish> pFish) {
  int typeID = pFish->GetTypeID();
  int fishType = pFish->GetFishType();

  return lua_tinker::call<int>(LuaRuntime::instance()->LuaState(),
                               "get_fish_weight", fishType, typeID);
}

int CTableFrameSink::getPlayerWeight(int guid) {
  int ratio = lua_tinker::call<int>(LuaRuntime::instance()->LuaState(),
                                    "get_player_weight", guid);
  return ratio;
}

void CTableFrameSink::LoadConfig() {
  // std::string config_path_name = lua_tinker::call<char*>(
  //     LuaRuntime::instance()->LuaState(), "get_fishing_config_dir_name");

  // std::string path = "../data/" + config_path_name + "/";

  std::cout << "开始加载配置 ......" << std::endl;
  uint32_t dwStartTick = timeGetTime();

  std::cout << "LoadSystemConfig" << std::endl;
  CGameConfig::instance()->LoadSystemConfig(LuaRuntime::instance()->LuaState());

  std::cout << "LoadBoundBox" << std::endl;
  CGameConfig::instance()->LoadBoundBox(LuaRuntime::instance()->LuaState());

  std::cout << "LoadFish" << std::endl;
  CGameConfig::instance()->LoadFish(LuaRuntime::instance()->LuaState());

  std::cout << "LoadNormalPath" << std::endl;
  PathManager::instance()->LoadNormalPath(LuaRuntime::instance()->LuaState());

  std::cout << "LoadTroop" << std::endl;
  PathManager::instance()->LoadTroop(LuaRuntime::instance()->LuaState());

  std::cout << "LoadCannonSet" << std::endl;
  CGameConfig::instance()->LoadCannonSet(LuaRuntime::instance()->LuaState());

  std::cout << "LoadBulletSet" << std::endl;
  CGameConfig::instance()->LoadBulletSet(LuaRuntime::instance()->LuaState());

  std::cout << "LoadScenes" << std::endl;
  CGameConfig::instance()->LoadScenes(LuaRuntime::instance()->LuaState());

  std::cout << "LoadSpecialFish" << std::endl;
  CGameConfig::instance()->LoadSpecialFish(LuaRuntime::instance()->LuaState());

  dwStartTick = timeGetTime() - dwStartTick;
  std::cout << "加载完成 总计耗时" << dwStartTick / 1000.f << "秒" << std::endl;
}

//重置桌子
void CTableFrameSink::ResetTable() {
  m_FishManager->Clear();
  m_BulletManager->Clear();
  m_fPauseTime = 0.0f;
  m_nSpecialCount = 0;
  m_nFishCount = 0;
  m_ChairPlayers.clear();
  m_GuidPlayers.clear();
}

//用户坐下
bool CTableFrameSink::OnActionUserSitDown(int wChairID, table player) {
  int Guid = player.get<int>("guid");
  if (Guid <= 0) {
    return false;
  }

  std::cout << "CTableFrameSink::OnActionUserSitDown:" << wChairID << std::endl;
  m_GuidPlayers[Guid]->ClearSet(wChairID);
  m_GuidPlayers[Guid]->FromLua(player);
  m_ChairPlayers[wChairID] = &m_GuidPlayers[Guid];

  m_UserWinScore[wChairID] = 0;

  //循环类型
  int mul = CGameConfig::instance()->BulletVector.size() - 1;
  m_GuidPlayers[Guid]->SetMultiply(mul);

  int CannonType = CGameConfig::instance()->BulletVector[mul].nCannonType;
  //设置炮
  m_GuidPlayers[Guid]->SetCannonType(CannonType);

  //获取BUFF管理器
  auto pBMgr = m_GuidPlayers[Guid]->GetComponent<EffectMgr>(ECF_BUFFERMGR);
  if (pBMgr) {
    pBMgr = CreateComponent<EffectMgr>();
    if (pBMgr) {
      m_GuidPlayers[Guid]->SetComponent(pBMgr);
    }
  }

  if (!pBMgr) {
    return false;
  }

  pBMgr->Clear();
  return true;
}

//用户起立
bool CTableFrameSink::OnActionUserStandUp(uint32_t Guid, int wChairID,
                                          bool is_offline) {
  // 更新用户金币日志到数据库
  ReturnBulletScore(Guid);

  m_UserWinScore[wChairID] = 0;

  auto iterChair = m_ChairPlayers.find(wChairID);
  if (iterChair != m_ChairPlayers.end()) {
    m_ChairPlayers.erase(iterChair);
  }

  auto iterGuid = m_GuidPlayers.find(Guid);
  if (iterGuid != m_GuidPlayers.end()) {
    m_GuidPlayers.erase(iterGuid);
  }

  if (m_GuidPlayers.empty()) {
    ResetTable();
  }

  ClearBullets(wChairID);

  return true;
}

//游戏开始
bool CTableFrameSink::OnEventGameStart() {
  ResetTable();

  m_dwLastTick = timeGetTime();

  m_nCurScene = CGameConfig::instance()->SceneSets.begin()->first;
  m_fSceneTime = 0.0f;
  m_fPauseTime = 0.0f;
  m_bAllowFire = false;

  ResetSceneDistrub();

  //初始化随机种子
  srand(timeGetTime());

  return true;
}
//重置场景
void CTableFrameSink::ResetSceneDistrub() {
  //重置干扰鱼群刷新时间
  int sn =
      CGameConfig::instance()->SceneSets[m_nCurScene].DistrubList.size();
  m_vDistrubFishTime.resize(sn);
  for (int i = 0; i < sn; ++i) {
    m_vDistrubFishTime[i] = 0;
  }

  //重置鱼群
  //获取场景刷新鱼时间组数
  sn = CGameConfig::instance()->SceneSets[m_nCurScene].TroopList.size();
  m_vDistrubTroop.resize(sn);  //设置刷新鱼信息大小
  //初始化刷新信息
  for (int i = 0; i < sn; ++i) {
    m_vDistrubTroop[i].bSendDes = false;
    m_vDistrubTroop[i].bSendTroop = false;
    m_vDistrubTroop[i].fBeginTime = 0.0f;
  }
}

//结束原因
#define GER_NORMAL 0x00         //常规结束
#define GER_DISMISS 0x01        //游戏解散
#define GER_USER_LEAVE 0x02     //用户离开
#define GER_NETWORK_ERROR 0x03  //网络错误

//游戏结束
bool CTableFrameSink::OnEventGameConclude(uint32_t Guid, int wChairID,
                                          uint8_t cbReason) {
  if (!HasPlayer(Guid, wChairID)) {
    return true;
  }

  switch (cbReason) {
    case GER_NORMAL:
    case GER_USER_LEAVE:
    case GER_NETWORK_ERROR: {
      //单个玩家，网络退出
      // ReturnBulletScore(Guid);
      m_GuidPlayers[Guid]->ClearSet(wChairID);
      return true;
    }
    case GER_DISMISS: {  //所有玩家退出 清除所有信息
      for (auto& iter : m_ChairPlayers) {
        iter.second->ClearSet(iter.first - 1);
      }
      return true;
    }
  }
  return false;
}

//发送场景
bool CTableFrameSink::OnEventSendGameScene(uint32_t GuID, int wChairID,
                                           uint8_t cbGameStatus,
                                           bool bSendSecret) {
  if (!HasPlayer(GuID, wChairID)) {
    return false;
  }

  switch (cbGameStatus) {
    case GAME_STATUS_FREE:
    case GAME_STATUS_PLAY: {
      SendGameConfig(GuID);
      SendPlayerInfo(0);
      SendAllowFire(0);
      for (auto& iter : m_ChairPlayers) {
        SendCannonSet(iter.first);
      }

      char szInfo[1024] = {0};
      sprintf(szInfo, "当前房间的游戏币与渔币的兑换比例为%d游戏币兑换%d渔币",
                CGameConfig::instance()->nChangeRatioUserScore,
                CGameConfig::instance()->nChangeRatioFishScore);

      SendSystemMsg(GuID, SMT_CHAT, szInfo);

      return true;
    }
  }
  return false;
}

bool CTableFrameSink::OnReady(int wChairID) {
  if (!HasPlayer(0, wChairID)) {
    return false;
  }

  SendFishList(wChairID);
  return true;
}

//发送游戏系统配置
void CTableFrameSink::SendGameConfig(int guid) {
  {
    lua_tinker::table msg(LuaRuntime::instance()->LuaState());
    msg.set("server_id",1);
    msg.set("change_ratio_fish_score",CGameConfig::instance()->nChangeRatioFishScore);
    msg.set("change_ratio_user_score",
        CGameConfig::instance()->nChangeRatioUserScore);
    msg.set("exchange_once",CGameConfig::instance()->nExchangeOnce);
    msg.set("fire_interval",CGameConfig::instance()->nFireInterval);
    msg.set("max_interval",CGameConfig::instance()->nMaxInterval);
    msg.set("min_interval",CGameConfig::instance()->nMinInterval);
    msg.set("show_gold_min_mul",CGameConfig::instance()->nShowGoldMinMul);
    msg.set("max_bullet_count",CGameConfig::instance()->nMaxBullet);
    msg.set("max_cannon",CGameConfig::instance()->m_MaxCannon);

    SendTo(guid,"SC_GameConfig", msg);
  }

  // 可优 子弹配置？ 配置数据不需要发送
  {
    lua_tinker::table msg(LuaRuntime::instance()->LuaState());
    lua_tinker::table pb_bullets(LuaRuntime::instance()->LuaState());
    
    int i = 0;
    for (auto& iter : CGameConfig::instance()->BulletVector) {
      lua_tinker::table pMsgUnit(LuaRuntime::instance()->LuaState());
      pMsgUnit.set("first",(i == 0 ? 1 : 0));
      pMsgUnit.set("bullet_size",(iter.nBulletSize));
      pMsgUnit.set("cannon_type",(iter.nCannonType));
      pMsgUnit.set("catch_radio",(iter.nCatchRadio));
      pMsgUnit.set("max_catch",(iter.nMaxCatch));
      pMsgUnit.set("mulriple",(iter.nMulriple * m_cell_money / 100.f));
      pMsgUnit.set("speed",(iter.nSpeed));
      pb_bullets.seti(i++,pMsgUnit);
    }

    msg.set("pb_bullets",pb_bullets);

    SendTo(guid,"SC_BulletSet_List", msg);
  }
}

void CTableFrameSink::SendSystemMsg(int guid, int type,
                                    const std::string& msg) {
  // std::wstring_convert<std::codecvt<wchar_t, char, mbstate_t>> mb_conv_ucs;
  // std::wstring test = mb_conv_ucs.from_bytes(msg);

  // std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
  // std::string narrowStr = conv.to_bytes(test);

  // CAutoLock cl(g_LuaLock);
  // table table(LuaRuntime::instance()->LuaState());
  // table.set("wType", SMT_CHAT);
  // table.set("szString", narrowStr.c_str());
  // SendTo(guid, "SC_SystemMessage", table);
}

//发送玩家信息
void CTableFrameSink::SendPlayerInfo(int TargetGuid) {
  for (auto iter : m_ChairPlayers) {
    lua_tinker::table msg(LuaRuntime::instance()->LuaState());
    msg.set("chair_id",(iter.first));
    msg.set("score",(iter.second->GetScore()));
    msg.set("cannon_mul",(iter.second->GetMultiply()));
    msg.set("cannon_type",(iter.second->GetCannonType()));
    msg.set("wastage",(iter.second->GetWastage()));
    SendTo(TargetGuid,"SC_UserInfo", msg);
  }
}

//发送场景信息
void CTableFrameSink::SendSceneInfo(int GuID) {
  int wChairID = m_GuidPlayers[GuID]->GetChairID();

  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("switching",0);
  msg.set("nst",m_nCurScene);
  SendTo(GuID,"SC_SwitchScene", msg);

  m_BulletManager->Lock();
  for (auto iter = m_BulletManager->Begin(); iter != m_BulletManager->End();
       ++iter) {
    SendBullet(std::dynamic_pointer_cast<CBullet>(iter->second));
  }
  m_BulletManager->Unlock();

  m_FishManager->Lock();
  for (auto iter = m_FishManager->Begin(); iter != m_FishManager->End(); ++iter) {
    SendFish(std::dynamic_pointer_cast<CFish>(iter->second), wChairID);
  }
  m_FishManager->Unlock();
}

//发送是否允许开火
void CTableFrameSink::SendAllowFire(int GuID) {
  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("allow_fire",(m_bAllowFire ? 1 : 0));
  SendTo(GuID,"SC_AllowFire", msg);
}

//游戏状态更新
void CTableFrameSink::OnGameUpdate() {
  uint32_t NowTime = timeGetTime();
  int ndt = NowTime - m_dwLastTick;
  float fdt = ndt / 1000.0f;

  bool hasR = HasRealPlayer();

  for (auto& iter : m_ChairPlayers) {
    if (iter.second->GetGuid() == 0) {
      continue;
    }

    //处理玩家事件
    iter.second->OnUpdate(ndt);
    //有玩家存在且玩家锁定了鱼
    if (iter.second->bLocking()) {
      //当玩家锁定鱼时判断鱼ID，是否存在
      if (iter.second->GetLockFishID() == 0) {
        // ID= 0 重新锁定
        LockFish(iter.second->GetChairID());
        if (iter.second->GetLockFishID() == 0) {
          iter.second->SetLocking(false);
        }
      } else {
        auto pFish = m_FishManager->Find<CFish>(iter.second->GetLockFishID());
        if (pFish == NULL ||
            !pFish->InSideScreen()) {  //当鱼不存在或鱼已经出屏幕，重新锁定
          LockFish(iter.second->GetChairID());
          if (iter.second->GetLockFishID() == 0) {
            iter.second->SetLocking(false);
          }
        }
      }
    }
  }
  //清理可锁定列表
  m_CanLockList.clear();
  //清理鱼数量
  m_nFishCount = 0;

  //移除队列
  std::list<uint32_t> rmList;
  //特殊鱼清0
  m_nSpecialCount = 0;

  m_FishManager->Lock();

  for (obj_table_iter ifs = m_FishManager->Begin(); ifs != m_FishManager->End();
       ++ifs) {
    auto pFish = std::dynamic_pointer_cast<CFish>(ifs->second);
    //处理鱼事件
    pFish->OnUpdate(ndt);
    auto pMove = pFish->GetComponent(ECF_MOVE);
    if (pMove == NULL || pMove->IsEndPath()) {  //移动组件为空或 已经移动到结束
      if (pMove != NULL && pFish->InSideScreen()) {  //移动组件存且移动结束，但还在屏幕内
                                                     //改为按指定方向移动
        auto pMove2 = CreateComponent(EMCT_DIRECTION);
        if (pMove2) {
          pMove2->SetSpeed(pMove->GetSpeed());
          pMove2->SetDirection(pMove->GetDirection());
          pMove2->SetPosition(pMove->GetPostion());
          pMove2->InitMove();
          // SetComponent有清除旧组件功能
          pFish->SetComponent(pMove2);
        }
      } else {  //否则添加到移除列表
        rmList.push_back(pFish->GetId());
      }
    } else if (pFish->GetFishType() !=
               ESFT_NORMAL) {  //钱类型不等于普通鱼 特殊鱼+1
      ++m_nSpecialCount;
    }

    if (hasR && pFish->InSideScreen()) {
      //还在屏幕内
      if (pFish->GetLockLevel() > 0) {  //锁定等级大于0 加入可锁定列表
        m_CanLockList.push_back(pFish->GetId());
      }

      //鱼数量+1
      ++m_nFishCount;
    }
  }

  m_FishManager->Unlock();

  //清除鱼

  for (std::list<uint32_t>::iterator it = rmList.begin(); it != rmList.end();
       it++) {
    lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),
                           "on_fish_removed", m_RoomID, m_TableID, *it);
    m_FishManager->Remove(*it);
  }

  rmList.clear();

  m_BulletManager->Lock();
  for (obj_table_iter ibu = m_BulletManager->Begin();
       ibu != m_BulletManager->End(); ++ibu) {
    CBullet* pBullet = (CBullet*)ibu->second;
    //处理子弹事件
    pBullet->OnUpdate(ndt);
    //获取移动组件
    MoveCompent* pMove = (MoveCompent*)pBullet->GetComponent(ECF_MOVE);
    if (pMove == NULL ||
        pMove->IsEndPath()) {  //当没有移动组件或已经移动到终点 加入到清除列表
      rmList.push_back(pBullet->GetId());
    }
    //不需要直接判断？
    else if (CGameConfig::instance()->bImitationRealPlayer &&
             !hasR) {  //如果开起模拟 且 无玩家？
      for (auto ifs = m_FishManager->Begin(); ifs != m_FishManager->End();
           ++ifs) {
        std::shared_ptr<CFish> pFish = (std::shared_ptr<CFish>)ifs->second;
        //只要鱼没死 判断 是否击中鱼
        if (pFish->GetState() < EOS_DEAD && pBullet->HitTest(pFish)) {
          //发送清除子弹
          lua_tinker::table msg(LuaRuntime::instance()->LuaState());
          msg.set("bullet_id",pBullet->GetId());
          msg.set("chair_id",pBullet->GetChairID());
          BroadCast("SC_KillBullet", msg);
          //抓捕鱼   //抓住后 Remove 不会破坏ifs？
          CatchFish(pBullet, pFish, 1, 0);
          //子弹加入清除列表
          rmList.push_back(pBullet->GetId());
          break;
        }
      }
    }
  }

  m_BulletManager->Unlock();

  for (auto it = rmList.begin(); it != rmList.end(); ++it) {
    m_BulletManager->Remove(*it);
  }
  rmList.clear();

  uint32_t tEvent = timeGetTime();
  CEventMgr::instance()->Update(ndt);
  tEvent = timeGetTime() - tEvent;

  //场景处理包换刷新鱼
  DistrubFish(fdt);

  m_dwLastTick = NowTime;
}
//判断是否有玩家在
bool CTableFrameSink::HasRealPlayer() { return m_ChairPlayers.size() > 0; }
//抓捕鱼
void CTableFrameSink::CatchFish(std::shared_ptr<CBullet> pBullet, std::shared_ptr<CFish> pFish, int nCatch,
                                int* nCatched) {
  //获取子弹 对鱼类型的概率值
  // float pbb = pBullet->GetProbilitySet(pFish->GetTypeID()) / MAX_PROBABILITY;
  //获取鱼被抓捕概率值
  // float pbf = pFish->GetProbability() / nCatch;
  //设置倍率
  // float fPB = 1.0f;

  //获取安卓增加值
  // fPB = CGameConfig::instance()->fAndroidProbMul;

  auto chair_id = pBullet->GetChairID();  //获取子弹所属玩家
  int guid = m_ChairPlayers[chair_id]->GetGuid();

  std::list<std::shared_ptr<MyObject>> list;  //存放被捕捉鱼 解除其它玩家锁定用

  //鱼的倍数
  int64_t fish_mul = CommonLogic::GetFishEffect(pBullet, pFish, list, true);
  //鱼的价值（随子弹价值变化）
  int64_t lScore = fish_mul * pBullet->GetScore();
  //金钱
  int64_t money = lScore * get_room_bullet_cell_money();

  UpdateHitLog(guid, pFish->GetTypeID(),
               pBullet->GetScore() * get_room_bullet_cell_money());

  //打爆的概率只和鱼的倍数有关，和子弹倍数无关
  int realProbV = MAX_FISH_HIT_CONST + getRoomWeight() + getFishWeight(pFish) +
                  getPlayerWeight(guid);

  int randV = RandomHelper::rand<int>(0, MAX_FISH_HIT_CONST * fish_mul);
  bool bCatch = randV < realProbV;
  if (!bCatch) {
    return;
  }

  list.clear();
  CommonLogic::GetFishEffect(pBullet, pFish, list, false);

  if (m_ChairPlayers.find(pBullet->GetChairID()) == m_ChairPlayers.end()) {
    std::cout << "遗留子弹打中鱼" << std::endl;
    return;
  }

  // Storage::getInstance().onCatchFish(lScore);
  m_UserWinScore[chair_id] += money;
  m_ChairPlayers[chair_id]->AddScore(money);

  UpdateCatchLog(guid, pFish->GetTypeID(), fish_mul, money);

  //能量炮 当鱼的值/炮弹值 大于 能量炮机率 且 随机值 小于能量炮率
  //为玩家获取双倍炮BUFF if (lScore / pBullet->GetScore() >
  // CGameConfig::instance()->nIonMultiply &&
  if (fish_mul > CGameConfig::instance()->nIonMultiply &&
      RandomHelper::rand<int>(0, MAX_PROBABILITY) <
          CGameConfig::instance()->nIonProbability) {
    auto pBMgr =
        m_ChairPlayers[pBullet->GetChairID()]->GetComponent<BufferMgr>(
            ECF_BUFFERMGR);
    if (pBMgr != NULL && !pBMgr->HasBuffer(EBT_DOUBLE_CANNON)) {
      pBMgr->Add(EBT_DOUBLE_CANNON, 0, CGameConfig::instance()->fDoubleTime);
      SendCannonSet(pBullet->GetChairID());
    }
  }

  SendCatchFish(pBullet, pFish, money);

  //解除其它玩家锁定的鱼
  for (std::list<MyObject*>::iterator im = list.begin(); im != list.end();
       ++im) {
    auto pf = std::dynamic_pointer_cast<CFish>(*im);
    for (auto& iter : m_ChairPlayers) {
      if (iter.second->GetLockFishID() == pf->GetId()) {
        iter.second->SetLockFishID(0);
      }
    }

    if (pf != pFish) {
      lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),
                             "on_fish_removed", m_RoomID, m_TableID,
                             pf->GetId());
      m_FishManager->Remove(pf);
    }
  }

  table table(LuaRuntime::instance()->LuaState());
  table.set("table_id", m_TableID);
  table.set("room_id", m_RoomID);
  table.set("fish_id", pFish->GetId());
  // table.set("multi", lScore / pBullet->GetScore());
  table.set("multi", fish_mul);
  table.set("score", money);
  table.set("player_guid", m_ChairPlayers[chair_id]->GetGuid());
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(), "on_catch_fish",
                         table);

  //移除鱼
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),
                         "on_fish_removed", m_RoomID, m_TableID,
                         pFish->GetId());
  m_FishManager->Remove(pFish);

  //用处不明 调用全为空 可优
  if (nCatched != NULL) {
    *nCatched = *nCatched + 1;
  }
}
//发送鱼被抓
void CTableFrameSink::SendCatchFish(std::shared_ptr<CBullet> pBullet, std::shared_ptr<CFish> pFish,
                                    long long score) {
  if (pBullet == NULL || pFish == NULL) {
    return;
  }

  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("chair_id",pBullet->GetChairID());
  msg.set("fish_id",pFish->GetId());
  msg.set("score",score);
  msg.set("bscoe",pBullet->GetScore() * get_room_bullet_cell_money());
  BroadCast("SC_KillFish", msg);
}
//给所有鱼添加BUFF
void CTableFrameSink::AddBuffer(int btp, float parm, float ft) {
  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("buffer_type",btp);
  msg.set("buffer_param",parm);
  msg.set("buffer_time",ft);
  BroadCast("SC_AddBuffer", msg);

  m_FishManager->Lock();
  obj_table_iter ifs = m_FishManager->Begin();
  while (ifs != m_FishManager->End()) {
    MyObject* pObj = ifs->second;
    BufferMgr* pBM = (BufferMgr*)pObj->GetComponent(ECF_BUFFERMGR);
    if (pBM != NULL) {
      pBM->Add(btp, parm, ft);
    }
    ++ifs;
  }
  m_FishManager->Unlock();
}
//场景处理 包括场景更换 鱼刷新
void CTableFrameSink::DistrubFish(float fdt) {
  if (m_fPauseTime > 0.0f) {
    m_fPauseTime -= fdt;
    return;
  }
  //场景时间增加
  m_fSceneTime += fdt;
  //时间大于场景准备时间，且不可开火 INVALID_CHAIR群发可开火命令
  //可优，是否应该出现在此处改为时间回调
  if (m_fSceneTime > SWITCH_SCENE_END && !m_bAllowFire) {
    m_bAllowFire = true;
    SendAllowFire(0);
  }

  //判断当前场景是否存在
  if (CGameConfig::instance()->SceneSets.find(m_nCurScene) ==
      CGameConfig::instance()->SceneSets.end()) {
    return;
  }

  //场景时间是否小于场景持续时间
  if (m_fSceneTime <
      CGameConfig::instance()->SceneSets[m_nCurScene].fSceneTime) {
    int npos = 0;
    //获取当前场景的刷鱼时间列表
    for (TroopSet& ts :
         CGameConfig::instance()->SceneSets[m_nCurScene].TroopList) {
      //是否无玩家存在
      if (!HasRealPlayer()) {
        //当场景时间　是否为刷鱼时间　
        if ((m_fSceneTime >= ts.fBeginTime) && (m_fSceneTime <= ts.fEndTime)) {
          //是则置为刷鱼结束时间
          m_fSceneTime = ts.fEndTime + fdt;
        }
      }

      //当场景时间　是否为刷鱼时间　
      if ((m_fSceneTime >= ts.fBeginTime) && (m_fSceneTime <= ts.fEndTime)) {
        //当循环小于刷新鱼信息数量
        if (npos < m_vDistrubTroop.size()) {
          int tid = ts.nTroopID;
          //是否发送描述 可优 描述无需发送吧
          if (!m_vDistrubTroop[npos].bSendDes) {
            //给所有鱼加速度BUFF
            AddBuffer(EBT_CHANGESPEED, 5, 60);
            //获取刷新鱼群描述信息
            Troop* ptp = PathManager::instance()->GetTroop(tid);
            if (ptp != NULL) {
              //获取总描述数量
              size_t nCount = ptp->Describe.size();
              //大于4条则只发送4条
              if (nCount > 4) nCount = 4;
              //配置刷新时间开始时间 为 2秒
              m_vDistrubTroop[npos].fBeginTime =
                  nCount * 2.0f;  //每条文字分配2秒的显示时间

              //发送描述  可优 改为发送ID
              lua_tinker::table msg(LuaRuntime::instance()->LuaState());
              for (int i = 0; i < nCount; ++i) {
                msg.seti(i+1,(char*)ptp->Describe[i].c_str());
              }
              BroadCast("SC_SendDes", msg);
            }
            //设置为已发送
            m_vDistrubTroop[npos].bSendDes = true;
          } else if (!m_vDistrubTroop[npos].bSendTroop &&
                     m_fSceneTime >
                         (m_vDistrubTroop[npos].fBeginTime +
                          ts.fBeginTime)) {  //如果没有发送过鱼群且 场景时间
                                             //大于 刷新时间加描述滚动时间
            m_vDistrubTroop[npos].bSendTroop = true;
            //获取刷新鱼群描述信息
            Troop* ptp = PathManager::instance()->GetTroop(tid);
            if (ptp == NULL) {
              //如果为空，则换下一场景
              m_fSceneTime +=
                  CGameConfig::instance()->SceneSets[m_nCurScene].fSceneTime;
            } else {
              int n = 0;
              int ns = ptp->nStep.size();  //获取步数 意义不明
              for (int i = 0; i < ns; ++i) {
                //刷鱼的ID
                int Fid = -1;
                //获取总步数
                int ncount = ptp->nStep[i];
                for (int j = 0; j < ncount; ++j) {
                  // n大于 总形状点时 退出循环
                  if (n >= ptp->Shape.size()) break;
                  //获取形状点
                  ShapePoint& tp = ptp->Shape[n++];
                  //总权重
                  int WeightCount = 0;
                  //获取鱼类型列表和权重列表最小值
                  int nsz = std::min(tp.m_lTypeList.size(), tp.m_lWeight.size());
                  //如果为0就跳过本次
                  if (nsz == 0) continue;
                  //获取总权重
                  for (int iw = 0; iw < nsz; ++iw) {
                    WeightCount += tp.m_lWeight[iw];
                  }

                  for (int ni = 0; ni < tp.m_nCount; ++ni) {
                    if (Fid == -1 || !tp.m_bSame) {
                      //第几个鱼目标
                      int wpos = 0;
                      //随机权重
                      int nf = RandomHelper::rand<int>(0, WeightCount);
                      //运算匹配的权重
                      while (nf > tp.m_lWeight[wpos]) {
                        //大于或等于权重最大值就跳出
                        if (wpos >= tp.m_lWeight.size()) break;
                        //随机值减去当前权重
                        nf -= tp.m_lWeight[wpos];
                        //目标加1
                        ++wpos;
                        //如果大于鱼类型列表
                        if (wpos >= nsz) {
                          wpos = 0;
                        }
                      }
                      //随机位置小于鱼列表 获取 鱼ID
                      if (wpos < tp.m_lTypeList.size()) {
                        Fid = tp.m_lTypeList[wpos];
                      }
                    }

                    //查找鱼
                    std::map<int, Fish>::iterator ift =
                        CGameConfig::instance()->FishMap.find(Fid);
                    if (ift != CGameConfig::instance()->FishMap.end()) {
                      Fish& finf = ift->second;
                      std::shared_ptr<CFish> pFish = CommonLogic::CreateFish(
                          finf, tp.x, tp.y, 0.0f, ni * tp.m_fInterval,
                          tp.m_fSpeed, tp.m_nPathID, true);
                      if (pFish != NULL) {
                        m_FishManager->Add(pFish);
                        SendFish(pFish);
                      }
                    }
                  }
                }
              }
            }
          }
        }
        return;
      }

      ++npos;
    }

    //如果场景时间大于 场景开始选择时间
    if (m_fSceneTime > SWITCH_SCENE_END) {
      int nfpos = 0;
      //获取干扰鱼列表
      std::list<DistrubFishSet>::iterator it = CGameConfig::instance()
                                                   ->SceneSets[m_nCurScene]
                                                   .DistrubList.begin();
      while (it != CGameConfig::instance()
                       ->SceneSets[m_nCurScene]
                       .DistrubList.end()) {
        //当前场景 干扰鱼群集
        DistrubFishSet& dis = *it;

        if (nfpos >= m_vDistrubFishTime.size()) {
          break;
        }
        m_vDistrubFishTime[nfpos] += fdt;
        //[nfpos]干扰鱼刷新时间 加上 当前时间跳动时间 大于刷新时间
        if (m_vDistrubFishTime[nfpos] > dis.ftime) {
          //清除一个刷新时间
          m_vDistrubFishTime[nfpos] -= dis.ftime;
          //是否当前有玩家在
          if (HasRealPlayer()) {
            //获取权重和鱼列表最小值
            int nsz = std::min(dis.Weight.size(), dis.FishID.size());
            //总权重
            int WeightCount = 0;
            //刷新鱼数量    随机一个刷新最小值到最大值
            int nct = RandomHelper::rand<int>(dis.nMinCount, dis.nMaxCount);
            //总刷新数量
            int nCount = nct;
            //蛇类型？
            int SnakeType = 0;
            //类型是否等于大蛇 刷新数量加2
            if (dis.nRefershType == ERT_SNAK) {
              nCount += 2;
              nct += 2;
            }

            //获取一个刷新ID
            uint32_t nRefershID = IDGenerator::instance()->GetID64();

            //获取总权重
            for (int wi = 0; wi < nsz; ++wi) WeightCount += dis.Weight[wi];

            //鱼与权重必须大于1
            if (nsz > 0) {
              //鱼ID
              int ftid = -1;
              //获取一个普通路径ID
              int pid = PathManager::instance()->GetRandNormalPathID();
              while (nct > 0) {
                //普通鱼
                if (ftid == -1 || dis.nRefershType == ERT_NORMAL) {
                  if (WeightCount == 0) {  //权重为0
                    ftid = dis.FishID[0];
                  } else {
                    //权重随机
                    int wpos = 0, nw = RandomHelper::rand<int>(0, WeightCount);
                    while (nw > dis.Weight[wpos]) {
                      if (wpos < 0 || wpos >= dis.Weight.size()) break;
                      nw -= dis.Weight[wpos];
                      ++wpos;
                      if (wpos >= nsz) wpos = 0;
                    }
                    if (wpos >= 0 || wpos < dis.FishID.size())
                      ftid = dis.FishID[wpos];
                  }

                  SnakeType = ftid;
                }
                //如果是刷大蛇，获取头和尾
                if (dis.nRefershType == ERT_SNAK) {
                  if (nct == nCount)
                    ftid = CGameConfig::instance()->nSnakeHeadType;
                  else if (nct == 1)
                    ftid = CGameConfig::instance()->nSnakeTailType;
                }
                //查找鱼
                std::map<int, Fish>::iterator ift =
                    CGameConfig::instance()->FishMap.find(ftid);
                if (ift != CGameConfig::instance()->FishMap.end()) {
                  Fish& finf = ift->second;
                  //类型普通
                  int FishType = ESFT_NORMAL;
                  //随机偏移值
                  float xOffest = RandomHelper::rand<float>(-dis.OffestX, dis.OffestX);
                  float yOffest = RandomHelper::rand<float>(-dis.OffestY, dis.OffestY);
                  //随机延时时间
                  float fDelay = RandomHelper::rand<float>(0.0f, dis.OffestTime);
                  //如果是线或大蛇 则不随机
                  if (dis.nRefershType == ERT_LINE ||
                      dis.nRefershType == ERT_SNAK) {
                    xOffest = dis.OffestX;
                    yOffest = dis.OffestY;
                    fDelay = dis.OffestTime * (nCount - nct);
                  } else if (dis.nRefershType == ERT_NORMAL &&
                             m_nSpecialCount <
                                 CGameConfig::instance()->nMaxSpecailCount) {
                    std::map<int, SpecialSet>* pMap = NULL;
                    //试着随机到谋一种特殊鱼
                    int nrand = rand() % 100;
                    int fft = ESFT_NORMAL;

                    if (nrand <
                        CGameConfig::instance()->nSpecialProb[ESFT_KING]) {
                      pMap = &(CGameConfig::instance()->KingFishMap);
                      fft = ESFT_KING;
                    } else {
                      nrand -=
                          CGameConfig::instance()->nSpecialProb[ESFT_KING];
                    }

                    if (nrand < CGameConfig::instance()
                                    ->nSpecialProb[ESFT_KINGANDQUAN]) {
                      pMap = &(CGameConfig::instance()->KingFishMap);
                      fft = ESFT_KINGANDQUAN;
                    } else {
                      nrand -= CGameConfig::instance()
                                   ->nSpecialProb[ESFT_KINGANDQUAN];
                    }

                    if (nrand < CGameConfig::instance()
                                    ->nSpecialProb[ESFT_SANYUAN]) {
                      pMap = &(CGameConfig::instance()->SanYuanFishMap);
                      fft = ESFT_SANYUAN;
                    } else {
                      nrand -= CGameConfig::instance()
                                   ->nSpecialProb[ESFT_SANYUAN];
                    }

                    if (nrand <
                        CGameConfig::instance()->nSpecialProb[ESFT_SIXI]) {
                      pMap = &(CGameConfig::instance()->SiXiFishMap);
                      fft = ESFT_SIXI;
                    }
                    //判断是否随机到特殊鱼
                    if (pMap != NULL) {
                      std::map<int, SpecialSet>::iterator ist =
                          pMap->find(ftid);
                      if (ist != pMap->end()) {
                        SpecialSet& kks = ist->second;
                        //对特殊鱼进行随机判断是否生成
                        if (RandomHelper::rand<float>(0, MAX_PROBABILITY) < kks.fProbability)
                          FishType = fft;
                      }
                    }
                  }
                  //生成鱼
                  std::shared_ptr<CFish> pFish = CommonLogic::CreateFish(
                      finf, xOffest, yOffest, 0.0f, fDelay, finf.nSpeed, pid,
                      false, FishType);
                  if (pFish != NULL) {
                    //设置鱼ID
                    pFish->SetRefershID(nRefershID);
                    m_FishManager->Add(pFish);
                    SendFish(pFish);
                  }
                }

                if (ftid == CGameConfig::instance()->nSnakeHeadType)
                  ftid = SnakeType;

                --nct;
              }
            }
          }
        }
        ++it;
        ++nfpos;
      }
    }
  } else {  //当场景时间大于场景持续时间 切换场景
    //获取下一场景ID 并判断是否存在
    int nex = CGameConfig::instance()->SceneSets[m_nCurScene].nNextID;
    if (CGameConfig::instance()->SceneSets.find(nex) !=
        CGameConfig::instance()->SceneSets.end()) {
      m_nCurScene = nex;
    }
    //重置场景
    ResetSceneDistrub();

    //清除玩家 锁定鱼 及锁定状态 子弹
	uint32_t GuID = 0;
    for (auto& iter : m_ChairPlayers) {
      iter.second->SetLocking(false);
      iter.second->SetLockFishID(0);
      iter.second->ClearBulletCount();
      if (iter.second->GetGuid() == 0) {
        continue;
      }

      GuID = iter.second->GetGuid();
      //发送 锁定信息
      lua_tinker::table msg(LuaRuntime::instance()->LuaState());
      msg.set("chair_id",iter.first);
      msg.set("lock_id",0);
      BroadCast("SC_LockFish", msg);
    }

    //设定不可开火 并发送
    m_bAllowFire = false;
    SendAllowFire(-1);

    //发送场景替换
    {
      lua_tinker::table msg(LuaRuntime::instance()->LuaState());
      msg.set("nst",m_nCurScene);
      msg.set("switching",1);
      BroadCast("SC_SwitchScene", msg);
    }

    //清除鱼
    m_FishManager->Clear();

    m_fSceneTime = 0.0f;
  }
}
//获取总玩家数 可优，每次循环获取？
int CTableFrameSink::CountPlayer() { return m_ChairPlayers.size(); }

bool CTableFrameSink::HasPlayer(int guid, int chair_id) {
  bool is_guid_exists = (m_GuidPlayers.find(guid) != m_GuidPlayers.end());
  bool is_chair_id_exists =
      m_ChairPlayers.find(chair_id) != m_ChairPlayers.end();
  if (guid > 0 && chair_id > 0) {
    return is_guid_exists && is_chair_id_exists;
  }
  if (guid > 0 && chair_id == 0) {
    return is_guid_exists;
  }
  if (guid == 0 && chair_id > 0) {
    return is_chair_id_exists;
  }

  return false;
}

void CTableFrameSink::ClearBullets(int chair_id) {
  std::lock_guard<std::recursive_mutex> m_locker(m_mutex);
  std::vector<std::shared_ptr<CBullet>> m_clear_bullets;
  for (auto iter = m_BulletManager->Begin(); iter != m_BulletManager->End();
       iter++) {
    auto pBullet = std::dynamic_pointer_cast<CBullet>(iter->second);
    if (pBullet->GetChairID() == chair_id) {
      m_clear_bullets.push_back(pBullet);
    }
  }

  for (auto bullet : m_clear_bullets) {
    m_BulletManager->Remove(bullet->GetId());
  }
}

//发送鱼数据
void CTableFrameSink::SendFish(std::shared_ptr<CFish> pFish, int wChairID) {
  auto ift = CGameConfig::instance()->FishMap.find(pFish->GetTypeID());
  if (ift == CGameConfig::instance()->FishMap.end()) {
    return;
  }

  Fish finf = ift->second;
  auto pMove = pFish->GetComponent<MoveCompent>(ECF_MOVE);
  auto pBM = pFish->GetComponent<BufferMgr>(ECF_BUFFERMGR);

  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("fish_id",pFish->GetId());
  msg.set("type_id",pFish->GetTypeID());
  msg.set("create_tick",pFish->GetCreateTick());
  msg.set("fis_type",pFish->GetFishType());
  msg.set("refersh_id",pFish->GetRefershID());
  if (pMove != NULL) {
    msg.set("path_id",pMove->GetPathID());
    if (pMove->GetID() == EMCT_DIRECTION) {
      msg.set("offest_x",pMove->GetPostion().x_);
      msg.set("offest_y",pMove->GetPostion().y_);
    } else {
      msg.set("offest_x",pMove->GetOffest().x_);
      msg.set("offest_y",pMove->GetOffest().y_);
    }

    msg.set("dir",pMove->GetDirection());
    msg.set("delay",pMove->GetDelay());
    msg.set("fish_speed",pMove->GetSpeed());
    msg.set("troop",pMove->bTroop());
  }

  if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT)) {
    PostEvent("FishMulChange", pFish);
  }

  msg.set("server_tick",timeGetTime());

  SendTo(m_ChairPlayers[wChairID]->GetGuid(),"SC_SendFish", msg);
}

void CTableFrameSink::SendFishList(int wChairID) {
  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  lua_tinker::table pb_fishes(LuaRuntime::instance()->LuaState());

  int i = 0;
  for (auto iter = m_FishManager->Begin(); iter != m_FishManager->End();
       iter++) {
    auto pFish = std::dynamic_pointer_cast<CFish>(iter->second);
    auto pMove = pFish->GetComponent<MoveCompent>(ECF_MOVE);
    auto pBM = pFish->GetComponent<BufferMgr>(ECF_BUFFERMGR);

    lua_tinker::table pMsgUnit = lua_tinker::table(LuaRuntime::instance()->LuaState());
    pMsgUnit.set("fish_id",pFish->GetId());
    pMsgUnit.set("type_id",pFish->GetTypeID());
    pMsgUnit.set("create_tick",pFish->GetCreateTick());
    pMsgUnit.set("fis_type",pFish->GetFishType());
    pMsgUnit.set("refersh_id",pFish->GetRefershID());

    if (pMove != NULL) {
      pMsgUnit.set("path_id",pMove->GetPathID());
      if (pMove->GetID() == EMCT_DIRECTION) {
        pMsgUnit.set("offest_x",pMove->GetPostion().x_);
        pMsgUnit.set("offest_y",pMove->GetPostion().y_);
      } else {
        pMsgUnit.set("offest_x",pMove->GetOffest().x_);
        pMsgUnit.set("offest_y",pMove->GetOffest().y_);
      }

      pMsgUnit.set("dir",pMove->GetDirection());
      pMsgUnit.set("delay",pMove->GetDelay());
      pMsgUnit.set("fish_speed",pMove->GetSpeed());
      pMsgUnit.set("troop",pMove->bTroop());
    }

    if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT)) {
      PostEvent("FishMulChange", pFish);
    }

    pMsgUnit.set("server_tick",timeGetTime());
    pb_fishes.seti(i++,pMsgUnit);
  }

  msg.set("pb_fishes",pb_fishes);

  SendTo(m_ChairPlayers[wChairID]->GetGuid(),"SC_SendFishList", msg);
}

//改变大炮集
bool CTableFrameSink::OnChangeCannonSet(int guid, int chair_id, int add) {
  std::lock_guard<std::recursive_mutex> locker(m_mutex);
  if (!HasPlayer(guid, chair_id)) {
    return true;
  }

  if (chair_id >= GAME_PLAYER) return false;

  auto pBMgr = m_ChairPlayers[chair_id]->GetComponent<BufferMgr>(ECF_BUFFERMGR);
  if (pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) ||
                        pBMgr->HasBuffer(EBT_ION_CANNON))) {
    return true;  //离子炮或能量炮时禁止换炮
  }
  //获取大炮集类型
  int n = m_ChairPlayers[chair_id]->GetCannonSetType();

  do {
    if (add) {
      if (n < CGameConfig::instance()->CannonSetArray.size() - 1) {
        ++n;
      } else {
        n = 0;
      }
    } else {
      if (n >= 1) {
        --n;
      } else {
        n = CGameConfig::instance()->CannonSetArray.size() - 1;
      }
    }  //等于离子炮ID 或双倍ID是退出循环
  } while (n == CGameConfig::instance()->CannonSetArray[n].nIonID ||
           n == CGameConfig::instance()->CannonSetArray[n].nDoubleID);

  if (n < 0) n = 0;
  if (n >= CGameConfig::instance()->CannonSetArray.size()) {
    n = CGameConfig::instance()->CannonSetArray.size() - 1;
  }

  //设置大炮集类型 ？CacluteCannonPos 获取的是大炮类型 m_nCannonType
  m_ChairPlayers[chair_id]->SetCannonSetType(n);
  //运算大炮坐标
  m_ChairPlayers[chair_id]->CacluteCannonPos(chair_id);
  //发送大炮信息
  SendCannonSet(chair_id);

  return true;
}
//开火
bool CTableFrameSink::OnFire(int guid, int chair_id, double direction,
                             int client_id, uint32_t fire_time, double pos_x,
                             double pos_y) {
  std::lock_guard<std::recursive_mutex> locker(m_mutex);
  double Direction = direction;
  int ClientID = client_id;
  uint32_t FireTime = fire_time;
  MyPoint bullet_pos(pos_x, pos_y);

  if (!HasPlayer(guid, chair_id)) {
    return true;
  }

  //获取子弹类型
  int mul = m_ChairPlayers[chair_id]->GetMultiply();
  if (mul < 0 || mul >= CGameConfig::instance()->BulletVector.size()) {
    std::cout << "invalid bullet multiple" << std::endl;
    return false;
  }

  //场景及玩家可以开火
  if (m_bAllowFire &&
      (HasRealPlayer() || CGameConfig::instance()->bImitationRealPlayer) &&
      m_ChairPlayers[chair_id]->CanFire()) {
    //获取子弹
    Bullet& binf = CGameConfig::instance()->BulletVector[mul];
    //子弹花费的钱（底注乘以倍率）
    int bullet_cost = binf.nMulriple * get_room_bullet_cell_money();
    //玩家金钱大于子弹值， 且 玩家总子弹数 小于最大子弹数
    if (m_ChairPlayers[chair_id]->GetScore() >= bullet_cost &&
        m_ChairPlayers[chair_id]->GetBulletCount() + 1 <=
            CGameConfig::instance()->nMaxBullet) {
      m_ChairPlayers[chair_id]->SetFired();

      // 整理税收和玩家输赢分数
      // Storage::getInstance().onUserFire(bullet_cost);
      m_UserWinScore[chair_id] -= bullet_cost;
      m_ChairPlayers[chair_id]->AddScore(-bullet_cost);

      UpdateFireLog(guid, mul, bullet_cost);

      //创建子弹
      auto pBullet = CommonLogic::CreateBullet(
          binf, bullet_pos, Direction,
          m_ChairPlayers[chair_id]->GetCannonType(),
          m_ChairPlayers[chair_id]->GetMultiply(), false);
      if (pBullet != NULL) {
        if (ClientID != 0) {
          pBullet->SetId(ClientID);
        }
        pBullet->SetChairID(chair_id);  //设置椅子
        pBullet->SetCreateTick(timeGetTime());  //设置开火时间 此时间无效校验

        //查找玩家BUFF是否有双倍炮BUFF
        auto pBMgr = m_ChairPlayers[chair_id]->GetComponent<BufferMgr>(ECF_BUFFERMGR);
        if (pBMgr != NULL && pBMgr->HasBuffer(EBT_DOUBLE_CANNON)) {
          pBullet->setDouble(true);
        }

        //是否有锁定鱼
        if (m_ChairPlayers[chair_id]->GetLockFishID() != 0) {
          //获取子弹移动控件
          auto pMove = pBullet->GetComponent<MoveCompent>(ECF_MOVE);
          if (pMove != NULL) {
            pMove->SetTarget(m_FishManager,
                             m_ChairPlayers[chair_id]->GetLockFishID());
          }
        }

        uint32_t now = timeGetTime();
        if (FireTime > now) {
          // m_pITableFrame->SendTableData(pf->wChairID, SUB_S_FORCE_TIME_SYNC);
        } else {
          //如果子弹生成时间大于2秒执行更新事件处理操作
          uint32_t delta = now - FireTime;
          if (delta > 2000) delta = 2000;
          pBullet->OnUpdate(delta);
        }

        //增加子弹
        m_ChairPlayers[chair_id]->ADDBulletCount(1);
        m_BulletManager->Add(pBullet);
        //发送子弹
        SendBullet(pBullet, true);
      } else {
        {
          lua_tinker::table msg(LuaRuntime::instance()->LuaState());
          msg.set("chair_id",chair_id);
          msg.set("bullet_id",ClientID);
          BroadCast("SC_KillBullet", msg);
        }

        {
          lua_tinker::table msg(LuaRuntime::instance()->LuaState());
          msg.set("chair_id",chair_id);
          msg.set("score",m_ChairPlayers[chair_id]->GetScore());
          SendTo(guid,"SC_UpdatePlayerInfo", msg);
        }
      }

      //设置最后开火时间
      m_ChairPlayers[chair_id]->SetLastFireTick(timeGetTime());
    } else {
      {
        lua_tinker::table msg(LuaRuntime::instance()->LuaState());
        msg.set("chair_id",chair_id);
        msg.set("bullet_id",ClientID);
        BroadCast("SC_KillBullet", msg);
      }

      {
        lua_tinker::table msg(LuaRuntime::instance()->LuaState());
        msg.set("chair_id",chair_id);
        msg.set("score",m_ChairPlayers[chair_id]->GetScore());
        SendTo(guid,"SC_UpdatePlayerInfo", msg);
      }

      std::cout << "Score less or reach max bullet count.guid:" << guid
                << " count:" << m_ChairPlayers[chair_id]->GetBulletCount()
                << " max count:" << CGameConfig::instance()->nMaxBullet
                << std::endl;
    }
  } else {
    {
      lua_tinker::table msg(LuaRuntime::instance()->LuaState());
      msg.set("chair_id",chair_id);
      msg.set("bullet_id",ClientID);
      BroadCast("SC_KillBullet", msg);
    }
    std::cout << "Do not allow fire,but fired." << std::endl;
  }

  return true;
}
//发送子弹
void CTableFrameSink::SendBullet(std::shared_ptr<CBullet> pBullet, bool bNew) {
  if (pBullet == NULL) return;

  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("chair_id",pBullet->GetChairID());
  msg.set("id",pBullet->GetId());
  msg.set("cannon_type",pBullet->GetCannonType());
  msg.set("multiply",pBullet->GetTypeID());
  msg.set("direction",pBullet->GetDirection());
  msg.set("x_pos",pBullet->GetPosition().x_);
  msg.set("y_pos",pBullet->GetPosition().y_);
  msg.set("score",m_ChairPlayers[pBullet->GetChairID()]->GetScore());
  msg.set("is_new",bNew ? 1 : 0);
  msg.set("is_double",pBullet->bDouble() ? 1 : 0);
  msg.set("server_tick",timeGetTime());
  if (bNew) {
    msg.set("create_tick",pBullet->GetCreateTick());
  } else {
    msg.set("create_tick",timeGetTime());
  }

  BroadCast("SC_SendBullet", msg);
}

//发送系统时间
bool CTableFrameSink::OnTimeSync(int guid, int chair_id, int client_tick) {
  if (!HasPlayer(guid, chair_id)) {
    return true;
  }

  if (guid != 0) {
    lua_tinker::table msg(LuaRuntime::instance()->LuaState());
    msg.set("chair_id",chair_id);
    msg.set("client_tick",client_tick);
    msg.set("server_tick",timeGetTime());
    SendTo(guid,"SC_TimeSync", msg);
    return true;
  }

  return false;
}

//变换大炮
bool CTableFrameSink::OnChangeCannon(int guid, int chair_id, int add) {
  std::lock_guard<std::recursive_mutex> locker(m_mutex);
  int ChairID = chair_id;
  if (!HasPlayer(guid, chair_id)) {
    return true;
  }

  //获取Buff管理器
  auto pBMgr = m_ChairPlayers[ChairID]->GetComponent<BufferMgr>(ECF_BUFFERMGR);
  //查看当前大炮是否为双倍或离子炮
  if (pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) ||
                        pBMgr->HasBuffer(EBT_ION_CANNON))) {
    return true;  //离子炮或能量炮时禁止换炮
  }

  //获取当前子弹类型
  int mul = m_ChairPlayers[ChairID]->GetMultiply();

  if (add) {
    ++mul;
  } else {
    --mul;
  }
  //循环类型
  if (mul < 0) mul = CGameConfig::instance()->BulletVector.size() - 1;
  if (mul >= CGameConfig::instance()->BulletVector.size()) mul = 0;
  //设置类型
  m_ChairPlayers[ChairID]->SetMultiply(mul);
  //获取子弹对应的炮类形
  int CannonType = CGameConfig::instance()->BulletVector[mul].nCannonType;
  //设置炮
  m_ChairPlayers[ChairID]->SetCannonType(CannonType);
  //发送炮设置
  SendCannonSet(ChairID);
  //设置最后一次开炮时间
  m_ChairPlayers[ChairID]->SetLastFireTick(timeGetTime());

  return true;
}
//发送大炮属性
void CTableFrameSink::SendCannonSet(int wChairID) {
  auto iter = m_ChairPlayers.find(wChairID);
  if (iter == m_ChairPlayers.end()) {
    return;
  }

  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("chair_id",iter->first);
  msg.set("cannon_mul",iter->second->GetMultiply());
  msg.set("cannon_type",iter->second->GetCannonType());
  msg.set("cannon_set",iter->second->GetCannonSetType());
  BroadCast("SC_CannonSet", msg);
}

//打开宝箱
bool CTableFrameSink::OnTreasureEND(table player, int64_t score) {
  int ChairID = player.get<int>("chair_id");
  int Guid = player.get<int>("guid");

  if (!HasPlayer(Guid, ChairID)) {
    return true;
  }

  if (ChairID > 0 && ChairID <= GAME_PLAYER && Guid != 0) {
    char szInfo[512] = {0};
    std::string str =
        "恭喜%s第%d桌的玩家『%s』打中宝箱,　并从中获得%lld金币!!!";
    sprintf(szInfo, str.c_str(), "fishing", GetTableID(),
              m_GuidPlayers[Guid]->GetNickname().c_str(), score);
    RaiseEvent("CatchFishBroadCast", std::make_shared<std::string>(szInfo), m_GuidPlayers[Guid]);
  }

  return true;
}

void CTableFrameSink::UpdateFireLog(int guid, int fire_mul, int fire_cost) {
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),
                         "update_player_fire_log", guid, fire_mul, fire_cost);
}

void CTableFrameSink::SubtractFireLog(int guid, int fire_mul, int fire_cost) {
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),
                         "subtract_player_fire_log", guid, fire_mul, fire_cost);
}

void CTableFrameSink::UpdateCatchLog(int guid, int fish_type_id, int64_t multi,
                                     int score) {
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),
                         "update_player_catch_log", guid, fish_type_id, multi,
                         score);
}

void CTableFrameSink::UpdateHitLog(int guid, int fish_type_id,
                                   int64_t connon_cost) {
  lua_tinker::call<void>(LuaRuntime::instance()->LuaState(),
                         "update_player_hit_log", guid, fish_type_id,
                         connon_cost);
}

//
void CTableFrameSink::ReturnBulletScore(int guid) {
  {
    int money = m_UserWinScore[m_GuidPlayers[guid]->GetChairID()];
    lua_tinker::call<void, int, int>(LuaRuntime::instance()->LuaState(),
                                     "write_player_money", guid, money);
  }

#if 0
	if (wChairID >= GAME_PLAYER)
	{
		DebugString(TEXT("[Fish]ReturnBulletScore Err: wTableID %d wChairID %d"), m_pITableFrame->GetTableID(), wChairID);
		return;
	}
	try
	{
		IServerUserItem* pIServerUserItem = m_pITableFrame->GetTableUserItem(wChairID);
		if (pIServerUserItem != NULL)
		{
			// 			int64_t score = m_player[wChairID].GetScore();
			// 			if(score != 0)
			// 			{
			// 				long long  ls = score * CGameConfig::instance()->nChangeRatioUserScore / CGameConfig::instance()->nChangeRatioFishScore;
			// 				m_player[wChairID].AddWastage(-ls);
			// 			}
			// 
			// 			tagScoreInfo ScoreInfo;
			// 			ZeroMemory(&ScoreInfo, sizeof(tagScoreInfo));
			// 			score = -m_player[wChairID].GetWastage();
			// 			long long  lReve=0,cbRevenue=m_pGameServiceOption->wRevenueRatio;	
			// 			if (score > 0)
			// 			{	
			// 				float fRevenuePer = float(cbRevenue/1000);
			// 				lReve  = long long (score*fRevenuePer);
			// 				ScoreInfo.cbType = SCORE_TYPE_WIN;
			// 			}
			// 			else if (score < 0)
			// 				ScoreInfo.cbType = SCORE_TYPE_LOSE;
			// 			else
			// 				ScoreInfo.cbType = SCORE_TYPE_DRAW;
			// 			ScoreInfo.lScore = score;
			// 			ScoreInfo.lRevenue = lReve;
			// 
			// 			m_pITableFrame->WriteUserScore(wChairID, ScoreInfo);

			if (user_win_scores_[wChairID] != 0 || user_revenues_[wChairID] != 0) {// 有发炮过
				tagScoreInfo ScoreInfo = { 0 };
				ScoreInfo.cbType = (user_win_scores_[wChairID] > 0L) ? SCORE_TYPE_WIN : SCORE_TYPE_LOSE;
				ScoreInfo.lRevenue = user_revenues_[wChairID];
				ScoreInfo.lScore = user_win_scores_[wChairID];
				user_revenues_[wChairID] = 0;
				user_win_scores_[wChairID] = 0;
				m_pITableFrame->WriteUserScore(wChairID, ScoreInfo);
			}

			m_player[wChairID].ClearSet(wChairID);
		}
	}
	catch (...)
	{
		CTraceService::TraceString(TEXT("ReturnBulletScore错误1"), TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误1"));
	}

	std::list<uint32_t> rmList;
	m_BulletManager->Lock();
	try
	{
		obj_table_iter ibu = m_BulletManager->Begin();
		while (ibu != m_BulletManager->End())
		{
			CBullet* pBullet = (CBullet*)ibu->second;
			if (pBullet->GetChairID() == wChairID)
				rmList.push_back(pBullet->GetId());

			++ibu;
		}
	}
	catch (...)
	{
		CTraceService::TraceString(TEXT("ReturnBulletScore错误2"), TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误2"));
	}
	m_BulletManager->Unlock();

	std::list<uint32_t>::iterator it = rmList.begin();
	while (it != rmList.end())
	{
		m_BulletManager->Remove(*it);
		++it;
	}

	rmList.clear();
#endif
}
//奖励事件
void CTableFrameSink::OnAdwardEvent(CMyEvent* pEvent) {
  //判断事件是否为本事件
  if (pEvent == NULL || pEvent->GetName() != "AdwardEvent") return;
  //奖励事件
  auto pe = pEvent->GetParam<CEffectAward>();
  //鱼
  auto pFish = pEvent->GetSource<CFish>();
  //子弹
  auto pBullet = pEvent->GetTarget<CBullet>();

  if (pe == NULL || pFish == NULL || pBullet == NULL) return;
  //设置玩家不可开火
  m_ChairPlayers[pBullet->GetChairID()]->SetCanFire(false);

  long long lScore = 0;
  // GetParam(1) 参数２表示实际效果 ０加金币　　１加ＢＵＦＦＥＲ
  if (pe->GetParam(1) == 0) {
    if (pe->GetParam(2) == 0)
      lScore = pe->GetParam(3);
    else
      lScore = pBullet->GetScore() * pe->GetParam(3);
  } else {
    //纵使子弹加BUFF
    auto pBMgr = m_ChairPlayers[pBullet->GetChairID()]->GetComponent<BufferMgr>(
            ECF_BUFFERMGR);
    if (pBMgr != NULL && !pBMgr->HasBuffer(pe->GetParam(2))) {
      // GetParam(2)类型 GetParam(3)持续时间
      pBMgr->Add(pe->GetParam(2), 0, pe->GetParam(3));
    }
  }
  //玩家加钱
  m_ChairPlayers[pBullet->GetChairID()]->AddScore(lScore);
}
//增加鱼BUFF
void CTableFrameSink::OnAddBuffer(CMyEvent* pEvent) {
  if (pEvent == NULL || pEvent->GetName() != "AddBuffer") return;
  auto pe = pEvent->GetParam<CEffectAddBuffer>();

  std::shared_ptr<CFish> pFish = (std::shared_ptr<CFish>)pEvent->GetSource();
  if (pFish == NULL) return;

  if (pFish->GetMgr() != &m_FishManager) return;

  //当目标是全部鱼且类型为改变速度 改变值为0时 定屏 时间为pe->GetParam(4)
  if (pe->GetParam(0) == 0 && pe->GetParam(2) == EBT_CHANGESPEED &&
      pe->GetParam(3) == 0)  //定屏
  {                          //？只停止了刷新?
    m_fPauseTime = pe->GetParam(4);
  }
}
//执行鱼死亡效果
void CTableFrameSink::OnMulChange(CMyEvent* pEvent) {
  if (pEvent == NULL || pEvent->GetName() != "FishMulChange") return;

  auto pFish = pEvent->GetParam<CFish>();
  if (pFish != NULL) {
    m_FishManager->Lock();
    obj_table_iter ifs = m_FishManager->Begin();
    while (ifs != m_FishManager->End()) {
      auto pf = std::dynamic_pointer_cast<CFish>(ifs->second);
      //找到一个同类的鱼，然后执行死亡效果
      if (pf != NULL && pf->GetTypeID() == pFish->GetTypeID()) {
        CBullet bt;
        bt.SetScore(1);
        std::list<MyObject*> llt;
        llt.clear();
        //如果找到鱼死亡管理器
        auto pEM = pf->GetComponent<EffectMgr>(ECF_EFFECTMGR);
        int multemp = 0;
        if (pEM != NULL) {  //执行死亡效果
          multemp = pEM->Execute(&bt, llt, true);
        }

        lua_tinker::table msg(LuaRuntime::instance()->LuaState());
        msg.set("fish_id",pf->GetId());
        msg.set("mul",multemp);
        BroadCast("SC_FishMul", msg);
      }

      ++ifs;
    }
    m_FishManager->Unlock();
  }
}
//第一次开火？ 为啥是生成鱼的 第一波鱼生成吗？
void CTableFrameSink::OnFirstFire(CMyEvent* pEvent) {
  if (pEvent == NULL || pEvent->GetName() != "FirstFire") return;

  auto pPlayer = pEvent->GetParam<CPlayer>();

  if (m_ChairPlayers.find(pPlayer->GetChairID()) == m_ChairPlayers.end()) {
    return;
  }

  int npos = 0;
  npos = CGameConfig::instance()->FirstFireList.size() - 1;
  FirstFire& ff = CGameConfig::instance()->FirstFireList[npos];
  //在鱼类型与权重中取最低值
  int nsz = std::min(ff.FishTypeVector.size(), ff.WeightVector.size());

  if (nsz <= 0) return;

  //总权重
  int WeightCount = 0;
  for (int iw = 0; iw < nsz; ++iw) {
    WeightCount += ff.WeightVector[iw];
  }

  //获取大炮位置
  MyPoint pt = pPlayer->GetCannonPos();
  //获取大炮方向
  float dir =
      CGameConfig::instance()->CannonPos[pPlayer->GetChairID()].m_Direction;
  //数量？
  for (int nc = 0; nc < ff.nCount; ++nc) {
    //价格计数？
    for (int ni = 0; ni < ff.nPriceCount; ++ni) {
      //获取 一种鱼
      int Fid = ff.FishTypeVector[RandomHelper::rand<int>(0, nsz)];
      //随机一个权重
      int nf = RandomHelper::rand<int>(0, WeightCount);
      int wpos = 0;
      //匹配一个权重
      for (; wpos < nsz; ++wpos) {
        if (nf > ff.WeightVector[wpos]) {
          nf -= ff.WeightVector[wpos];
        } else {
          Fid = ff.FishTypeVector[wpos];
          break;
          ;
        }
      }
      //如果没有匹配到则匹配第一个
      if (wpos >= nsz) {
        Fid = ff.FishTypeVector[0];
      }

      //运算最终角度？
      dir = CGameConfig::instance()
                ->CannonPos[pPlayer->GetChairID()]
                .m_Direction -
            M_PI_2 + M_PI / ff.nPriceCount * ni;

      //查找匹配到的鱼
      std::map<int, Fish>::iterator ift =
          CGameConfig::instance()->FishMap.find(Fid);
      if (ift != CGameConfig::instance()->FishMap.end()) {
        Fish& finf = ift->second;

        //生成鱼
        std::shared_ptr<CFish> pFish = CommonLogic::CreateFish(finf, pt.x_, pt.y_, dir,
                                               RandomHelper::rand<float>(0.0f, 1.0f) + nc,
                                               finf.nSpeed, -2);
        if (pFish != NULL) {
          m_FishManager->Add(pFish);
          SendFish(pFish);
        }
      }
    }
  }
}
//生成鱼
void CTableFrameSink::OnProduceFish(CMyEvent* pEvent) {
  if (pEvent == NULL || pEvent->GetName() != "ProduceFish") return;

  auto pe = pEvent->GetParam<CEffectProduce>();
  // Source为鱼
  auto pFish = pEvent->GetSource<CFish>();
  if (pFish == NULL) return;

  if (pFish->GetMgr() != m_FishManager) return;
  //获取坐标
  MyPoint pt = pFish->GetPosition();
  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  lua_tinker::table pb_fishes(LuaRuntime::instance()->LuaState());
  int fi = 0;
  //通过ID查找鱼
  std::map<int, Fish>::iterator ift =
      CGameConfig::instance()->FishMap.find(pe->GetParam(0));
  if (ift != CGameConfig::instance()->FishMap.end()) {
    Fish finf = ift->second;
    float fdt = M_PI * 2.0f / (float)pe->GetParam(2);
    //类型为普通
    int fishtype = ESFT_NORMAL;
    int ndif = -1;
    //批次循环
    for (int i = 0; i < pe->GetParam(1); ++i) {
      //当最后一批，且总批次大于2 刷新数量大于10只时 随机一条鱼刷新为鱼王
      if ((i == pe->GetParam(1) - 1) && (pe->GetParam(1) > 2) &&
          (pe->GetParam(2) > 10)) {
        ndif = RandomHelper::rand<int>(0, pe->GetParam(2));
      }

      //刷新数量
      for (int j = 0; j < pe->GetParam(2); ++j) {
        if (j == ndif) {
          fishtype = ESFT_KING;
        } else {
          fishtype = ESFT_NORMAL;
        }

        //创建鱼
        std::shared_ptr<CFish> pf = CommonLogic::CreateFish(finf, pt.x_, pt.y_, fdt * j,
                                            1.0f + pe->GetParam(3) * i,
                                            finf.nSpeed, -2, false, fishtype);
        if (pf != NULL) {
          m_FishManager->Add(pf);

          lua_tinker::table pMsgUnit(LuaRuntime::instance()->LuaState());
          pMsgUnit.set("fish_id",pf->GetId());
          pMsgUnit.set("type_id",pf->GetTypeID());
          pMsgUnit.set("create_tick",pf->GetCreateTick());
          pMsgUnit.set("server_tick",timeGetTime());
          pMsgUnit.set("fis_type",pf->GetFishType());
          pMsgUnit.set("refersh_id",pf->GetRefershID());
          

          //添加移动组件
          auto pMove = pf->GetComponent<MoveCompent>(ECF_MOVE);
          if (pMove != NULL) {
            pMsgUnit.set("path_id",pMove->GetPathID());
            if(pMove->GetID() != EMCT_DIRECTION){
              pMsgUnit.set("offest_x",pMove->GetOffest().x_);
              pMsgUnit.set("offest_y",pMove->GetOffest().y_);
            }else{
              pMsgUnit.set("offest_x",pMove->GetPostion().x_);
              pMsgUnit.set("offest_y",pMove->GetPostion().y_);
            }
            pMsgUnit.set("dir",pMove->GetDirection());
            pMsgUnit.set("delay",pMove->GetDelay());
            pMsgUnit.set("fish_speed",pMove->GetSpeed());
            pMsgUnit.set("troop",pMove->bTroop() ? 1 : 0);
          }

          auto pBM = pf->GetComponent<BufferMgr>(ECF_BUFFERMGR);
          if (pBM != NULL &&
              pBM->HasBuffer(EBT_ADDMUL_BYHIT)) {  //找到BUFF管理器，且有BUFF
                                                   //被击 吃子弹 添加事件
            PostEvent("FishMulChange", pf);
          }

          pb_fishes.seti(fi++,pMsgUnit);
        }
      }
    }
  }
  msg.set("pb_fishes",pb_fishes);

  BroadCast( "SC_SendFishList",msg);
}
//锁定鱼
void CTableFrameSink::LockFish(int wChairID) {
  uint32_t dwFishID = 0;

  std::shared_ptr<CFish> pf = NULL;
  //获取当前锁定ID
  dwFishID = m_ChairPlayers[wChairID]->GetLockFishID();
  if (dwFishID != 0) {
    pf = m_FishManager->Find<CFish>(dwFishID);
  }

  if (pf != NULL) {
    //判断当前锁定鱼 是否已经不可锁定了
    auto pMove = pf->GetComponent<MoveCompent>(ECF_MOVE);
    if (pf->GetState() >= EOS_DEAD || pMove == NULL || pMove->IsEndPath()) {
      pf = NULL;
    }
  }

  dwFishID = 0;

  std::shared_ptr<CFish> pLock = NULL;

  //轮询可锁定列表
  for (std::list<uint32_t>::iterator iw = m_CanLockList.begin();
       iw != m_CanLockList.end(); ++iw) {
    //查找鱼
    auto pFish = m_FishManager->Find<CFish>(*iw);
    //当前鱼有效 且 没死亡 且 锁定等级大于0 且 没有游出屏幕
    if (pFish != NULL && pFish->GetState() < EOS_DEAD &&
        pFish->GetLockLevel() > 0 && pFish->InSideScreen()) {
      //获取能锁定的最大等级的鱼
      if (pf == NULL || (pf != pFish && !m_ChairPlayers[wChairID]->HasLocked(
                                            pFish->GetId()))) {
        pf = pFish;

        if (pLock == NULL) {
          pLock = pf;
        } else if (pf->GetLockLevel() > pLock->GetLockLevel()) {
          pLock = pf;
        }
      }
    }
  }

  if (pLock != NULL) {
    dwFishID = pLock->GetId();
  }

  //设置锁定ID
  m_ChairPlayers[wChairID]->SetLockFishID(dwFishID);
  if (m_ChairPlayers[wChairID]->GetLockFishID() == 0) {
    return;
  }

  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("chair_id",wChairID);
  msg.set("lock_id",dwFishID);
  BroadCast("SC_LockFish", msg);
}
//锁定鱼
bool CTableFrameSink::OnLockFish(int guid, int chair_id, int isLock) {
  std::lock_guard<std::recursive_mutex> locker(m_mutex);

  if (!HasPlayer(guid, chair_id)) {
    return true;
  }

  //椅子子位置是否合理
  //如果没有玩家退出
  if (!HasRealPlayer()) return true;

  if (isLock) {
    //设置玩家锁定
    m_GuidPlayers[guid]->SetLocking(true);
    //锁定鱼
    LockFish(chair_id);
  } else {
    m_GuidPlayers[guid]->SetLocking(false);
    m_GuidPlayers[guid]->SetLockFishID(0);

    lua_tinker::table msg(LuaRuntime::instance()->LuaState());
    msg.set("chair_id",chair_id);
    msg.set("lock_id",0);
    BroadCast( "SC_LockFish",msg);
  }
  m_GuidPlayers[guid]->SetLastFireTick(timeGetTime());

  return true;
}

bool CTableFrameSink::OnLockSpecFish(int guid, int chair_id, int fishID) {
  std::lock_guard<std::recursive_mutex> locker(m_mutex);
  if (!HasPlayer(guid, chair_id)) {
    return true;
  }

  if (!HasRealPlayer()) return true;

  if (fishID > 0) {
    std::shared_ptr<CFish> pLockFish = (std::shared_ptr<CFish>)m_FishManager->Find(fishID);
    if (!pLockFish) {
      m_GuidPlayers[guid]->SetLocking(false);
      m_GuidPlayers[guid]->SetLockFishID(0);
      fishID = 0;
    } else {
      m_GuidPlayers[guid]->SetLocking(true);
      m_GuidPlayers[guid]->SetLockFishID(fishID);
    }
  } else {
    m_GuidPlayers[guid]->SetLocking(false);
    m_GuidPlayers[guid]->SetLockFishID(0);
  }

  lua_tinker::table msg(LuaRuntime::instance()->LuaState());
  msg.set("chair_id",chair_id);
  msg.set("lock_id",fishID);
  BroadCast("SC_LockFish", msg);

  m_GuidPlayers[guid]->SetLastFireTick(timeGetTime());

  return true;
}

//发送 玩家大炮属性    并不是改变大炮？
void CTableFrameSink::OnCannonSetChange(CMyEvent* pEvent) {
  if (pEvent == NULL || pEvent->GetName() != "CannonSetChanaged") {
    return;
  }

  CPlayer* pp = (CPlayer*)pEvent->GetParam();
  if (!pp) {
    return;
  }

  SendCannonSet(pp->GetChairID());
}
//网鱼
bool CTableFrameSink::OnNetCast(int guid, int chair_id, int bullet_id, int data,
                                int fish_id) {
  std::lock_guard<std::recursive_mutex> locker(m_mutex);
  if (!HasPlayer(guid, chair_id)) {
    return true;
  }

  m_BulletManager->Lock();
  //获取子弹
  auto pBullet = m_BulletManager->Find<CBullet>(bullet_id);
  if (pBullet != NULL) {
    int bulletChairID = pBullet->GetChairID();
    //获取子弹所属玩家座位
    if (m_ChairPlayers.find(bulletChairID) == m_ChairPlayers.end()) {
      return true;
    }

    m_FishManager->Lock();
    auto pFish = m_FishManager->Find<CFish>(fish_id);
    if (pFish != NULL) {
      CatchFish(pBullet, pFish, 1, 0);
    } else {  //打中的鱼已经死亡,返还子弹分数
      do {
        int mul = m_ChairPlayers[bulletChairID]->GetMultiply();
        if (mul < 0 || mul >= CGameConfig::instance()->BulletVector.size()) {
          break;
        }

        Bullet& binf = CGameConfig::instance()->BulletVector[mul];
        int bullet_cost = binf.nMulriple * get_room_bullet_cell_money();
        m_ChairPlayers[bulletChairID]->AddScore(bullet_cost);
        m_UserWinScore[bulletChairID] += bullet_cost;

        //开炮无效，减掉
        SubtractFireLog(m_ChairPlayers[bulletChairID]->GetGuid(), mul,
                        bullet_cost);

        lua_tinker::table msg(LuaRuntime::instance()->LuaState());
        msg.set("chair_id",bulletChairID);
        msg.set("score",m_ChairPlayers[bulletChairID]->GetScore());
        BroadCast("SC_UpdatePlayerInfo", msg);
      } while (false);
    }

    m_FishManager->Unlock();

    //发送子弹消失
    lua_tinker::table msg(LuaRuntime::instance()->LuaState());
    msg.set("chair_id",bulletChairID);
    msg.set("bullet_id",bullet_id);
    BroadCast("SC_KillBullet", msg);

    //玩家子弹-1
    m_ChairPlayers[bulletChairID]->ADDBulletCount(-1);
    //移除子弹
    m_BulletManager->Remove(bullet_id);
  } else {
    // TODO:
    // 如果子弹不存在，也可能导致一些问题,有可能是上一个玩家已经打掉某个鱼把子弹已经消掉了，接着又收到捕中鱼的消息
  }
  m_BulletManager->Unlock();

  return true;
}

//打中鱼广播 无处理，只发送？ 可优
void CTableFrameSink::OnCatchFishBroadCast(CMyEvent* pEvent) {
  // if (pEvent != NULL && pEvent->GetName() == "CatchFishBroadCast"){
  //	//获取玩家
  //	CPlayer* pp = (CPlayer*)pEvent->GetSource();
  //	if (pp != NULL){
  //           CAutoLock cl(g_LuaLock);

  //		table table(LuaRuntime::instance()->LuaState());
  //		table.set("wType", SMT_TABLE_ROLL);              //椅子ID
  //		table.set("szString", (char*)pEvent->GetParam());
  //		BroadCast( "SC_SystemMessage", table);
  //	}
  //}
}

int CTableFrameSink::GetTableID() { return m_TableID; }

void CTableFrameSink::BroadCast(const char* MsgName,const lua_tinker::table& Msg) {
  lua_tinker::call<void>(
      LuaRuntime::instance()->LuaState(), "broadcast2client_pb", m_RoomID,
      m_TableID, MsgName, Msg);
}

void CTableFrameSink::SendTo(int Guid, const char* MsgName,const lua_tinker::table& Msg) {
  lua_tinker::call<void, int, const char*, table>(
      LuaRuntime::instance()->LuaState(), "send2client_pb", Guid, MsgName,
      Msg);
}