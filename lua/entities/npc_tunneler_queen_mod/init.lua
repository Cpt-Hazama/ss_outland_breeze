if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("shared.lua")

include('shared.lua')

local _R = debug.getregistry()
_R.NPCFaction.Create("NPC_FACTION_ZOMBIE","npc_tunneler_queen_mod")
ENT.skName = "tunneler_queen"
ENT.UsePoison = true
ENT.CanUseRadiation = false
ENT.GlowEffects = false
ENT.ScaleExp = 2
function ENT:SubInit()
	self:SetSkin(1)
end