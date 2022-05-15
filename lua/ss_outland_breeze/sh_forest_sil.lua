include("sh_concommands.lua")
local function PointInBounds(p,min,max)
	return p.x > min.x && p.x < max.x &&
		p.y > min.y && p.y < max.y &&
		p.z > min.z && p.z < max.z
end

local function CheckPlayerStuck(plA,plB)
	local pos = plA:GetPos()
	local min,max = plA:GetCollisionBounds()
	min = pos +min
	max = pos +max
	local posTgt = plB:GetPos()
	local minTgt,maxTgt = plB:GetCollisionBounds()
	minTgt = posTgt +minTgt
	maxTgt = posTgt +maxTgt
	return PointInBounds(min,minTgt,maxTgt) || PointInBounds(Vector(min.x,min.y,max.z),minTgt,maxTgt) || PointInBounds(Vector(min.x,max.y,min.z),minTgt,maxTgt) || PointInBounds(Vector(max.x,min.y,min.z),minTgt,maxTgt)
		|| PointInBounds(max,minTgt,maxTgt) || PointInBounds(Vector(max.x,max.y,min.z),minTgt,maxTgt) || PointInBounds(Vector(max.x,min.y,max.z),minTgt,maxTgt) || PointInBounds(Vector(min.x,max.y,max.z),minTgt,maxTgt)
end

hook.Add("ShouldCollide","plprevstuck",function(entA,entB)
	if(entA:IsPlayer() && entB:IsPlayer()) then
		if(CheckPlayerStuck(entA,entB) || CheckPlayerStuck(entB,entA)) then
			return false
		end
	end
end)