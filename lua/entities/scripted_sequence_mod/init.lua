if(!MAP_IS_OUTLAND_BREEZE) then return end
ENT.Type 			= "point"
ENT.Base 			= "base_point"

local Outputs = {"onbeginsequence","onendsequence"}
function ENT:Initialize()
	self:SetNotSolid(true)
	self:DrawShadow(false)
	
	self.m_tEntities = {}
	for _,ent in ipairs(ents.FindByName(self.m_iszEntity)) do self:AddEntity(ent) end
	
	local idx = self:EntIndex()
	local hk = "scripted_sequence_wait" .. idx
	hook.Add("OnEntityCreated",hk,function(ent)
		timer.Simple(0,function()
			if(self:IsValid() && ent:IsValid()) then
				if(ent:GetName() == self.m_iszEntity) then
					self:AddEntity(ent)
				end
			end
		end)
	end)
	self.m_bPlayed = false
end

function ENT:AddEntity(ent)
	if(!ent.PlaySequence || table.HasValue(self.m_tEntities,ent)) then return end
	table.insert(self.m_tEntities,ent)
	ent:SetAngles(self:GetAngles())
	ent:PlaySequence(self.m_iszIdle,true)
end

function ENT:BeginSequence()
	if(self.m_bPlayed && !self.m_bRepeatable) then return end
	self.m_bPlayed = true
	for _,ent in ipairs(self.m_tEntities) do
		if(ent:IsValid()) then
			self:TriggerOutput("onbeginsequence",ent)
			ent:PlaySequence(self.m_iszPlay,false,function()
				self:TriggerOutput("onendsequence",ent)
			end)
		end
	end
end

function ENT:OnRemove()
	local idx = self:EntIndex()
	local hk = "scripted_sequence_wait" .. idx
	hook.Remove("OnEntityCreated",hk)
end

function ENT:Think()
end

function ENT:KeyValue(key,val)
	key = string.lower(key)
	if(key == "m_iszentity") then self.m_iszEntity = val
	elseif(key == "m_iszidle") then self.m_iszIdle = val
	elseif(key == "m_iszplay") then self.m_iszPlay = val
	elseif(key == "spawnflags") then
		val = tonumber(val)
		if(bit.band(val,4) == 4) then self.m_bRepeatable = true end
	elseif(table.HasValue(Outputs,key)) then self:StoreOutput(key,val) end
end

function ENT:AcceptInput(name,caller,activator,data)
	name = string.lower(name)
	if(name == "beginsequence") then
		self:BeginSequence()
		return true
	end
end