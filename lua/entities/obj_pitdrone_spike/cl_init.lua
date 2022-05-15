include('shared.lua')

language.Add("obj_pitdrone_spike", "Pit Drone")
function ENT:Draw()     
	self:DrawModel()
end

function ENT:Initialize()
end
 
function ENT:OnRemove()
end
 
function ENT:Think()
 end