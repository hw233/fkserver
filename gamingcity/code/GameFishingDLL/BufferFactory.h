#ifndef __BUFFER_FACTORY_H__
#define __BUFFER_FACTORY_H__

#include "Buffer.h"
#include "Factory.h"
#include "Singleton.h"

class BufferFactory: public Factory< int, CBuffer>, public Singleton< BufferFactory >
{
public:
	BufferFactory();
	virtual ~BufferFactory();
	FriendBaseSingleton(BufferFactory);

public:
	virtual std::shared_ptr<CBuffer> Create(int BuffType);
};


template < class _Ty >
class BufferCreator: public Creator< CBuffer >
{
public:
	virtual std::shared_ptr<_Ty> Create()
	{
		return std::make_shared<_Ty>();
	}
};

#define REGISTER_BUFFER_TYPE( typeID, type ) {std::shared_ptr< Creator< CBuffer > > ptr( new BufferCreator< type >()); BufferFactory::instance()->Register(typeID, ptr);}

inline std::shared_ptr<CBuffer> CreateBuffer( int BuffType )
{
	return BufferFactory::instance()->Create(BuffType);
}

#endif
