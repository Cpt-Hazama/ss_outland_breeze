local FL_FADE_FROM = 1
local FL_STAY_OUT = 2
SS_Map.FadeScreen = function(tFade,tHold,col,flags)
	flags = flags || 0
	local tStart = UnPredictedCurTime()
	local tEnd = tStart +tFade +tHold
	local hk = "fadescreen"
	hook.Add("HUDPaint",hk,function()
		local tCur = UnPredictedCurTime()
		if(tCur >= tEnd && bit.band(flags,FL_STAY_OUT) == 0) then hook.Remove("HUDPaint",hk)
		else
			local a
			local tDelta = tCur -tStart
			a = math.min(tDelta /tFade,1) *col.a
			if(bit.band(flags,FL_FADE_FROM) == FL_FADE_FROM) then a = col.a -a end
			surface.SetDrawColor(col.r,col.g,col.b,a)
			surface.DrawRect(0,0,ScrW(),ScrH())
		end
	end)
end

local posWorld = Vector(869,8457.86,-1871)
local angWorld = Angle(0,0,0)
net.Receive("ss_viewcam_end",function(len)
	local hk = "viewcam_end"
	hook.Add("CalcView",hk,function(pl,pos,ang,fov)
		return {
			origin = posWorld,
			angles = angWorld,
			vm_origin = -Vector(0,0,10000),
			fov = fov
		}
	end)
end)

net.Receive("ss_fade",function(len)
	local tFade = net.ReadFloat()
	local tHold = net.ReadFloat()
	local col = Color(net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8))
	local flags = net.ReadUInt(4)
	SS_Map.FadeScreen(tFade,tHold,col,flags)
end)