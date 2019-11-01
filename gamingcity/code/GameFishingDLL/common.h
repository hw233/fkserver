#pragma once

#include "preinclude.h"

// 游戏人数
#define GAME_PLAYER CGameConfig::instance()->nPlayerCount

#define MAX_PROBABILITY 1000
#define MAX_FISH_HIT_CONST 1000
//#define GAME_FPS			60// del lee 2016.03.07
#define GAME_FPS 30        // 修改成30帧 add lee 2016.03.07
#define MAX_TABLE_CHAIR 4  // 每张桌子椅子个数

#define SCENE_CHANAGE_NONE -1

#define SWITCH_SCENE_END 8

#ifndef PLATFORM_LINUX

#define M_E 2.71828182845904523536
#define M_LOG2E 1.44269504088896340736
#define M_LOG10E 0.434294481903251827651
#define M_LN2 0.693147180559945309417
#define M_LN10 2.30258509299404568402
#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.785398163397448309616
#define M_1_PI 0.318309886183790671538
#define M_2_PI 0.636619772367581343076
#define M_2_SQRTPI 1.12837916709551257390
#define M_SQRT2 1.41421356237309504880
#define M_SQRT1_2 0.707106781186547524401

#endif

enum SMT_TYPE {
  SMT_CHAT = 1,
  SMT_EJECT = 2,
  SMT_GLOBAL = 4,
  SMT_PROMPT = 8,
  SMT_TABLE_ROLL = 16,
  SMT_SCORE = 32
};

#define SAFE_DELETE(x) \
  {                    \
    if (0 != (x)) { \
      delete (x);      \
      (x) = 0;      \
    }  \
  }

#ifdef PLATFORM_WINDOWS
#include <stdio.h>
#include <timeapi.h>
#include <windows.h>
#include <cstdint>

#pragma comment(lib, "winmm.lib")
#endif

#ifdef PLATFORM_LINUX

uint32_t timeGetTime();

#endif

#include <sstream>

class fmt{
public:
    static std::stringstream& ssformat(std::stringstream& ss){
        return ss;
    }

    template<class TArg1,class...TArgs>
    static std::stringstream& ssformat(std::stringstream& ss,const TArg1& arg1,const TArgs&...args){
        ss << arg1;
        ssformat(ss,args...);
        return ss;
    }

    template<class...TArgs>
    static std::string tostring(const TArgs&...args){
        std::stringstream ss;
        ssformat(ss,args...);
        return std::move(ss.str());
    }
};