////
#ifndef __MyObjMgr_h__
#define __MyObjMgr_h__

#include "MyObject.h"
#include <list>
#include <mutex>

typedef std::map< uint32_t, std::shared_ptr<MyObject> > obj_table_t;
typedef obj_table_t::iterator obj_table_iter;

class MyObjMgr
{
public:
	template<class T>
	std::shared_ptr<T> Find(uint32_t nID);

	template<class T>
	void Add(std::shared_ptr<T> pObj);//添加一个角色到列表

	template<class T>
	void Remove(std::shared_ptr<T> pObj);
	
	void Remove(uint32_t nID);

	void OnUpdate(uint32_t);

	obj_table_iter Begin();
	obj_table_iter End();

	void Clear();//清除所有角色

	int CountObject();//统计角色数量

	MyObjMgr();
	~MyObjMgr();
public:// add lee 2016.04.01
	void Lock(void);
	void Unlock(void);
protected:
	obj_table_t m_mapObject;

	std::recursive_mutex m_lock;// add lee 2016.04.01
};

#endif//__MyObjMgr_h__
