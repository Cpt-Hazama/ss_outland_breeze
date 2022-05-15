local mat = Material("effects/shadow_glow.vmt")
local matBuff = Material("effects/guardian_shield.vmt")
net.Receive("ss_init_shadowguardian",function(len)
	local ent = net.ReadEntity()
	if(!ent:IsValid()) then return end
	function ent:RenderOverride()
		local tmCur = UnPredictedCurTime()

		local ent = self
		local ragdoll = self:GetNetworkedEntity("ragdoll")
		if(ragdoll:IsValid()) then ent = ragdoll end
		local a
		local d = 4
		if(!self.m_bShadowBuff) then
			a = 0.5
			render.SetColorModulation(0.5,0.5,0.5)
		else
			a = 1
			render.SetColorModulation(0.15,0.15,0.15)
		end
		local posEye = EyePos()
		cam.Start3D(posEye,EyeAngles())
			self:DrawModel()
		cam.End3D()
		if(self.m_bShadowBuff) then
			render.SetColorModulation(1,1,1)
			cam.Start3D(posEye,EyeAngles(),90)
				render.SetBlend(1)
				render.MaterialOverride(matBuff)
					self:DrawModel()
				render.MaterialOverride(0)
				render.SetBlend(1)
			cam.End3D()
		end
		
		render.SetColorModulation(1,0,0)
		render.SetBlend(((math.sin(CurTime() *2) +1) *0.5) *a)
		render.MaterialOverride(mat)
		cam.Start3D(posEye -ent:GetForward() *d +ent:GetRight() *d,EyeAngles())
			ent:DrawModel()
		cam.End3D()
		render.SetColorModulation(1,0.2,0.2)
		cam.Start3D(posEye +ent:GetForward() *d -ent:GetRight() *d,EyeAngles())
			ent:DrawModel()
		cam.End3D()
		if(self.m_bShadowBuff) then
			cam.Start3D(posEye -ent:GetUp() *d +ent:GetRight() *d,EyeAngles())
				ent:DrawModel()
			cam.End3D()
		end
		render.MaterialOverride(0)
		render.SetBlend(1)
	end
end)