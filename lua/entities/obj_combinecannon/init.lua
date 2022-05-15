if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

local MAX_DISTANCE = 35

util.AddNetworkString("combinecannon_mount")
util.AddNetworkString("combinecannon_dismount")
util.AddNetworkString("combinecannon_fire")
util.AddNetworkString("combinecannon_detach")

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
	self:PhysicsInit(SOLID_OBB)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	local min,max = Vector(-18,-2,5),Vector(17,2,17)
	self:SetCollisionBounds(min,max)
	//self:PhysicsInit(SOLID_OBB)
	self:SetSolid(SOLID_OBB)
	local phys = self:GetPhysicsObject()
	if(phys:IsValid()) then
		phys:EnableMotion(false)
	end
	
	self:SetUseType(SIMPLE_USE)
	self:SetNetworkedBool("mounted",false)
	self:SetNetworkedBool("broken",false)
	self.m_tNextMount = CurTime()
	self.m_tNextFire = CurTime()
	self:SharedInit()
	self:SetAnglesOrigin(self:GetAngles())
	
	self.m_damage = self.m_damage || 100000
	self.m_damageForce = self.m_damageForce || 5000
	self.m_bDisabled = self.m_bDisabled || false
	if(self.m_bDamageNPCs == nil) then self.m_bDamageNPCs = true end
	if(self.m_bDamageActivator == nil) then self.m_bDamageActivator = true end
	self.m_bDamagePlayers = self.m_bDamagePlayers || false
	self.m_bDetachable = self.m_bDetachable || false
	
	local spr = ents.Create("env_sprite")
	spr:SetKeyValue("model","sprites/glow01.vmt")
	spr:SetKeyValue("rendermode","5") 
	spr:SetKeyValue("rendercolor","255 85 50") 
	spr:SetKeyValue("scale","0.05") 
	spr:SetParent(self)
	spr:SetPos(self:GetPos() +self:GetForward() *2.8 +self:GetUp() *16.6 +self:GetRight() *1.28)
	spr:Spawn()
	spr:Activate()
	spr:Fire("hidesprite","",0)
	self.m_entSprite = spr
	self:DeleteOnRemove(spr)
	
	if(self.m_attachPoint) then
		timer.Simple(0.01,function()
			if(self:IsValid()) then
				local ent = ents.FindByName(self.m_attachPoint)[1]
				self.m_attachPoint = nil
				if(IsValid(ent)) then
					ent:Attach(self)
				end
			end
		end)
	end
end

function ENT:SetAnglesOrigin(ang)
	self:SetNetworkedAngle("angorigin",ang)
end

function ENT:SetDetachable(b)
	self.m_bDetachable = b
	if(b) then self:DetachableMessage() end
end

function ENT:GetDetachable() return self.m_bDetachable end

function ENT:DetachableMessage()
	if(!self:IsMounted()) then return end
	local activator = self:GetActivator()
	if(!IsValid(activator)) then return end
	SS_Map.DrawHUDTip("cc_detach","RELOAD","DETACH",activator)
end

function ENT:Detach()
	if(!self:GetDetachable()) then return end
	if(!self:IsMounted() || self:IsCharging()) then return end
	local pl = self:GetActivator()
	if(!IsValid(pl)) then return end
	local wep = pl:Give("weapon_combinecannon")
	if(IsValid(wep)) then
		if(IsValid(self.m_entAttachedTo)) then self.m_entAttachedTo:OnDetach() end
		wep:SetName(self:GetName())
		wep:SetDamage(self:GetDamage())
		wep:SetDamageForce(self:GetDamageForce())
		wep:SetDamagePlayers(self:GetDamagePlayers())
		wep:SetDamageActivator(self:GetDamageActivator())
		wep:SetDamageNPCs(self:GetDamageNPCs())
		wep:SetVital(self:GetVital())
		if(self:IsBroken()) then wep:BreakDown() end
		if(self.m_tReinstate) then wep:Reinstate(self.m_tReinstate -CurTime()) end
		wep.m_bDetachable = self:GetDetachable()
		pl:SelectWeapon("weapon_combinecannon")
		self:OnDetached(pl,wep)
		if(self.Outputs) then
			wep.Outputs = wep.Outputs || {}
			for name,outputs in pairs(self.Outputs) do
				wep.Outputs[name] = wep.Outputs[name] || {}
				table.Add(wep.Outputs[name],outputs)
			end
		end
		self:Remove()
	end
end

function ENT:OnDetached(pl,wep)
end

function ENT:GetDisabled() return self.m_bDisabled end
function ENT:SetDisabled(b)
	if(b) then self:Dismount() end
	self.m_bDisabled = b
end

function ENT:SpawnFunction(pl,tr)
	if(!tr.Hit) then return end
	local pos = tr.HitPos
	local ang = pl:GetAimVector():Angle()
	ang.p = 0
	ang.r = 0
	local ent = ents.Create("obj_combinecannon")
	ent:SetPos(pos +Vector(0,0,40))
	ent:SetAngles(ang)
	ent:SetKeyValue("startdisabled","0")
	ent:SetKeyValue("health","100")
	ent:SetKeyValue("spawnflags","8")
	ent:Spawn()
	ent:Activate()
	ent:StoreOutput("onfired","!self,break,,0,-1")
	ent:StoreOutput("onbreak","!self,delayedreinstate,8,0,-1")
	return ent
end

function ENT:InRange(pl)
	local pos = self:GetPos()
	return pl:NearestPoint(pos):Distance(pos) <= MAX_DISTANCE
end

function ENT:Attack()
	self:SetAngles(self:GetAngles() -Angle(4,0,0))
	self.m_tNextFire = CurTime() +0.25
	//self:ResetSequence(self:LookupSequence("fire"))
	self:SetPlaybackRate(1)
	self:EmitSound("NPC_FloorTurret.ShotSounds",75,100)
	local src = self:GetShootPos()
	self:FireBullets({
		Attacker = self:GetActivator(),
		Num = 1,
		Src = src,
		Dir = self:GetForward(),
		Spread = Vector(0.01,0.01,0),
		Tracer = 1,
		TracerName = "AR2Tracer",
		Force = 10,
		Damage = 5
	})
	local ed = EffectData()
	ed:SetStart(src)
	ed:SetOrigin(src)
	ed:SetScale(1)
	ed:SetAngles(self:GetAngles())
	ed:SetNormal(self:GetForward())
	util.Effect("MuzzleEffect",ed)
end

net.Receive("combinecannon_detach",function(len,pl)
	if(!IsValid(pl.m_entCombineCannon)) then return end
	pl.m_entCombineCannon:Detach()
end)

net.Receive("combinecannon_fire",function(len,pl)
	if(!IsValid(pl.m_entCombineCannon)) then return end
	pl.m_entCombineCannon.m_bFire = net.ReadUInt(1) == 1
end)

function ENT:OnCannonFired()
end

function ENT:Impact()
	self:OnCannonFired()
	self:TriggerOutput("onfired",self:GetActivator())
	self:StopParticles()
	local att = self:LookupAttachment("muzzle")
	ParticleEffectAttach("striderbuster_break_lightning",PATTACH_POINT_FOLLOW,self,att)
	ParticleEffectAttach("striderbuster_attach_flash",PATTACH_POINT_FOLLOW,self,att)
	ParticleEffectAttach("hunter_muzzle_flash",PATTACH_POINT_FOLLOW,self,att)
	ParticleEffectAttach("hunter_muzzle_flash_b",PATTACH_POINT_FOLLOW,self,att)
	local pos = self:GetShootPos()
	local dir = self:GetForward()
	local tr = self:CreateTrace()
	util.ParticleTracerEx("Weapon_Combine_Ion_Cannon",pos -self:GetRight() *4.111 +self:GetUp() *0.8,tr.HitPos,self:EntIndex(),1,att)
	ParticleEffect("Weapon_Combine_Ion_Cannon_Explosion",tr.HitPos,tr.Normal:Angle())
	ParticleEffectAttach("warp_shield_impact",PATTACH_POINT_FOLLOW,self,att)
	sound.Play("NPC_Combine_Cannon.FireBullet",tr.HitPos,100,100,1)
	
	local attacker = self:GetActivator()
	if(!IsValid(attacker)) then attacker = self end
	local distMax = 250
	for _,ent in ipairs(ents.FindInSphere(tr.HitPos,distMax)) do
		if(ent != self && ((self:GetDamageNPCs() && ent:IsNPC()) || ((self:GetDamagePlayers() || (ent == attacker && self:GetDamageActivator())) && ent:IsPlayer()) || ent:GetPhysicsObject():IsValid())) then
			local am = self:GetDamage()
			local dist = ent:NearestPoint(tr.HitPos):Distance(tr.HitPos)
			am = am *(1 -(dist /distMax))
			local dmg = DamageInfo()
			dmg:SetDamage(am)
			dmg:SetDamageForce(dir *self:GetDamageForce())
			dmg:SetDamageType(DMG_DISSOLVE)
			dmg:SetInflictor(self)
			dmg:SetAttacker(attacker)
			ent:TakeDamageInfo(dmg)
			self:OnHit(ent)
		end
	end
	util.ScreenShake(tr.HitPos,1000,5000,2,distMax *2)
end

function ENT:OnHit(ent)
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
	elseif(name == "enable") then
		self:SetDisabled(false)
		return true
	elseif(name == "disable") then
		self:SetDisabled(true)
		return true
	elseif(name == "dismount") then
		self:Dismount()
		return true
	elseif(name == "sethealth") then
		self:SetHealth(tonumber(data))
		return true
	elseif(name == "firecannon") then
		self:ChargeFire()
		return true
	elseif(name == "setdetachable") then
		self:SetDetachable(true)
		return true
	elseif(name == "setundetachable") then
		self:SetDetachable(false)
		return true
	elseif(name == "attachto") then
		local ent = ents.FindByName(data)[1]
		if(IsValid(ent)) then
			ent:Attach(self)
		end
		return true
	end
end

function ENT:OnTakeDamage(dmg)
	if(self:IsBroken()) then return end
	local am = dmg:GetDamage()
	local hp = self:Health()
	if(hp == 0) then return end
	hp = hp -am
	self:SetHealth(math.max(hp,0))
	if(hp <= 0) then
		self:Fire("break","",0)
	end
end

local SF_DAMAGE_NPCS = 1
local SF_DAMAGE_PLAYERS = 2
local SF_DAMAGE_ACTIVATOR = 4
local SF_DETACHABLE = 8
function ENT:KeyValue(key,val)
	key = string.lower(key)
	if(key == "damage") then self:SetDamage(tonumber(val))
	elseif(key == "damageforce") then self:SetDamageForce(tonumber(val))
	elseif(key == "startdisabled") then self:SetDisabled(tonumber(val) != 0)
	elseif(key == "health") then self:SetHealth(tonumber(val))
	elseif(key == "attachment") then self.m_attachPoint = val
	elseif(key == "spawnflags") then
		local sf = tonumber(val)
		if(bit.band(sf,SF_DAMAGE_NPCS) == SF_DAMAGE_NPCS) then self:SetDamageNPCs(true) end
		if(bit.band(sf,SF_DAMAGE_PLAYERS) == SF_DAMAGE_PLAYERS) then self:SetDamagePlayers(true) end
		if(bit.band(sf,SF_DAMAGE_ACTIVATOR) == SF_DAMAGE_ACTIVATOR) then self:SetDamageActivator(true) end
		if(bit.band(sf,SF_DETACHABLE) == SF_DETACHABLE) then self:SetDetachable(true) end
	end
end

function ENT:ChargeFire()
	if(self:IsBroken()) then return end
	if(self:IsCharging()) then return end
	//self:EmitSound("NPC_Strider.Charge",75,100)
	self:SetNetworkedBool("charging",true)
	self:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,40)
	self:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,40)
	self:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,50)
	self:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,60)
	self:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,70)
	self:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,80)
	local att = self:LookupAttachment("muzzle")
	ParticleEffectAttach("combinecannon_charge",PATTACH_POINT_FOLLOW,self,att)
	ParticleEffectAttach("cingularity_start",PATTACH_POINT_FOLLOW,self,att)
	timer.Simple(2,function() ParticleEffectAttach("cingularity",PATTACH_POINT_FOLLOW,self,att) end)
	self.m_tNextFire = CurTime() +5
	timer.Simple(4.5,function()
		if(self:IsValid()) then
			self:Impact()
			self:SetAngles(self:GetAngles() -Angle(32,0,0))
			self:EmitSound("NPC_Strider.Shoot",75,100)
			self:SetNetworkedBool("charging",false)
		end
	end)
end

function ENT:BreakDown()
	if(self:IsBroken()) then return end
	self:Dismount()
	self:SetNetworkedBool("broken",true)
	self:EmitSound("k_lab.teleport_discharge",75,100)
	local ang = self:GetAngles()
	local ent = ents.Create("env_smokestack")
	ent:SetKeyValue("BaseSpread","0.1")
	ent:SetKeyValue("endsize","5")
	ent:SetKeyValue("InitialState","1")
	ent:SetKeyValue("JetLength","38")
	ent:SetKeyValue("Rate","10")
	ent:SetKeyValue("renderamt","255")
	ent:SetKeyValue("rendercolor","15 15 15")
	ent:SetKeyValue("roll","0")
	ent:SetKeyValue("SmokeMaterial","particle/SmokeStack.vmt")
	ent:SetKeyValue("Speed","30")
	ent:SetKeyValue("SpreadSpeed","2")
	ent:SetKeyValue("WindSpeed","0")
	ent:SetKeyValue("startsize","2")
	ent:SetKeyValue("twist","0")
	ent:SetKeyValue("WindAngle","0")
	ent:SetPos(self:GetPos() +ang:Up() *10 -ang:Forward() *5)
	ent:Spawn()
	ent:Activate()
	ent:SetParent(self)
	self.m_entSmoke = ent
	self:DeleteOnRemove(ent)
	self:TriggerOutput("onbreak",self:GetActivator())
end

function ENT:Reinstate(t)
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
	self:SetNetworkedBool("broken",false)
	if(IsValid(self.m_entSmoke)) then
		self.m_entSmoke:Fire("turnoff","",0)
		self.m_entSmoke:Fire("kill","",1.5)
		self.m_entSmoke = nil
	end
	self:EmitSound("d3_citadel.weapon_zapper_charge_node",75,100)
end

function ENT:Update()
	local pl = self:GetActivator()
	if(!self:InRange(pl)) then self:Dismount(); return end
	if(self.m_bActivatorKeyDownLast) then if(!pl:KeyDown(IN_USE)) then self.m_bActivatorKeyDownLast = false end // KeyPressed doesn't seem to work right, so we'll do this instead
	elseif(pl:KeyDown(IN_USE)) then self:Dismount(); return end
	if(self.m_bFire && CurTime() >= self.m_tNextFire) then
		self:ChargeFire()
	end
end

function ENT:Mount(pl)
	if(self:GetDisabled()) then return end
	if(self:IsMounted()) then return end
	if(self:IsBroken()) then
		self:EmitSound("Buttons.snd42",75,100)
		return
	end
	if(CurTime() < self.m_tNextMount) then return end
	if(IsValid(pl.m_entCombineCannon)) then pl.m_entCombineCannon:Dismount() end
	pl.m_entCombineCannon = self
	if(IsValid(self.m_entSprite)) then self.m_entSprite:Fire("showsprite","",0) end
	self:EmitSound("NPC_Turret.Deploy",75,100)
	self:SetNetworkedBool("mounted",true)
	self:SetNetworkedEntity("activator",pl)
	self.m_bActivatorKeyDownLast = true
	net.Start("combinecannon_mount")
		net.WriteEntity(self)
	net.Send(pl)
	if(self:GetDetachable()) then self:DetachableMessage() end
	local wep = pl:GetActiveWeapon()
	if(IsValid(wep) && wep.QuickHolster) then wep:QuickHolster() end
end

function ENT:Dismount()
	if(!self:IsMounted()) then return end
	local pl = self:GetActivator()
	pl.m_entCombineCannon = nil
	if(IsValid(self.m_entSprite)) then self.m_entSprite:Fire("hidesprite","",0) end
	net.Start("combinecannon_dismount")
	net.Send(pl)
	self:SetNetworkedBool("mounted",false)
	self:SetNetworkedEntity("activator",NULL)
	self.m_tNextMount = CurTime() +1
	self.m_bActivatorKeyDownLast = false
	local wep = pl:GetActiveWeapon()
	if(IsValid(wep) && wep.QuickDraw) then wep:QuickDraw() end
end

function ENT:Use(activator,caller,useType,val)
	if(self:IsMounted() || !self:InRange(activator)) then return end
	self:Mount(activator)
end

function ENT:OnRemove()
	timer.Remove("ss_cc_reinstate" .. self:EntIndex())
	self:Dismount()
end
