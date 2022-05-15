if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("shared.lua")

include('shared.lua')

local _R = debug.getregistry()
_R.NPCFaction.Create("NPC_FACTION_ZOMBIE","npc_hopper_mod")
ENT.NPCFaction = NPC_FACTION_ZOMBIE
ENT.iClass = CLASS_ZOMBIE
util.AddNPCClassAlly(CLASS_ZOMBIE,"npc_hopper_mod")
ENT.sModel = "models/sin/hopper.mdl"
ENT.bFlinchOnDamage = false
ENT.fRangeDistanceLeap = 575
ENT.fRangeDistanceSpit = 1000
ENT.fMeleeDistance	= 60
ENT.possOffset = Vector(-30,0,50)

ENT.skName = "hopper"
ENT.CollisionBounds = Vector(20,20,24)

ENT.iBloodType = BLOOD_COLOR_RED
ENT.sSoundDir = "npc/hopper/"

ENT.m_tbSounds = {
	["Alert"] = "hopper_alert[1-3].mp3",
	["Attack"] = "hopper_attack[1-4].mp3",
	["Bite"] = "hopper_bite[1-3].mp3",
	["Death"] = "hopper_death[1-4].mp3",
	["FlyAttack"] = "hopper_flyattack[1-3].mp3",
	["Idle"] = "hopper_idle[1-3].mp3",
	["Jump"] = "hopper_jump[1-3].mp3",
	["LandAway"] = "hopper_landaway[1-3].mp3",
	["Pain"] = "hopper_pain[1-4].mp3",
	["PounceOff"] = "hopper_pounceoff[1-3].mp3",
	["Run"] = "hopper_run[1-2].mp3",
	["SpitAttack"] = "hopper_spitattack[1-3].mp3",
	["Turn"] = "hopper_turn[1-3].mp3",
	["Walk"] = "hopper_walk[1-4].mp3"
}

function ENT:OnInit()
	self:SetHullType(HULL_WIDE_SHORT)
	self:SetHullSizeNormal()
	self:SetCollisionBounds(self.CollisionBounds,Vector(self.CollisionBounds.x *-1,self.CollisionBounds.y *-1,0))
	
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND,CAP_OPEN_DOORS))
	self:SetHealth(GetConVarNumber("sk_" .. self.skName .. "_health"))
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

function ENT:OnThink()
	self:UpdateLastEnemyPositions()
	if(self.m_bInJump) then
		local bHitWorld
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
				bHitWorld = true
			end
		end
		if(!bHitWorld && !self.m_bJumpHit && IsValid(self.entEnemy) && self:Visible(self.entEnemy) && self:OBBDistance(self.entEnemy) <= 120) then
			local deg = 45
			local ang = self:GetAngleToPos(self.entEnemy:GetPos())
			if(ang.y <= deg || ang.y >= 360 -deg) then
				self.m_bJumpHit = true
				self:PlayActivity(ACT_RANGE_ATTACK1)
			end
		end
	end
	local act = self:GetActivity()
	if((act == ACT_RANGE_ATTACK2 || act == ACT_HL2MP_JUMP) && IsValid(self.entEnemy)) then
		self:TurnToTarget(self.entEnemy,2)
		self:NextThink(CurTime())
		return true
	end
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
		else self:PlayActivity(ACT_HOP) end
		return true
	elseif(event == "rattack") then
		self:EmitSound(self.sSoundDir .. "hopper_spit1.mp3",75,100)
		local att = self:GetAttachment(self:LookupAttachment("acid_spit"))
		local vTarget = (self:IsPossessed() && self:GetPossessor():GetPossessionEyeTrace().HitPos) || self:GetPredictedEnemyPosition() || (att.Pos +self:GetForward() *500)
		local dir = (vTarget -att.Pos):GetNormal()
		vTarget = att.Pos +dir *(math.min(att.Pos:Distance(vTarget),self.fRangeDistanceSpit))
		local entSpit = ents.Create("obj_spit_mod")
		entSpit:SetPos(att.Pos)
		entSpit:SetEntityOwner(self)
		entSpit:SetDamage(GetConVarNumber("sk_hopper_dmg_spit"))
		entSpit:SetHitSound(self.sSoundDir .. "hopper_acidhit.mp3")
		entSpit:Spawn()
		entSpit:Activate()
		local eta = entSpit:SetArcVelocity(att.Pos,vTarget,600,self:GetForward(),0.65)
		return true
	elseif(event == "mattack") then
		self:DealMeleeDamage(self.fMeleeDistance,30,Angle(32,0,0),Vector(120,0,0),DMG_SLASH)
		return true
	end
end

function ENT:LegsCrippled()
	return self:LimbCrippled(HITBOX_LEFTLEG) || self:LimbCrippled(HITBOX_RIGHTLEG)
end

function ENT:_PossJump(entPossessor,fcDone)
	self:PlayActivity(ACT_JUMP,false)
	self.bInSchedule = true
	self._possfuncJumpEnd = fcDone
end

function ENT:_PossPrimaryAttack(entPossessor, fcDone)
	self:PlayActivity(ACT_RANGE_ATTACK2,false,fcDone)
end

function ENT:SelectScheduleHandle(enemy,dist,distPred,disp)
	if(disp == D_HT) then
		if(self:CanSee(enemy)) then
			if(self.m_bNextHop) then
				self.m_bNextHop = false
				if(math.random(1,4) <= 3) then self:PlayActivity(ACT_HL2MP_JUMP) end
				return
			end
			if(dist <= self.fRangeDistanceSpit) then
				if(!self:LegsCrippled() && dist <= self.fRangeDistanceLeap && ((dist >= 160 && math.random(1,2) == 1) || dist <= 60) && math.abs(self:GetForward():DotProduct((enemy:GetPos() -self:GetPos()):GetNormal())) > 0.91) then
					self.bInSchedule = true
					self:PlayActivity(ACT_JUMP,true)
					return
				end
				self:PlayActivity(ACT_RANGE_ATTACK2)
				self.m_bNextHop = true
				return
			end
		end
		self:ChaseEnemy()
	elseif(disp == D_FR) then
		self:Hide()
	end
end