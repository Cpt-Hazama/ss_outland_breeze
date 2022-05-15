if(!MAP_IS_OUTLAND_BREEZE) then return end
ENT.Type 			= "point"
ENT.Base 			= "base_point"

AccessorFunc(ENT,"m_class","NPCClass",FORCE_STRING)
AccessorFunc(ENT,"m_squad","Squad",FORCE_STRING)
AccessorFunc(ENT,"m_equipment","NPCEquipment",FORCE_STRING)
AccessorFunc(ENT,"m_delay","SpawnDelay",FORCE_NUMBER)
AccessorFunc(ENT,"m_max","MaxNPCs",FORCE_NUMBER)
AccessorFunc(ENT,"m_total","TotalNPCs",FORCE_NUMBER)
AccessorFunc(ENT,"m_bStartOn","StartOn",FORCE_BOOL)
AccessorFunc(ENT,"m_bDeleteOnRemove","DeleteOnRemove",FORCE_BOOL)
AccessorFunc(ENT,"m_bEnabled","Enabled",FORCE_BOOL)
AccessorFunc(ENT,"m_bPatrolWalk","PatrolWalk",FORCE_BOOL)
AccessorFunc(ENT,"m_patrolType","PatrolType",FORCE_NUMBER)
AccessorFunc(ENT,"m_bStrict","StrictMovement",FORCE_BOOL)
AccessorFunc(ENT,"m_spawnflags","NPCSpawnflags",FORCE_NUMBER)
AccessorFunc(ENT,"m_bBurrowed","NPCBurrowed",FORCE_BOOL)
AccessorFunc(ENT,"m_tbKeyValues","NPCKeyValues")
AccessorFunc(ENT,"m_proficiency","NPCProficiency",FORCE_NUMBER)
AccessorFunc(ENT,"m_tbNPCData","NPCData")
function ENT:Initialize()
	self:SetNotSolid(true)
	self:DrawShadow(false)
	
	self:SetEnabled(false)
	self.m_nextSpawn = CurTime() +self:GetSpawnDelay()
	self.m_tbNPCs = {}
	self.m_tbPatrolPoints = self.m_tbPatrolPoints || {}
	self.m_tbRelationships = self.m_tbRelationships || {}
	if self:GetStartOn() then self:SetEnabled(true) end
	if(self.m_bShowEffects == nil) then self:ShowEffects(true) end
	self.m_tbClients = {}
	self.m_tbNPCData = self.m_tbNPCData || {}
	local idx = self:EntIndex()
	hook.Add("OnEntityCreated","npcspawner_updaterelationships" .. idx,function(ent)
		if(!self:IsValid()) then hook.Remove("OnEntityCreated","npcspawner_updaterelationships" .. idx)
		elseif(IsValid(ent) && (ent:IsNPC() || ent:IsPlayer())) then
			local class = self:GetNPCClass()
			local classTgt = ent.ClassName || ent:GetClass()
			local disp = self.m_tbRelationships[classTgt]
			if(disp) then
				if(classTgt != class || !table.HasValue(self.m_tbNPCs,ent)) then
					for _,npc in ipairs(self.m_tbNPCs) do
						if(npc:IsValid()) then
							npc:AddEntityRelationship(ent,disp)
							if(ent:IsNPC()) then ent:AddEntityRelationship(npc,disp) end
						end
					end
				end
			end
		end
	end)
end

function ENT:GetSpawnedNPCs() return self.m_tbNPCs end

function ENT:GetNPCData() return self.m_tbNPCData end

function ENT:ShowEffects(b)
	self.m_bShowEffects = b
	if(!b) then
		if(IsValid(self.m_entEffect)) then self.m_entEffect:Remove() end
		self.m_entEffect = nil
		return
	end
	if(IsValid(self.m_entEffect)) then return end
	local e = ents.Create("env_effectscript")
	e:SetPos(self:GetPos())
	e:SetParent(self)
	e:SetModel("models/Effects/teleporttrail_Alyx.mdl")
	e:SetKeyValue("scriptfile","scripts/effects/testeffect.txt")
	e:Spawn()
	e:Activate()
	e:Fire("SetSequence","teleport",0)
	self:DeleteOnRemove(e)
	self.m_nextEffect = CurTime() +8
	self.m_entEffect = e
end

function ENT:AddPatrolPoint(vec)
	self.m_tbPatrolPoints = self.m_tbPatrolPoints || {}
	local ent = ents.Create("obj_patrolpoint")
	ent:SetPos(vec)
	ent:SetWalk(self:GetPatrolWalk())
	ent:SetType(self:GetPatrolType())
	ent:SetStrictMovement(self:GetStrictMovement())
	ent:Spawn()
	ent:Activate()
	local ptype = self:GetPatrolType()
	if ptype == 3 && self.m_tbPatrolPoints[1] then ent:SetNextPatrolPoint(self.m_tbPatrolPoints[1])
	elseif ptype == 2 && #self.m_tbPatrolPoints > 0 then ent:SetLastPatrolPoint(self.m_tbPatrolPoints[#self.m_tbPatrolPoints]) end
	if self.m_tbPatrolPoints[#self.m_tbPatrolPoints] then self.m_tbPatrolPoints[#self.m_tbPatrolPoints]:SetNextPatrolPoint(ent) end
	table.insert(self.m_tbPatrolPoints, ent)
	
	self:DeleteOnRemove(ent)
end

function ENT:SetEntityOwner(ent)
	self.entOwner = ent
end

function ENT:SpawnNPC()
	for i = #self.m_tbNPCs,1,-1 do
		local ent = self.m_tbNPCs[i]
		if(!ent:IsValid() || ent:Health() < 0) then table.remove(self.m_tbNPCs,i) end
	end
	if(#self.m_tbNPCs >= self:GetMaxNPCs()) then return end
	if(self.m_obbMaxNPC) then
		for _,ent in ipairs(ents.FindInBox(self:LocalToWorld(self.m_obbMinNPC) +self:GetUp() *25,self:LocalToWorld(self.m_obbMaxNPC) +self:GetUp() *25)) do
			if(ent:IsValid() && (ent:GetPhysicsObject():IsValid() || ent:IsNPC() || ent:IsPlayer()) && !ent:IsWeapon()) then return end
		end
	end
	if(self.m_bShowEffects) then self:EmitSound("beams/beamstart5.wav",75,100) end
	local class = self:GetNPCClass()
	local npc = ents.Create(class)
	if(!npc:IsValid()) then ErrorNoHalt("Warning: Invalid npc class '" .. class .. "' for NPC Spawner! Removing..."); self:Remove(); return end
	npc:SetPos(self:GetPos() +self:GetUp() *25)
	npc:SetAngles(Angle(0,self:GetAngles().y,0))
	local equip = self:GetNPCEquipment()
	local spawnflags = self:GetNPCSpawnflags()
	local burrowed = self:GetNPCBurrowed()
	if(equip) then npc:SetKeyValue("additionalequipment",equip) end
	local data = self:GetNPCData()
	local flags = spawnflags || 0
	if(data.SpawnFlags) then flags = bit.bor(flags,data.SpawnFlags) end
	npc:SetKeyValue("spawnflags",flags)
	if(burrowed) then npc:SetKeyValue("startburrowed","1") end
	if(data.KeyValues) then
		for key,val in pairs(data.KeyValues) do
			npc:SetKeyValue(key,val)
		end
	end
	local keyvalues = self:GetNPCKeyValues()
	if(keyvalues) then
		for key,val in pairs(keyvalues) do npc:SetKeyValue(key,val) end
	end
	self:OnSpawnNPC(npc)
	npc:Spawn()
	npc:Activate()
	if(data.Model) then npc:SetModel(data.Model) end
	if(data.Skin) then npc:SetSkin(data.Skin) end
	local proficiency = self:GetNPCProficiency()
	if(proficiency) then
		if(proficiency == 5) then npc:SetCurrentWeaponProficiency(math.random(0,4))
		elseif(proficiency != 6) then npc:SetCurrentWeaponProficiency(proficiency) end
	end
	if(IsValid(self.entOwner)) then cleanup.Add(self.entOwner,"npcs",npc) end
	if(burrowed) then npc:Fire("unburrow","",0) end
	if(!self.m_obbMaxNPC) then
		self.m_obbMinNPC = npc:OBBMins()
		self.m_obbMaxNPC = npc:OBBMaxs()
	end
	local squad = self:GetSquad()
	if(squad) then npc:Fire("setsquad",squad,0) end
	local tbRel = self.m_tbRelationships
	for _,ent in ipairs(ents.GetAll()) do
		if(ent:IsNPC() || ent:IsPlayer()) then
			local classTgt = ent:GetClass()
			if(tbRel[classTgt]) then
				if(classTgt != class || !table.HasValue(self.m_tbNPCs,ent)) then
					npc:AddEntityRelationship(ent,tbRel[classTgt],100)
					if(ent:IsNPC()) then ent:AddEntityRelationship(npc,tbRel[classTgt],100) end
				end
			end
		end
	end
	for _,ent in ipairs(self.m_tbNPCs) do
		if(ent:IsValid()) then
			npc:AddEntityRelationship(ent,D_LI,100)
			ent:AddEntityRelationship(npc,D_LI,100)
		end
	end
	table.insert(self.m_tbNPCs,npc)
	if(self:GetDeleteOnRemove()) then self:DeleteOnRemove(npc) end
	if(self.m_tbPatrolPoints[1]) then
		self.m_tbPatrolPoints[1]:AddNPC(npc)
	end
	self:OnSpawnedNPC(npc)
	local total = self:GetTotalNPCs()
	if(total > 0) then
		total = total -1
		self:SetTotalNPCs(total)
		if(total == 0) then
			for _,npc in ipairs(self.m_tbNPCs) do
				if(npc:IsValid()) then self:DontDeleteOnRemove(npc) end
			end
			self:Remove()
			return
		end
	end
end

function ENT:OnSpawnNPC(npc)
end

function ENT:OnSpawnedNPC(npc)
end

function ENT:SetDisposition(class,disp)
	self.m_tbRelationships = self.m_tbRelationships || {}
	self.m_tbRelationships[class] = disp
end

function ENT:Think()
	if(IsValid(self.m_entEffect) && CurTime() > self.m_nextEffect) then self.m_entEffect:Fire("SetSequence","teleport",0); self.m_nextEffect = CurTime() +8 end
	if(!self:GetEnabled()) then return end
	if(CurTime() >= self.m_nextSpawn) then
		self:SpawnNPC()
		self.m_nextSpawn = CurTime() +self:GetSpawnDelay()
	end
end

function ENT:AcceptInput(cvar,activator,caller) end

function ENT:OnRemove()
	hook.Remove("OnEntityCreated","npcspawner_updaterelationships" .. self:EntIndex())
end

local SF_STARTON = 1
local SF_DELETEONREMOVE = 2
local SF_PATROLWALK = 4
local SF_PATROLSTRICT = 8
local SF_STARTBURROWED = 16
local SF_SHOWEFFECTS = 32
function ENT:KeyValue(key,val)
	key = string.lower(key)
	if(key == "npcclass") then self:SetNPCClass(val)
	elseif(key == "npcsquad") then self:SetSquad(val)
	elseif(key == "npcequipment") then self:SetNPCEquipment(val)
	elseif(key == "spawndelay") then self:SetSpawnDelay(tonumber(val))
	elseif(key == "maxnpcs") then self:SetMaxNPCs(tonumber(val))
	elseif(key == "totalnpcs") then self:SetTotalNPCs(tonumber(val))
	elseif(key == "patroltype") then self:SetPatrolType(tonumber(val))
	elseif(key == "npcspawnflags") then self:SetNPCSpawnflags(tonumber(val))
	elseif(key == "npckeyvalues") then
		local tKv = string.Explode(";",val)
		local keyvalues = {}
		for _,kv in pairs(tKv) do
			kv = string.Explode(":",kv)
			if(kv[2]) then keyvalues[kv[1]] = kv[2] end
		end
		self:SetNPCKeyValues(keyvalues)
	elseif(key == "npcproficiency") then self:SetNPCProficiency(tonumber(val))
	elseif(key == "spawnflags") then
		local sf = tonumber(val)
		if(bit.band(sf,SF_STARTON) == SF_STARTON) then self:SetStartOn(true) end
		if(bit.band(sf,SF_DELETEONREMOVE) == SF_DELETEONREMOVE) then self:SetDeleteOnRemove(true) end
		if(bit.band(sf,SF_PATROLWALK) == SF_PATROLWALK) then self:SetPatrolWalk(true) end
		if(bit.band(sf,SF_PATROLSTRICT) == SF_PATROLSTRICT) then self:SetStrictMovement(true) end
		if(bit.band(sf,SF_STARTBURROWED) == SF_STARTBURROWED) then self:SetNPCBurrowed(true) end
		self:ShowEffects(bit.band(sf,SF_SHOWEFFECTS) == SF_SHOWEFFECTS)
	end
end

function ENT:AcceptInput(name,caller,activator,data)
	name = string.lower(name)
	if(name == "enable") then
		self:SetEnabled(true)
		return true
	elseif(name == "disable") then
		self:SetEnabled(false)
		return true
	end
end