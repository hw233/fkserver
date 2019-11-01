#pragma once
#include <stdint.h>
#include <mutex>
#include <random>
#include "GameLog.h"
#include "common.h"
#include <type_traits>

class RandomHelper {
 public:
  static int rand_ex(int min1, int max1, int prob, int min2, int max2) {
    if (rand<int>(1, 100) <= prob) {
      return rand<int>(min2, max2);
    }
    return rand<int>(min1, max1);
  }

  template<class T>
  static T rand(T min, T max) {
	auto seed = std::random_device()();
	std::mt19937 gen(seed);
	typedef typename std::conditional<std::is_floating_point<T>::value,
		typename std::uniform_real_distribution<T>,typename std::uniform_int_distribution<T>
		>::type uniform_distribution_t;
	return uniform_distribution_t(min,max)(gen);
  }
};
