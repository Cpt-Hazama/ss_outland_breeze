if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	timer.Simple(8,function() if IsValid(self) then self:Remove() end end)
	self:SetModel("models/opfor/pit_drone_spike.mdl")
	self:PhysicsInitBox(Vector(-6,-6,-6), Vector(6,6,6))
	self:SetCollisionBounds(Vector(-6,-6,-6), Vector(6,6,6)) 
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_CUSTOM)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(1)
		phys:EnableDrag(false)
		phys:EnableGravity(false)
		phys:SetBuoyancyRatio(0)
		phys:Wake()
	end
end

function ENT:SetEntityOwner(ent)
	self:SetOwner(ent)
	self.entOwner = ent
end

function ENT:OnRemove()
end

function ENT:Think()
	if IsValid(self.entOwner) && self:GetPos():Distance(self.entOwner:GetPos()) >= 2000 then
		self:Remove()
		return
	end
end

function ENT:PhysicsCollide(data, physobj)
	local ent = data.HitEntity
	if IsValid(ent) && (ent:IsPlayer() || ent:IsNPC()) then
		if !IsValid(self.entOwner) || self.entOwner:Disposition(ent) <= 2 then
			if ent:GetClass() != "npc_turret_floor" then
				local dmg = DamageInfo()
				dmg:SetDamage(GetConVarNumber("sk_pitdrone_dmg_spike"))
				dmg:SetDamageType(DMG_SLASH)
				dmg:SetAttacker(IsValid(self.entOwner) && self.entOwner || self)
				dmg:SetInflictor(self)
				dmg:SetDamagePosition(data.HitPos)
				ent:TakeDamageInfo(dmg)
			elseif !ent.bSelfDestruct then
				ent:GetPhysicsObject():ApplyForceCenter(self:GetVelocity():GetNormal() *10000)
				ent:Fire("selfdestruct", "", 0)
				ent.bSelfDestruct = true
			end
			self:EmitSound("npc/pitdrone/pit_drone_hitbod" .. math.random(1,2) .. ".wav", 75, 100)
		end
	else self:EmitSound("npc/pitdrone/pit_drone_hit1.wav", 75, 100) end
	self:Remove()
	return true
end

