if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("shared.lua")

include('shared.lua')

local _R = debug.getregistry()
_R.NPCFaction.Create("NPC_FACTION_ZOMBIE","npc_leperkin_mod")
ENT.NPCFaction = NPC_FACTION_ZOMBIE
ENT.iClass = CLASS_ZOMBIE
util.AddNPCClassAlly(CLASS_ZOMBIE,"npc_leperkin_mod")
ENT.sModel = "models/sin/leperkin.mdl"
ENT.fRangeDistanceLeap = 780
ENT.fRangeDistanceSpit = 1000
ENT.fMeleeDistance	= 50
ENT.tblAlertAct = {ACT_IDLE_AGITATED}
ENT.AlertChance = 40
ENT.DamageScales = {
	[DMG_BURN] = 4,
	[DMG_BLAST] = 2,
	[DMG_SHOCK] = 1.2,
	[DMG_POISON] = 0.1,
	[DMG_ACID] = 0.1,
	[DMG_DIRECT] = 4
}

ENT.skName = "leperkin"
ENT.CollisionBounds = Vector(15,15,64)

ENT.iBloodType = BLOOD_COLOR_RED
ENT.sSoundDir = "npc/leperkin/"

ENT.tblFlinchActivities = {
	[HITBOX_GENERIC] = ACT_FLINCH_CHEST,
	[HITBOX_LEFTARM] = ACT_FLINCH_LEFTARM,
	[HITBOX_RIGHTARM] = ACT_FLINCH_RIGHTARM,
	[HITBOX_LEFTLEG] = ACT_FLINCH_LEFTLEG,
	[HITBOX_RIGHTLEG] = ACT_FLINCH_RIGHTLEG,
	[HITBOX_HEAD] = ACT_FLINCH_HEAD,
}

ENT.m_tbSounds = {
	["Attack"] = "leperkin_attack[1-3].mp3",
	["Death"] = "stage2_death[1-4].mp3",
	["Pain"] = "stage2_pain[1-7].mp3",
	["FootLeft"] = "leperkin_step4.mp3",
	["FootRight"] = "leperkin_step[1-3].mp3",
	["Death"] = "stage2_death[1-4].mp3",
	["Walk"] = "stage2_walkall.mp3",
	["WalkFast"] = "stage2_walkfast.mp3",
	["Scream"] = "stage2_scream[1-2].mp3",
	["Alert"] = "leperkin_attack[1-3].mp3",
	["FrenzyAttack"] = "stage2_frenzyattack[1-4].mp3",
	["FrenzyJumpBack"] = "stage2_frenzyjumpback.mp3",
	["Leap"] = "stage2_leap[1-2].mp3",
	["Jump"] = {"stage2_jump[1-2].mp3","stage2_leap[1-2].mp3"},
	["LandForward"] = "stage2_landforward[1-2].mp3",
	["Turn"] = "stage2_turn[1-2].mp3",
	["WallLand"] = "stage2_walland[1-2].mp3",
	["OutOfSludge"] = "stage2_outofsludge[1-2].mp3",
	["OnFire"] = "stage2_onfire[1-2].mp3",
	["Melee"] = "stage2_melee[1-4].mp3",
	["Melee01"] = "stage2_melee01_[1-2].mp3",
	["Run"] = "stage2_run.mp3",
	["ChargeUp"] = "leperkin_chargeup.mp3",
	["Morph"] = "stage2_morph[1-2].mp3",
	["Hit"] = "leperkin_hit[1-3].mp3",
	["Whoosh"] = "leperkin_whoosh[1-3].mp3"
}

function ENT:OnInit()
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetCollisionBounds(self.CollisionBounds,Vector(self.CollisionBounds.x *-1,self.CollisionBounds.y *-1,0))
	
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND,CAP_OPEN_DOORS))
	self:SetHealth(GetConVarNumber("sk_" .. self.skName .. "_health"))
	if(math.random(1,2) == 1) then self:Give("weapon_npc_leadpipe") end
	self:SetBodygroup(0,math.random(1,2))
	
	self.cspIdle = CreateSound(self,self.sSoundDir .. "stage2_idle.wav")
	if(!self.m_bVoiceDisabled) then self.cspIdle:Play() end
	self:StopSoundOnDeath(self.cspIdle)
	
	self.m_nextSpit = 0
	self.m_nextJump = 0
	
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

function ENT:PlaySound(...)
	if(self.m_tSequence) then return end
	return self.BaseClass.PlaySound(self,...)
end

function ENT:InputHandle(cvar,activator,caller,data)
	if(cvar == "enablevoice") then
		if(self.m_bVoiceDisabled) then
			self.m_bVoiceDisabled = false
			self.cspIdle:Play()
		end
		return true
	elseif(cvar == "disablevoice") then
		if(!self.m_bVoiceDisabled) then
			self.m_bVoiceDisabled = true
			self.cspIdle:Stop()
		end
		return true
	end
	return false
end

function ENT:KeyValueHandle(key,val)
	if(key == "m_bvoicedisabled") then
		self.m_bVoiceDisabled = tobool(val)
		return true
	end
end

function ENT:Flinch(hitgroup)
	local act = self.tblFlinchActivities[hitgroup] || self.tblFlinchActivities[HITGROUP_GENERIC] || self.tblFlinchActivities[HITBOX_GENERIC]
	if(!act) then return end
	self:RestartGesture(act)
end

function ENT:OnThink()
	self:UpdateLastEnemyPositions()
	if(self:IsOnFire()) then self:SetIdleActivity(ACT_IDLE_ON_FIRE)
	else self:SetIdleActivity(ACT_IDLE) end
	if(self.m_bInJump) then
		if(CurTime() -self.m_tJumpStart >= 0.1 && self:GetVelocity().z <= 0) then
			local pos = self:GetPos()
			local tr = util.TraceHull({
				start = pos,
				endpos = pos -Vector(0,0,50),
				filter = self,
				mask = MASK_NPCWORLDSTATIC,
				mins = self:OBBMins(),
				maxs = self:OBBMaxs()
			})
			if(tr.Hit) then
				self.m_tJumpStart = nil
				self.m_bInJump = false
				self.m_bJumpHit = nil
				self.bInSchedule = false
				self:PlayActivity(ACT_LAND,false,self._possfuncJumpEnd)
				self._possfuncJumpEnd = nil
			end
		end
	end
	local act = self:GetActivity()
	if((act == ACT_RANGE_ATTACK2 || act == ACT_HL2MP_JUMP) && IsValid(self.entEnemy)) then
		self:TurnToTarget(self.entEnemy,2)
		self:NextThink(CurTime())
		return true
	end
	self:NextThink(CurTime())
	return true
end

function ENT:EventHandle(...)
	local event = select(1,...)
	if(event == "jump") then
		local tp = select(2,...)
		if(tp == "start") then
			self:SetGroundEntity(NULL)
			self:SetVelocity(self:GetForward() *600 +self:GetUp() *300)
			self.m_bInJump = true
			self.m_tJumpStart = CurTime()
		else self:PlayActivity(ACT_GLIDE) end
		return true
	elseif(event == "rattack") then
		self:EmitSound(self.sSoundDir .. "stage2_spitgest" .. math.random(1,2) .. ".mp3",75,100)
		local att = self:GetAttachment(self:LookupAttachment("acid_spit"))
		local vTarget = (self:IsPossessed() && self:GetPossessor():GetPossessionEyeTrace().HitPos) || self:GetPredictedEnemyPosition() || (att.Pos +self:GetForward() *500)
		local dir = (vTarget -att.Pos):GetNormal()
		vTarget = att.Pos +dir *(math.min(att.Pos:Distance(vTarget),self.fRangeDistanceSpit))
		local entSpit = ents.Create("obj_spit_mod")
		entSpit:SetPos(att.Pos)
		entSpit:SetEntityOwner(self)
		entSpit:SetDamage(GetConVarNumber("sk_leperkin_dmg_spit"))
		entSpit:SetHitSound(self.sSoundDir .. "stage2_acidhit.mp3")
		entSpit:Spawn()
		entSpit:Activate()
		local eta = entSpit:SetArcVelocity(att.Pos,vTarget,520,self:GetForward(),0.65)
		return true
	elseif(event == "mattack") then
		local dist = self.fMeleeDistance
		local dmg
		local ang
		local seq = self:GetSequence()
		if(seq == self:LookupSequence("Melee_blunt_weapon") || seq == self:LookupSequence("Melee_01_blunt_weapon")) then
			dmg = GetConVarNumber("sk_leperkin_dmg_slash_blunt")
			ang = Angle(34,-12,2)
		else
			dmg = GetConVarNumber("sk_leperkin_dmg_slash")
			if(string.find(event,"right")) then ang = Angle(26,26,-3)
			else ang = Angle(-26,-26,3) end
		end
		local hit = self:DealMeleeDamage(dist,dmg,ang,Vector(110,0,0),nil,nil,true)
		if(hit) then self:EmitEventSound("Hit")
		else self:EmitEventSound("Whoosh") end
		return true
	end
end

function ENT:LegsCrippled()
	return self:LimbCrippled(HITBOX_LEFTLEG) || self:LimbCrippled(HITBOX_RIGHTLEG)
end

function ENT:_PossJump(entPossessor,fcDone)
	self:PlayActivity(ACT_JUMP,false,fcDone)
	self._possfuncJumpEnd = fcDone
end

function ENT:_PossPrimaryAttack(entPossessor, fcDone)
	self:PlayActivity(ACT_MELEE_ATTACK1,false,fcDone)
end

function ENT:_PossSecondaryAttack(entPossessor,fcDone)
	self:RestartGesture(ACT_GESTURE_RANGE_ATTACK1)
	timer.Simple(1,function()
		if(self:IsValid() && entPossessor:IsValid()) then fcDone() end
	end)
end

function ENT:AttackMelee(ent)
	self:SetTarget(ent)
	local act = ACT_MELEE_ATTACK1
	local wep = self:GetActiveWeapon()
	if(wep:IsValid()) then act = wep:TranslateActivity(act) end
	self:PlayActivity(act,2)
end

function ENT:SelectScheduleHandle(enemy,dist,distPred,disp)
	if(disp == D_HT) then
		if(self:CanSee(enemy)) then
			if(dist <= self.fMeleeDistance) then
				local act = ACT_MELEE_ATTACK1
				local wep = self:GetActiveWeapon()
				if(wep:IsValid()) then act = wep:TranslateActivity(act) end
				self:PlayActivity(act,true)
				return
			end
			if(dist >= 160 && math.abs(self:GetForward():DotProduct((enemy:GetPos() -self:GetPos()):GetNormal())) > 0.91) then
				if(dist >= 360 && CurTime() >= self.m_nextJump && dist <= self.fRangeDistanceSpit) then
					self.m_nextJump = CurTime() +math.Rand(3,6)
					self.m_nextSpit = CurTime() +2.5
					if(math.random(1,5) <= 3) then self:PlayActivity(ACT_JUMP,true) end
					return
				end
				if(dist <= self.fRangeDistanceSpit && CurTime() >= self.m_nextSpit) then
					self.m_nextSpit = CurTime() +math.Rand(2,3)
					self.m_nextJump = CurTime() +1.5
					self:RestartGesture(ACT_GESTURE_RANGE_ATTACK1)
					return
				end
			end
		end
		self:ChaseEnemy()
	elseif(disp == D_FR) then
		self:Hide()
	end
end