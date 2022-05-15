if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("shared.lua")

include('shared.lua')

local _R = debug.getregistry()
_R.NPCFaction.Create("NPC_FACTION_ZOMBIE","npc_tunneler_mod")
ENT.sModel = "models/fallout/tunneler.mdl"
ENT.skName = "tunneler"
ENT.CanUseMounds = true
ENT.CanUseRadiation = false
ENT.GlowEffects = false