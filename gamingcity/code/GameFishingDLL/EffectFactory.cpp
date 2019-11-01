#include "EffectFactory.h"

SingletonInstance(EffectFactory);

EffectFactory::EffectFactory()
{
	m_nPoolSize = 10001;
}

EffectFactory::~EffectFactory()
{

}

std::shared_ptr<CEffect> EffectFactory::Create(int objType)
{
	auto eff = Factory<int, CEffect>::Create(objType);
	if(eff != NULL)
	{
		eff->SetEffectType((EffectType)objType);
	}
	return eff;
}






