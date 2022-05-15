local ConVars = {}
// QUADRALEX
ConVars["sk_quadralex_health"] = 1500
ConVars["sk_quadralex_dmg_shove"] = 88

// HOPPER
ConVars["sk_hopper_health"] = 150
ConVars["sk_hopper_dmg_slash"] = 12
ConVars["sk_hopper_dmg_spit"] = 16

// LEPERKIN
ConVars["sk_leperkin_health"] = 180
ConVars["sk_leperkin_dmg_slash"] = 15
ConVars["sk_leperkin_dmg_slash_blunt"] = 23
ConVars["sk_leperkin_dmg_spit"] = 19

// COMBINE ASSASSIN
ConVars["sk_fassassin_health"] = 150
ConVars["sk_fassassin_dmg_kick"] = 12
ConVars["sk_fassassin_dmg_bullet"] = 1

// GONOME
ConVars["sk_gonome_health"] = 200
ConVars["sk_gonome_dmg_slash"] = 18
ConVars["sk_gonome_dmg_jump"] = 30
ConVars["sk_gonome_dmg_acid"] = 4
ConVars["sk_gonome_dmg_bite"] = 4

// PITDRONE
ConVars["sk_pitdrone_health"] = 60
ConVars["sk_pitdrone_dmg_slash_both"] = 18
ConVars["sk_pitdrone_dmg_spike"] = 24
ConVars["sk_pitdrone_dmg_slash"] = 8

// TUNNELER
ConVars["sk_tunneler_health"] = 120
ConVars["sk_tunneler_dmg_slash"] = 4
ConVars["sk_tunneler_dmg_slash_power"] = 8

// TUNNELER QUEEN
ConVars["sk_tunneler_queen_health"] = 160
ConVars["sk_tunneler_queen_dmg_slash"] = 6
ConVars["sk_tunneler_queen_dmg_slash_power"] = 10

for k, v in pairs(ConVars) do
	CreateConVar(k, v, {})
end