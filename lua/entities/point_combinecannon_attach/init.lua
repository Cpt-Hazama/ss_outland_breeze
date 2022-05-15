if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:SpawnFunction(pl,tr)
	if(!tr.Hit) then return end
	local pos = tr.HitPos
	local ang = pl:GetAimVector():Angle()
	ang.p = 0
	ang.r = 0
	local ent = ents.Create("point_combinecannon_attach")
	ent:SetPos(pos +Vector(0,0,40))
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self:SetModel("models/combine_turrets/combine_cannon_gun.mdl")
	self:SetMoveCollide(MOVECOLLIDE_DEFAULT)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	local min,max = Vector(-18,-2,5),Vector(17,2,17)
	self:SetCollisionBounds(min,max)
	self:PhysicsInitBox(min,max)
	self:SetSolid(SOLID_BBOX)//SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetUseType(SIMPLE_USE)
	
	self:SetColor(Color(255,0,0,128))
	self:DrawShadow(false)
	
	self:SetNetworkedBool("hasattached",false)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
end

function ENT:OnDetach()
	self.m_entAttached.m_entAttachedTo = nil
	self.m_entAttached = nil
	self:SetNetworkedBool("hasattached",false)
end

function ENT:Attach(ent)
	if(ent:GetClass() == "obj_combinecannon") then
		ent:SetPos(self:GetPos())
		ent:SetAngles(self:GetAngles())
		ent:SetAnglesOrigin(self:GetAngles())
		self.m_entAttached = ent
		ent.m_entAttachedTo = self
		self:SetNetworkedBool("hasattached",true)
	elseif(ent:GetClass() == "weapon_combinecannon") then
		local entDrop = ent:CreateDrop()
		ent:Remove()
		ent = entDrop
		local entM = ents.Create("obj_combinecannon")
		entM:SetPos(self:GetPos())
		entM:SetAngles(self:GetAngles())
		entM:SetName(ent:GetName())
		entM:SetDamage(ent:GetDamage())
		entM:SetDamageForce(ent:GetDamageForce())
		entM:SetDamagePlayers(ent:GetDamagePlayers())
		entM:SetDamageActivator(ent:GetDamageActivator())
		entM:SetDamageNPCs(ent:GetDamageNPCs())
		entM:SetDetachable(ent.m_bDetachable)
		entM:SetVital(ent:GetVital())
		entM:Spawn()
		entM:Activate()
		if(ent:IsBroken()) then entM:BreakDown() end
		if(ent.m_tReinstate) then entM:Reinstate(ent.m_tReinstate -CurTime()) end
		ent:OnAttached(entM)
		if(ent.Outputs) then
			entM.Outputs = entM.Outputs || {}
			for name,outputs in pairs(ent.Outputs) do
				entM.Outputs[name] = entM.Outputs[name] || {}
				table.Add(entM.Outputs[name],outputs)
			end
		end
		ent:Remove()
		self.m_entAttached = entM
		entM.m_entAttachedTo = self
		self:SetNetworkedBool("hasattached",true)
	end
end

function ENT:Use(activator)
	if(self:GetNetworkedBool("hasattached")) then return end
	local wep = activator:GetActiveWeapon()
	if(IsValid(wep) && wep:GetClass() == "weapon_combinecannon") then
		if(wep:IsCharging()) then return end
		self:Attach(wep)
	end
end

function ENT:KeyValue(key,val)
	key = string.lower(key)
end

function ENT:AcceptInput(name,activator,caller,data)
	name = string.lower(name)
	if(name == "attach") then
		local ent = ents.FindByName(data)[1]
		if(IsValid(ent)) then
			self:Attach(ent)
		end
		return true
	end
end