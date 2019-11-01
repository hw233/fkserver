#include "common.h"
#include "PathManager.h"
#include "CommonLogic.h"
#include "MathAide.h"
#include "GameConfig.h"
#include <math.h>
#include "BezierCurve.h"
#include <iostream>
#include "lua_tinker.h"
#include "RandomHelper.h"

using namespace lua_tinker;

SingletonInstance(PathManager);

PathManager::PathManager()
:m_bLoaded(false)
{
}

PathManager::~PathManager()
{
	m_NormalPaths.clear();
}

SPATH* PathManager::GetNormalPath(int id)
{
	if(!m_bLoaded || id < 0)
	{
		return NULL;
	}

	return &(m_NormalPaths[id % m_NormalPaths.size()]);
}

MovePoints* PathManager::GetPathData(int id, bool bTroop)
{
	if(!m_bLoaded || id < 0)
	{
		return NULL;
	}

	if(bTroop)
	{
		if(m_TroopPathMap.find(id) != m_TroopPathMap.end())
			return &(m_TroopPathMap[id]);
		else
			return NULL;
	}
	else
		return &(m_NormalPathVector[id % m_NormalPathVector.size()]);
}

SPATH* PathManager::GetTroopPath(int id)
{
	std::map<int, SPATH>::iterator it = m_TroopPath.find(id);
	if(it != m_TroopPath.end())
		return &(it->second);

	return NULL;
}

Troop* PathManager::GetTroop(int id)
{
	std::map<int, Troop>::iterator it = m_TroopMap.find(id);
	if(it == m_TroopMap.end()) return NULL;

	return &(it->second);
}

int PathManager::GetRandNormalPathID()
{
	if(!m_bLoaded)
		return 0;

	static int path_ignore[] = { 4, 10, 15, 35 };

	int path =  RandomHelper::rand<int>(0, m_NormalPathVector.size() - 1);;
	//do{
	//again:
	//	for (int i = 0; i < sizeof(path_ignore) / sizeof(path_ignore[0]); i++){
	//		if (path >= (path_ignore[i] - 1) * 16 && path < path_ignore[i] * 16){
	//			goto again;
	//		}
	//	}

	//	break;

	//	path = RandInt(0, m_NormalPathVector.size() - 1);
	//} while (1);

	//std::cout << path / 16 << std::endl;

	return path;
}

void PathManager::CreatTroopByData(TroopData& td, Troop& tp)
{
	tp.Describe.clear();
	tp.Shape.clear();
	tp.nStep.clear();

	tp.nTroopID = td.nTroopID;

	std::vector<std::string>::iterator ids = td.szDescrib.begin();
	while(ids != td.szDescrib.end())
	{
		if((*ids).length() > 0)
		{
			/*wchar_t szinof[256];
			uint32_t	nLen = MultiByteToWideChar(CP_UTF8, 0, (*ids).c_str(), (*ids).length(), NULL, 0);
			MultiByteToWideChar(CP_UTF8, 0,(*ids).c_str(), (*ids).length(), szinof, nLen);
			szinof[nLen] = wchar_t('\0');

			tp.Describe.push_back(szinof);*/
			tp.Describe.push_back(*ids);
		}
		++ids;
	}

	for (ShapeLine sl:td.LineData)
	{
		MovePoints TraceVector;

		int nc = sl.m_nCount-1;
		if(nc <= 0) nc = 1;
		CMathAide::BuildLinear(sl.x, sl.y, 2, TraceVector, CMathAide::CalcDistance(sl.x[0],sl.y[0],sl.x[1],sl.y[1])/nc);
		nc = TraceVector.size();

		for(int i = 0; i < nc; ++i)
		{
			ShapePoint tt;
			tt.x = TraceVector[i].m_Position.x_;
			tt.y = TraceVector[i].m_Position.y_;
			tt.m_bSame = sl.m_bSame;
			tt.m_nCount = sl.m_PriceCount;
			tt.m_nPathID = sl.m_nPathID;
			tt.m_fInterval = sl.m_fInterval;
			tt.m_fSpeed = sl.m_fSpeed;

			int nt = std::min(sl.m_lTypeList.size(), sl.m_lWeight.size());
			for(int j = 0; j < nt; ++j)
			{
				tt.m_lTypeList.push_back(sl.m_lTypeList[j]);
				tt.m_lWeight.push_back(sl.m_lWeight[j]);
			}
			tp.Shape.push_back(tt);
		}
		tp.nStep.push_back(nc);
	}

	for (ShapeCircle sc: td.CircleData)
	{
		MovePoints TraceVector;

		int nc = sc.m_nCount;
		if(nc <= 0) nc = 1;
		CMathAide::BuildCircle(sc.x, sc.y, sc.r, TraceVector, nc);
		nc = TraceVector.size();

		for(int i = 0; i < nc; ++i)
		{
			ShapePoint tt;
			tt.x = TraceVector[i].m_Position.x_;
			tt.y = TraceVector[i].m_Position.y_;
			tt.m_bSame = sc.m_bSame;
			tt.m_nCount = sc.m_PriceCount;
			tt.m_nPathID = sc.m_nPathID;
			tt.m_fInterval = sc.m_fInterval;
			tt.m_fSpeed = sc.m_fSpeed;

			int nt = std::min(sc.m_lTypeList.size(), sc.m_lWeight.size());
			for(int j = 0; j < nt; ++j)
			{
				tt.m_lTypeList.push_back(sc.m_lTypeList[j]);
				tt.m_lWeight.push_back(sc.m_lWeight[j]);
			}
			tp.Shape.push_back(tt);
		}
		tp.nStep.push_back(nc);
	}

	std::vector<ShapePoint>::iterator ip = td.PointData.begin();
	while(ip != td.PointData.end())
	{
		tp.Shape.push_back(*ip);
		tp.nStep.push_back(1);
		++ip;
	}
}


bool PathManager::LoadTroop(lua_State* L){
	global g(L);
	table TPS = g["troop_set"];
	for (table::iterator iter(TPS);iter;iter++){
		TroopData td = {0};
		table one_troop = iter.value();
		td.nTroopID = iter.key();
		table des = one_troop["describe_text"];
		for(int j = 1;j <= des.size();j++){
			td.szDescrib.push_back((char*)des[j]);
		}

		table shapes = one_troop["shape"];
		for (table::iterator shapeIter(shapes);shapeIter;shapeIter++){
			table one_shape = shapeIter.value();
			int type = one_shape["type"];
			if (type == 0){//直锟斤拷
				ShapeLine sl = {0};
				sl.x[0] = one_shape["pos_x1"];
				sl.x[1] = one_shape["pos_x2"];
				sl.y[0] = one_shape["pos_y1"];
				sl.y[1] = one_shape["pos_y2"];
				sl.m_bSame = one_shape["same"];
				sl.m_PriceCount = one_shape["pice_count"];
				sl.m_nCount = one_shape["count"];
				sl.m_nPathID = one_shape["path"];
				sl.m_fInterval = one_shape["interval"];
				sl.m_fSpeed = one_shape["speed"];

				table ts = one_shape["fish_type"];
				table tw = one_shape["weight"];
				for (int k = 0; k < tw.size(); k++){
					sl.m_lTypeList.push_back(ts[k]);
					int nn = tw[k];
					if (nn <= 0 || nn > 100) nn = 1;
					sl.m_lWeight.push_back(nn);
				}

				td.LineData.push_back(sl);
			}
			else if (type == 1){//圆
				ShapeCircle sc = { 0 };
				sc.x = one_shape["center_x"];
				sc.y = one_shape["center_y"];
				sc.r = one_shape["radio"];
				sc.m_bSame = one_shape["same"];
				sc.m_PriceCount = one_shape["pice_count"];
				sc.m_nCount = one_shape["count"];
				sc.m_nPathID = one_shape["path"];
				sc.m_fInterval = one_shape["interval"];
				sc.m_fSpeed = one_shape["speed"];

				table ts = one_shape["fish_type"];
				table tw = one_shape["weight"];
				for (int k = 0; k < tw.size(); k++){
					sc.m_lTypeList.push_back(ts[k]);
					int nn = tw[k];
					if (nn <= 0 || nn > 100) nn = 1;
					sc.m_lWeight.push_back(nn);
				}

				td.CircleData.push_back(sc);
			}
		}

		table point = one_troop["point"];
		for (table::iterator pointIter(point);pointIter;pointIter++){
			table one_point = pointIter.value();

			ShapePoint tt;
			tt.x = one_point["pos_x"];
			tt.y = one_point["pos_y"];
			tt.m_bSame = one_point["same"];
			tt.m_nCount = one_point["count"];
			tt.m_nPathID = one_point["path"];
			tt.m_fInterval = one_point["interval"];
			tt.m_fSpeed = one_point["speed"];
			table ts = one_point["fish_type"];
			table tw = one_point["weigth"];
			for (table::iterator typeIter(ts); typeIter;typeIter++){
				tt.m_lTypeList.push_back(typeIter.value());
				int weight = tw[(int)typeIter.key()];
				if (weight <= 0 || weight > 100) weight = 1;
				tt.m_lWeight.push_back(weight);
			}

			td.PointData.push_back(tt);
		}

		m_TroopData[td.nTroopID] = td;

		Troop trp;
		CreatTroopByData(td, trp);
		m_TroopMap[td.nTroopID] = trp;
	}

	table TPP = g["path"];
	for (int i = 1; i <= TPP.size(); i++){
		table TPP_one = TPP[i];

		SPATH pd = { 0 };
		int id = TPP_one["id"];
		pd.type = TPP_one["type"];
		pd.PointCount = 0;

		table pt = TPP_one["point"];
		for(int j = 1;j <= pt.size();j++){
			table pt_one = pt[j];
			pd.xPos[pd.PointCount] = pt_one["x"];
			pd.yPos[pd.PointCount++] = pt_one["y"];
		}

		if (pd.type == NPT_LINE){
			pd.PointCount = 2;
		}else if (pd.type == NPT_BEZIER){
			if (pd.xPos[3] == 0.0f && pd.yPos[3] == 0.0f){
				pd.PointCount = 3;
			}
		}else{
			pd.PointCount = PTCOUNT;
		}

		pd.nNext = TPP_one["next"];
		pd.nDelay = TPP_one["delay"];

		m_TroopPath[id] = pd;
	}

	std::vector<int> exclude;
	for (std::map<int, SPATH>::iterator itp = m_TroopPath.begin(); itp != m_TroopPath.end(); ++itp){
		SPATH& sph = itp->second;

		auto ie = exclude.begin();
		while (ie != exclude.end()){
			if (itp->first == *ie)	break;
			++ie;
		}

		if (ie != exclude.end()){
			continue;
		}

		int nxt = sph.nNext;
		while (nxt > 0 && m_TroopPath.find(nxt) != m_TroopPath.end()){
			exclude.push_back(nxt);
			nxt = m_TroopPath[nxt].nNext;
		}

		MovePoints path;
		CreatePathByData(&sph, false, false, false, false, true, path);

		m_TroopPathMap[itp->first] = path;
	}

	return true;
}

bool PathManager::LoadNormalPath(lua_State* L){
	table FishPath = global(L)["fish_path"];
	int size = FishPath.size();
	for (int i = 1; i <= FishPath.size(); i++){
		table path = FishPath[i];

		SPATH pd = {0};
		pd.type = path["type"];
		pd.PointCount = 0;
		pd.nNext = path["next"];
		pd.nDelay = path["delay"];
		pd.nPathType = path["type"];

		table position = path["position"];
		for (int j = 1; j <= position.size(); j++){
			table one_pos = position[j];

			pd.xPos[pd.PointCount] = one_pos["x"];
			pd.yPos[pd.PointCount++] = one_pos["y"];
		}

		if (pd.type == NPT_LINE){
			pd.PointCount = 2;
		}else if (pd.type == NPT_BEZIER){
			if (pd.xPos[3] == 0.0f && pd.yPos[3] == 0.0f){
				pd.PointCount = 3;
			}
		}else{
			pd.PointCount = PTCOUNT;
		}

		m_NormalPaths.push_back(pd);
	}

	int nsize = m_NormalPaths.size();
	m_bLoaded = nsize > 0;

	std::vector<int> exclude;
	for (int i = 0; i < nsize; ++i){
		SPATH& sph = m_NormalPaths[i];

		auto ie = exclude.begin();
		while (ie != exclude.end()){
			if (i == *ie) break;
			++ie;
		}

		if (ie != exclude.end()){
			continue;
		}

		int nxt = sph.nNext;
		while (nxt > 0 && nxt < nsize){
			exclude.push_back(nxt);
			nxt = m_NormalPaths[nxt].nNext;
		}

		MovePoints path;

		for (int x = 0; x < 2; ++x){
			for (int y = 0; y < 2; ++y){
				for (int xy = 0; xy < 2; ++xy){
					for (int nt = 0; nt < 2; ++nt){
						CreatePathByData(&sph, x == 0, y == 0, xy == 0, nt == 0, false, path);
						m_NormalPathVector.push_back(path);
					}
				}
			}
		}
	}

	return true;
}

void PathManager::CreatePathByData(SPATH* sp, bool xMirror, bool yMirror, bool xyMirror, bool Not, bool troop, MovePoints& out)
{
	out.clear();
	while(sp != NULL)
	{
		MovePoints path;

		float x[4], y[4];
		for (int n = 0; n < sp->PointCount; ++n)
		{
			x[n] = sp->xPos[n];
			y[n] = sp->yPos[n];
		}

		if(xMirror)
		{
			if(sp->type == NPT_CIRCLE)
			{
				x[0] = 1.0f - x[0];
				x[2] = M_PI - x[2];
				y[2] = -y[2];
			}
			else
			{
				for (int n = 0; n < sp->PointCount; ++n)
				{
					x[n] = 1.0f - x[n];
				}
			}
		}
		if(yMirror)
		{
			if(sp->type == NPT_CIRCLE)
			{
				y[0] = 1.0f - y[0];
				x[2] = 2 * M_PI - x[2];
				y[2] = -y[2];
			}
			else
			{
				for (int n = 0; n < sp->PointCount; ++n)
				{
					y[n] = 1.0f - y[n];
				}
			}
		}

		if(xyMirror)
		{
			if(sp->type == NPT_CIRCLE)
			{
				float t = x[0];
				x[0] = 1.0f - y[0];
				y[0] = 1.0f - t;
				x[2] += M_PI_2;
			}
			else
			{
				for (int n = 0; n < sp->PointCount; ++n)
				{
					float t = x[n];
					x[n] = y[n];
					y[n] = t;
				}
			}
		}

		if(Not)//取锟斤拷
		{
			if(sp->type == NPT_CIRCLE)
			{
				x[2] += y[2];
				y[2] = -y[2];
			}
			else
			{
				for (int n = 0; n < sp->PointCount / 2; ++n)
				{
					float t = x[n];
					x[n] = x[sp->PointCount-1-n];
					x[sp->PointCount-1-n] = t;

					t = y[n];
					y[n] = y[sp->PointCount-1-n];
					y[sp->PointCount-1-n] = t;
				}
			}
		}

		
		for (int n = 0; n < sp->PointCount; ++n)
		{
			x[n] = x[n] * CGameConfig::instance()->nDefaultWidth;
			y[n] = y[n] * CGameConfig::instance()->nDefaultHeight;

			if(sp->type == NPT_CIRCLE)
				break;
		}

		if(sp->type == NPT_LINE)
			CMathAide::BuildLinear(x, y, sp->PointCount, path, 1.0f);
		else if (sp->type == NPT_BEZIER)
		{
			//CMathAide::BuildBezier(x, y, sp->PointCount, path, 1.0f);
			CBezierCurve::instance()->Bezier2D(x, y, sp->PointCount, 2000, path, 1.0f);
		}
		else if(sp->type == NPT_CIRCLE)
			CMathAide::BuildCirclePath(x[0], y[0], x[1], path, x[2], y[2], 1, y[1]);

// 		CMovePoint* pt = NULL;
// 		MovePoints::iterator ip = path.begin();
// 		while(ip != path.end())
// 		{
// 			pt = &(*ip);
// 			out.push_back(*ip);
// 			++ip;
// 		}
// 
// 		if(sp->nDelay != 0 && pt != NULL)
// 		{
// 			for(int i = 0; i < sp->nDelay; ++i)
// 				out.push_back(*pt);
// 		}

 		MovePoints::iterator ip = path.begin();
		while (ip != path.end())
		{
			out.push_back(*ip);
			++ip;
		}

		if (sp->nDelay != 0)
		{
			CMovePoint& pt = path[path.size() - 1];
			for (int i = 0; i < sp->nDelay; ++i)
				out.push_back(pt);
		}

		if(troop)
		{
			int nxt = sp->nNext;
			if (nxt > 0 && m_TroopPath.find(nxt) != m_TroopPath.end())
			{
				sp = &(m_TroopPath[nxt]);
			} 
			else
			{
				break;
			}
		}
		else
		{
			if(sp->nNext > 0 && sp->nNext < m_NormalPaths.size())
			{
				sp = &(m_NormalPaths[sp->nNext]);
			}
			else
			{
				break;
			}
		}
	}	
}








