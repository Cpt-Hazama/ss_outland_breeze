if(!MAP_IS_OUTLAND_BREEZE || !Swords_Installed) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

function ENT:SpawnFunction(pl,tr)
	if(!tr.Hit) then return end
	local pos = tr.HitPos +tr.HitNormal *5
	local ang = Angle(0,0,90)
	
	local ent = ents.Create("obj_ring")
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent.RingType_RAW = "Life"
	ent:Spawn()
	ent:Activate()
	return ent
end

ENT.Size = 1
local sounds = {
	["RNG_Warrior"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Mage"] = {"rings/ring_mana_equip.wav","rings/ring_mana_unequip.wav"},
	["RNG_Careless"] = {"rings/ring_mana_equip.wav","rings/ring_mana_unequip.wav"},
	["RNG_Disaster"] = {"rings/ring_mana_equip.wav","rings/ring_mana_unequip.wav"},
	["RNG_Reflex"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Power"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Fleet"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Pheonix"] = {"rings/ring_pheonix_equip.wav","rings/ring_pheonix_unequip.wav"},
	["RNG_FlatFoot"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Safety"] = {"rings/ring_regeneration_equip.wav","rings/ring_regeneration_unequip.wav"},
	["RNG_Life"] = {"rings/ring_regeneration_equip.wav","rings/ring_regeneration_unequip.wav"},
	["RNG_Defence"] = {"rings/ring_fire_equip.wav","rings/ring_fire_unequip.wav"},
	["RNG_Elements"] = {"rings/ring_fire_equip.wav","rings/ring_fire_unequip.wav"},
	["RNG_Fear"] = {"rings/ring_strength_equip.wav","rings/ring_strength_unequip.wav"},
	["RNG_Force"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Fortitude"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Recovery"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Persistence"] = {"rings/ring_mana_equip.wav","rings/ring_mana_unequip.wav"},
	["RNG_Tenacity"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Nova"] = {"rings/ring_fire_equip.wav","rings/ring_fire_unequip.wav"},
	["RNG_Eternity"] = {"rings/ring_pheonix_equip.wav","rings/ring_pheonix_unequip.wav"},
	["RNG_Cursed"] = {"rings/ring_strength_equip.wav","rings/ring_strength_unequip.wav"},
	["RNG_Enchanted"] = {"rings/ring_fire_equip.wav","rings/ring_fire_unequip.wav"},
	["RNG_Tranquility"] = {"rings/ring_pheonix_equip.wav","rings/ring_pheonix_unequip.wav"},
	["RNG_Quiver"] = {"rings/ring_equip.wav","rings/ring_unequip.wav"},
	["RNG_Malice"] = {"rings/ring_regeneration_equip.wav","rings/ring_regeneration_unequip.wav"}
}

util.AddNetworkString("ss_ring_msg")
util.AddNetworkString("ss_ring_blink")
function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self:SetUseType(SIMPLE_USE)
	//self:AddEffects(EF_ITEM_BLINK)
	local bounds = Vector(self.Size,self.Size,self.Size)
	self:PhysicsInitBox(-bounds,bounds)
	self:SetCollisionBounds(-bounds,bounds)
	self.SOUND:Stop()
	
	self.m_tNextBlink = CurTime() +math.Rand(10,25)
end

function ENT:Think()
	if(CurTime() >= self.m_tNextBlink) then
		self.m_tNextBlink = CurTime() +math.Rand(10,25)
		if(math.Rand(0,1) <= 0.8) then self:Blink() end
	end
end

function ENT:Blink()
	net.Start("ss_ring_blink")
		net.WriteEntity(self)
	net.Broadcast()
end

function ENT:HUDMessage(msg,pl)
	net.Start("ss_ring_msg")
		net.WriteString(msg)
	net.Send(pl)
end

local meta = FindMetaTable("Player")
local SaveRings = meta.SaveRings
local HasRing = meta.HasRing
local SetHasRing = meta.SetHasRing
local EquippedRings = meta.EquippedRings
local bIgnoreTempRings
local bForceEquip
local file_Write = file.Write
file.Write = function(...)
	if(bForceEquip) then return end // Don't save temporarily equipped rings
	return file_Write(...)
end
function meta:HasRing(...)
	if(bIgnoreTempRings && self.m_tRingsTemp) then
		local ring = ...
		if(self.m_tRingsTemp[ring]) then return false end // Don't save temporary rings from this map; Allow us to pick regular rings if we only have a temporary one
	end
	return HasRing(self,...)
end
function meta:EquippedRings(...)
	local r = EquippedRings(self,...)
	if(!self.m_tRingsTemp) then return r end
	for ring,b in pairs(self.m_tRingsTemp) do
		if(b) then r = r -1 end // Don't count temporary rings
	end
	return r
end
function meta:SaveRings(...)
	bIgnoreTempRings = true
	local b,r = pcall(SaveRings,self,...)
	bIgnoreTempRings = false
	if(!b) then Error(r); return end
	return r
end
function meta:SetHasRing(...)
	if(bIgnoreTempRings) then
		if(self.m_tRingsTemp) then
			local ring = select(1,...)
			self.m_tRingsTemp[ring] = false // Turn temporary ring into static ring
		end
	end
	return SetHasRing(self,...)
end
hook.Add("Initialize","tmpringotstatic",function()
	local data = scripted_ents.GetList()["magic_ring"]
	if(!data) then return end
	data = data.t
	if(!data) then return end
	local Use = data.Use
	data.Use = function(...)
		bIgnoreTempRings = true
		local b,r = pcall(Use,...)
		bIgnoreTempRings = false
		if(!b) then Error(r); return end
		return r
	end
end)

function ENT:Use(activator)
	if(activator:RingEquipped(self.RingType)) then
		self:HUDMessage("You already have the " .. self.RingName .. ".",activator)
		return
	end
	self:HUDMessage("You picked up the " .. self.RingName,activator)
	activator.m_tRingsTemp = activator.m_tRingsTemp || {}
	activator.m_tRingsTemp[self.RingType] = true
	activator:SetHasRing(self.RingType,1)
	bForceEquip = true
	local b,r = pcall(activator.SetRingEquipped,activator,self.RingType,true)
	bForceEquip = false
	local snd = sounds[self.RingType] || sounds["RNG_Warrior"]
	activator:EmitSound(snd[1],75,100)
	self:Remove()
end