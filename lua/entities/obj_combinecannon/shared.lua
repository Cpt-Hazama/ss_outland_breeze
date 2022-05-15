
ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.PrintName		= "Combine Cannon"
ENT.Author			= "Silverlan"
ENT.Category = "Misc"

ENT.AimRestriction = Angle(65,65,0)

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

game.AddParticles("particles/striderbuster.pcf")
game.AddParticles("particles/hunter_projectile.pcf")
game.AddParticles("particles/weapon_fx.pcf")
game.AddParticles("particles/warpshield.pcf")
game.AddParticles("particles/ss_combinecannon.pcf")
game.AddParticles("particles/magnusson_burner.pcf")
for _,pt in ipairs({
	"striderbuster_break_lightning",
	"striderbuster_attach_flash",
	"hunter_muzzle_flash",
	"hunter_muzzle_flash_b",
	"Weapon_Combine_Ion_Cannon",
	"Weapon_Combine_Ion_Cannon_Explosion",
	"warp_shield_impact",
	"combinecannon_charge",
	"cingularity_start",
	"cingularity"
})
do PrecacheParticleSystem(pt) end

function ENT:SharedInit()
	local pos = self:GetPos()
	local attID = self:LookupAttachment("muzzle")
	local att = self:GetAttachment(attID)
	self.m_posMuzzle = att.Pos -pos
end


function ENT:GetActivator() return self:GetNetworkedEntity("activator") end

function ENT:IsMounted() return self:GetNetworkedBool("mounted") end

function ENT:IsBroken() return self:GetNetworkedBool("broken") end

function ENT:IsCharging() return self:GetNetworkedBool("charging") end

function ENT:CreateTrace()
	local pos = self:GetShootPos()
	local dir = self:GetForward()
	return util.TraceLine({
		start = pos,
		endpos = pos +dir *10000,
		filter = self,
		mask = MASK_SHOT
	})
end

function ENT:GetShootPos()
	local attID = self:LookupAttachment("muzzle")
	local att = self:GetAttachment(attID)
	if(!att) then return self:GetPos() end
	return att.Pos
end

function ENT:GetAnglesOrigin()
	return self:GetNetworkedAngle("angorigin")
end

local yawSpeed = 1.5
function ENT:Think()
	local angOrigin = self:GetAnglesOrigin()
	local angCur = self:GetAngles()
	local angTgt = Angle(angOrigin.p,angOrigin.y,angOrigin.r)
	local activator
	if(self:IsBroken()) then angTgt.p = angOrigin.p +40
	elseif(self:IsMounted()) then
		local pl = self:GetActivator()
		if(pl:IsValid()) then
			local trData = util.GetPlayerTrace(pl)
			trData.mask = MASK_SHOT
			trData.filter = {trData.filter,self}
			table.Add(trData.filter,ents.FindByClass("point_combinecannon_attach"))
			local tr = util.TraceLine(trData)
			local pos = self:GetPos()
			local dir = (tr.HitPos -pos):GetNormal()
			angTgt = dir:Angle()
			local posMuzzle = self:GetPos() +self:GetForward() *self.m_posMuzzle.x +self:GetRight() *self.m_posMuzzle.y +self:GetUp() *self.m_posMuzzle.z
			local trB = util.TraceLine({
				start = pos,
				endpos = pos +self:GetForward() *10000,
				filter = self,
				mask = MASK_SHOT
			})
			angTgt = angTgt -(self:GetForward():Angle() -(trB.HitPos -posMuzzle):Angle())
			if(SERVER) then activator = pl end
		end
	elseif(self:IsCharging()) then self:NextThink(CurTime()); return true end
	angTgt.p = math.ApproachAngle(angOrigin.p,angTgt.p,self.AimRestriction.p)
	angTgt.y = math.ApproachAngle(angOrigin.y,angTgt.y,self.AimRestriction.y)
	local ang = Angle(math.ApproachAngle(angCur.p,angTgt.p,yawSpeed),math.ApproachAngle(angCur.y,angTgt.y,yawSpeed),0)
	self:SetAngles(ang)
	self:NextThink(CurTime())
	if(activator) then self:Update() end
	return true
end