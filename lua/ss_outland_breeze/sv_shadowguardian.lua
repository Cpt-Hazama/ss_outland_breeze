AddCSLuaFile("ss_outland_breeze/cl_shadowguardian.lua")
util.AddNetworkString("ss_init_shadowguardian")
local tEnts = {}
SS_Map.MakeShadowGuardian = function(name)
	local ents = ents.FindByName(name)
	for _,ent in ipairs(ents) do
		ent:ShadowBuff()
		net.Start("ss_init_shadowguardian")
			net.WriteEntity(ent)
		net.Broadcast()
	end
	table.Add(tEnts,ents)
end

hook.Add("PlayerAuthed","shadowguardianplinit",function(pl,steamID,uniqueID)
	for _,ent in ipairs(tEnts) do
		if(ent:IsValid()) then
			net.Start("ss_init_shadowguardian")
				net.WriteEntity(ent)
			net.Send(pl)
		end
	end
end)