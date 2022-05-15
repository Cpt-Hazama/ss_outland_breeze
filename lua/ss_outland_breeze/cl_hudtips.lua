surface.CreateFont("HUDHintLarge",{
	font 		= "default",
	size 		= 36,
	weight 		= 1000,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= false,
	additive 	= false,
	outline 	= false
})
surface.CreateFont("HUDHintMedium",{
	font 		= "default",
	size 		= 24,
	weight 		= 500,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= false,
	additive 	= false,
	outline 	= false
})
local colBg = Color(20,20,20,128)
local colFont = Color(242,220,0,255)
local colFontBlink = Color(255,150,0,255)
local tFadeIn = 0.5
local tStay = 3
local tFadeOut = tFadeIn
local tipsDrawn = {}
SS_Map.DrawHUDTip = function(name,key,action)
	if(tipsDrawn[name]) then return end
	tipsDrawn[name] = true
	surface.SetFont("HUDHintLarge")
	local wKey,hKey = surface.GetTextSize(key)
	surface.SetFont("HUDHintMedium")
	local wAction,hAction = surface.GetTextSize(action)
	local wSpaceSide = 20
	local wSpace = 30
	local wBox = wKey +wAction +wSpace +wSpaceSide *2
	local hBox = hKey +35
	local tStart = UnPredictedCurTime()
	local hk = "ss_drawhudtip"
	local tBlinkStart = tStart +tFadeIn
	hook.Add("HUDPaint",hk,function()
		local tCur = UnPredictedCurTime()
		local tDelta = tCur -tStart
		if(tDelta >= tFadeIn +tStay +tFadeOut) then hook.Remove("HUDPaint",hk)
		else
			local colBg = Color(colBg.r,colBg.g,colBg.b,colBg.a)
			local colFont = Color(colFont.r,colFont.g,colFont.b,colFont.a)
			if(tCur >= tBlinkStart) then
				local sc = math.abs(math.sin((tCur -tBlinkStart) *2.5))
				colFont.r = colFont.r +(colFontBlink.r -colFont.r) *sc
				colFont.g = colFont.g +(colFontBlink.g -colFont.g) *sc
				colFont.b = colFont.b +(colFontBlink.b -colFont.b) *sc
			end
			local scale
			if(tDelta <= tFadeIn +tStay) then scale = math.min((tCur -tStart) /tFadeIn,1)
			else scale = 1 -(tDelta -(tFadeIn +tStay)) /tFadeOut end
			colBg.a = colBg.a *scale
			colFont.a = colFont.a *scale
			local x = ScrW() -wBox -30
			local y = ScrH() *0.6
			draw.RoundedBox(6,x,y,wBox,hBox,colBg)
			surface.SetFont("HUDHintLarge")
			surface.SetTextColor(colFont.r,colFont.g,colFont.b,colFont.a)
			surface.SetTextPos(x +wSpaceSide,y +hBox *0.5 -hKey *0.5)
			surface.DrawText(key)
			
			surface.SetFont("HUDHintMedium")
			surface.SetTextPos(x +wSpaceSide +wSpace +wKey,y +hBox *0.5 -hAction *0.5)
			surface.DrawText(action)
		end
	end)
end

net.Receive("ss_hudtip",function(len)
	local identifier = net.ReadString()
	local key = net.ReadString()
	local action = net.ReadString()
	SS_Map.DrawHUDTip(identifier,key,action)
end)