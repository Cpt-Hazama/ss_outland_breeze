include('shared.lua')

function ENT:Draw()
	if(self:GetNetworkedBool("hasattached")) then return end
	local wep = LocalPlayer():GetActiveWeapon()
	if(IsValid(wep) && wep:GetClass() == "weapon_combinecannon") then
		local dist = LocalPlayer():GetPos():Distance(self:GetPos())
		if(dist <= 80) then SS_Map.DrawHUDTip("cc_attach","USE","ATTACH") end
		local a = math.max(1 -dist /200,0)
		render.SetBlend(a)
		self:DrawModel()
		render.SetBlend(1)
	end
end

function ENT:Initialize()
end

function ENT:OnRemove()
end