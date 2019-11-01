#pragma once
#include <stdint.h>
extern "C" {
#include "lauxlib.h"
#include "lua.hpp"
#include "lualib.h"
}

class Storage {
 public:
  static Storage& instance();
  ~Storage();

  int64_t getStorage() { return m_Storage; }
  void addStorage(int64_t toAdd) { m_Storage += toAdd; }
  int64_t getRevenue() { return m_Revenue; }
  void addRevenue(int64_t toAdd) { m_Revenue += toAdd; }
  float getRevenueRatio() { return m_RevenueRatio; }
  void onUserFire(int fireBulletMutiple);
  void onCatchFish(int allFishScore);

  float getProbabilityRatio(float fishMulti);

 private:
  Storage();

  int64_t m_Storage = 0;
  int64_t m_Revenue = 0;
  float m_RevenueRatio = 0;
};