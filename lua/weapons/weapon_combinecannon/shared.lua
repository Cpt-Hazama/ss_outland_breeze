if(!MAP_IS_OUTLAND_BREEZE) then return end
if(SERVER) then
	include("outputs.lua")
	AddCSLuaFile("cl_init.lua")
	AddCSLuaFile("shared.lua")
	AddCSLuaFile("sh_anim.lua")

	SWEP.Weight = 4
	SWEP.AutoSwitchTo = true
	SWEP.AutoSwitchFrom = true
	
	util.AddNetworkString("ss_cc_deploy")
	util.AddNetworkString("ss_cc_holster")
	util.AddNetworkString("ss_cc_charge")
	util.AddNetworkString("ss_cc_impact")
	function SWEP:Deploy() // TODO: Inform new players
		self:SetWeaponHoldType("crossbow")
		net.Start("ss_cc_deploy")
			net.WriteEntity(self)
		net.Broadcast()
		self:SharedDeploy()
	end
	function SWEP:Holster()
		net.Start("ss_cc_holster")
			net.WriteEntity(self)
		net.Broadcast()
		return false
	end
	function SWEP:CreateTrace()
		local pos = self.Owner:GetShootPos()
		local dir = self.Owner:GetAimVector()
		return util.TraceLine({
			start = pos,
			endpos = pos +dir *10000,
			filter = {self,self.Owner},
			mask = MASK_SHOT
		})
	end
	function SWEP:OnCannonFired() end
	function SWEP:Impact()
		self:OnCannonFired()
		self:TriggerOutput("onfired",self:GetActivator())
		self:RestoreFOV()
		self.Owner:SetVelocity(self.Owner:GetAimVector() *-1200)
		net.Start("ss_cc_impact")
			net.WriteEntity(self)
		net.Broadcast()
		local dir = self.Owner:GetAimVector()
		local tr = self:CreateTrace()
		local distMax = 250
		for _,ent in ipairs(ents.FindInSphere(tr.HitPos,distMax)) do
			if(ent != self && ((self:GetDamageNPCs() && ent:IsNPC()) || ((self:GetDamagePlayers() || (ent == self.Owner && self:GetDamageActivator())) && ent:IsPlayer()) || ent:GetPhysicsObject():IsValid())) then
				local am = self:GetDamage()
				local dist = ent:NearestPoint(tr.HitPos):Distance(tr.HitPos)
				am = am *(1 -(dist /distMax))
				local dmg = DamageInfo()
				dmg:SetDamage(am)
				dmg:SetDamageForce(dir *self:GetDamageForce())
				dmg:SetDamageType(DMG_DISSOLVE)
				dmg:SetInflictor(self)
				dmg:SetAttacker(self.Owner)
				ent:TakeDamageInfo(dmg)
				self:OnHit(ent)
			end
		end
		util.ScreenShake(tr.HitPos,1000,5000,2,distMax *2)
	end
	function SWEP:OnHit(ent) end
	AccessorFunc(SWEP,"m_damage","Damage",FORCE_NUMBER)
	AccessorFunc(SWEP,"m_damageForce","DamageForce",FORCE_NUMBER)
	AccessorFunc(SWEP,"m_bDamagePlayers","DamagePlayers",FORCE_BOOL)
	AccessorFunc(SWEP,"m_bDamageActivator","DamageActivator",FORCE_BOOL)
	AccessorFunc(SWEP,"m_bDamageNPCs","DamageNPCs",FORCE_BOOL)
	AccessorFunc(SWEP,"m_bVital","Vital",FORCE_BOOL)
	function SWEP:ChargeFire()
		if(self:IsBroken()) then self:EmitSound("Buttons.snd42",75,100) return end
		if(self:IsCharging()) then return end
		self:OnCannonCharging()
		//self:EmitSound("NPC_Strider.Charge",75,100)
		self:SetNetworkedBool("charging",true)
		net.Start("ss_cc_charge")
			net.WriteEntity(self)
		net.Broadcast()
		self:SetNextPrimaryFire(CurTime() +5)
		timer.Simple(4.5,function()
			if(self:IsValid()) then
				self:Impact()
				self:SetNetworkedBool("charging",false)
			end
		end)
	end
	function SWEP:OnCannonCharging() end
	function SWEP:IsBroken() return self.m_bBroken end
	function SWEP:OnDropped(ent) end
	function SWEP:CreateDrop()
		if(self.m_entDrop) then return self.m_entDrop end
		local ent = ents.Create("obj_combinecannon_dropped")
		self.m_entDrop = ent
		if(IsValid(ent)) then
			local dir = self.Owner:GetAimVector()
			local ang = dir:Angle()
			ent:SetPos(self.Owner:GetShootPos() -Vector(0,0,20))
			ent:SetAngles(ang)
			ent:SetOwner(self.Owner)
			ent:SetName(self:GetName())
			ent:Spawn()
			ent:Activate()
			ent.m_bDetachable = self.m_bDetachable
			ent:SetDamage(self:GetDamage())
			ent:SetDamageForce(self:GetDamageForce())
			ent:SetDamagePlayers(self:GetDamagePlayers())
			ent:SetDamageActivator(self:GetDamageActivator())
			ent:SetDamageNPCs(self:GetDamageNPCs())
			ent:SetVital(self:GetVital())
			if(self:IsBroken()) then ent:BreakDown() end
			if(self.m_tReinstate) then ent:Reinstate(self.m_tReinstate -CurTime()) end
			ent:SetAngles(ang)
			ent:EmitSound("Weapon_RPG.LaserOff",75,100)
			if(self.Outputs) then
				ent.Outputs = ent.Outputs || {}
				for name,outputs in pairs(self.Outputs) do
					ent.Outputs[name] = ent.Outputs[name] || {}
					table.Add(ent.Outputs[name],outputs)
				end
			end
			local phys = ent:GetPhysicsObject()
			if(phys:IsValid()) then
				phys:ApplyForceCenter(ang:Forward() *250 +ang:Up() *180)
			end
			timer.Simple(0.25,function()
				if(IsValid(ent)) then ent:SetOwner(NULL) end
			end)
			self:OnDropped(ent)
			return ent
		end
		self:OnDropped(NULL)
		return NULL
	end
	function SWEP:Reload()
		if(self:IsCharging()) then return end
		if(CurTime() -self.m_tInit >= 2) then
			self:Remove()
		end
	end
	function SWEP:GetActivator() return self.Owner end
	function SWEP:Initialize()
		self.m_tInit = CurTime()
		self.m_damage = self.m_damage || 100000
		self.m_damageForce = self.m_damageForce || 5000
		self.m_bDisabled = self.m_bDisabled || false
		if(self.m_bDamageNPCs == nil) then self.m_bDamageNPCs = true end
		if(self.m_bDamageActivator == nil) then self.m_bDamageActivator = true end
		self.m_bDamagePlayers = self.m_bDamagePlayers || false
		self.m_bDetachable = self.m_bDetachable || false
	end
	util.AddNetworkString("ss_cc_break")
	function SWEP:BreakDown()
		if(self:IsBroken()) then return end
		self:RestoreFOV()
		self.m_bBroken = true
		net.Start("ss_cc_break")
			net.WriteEntity(self)
		net.Broadcast()
		self:TriggerOutput("onbreak",self:GetActivator())
	end
	util.AddNetworkString("ss_cc_reinstate")
	function SWEP:Reinstate(t)
		if(!self:IsBroken()) then return end
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
		timer.Remove("ss_cc_reinstate" .. self:EntIndex())
		self:SetNextPrimaryFire(CurTime() +1)
		self.m_bBroken = false
		net.Start("ss_cc_reinstate")
			net.WriteEntity(self)
		net.Broadcast()
	end
	function SWEP:AcceptInput(name,activator,caller,data)
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
	function SWEP:RestoreFOV()
		if(!self.m_fovReal) then return end
		self.Owner:SetFOV(self.m_fovReal,0.25)
		self.m_fovReal = nil
	end
end
game.AddParticles("particles/combinecannon_smoke.pcf")
PrecacheParticleSystem("combinecannon_smoke")

include("sh_anim.lua")

SWEP.Category		= "Misc"

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.ViewModel = "models/combine_turrets/combine_cannon_gun.mdl"
SWEP.WorldModel = "models/combine_turrets/combine_cannon_gun.mdl"

SWEP.Primary.Recoil = -2.5
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.065
SWEP.Primary.Delay = 0.12

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

SWEP.ReloadDelay = 0.8

function SWEP:IsCharging() return self:GetNetworkedBool("charging") end

function SWEP:PrimaryAttack()
	if(CLIENT) then return end
	if(CurTime() < self:GetNextPrimaryFire()) then return end
	self:ChargeFire()
end

function SWEP:SharedDeploy()
	local idx = self.Owner:EntIndex()
	hook.Add("SetupMove","combinecannon_move" .. idx,function(pl,move)
		if(pl == self.Owner) then
			local vel = move:GetVelocity()
			vel.x = vel.x *0.7
			vel.y = vel.y *0.7
			move:SetVelocity(vel)
		end
	end)
end

function SWEP:OnRemove()
	if(IsValid(self.Owner)) then
		self:SharedHolster()
		if(SERVER) then
			self:CreateDrop()
		end
	elseif(SERVER && self.m_bVital) then self:CreateDrop() end
	if(SERVER) then self:RestoreFOV(); timer.Remove("ss_cc_reinstate" .. self:EntIndex()) end
end

function SWEP:SharedHolster()
	local idx = self.Owner:EntIndex()
	hook.Remove("SetupMove","combinecannon_move" .. idx)
end

function SWEP:SecondaryAttack()
	if(CLIENT) then return end
	if(self.m_fovReal) then self:RestoreFOV(); return end
	if(self:IsCharging() || self:IsBroken()) then return end
	self.m_fovReal = self.Owner:GetFOV()
	self.Owner:SetFOV(30,0.25)
end