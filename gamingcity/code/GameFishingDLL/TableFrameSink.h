#pragma once

#include "common.h"

#include "BaseStruct.h"
#include "Bullet.h"
#include "Define.h"
#include "Effect.h"
#include "EffectManager.h"
#include "Fish.h"
#include "GameLog.h"
#include "MoveCompent.h"
#include "MyObjectManager.h"
#include "Player.h"
#include "LuaRuntime.h"

extern "C" {
#include "lauxlib.h"
#include "lua.hpp"
#include "lualib.h"
}

#include <iostream>
#include <list>

using namespace lua_tinker;

using namespace std;

class CMyEvent;

//刷新鱼群
struct RefershTroop {
  bool bSendDes;     //发送描述
  bool bSendTroop;   //发送鱼群
  float fBeginTime;  //开始时间
};

//游戏桌子类
class CTableFrameSink {
 public:
  CTableFrameSink();
  ~CTableFrameSink();

 public:
  void ResetTable();
  bool Initialization(table luaTable);
  void UpdateConfig(int cell_money, int tax, int tax_show);

 public:
  bool OnEventGameStart();
  bool OnEventGameConclude(uint32_t Guid, int wChairID, uint8_t cbReason);
  bool OnEventSendGameScene(uint32_t GuID, int wChairID, uint8_t cbGameStatus,
                            bool bSendSecret);
  bool OnReady(int wChairID);

 public:
  bool OnActionUserSitDown(int wChairID, table player);
  bool OnActionUserStandUp(uint32_t Guid, int wChairID, bool is_offline);
  bool OnActionUserOffLine(table player, int Guid) { return true; }

  void OnGameUpdate();
  bool OnTimeSync(int guid, int chair_id, int client_tick);
  bool OnChangeCannon(int guid, int chair_id, int add);
  bool OnFire(int guid, int chair_id, double direction, int client_id,
              uint32_t FireTime, double pos_x, double pos_y);

  void CatchFish(std::shared_ptr<CBullet> pBullet, std::shared_ptr<CFish> pFish, int nCatch, int* nCatched);
  void SendCatchFish(std::shared_ptr<CBullet> pBullet, std::shared_ptr<CFish> pFish, long long score);
  void DistrubFish(float fdt);
  void ResetSceneDistrub();

  void SendFish(std::shared_ptr<CFish> pFish, int wChairID = 0);
  void SendFishList(int wChairID = 0);
  void SendBullet(std::shared_ptr<CBullet> pBullet, bool bNew = false);
  void SendSceneInfo(int TargetGuid);
  void SendPlayerInfo(int TargetGuid = 0);
  void SendCannonSet(int wChairID);
  void SendGameConfig(int TargetGuid);
  void SendSystemMsg(int TargetGuid, int type, const std::string& msg);
  void ReturnBulletScore(int guid);

  void SendAllowFire(int GuID);

  void OnProduceFish(CMyEvent* pEvent);
  void OnAddBuffer(CMyEvent* pEvent);
  void OnAdwardEvent(CMyEvent* pEvent);
  void OnCannonSetChange(CMyEvent* pEvent);
  void OnCatchFishBroadCast(CMyEvent* pEvent);
  void OnFirstFire(CMyEvent* pEvent);
  void OnMulChange(CMyEvent* pEvent);

  void LockFish(int wChairID);
  bool OnLockFish(int guid, int chair_id, int isLock);
  bool OnLockSpecFish(int guid, int chair_id, int fishID);
  bool OnNetCast(int guid, int chair_id, int bullet_id, int data, int fish_id);
  bool OnChangeCannonSet(int guid, int chair_id, int add);
  bool HasRealPlayer();
  void AddBuffer(int btp, float parm, float ft);

  int CountPlayer();

  bool HasPlayer(int guid = 0, int chair_id = 0);

  void ClearBullets(int chair_id);

 public:
  static void LoadConfig();

  bool OnTreasureEND(table player, int64_t score);

  int GetTableID();
  void BroadCast(const char* MsgName, const table& Msg);
  void SendTo(int Guid, const char* MsgName, const table& Msg);

 protected:
  bool IsUserInTable(int Guid);
  bool IsUserSitDownChair(int ChairID);

  float get_room_bullet_cell_money();  //获取房间倍率

  int getRoomWeight();              //获取房间系数
  int getFishWeight(std::shared_ptr<CFish> pFish);  //获取鱼系数
  int getPlayerWeight(int guid);    //获取玩家系数

  void UpdateFireLog(int guid, int fire_mul,
                     int fire_cost);  //向lua更新开炮记录
  void SubtractFireLog(int guid, int fire_mul, int fire_cost);  //减掉开炮记录
  void UpdateCatchLog(int guid, int fish_type_id, int64_t multi,
                      int score);  //向lua更新打鱼记录
  void UpdateHitLog(int guid, int fish_type_id,
                    int64_t connon_cost);  //像lua更新击中鱼记录

 protected:
  uint32_t m_dwLastTick;     //上一次扫描时间
  float m_fSceneTime;        //场景时间
  int m_nCurScene;           //当前场景
  std::shared_ptr<MyObjMgr> m_FishManager;    //鱼管理器
  std::shared_ptr<MyObjMgr> m_BulletManager;  //子弹管理器
  bool m_bAllowFire;         //可以开火
  float m_fPauseTime;        //暂停时间

  int m_nSpecialCount;                        //特殊鱼数量
  std::list<uint32_t> m_CanLockList;          //可锁定列表
  std::vector<float> m_vDistrubFishTime;      //干扰时间
  std::vector<RefershTroop> m_vDistrubTroop;  //干扰鱼群
  std::unordered_map<int, std::shared_ptr<CPlayer>> m_GuidPlayers;
  std::unordered_map<int, std::shared_ptr<CPlayer>> m_ChairPlayers;
  int m_nFishCount;  //鱼数量

  std::unordered_map<int, int64_t> m_UserWinScore;  // Chair用户的总输赢

  int m_TableID;
  int m_RoomID;
  int m_cell_money;  //底注
  int m_tax;         //税收
  int m_tax_show;    //是否显示税收

  std::recursive_mutex m_mutex;
  lua_State* m_L;
};

//////////////////////////////////////////////////////////////////////////
