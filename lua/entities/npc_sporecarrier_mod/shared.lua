ENT.Base = "npc_creature_base_mod"
ENT.Type = "ai"

ENT.PrintName = "Spore Carrier"
ENT.Category = "Fallout NPCs"

if(CLIENT) then
	local attGlow = {"LClavicle","RClavicle","LForearm","RForearm","LHand","RHand","LThigh","RThigh","LCalf","RCalf","LFoot","RFoot","Head"}
	function ENT:Initialize()
		for _, att in ipairs(attGlow) do
			ParticleEffectAttach("sporecarrier_glow",PATTACH_POINT_FOLLOW,self,self:LookupAttachment(att))
		end
	end
	language.Add("npc_sporecarrier_mod","Spore Carrier")
end

