include('shared.lua')

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE

function SWEP:DrawWorldModel()
	self:DrawModel()
end