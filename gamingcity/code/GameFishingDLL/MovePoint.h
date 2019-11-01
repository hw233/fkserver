////
#ifndef __MOVE_POINT_H__
#define __MOVE_POINT_H__

#include <vector>
#include "Point.h"

class CMovePoint {
 public:
  CMovePoint();
  CMovePoint(MyPoint pos, float dir);

  virtual ~CMovePoint();

 public:
  MyPoint m_Position;  //坐标
  float m_Direction;   //方向
};

typedef std::vector<CMovePoint> MovePoints;

#endif
