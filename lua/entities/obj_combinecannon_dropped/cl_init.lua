include('shared.lua')

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
end

function ENT:OnRemove()
end

net.Receive("ss_cc_dropped_break",function(len)
	local ent = net.ReadEntity()
	if(!IsValid(ent)) then return end
	timer.Simple(0.01,function()
		if(IsValid(ent)) then
			local ang = ent:GetAngles()
			local pt = ClientsideModel("models/error.mdl")
			pt:SetNoDraw(true)
			pt:SetPos(ent:GetPos() +ang:Up() *18)
			pt:SetAngles(ang)
			pt:SetParent(ent)
			ent:CallOnRemove("cleanupparticle",function()
				if(IsValid(pt)) then pt:Remove() end
			end)
			ent.m_entParticle = pt
			ParticleEffectAttach("combinecannon_smoke",PATTACH_ABSORIGIN_FOLLOW,pt,0)
		end
	end)
end)

net.Receive("ss_cc_dropped_reinstate",function(len)
	local ent = net.ReadEntity()
	if(!IsValid(ent)) then return end
	if(IsValid(ent.m_entParticle)) then ent.m_entParticle:Remove() end
end)