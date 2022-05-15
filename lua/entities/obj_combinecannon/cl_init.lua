include('shared.lua')

function ENT:Draw()
	self:DrawModel()
end

local mat = Material("sprites/redglow1")
function ENT:Initialize()
	self:SharedInit()
	local col = Color(255,0,0,255)
	local idx = self:EntIndex()
	local hk = "combinecannon_laser" .. idx
	hook.Add("HUDPaint",hk,function()
		if(self:IsMounted()) then
			local tr = self:CreateTrace()
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
		end
	end)
end

function ENT:OnRemove()
	local idx = self:EntIndex()
	local hk = "combinecannon_laser" .. idx
	hook.Remove("HUDPaint",hk)
end

local VIEW_MOVE_SCALE = 0.25
local cvPitch = GetConVar("m_pitch")
local cvYaw = GetConVar("m_yaw")
local fov
net.Receive("combinecannon_mount",function(len)
	local ent = net.ReadEntity()
	if(!ent:IsValid()) then return end
	local hk = "combinecannon_mount"
	hook.Add("CalcView",hk,function(pl,pos,ang,fov)
		return {
			origin = pos,
			angles = ang,
			vm_origin = -Vector(0,0,10000), // Player.DrawViewModel is being a cunt so we'll just move the viewmodel out of the screen
			fov = fov
		}
	end)
	hook.Add("HUDShouldDraw",hk,function(name)
		if(name == "CHudAmmo" || name == "CHudSecondaryAmmo") then return false end
	end)
	local bAttack = false
	local bZoom = false
	local bDetach = false
	hook.Add("CreateMove",hk,function(cmd)
		local keys = cmd:GetButtons()
		keys = keys -bit.band(keys,IN_JUMP)
		if(bit.band(keys,IN_ATTACK) == IN_ATTACK) then
			keys = keys -bit.band(keys,IN_ATTACK)
			if(!bAttack) then
				bAttack = true
				net.Start("combinecannon_fire")
					net.WriteUInt(1,1)
				net.SendToServer()
			end
		elseif(bAttack) then
			bAttack = false
			net.Start("combinecannon_fire")
				net.WriteUInt(0,1)
			net.SendToServer()
		end
		if(bit.band(keys,IN_ATTACK2) == IN_ATTACK2) then
			keys = keys -bit.band(keys,IN_ATTACK2)
			if(!bZoom) then
				bZoom = true
				if(!fov) then
					fov = LocalPlayer():GetFOV()
					LocalPlayer():SetFOV(30,0.25)
				else
					LocalPlayer():SetFOV(fov,0.25)
					fov = nil
				end
			end
		elseif(bZoom) then bZoom = false end
		if(bit.band(keys,IN_RELOAD) == IN_RELOAD) then
			keys = keys -bit.band(keys,IN_RELOAD)
			if(!bDetach) then
				bDetach = true
				net.Start("combinecannon_detach")
				net.SendToServer()
			elseif(bDetach) then bDetach = false end
		elseif(bDetach) then bDetach = false end
		cmd:SetButtons(keys)
	end)
	hook.Add("InputMouseApply",hk,function(cmd,x,y,ang)
		local angCur = ent:GetAnglesOrigin()
		local restr = ent.AimRestriction
		local VIEW_MOVE_SCALE = VIEW_MOVE_SCALE
		if(ent:IsCharging()) then VIEW_MOVE_SCALE = VIEW_MOVE_SCALE *0.1 end
		x = x *cvYaw:GetFloat() *-1
		y = y *cvPitch:GetFloat()
		ang.p = ang.p +y *VIEW_MOVE_SCALE
		ang.y = ang.y +x *VIEW_MOVE_SCALE
		ang.p = math.ApproachAngle(angCur.p,ang.p,restr.p)
		ang.y = math.ApproachAngle(angCur.y,ang.y,restr.y)
		cmd:SetViewAngles(ang)
		return true
	end)
end)

net.Receive("combinecannon_dismount",function(len)
	if(fov) then
		LocalPlayer():SetFOV(fov,0.25)
		fov = nil
	end
	local hk = "combinecannon_mount"
	hook.Remove("CalcView",hk)
	hook.Remove("HUDShouldDraw",hk)
	hook.Remove("CreateMove",hk)
	hook.Remove("InputMouseApply",hk)
end)