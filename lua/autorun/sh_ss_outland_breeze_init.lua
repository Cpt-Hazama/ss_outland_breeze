local map = game.GetMap()
MAP_IS_OUTLAND_BREEZE = string.Left(map,17) == "ss_outland_breeze"
if(!MAP_IS_OUTLAND_BREEZE) then return end
if(!SLVBase) then
	include("slvbase/slvbase.lua")
	if(!SLVBase) then return end
	if(SERVER) then AddCSLuaFile("slvbase/slvbase.lua") end
end
local addon = "SS_Map"
if(SLVBase.AddonInitialized(addon)) then return end
SLVBase.AddDerivedAddon(addon,{})
if(SERVER) then
	Add_NPC_Class("CLASS_RACEX")
	local _R = debug.getregistry()
	_R.NPCFaction.Create("NPC_FACTION_COMBINE","npc_turret_floor","npc_rollermine","npc_combine_s","npc_manhack","npc_clawscanner","npc_helicopter","npc_combinegunship",
	"npc_combine_camera","npc_cscanner","npc_turret_ceiling","npc_strider","npc_stalker","npc_combinedropship","npc_hunter")
	_R.NPCFaction.Create("NPC_FACTION_ZOMBIE","monster_gonome_mod","monster_pitdrone_mod","npc_zombie","npc_fastzombie","npc_poisonzombie","npc_zombine","npc_headcrab","npc_headcrab_fast","npc_headcrab_black","npc_headcrab_poison",
	"npc_leperkin_mod","npc_hopper_mod","npc_tunneler_mod","npc_tunneler_queen_mod","npc_barnacle","npc_zombie_torso","npc_fastzombie_torso")
end

sound.AddSoundOverrides("scripts/soundscapes_ss_outland_breeze_b1.txt")
sound.AddSoundOverrides("scripts/npc_sounds_antlion_episodic.txt")
sound.AddSoundOverrides("scripts/npc_sounds_antlionguard_episodic.txt")
sound.AddSoundOverrides("scripts/npc_sounds_barnacle.txt")
sound.AddSoundOverrides("scripts/npc_sounds_dropship.txt")
sound.AddSoundOverrides("scripts/npc_sounds_env_headcrabcanister.txt")
sound.AddSoundOverrides("scripts/npc_sounds_soldier.txt")
sound.AddSoundOverrides("scripts/npc_sounds_strider.txt")
sound.AddSoundOverrides("scripts/npc_sounds_zombine.txt")
sound.AddSoundOverrides("scripts/npc_sounds_attackheli.txt")
sound.AddSoundOverrides("scripts/npc_sounds_antlion_grub_episodic.txt")
sound.AddSoundOverrides("scripts/npc_sounds_combine_mine.txt")
SS_Map = {}
game.AddParticles("particles/waterfall.pcf")
game.AddParticles("particles/bonfire.pcf")
game.AddParticles("particles/centaur_spit.pcf")
game.AddParticles("particles/antlion_worker.pcf")
game.AddParticles("particles/sword_curse_enemy_large.pcf")
game.AddParticles("particles/antlion_gib_01.pcf")
game.AddParticles("particles/antlion_gib_02.pcf")
game.AddParticles("particles/grub_blood.pcf")
game.AddParticles("particles/shadowmaster_fx.pcf")
game.AddParticles("particles/shadowmaster_buff_impact.pcf")
game.AddParticles("particles/sword_shadowmaster.pcf")

for _,pt in ipairs({
	"Waterfall_Impact_01",
	"Waterfall_Cascade_01",
	"Waterfall_Spray_01",
	"smoke",
	"centaur_spit",
	"sword_curse_enemy_large",
	"shadowmaster_summonshadow",
	"shadowmaster_buff_impact",
	"shadowmaster_buff_impact2",
	"shadowmaster_buff_impactglow"
}) do
	PrecacheParticleSystem(pt)
end

if(SERVER) then
	AddCSLuaFile("autorun/sh_ss_outland_breeze_init.lua")
	AddCSLuaFile("ss_outland_breeze/cl_ss_outland_breeze.lua")
	include("ss_outland_breeze/sv_ss_outland_breeze.lua")
else
	include("ss_outland_breeze/cl_ss_outland_breeze.lua")
end