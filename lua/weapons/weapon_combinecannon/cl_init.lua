include('shared.lua')

language.Add("weapon_combinecannon","Combine Cannon")

SWEP.PrintName = "Combine Cannon"
SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 90
SWEP.ViewModelFlip = false
SWEP.DrawCrosshair = false
SWEP.DrawWeaponInfoBox	= false

SWEP.BounceWeaponIcon = false

local icon = surface.GetTextureID("HUD/weapons/weapon_combinecannon") 
function SWEP:DrawWeaponSelection(x,y,w,h,a)
	surface.SetDrawColor(255,255,255,a)
	surface.SetTexture(icon)
	surface.DrawTexturedRect(x,y,w,h)
end

local tAnim = 0.25
function SWEP:GetViewModelPosition(pos,ang)
	pos = pos -ang:Up() *20 +ang:Right() *5 +ang:Forward() *12
	ang = ang +Angle(0,1,0)
	if(self.m_tBreak || self.m_tReinstate) then
		local tCur = UnPredictedCurTime()
		local tDelta = tCur -(self.m_tBreak || self.m_tReinstate)
		local sc = math.min(tDelta /0.25,1)
		if(self.m_tReinstate) then sc = 1 -sc end
		ang.p = ang.p +sc *40
		pos = pos -ang:Up() *(sc *5)
	end
	if(self.m_tFire) then
		local tCur = UnPredictedCurTime()
		local tDelta = tCur -self.m_tFire
		if(tDelta > (1 /15) *4) then self.m_tFire = nil
		else ang.p = ang.p -((math.sin(tDelta *15) +1) *0.5) *25 end
	end
	return pos,ang
end

function SWEP:DrawHUD()
end

function SWEP:DrawWorldModel()
	//self:DrawModel()
end

function SWEP:GetWorldModelEntity()
	if(!IsValid(self.Owner)) then return NULL end
	return self.Owner.m_combineCannonClModel
end

function SWEP:GetEffectTarget()
	if(self.Owner != LocalPlayer() || hook.Call("ShouldDrawLocalPlayer",LocalPlayer())) then return IsValid(self:GetWorldModelEntity()) && self:GetWorldModelEntity() || self end
	return self.Owner:GetViewModel()
end

function SWEP:GetMuzzlePos()
	local ent = self:GetEffectTarget()
	local attID = ent:LookupAttachment("muzzle")
	return ent:GetAttachment(attID)
end

function SWEP:CreateTrace()
	local att = self:GetMuzzlePos()
	local dir = att.Ang:Forward()
	return util.TraceLine({
		start = att.Pos,
		endpos = att.Pos +dir *10000,
		filter = {self,self.Owner},
		mask = MASK_SHOT
	})
end

net.Receive("ss_cc_break",function(len)
	local wep = net.ReadEntity()
	if(!wep:IsValid() || !IsValid(wep.Owner)) then return end
	timer.Simple(0.01,function()
		if(wep:IsValid()) then
			local ent = wep:GetEffectTarget()
			local ang = ent:GetAngles()
			local pt = ClientsideModel("models/error.mdl")
			pt:SetNoDraw(true)
			pt:SetPos(ent:GetPos() +ang:Up() *18)
			pt:SetAngles(ang)
			pt:SetParent(ent)
			wep:CallOnRemove("cleanupparticle",function()
				if(IsValid(pt)) then pt:Remove() end
			end)
			ent.m_entParticle = pt
			ParticleEffectAttach("combinecannon_smoke",PATTACH_ABSORIGIN_FOLLOW,pt,0)
			wep:EmitSound("k_lab.teleport_discharge",75,100)
			wep.m_tReinstate = nil
			wep.m_tBreak = UnPredictedCurTime()
		end
	end)
end)

net.Receive("ss_cc_reinstate",function(len)
	local wep = net.ReadEntity()
	if(!wep:IsValid() || !IsValid(wep.Owner)) then return end
	timer.Simple(0.01,function()
		if(wep:IsValid()) then
			local ent = wep:GetEffectTarget()
			if(IsValid(ent.m_entParticle)) then ent.m_entParticle:Remove() end
			wep:EmitSound("d3_citadel.weapon_zapper_charge_node",75,100)
			wep.m_tBreak = nil
			wep.m_tReinstate = UnPredictedCurTime()
		end
	end)
end)

local VIEW_MOVE_SCALE = 0.25
local cvPitch = GetConVar("m_pitch")
local cvYaw = GetConVar("m_yaw")
local mat = Material("sprites/redglow1")
local col = Color(255,0,0,255)
net.Receive("ss_cc_deploy",function(len)
	local wep = net.ReadEntity()
	if(!wep:IsValid() || !IsValid(wep.Owner)) then return end
	timer.Simple(0.01,function()
		if(wep:IsValid() && IsValid(wep.Owner)) then
			//wep.Owner:DrawViewModel(false)
			wep:SharedDeploy()
			wep:SetWeaponHoldType("crossbow")
			local attID = wep.Owner:LookupAttachment("anim_attachment_RH")
			local idx = wep.Owner:EntIndex()
			local hk = "ss_cc_drawworldmdl" .. idx
			if(IsValid(wep:GetWorldModelEntity())) then wep:GetWorldModelEntity():Remove() end
			local mdl = ClientsideModel("models/combine_turrets/combine_cannon_gun.mdl")
			wep.Owner.m_combineCannonClModel = mdl
			wep:CallOnRemove(hk,function()
				if(mdl:IsValid()) then mdl:Remove() end
				hook.Remove("Think",hk)
				hook.Remove("HUDPaint",hk)
				hook.Remove("RenderScreenspaceEffects",hk)
			end)
			wep.Owner:CallOnRemove(hk,function()
				if(mdl:IsValid()) then mdl:Remove() end
			end)
			local function UpdatePos()
				local bone = wep.Owner:LookupBone("ValveBiped.Anim_Attachment_RH")
				local pos,ang = wep.Owner:GetBonePosition(bone)
				mdl:SetPos(pos -ang:Up() *6 +ang:Forward() *18 +ang:Right() *1)
				mdl:SetAngles(ang)
			end
			UpdatePos()
			mdl:SetParent(wep.Owner,attID)
			hook.Add("Think",hk,function()
				if(!IsValid(wep.Owner)) then
					if(mdl:IsValid()) then mdl:Remove() end
					hook.Remove("Think",hk)
				else
					mdl:SetNoDraw(wep.Owner == LocalPlayer() && !hook.Call("ShouldDrawLocalPlayer",LocalPlayer()))
					UpdatePos()
				end
			end)
			hook.Add("HUDPaint",hk,function()
				local tr = util.TraceLine(util.GetPlayerTrace(wep.Owner))
				local dist = tr.StartPos:Distance(tr.HitPos)
				local size = math.Clamp((50 /dist) *800,0,50)
				
				local lp = LocalPlayer()
				local trB = util.TraceLine({
					start = lp:EyePos(),
					endpos = tr.HitPos +tr.HitNormal *4,
					filter = lp
				})
				if(!trB.Hit) then
					cam.Start3D(EyePos(),EyeAngles())
						render.SetMaterial(mat)
						render.DrawSprite(tr.HitPos,size,size,col)
					cam.End3D()
				end
			end)
			hook.Add("RenderScreenspaceEffects",hk,function()
				local size = 20
				local ent = wep:GetEffectTarget()
				local pos = ent:GetPos() +ent:GetUp() *16.6 +ent:GetRight() *1.28
				if(wep.Owner != LocalPlayer() || hook.Call("ShouldDrawLocalPlayer",LocalPlayer())) then pos = pos +ent:GetForward() *2.8
				else pos = pos +ent:GetForward() *8 end
				cam.Start3D(EyePos(),EyeAngles())
					render.SetMaterial(mat)
					render.DrawSprite(pos,size,size,col)
				cam.End3D()
			end)
			if(wep.Owner == LocalPlayer()) then
				hook.Add("InputMouseApply",hk,function(cmd,x,y,ang)
					if(!IsValid(wep) && !IsValid(wep.Owner)) then hook.Remove("InputMouseApply",hk)
					else
						local VIEW_MOVE_SCALE = VIEW_MOVE_SCALE
						if(wep:IsCharging()) then VIEW_MOVE_SCALE = VIEW_MOVE_SCALE *0.1 end
						x = x *cvYaw:GetFloat() *-1
						y = y *cvPitch:GetFloat()
						ang.p = ang.p +y *VIEW_MOVE_SCALE
						ang.y = ang.y +x *VIEW_MOVE_SCALE
						cmd:SetViewAngles(ang)
						return true
					end
				end)
			end
		end
	end)
end)

net.Receive("ss_cc_holster",function(len)
	local wep = net.ReadEntity()
	if(!wep:IsValid()) then return end
	if(IsValid(wep:GetWorldModelEntity())) then wep:GetWorldModelEntity():Remove(); wep.Owner.m_combineCannonClModel = nil end
	local idx = wep.Owner:EntIndex()
	local hk = "ss_cc_drawworldmdl" .. idx
	wep:RemoveCallOnRemove(hk)
	wep.Owner:RemoveCallOnRemove(hk)
	hook.Remove("Think",hk)
	hook.Remove("HUDPaint",hk)
	hook.Remove("RenderScreenspaceEffects",hk)
	if(wep.Owner == LocalPlayer()) then hook.Remove("InputMouseApply",hk) end
end)

net.Receive("ss_cc_charge",function(len)
	local wep = net.ReadEntity()
	if(!wep:IsValid()) then return end
	local ent = wep:GetEffectTarget()
	wep:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,40)
	wep:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,40)
	wep:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,50)
	wep:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,60)
	wep:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,70)
	wep:EmitSound("weapons/strider_buster/Strider_Buster_stick1.wav",110,80)
	local att = ent:LookupAttachment("muzzle")
	ParticleEffectAttach("combinecannon_charge",PATTACH_POINT_FOLLOW,ent,att)
	ParticleEffectAttach("cingularity_start",PATTACH_POINT_FOLLOW,ent,att)
	timer.Simple(2,function() ParticleEffectAttach("cingularity",PATTACH_POINT_FOLLOW,ent,att) end)
end)

net.Receive("ss_cc_impact",function(len)
	local wep = net.ReadEntity()
	if(!wep:IsValid()) then return end
	wep.m_tFire = UnPredictedCurTime()
	local ent = wep:GetEffectTarget()
	ent:StopParticles()
	ent:EmitSound("NPC_Strider.Shoot",75,100)
	local att = wep:GetMuzzlePos()
	if(!att) then return end
	//ent:SetAngles(ent:GetAngles() -Angle(32,0,0))
	local attID = ent:LookupAttachment("muzzle")
	ParticleEffectAttach("striderbuster_break_lightning",PATTACH_POINT_FOLLOW,ent,attID)
	ParticleEffectAttach("striderbuster_attach_flash",PATTACH_POINT_FOLLOW,ent,attID)
	ParticleEffectAttach("hunter_muzzle_flash",PATTACH_POINT_FOLLOW,ent,attID)
	ParticleEffectAttach("hunter_muzzle_flash_b",PATTACH_POINT_FOLLOW,ent,attID)
	local pos = att.Pos
	local dir = ent:GetForward()
	local tr = wep:CreateTrace()
	util.ParticleTracerEx("Weapon_Combine_Ion_Cannon",pos +att.Ang:Right() *4.25 +att.Ang:Up() *0.8,tr.HitPos,ent:EntIndex(),1,attID)
	ParticleEffect("Weapon_Combine_Ion_Cannon_Explosion",tr.HitPos,tr.Normal:Angle())
	ParticleEffectAttach("warp_shield_impact",PATTACH_POINT_FOLLOW,ent,attID)
	sound.Play("NPC_Combine_Cannon.FireBullet",tr.HitPos,100,100,1)
end)