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
	local ent = ents.Create("obj_combinecannon_dropped")
	ent:SetPos(pos +Vector(0,0,40))
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()
	return ent
end

AccessorFunc(ENT,"m_damage","Damage",FORCE_NUMBER)
AccessorFunc(ENT,"m_damageForce","DamageForce",FORCE_NUMBER)
AccessorFunc(ENT,"m_bDamagePlayers","DamagePlayers",FORCE_BOOL)
AccessorFunc(ENT,"m_bDamageActivator","DamageActivator",FORCE_BOOL)
AccessorFunc(ENT,"m_bDamageNPCs","DamageNPCs",FORCE_BOOL)
AccessorFunc(ENT,"m_bVital","Vital",FORCE_BOOL)
function ENT:Initialize()
	self:SetModel("models/combine_turrets/combine_cannon_gun.mdl")
	self:SetMoveCollide(MOVECOLLIDE_DEFAULT)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	local min,max = Vector(-18,-2,5),Vector(17,2,17)
	self:SetCollisionBounds(min,max)
	self:PhysicsInitBox(min,max)
	self:SetSolid(SOLID_OBB)
	local phys = self:GetPhysicsObject()
	if(phys:IsValid()) then
		phys:Wake()
		phys:SetMass(2)
	end
	self:SetUseType(SIMPLE_USE)
end

function ENT:IsBroken() return self.m_bBroken || false end

util.AddNetworkString("ss_cc_dropped_break")
function ENT:BreakDown()
	if(self:IsBroken()) then return end
	self.m_bBroken = true
	net.Start("ss_cc_dropped_break")
		net.WriteEntity(self)
	net.Broadcast()
end

util.AddNetworkString("ss_cc_dropped_reinstate")
function ENT:Reinstate(t)
	self.m_tReinstate = nil
	if(t) then
		self.m_tReinstate = CurTime() +t
		timer.Create("ss_cc_reinstate" .. self:EntIndex(),t,1,function()
			if(self:IsValid()) then
				self:Reinstate()
			end
		end)
		return
	end
	net.Start("ss_cc_dropped_reinstate")
		net.WriteEntity(self)
	net.Broadcast()
	timer.Remove("ss_cc_reinstate" .. self:EntIndex())
	self.m_bBroken = false
end

function ENT:OnRemove()
	timer.Remove("ss_cc_reinstate" .. self:EntIndex())
end

function ENT:OnAttached(entMounted)
end

function ENT:OnPickedUp(activator,wep)
end

function ENT:Use(activator)
	local wep = activator:Give("weapon_combinecannon")
	if(IsValid(wep)) then
		self:OnPickedUp(activator,wep)
		wep:SetName(self:GetName())
		wep.m_bDetachable = self.m_bDetachable
		wep:SetDamage(self:GetDamage())
		wep:SetDamageForce(self:GetDamageForce())
		wep:SetDamagePlayers(self:GetDamagePlayers())
		wep:SetDamageActivator(self:GetDamageActivator())
		wep:SetDamageNPCs(self:GetDamageNPCs())
		wep:SetVital(self:GetVital())
		if(self:IsBroken()) then wep:BreakDown() end
		if(self.m_tReinstate) then wep:Reinstate(self.m_tReinstate -CurTime()) end
		if(self.Outputs) then
			wep.Outputs = wep.Outputs || {}
			for name,outputs in pairs(self.Outputs) do
				wep.Outputs[name] = wep.Outputs[name] || {}
				table.Add(wep.Outputs[name],outputs)
			end
		end
		activator:SelectWeapon("weapon_combinecannon")
		self:Remove()
	end
end

function ENT:AcceptInput(name,activator,caller,data)
	name = string.lower(name)
	if(name == "break") then
		self:BreakDown()
		return true
	elseif(name == "reinstate") then
		self:Reinstate()
		return true
	elseif(name == "delayedreinstate") then
		self:Reinstate(tonumber(data))
		return true
	end
end