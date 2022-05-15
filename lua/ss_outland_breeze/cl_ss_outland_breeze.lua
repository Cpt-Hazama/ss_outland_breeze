include("sh_forest_sil.lua")
include("ss_outland_breeze/cl_shadowguardian.lua")
include("ss_outland_breeze/cl_hudtips.lua")
include("ss_outland_breeze/cl_viewcam.lua")

language.Add("npc_helicopter","Combine Helicopter")
language.Add("env_headcrabcanister","Headcrab Canister")
language.Add("npc_clawscanner","Claw Scanner")
language.Add("grenade_spit","Antlion")
language.Add("entityflame","Fire")
language.Add("world","World")

local cvSSMusic = CreateClientConVar("ss_outland_breeze_enable_ss_music",0,true)
local meta = FindMetaTable("Entity")
function meta:DoSummonEffects(bNoFade)
	local numBones = self:GetBoneCount()
	local origin = self:GetPos()
	local tbPos = {}
	for i=0,self:GetBoneCount() -1 do
		local bonepos,boneang = self:GetBonePosition(i)
		local bDontAdd
		local distMin = math.huge
		for _,pos in ipairs(tbPos) do
			if(_ != i) then
				local dist = bonepos:Distance(pos)
				if(dist <= 40) then bDontAdd = true; break end
			end
		end
		if(!bDontAdd) then
			table.insert(tbPos,bonepos)
		end
	end
	local idx = self:EntIndex()
	local tParticles = {}
	for _,posTgt in ipairs(tbPos) do
		local pt = ClientsideModel("models/error.mdl")
		pt:SetNoDraw(true)
		pt:DrawShadow(false)
		pt:SetPos(origin)
		pt:PhysicsInitSphere(8)
		pt:SetMoveType(MOVETYPE_VPHYSICS)
		pt:SetSolid(SOLID_VPHYSICS)

		local phys = pt:GetPhysicsObject()
		if(phys:IsValid()) then
			phys:Wake()
			phys:EnableGravity(false)
			phys:SetBuoyancyRatio(0)
		end
		ParticleEffectAttach("shadowmaster_summonshadow",PATTACH_ABSORIGIN_FOLLOW,pt,0)
		table.insert(tParticles,pt)
		local hk = "moveshadowpt" .. idx .. "_" .. _
		pt:CallOnRemove(hk,function() hook.Remove("Think",hk) end)
		hook.Add("Think",hk,function()
			local pos = pt:GetPos()
			pos = pos +(posTgt -pos):GetNormal() *3
			pt:SetPos(pos)
		end)
	end
	self:SetNoDraw(!bNoFade)
	timer.Simple(1,function()
		if(self:IsValid()) then self:SetNoDraw(false) end
		for _,pt in ipairs(tParticles) do
			if(pt:IsValid()) then pt:Remove() end
		end
	end)
end

local mat = Material("effects/shadow_glow.vmt")
local matBuff = Material("effects/guardian_shield.vmt")
net.Receive("shadowmaster_buff_tgt",function(len)
	local ent = net.ReadEntity()
	if(!ent:IsValid()) then return end
	ent.m_bShadowBuff = net.ReadUInt(1) == 1
	ent:DoSummonEffects(true)
	if(ent.m_bShadowBuff) then
		ent:EmitSound("spells/life/life_aegis_cast.wav",100,100)
		ent:DoSummonEffects(true)
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
			render.SetColorModulation(1,1,1)
			cam.Start3D(posEye,EyeAngles(),90)
				render.SetBlend(1)
				render.MaterialOverride(matBuff)
					self:DrawModel()
				render.MaterialOverride(0)
				render.SetBlend(1)
			cam.End3D()
			
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
			cam.Start3D(posEye -ent:GetUp() *d +ent:GetRight() *d,EyeAngles())
				ent:DrawModel()
			cam.End3D()
			render.MaterialOverride(0)
			render.SetBlend(1)
		end
	else ent.RenderOverride = nil; ent:EmitSound("spells/life/life_vines_end.wav",100,100) end
end)

net.Receive("ss_blackout",function(len)
	local ent = ClientsideModel("models/blackout.mdl")
	ent:SetPos(Vector(257,-700,67.832497))
	ent:ResetSequence(ent:LookupSequence("exit1"))
	local t = UnPredictedCurTime() +10
	local numFrames = 90
	local fps = 30
	local tDur = numFrames /fps
	local hk = "blackout"
	hook.Add("CalcView",hk,function(pl,pos,ang,fov)
		local tCur = UnPredictedCurTime()
		local delta = math.max(tCur -t,0)
		local att = ent:GetAttachment(ent:LookupAttachment("vehicle_driver_eyes"))
		if(delta >= tDur) then
			hook.Remove("CalcView",hk)
			LocalPlayer():SetEyeAngles(att.Ang)
		end
		ent:SetCycle(delta /tDur)
		return {
			origin = att.Pos,
			angles = att.Ang,
			vm_origin = -Vector(0,0,10000), // Player.DrawViewModel is being a cunt so we'll just move the viewmodel out of the screen
			fov = fov
		}
	end)

	local tDur = 3
	local tHold = 3
	local t = UnPredictedCurTime() +tHold
	hook.Add("HUDPaint",hk,function()
		local tCur = UnPredictedCurTime()
		local delta = math.max(tCur -t,0)
		if(delta >= tDur) then hook.Remove("HUDPaint",hk)
		else
			local a = (1 -(delta /tDur)) *255
			surface.SetDrawColor(0,0,0,a)
			surface.DrawRect(0,0,ScrW(),ScrH())
		end
	end)
end)

local tracks = {
	[1] = {
		track = "music/VLVX_song22.mp3",
		duration = 194.717
	},
	[2] = {
		track = "music/VLVX_song25.mp3",
		duration = 167.34
	},
	[3] = {
		track = "music/VLVX_song27.mp3",
		duration = 209.58
	},
	[4] = {
		track = "music/VLVX_song28.mp3",
		duration = 193.985
	},
	[5] = {
		track = "music/VLVX_song12.mp3",
		duration = 120.216
	},
	[6] = {
		track = "music/VLVX_song21.mp3",
		duration = 169.561
	},
	[7] = {
		track = "music/HL2_song14.mp3",
		duration = 159.269
	},
	[8] = {
		track = "music/HL2_song16.mp3",
		duration = 170.318
	},
	[9] = {
		track = "music/HL2_song29.mp3",
		duration = 135.706
	},
	[10] = {
		track = "music/HL2_song31.mp3",
		duration = 98.769
	},
	[11] = {
		track = "music/VLVX_song0.mp3",
		duration = 62.537
	},
	[12] = {
		track = "music/VLVX_song9.mp3",
		duration = 74.736
	},
	[13] = {
		track = "music/VLVX_song24.mp3",
		duration = 127.216
	},
	[14] = {
		track = "music/VLVX_song20.mp3",
		duration = 124.395
	},
	[15] = {
		track = "music/VLVX_song23.mp3",
		duration = 166.504
	},
	[16] = {
		track = "music/VLVX_song18.mp3",
		duration = 184.686
	},
	[17] = {
		track = "music/VLVX_song4.mp3",
		duration = 99.474
	},
	[18] = {
		track = "music/HL2_song12_long.mp3",
		duration = 73.064
	},
	[19] = {
		track = "music/HL2_song15.mp3",
		duration = 69.224
	},
	[20] = {
		track = "music/HL2_song16.mp3",
		duration = 170.318
	},
	[21] = {
		track = "music/HL2_song3.mp3",
		duration = 90.749
	},
	[22] = {
		track = "music/VLVX_song23ambient.mp3",
		duration = 158.041
	},
	[23] = {
		track = "music/VLVX_Song26.mp3",
		duration = 110.08
	},
	[24] = {
		track = "music/VLVX_song1.mp3",
		duration = 78.054
	},
	[25] = {
		track = "music/VLVX_song19a.mp3",
		duration = 277.943
	},
	[26] = {
		track = "music/VLVX_song19b.mp3",
		duration = 186.776
	},
	[27] = {
		track = "music/VLVX_song2.mp3",
		duration = 55.129
	},
	[28] = {
		track = "music/HL2_song11.mp3",
		duration = 34.612
	},
	[29] = {
		track = "music/HL2_song13.mp3",
		duration = 53.551
	},
	[30] = {
		track = "music/HL2_song17.mp3",
		duration = 61.153
	},
	[31] = {
		track = "music/HL2_song19.mp3",
		duration = 115.801
	},
	[32] = {
		track = "music/HL2_song26.mp3",
		duration = 69.721
	},
	[33] = {
		track = "music/HL2_song27_trainstation2.mp3",
		duration = 72.098
	},
	[34] = {
		track = "music/HL2_song30.mp3",
		duration = 104.02
	},
	[35] = {
		track = "music/HL2_song33.mp3",
		duration = 84.01
	},
	[36] = {
		track = "music/HL2_song28.mp3",
		duration = 13.296
	}
}

local trackEvents = {
	[1] = {1,2,3,4,5,6,7,8,9,10,15,16},
	[2] = {11,12},
	[3] = {13,1,5,6,17,7,8,9},
	[4] = {14},
	[5] = {2,3,5,17,18,19,20,21},
	[6] = {22,23,24,25,26,27,28,29,30,31,32,33,34,35},
	[7] = {36}
}

local _trackCur
local trackCur

local GetVisibleNPCS_Restore
local function EnableSSMusic(b)
	if(b) then
		if(!GetVisibleNPCS_Restore) then return end
		if(trackCur) then trackCur:Stop(); trackCur = nil end
		GetVisibleNPCS = GetVisibleNPCS_Restore
		return
	end
	GetVisibleNPCS_Restore = GetVisibleNPCS_Restore || GetVisibleNPCS
	GetVisibleNPCS = function() return 0 end
end
hook.Add("Initialize","disablemusicsystem",function()
	EnableSSMusic(cvSSMusic:GetBool())
end)
cvars.AddChangeCallback("ss_outland_breeze_enable_ss_music",function(cvar,prev,new)
	EnableSSMusic(tobool(new))
end)

local function PlayTrack(ev,start,bOnce)
	local trackevs = trackEvents[ev]
	local num = #trackevs
	local track = tracks[trackevs[start]]
	if(trackCur) then trackCur:Stop() end
	trackCur = CreateSound(LocalPlayer(),track.track)
	trackCur:SetSoundLevel(0.2)
	if(!cvSSMusic:GetBool()) then trackCur:Play() end
	local tEnd = RealTime() +track.duration +2
	hook.Add("Think","ss_sndtrack",function()
		if(RealTime() >= tEnd) then
			if(bOnce) then
				trackCur = nil
				hook.Remove("Think","ss_sndtrack")
				return
			end
			trackCur:Stop()
			start = start +1
			if(start > num) then start = 1 end
			track = tracks[trackevs[start]]
			trackCur = CreateSound(LocalPlayer(),track.track)
			trackCur:SetSoundLevel(0.2)
			if(!cvSSMusic:GetBool()) then trackCur:Play() end
			tEnd = RealTime() +track.duration +2
		end
	end)
end
local function EndTrack(bKeepActive)
	hook.Remove("Think","ss_sndtrack")
	if(!trackCur || bKeepActive) then return end
	if(trackCur:IsPlaying()) then
		trackCur:FadeOut(4)
		_trackCur = trackCur // Keeping a reference so the gc doesn't fuck this up...
	end
	trackCur = nil
end

net.Receive("ss_track",function(len)
	local ev = net.ReadUInt(5)
	local r = net.ReadFloat()
	local bOnce = net.ReadUInt(1) == 1
	local numTracks = #trackEvents[ev]
	local start = math.Round(r *(numTracks -1) +1)
	PlayTrack(ev,start,bOnce)
end)

net.Receive("ss_track_end",function(len)
	local bKeepActive = net.ReadUInt(1) == 1
	EndTrack(bKeepActive)
end)

SS_Map.HUDMessage = function(msg)
	local tm = UnPredictedCurTime()
	local tFadeIn = tm +0.4
	local tFade = tm +2
	local tEnd = tFade +0.5
	local outlineDef = 4
	local outlineFade = 20
	local bPlay
	hook.Add("HUDPaint","sm_hudmsg",function()
		if(UnPredictedCurTime() >= tEnd) then hook.Remove("HUDPaint","sm_hudmsg")
		else
			local v = ((math.sin((UnPredictedCurTime() -tm) *4) +1) *0.5) *64 +128
			surface.SetFont("Manuscript_Text_Title2")
			surface.SetTextColor(v,v,v,255)
			local w,h = surface.GetTextSize(msg)
			surface.SetTextPos(ScrW() *0.5 -w *0.5,ScrH() *0.35)
			local outline
			local col = Color(v,v,v,255)
			local colOut = Color(0,0,0,255)
			if(UnPredictedCurTime() > tFade) then
				if(!bPlay) then bPlay = true; surface.PlaySound("enchant/enchant_lightning.wav") end
				local tScale = (UnPredictedCurTime() -tFade) /(tEnd -tFade)
				col.a = (1 -tScale) *255
				colOut.a = col.a
				outline = outlineDef +(outlineFade -outlineDef) *tScale
			else
				outline = outlineDef
				if(UnPredictedCurTime() < tFadeIn) then
					local tScale = (tFadeIn -UnPredictedCurTime()) /(tFadeIn -tm)
					col.a = (1 -tScale) *255
					colOut.a = col.a
				end
			end
			draw.SimpleTextOutlined(msg,"Manuscript_Text_Title2",ScrW() *0.5 -w *0.5,ScrH() *0.35,col,0,0,outline,colOut)
		end
	end)
end

local mat = surface.GetTextureID("effects/curse_hud.vmt")
local tDur = 1
local w,h = 256,256
net.Receive("ss_curse",function(len)
	local tStart = UnPredictedCurTime()
	surface.PlaySound("sword/faust_curse.wav")
	// SS_Map.HUDMessage("You have been cursed")
	hook.Add("HUDPaint","cursed",function()
		local tCur = UnPredictedCurTime()
		if(tCur >= tStart +tDur *2) then hook.Remove("HUDPaint","cursed")
		else
			surface.SetTexture(mat)
			local scale
			if(tCur <= tStart +tDur) then scale = math.min((tCur -tStart) /tDur,1)
			else scale = (1 -math.min((tCur -tStart -tDur) /tDur,1)) end
			local a = scale *128
			surface.SetDrawColor(255,0,255,a)
			surface.DrawTexturedRect(ScrW() *0.5 -w *0.5,0,w,h)
		end
	end)
end)