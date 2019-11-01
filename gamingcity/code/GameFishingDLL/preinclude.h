#pragma once

// 平台定义
#if defined(_WIN32) || defined(_WIN64)
#define PLATFORM_WINDOWS
#else
#define PLATFORM_LINUX
#endif


#include <stdint.h>

#ifdef PLATFORM_WINDOWS
#include <Windows.h>
#define WIN32_LEAN_AND_MEAN
#include <process.h>
#include <psapi.h>
#pragma comment(lib,"psapi.lib")
#endif

#ifdef PLATFORM_LINUX
#include <unistd.h>

uint32_t timeGetTime();
#endif

// c
#include <cstdlib>
#include <cstdio>
#include <malloc.h>
#include <memory.h>
#include <cassert>
#include <cctype>
#include <cmath>
#include <ctime>
#include <stdarg.h>

// stl

#include <limits>
#include <algorithm>
#include <array>
#include <bitset>
#include <complex>
#include <deque>
#include <exception>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <list>
#include <map>
#include <memory>
#include <new>
#include <numeric>
#include <queue>
#include <random>
#include <regex>
#include <set>
#include <sstream>
#include <stack>
#include <string>
#include <tuple>
#include <type_traits>
#include <valarray>
#include <vector>
#include <unordered_set>
#include <unordered_map>
#include <thread>
#include <mutex>

#ifdef PLATFORM_WINDOWS
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>

#ifdef _DEBUG
#define DEBUG_NEW new(_CLIENT_BLOCK, __FILE__, __LINE__)
#endif  // _DEBUG
#endif

#ifdef PLATFORM_LINUX
#define DEBUG_NEW new
#endif

#define MSG_TIMEOUT_LIMIT 30
#define SERVER_HEARTBEAT_TIME 10
#define DO_RECVMSG_PER_TICK_LIMIT 10
#define DO_RECVMSG_VOLIDATE_DATA (256 * 1024)
#define DO_MYSQL_PER_TICK_LIMIT 10
#define DO_REDIS_PER_TICK_LIMIT 100
#define SERVER_TICK_TIMEOUT_GUARD 100
#define MYSQL_RETRY_TIME 5000
#define DO_AI_PER_TICK_LIMIT 10

