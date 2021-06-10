#include "common.h"
#include "Player.h"
#include "GameConfig.h"
#include "MathAide.h"
#include "EventMgr.h"

CPlayer::CPlayer()
:m_dwLastFireTick(timeGetTime())
,m_Wastage(0)
,m_nCannonType(0)
,m_nMultiply(0)
,m_CannonPos()
,m_dwLockFishID(0)
,m_bLocking(false)
,BulletCount(0)
,bFired(false)
,m_nCannonSetType(0)
,m_bCanFire(true)
, guid_(0)
, gate_id_(0)
, chair_id_(0)
{
	SetObjType(EOT_PLAYER);
}

CPlayer::~CPlayer()
{
}

void CPlayer::ClearSet(int chairid)
{
	SetScore(0);
	SetProbability(MAX_PROBABILITY);
	m_Wastage = 0;
	m_nCannonType = CGameConfig::GetInstance()->BulletVector[0].nCannonType;
	m_nMultiply = 0;
	BulletCount = 0;
	bFired = false;
	m_nCannonSetType = 0;
	m_bCanFire = true;
	gate_id_ = 0;
	chair_id_ = 0;
	CacluteCannonPos(chairid);

	auto tick = timeGetTime();
	SetCreateTick(tick);
	SetLastFireTick(tick);

	LockBuffer.clear();
	m_dwLockFishID = 0;
}
//�������λ��
void CPlayer::CacluteCannonPos(unsigned int chairid)
{
    //��������
	MyPoint CannonPos;
    //��ȡ��������
	CannonPos.x_ = CGameConfig::GetInstance()->CannonPos[chairid].m_Position.x_ * CGameConfig::GetInstance()->nDefaultWidth;
	CannonPos.y_ = CGameConfig::GetInstance()->CannonPos[chairid].m_Position.y_ * CGameConfig::GetInstance()->nDefaultHeight;

    //����
	std::vector<CannonSetS>::iterator ic = CGameConfig::GetInstance()->CannonSetArray.begin();

    //��ȡ��һ���ڼ�
	CannonSetS& css = CGameConfig::GetInstance()->CannonSetArray[0];
    //���ұ����������
	std::map<int, CannonSet>::iterator ics = css.Sets.find(m_nCannonType);
    //���û�ҵ�ѡ���һ������
    if (ics == css.Sets.end())
    {
        ics = css.Sets.begin();
    }
	std::vector<CannonPart>::iterator icp = ics->second.vCannonParts.begin();
	while(icp != ics->second.vCannonParts.end())
	{
		if(icp->nType == EPT_CANNON)
		{//�ҵ�����Ϊ���ڵ� ��ȥ����������
			CannonPos = CMathAide::GetRotationPosByOffest(CannonPos.x_, CannonPos.y_, icp->Pos.x_, 
				icp->Pos.y_, CGameConfig::GetInstance()->CannonPos[chairid].m_Direction, 1.0f, 1.0f);
			break;
		}
		++icp;
	}
	SetCannonPos(CannonPos);
}

void CPlayer::SetLockFishID(uint32_t id)
{
	m_dwLockFishID = id; 

	if(m_dwLockFishID != 0)
		LockBuffer.push_back(id);
	else
		ClearLockedBuffer();
}

bool CPlayer::HasLocked(uint32_t id)
{
	std::list<uint32_t>::iterator i = LockBuffer.begin();
	while(i != LockBuffer.end())
	{
		if(id == *i)
			return true;
		++i;
	}
	return false;
}

void CPlayer::SetFired()
{
	if(!bFired){
		bFired = true;
		RaiseEvent("FirstFire", this);
	}
}

void CPlayer::FromLua(lua_tinker::table player){
	guid_ = player.get<int>("guid");
	chair_id_ = player.get<int>("chair_id");
	m_Score = player.get<lua_tinker::table>("pb_base_info").get<long long>("money");
	nickname_ = player.get<const char*>("nickname");
	m_Level = player.get<lua_tinker::table>("pb_base_info").get<int>("level");
	gate_id_ = player.get<int>("gate_id");
	nickname_ = player.get<const char*>("nickname");
}
