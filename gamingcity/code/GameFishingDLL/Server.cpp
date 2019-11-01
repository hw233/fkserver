#include <stdio.h>
#include <iostream>
#include <string>
using namespace std;
#include <math.h>
#include <cmath>
extern "C" {
#include "lauxlib.h"
#include "lua.hpp"
#include "lualib.h"
}

#define LUA_BUILD_AS_DLL

#include "common.h"

#include "BufferFactory.h"
#include "BufferManager.h"
#include "EffectFactory.h"
#include "EffectManager.h"
#include "LuaRuntime.h"
#include "MyComponentFactory.h"
#include "MyObjectFactory.h"
#include "Storage.h"
#include "TableframeSink.h"
#include "lua_tinker.h"

#include <iostream>

using namespace lua_tinker;

static int Init(lua_State* L) {
  std::cout << "初始化......" << std::endl;

  lua_tinker::class_def<CTableFrameSink>(L, "FishingTable")
  .constructor<>()
  .function("Initialization",&CTableFrameSink::Initialization)
  .function("OnEventGameStart",&CTableFrameSink::OnEventGameStart)
  .function("OnEventGameConclude",&CTableFrameSink::OnEventGameConclude)
  .function("OnEventSendGameScene",&CTableFrameSink::OnEventSendGameScene)
  .function("OnGameUpdate",&CTableFrameSink::OnGameUpdate)
  .function("OnLockFish",&CTableFrameSink::OnLockFish)
  .function("OnLockSpecFish",&CTableFrameSink::OnLockSpecFish)
  .function("OnNetCast",&CTableFrameSink::OnNetCast)
  .function("OnTimeSync",&CTableFrameSink::OnTimeSync)
  .function("OnChangeCannon",&CTableFrameSink::OnChangeCannon)
  .function("OnChangeCannonSet",&CTableFrameSink::OnChangeCannonSet)
  .function("OnFire",&CTableFrameSink::OnFire)
  .function("OnActionUserSitDown",&CTableFrameSink::OnActionUserSitDown)
  .function("OnActionUserStandUp",&CTableFrameSink::OnActionUserStandUp)
  .function("OnReady",&CTableFrameSink::OnReady)
  .function("UpdateConfig",&CTableFrameSink::UpdateConfig);

  REGISTER_OBJ_TYPE(EOT_PLAYER, CPlayer);
  REGISTER_OBJ_TYPE(EOT_BULLET, CBullet);
  REGISTER_OBJ_TYPE(EOT_FISH, CFish);

  REGISTER_EFFECT_TYPE(ETP_ADDMONEY, CEffectAddMoney);
  REGISTER_EFFECT_TYPE(ETP_KILL, CEffectKill);
  REGISTER_EFFECT_TYPE(ETP_ADDBUFFER, CEffectAddBuffer);
  REGISTER_EFFECT_TYPE(ETP_PRODUCE, CEffectProduce);
  REGISTER_EFFECT_TYPE(ETP_BLACKWATER, CEffectBlackWater);
  REGISTER_EFFECT_TYPE(ETP_AWARD, CEffectAward);

  REGISTER_BUFFER_TYPE(EBT_CHANGESPEED, CSpeedBuffer);
  REGISTER_BUFFER_TYPE(EBT_DOUBLE_CANNON, CDoubleCannon);
  REGISTER_BUFFER_TYPE(EBT_ION_CANNON, CIonCannon);
  REGISTER_BUFFER_TYPE(EBT_ADDMUL_BYHIT, CAddMulByHit);

  REGISTER_MYCOMPONENT_TYPE(EMCT_PATH, MoveByPath);
  REGISTER_MYCOMPONENT_TYPE(EMCT_DIRECTION, MoveByDirection);

  REGISTER_MYCOMPONENT_TYPE(EECT_MGR, EffectMgr);
  REGISTER_MYCOMPONENT_TYPE(EBCT_BUFFERMGR, BufferMgr);
  return 1;
}

class GameFishingModule {
 public:
  static GameFishingModule* instance(lua_State* L = nullptr) {
    if (!sInstance) {
      sInstance = new GameFishingModule(L);
    }

    return sInstance;
  }

  static void Destroy() {
    LuaRuntime::Destory();

    delete sInstance;
    sInstance = nullptr;
  }

 private:
  GameFishingModule(lua_State* L) {
    LuaRuntime::instance(L);

    Init(L);
    CTableFrameSink::LoadConfig();
  }

  ~GameFishingModule() {}

  static GameFishingModule* sInstance;
};

GameFishingModule* GameFishingModule::sInstance = nullptr;

// dll通过函数luaI_openlib导出，然后lua使用package.loadlib导入库函数
extern "C"
#ifdef PLATFORM_WINDOWS
__declspec(dllexport)
#else
__attribute__ ((visibility("default")))
#endif
int luaopen_GameFishingDLL(
            lua_State* L)  //需要注意的地方,此函数命名与库名一致
{
  GameFishingModule::instance(L);
  return 1;
}

#ifdef PLATFORM_WINDOWS
BOOL WINAPI DllMain(HINSTANCE hinstDLL, uint32_t fdwReason, LPVOID lpReserved) {
  // Perform actions based on the reason for calling.
  switch (fdwReason) {
    case DLL_PROCESS_ATTACH: {
    } break;

    case DLL_THREAD_ATTACH:
      // Do thread-specific initialization.
      break;

    case DLL_THREAD_DETACH:
      // Do thread-specific cleanup.
      break;

    case DLL_PROCESS_DETACH:
      // Perform any necessary cleanup.
      break;
  }
  return TRUE;  // Successful DLL_PROCESS_ATTACH.
}
#endif