AddCSLuaFile("ss_outland_breeze/cl_shadowguardian.lua")
AddCSLuaFile("ss_outland_breeze/sh_forest_sil.lua")
AddCSLuaFile("ss_outland_breeze/sh_concommands.lua")
AddCSLuaFile("ss_outland_breeze/cl_hudtips.lua")
AddCSLuaFile("ss_outland_breeze/cl_viewcam.lua")
include("sh_forest_sil.lua")
include("sv_shadowguardian.lua")
include("sv_rings.lua")

util.AddNetworkString("ss_viewcam_end")

util.AddNetworkString("ss_fade")
SS_Map.FadeScreen = function(tFade,tHold,col,flags,rp)
	net.Start("ss_fade")
		net.WriteFloat(tFade)
		net.WriteFloat(tHold)
		net.WriteUInt(col.r,8)
		net.WriteUInt(col.g,8)
		net.WriteUInt(col.b,8)
		net.WriteUInt(col.a,8)
		net.WriteUInt(flags,4)
	if(rp) then net.Send(rp)
	else net.Broadcast() end
end

util.AddNetworkString("ss_curse")
util.AddNetworkString("ss_hudtip")
local hudtipsshown = {}
SS_Map.DrawHUDTip = function(name,key,action,pl)
	hudtipsshown[pl] = hudtipsshown[pl] || {}
	if(hudtipsshown[pl][name]) then return end
	hudtipsshown[name] = true
	net.Start("ss_hudtip")
		net.WriteString(name)
		net.WriteString(key)
		net.WriteString(action)
	net.Send(pl)
end

SS_Map.MakeCavernGuardian = function(name) // Behavior must be set manually via keyvalues
	for _,ent in ipairs(ents.FindByName(name)) do
		ent:SetModel("models/antlion_guarb.mdl")
		ent:SetSkin(1)
		local b = false
		for _,spr in ipairs(ents.FindByClass("env_sprite")) do
			if(spr:GetParent() == ent) then
				spr:Fire("setparentattachment","attach_glow" .. (b && 2 || 1),0)
				b = true
			end
		end
	end
end
if(!Swords_Installed) then
	hook.Add("InitPostEntity","clearssitems",function()
		timer.Simple(0.25,function()
			local tEnts = ents.FindByClass("prop_physics")
			table.Add(tEnts,ents.FindByClass("prop_dynamic"))
			for _,ent in ipairs(tEnts) do
				if(!util.IsValidModel(ent:GetModel())) then
					ent:Remove()
				end
			end
			local ent = ents.FindByName("antlion_corpse")[1]
			if(IsValid(ent)) then ent:Remove() end
		end)
	end)
end

util.AddNetworkString("ss_blackout")
hook.Add("PlayerInitialSpawn","viewcontrol",function(pl)
	pl:SetCustomCollisionCheck(true)
	local ent = ents.FindByName("mapspawn_relay")[1]
	if(IsValid(ent)) then ent:Fire("trigger","",0) end
	net.Start("ss_blackout")
	net.Send(pl)
	pl.m_bBlackout = true
	timer.Simple(0.01,function()
		if(pl:IsValid()) then
			pl:SetPos(Vector(257,-700,76))
			pl:Lock()
			pl:SetMoveType(MOVETYPE_NONE)
		end
	end)
	timer.Create("viewcontrol" .. pl:EntIndex(),13,1,function()
		if(pl:IsValid()) then
			pl.m_bBlackout = false
			pl:SetMoveType(MOVETYPE_WALK)
			pl:UnLock()
			local wep = pl:GetActiveWeapon()
			if(IsValid(wep) && wep.Deploy) then wep:Deploy() end
		end
	end)
end)

hook.Add("PlayerDeath","viewcontrol_cancel",function(pl)
	if(pl.m_bBlackout) then
		pl.m_bBlackout = false
		pl:SetMoveType(MOVETYPE_WALK)
		pl:UnLock()
		//pl:DrawViewModel(true)
		timer.Remove("viewcontrol" .. pl:EntIndex())
	end
end)

local meta = FindMetaTable("NPC")
util.AddNetworkString("shadowmaster_buff_tgt")
function meta:ShadowBuff(tm,fcCallback)
	net.Start("shadowmaster_buff_tgt")
		net.WriteEntity(self)
		net.WriteUInt(1,1)
	net.Broadcast()
	self.m_fcShadowBuffCallback = fcCallback
	local idx = self:EntIndex()
	local hk = "npcshadowbuff" .. idx
	hook.Add("EntityTakeDamage",hk,function(ent,dmginfo)
		if(ent == self) then
			dmginfo:ScaleDamage(0.5)
			local pos = dmginfo:GetDamagePosition()
			if(pos != vector_origin) then
				local ang = Angle(0,0,0)
				ParticleEffect("shadowmaster_buff_impact",pos,ang,ent)
				ParticleEffect("shadowmaster_buff_impact2",pos,ang,ent)
				ParticleEffect("shadowmaster_buff_impactglow",pos,ang,ent)
			end
			local r = math.random(1,11)
			r = string.rep("0",2 -string.len(r)) .. r
			ent:EmitSound("ambient/energy/NewSpark" .. r .. ".wav",75,100)
		elseif(dmginfo:GetAttacker() == self) then
			dmginfo:ScaleDamage(1.25)
		end
	end)
	timer.Create(hk .. "_healthregen",1,-1,function()
		if(IsValid(self)) then
			local hp = self:Health()
			local hpMax = self:GetMaxHealth()
			if(hp < hpMax) then
				self:SetHealth(hp +1)
			end
		end
	end)
	self:CallOnRemove(hk,function()
		self:EndShadowBuff()
	end)
	if(!tm || tm == -1) then return end
	timer.Create(hk,tm,1,function()
		if(IsValid(self)) then
			self:EndShadowBuff(fcCallback)
		end
	end)
end

function meta:EndShadowBuff()
	local idx = self:EntIndex()
	local hk = "npcshadowbuff" .. idx
	hook.Remove("EntityTakeDamage",hk)
	timer.Remove(hk)
	timer.Remove(hk .. "_healthregen")
	net.Start("shadowmaster_buff_tgt")
		net.WriteEntity(self)
		net.WriteUInt(0,1)
	net.Broadcast()
	if(self.m_fcShadowBuffCallback) then self.m_fcShadowBuffCallback() end
	self.m_fcShadowBuffCallback = nil
end