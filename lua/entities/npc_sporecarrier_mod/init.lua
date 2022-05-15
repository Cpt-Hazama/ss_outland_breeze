if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("shared.lua")

include('shared.lua')

local _R = debug.getregistry()
_R.NPCFaction.Create("NPC_FACTION_ZOMBIE","npc_sporecarrier_mod")
ENT.NPCFaction = NPC_FACTION_ZOMBIE
ENT.iClass = CLASS_ZOMBIE
ENT.sModel = "models/fallout/sporecarrier.mdl"
ENT.fMeleeDistance	= 40
ENT.fMeleeForwardDistance = 180
ENT.fRangeDistance = 2200
ENT.bFlinchOnDamage = true
ENT.m_bKnockDownable = true
ENT.BoneRagdollMain = "Bip01 Pelvis"
ENT.skName = "sporecarrier"
ENT.CollisionBounds = Vector(20,20,42)
ENT.UseActivityTranslator = true
ENT.UseIdleSystem = true
ENT.UsePoison = false
ENT.CanUseMounds = false
ENT.CanUseRadiation = true
--ENT.GlowEffects = true -- Obsolete. This is done clientside now.

ENT.DamageScales = {
	[DMG_BURN] = 1.8,
	[DMG_PARALYZE] = 0.4,
	[DMG_NERVEGAS] = 0.4,
	[DMG_POISON] = 0.4,
	[DMG_DIRECT] = 1.4
}

ENT.iBloodType = BLOOD_COLOR_GREEN
ENT.sSoundDir = "npc/sporecarrier/"
ENT.sndIdle = "sporecarrier_consciouslp.wav"
ENT.sndIdleSoundLevel = 100

ENT.tblFlinchActivities = {
	[HITBOX_GENERIC] = ACT_FLINCH_CHEST,
	[HITBOX_HEAD] = ACT_FLINCH_HEAD,
	[HITBOX_LEFTARM] = ACT_FLINCH_LEFTARM,
	[HITBOX_RIGHTARM] = ACT_FLINCH_RIGHTARM,
	[HITBOX_LEFTLEG] = ACT_FLINCH_LEFTARM,
	[HITBOX_RIGHTLEG] = ACT_FLINCH_RIGHTARM
}

ENT.m_tbSounds = {
	["Aim"] = "sporecarrier_aimvox0[1-4].mp3",
	["Cannibal"] = "../streettrog/trog_cannibal0[1-2].mp3",
	["Death"] = "../streettrog/trog_death0[1-2].mp3",
	["Attack"] = "sporecarrier_atkvox0[1-7].mp3",
	["Emerge"] = "tunneler_emerge0[1-2].mp3",
	["ClimbFence"] = "sporecarrier_chainfence01.mp3",
	["Fly"] = "sporecarrier_flyvox0[1-3].mp3",
	["Pain"] = "sporecarrier_hissvox0[1-5].mp3",
	["RiseVox"] = "sporecarrier_risevox0[1-3].mp3",
	["Rise"] = "sporecarrier_rise0[1-2].mp3",
	["FootWalkLeft"] = "foot/sporecarrier_foot_l0[1-3].mp3",
	["FootWalkRight"] = "foot/sporecarrier_foot_r0[1-3].mp3",
	["FootRunLeft"] = "foot/sporecarrier_foot_l0[1-3].mp3",
	["FootRunRight"] = "foot/sporecarrier_foot_r0[1-3].mp3"
}

PrecacheParticleSystem("sporecarrier_glow")
--local attGlow = {"LClavicle","RClavicle","LForearm","RForearm","LHand","RHand","LThigh","RThigh","LCalf","RCalf","LFoot","RFoot","Head"}
function ENT:OnInit()
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetCollisionBounds(self.CollisionBounds,Vector(self.CollisionBounds.x *-1,self.CollisionBounds.y *-1,0))
	
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND,CAP_OPEN_DOORS))
	self:SetHealth(GetConVarNumber("sk_" .. self.skName .. "_health"))
	
	self.cspIdle = CreateSound(self,self.sSoundDir .. self.sndIdle)
	self.cspIdle:SetSoundLevel(self.sndIdleSoundLevel)
	self.cspIdle:Play()
	self:StopSoundOnDeath(self.cspIdle)
	
	--if(self.GlowEffects) then
		--for _, att in ipairs(attGlow) do
		--	ParticleEffectAttach("sporecarrier_glow",PATTACH_POINT_FOLLOW,self,self:LookupAttachment(att))
		--end
	--end
	
	if(self.CanUseMounds) then
		self.m_nextUseMound = 0
	end
	
	self.m_nextJumpAttack = 0
	self:SubInit()
	timer.Simple(0.25,function()
		if(IsValid(self)) then
			for _,pl in ipairs(player.GetAll()) do self:AddToMemory(pl) end
		end
	end)
end

function ENT:ApplyCustomClassDisposition(ent)
	if(ent:IsPlayer()) then return end
	local faction = _R.NPCFaction.GetFaction(self:GetNPCFaction())
	if(!faction) then return end
	if(faction:HasClass(ent:GetClass())) then
		self:AddEntityRelationship(ent,D_LI,0)
		ent:AddEntityRelationship(self,D_LI,0)
		return true
	end
end

function ENT:_PossPrimaryAttack(entPossessor,fcDone)
	self:PlayActivity(ACT_MELEE_ATTACK1,false,fcDone)
end

function ENT:_PossJump(entPossessor,fcDone)
	self:PlayActivity(ACT_MELEE_ATTACK2,false,fcDone)
end

function ENT:_PossSecondaryAttack(entPossessor,fcDone)
	if(!self.CanUseRadiation) then fcDone(true); return end
	self:PlayActivity(ACT_RANGE_ATTACK1_LOW,false,fcDone)
end

function ENT:OnDamaged(healthOld,healthNew,dmgTagen,attacker,inflictor,dmgInfo)
	if(!self.CanUseRadiation) then return end
	local healthMax = self:GetMaxHealth()
	local healthExplode = healthMax *0.2
	if(healthOld > healthExplode && healthNew <= healthExplode && math.random(1,3) == 1) then
		self.m_bNextExplode = true
	end
end

function ENT:OnKilledTarget(ent)
	if(ent:IsPlayer()) then self.m_lastRagdoll = ent:GetRagdollEntity()
	else
		timer.Simple(0,function()
			if(self:IsValid() && ent:IsValid()) then
				self.m_lastRagdoll = ent:GetRagdollEntity()
			end
		end)
	end
end

function ENT:SubInit() end

function ENT:IsLegCrippled()
	return self:LimbCrippled(HITBOX_LEFTARM) || self:LimbCrippled(HITBOX_RIGHTARM) || self:LimbCrippled(HITBOX_LEFTLEG) || self:LimbCrippled(HITBOX_RIGHTLEG)
end

function ENT:TranslateActivity(act)
	//self.BaseClass:TranslateActivity(act)
	if(act == ACT_WALK || act == ACT_RUN) then
		local crippled = self:IsLegCrippled()
		if(self:IsLegCrippled()) then
			act = act == ACT_WALK && ACT_WALK_HURT || ACT_RUN_HURT
			self:SetMovementActivity(act)
			return act
		end
	end
	if(self:IsArmed()) then
		if(act == ACT_IDLE) then return ACT_IDLE_ANGRY end
	end
	return act
end

function ENT:SelectGetUpActivity()
	local _, ang = self.ragdoll:GetBonePosition(self:GetMainRagdollBone())
	return ang.r <= 0 && ACT_ROLL_LEFT || ACT_ROLL_RIGHT
end

function ENT:Poison(ent)
	if(ent:IsPlayer()) then ent:SendLua("surface.PlaySound([[fx/fx_poison_stinger.mp3]])") end
	local tm = "npcpoison" .. self:EntIndex() .. "_" .. ent:EntIndex()
	timer.Create(tm,0.35,8,function()
		if(!ent:IsValid() || !ent:Alive()) then timer.Remove(tm)
		else
			local attacker
			if(self:IsValid()) then attacker = self
			else attacker = ent end
			local dmg = DamageInfo()
			dmg:SetDamageType(DMG_NERVEGAS)
			dmg:SetDamage(4)
			dmg:SetAttacker(attacker)
			dmg:SetInflictor(attacker)
			dmg:SetDamagePosition(ent:GetPos() +ent:OBBCenter())
			ent:TakeDamageInfo(dmg)
		end
	end)
end

function ENT:EventHandle(...)
	local event = select(1,...)
	if(event == "disarm") then
		self.m_bArmed = false
		self:StartEngineTask(GetTaskID("TASK_SET_ACTIVITY"),ACT_IDLE)
		return true
	end
	if(event == "mattack") then
		local dist = self.fMeleeDistance
		local dmg
		local force
		local ang
		local atk = select(2,...)
		if(atk == "back") then
			util.ParticleEffect("sporecarrier_radiation",self:GetCenter(),self:GetAngles(),nil,nil,3)
			sound.Play("fx/fx_flinder_body_head0" .. math.random(1,3) .. ".wav",self:GetPos(),75,100)
			local entRAD = ents.Create("point_radiation")
			entRAD:SetEntityOwner(self)
			entRAD:SetPos(self:GetCenter())
			entRAD:SetLife(2)
			entRAD:SetEmissionDistance(380)
			entRAD:SetRAD(25)
			entRAD:Spawn()
			entRAD:Activate()
			local i = 0
			local bonepos, boneang = self:GetBonePosition(i)
			while(bonepos) do
				ParticleEffect("blood_impact_green_01",bonepos,boneang,nil)
				i = i +1
				bonepos, boneang = self:GetBonePosition(i)
			end
			self:Remove()
		elseif(atk == "forward") then
			dist = self.fMeleeForwardDistance +20
			ang = Angle(30,0,0)
			force = Vector(420,0,0)
			dmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash_power")
		elseif(atk == "left") then
			local power = select(3,...)
			if(power) then
				ang = Angle(-12,40,-3)
				force = Vector(190,0,0)
				dmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash")
			else
				ang = Angle(-14,50,-4)
				force = Vector(340,0,0)
				dmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash_power")
			end
		elseif(atk == "right") then
			local power = select(3,...)
			if(power) then
				ang = Angle(-12,-40,3)
				force = Vector(190,0,0)
				dmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash")
			else
				ang = Angle(-14,-50,4)
				force = Vector(340,0,0)
				dmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash_power")
			end
		elseif(atk == "power") then
			ang = Angle(38,0,0)
			force = Vector(310,0,0)
			dmg = GetConVarNumber("sk_" .. self.skName .. "_dmg_slash_power")
		end
		local fcOnHit
		if(self.UsePoison) then
			fcOnHit = function(ent,dmginfo)
				if(ent:IsPlayer() && math.random(1,6) == 1) then self:Poison(ent) end
			end
		end
		local hit = self:DealMeleeDamage(dist,dmg,ang,force,nil,nil,true,nil,fcOnHit)
		if(hit) then self:EmitSound("npc/zombie/claw_strike" .. math.random(1,3) .. ".wav",75,100)
		else self:EmitSound("npc/sporecarrier/sporecarrier_armswing0" .. math.random(1,4) .. ".mp3",75,100) end
		return true
	end
	if(event == "eat") then
		local ragdoll = self.m_lastRagdoll
		self.m_lastRagdoll = nil
		if(IsValid(ragdoll) && self:GetPos():Distance(ragdoll:GetPos()) <= 80) then
			local particle = self:GetBloodParticle(ragdoll:GetBloodColor()) || "blood_impact_red_01"
			local numPhys = ragdoll:GetPhysicsObjectCount()
			if(numPhys > 0) then
				for i=0,numPhys -1 do
					local bone = ragdoll:GetPhysicsObjectNum(i)
					if(IsValid(bone)) then
						ParticleEffect(particle,bone:GetPos(),bone:GetAngles(),self)
					end
				end
			else ParticleEffect("blood_impact_red_01",ragdoll:GetPos(),ragdoll:GetAngles(),self) end
			sound.Play("fx/fx_flinder_body_head0" .. math.random(1,3) .. ".wav",ragdoll:GetPos(),75,100)
			ragdoll:Remove()
		end
		return true
	end
	if(event == "burrowed") then
		self:Sleep()
		self.m_nextUnburrow = CurTime() +math.Rand(0.25,4)
		return true
	end
end

function ENT:IsArmed() return self.m_bArmed end

function ENT:Arm()
	self:PlayActivity(ACT_ARM,true)
	self.m_bArmed = true
end

function ENT:Disarm()
	if(self:GetActivity() == ACT_DISARM) then return end
	self:PlayActivity(ACT_DISARM)
end

function ENT:OnAreaCleared()
	if(self:IsArmed()) then self:Disarm() end
end

function ENT:SelectDefaultSchedule()
	if(IsValid(self.m_lastRagdoll)) then
		local pos = self.m_lastRagdoll:GetPos()
		local posSelf = self:GetPos()
		local dist = posSelf:Distance(pos)
		if(dist <= 40) then self:PlayActivity(ACT_IDLE_STIMULATED)
		else self:MoveToPos(pos,dist <= 200) end
	end
end

function ENT:OnFoundEnemy(iEnemies)
	self.m_lastRagdoll = nil
	if(self.CanUseMounds) then
		self.m_nextUseMound = CurTime() +math.Rand(5,16)
	end
end

function ENT:OnStateChanged(old, new)
	if((old == NPC_STATE_COMBAT || old == NPC_STATE_ALERT) && new == NPC_STATE_IDLE && self:IsArmed()) then self:Disarm() end
	if((new == NPC_STATE_COMBAT || new == NPC_STATE_ALERT) && old != NPC_STATE_COMBAT && old != NPC_STATE_ALERT) then self:Arm() end
end

function ENT:FindMoundsInRange()
	local entMounds = ents.FindByClass("obj_tunnelermound")
	local distMax = 1000
	local posSelf = self:GetPos()
	for i = #entMounds,1,-1 do
		if(entMounds[i]:GetPos():Distance(posSelf) > distMax) then
			table.remove(entMounds,i)
		end
	end
	return entMounds
end

function ENT:AttackMelee(ent)
	self:SetTarget(ent)
	self:PlayActivity(ACT_MELEE_ATTACK1,2)
end

function ENT:SelectScheduleHandle(enemy,dist,distPred,disp)
	if(self.CanUseMounds) then
		if(IsValid(self.m_entMound)) then
			if(self.m_nextUnburrow) then
				if(CurTime() >= self.m_nextUnburrow) then
					local entMounds = self:FindMoundsInRange()
					local ent
					local numMounds = #entMounds
					if(numMounds == 1) then ent = entMounds[1]
					else
						for i = 1,numMounds do
							if(entMounds[i] == self.m_entMound) then
								table.remove(entMounds,i)
								break
							end
						end
						ent = entMounds[math.random(1,numMounds -1)]
					end
					self.m_entMound = nil
					self.m_nextUnburrow = nil
					if(IsValid(ent)) then
						local pos = ent:GetPos()
						pos.z = pos.z +ent:OBBMaxs().z +20
						self:SetPos(pos)
					end
					self:DropToFloor()
					self:Wake()
					if(IsValid(self.entEnemy)) then
						local posEnemy = self.entEnemy:GetPos()
						local pos = self:GetPos()
						local ang = (posEnemy -pos):Angle()
						ang.p = 0
						ang.r = 0
						self:SetAngles(ang)
					end
					self.m_nextUseMound = CurTime() +math.Rand(3,8)
					local hp = self:Health()
					local hpMax = self:GetMaxHealth()
					self:SetHealth(math.min(hp +20),hpMax)
					self:PlayActivity(ACT_CLIMB_UP)
				end
				return
			end
			local ent = self.m_entMound
			local pos = ent:GetPos() +Vector(0,0,100)
			local posSelf = self:GetPos()
			local dist = posSelf:Distance(pos)
			if(dist <= 80) then self:PlayActivity(ACT_CLIMB_DOWN)
			else self:MoveToPos(pos) end
			return
		end
		if(CurTime() >= self.m_nextUseMound) then
			self.m_nextUseMound = CurTime() +math.Rand(3,8)
			if(dist >= 200 && math.random(1,3) <= 2) then
				local entMounds = self:FindMoundsInRange()
				if(#entMounds > 0) then
					local distClosest = math.huge
					local entClosest
					local posSelf = self:GetPos()
					for _, ent in ipairs(entMounds) do
						local dist = ent:GetPos():Distance(posSelf)
						if(dist <= distClosest) then
							distClosest = dist
							entClosest = ent
						end
					end
					self.m_entMound = entClosest
				end
			end
		end
	end
	if(disp == 1) then
		if(self:CanSee(enemy)) then
			if(self.m_bNextExplode && dist <= 120) then
				self:PlayActivity(ACT_RANGE_ATTACK1_LOW)
				return
			end
			if((dist <= self.fMeleeDistance || distPred <= self.fMeleeDistance) && self:CanSee(enemy)) then
				self:PlayActivity(ACT_MELEE_ATTACK1,true)
				return
			end
			if(/*self.bDirectChase &&*/ dist <= self.fMeleeForwardDistance && CurTime() >= self.m_nextJumpAttack && !self:IsLegCrippled()) then
				local ang = self:GetAngleToPos(enemy:GetPos())
				if(ang.y <= 35 || ang.y >= 325) then
					local fTimeToGoal = self:GetPathTimeToGoal()
					if(fTimeToGoal <= 0.6 && fTimeToGoal >= 0.3) then
						self:PlayActivity(ACT_MELEE_ATTACK2)
						self.m_nextJumpAttack = CurTime() +math.Rand(1,4)
						return
					end
				end
			end
		end
		self:ChaseEnemy()
	elseif(disp == 2) then
		self:Hide()
	end
end
