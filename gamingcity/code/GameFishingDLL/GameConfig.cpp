#include "common.h"
#include "GameConfig.h"
#include "lua_tinker.h"

using namespace lua_tinker;

SingletonInstance(CGameConfig);

CGameConfig::CGameConfig()
	:nDefaultWidth(1440)
	, nDefaultHeight(900)
	, nWidth(1440)
	, nHeight(900)
	, nChangeRatioUserScore(1)
	, nChangeRatioFishScore(1)
	, nExchangeOnce(10000)
	, nFireInterval(300)
	, fHScale(1.0f)
	, fVScale(1.0f)
	, ShowDebugInfo(false)
	, ShowShadow(false)
	, nShowGoldMinMul(10)
	, nMinNotice(200)
	, nMaxBullet(20)
	, nMaxSpecailCount(0)
	, m_MaxCannon(0)
	, nPlayerCount(4)
	, fAndroidProbMul(1.2f)
	, nAddMulBegin(40)
	, nAddMulCur(0)
	, nSnakeHeadType(901)
	, nSnakeTailType(902)
	, bImitationRealPlayer(false)
{
	nSpecialProb[0] = 100;
	for (int i = 1; i < ESFT_MAX; ++i)
		nSpecialProb[i] = 0;
}

CGameConfig::~CGameConfig()
{
}


bool CGameConfig::LoadSystemConfig(lua_State* L){
	table SystemSet = lua_tinker::global(L)["system_set"];
	ShowDebugInfo = SystemSet["show_debug_info"];
	ShowShadow = SystemSet["shadow"];
	bImitationRealPlayer = SystemSet["imitation_real_player"];

	table default_screen_set = SystemSet["default_screen_set"];

	nDefaultWidth = default_screen_set["width"];
	nDefaultHeight = default_screen_set["height"];

	table exchange_score = SystemSet["exchange_score"];
	table ratio = exchange_score["ratio"];
	nChangeRatioUserScore = ratio[1];
	if (nChangeRatioUserScore <= 0) nChangeRatioUserScore = 1;
	nChangeRatioFishScore = ratio[2];
	if (nChangeRatioFishScore <= 0) nChangeRatioFishScore = 1;
	nExchangeOnce = exchange_score["once"];
	if (nExchangeOnce <= 0) nExchangeOnce = 10000;
	nShowGoldMinMul = exchange_score["show_gold_min_mul"];

	table fire_set = SystemSet["fire"];
	nFireInterval = fire_set["interval"];
	nMaxInterval = fire_set["max_interval"];
	nMinInterval = fire_set["min_interval"];
	nMaxBullet = fire_set["max_bullet"];

	table ion_set = SystemSet["ion_set"];
	nIonMultiply = ion_set["multiple"];
	nIonProbability = ion_set["probability"];
	fDoubleTime = ion_set["time"];

	table catch_set = SystemSet["catch"];
	nMinNotice = catch_set["notice_level"];
	fAndroidProbMul = catch_set["android_prob_mul"];

	table special_set = SystemSet["special"];
	nMaxSpecailCount = special_set["max_count"];
	//nSpecialProb[ESFT_KING] = sets["king");
	//nSpecialProb[ESFT_KINGANDQUAN] = sets["king_quan");
	//nSpecialProb[ESFT_SANYUAN] = sets["san_yuan");
	//nSpecialProb[ESFT_SIXI] = sets["sixi");

	table add_mul_set = SystemSet["add_mul"];
	nAddMulBegin = add_mul_set["begin"];

	table snake_set = SystemSet["snake"];
	nSnakeHeadType = snake_set["head"];
	nSnakeTailType = snake_set["tail"];

	FirstFireList.clear();
	table first_fire_set = SystemSet["first_fire"];
	for (int i = 1; i <= first_fire_set.size(); i++){
		table one = first_fire_set[i];
		FirstFire ff;
		ff.nLevel = one["level"];
		ff.nCount = one["count"];
		ff.nPriceCount = one["pirce_count"];

		int tc = one["type_count"];
		table ts = one["type_list"];
		table tw = one["weight_list"];
		for (int j = 1; j <= ts.size(); ++j){
			ff.FishTypeVector.push_back(ts[j]);
			ff.WeightVector.push_back(tw[j]);
		}

		FirstFireList.push_back(ff);
	}

	return true;
}


bool CGameConfig::LoadScenes(lua_State* L){
	SceneSets.clear();
	
	table sst = global(L)["scene"];
	for (table::iterator iter(sst); iter;iter++){
		SceneSet SceSet;
		table sst = iter.value();
		SceSet.nID = iter.key();
		SceSet.fSceneTime = sst["time"];
		SceSet.szMap = (char*)sst["map"];
		SceSet.nNextID = sst["next"];

		table tps = sst["troop_set"];
		for (int j = 1; j <= tps.size();j++){
			TroopSet ts;

			ts.fBeginTime = tps["begin_time"];
			ts.fEndTime = tps["end_time"];
			ts.nTroopID = tps["id"];

			SceSet.TroopList.push_back(ts);
		}

		SceSet.DistrubList.clear();
		table distribute_fish = sst["distrub_fish"];
		for (int j = 1; j <= distribute_fish.size(); j++){
			DistrubFishSet dis;
			dis.ftime = distribute_fish["time"];
			dis.nMinCount = distribute_fish["min_count"];
			dis.nMaxCount = distribute_fish["max_count"];
			dis.nMaxCount = std::max(dis.nMinCount, dis.nMaxCount);
			dis.nRefershType = distribute_fish["refersh_type"];
			table ts = distribute_fish["type_list"];
			table tw = distribute_fish["weight_list"];
			for (int k = 0; k <= ts.size(); ++k){
				dis.FishID.push_back(ts[k]);
				dis.Weight.push_back(tw[k]);
			}

			dis.OffestX = distribute_fish["offest_x"];
			dis.OffestY = distribute_fish["offest_y"];
			dis.OffestTime = distribute_fish["offest_time"];

			SceSet.DistrubList.push_back(dis);
		}

		SceneSets[SceSet.nID] = SceSet;
	}

	return true;
}


bool CGameConfig::LoadFish(lua_State* L){
	table FishSet = lua_tinker::global(L)["fish_set"];
	FishMap.clear();
	for (table::iterator iter(FishSet); iter; iter++){
		Fish ff = {0};

		table fish_one = iter.value();
		ff.nTypeID = iter.key();
		ff.szName = (const char*)fish_one["name"];
		ff.bBroadCast = fish_one["broad_cast"];
		ff.fProbability = fish_one["probability"];
		ff.nSpeed = fish_one["speed"];
		ff.nVisualID = fish_one["visual_id"];
		ff.nBoundBox = fish_one["bounding_box"];
		ff.bShowBingo = fish_one["show_bingo"];
		ff.szParticle = (char*)fish_one["particle"];
		ff.bShakeScree = fish_one["shake_screen"];
		ff.nLockLevel = fish_one["lock_level"];

		table effect = fish_one["effect"];
		for (int j = 1; j <= effect.size();j++){
			table one_effect = effect[j];

			Effect ecf = { 0 };
			ecf.nTypeID = one_effect["type_id"];
			int k = 1;
			table::iterator effect_iter(one_effect);
			effect_iter++;
			for (; effect_iter;effect_iter++,k++){
				ecf.nParam.push_back(one_effect[fmt::tostring("param",k).c_str()]);
			}

			ff.EffectSet.push_back(ecf);
		}

		table buf = fish_one["buffer"];
		for (int j = 1; j <= buf.size();j++){
			table buf_one = buf[j];

			Buffer buf = {0};
			buf.nTypeID = buf_one["type_id"];
			buf.fParam = buf_one["param"];
			buf.fLife = buf_one["life"];

			ff.BufferSet.push_back(buf);
		}

		FishMap[ff.nTypeID] = ff;
	}

	return true;
}


bool CGameConfig::LoadFishSound(lua_State* L){
	table nbbx = global(L)["fish_sound"];
	table fs = nbbx["fish"];
	for (int i = 1; i <= fs.size();i++){
		SoundSet ss;

		table one = fs[i];

		int id = fs["id"];
		ss.szFoundName = (char*)fs["sound"];
		ss.m_nProbility = fs["probility"];

		FishSound[id] = ss;
	}

	return true;
}

bool CGameConfig::LoadBoundBox(lua_State* L){
	BBXMap.clear();
	
	table nbbx = global(L)["bounding_box"];
	for (table::iterator iter(nbbx); iter;iter++){
		std::cout << iter.key().as<int>() << std::endl;
		BBX boubx;
		boubx.nID = iter.key();
		table nbb = iter.value().as<table>()["BB"];
		for (int i = 1; i <= nbb.size();i++){
			BB b;
			table bb = nbb[i];
			b.fRadio = bb["radio"];
			b.nOffestX = bb["offest_x"];
			b.nOffestY = bb["offest_y"];

			boubx.BBList.push_back(b);
		}

		BBXMap[boubx.nID] = boubx;
	}

	return true;
}


bool CGameConfig::LoadBulletSet(lua_State* L){
	BulletVector.clear();
	table BulletSet = global(L)["bullet_set"];
	for (int i = 1; i < BulletSet.size(); i++){
		table one = BulletSet[i];

		Bullet bt;
		bt.nMulriple = one["mulriple"];
		bt.nSpeed = one["speed"];
		bt.nMaxCatch = one["max_catch"];
		bt.nCatchRadio = one["catch_radio"];
		bt.nCannonType = one["cannon_type"];
		bt.nBulletSize = one["bridio"];

		if (m_MaxCannon < bt.nMulriple){
			m_MaxCannon = bt.nMulriple;
		}

		table catchs = one["catch"];
		for (int j = 1; j <= catchs.size();j++){
			table catch_fish = catchs[j];
			bt.ProbabilitySet[catch_fish["fish_id"]] = catch_fish["probability"];
		}

		BulletVector.push_back(bt);
	}

	return true;
}

bool CGameConfig::LoadCannonSet(lua_State* L){
	table CCPOS = global(L)["cannon_pos"];
	table Cannon = CCPOS["cannon"];
	CannonPos.resize(GAME_PLAYER + 1);
	for (table::iterator iter(Cannon);iter;iter++){
		int id = iter.key();
		table value = iter.value();
		CannonPos[id].m_Position.x_ = value["pos_x"];
		CannonPos[id].m_Position.y_ = value["pos_y"];
		CannonPos[id].m_Direction = value["direction"];
	}

	table cef = CCPOS["cannon_effect"];
	szCannonEffect = (char*)cef["name"];
	EffectPos.x_ = cef["pos_x"];
	EffectPos.y_ = cef["pos_y"];

	table lock = CCPOS["lock"];
	LockInfo.szLockIcon = (char*)lock["name"];
	LockInfo.szLockLine = (char*)lock["line"];
	LockInfo.szLockFlag = (char*)lock["flag"];
	LockInfo.Pos.x_ = lock["pos_x"];
	LockInfo.Pos.y_ = lock["pos_y"];

	table jetton = CCPOS["jetton"];
	nJettonCount = jetton["max"];
	JettonPos.x_ = jetton["pos_x"];
	JettonPos.y_ = jetton["pos_y"];


	table cannon_set = global(L)["cannon_set"];
	CannonSetArray.clear();
	for (table::iterator iter(cannon_set); iter; iter++){
		CannonSetS canset = {0};

		canset.nID = iter.key();
		table cannon_one = iter.value();
		canset.bRebound = cannon_one["rebound"];
		canset.nNormalID = cannon_one["normal"];
		canset.nIonID = cannon_one["ion"];
		canset.nDoubleID = cannon_one["double"];

		table CannonType = cannon_one["cannon_type"];
		for (int j = 1; j <= CannonType.size(); j++){
			table connon_type_one = CannonType[j];
			CannonSet ccs = {0};
			ccs.nTypeID = connon_type_one["type"];
			table cannon_part = connon_type_one["cannon"];
			for (int k = 1; k <= cannon_part.size(); k++){
				CannonPart cpt;
				table part_one = cannon_part[k];
				cpt.szResourceName = (char*)part_one["res_name"];
				cpt.nResType = part_one["res_type"];
				cpt.Pos.x_ = part_one["pos_x"];
				cpt.Pos.y_ = part_one["pos_y"];
				cpt.FireOfffest = part_one["fire_offest"];
				cpt.nType = part_one["type"];
				cpt.RoateSpeed = part_one["roate_speed"];

				ccs.vCannonParts.push_back(cpt);
			}

			table bullet = connon_type_one["bullet"];
			for (int k = 1; k <= bullet.size(); k++){
				table bullet_one = bullet[k];
				CannonBullet cb;
				cb.szResourceName = (char*)bullet_one["res_name"];
				cb.nResType = bullet_one["res_type"];
				cb.fScale = bullet_one["scale"];
				cb.Pos.x_ = bullet_one["pos_x"];
				cb.Pos.y_ = bullet_one["pos_y"];
				ccs.BulletSet.push_back(cb);
			}

			table net = connon_type_one["net"];
			for (int k = 1; k <= net.size(); k++){
				CannonNet ns;
				table net_one = net[k];
				ns.szResourceName = (char*)net_one["res_name"];
				ns.nResType = net_one["res_type"];
				ns.fScale = net_one["scale"];
				ns.Pos.x_ = net_one["pos_x"];
				ns.Pos.y_ = net_one["pos_y"];
				ccs.NetSet.push_back(ns);
			}

			canset.Sets[ccs.nTypeID] = ccs;
		}

		CannonSetArray.push_back(canset);
	}

	return true;
}


bool CGameConfig::LoadVisual(lua_State* L){
	table VisualSet = global(L)["visual_set"];
	table visual = VisualSet["visual"];
	VisualMap.clear();
	for (int i = 1; i <= visual.size();i++){
		Visual vs;
		vs.nID = visual["id"];
		vs.nTypeID = visual["type_id"];

		table image = visual["life_image"];
		for (int j = 1; j <= image.size();j++){
			ImageInfo imi;
			imi.szImageName = (char*)image["name"];
			imi.fImageScale = image["scale"];
			imi.ImageOffest.m_Position.x_ = image["offest_x"];
			imi.ImageOffest.m_Position.y_ = image["offest_y"];
			imi.ImageOffest.m_Direction = image["direction"];

			imi.nAniType = image["ani_type"];

			vs.ImageInfoLive.push_back(imi);
		}

		image = visual["dead_image"];
		for (int j = 1; j <= image.size();j++){
			ImageInfo imi;
			imi.szImageName = (char*)image["name"];
			imi.fImageScale = image["scale"];

			imi.ImageOffest.m_Position.x_ = image["offest_x"];
			imi.ImageOffest.m_Position.y_ = image["offest_y"];
			imi.ImageOffest.m_Direction = image["direction"];

			imi.nAniType = image["ani_type"];

			vs.ImageInfoDead.push_back(imi);
		}

		VisualMap[vs.nID] = vs;
	}
	return true;
}

bool CGameConfig::LoadSpecialFish(lua_State* L){
	KingFishMap.clear();
	global g(L);
	table king = g["fish_king"];
	for (table::iterator iter(king); iter; iter++){
		SpecialSet ks;

		table one = iter.value();
		ks.nTypeID = iter.key();

		ks.fProbability = one["probability"];
		ks.nMaxScore = one["max_score"];
		ks.fCatchProbability = one["catch_probability"];
		ks.fVisualScale = one["visual_scale"];
		ks.nVisualID = one["visual_attach"];
		ks.nBoundingBox = one["bounding_box"];
		ks.nLockLevel = one["lock_level"];

		KingFishMap[ks.nTypeID] = ks;
	}

	SanYuanFishMap.clear();

	table sanyuan = g["fish_sanyuan"];
	for (table::iterator iter(sanyuan); iter; iter++){
		SpecialSet ks;

		table one = iter.value();
		ks.nTypeID = iter.key();

		ks.fProbability = one["probability"];
		ks.nMaxScore = one["max_score"];
		ks.fCatchProbability = one["catch_probability"];
		ks.fVisualScale = one["visual_scale"];
		ks.nVisualID = one["visual_attach"];
		ks.nBoundingBox = one["bounding_box"];
		ks.nLockLevel = one["lock_level"];

		SanYuanFishMap[ks.nTypeID] = ks;
	}

	SiXiFishMap.clear();

	table sixi = g["fish_sixi"];
	for (table::iterator iter(sixi); iter; iter++){
		SpecialSet ks;

		table one = iter.value();
		ks.nTypeID = iter.key();
		ks.fProbability = one["probability"];
		ks.nMaxScore = one["max_score"];
		ks.fCatchProbability = one["catch_probability"];
		ks.fVisualScale = one["visual_scale"];
		ks.nVisualID = one["visual_attach"];
		ks.nBoundingBox = one["bounding_box"];
		ks.nLockLevel = one["lock_level"];

		SiXiFishMap[ks.nTypeID] = ks;
	}

	return true;
}




