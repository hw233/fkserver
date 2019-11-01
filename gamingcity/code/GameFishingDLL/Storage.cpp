#include "Storage.h"

#include "LuaRuntime.h"
#include "lua_tinker.h"

Storage& Storage::instance() {
  static Storage* sInstance = new Storage();
  return *sInstance;
}

Storage::~Storage() {}

void Storage::onUserFire(int fireBulletMutiple) {
  m_RevenueRatio = lua_tinker::call<float>(
      LuaRuntime::instance()->LuaState(), "get_revenue_ratio");
  m_Revenue += ceil(((double)fireBulletMutiple) * m_RevenueRatio);
  m_Storage += ((double)fireBulletMutiple) * (1.0f - m_RevenueRatio);
}

void Storage::onCatchFish(int allFishScore) { m_Storage -= allFishScore; }

float Storage::getProbabilityRatio(float fishMulti) {
  return lua_tinker::call<float, int64_t, float>(
      LuaRuntime::instance()->LuaState(), "calc_storage_probability_ratio",
      m_Storage, 10000.0 / fishMulti);
}

Storage::Storage() {
  m_RevenueRatio = lua_tinker::get<float>(LuaRuntime::instance()->LuaState(),
                                          "revenue_ratio");
  m_RevenueRatio =
      m_RevenueRatio > 1 ? 1 : m_RevenueRatio < 0 ? 0 : m_RevenueRatio;
  m_Storage = lua_tinker::get<int64_t>(LuaRuntime::instance()->LuaState(),
                                       "beginning_storage");
}
