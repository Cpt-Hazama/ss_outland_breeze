if(!Swords_Installed) then return end
local tRingTypes = {"Warrior","Mage","Careless","Disaster","Reflex","Power","Fleet","Pheonix","FlatFoot",
"Safety","Life","Defence","Elements","Fear","Force","Fortitude","Recovery","Persistence","Tenacity","Nova",
"Eternity","Cursed","Enchanted","Tranquility","Quiver","Malice"}


SS_Map.SpawnRing = function(pos,ang,type)
	type = type || table.Random(tRingTypes)
	ang = ang || Angle(math.Rand(0,360),math.Rand(0,360),90)
	local ent = ents.Create("obj_ring")
	if(!ent:IsValid()) then return NULL end
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent.RingType_RAW = type
	ent:Spawn()
	ent:Activate()
	timer.Simple(3,function()
		if(ent:IsValid()) then
			local phys = ent:GetPhysicsObject()
			if(phys:IsValid()) then
				phys:EnableMotion(false)
			end
		end
	end)
	return ent
end

local function CreateRingSpawn(...)
	local chance = select(1,...)
	local tPos = {select(2,...)}
	if(math.Rand(0,1) <= chance) then
		local pos = table.Random(tPos)
		return SS_Map.SpawnRing(pos)
	end
	return NULL
end

hook.Add("InitPostEntity","ringspawn",function()
	timer.Simple(0.1,function()
		CreateRingSpawn(0.72,Vector(2381.1,590.098,65.0833),Vector(2265.89,1622.15,-22.3085),Vector(2237.53,2473.22,-27.2027),Vector(2819.48,2337.24,40.8232),Vector(2743.96,2582.05,246.692),Vector(2742.75,2351.47,246.692),Vector(2823,2679,57.5962))
		CreateRingSpawn(0.72,Vector(-1863.66,3966.18,-536.354),Vector(-2279.36,3381,-457.333),Vector(-2906.32,3989.71,-161.308),Vector(-2663.19,3815.53,-161.308),Vector(-3216.08,4300.68,-131.083))
		CreateRingSpawn(0.75,Vector(-2584.65,5306.96,24.4811),Vector(-1296.67,4759.52,-146.038),Vector(-3712.24,7101.07,-144.878),Vector(-2774.78,7378.21,-161.156))
		CreateRingSpawn(0.72,Vector(-1330.62,7859.25,-161.308),Vector(-2544.03,8303.53,-161.308),Vector(-3370.69,9471.82,-141.426),Vector(-2080.62,10044.9,-161.308),Vector(-2460,10605,-30),Vector(-1978.94,10930.3,1.78118))
		CreateRingSpawn(0.75,Vector(-686.295,10460.2,58.6915),Vector(-447.142,8958.7,262.63),Vector(1229.13,8314.52,294.692),Vector(-1528,10986,154),Vector(-1634.6,8730.2,287.254))
		CreateRingSpawn(0.75,Vector(-1959.09,2762.57,-155.308),Vector(-2265.46,784.308,-155.308),Vector(-3566,-968,-102),Vector(-3194,-236,-138),Vector(-3942,-2226,-157.276))
	end)
end)