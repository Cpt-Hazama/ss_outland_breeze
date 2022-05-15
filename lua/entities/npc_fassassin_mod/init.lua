if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("shared.lua")

include('shared.lua')

util.AddNPCClassAlly(CLASS_COMBINE,"npc_fassassin_mod")
local _R = debug.getregistry()
_R.NPCFaction.Create("NPC_FACTION_COMBINE","npc_fassasin_mod")
ENT.NPCFaction = NPC_FACTION_COMBINE
ENT.sModel = "models/fassassin.mdl"
ENT.iClass = CLASS_COMBINE
ENT.fMeleeDistance = 84
ENT.fRangeDistance = 1024
ENT.bFlinchOnDamage = false
ENT.iBloodType = BLOOD_COLOR_RED
ENT.sSoundDir = "npc/fassassin/"

local FLIP_FORWARD = 1
local FLIP_LEFT = 2
local FLIP_BACKWARD = 3
local FLIP_RIGHT = 4

local tbFlipAct = {ACT_HL2MP_JUMP_AR2,ACT_HL2MP_JUMP_PISTOL,ACT_HL2MP_JUMP_SMG1,ACT_HL2MP_JUMP}

ENT.m_tbSounds = {
	["Death"] = "../combine_soldier/die[1-3].wav",
	["Pain"] = "../combine_soldier/pain[1-3].wav",
	["Foot"] = "../../player/pl_step[1-4].wav"
}

function ENT:OnInit()
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetCollisionBounds(Vector(10,10,55),Vector(-10,-10,0))

	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND,CAP_OPEN_DOORS))
	self.m_flNextFlipTime = 0
	self.m_FlipNextPrevent = 0
	self.m_nNumFlips = 0
	self.m_flNextLungeTime = 0
	self:SetHealth(GetConVarNumber("sk_fassassin_health"))
	
	local entSpriteEye = ents.Create("env_sprite")
	entSpriteEye:SetKeyValue("model","sprites/glow01.spr")
	entSpriteEye:SetKeyValue("rendermode","5") 
	entSpriteEye:SetKeyValue("rendercolor","232 85 50") 
	entSpriteEye:SetKeyValue("scale","0.1") 
	entSpriteEye:SetKeyValue("spawnflags","1") 
	entSpriteEye:SetParent(self)
	entSpriteEye:Fire("SetParentAttachment","Eye",0)
	entSpriteEye:Spawn()
	entSpriteEye:Activate()
	self:DeleteOnRemove(entSpriteEye)
	
	util.SpriteTrail(self,self:LookupAttachment("Eye"),Color(200,47,52),true,8,8,0.8,0.125,"models/combine_fassassin/eyetrail.vmt" )
end

local combine = {"npc_turret_floor","npc_rollermine","npc_combine_s","npc_manhack","npc_clawscanner","npc_helicopter","npc_combinegunship","npc_combine_camera","npc_cscanner","npc_turret_ceiling","npc_strider","npc_stalker","npc_combinedropship","npc_ministrider","npc_hunter","npc_metropolice"}
function ENT:ApplyCustomEntityDisposition(ent)
	if(ent:IsNPC() && (ent:Classify() == CLASS_COMBINE || table.HasValue(combine,ent:GetClass()))) then
		self:AddEntityRelationship(ent,D_LI,100)
		ent:AddEntityRelationship(self,D_LI,100)
		return true
	end
end

function ENT:EventHandle(...)
	local event = select(1,...)
	if(event == "mattack") then
		local dmg = GetConVarNumber("sk_fassassin_dmg_kick")
		local dist = self.fMeleeDistance
		local ang = Angle(-30,40,10)
		local force = Vector(60,0,0)
		self:DealMeleeDamage(dist,dmg,ang,force,DMG_CLUB)
		return true
	end
	if(event == "rattack") then
		local type = select(2,...)
		local att = self:GetAttachment(self:LookupAttachment(type == "right" && "RightMuzzle" || "LeftMuzzle"))
		local effectdata = EffectData()
		effectdata:SetStart(att.Pos)
		effectdata:SetOrigin(att.Pos)
		effectdata:SetScale(1)
		effectdata:SetAngles(att.Ang)
		util.Effect("MuzzleEffect", effectdata)
		local dir = att.Ang:Forward()
		if(!self:IsPossessed() && IsValid(self.entEnemy) && self.entEnemy:Health() > 0) then
			local posTgt = self.entEnemy:GetCenter()
			local angAcc = (posTgt -att.Pos):Angle()
			dir = Angle(math.ApproachAngle(att.Ang.p,angAcc.p,45),math.ApproachAngle(att.Ang.y,angAcc.y,35),0):Forward()
		end
		local fSpread = 0.04
		self:FireBullets({
			Num = 1,
			Src = att.Pos,
			Attacker = self,
			Dir = dir,
			Spread = Vector(fSpread,fSpread,fSpread),
			Tracer = 1,
			Force = 3,
			Damage = GetConVarNumber("sk_fassassin_dmg_bullet")
		})
		self:EmitSound("weapons/pl_gun" .. math.random(1,2) .. ".wav",100,100)
		return true
	end
end

function ENT:OnThink()
	self:UpdateLastEnemyPositions()
	local pp = self:GetPoseParameter("aim_pitch")
	local ppTgt
	local bPossessed = self:IsPossessed()
	if(!IsValid(self.entEnemy) && !bPossessed) then
		if(pp == 0) then return end
		ppTgt = 0
	else
		local posTgt = !bPossessed && self.entEnemy:GetCenter() || self:GetPossessor():GetPossessionEyeTrace().HitPos
		local pos,ang = self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_Spine"))
		ang = (posTgt -pos):Angle()// -ang
		ppTgt = math.NormalizeAngle(ang.p)
	end
	self:SetPoseParameter("aim_pitch",math.ApproachAngle(pp,ppTgt,1))
	self:NextThink(CurTime())
	return true
end

function ENT:OnDamaged(dmgTaken,attacker,inflictor,dmginfo)
	if(self.m_nNumFlips <= 0) then self.m_nNumFlips = math.random(1,2) end
end

function ENT:OnDanger(vecPos,iType)
	local ang = self:GetAngles()
	local angDanger = (vecPos -self:GetPos()):Angle()
	local y = math.NormalizeAngle(ang.y -angDanger.y)
	local flip = y <= 45 && y >= -45 && FLIP_BACKWARD || y <= 135 && y > 45 && FLIP_RIGHT || y >= -135 && y < -45 && FLIP_LEFT || FLIP_FORWARD
	self:PlayActivity(tbFlipAct[flip])
	return true
end

function ENT:PlayJumpActivity(flip)
	local pos = self:GetCenter()
	if(!flip) then
		local tbFlip = {}
		local dist = 250
		local trInfo = {
			start = pos,
			filter = self,
			mask = MASK_NPCWORLDSTATIC
		}
		local fwd = self:GetForward()
		local rgt = self:GetRight()
		for i = 1, 4 do
			if(i != self.m_FlipNextPrevent) then
				trInfo.endpos = pos +(i == FLIP_FORWARD && fwd || i == FLIP_LEFT && rgt || i == FLIP_BACKWARD && fwd *-1 || rgt *-1) *dist
				local tr = util.TraceLine(trInfo)
				if(!tr.Hit || tr.Entity == self.entEnemy && self:NearestPoint(tr.HitPos):Distance(tr.HitPos) >= 150) then
					table.insert(tbFlip,i)
				end
			end
		end
		if(#tbFlip == 0) then return false end
		self.m_nNumFlips = math.max(self.m_nNumFlips -1,0)
		flip = table.Random(tbFlip)
	end
	self.m_FlipNextPrevent = flip == FLIP_LEFT && FLIP_RIGHT || flip == FLIP_RIGHT && FLIP_LEFT || flip == FLIP_FORWARD && FLIP_BACKWARD || FLIP_FORWARD
	self:PlayActivity(tbFlipAct[flip])
	return true
end

function ENT:MovementCost(vecStart,vecEnd,cost)
	if(!IsValid(self.entEnemy)) then return end
	local multiplier = 1
	local moveDir = (vecEnd -vecStart):GetNormal()
	local enemyDir = (self.entEnemy:GetPos() -vecStart):GetNormal()
	
	if(enemyDir:DotProduct(moveDir) > 0.5) then multiplier = 16 end
	cost = cost *multiplier
	return cost
end

function ENT:_PossJump(entPossessor,fcDone)
	local dir = entPossessor:KeyDown(IN_MOVELEFT) && FLIP_RIGHT ||
				entPossessor:KeyDown(IN_MOVERIGHT) && FLIP_LEFT ||
				entPossessor:KeyDown(IN_BACK) && FLIP_BACKWARD ||
				FLIP_FORWARD
	self:PlayActivity(tbFlipAct[dir],false,fcDone)
end

function ENT:_PossPrimaryAttack(entPossessor, fcDone)
	self:PlayActivity(ACT_RANGE_ATTACK1,false,fcDone)
end

function ENT:_PossSecondaryAttack(entPossessor, fcDone)
	self:PlayActivity(math.random(1,2) == 1 && ACT_MELEE_ATTACK1 || ACT_MELEE_ATTACK2,false,fcDone)
end

function ENT:SelectScheduleHandle(enemy,dist,distPred,disp)
	if(disp == D_HT) then
		local health = self:Health()
		local healthMax = self:GetMaxHealth()
		local fraction = health /healthMax
		if(self:CanSee(enemy)) then
			if(dist <= self.fMeleeDistance || distPred <= self.fMeleeDistance) then
				if((fraction <= 0.33 && math.random(1,3) != 1) || math.random(1,8) <= 3) then
					local pos = self:GetPos()
					if(!self.m_posLastLeapEscape || pos:Distance(self.m_posLastLeapEscape) > 25 || (CurTime() -self.m_tmLastEscape) >= 5) then
						self:PlayJumpActivity(FLIP_BACKWARD)
						self.m_posLastLeapEscape = pos
						self.m_tmLastEscape = CurTime()
					end
					return
				end
				if(CurTime() >= self.m_flNextLungeTime) then
					self.m_flNextLungeTime = CurTime() +math.Rand(0.8,2.2)
					self:PlayActivity(ACT_MELEE_ATTACK2)
				else self:PlayActivity(ACT_MELEE_ATTACK1,true) end
				return
			end
			if(CurTime() >= self.m_flNextFlipTime && (self.m_nNumFlips > 0 || (dist <= self.fRangeDistance && math.random(1,6) >= 5))) then
				self.m_flNextFlipTime = CurTime() +math.Rand(0.4,2)
				if(self:PlayJumpActivity()) then return end
			end
			if(dist <= self.fRangeDistance) then
				self:PlayActivity(ACT_RANGE_ATTACK1,true)
				return
			end
		end
		self:ChaseEnemy()
	elseif(disp == D_FR) then self:Hide() end
end
