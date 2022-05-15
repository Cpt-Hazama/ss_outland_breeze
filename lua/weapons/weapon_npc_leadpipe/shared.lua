SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.HoldType = "pistol"

SWEP.Category		= "Sin Episodes: Emergence"

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/sin/weapons/w_leadpipe.mdl"
SWEP.WorldModel		= "models/sin/weapons/w_leadpipe.mdl"
SWEP.AnimPrefix		= "python"

local tbActs = {
	[ACT_IDLE] = ACT_IDLE_ANGRY,
	[ACT_WALK] = ACT_RUN_RELAXED,
	[ACT_RUN] = ACT_RUN_RELAXED,
	[ACT_MELEE_ATTACK1] = ACT_MELEE_ATTACK2
}
function SWEP:TranslateActivity(act)
	return tbActs[act] || act
end