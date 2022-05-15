if(!MAP_IS_OUTLAND_BREEZE) then return end
ENT.Type 			= "point"
ENT.Base 			= "base_point"

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
end

local function PreSpawn(class,pos,yaw)
	local ent = ents.Create(class)
	if(!IsValid(ent)) then return NULL end
	ent:SetPos(pos)
	if(yaw) then ent:SetAngles(Angle(0,yaw,0)) end
	return ent
end

local function SpawnNPC(class,pos,yaw)
	local ent = PreSpawn(class,pos,yaw)
	if(!IsValid(ent)) then return NULL end
	ent:Spawn()
	ent:Activate()
	return ent
end

local seats = {
	{
		pos = Vector(4.4,38,-29.15),
		ang = Angle(0,-90,3),
		visible = false
	},
	{
		pos = Vector(-121,38,-8.15),
		ang = Angle(1,90,0),
		visible = true
	},
	{
		pos = Vector(-121,-4,-8.15),
		ang = Angle(1,90,0),
		visible = true
	}
}
local function AddJalopySeats(ent)
	ent.tEntsSeats = ent.tEntsSeats || {}
	local attID = ent:LookupAttachment("vehicle_driver_eyes")
	local att = ent:GetAttachment(attID)
	if(!att) then return end
	local forward = att.Ang:Forward()
	local right = att.Ang:Right()
	local up = att.Ang:Up()
	for i = 1,math.min(#seats,#player.GetAll() -1) do
		if(!ent.tEntsSeats[i]) then
			local data = seats[i]
			local seat = ents.Create("prop_vehicle_prisoner_pod")
			if(IsValid(seat)) then
				seat:SetPos(att.Pos +forward *data.pos.x +right *data.pos.y +up *data.pos.z)
				seat:SetAngles(att.Ang +data.ang)
				seat:SetModel("models/nova/jalopy_seat.mdl")
				seat:SetKeyValue("vehiclescript","scripts/vehicles/prisoner_pod.txt")
				seat:SetKeyValue("limitview","0")
				seat:SetParent(ent)
				seat:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				if(!data.visible) then seat:SetNoDraw(true) end
				seat:Spawn()
				seat:Activate()
				ent.tEntsSeats[i] = seat
			end
		end
	end
end

hook.Add("PlayerAuthed","addseat",function(pl)
	for _,ent in ipairs(ents.FindByName("vehicle1")) do
		AddJalopySeats(ent)
	end
end)

hook.Add("EntityTakeDamage","zerohelidamage",function(ent,dmginfo)
	if(ent:IsNPC() && ent:GetName() == "combine_helicopter1") then
		if(!dmginfo:IsDamageType(DMG_AIRBOAT) && dmginfo:GetAttacker() != ent) then dmginfo:SetDamage(0) end
	end
end)

local function EnableChopperMissileAttack(b)
	local mt = ents.FindByName("combine_helicopter1_missiletimer")[1]
	if(IsValid(mt)) then mt:Fire(b && "enable" || "disable","",0) end
end

local function ActivateMissileSpam()
	local mt = ents.FindByName("combine_helicopter1_missiletimer")[1]
	if(IsValid(mt)) then mt:Fire("disable","",0) end
	local ms = ents.FindByName("combine_helicopter1_missilespam")[1]
	if(IsValid(ms)) then
		local r = math.Rand(4,16)
		ms:Fire("trigger","",r)
		if(IsValid(mt)) then mt:Fire("enable","",r +6) end
	end
end

local function InitMap()
	local ent = ents.FindByName("vehicle1")[1]
	if(IsValid(ent)) then AddJalopySeats(ent) end
	local ent = SpawnNPC("shop_keep",Vector(2840,2620,46),-135)
	if(IsValid(ent)) then
		ent.KeeperPosition = ent:GetPos()
		ent.KeeperAngles = ent:GetAngles()
		THESHOPKEEPER = ent
	end
	local ent = ents.FindByName("combinecannon1")[1]
	if(IsValid(ent)) then
		local hit = -1
		local numHit = 0
		local numHitsMax = 10
		ent:SetVital(true)
		local OnCannonFired = function(cc)
			timer.Simple(0.01,function()
				if(cc:IsValid()) then
					if(hit != 2) then
						cc:Fire("break","",0)
						cc:Fire("delayedreinstate",math.Rand(8,15),0)
					elseif(hit == 2) then
						local hc = ents.FindByName("combine_helicopter1")[1]
						if(IsValid(hc)) then
							if(hc.m_bInvincible) then return end
							if(!hc.m_bNoPatrol) then hc:Fire("StopPatrol","",0) end
							local ct = ents.FindByName("combine_helicopter1_crashtrigger")[1]
							if(IsValid(ct)) then ct:Fire("enable","",0) end
							cc:Fire("break","",0)
							numHit = numHit +1
							if(numHit == 1) then
								cc:Fire("delayedreinstate",8,0)
								local mm = ents.FindByName("manhack2_maker")[1]
								if(IsValid(mm)) then
									local numPlayers = #player.GetAll()
									mm:Fire("setmaxchildren",math.min((numPlayers -1) *2,18),0)
									mm:Fire("enable","",0.01)
								end
							elseif(numHit == 2) then
								local at = ents.FindByName("ff_actioncase1")[1] // ff_actiontimer1 is obsolete now
								if(IsValid(at)) then
									timer.Simple(math.Rand(0,6),function()
										if(at:IsValid()) then
											at:Fire("pickrandomshuffle","",0)
										end
									end)
									local fcm = ents.FindByName("zombie_fast3_maker")[1]
									if(IsValid(fcm)) then
										local numPlayers = #player.GetAll()
										fcm:Fire("setmaxchildren",math.min(4 +(numPlayers -1) *3,16),0)
										fcm:Fire("SetMaxLiveChildren",math.min(3 +(numPlayers -1) *2,6),0)
									end
								end
								cc:Fire("delayedreinstate",8,0)
							elseif(numHit == 3) then
								local at = ents.FindByName("ff_actioncase1")[1]
								if(IsValid(at)) then
									timer.Simple(math.Rand(0,3),function()
										if(at:IsValid()) then
											at:Fire("pickrandomshuffle","",0)
											timer.Simple(math.Rand(0,6),function()
												if(at:IsValid()) then
													at:Fire("pickrandomshuffle","",0)
												end
											end)
										end
									end)
								end
								cc:Fire("delayedreinstate",12,0)
								EnableChopperMissileAttack(true)
							elseif(numHit == 4) then
								local ft = ents.FindByName("combine_helicopter1_flytimer")[1]
								if(IsValid(ft)) then ft:Fire("kill","",0) end
								cc:Fire("setdetachable","",0)
								local np = ents.FindByName("combine_helicopter1_path12")[1]
								if(IsValid(np)) then np:Fire("EnablePath","",0) end
								local npB = ents.FindByName("combine_helicopter1_path13_1")[1]
								if(IsValid(npB)) then npB:Fire("EnablePath","",0) end
								local npC = ents.FindByName("combine_helicopter1_path13_2")[1]
								if(IsValid(npC)) then npC:Fire("EnablePath","",0) end
								hc:Fire("FlyToSpecificTrackViaPath","combine_helicopter1_path12",0.1)
								hc.m_bNoPatrol = true
								EnableChopperMissileAttack(false)
								cc:Fire("delayedreinstate",8,0)
							elseif(numHit == 6) then
								local sm = ents.FindByName("combine_strider1_maker")[1]
								if(IsValid(sm)) then
									local r = math.Rand(0,3)
									sm:Fire("enable","",r)
									local cm = ents.FindByName("citizen4_maker")[1]
									if(IsValid(cm)) then
										local num = math.max(3 -math.floor(#player.GetAll() /2),0)
										cm:Fire("setmaxchildren",num,0)
										cm:Fire("enable","",0.01)
									end
								end
								local cc = ents.FindByName("combinecannon1")[1]
								if(IsValid(cc)) then
									if(IsValid(cc.Owner)) then SS_Map.DrawHUDTip("cc_drop","RELOAD","DROP",cc.Owner)
									else
										if(cc.OnPickedUp) then
											local OnPickedUp = cc.OnPickedUp
											cc.OnPickedUp = function(cc,activator,wep)
												SS_Map.DrawHUDTip("cc_drop","RELOAD","DROP",activator)
												OnPickedUp(cc,activator,wep)
											end
										end
										if(cc.OnDetached) then
											local OnDetached = cc.OnDetached
											cc.OnDetached = function(cc,pl,wep)
												SS_Map.DrawHUDTip("cc_drop","RELOAD","DROP",pl)
												OnDetached(cc,pl,wep)
											end
										end
									end
								end
								local cds = ents.FindByName("combine_dropship1_relay")[1]
								if(IsValid(cds)) then cds:Fire("trigger","",math.Rand(0,7)) end
								cc:Fire("delayedreinstate",8,0)
								local hc = ents.FindByName("combine_helicopter1")[1]
								if(IsValid(hc)) then
									hc:Fire("stoppatrol","",0)
									hc:Fire("FlyToSpecificTrackViaPath","combine_helicopter1_path16_track19",0.01)
									hc:Fire("gunoff","",0)
									hc.m_bNoPatrol = true
									hc.m_bInvincible = true
								end
								local hm = ents.FindByName("hunter5_maker")[1]
								if(IsValid(hm)) then
									local numPlayers = #player.GetAll()
									hm:Fire("setmaxchildren",math.min(math.ceil((numPlayers -1) *0.5),8),0)
									hm:Fire("enable","",0.01)
								end
							elseif(numHit == 7) then
								cc:Fire("delayedreinstate",8,0)
								local mm = ents.FindByName("manhack2_maker")[1]
								local numPlayers = #player.GetAll()
								if(IsValid(mm)) then
									local numPlayers = #player.GetAll()
									mm:Fire("addmaxchildren",math.min((numPlayers -1) *6,22))
								end
								local cma = ents.FindByName("combine1_maker")[1]
								local cmb = ents.FindByName("combine2_maker")[1]
								local cmc = ents.FindByName("combine3_maker")[1]
								if(numPlayers > 1) then
									if(IsValid(cma)) then
										cma:Fire("addmaxchildren","99999",0)
										cma:Fire("setmaxlivechildren","2",0)
										cma:Fire("SetSpawnFrequency","6",0)
									end
									if(IsValid(cmb)) then
										cmb:Fire("addmaxchildren","99999",0)
										cmb:Fire("setmaxlivechildren","2",0)
										cmb:Fire("SetSpawnFrequency","6",0)
									end
									if(IsValid(cmc)) then
										cmc:Fire("addmaxchildren","99999",0)
										cmc:Fire("setmaxlivechildren","2",0)
										cmc:Fire("SetSpawnFrequency","6",0)
									end
								end
							elseif(numHit == 8) then
								cc:Fire("delayedreinstate",8,0)
								ActivateMissileSpam()
							elseif(numHit == numHitsMax) then
								hc:Fire("setdamagefilter","",0)
								hc:Fire("selfdestruct","",0.01)
							elseif(numHit < numHitsMax) then cc:Fire("delayedreinstate",8,0) end
							hc:SetHealth(hc:GetMaxHealth())
							local attacker
							if(IsValid(cc.Owner)) then attacker = cc.Owner
							elseif(IsValid(cc:GetOwner())) then attacker = cc:GetOwner()
							else attacker = cc end
							local dmg = DamageInfo()
							dmg:SetAttacker(attacker)
							dmg:SetInflictor(cc)
							dmg:SetDamage(1)
							dmg:SetDamageType(DMG_AIRBOAT)
							hc:TakeDamageInfo(dmg) // Apply minor damage for damage effects
						end
					end
					hit = -1
				end
			end)
		end
		local OnHit = function(cc,ent)
			if(ent:GetName() == "combine_helicopter1") then hit = 2
			elseif(hit == -1) then hit = 1 end
			if(ent:GetClass() == "npc_strider") then
				ent.m_numHitCombineCannon = ent.m_numHitCombineCannon || 0
				ent.m_numHitCombineCannon = ent.m_numHitCombineCannon +1
				if(ent.m_numHitCombineCannon == 3) then ent:Fire("explode","",0)
				else
					ent:EmitSound("NPC_Strider.Pain",100,100)
					ent:RestartGesture(ACT_GESTURE_BIG_FLINCH)
					ent:Fire("StopShootingMinigunForSeconds","2.8",0)
					if(ent.m_numHitCombineCannon == 2) then
						if(ent:GetName() == "combine_strider1") then
							local tr = ents.FindByName("combine_strider1_cannontarget1_relay")[1]
							if(IsValid(tr)) then
								timer.Simple(2.8,function()
									if(tr:IsValid()) then
										tr:Fire("trigger","",0)
									end
								end)
							end
						end
					end
				end
			end
		end
		local OnDetached
		local OnAttached = function(ent,entMounted)
			entMounted.OnCannonFired = OnCannonFired
			entMounted.OnDetached = OnDetached
			entMounted.OnHit = OnHit
		end
		local OnCannonCharging = function(wep)
			local ent = ents.FindByName("combine_helicopter1")[1]
			if(IsValid(ent) && !ent.m_bNoPatrol) then ent:Fire("StartPatrol","",0) end
		end
		local OnDropped
		OnDropped = function(wep,ent)
			ent.OnPickedUp = function(ent,activator,wep)
				wep.OnCannonFired = OnCannonFired
				wep.OnDropped = OnDropped
				wep.OnCannonCharging = OnCannonCharging
				wep.OnHit = OnHit
			end
			ent.OnAttached = OnAttached
		end
		OnDetached = function(cc,pl,wep)
			wep.OnCannonFired = OnCannonFired
			wep.OnDropped = OnDropped
			wep.OnCannonCharging = OnCannonCharging
			wep.OnHit = OnHit
		end
		ent.OnCannonFired = OnCannonFired
		ent.OnDetached = OnDetached
		ent.OnHit = OnHit
	end
end

local PLAYERS_CHANCE_MAX = 8
local function ChanceByPlayerCount(vMin,vMax)
	local num = #player.GetAll()
	local chance = vMin +(vMax -vMin) *math.Clamp(num /PLAYERS_CHANCE_MAX,0,1)
	return math.Rand(0,1) <= chance
end

util.AddNetworkString("ss_track")
util.AddNetworkString("ss_track_end")
local trackCur
local function PlayTrack(ID,bOnce)
	local r = math.Rand(0,1)
	net.Start("ss_track")
		net.WriteUInt(ID,5)
		net.WriteFloat(r)
		net.WriteUInt(bOnce && 1 || 0,1)
	net.Broadcast()
	trackCur = {ID,r,bOnce,CurTime()}
end

local function EndTrack(bKeepActive)
	if(!trackCur) then return end
	if(!bKeepActive) then trackCur = nil end
	net.Start("ss_track_end")
		net.WriteUInt(bKeepActive && 1 || 0,1)
	net.Broadcast()
end

hook.Add("PlayerInitialSpawn","ss_updatetrack",function(pl)
	if(!trackCur || (trackCur[3] && CurTime() -trackCur[4] >= 20)) then return end
	net.Start("ss_track")
		net.WriteUInt(trackCur[1],5)
		net.WriteFloat(trackCur[2])
		net.WriteUInt(0,1)
	net.Send(pl)
end)

local proficiency = {
	[0] = WEAPON_PROFICIENCY_AVERAGE,
	[1] = WEAPON_PROFICIENCY_AVERAGE,
	[2] = WEAPON_PROFICIENCY_GOOD,
	[3] = WEAPON_PROFICIENCY_VERY_GOOD,
	[4] = WEAPON_PROFICIENCY_VERY_GOOD,
	[5] = WEAPON_PROFICIENCY_VERY_GOOD
}
hook.Add("OnEntityCreated","proficiency",function(ent)
	if(IsValid(ent)) then
		if(ent:IsNPC()) then
			timer.Simple(0.05,function()
				if(ent:IsValid()) then
					ent:SetCurrentWeaponProficiency(proficiency[#player.GetAll()] || WEAPON_PROFICIENCY_PERFECT)
					if(ent:GetName() == "gman2") then ent:SetPos(Vector(1067,8454,ent:GetPos().z)) end
				end
			end)
		elseif(ent:GetClass() == "grenade_helicopter") then
			ent:SetModel("models/combine_helicopter/helicopter_bomb02.mdl")
		elseif(ent:GetClass() == "env_headcrabcanister") then ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS) end
	end
end)

local antlionSpawnpointsOutside = {
	Vector(-2228,7864,-155),
	Vector(-2255,8893,-155),
	Vector(-2677,9597,-155),
	Vector(-3025,9390,-155),
	Vector(-2148,8440,-155),
	Vector(-2427,10011,-155),
	Vector(-2163,9221,-155),
	Vector(-2571,7921,-155),
	Vector(-2215,9593,-155),
	Vector(-2727,9004,-155),
	Vector(-1927,8076,-152),
	Vector(-2532,7670,-155),
	Vector(-2375,7765,-154)
}

local metaEntity = FindMetaTable("Entity")
local function SpawnGuardian(pos,yaw,onremove)
	local ent = PreSpawn("npc_antlionguard",pos +Vector(0,0,10),yaw)
	if(!IsValid(ent)) then return NULL end
	local bCavern = ChanceByPlayerCount(0.2,0.85)
	local bShadowGuardian = ChanceByPlayerCount(0.1,0.75)
	local hpScale = 1 +math.min(#player.GetAll() -1,8) *0.3
	if(bCavern) then
		ent:SetKeyValue("allowbark","1")
		ent:SetKeyValue("cavernbreed","1")
		//ent:SetKeyValue("incavern","1")
		ent:SetKeyValue("spawnflags","131584")
		hpScale = hpScale +0.5
	end
	if(!bShadowGuardian) then ent:SetKeyValue("startburrowed","1") end
	ent:SetKeyValue("targetname","guardian1")
	ent:SetKeyValue("squadname","antsquad1")
	local bCursed = metaEntity.StartCurse && ChanceByPlayerCount(0.15,0.7) || false
	timer.Simple(bShadowGuardian && 1 || 0,function()
		if(ent:IsValid()) then
			ent:Spawn()
			ent:Activate()
			if(!bShadowGuardian) then ent:Fire("unburrow","",1) end
			if(bCavern) then SS_Map.MakeCavernGuardian("guardian1") end
			if(bShadowGuardian) then
				SS_Map.MakeShadowGuardian("guardian1")
				hpScale = hpScale +0.5
			end
			ent:SetHealth(ent:GetMaxHealth() *hpScale)
			ent:CallOnRemove("antdeath",onremove)
			if(bCursed) then
				local pt = ents.Create("info_particle_system")
				pt:SetPos(ent:GetPos() +Vector(0,0,(ent:OBBMaxs().z +5)))
				pt:SetKeyValue("effect_name","sword_curse_enemy_large")
				pt:SetKeyValue("start_active","1")
				pt:SetParent(ent)
				pt:Spawn()
				pt:Activate()
				ent.m_bCursed = true
				local idx = ent:EntIndex()
				local hk = "cursedguardian" .. idx
				hook.Add("EntityTakeDamage",hk,function(entTgt,dmginfo)
					if((entTgt:IsNPC() && !entTgt.m_bCursed) || entTgt:IsPlayer()) then
						local attacker = dmginfo:GetAttacker()
						local inflictor = dmginfo:GetInflictor()
						if(attacker == ent && inflictor == ent) then
							if(math.Rand(0,1) <= 0.75) then
								if(entTgt:IsPlayer() && !entTgt.Cursed) then
									net.Start("ss_curse")
									net.Send(entTgt)
								end
								entTgt:StartCurse(ent)
							end
						end
					end
				end)
				ent:CallOnRemove(hk,function()
					hook.Remove("EntityTakeDamage",hk)
					if(IsValid(pt)) then pt:Remove() end
				end)
			end
		end
	end)
	return ent
end

local function FireMissile(ent)
	local hc = ent:GetOwner()
	if(!IsValid(hc)) then return end
	local tgt = hc:GetEnemy()
	if(!IsValid(tgt)) then return end
	local angHc = hc:GetAngles()
	local posTgt = tgt:GetPos() +tgt:OBBCenter()
	local pos = ent:GetPos()
	local angNew = (posTgt -pos):Angle()
	if(math.abs(math.AngleDifference(angHc.p,angNew.p)) <= 50 && math.abs(math.AngleDifference(angHc.y,angNew.y)) <= 50) then
		angNew.p = math.ApproachAngle(angHc.p,angNew.p,45)
		angNew.y = math.ApproachAngle(angHc.y,angNew.y,45)
		ent:SetAngles(angNew +Angle(90,0,0))
		ent:SetEnemy(tgt)
		ent:Fire("fireonce","",0)
	end
end

function ENT:HandleEvent(...)
	print("Map Event: ",...)
	local event = select(1,...)
	if(event == "mapspawn") then
		InitMap()
		return true
	elseif(event == "jalopyspawn") then
		local name = select(2,...)
		local ents = ents.FindByName(name)
		local ent = ents[#ents]
		AddJalopySeats(ent)
		return true
	elseif(event == "checkpoint") then
		hook.Remove("PlayerInitialSpawn","viewcontrol")
		return true
	elseif(event == "strider_death_recall") then
		local hc = ents.FindByName("combine_helicopter1")[1]
		if(IsValid(hc)) then
			hc.m_bInvincible = false
			hc.m_bNoPatrol = false
		end
		return true
	elseif(event == "helicopter_firemissile") then
		local name = select(2,...)
		local ent = ents.FindByName(name)[1]
		if(IsValid(ent)) then
			FireMissile(ent)
		end
		return true
	elseif(event == "helicopter_firemissiles") then
		local name = select(2,...)
		local hc = ents.FindByName(name)[1]
		if(IsValid(hc) && hc.m_tMissileLaunchers) then
			for _,ent in ipairs(hc.m_tMissileLaunchers) do
				FireMissile(ent)
			end
		end
		return true
	elseif(event == "multitrigger_update") then
		local trigger = select(2,...)
		local ent = ents.FindByName(trigger)[1]
		if(IsValid(ent)) then
			local add = select(3,...)
			add = tonumber(add)
			self.m_tMultitriggers = self.m_tMultitriggers || {}
			self.m_tMultitriggers[trigger] = self.m_tMultitriggers[trigger] || 0
			local num = self.m_tMultitriggers[trigger] +add
			self.m_tMultitriggers[trigger] = num
			local numPlayers = math.ceil(#player.GetAll() *0.5)
			if(num >= numPlayers) then
				ent:Fire("kill","",0)
				if(trigger == "multitrigger_endgame") then
					local tr = ents.FindByName("endgame_trigger")[1]
					if(IsValid(tr)) then tr:Fire("enable","",0) end
				elseif(trigger == "multitrigger_antlionbattle") then
					local tr = ents.FindByName("battle_antlion_outside1_relay_timer")[1]
					if(IsValid(tr)) then tr:Fire("enable","",0) end
				end
			end
		end
		return true
	elseif(event == "endgame") then
		net.Start("ss_viewcam_end")
		net.Broadcast()
		for _,pl in ipairs(player.GetAll()) do
			pl:SetPos(Vector(733,8458,-1936))
			local wep = pl:GetActiveWeapon()
			if(IsValid(wep) && wep.QuickHolster) then wep:QuickHolster() end
			pl:Flashlight(false)
			pl:Lock()
		end
		return true
	elseif(event == "fadescreen") then
		local tFade = select(2,...)
		local tHold = select(3,...)
		tFade = tFade && tonumber(tFade) || 0
		tHold = tHold && tonumber(tHold) || 0
		local col = select(4,...)
		col = string.Explode(" ",col)
		col = Color(col[1],col[2],col[3],col[4])
		local flags = select(5,...)
		flags = flags && tonumber(flags) || 0
		SS_Map.FadeScreen(tFade,tHold,col,flags)
		return true
	elseif(event == "helicopter_addmissiles") then
		local name = select(2,...)
		local hc = ents.FindByName(name)[1]
		if(IsValid(hc)) then
			local offset = {
				Vector(14,-64.2,-61.5),
				Vector(14,64.2,-61.5)
			}
			local pos = hc:GetPos()
			local ang = hc:GetAngles()
			local forward = ang:Forward()
			local right = ang:Right()
			local up = ang:Up()
			hc.m_tMissileLaunchers = {}
			for i = 1,2 do
				local posMissile = pos +offset[i].x *forward +offset[i].y *right +offset[i].z *up
				local ent = ents.Create("prop_dynamic_override")
				ent:SetModel("models/weapons/w_missile_closed.mdl")
				ent:SetAngles(ang)
				ent:SetPos(posMissile)
				ent:SetParent(hc)
				ent:Spawn()
				ent:Activate()
				hc:DeleteOnRemove(ent)
				
				local ent = ents.Create("npc_launcher")
				ent:SetKeyValue("Damage","15")
				ent:SetKeyValue("DamageRadius","140")
				ent:SetKeyValue("FlySound","Missile.Ignite")
				ent:SetKeyValue("spawnflags","0")
				ent:SetKeyValue("LaunchSound","npc/waste_scanner/grenade_fire.wav")
				ent:SetKeyValue("MissileModel","models/weapons/w_missile.mdl")
				ent:SetKeyValue("SmokeTrail","1")
				ent:SetKeyValue("LaunchSpeed","1000")
				ent:SetKeyValue("MaxRange","20000")
				ent:SetKeyValue("HomingStrength","0")
				ent:SetKeyValue("LaunchSmoke","1")
				ent:SetKeyValue("StartOn","0")
				ent:SetKeyValue("LaunchDelay","0")
				ent:SetAngles(ang +Angle(90,0,0))
				ent:SetPos(posMissile)
				ent:SetParent(hc)
				ent:Spawn()
				ent:Activate()
				ent:SetOwner(hc)
				local nameLauncher = name .. "_launcher" .. i
				ent:SetName(nameLauncher)
				table.insert(hc.m_tMissileLaunchers,ent)
				hc:DeleteOnRemove(ent)
				
				local hk = nameLauncher .. "_nocollision"
				ent:CallOnRemove(hk,function()
					hook.Remove("OnEntityCreated",hk)
				end)
				hook.Add("OnEntityCreated",hk,function(entTgt)
					if(entTgt:IsValid() && entTgt:GetClass() == "grenade_homer") then
						local owner = entTgt:GetOwner()
						if(IsValid(owner) && owner == ent) then
							owner = owner:GetOwner()
							if(IsValid(owner)) then
								entTgt:SetOwner(owner)
							end
						end
					end
				end)
			end
		end
		return true
	elseif(event == "makecavernguardian") then
		SS_Map.MakeCavernGuardian(select(2,...))
		return true
	elseif(event == "makeshadowguardian") then
		SS_Map.MakeShadowGuardian(select(2,...))
		return true
	elseif(event == "tunnel_barnaclespawn") then
		if(math.random(1,3) == 1) then
			local ent = PreSpawn("npc_barnacle",Vector(-2990,3783,34.6976))
			if(ent:IsValid()) then ent:SetKeyValue("spawnflags","131588"); ent:SetName("barnacle2"); ent:Spawn(); ent:Activate() end
		end
		return true
	elseif(event == "tunnelbattle") then
		local ent = ents.FindByName("tunnel_battle_relay")[1]
		if(IsValid(ent)) then
			ent:Fire("trigger","",0.01)
			local numPlayers = #player.GetAll()
			local hm = ents.FindByName("hopper1_maker")[1]
			if(IsValid(hm)) then
				ent:Fire("SetMaxLiveChildren",2 +math.min(math.floor(numPlayers -1 *0.5),3),0)
				ent:Fire("setmaxchildren",math.min((numPlayers -1) *1,12),0)
			end
			local lm = ents.FindByName("leperkin2_maker")[1]
			if(IsValid(lm)) then
				ent:Fire("SetMaxLiveChildren",6 +math.min(math.floor(numPlayers -1 *0.5),4),0)
				ent:Fire("setmaxchildren",math.min((numPlayers -1) *5,16),0)
			end
			local tm = ents.FindByName("tunnelermound1")[1]
			if(IsValid(tm)) then
				tm:SetTotalNPCAmount(tm:GetTotalNPCAmount() +2 +math.min(math.floor(numPlayers -1) *0.5),5)
				tm:SetMaxNPCAmount(tm:GetMaxNPCAmount() +math.min(math.floor(numPlayers -1) *0.5),2)
			end
			local hm = ents.FindByName("headcrab3_maker")[1]
			if(IsValid(hm)) then
				hm:Fire("SetMaxLiveChildren",3 +math.min(math.floor(numPlayers -1 *1),3),0)
				hm:Fire("setmaxchildren",4 +math.min((numPlayers -1) *1,8),0)
			end
			local fmm = ents.FindByName("headcrab_fast1_maker")[1]
			if(IsValid(fmm)) then fmm:Fire("enable","",math.Rand(0,1),0) end
			local pmm = ents.FindByName("zombie_poison2_maker")[1]
			if(IsValid(pmm)) then
				pmm:Fire("SetMaxLiveChildren",2 +math.min(math.floor(numPlayers -1) *2,2),0)
				pmm:Fire("setmaxchildren",2 +math.min((numPlayers -1) *0.5,4),0)
				pmm:Fire("enable","",math.Rand(0,1),0.01)
			end
		end
		return true
	elseif(event == "tunnelbattle2") then
		local zmm = ents.FindByName("zombie8_maker")[1]
		local gnm = ents.FindByName("gonome2_maker")[1]
		local fzm = ents.FindByName("zombie_fast9_maker")[1]
		local pdm = ents.FindByName("pitdrone2_maker")[1]
		local pzm = ents.FindByName("zombie_poison3_maker")[1]
		local numPlayers = #player.GetAll()
		if(IsValid(zmm)) then
			zmm:Fire("SetMaxLiveChildren",4 +math.min(math.floor(numPlayers -1) *2,4),0)
			zmm:Fire("setmaxchildren",5 +math.min(numPlayers *2,8),0)
			zmm:Fire("enable","",math.Rand(0,1),0.01)
		end
		if(IsValid(gnm)) then
			gnm:Fire("SetMaxLiveChildren",2 +math.min(math.floor(numPlayers -1) *1,2),0)
			gnm:Fire("setmaxchildren",1 +math.min((numPlayers -1) *1,3),0)
			gnm:Fire("enable","",math.Rand(0,1),0.01)
		end
		if(IsValid(fzm)) then
			fzm:Fire("SetMaxLiveChildren",2 +math.min(math.floor(numPlayers -1) *1,1),0)
			fzm:Fire("setmaxchildren",2 +math.min((numPlayers -1) *1,4),0)
			fzm:Fire("enable","",math.Rand(0,1),0.01)
		end
		if(IsValid(pdm)) then
			pdm:Fire("SetMaxLiveChildren",1 +math.min(math.floor(numPlayers -1) *1,2),0)
			pdm:Fire("setmaxchildren",3 +math.min((numPlayers -1) *0.5,2),0)
			pdm:Fire("enable","",math.Rand(0,1),0.01)
		end
		if(IsValid(pzm)) then
			pzm:Fire("SetMaxLiveChildren",2 +math.min(math.floor(numPlayers -1) *1,2),0)
			pzm:Fire("setmaxchildren",3 +math.min((numPlayers -1) *0.5,2),0)
			pzm:Fire("enable","",math.Rand(0,1),0.01)
		end
		return true
	elseif(event == "playtrack") then
		local trackID = select(2,...)
		local bOnce = select(3,...)
		if(bOnce) then bOnce = tonumber(bOnce) end
		PlayTrack(trackID,bOnce != nil && bOnce != 0)
		return true
	elseif(event == "endtrack") then
		local bKeepActive = select(2,...)
		bKeepActive = bKeepActive && tonumber(bKeepActive) != 0
		EndTrack(bKeepActive)
		return true
	elseif(event == "playactivity") then
		local name = select(2,...)
		local act = _G[select(3,...)]
		for _,ent in ipairs(ents.FindByName(name)) do
			if(ent.PlayActivity) then ent:PlayActivity(act) end
		end
		return true
	elseif(event == "goto_ifidle") then
		local name = select(2,...)
		local pos = select(3,...)
		pos = string.Explode(" ",pos)
		pos = Vector(pos[1],pos[2],pos[3])
		local run = select(4,...)
		run = run && tonumber(run) != 0
		for _,ent in ipairs(ents.FindByName(name)) do
			if(ent.GoToPos) then
				if(ent:GetEnemyCount() == 0) then
					ent:GoToPos(pos,false,false,100)
				end
			end
		end
		return true
	elseif(event == "goto") then
		local name = select(2,...)
		local pos = select(3,...)
		pos = string.Explode(" ",pos)
		pos = Vector(pos[1],pos[2],pos[3])
		local run = select(4,...)
		run = run && tonumber(run) != 0
		for _,ent in ipairs(ents.FindByName(name)) do
			if(ent.GoToPos) then
				ent:GoToPos(pos,false,false,100)
			end
		end
		return true
	elseif(event == "stripweapons") then
		for _,pl in ipairs(player.GetAll()) do pl:StripWeapons() end
		return true
	elseif(event == "antlionspawn1_adjust") then
		local numPlayers = #player.GetAll()
		local am = ents.FindByName("antlion5_maker")[1]
		if(IsValid(am)) then
			am:Fire("SetMaxLiveChildren",6 +math.min(math.floor(numPlayers -1 *0.5),6),0)
			am:Fire("setmaxchildren",math.min((numPlayers -1) *5,36),0)
		end
		if(numPlayers > 2) then
			local evm = ents.FindByName("evmanager")[1]
			if(IsValid(evm)) then evm:Fire("FireEvent","playtrack;2;1",2) end
		end
		return true
	elseif(event == "zombieambush_outland") then
		local numPlayers = #player.GetAll()
		if(numPlayers > 1) then
			local zfm = ents.FindByName("zombie_fast7_maker")[1]
			local zmm = ents.FindByName("zombine2_maker")[1]
			local zm = ents.FindByName("zombie4_maker")[1]
			local gnm = ents.FindByName("gonome1_maker")[1]
			local pdm = ents.FindByName("pitdrone1_maker")[1]
			if(zfm:IsValid()) then
				zfm:Fire("setmaxchildren",math.min((numPlayers -1) *3,17),0)
				zfm:Fire("enable","",math.Rand(0,6))
			end
			if(zmm:IsValid()) then
				zmm:Fire("setmaxchildren",math.min((numPlayers -1) *1,6),0)
				zmm:Fire("enable","",math.Rand(0,6))
			end
			if(zm:IsValid()) then
				zm:Fire("setmaxchildren",math.min((numPlayers -1) *3,12),0)
				zm:Fire("enable","",math.Rand(0,6))
			end
			if(gnm:IsValid()) then
				gnm:Fire("setmaxchildren",math.min((numPlayers -1) *1,11),0)
				gnm:Fire("enable","",math.Rand(0,6))
			end
			if(pdm:IsValid()) then
				pdm:Fire("setmaxchildren",math.min((numPlayers -1) *1,8),0)
				pdm:Fire("enable","",math.Rand(0,6))
			end
			if(numPlayers >= 3) then
				local em = ents.FindByName("evmanager")[1]
				if(IsValid(em)) then em:Fire("FireEvent","playtrack;5;" .. (numPlayers <= 4 && 1 || 0),3) end
			end
		end
		return true
	elseif(event == "combine_ambush1") then
		local cmakers = {"combine6_maker","combine7_maker","combine8_maker"}
		local makers = {"hunter4_maker"}
		table.Add(makers,cmakers)
		local numPlayers = #player.GetAll()
		local hm = ents.FindByName("hunter4_maker")[1]
		if(IsValid(hm)) then hm:Fire("setmaxchildren",math.min(numPlayers,4),0) end
		local num = math.min(3 +(numPlayers *2),11)
		local numPerMaker = math.ceil(num /3)
		for _,name in ipairs(cmakers) do
			for _,ent in ipairs(ents.FindByName(name)) do
				ent:Fire("setmaxchildren",numPerMaker,0)
			end
		end
		for _,name in ipairs(makers) do
			for _,ent in ipairs(ents.FindByName(name)) do
				ent:Fire("enable","",0.01)
			end
		end
		local fm = ents.FindByName("fassassin1_maker")[1]
		if(IsValid(fm)) then
			if(ChanceByPlayerCount(0.05,0.95)) then
				local num = math.min((#player.GetAll() -3) +1,3)
				fm:Fire("setmaxchildren",num,0)
				fm:Fire("enable","",0.01)
			end
		end
		local csm = ents.FindByName("clawscanner1_maker")[1]
		if(IsValid(csm)) then csm:Fire("enable","",0) end
		local csm = ents.FindByName("clawscanner2_maker")[1]
		if(IsValid(csm)) then csm:Fire("enable","",0) end
		local csm = ents.FindByName("clawscanner3_maker")[1]
		if(IsValid(csm)) then csm:Fire("enable","",0) end
		//local cmm = ents.FindByName("manhack1_maker")[1]
		//if(IsValid(cmm)) then cmm:Fire("enable","",0) end
		return true
	elseif(event == "scalehealth") then
		local name = select(2,...)
		local scale = tonumber(select(3,...))
		for _,ent in ipairs(ents.FindByName(name)) do
			ent:SetHealth(ent:GetMaxHealth() *scale)
		end
		return true
	elseif(event == "sethealth") then
		local name = select(2,...)
		local hp = tonumber(select(3,...))
		for _,ent in ipairs(ents.FindByName(name)) do
			ent:SetHealth(hp)
		end
		return true
	elseif(event == "emitsound") then
		local name,snd,sndlevel,pitch = select(2,...)
		sndlevel = sndlevel && tonumber(sndlevel) || 75
		pitch = pitch && tonumber(pitch) || 100
		for _,ent in ipairs(ents.FindByName(name)) do
			ent:EmitSound(snd,sndlevel,pitch)
		end
		return true
	elseif(event == "battle_helicopter_carpetend") then
		local ent = ents.FindByName("combine_helicopter1")[1]
		if(IsValid(ent) && ent.m_bNoPatrol) then ent.m_bNoPatrol = nil; EnableChopperMissileAttack(true) end
		return true
	elseif(event == "battle_outland_dropship_init") then
		if(#player.GetAll() >= 4) then
			local dm = ents.FindByName("combine_dropship2_maker")[1]
			if(IsValid(dm)) then dm:Fire("enable","",0) end
		end
		return true
	elseif(event == "battle_antlion_outdoors_cleanup") then
		if(IsValid(self.m_entAntlionBattleSpawner)) then
			local ent = self.m_entAntlionBattleSpawner
			local tEnts = ent:GetSpawnedNPCs()
			for _,ent in ipairs(tEnts) do
				if(IsValid(ent)) then
					ent:Fire("burrowaway","",0)
				end
			end
			self.m_entAntlionBattleSpawner = nil
		end
		return true
	elseif(event == "battle_antlion_outdoors") then
		self.m_battleAntlionCount = 0
		local tPos = {Vector(-2301,8818,-146),Vector(-2682,9531,-90),Vector(-2503,7878,-90)}
		local r = math.random(1,#tPos)
		local pos = tPos[r]
		table.remove(tPos,r)
		local plClosest
		local distClosest = math.huge
		for _,pl in ipairs(player.GetAll()) do
			local posPl = pl:GetPos()
			local dist = pos:Distance(posPl)
			if(dist < distClosest) then
				distClosest = dist
				plClosest = pl
			end
		end
		local yaw = 221
		if(IsValid(plClosest)) then
			yaw = (plClosest:GetPos() -pos):Angle().y
		end
		local onremove = function(ent)
			if(self.m_battleAntlionCount) then
				self.m_battleAntlionCount = self.m_battleAntlionCount -1
				if(self.m_battleAntlionCount <= 0) then
					self.m_battleAntlionCount = nil
					self:Fire("fireevent","endtrack",0)
				end
				if(ent:GetClass() == "npc_antlionguard") then
					self.m_numGuardians = self.m_numGuardians -1
					if(self.m_numGuardians == 0) then
						local spawner = ents.FindByName("antguard_spawner1")[1]
						if(IsValid(spawner)) then spawner:Remove() end
						self:Fire("fireevent","endtrack;1",0)
						timer.Simple(math.Rand(5,18),function()
							local ent = ents.FindByName("combine_ambush1_trigger")[1]
							if(IsValid(ent)) then ent:Fire("enable","",0) end
						end)
					end
				end
			end
		end
		self.m_numGuardians = 1
		if(IsValid(SpawnGuardian(pos,yaw,onremove))) then self.m_battleAntlionCount = self.m_battleAntlionCount +1 end
		local numPlayers = #player.GetAll()
		if(numPlayers >= PLAYERS_CHANCE_MAX || (numPlayers >= PLAYERS_CHANCE_MAX *0.5 && math.random(1,8) == 1)) then // Spawn a second guardian
			r = math.random(1,#tPos)
			pos = tPos[r]
			if(IsValid(SpawnGuardian(pos,yaw +180,onremove))) then self.m_numGuardians = self.m_numGuardians +1; self.m_battleAntlionCount = self.m_battleAntlionCount +1 end
		end
		local ent = PreSpawn("point_ss_forest_npcspawner",antlionSpawnpointsOutside[1])
		if(IsValid(ent)) then
			self.m_entAntlionBattleSpawner = ent
			local numPlayers = math.min(numPlayers,PLAYERS_CHANCE_MAX)
			local function UpdateSpawnDelay()
				local min = 0.5 +((PLAYERS_CHANCE_MAX -(numPlayers -1)) /PLAYERS_CHANCE_MAX) *0.5
				local max = 4 +((PLAYERS_CHANCE_MAX -(numPlayers -1)) /PLAYERS_CHANCE_MAX) *4
				ent:SetSpawnDelay(math.Rand(min,max))
			end
			ent.OnSpawnNPC = function(ent,npc)
				local flags = 516
				if(ChanceByPlayerCount(0.1,0.25)) then flags = bit.bor(flags,262144) end
				npc:SetKeyValue("spawnflags",flags)
				local pos = table.Random(antlionSpawnpointsOutside)
				npc:SetPos(pos +Vector(0,0,10))
				npc:SetAngles(Angle(0,math.random(0,360),0))
				//npc:DropToFloor()
				UpdateSpawnDelay()
			end
			ent.OnSpawnedNPC = function(ent,npc)
				self.m_battleAntlionCount = self.m_battleAntlionCount +1
				npc:CallOnRemove("antdeath",onremove)
			end
			ent:SetKeyValue("targetname","antguard_spawner1")
			ent:SetKeyValue("npcclass","npc_antlion")
			ent:SetKeyValue("npcsquad","antsquad1")
			ent:SetKeyValue("maxnpcs",math.min(3 +(numPlayers -1) *2,12))
			ent:SetKeyValue("totalnpcs",0)
			ent:SetKeyValue("npckeyvalues","squadname:antsquad1;radius:1024")
			ent:SetKeyValue("spawnflags",17)
			UpdateSpawnDelay()
			ent:Spawn()
			ent:Activate()
			UpdateSpawnDelay()
		end
		return true
	elseif(event == "setmodel") then
		local model = select(3,...)
		if(model) then
			for _,ent in ipairs(ents.FindByName(select(2,...))) do
				ent:SetModel(model)
			end
		end
		return true
	end
end

function ENT:AcceptInput(name,activator,caller,data)
	name = string.lower(name)
	if(name == "fireevent") then
		local ev = string.Explode(";",data)
		self:HandleEvent(unpack(ev))
		return true
	end
end