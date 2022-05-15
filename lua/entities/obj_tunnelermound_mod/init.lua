if(!MAP_IS_OUTLAND_BREEZE) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:SpawnFunction(pl,tr)
	if(!tr.Hit) then return end
	local pos = tr.HitPos
	local ang = tr.HitNormal:Angle()
	ang.p = ang.p +90
	local ent = ents.Create("obj_tunnelermound_mod")
	ent:SetPos(pos +Vector(0,0,0))
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()
	return ent
end

AccessorFunc(ENT,"m_numNpcs","MaxNPCAmount",FORCE_NUMBER)
AccessorFunc(ENT,"m_queenChance","QueenChance",FORCE_NUMBER)
AccessorFunc(ENT,"m_spawnRateMin","MinSpawnRate",FORCE_NUMBER)
AccessorFunc(ENT,"m_spawnRateMax","MaxSpawnRate",FORCE_NUMBER)
AccessorFunc(ENT,"m_totalCount","TotalNPCAmount",FORCE_NUMBER)
AccessorFunc(ENT,"m_triggerRadius","TriggerRadius",FORCE_NUMBER)
AccessorFunc(ENT,"m_squad","Squad",FORCE_STRING)
function ENT:Initialize()
	self:SetModel("models/fallout/clutter/tunnelermound.mdl")
	
	self.m_numNpcs = self.m_numNpcs || 3
	self.m_queenChance = self.m_queenChance || 0.25
	self.m_spawnRateMin = self.m_spawnRateMin || 3
	self.m_spawnRateMax = self.m_spawnRateMax || 8
	self.m_totalCount = self.m_totalCount || 4
	self.m_triggerRadius = self.m_triggerRadius || 800
	self.m_bDisabled = self.m_bDisabled || false
	
	self.m_nextSpawn = 0
	self.m_totalSpawned = 0
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.m_tbNpcs = {}
	self:DrawShadow(false)
end

function ENT:IsDisabled() return self.m_bDisabled end

function ENT:KeyValue(key,value)
	key = string.lower(key)
	if(key == "maxnpcs") then self:SetMaxNPCAmount(tonumber(value))
	elseif(key == "queenchance") then self:SetQueenChance(tonumber(value))
	elseif(key == "spawnratemin") then self:SetMinSpawnRate(tonumber(value))
	elseif(key == "spawnratemax") then self:SetMaxSpawnRate(tonumber(value))
	elseif(key == "totalnpcs") then self:SetTotalNPCAmount(tonumber(value))
	elseif(key == "squad") then self:SetSquad(value)
	elseif(key == "radius") then self:SetTriggerRadius(tonumber(value))
	elseif(key == "startdisabled") then self.m_bDisabled = true end
end

function ENT:FindPlayersInRadius(radius)
	local tbPlayers = {}
	local posSelf = self:GetPos()
	for _,pl in ipairs(player.GetAll()) do
		if(pl:GetPos():Distance(posSelf) <= radius) then
			table.insert(tbPlayers,pl)
		end
	end
	return tbPlayers
end

function ENT:AcceptInput(name,activator,caller,data)
	name = string.lower(name)
	if(name == "enable") then
		self.m_bDisabled = false
		return true
	elseif(name == "disable") then
		self.m_bDisabled = true
		return true
	end
end

function ENT:SpawnTunneler(tEnemies)
	local squad = self:GetSquad()
	self.m_nextSpawn = CurTime() +math.Rand(self:GetMinSpawnRate(),self:GetMaxSpawnRate())
	local bQueen = math.Rand(0,1) <= self:GetQueenChance()
	local pos = self:GetPos()
	pos.z = pos.z +self:OBBMaxs().z +20
	local ent = ents.Create(bQueen && "npc_tunneler_queen_mod" || "npc_tunneler_mod")
	ent:SetPos(pos)
	ent:SetAngles(Angle(0,math.random(0,359),0))
	ent:DropToFloor()
	ent:Spawn()
	ent:Activate()
	if(tEnemies) then
		for _,entTgt in ipairs(tEnemies) do
			ent:AddToMemory(entTgt)
		end
	end
	self.m_totalSpawned = self.m_totalSpawned +1
	if(squad && squad != "") then ent:SetSquad(squad) end
	ent:Sleep()
	ent:CallOnInitialized(function()
		ent:Wake()
		ent:PlayActivity(ACT_CLIMB_UP)
	end)
	ent:AddToMemory(tbPlayers)
	table.insert(self.m_tbNpcs,ent)
	self:DeleteOnRemove(ent)
	ent:CallOnDeath(function()
		if(!self:IsValid()) then return end
		for _,entTgt in ipairs(self.m_tbNpcs) do
			if(entTgt == ent) then
				table.remove(self.m_tbNpcs,_)
				break
			end
		end
	end)
end

function ENT:Think()
	if(self:IsDisabled()) then return end
	local numTotal = self:GetTotalNPCAmount()
	if(numTotal > 0 && self.m_totalSpawned < numTotal) then
		local numMax = self:GetMaxNPCAmount()
		local numNPCs = #self.m_tbNpcs
		if(numNPCs < numMax) then
			if(CurTime() >= self.m_nextSpawn) then
				local r = self:GetTriggerRadius()
				if(r == 0) then self:SpawnTunneler()
				else
					local tbPlayers = self:FindPlayersInRadius(r)
					if(#tbPlayers > 0) then
						self:SpawnTunneler(tbPlayers)
					end
				end
			end
		end
	end
	self:NextThink(CurTime() +1)
	return true
end
