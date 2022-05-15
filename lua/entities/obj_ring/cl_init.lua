include('shared.lua')

net.Receive("ss_ring_msg",function(len)
	local msg = net.ReadString()
	SS_Map.HUDMessage(msg)
end)

local blinkFadeIn = 0.25
local blinkDuration = 0
local blinkFadeOut = 0.25
net.Receive("ss_ring_blink",function(len)
	local ent = net.ReadEntity()
	if(!ent:IsValid()) then return end
	ent.m_tBlink = UnPredictedCurTime()
	ent:EmitSound("rings/ring_equip.wav",60,100)
end)

function ENT:GetBlinkScale()
	local tStart = self.m_tBlink
	if(!tStart) then return end
	local tCur = UnPredictedCurTime()
	local tDelta = tCur -tStart
	local tFadeOut = tStart +blinkFadeIn +blinkDuration
	local scale
	if(tCur <= tFadeOut) then scale = math.min(tDelta /blinkFadeIn,1)
	else scale = math.Clamp(1 -(tCur -tFadeOut),0,1) end
	return scale
end

local szLight = 32
local brightness = 0.9
function ENT:Think()
	self.BaseClass.Think(self)
	local scale = self:GetBlinkScale()
	if(!scale) then return end
	local dlight = DynamicLight(self:EntIndex())
	local szLight = szLight *scale
	local brightness = brightness *scale
	if(dlight) then
		local col = self:GetColor()
		dlight.Pos = self:GetPos()
		dlight.r = col.r
		dlight.g = col.g
		dlight.b = col.b
		dlight.Brightness = brightness
		dlight.Size = szLight
		dlight.Decay = szLight *5
		dlight.DieTime = CurTime() +1
		dlight.Style = 0
	end
end

local colSprite = Color(255,255,255,255)
local matSprite = Material("sprites/glow04_noz")
local szSprite = 10
function ENT:Draw()
	self.BaseClass.Draw(self)
	if(self.m_tBlink) then
		local tStart = self.m_tBlink
		local tEnd = tStart +blinkFadeIn +blinkDuration +blinkFadeOut
		local tCur = UnPredictedCurTime()
		if(tCur >= tEnd) then self.m_tBlink = nil
		else
			local pos = self:GetPos()
			local scale = self:GetBlinkScale()
			local szSprite = scale *szSprite
			render.SetMaterial(matSprite)
			render.DrawSprite(pos,szSprite,szSprite,colSprite)
		end
	end
end