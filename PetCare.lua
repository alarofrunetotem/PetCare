local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- MUST BE LINE 1
local _,_,_,toc=GetBuildInfo()
local pp=print
local me, ns = ...
--@debug@
print("Loading",__FILE__," inside ",me)
--@end-debug@
if (LibDebug) then LibDebug() end
local function debug(...)
	--@debug@
	print(...)
	--@end-debug@
end
local print=_G.print
local notify=_G.print
local error=_G.error
local sdebug=debug
local function dump() end
local function debugEnable() end
if (LibStub("AlarLoader-3.0",true)) then
	local rc=LibStub("AlarLoader-3.0"):GetPrintFunctions(me)
	print=rc.print
	--@debug@
	debug=rc.debug
	sdebug=rc.sdebug
	dump=rc.dump
	--@end-debug@
	notify=rc.notify
	error=rc.error
	debugEnable=rc.debugEnable
else
	debug("Missing AlarLoader-3.0")
end
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local C=LibStub("AlarCrayon-3.0"):GetColorTable()
-----------------------------------------------------------------
local MendPetId=136
local MendPet=''
local MisdirectionId=34477
local Misdirection=''
local DismissPetId=2641
local DismissPet=''
local RevivePetId=982 --Note in WOD this spell actually switch between mend and revive based on pet status
local RevivePet=''
local CallPet1Id=883
local CallPet1=''
local CallPet2Id=83242
local CallPet2=''
local CallPet3Id=83243
local CallPet3=''
local CallPet4Id=83244
local CallPet4=''
local CallPet5Id=83245
local CallPet5=''
		-- call pet 1 883
		-- call pet 2 83242
		-- call pet 3 83243
		-- call pet 4 83244
		-- call pet 5 83245
		--dismiss pet 2641
local Sounds={
		["Sound\\Doodad\\ZeppelinHorn.wav"]='Horn',
		["Sound\\Doodad\\SimonGame_LargeBlueTree.wav"]='Chimes',
		["Sound\\Doodad\\UtherShrineLightBeam_Open.wav"]='Beam',
		RaidWarning="RaidWarning",
		ReadyCheck="ReadyCheck"
}
local throttled
local alert
local soundalert
local screenalert
local iconalert
local sound="RaidWarning"
local limit=50
local alertmessage=''
local iconrem

--
local addon=LibStub("AlarLoader-3.0"):CreateAddon(me,true) --#PetCare
function addon:OnInitialized()
	_G.PC=self
--@debug@
	debugEnable(true)
--@end-debug@
	if (self:Is('HUNTER')) then
		self:Init()
		self:AddSlider("LIMIT",60,10,90,L["Health in percent under which alerts can be performed"]).width="full"
		self:AddToggle("SCREENALERT",false,L["Send an alert on screen when when pet life is under limit"]).width="full"
		self:AddToggle("SOUNDALERT",false,L["Play a sound when pet life is under limit"]).width="full"
		self:AddToggle("ICONALERT",false,L["Show a cast icon reminder when pet life is under limit"]).width="full"
		self:AddSelect("SOUND",'Beam',Sounds,L["Choose the sound you want to play"])
		self:loadHelp()
		self:APPLY()
	else
		print(L['This addon is meaningless for non hunter'])
		self:Disable()
		DisableAddOn(me)
	end
	return true
end
function addon:APPLY()
		soundalert=self:GetBoolean("SOUNDALERT")
		screenalert=self:GetBoolean("SCREENALERT")
		iconalert=self:GetBoolean("ICONALERT")
		alert=soundalert or screenalert or iconalert
		sound=self:GetVar("SOUND")
		limit=self:GetVar("LIMIT")
		alertmessage=format(L["Pet health under "] .. "%d%%",limit)
end
function addon:Init()
	MendPet=GetSpellInfo(MendPetId)
	Misdirection=GetSpellInfo(MisdirectionId)
	RevivePet=GetSpellInfo(RevivePetId)
	DismissPet=GetSpellInfo(DismissPetId)
	CallPet1=GetSpellInfo(CallPet1Id)
	CallPet2=GetSpellInfo(CallPet2Id)
	CallPet3=GetSpellInfo(CallPet3Id)
	CallPet4=GetSpellInfo(CallPet4Id)
	CallPet5=GetSpellInfo(CallPet5Id)
	self:GenerateFrame()
	self:ScheduleRepeatingTimer("PetAlert", 1)

end
function addon:GenerateFrame()
			local h=12
			local l=100
			local widget=LibStub("AceGUI-3.0"):Create("AlarCastHeader")
			self.petcare=widget
			widget.frame:SetAttribute("unit","pet")
			RegisterUnitWatch(widget.frame)
			widget:SetOnAttributeChanged([=[
			if (name=='statehidden' and not value) then
				self:CallMethod("SetText",(select(2,PlayerPetSummary())))
			end
			]=]
			)
			local stable=self.db
			widget:SetStatusTable(stable)
			widget:ApplyStatus()
			widget:SetHeight(h+8)
			widget:SetWidth(l)
			widget:SetTitle(UnitName("pet") or "Pet")
--    SetModifiedCast(modifier,actiontype,button,value)
			local tooltip=''
			if (toc<60000) then
				widget:SetModifiedCast('','spell','1',MendPet)
				tooltip=tooltip .. "Left-Click: " .. MendPet .. "\n"
				widget:SetModifiedCast('','spell','3',RevivePet)
				tooltip=tooltip .. "Middle-Click: " .. RevivePet .. "\n"
			else
				widget:SetModifiedCast('','spell','1',RevivePet)
				tooltip=tooltip .. "Left-Click: " .. RevivePet .. "\n"
			end
			widget:SetModifiedCast('','spell','2',Misdirection)
			tooltip=tooltip .. "Right-Click: " .. Misdirection .. "\n"
			widget:SetModifiedCast('ctrl-','spell','2',DismissPet)
			tooltip=tooltip .. "Ctrl-Right-Click: " .. DismissPet .. "\n"
			widget:SetTooltipText(C(tooltip,'green'))
			local status=CreateFrame("StatusBar","PetCareStatus",nil,"TooltipStatusBarTemplate")
			status:SetHeight(h)
			status:SetWidth(l)
			status:SetMinMaxValues(0,100)
			status.TextString=_G.PetCareStatusText
			status.TextString:SetAllPoints()
			status.TextString:SetJustifyH("LEFT")
			status.elapsed=0
			status.throttled=false
			status.refresh=function(self,elapsed)
				self.elapsed=self.elapsed+elapsed
				if self.elapsed > 5 then
					self.elapsed=0
				end
				if (UnitExists("pet")) then
						self:SetValue(floor(UnitHealth("pet")/UnitHealthMax("pet")*100+0.5))
				end
			end
			status.onchanged=function(self,value)
					HealthBar_OnValueChanged(self,value,true)
					self.TextString:SetFormattedText("%d%%",value)
				end
			status:SetScript("OnUpdate",status.refresh)
			status:SetScript("OnValueChanged",status.onchanged)
			local petbar=CreateFrame("Frame")
			local mebar=CreateFrame("Frame")
			self:GenThreatBar(petbar,"pet","pettarget")
			self:GenThreatBar(mebar,"player","pettarget")
			widget:Append(status)
			widget:Append(petbar)
			mebar:SetParent(petbar)
			petbar:SetPoint("BOTTOMLEFT",petbar:GetParent(),"TOPLEFT",0,-petbar:GetHeight()/2)
			mebar:SetPoint("TOPLEFT",mebar:GetParent(),"TOPRIGHT",-10,0)
			status:SetPoint("TOPLEFT",status:GetParent(),"BOTTOMLEFT",0,-3)
			status:Show()
			debug("Create le spell")
			widget:Show()
			self.petstatus=status
			self.petbar=petbar
			iconrem=CreateFrame("Frame")
			iconrem:Hide()
			iconrem:SetBackdrop( {
				bgFile = select(3,GetSpellInfo(MendPet)),
				edgeFile = nil, tile = false, tileSize = 0, edgeSize = 32,
				insets = { left = 0, right = 0, top = 0, bottom = 0 }
			});
			iconrem:SetAlpha(0.4)
			iconrem:SetPoint("CENTER")
			iconrem:SetWidth(128)
			iconrem:SetHeight(128)

			self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end
function addon:PetAlert(value)
	if not alert then return end
	if (not(UnitExists("pet"))) then return end
	local health=self.petstatus:GetValue()
	if (value) then health = value end
	if (health >limit) then
		if (value) then debug("reset") end
		throttled=false
		iconrem:Hide()
		return
	end
	debug(limit,health)
	if (UnitBuff("Pet",MendPet)) then return end -- Already has mend pet
	if (not throttled) then
		if (value) then debug("throttled") end
		throttled=true
		if (soundalert) then
			debug("Current sound",sound)
			PlaySound(sound)
		end
		if (screenalert) then
			UIErrorsFrame:AddMessage(alertmessage, 1,0,0, 1.0, 40);
		end
		if (iconalert) then
			iconrem:Show()
		end
	end
end
function addon:GenThreatBar(threatbar,unit,target)
	threatbar.t=-1
	threatbar.unit=unit
	threatbar.target=target
	threatbar:SetHeight(30)
	threatbar:SetWidth(60)
	local backdrop = {
	bgFile = "Interface\\TargetingFrame\\NumericThreatBorder", tile = false, tileSize = 16,
	--bgFile="Interface\\QuestFrame\\UI-QuestTitleHighlight", tile = false, tileSize = 16,
	edgeFile = nil, edgeSize = 0,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
	}
	local text=threatbar:CreateFontString(nil,"OVERLAY","TextStatusBarText")
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetPoint("TOPLEFT")
	text:SetHeight(15)
	text:SetWidth(40)
	threatbar.text=text
	threatbar:SetBackdrop(backdrop)
	threatbar.elapsed=1
	threatbar.refresh=
	function(self,elapsed)
			if not UnitExists(self.unit) or not UnitExists(self.target) then self.text:SetFormattedText("%d%%",0) return end
			local isTanking, t, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(self.unit,self.target)
			if (isTanking) then threatpct=100 end
			if (self.t ~= t) then
				self.t=t
				self:SetBackdropColor(GetThreatStatusColor(t))
			end
			if (tonumber(threatpct)) then
				self.text:SetFormattedText("%d%%",threatpct)
			else
				self.text:SetText("---")
			end
			self.elapsed=self.elapsed+elapsed
		end
	threatbar:SetScript("OnUpdate",threatbar.refresh)
end
local function misCheck(bar,elapsed)
	if (floor(GetTime()) > bar:Get("u")) then
		if (not UnitBuff("pet",Misdirection)) then
			debug(Misdirection,":",UnitBuff("pet",Misdirection))
			bar:Stop()
		end
	end
end
local function barupdate(bar,elapsed)
	if (floor(GetTime()) > bar:Get("u")) then
		if (not UnitBuff("pet",MendPet)) then
			debug(MendPet,":",UnitBuff("pet",MendPet))
			bar:Stop()
		end
		local p=bar:Get("h") -- old health
		local h=UnitHealth("pet") -- current health
		local r=bar:Get("r")
		local d=(h-p)
		local c="green"
		if (d<0) then
			if (abs(d)>r) then
				c="red"
			else
				c="orange"
			end
		end
		bar:SetColor(C[c](C))
	end
end
function addon:UNIT_SPELLCAST_SUCCEEDED(event, caster,spell,rank,lineid,spellid)
	if (caster == "player") then
		if (spell==MendPet) then
			local status=self.petstatus
			iconrem:Hide()
			if (status) then
				status:Show()
				local bar=LibStub("LibCandyBar-3.0"):New("Interface\\TargetingFrame\\UI-StatusBar",100,15)
				local name,_,icon=GetSpellInfo(MendPet)
				bar:SetIcon(icon)
				bar:SetLabel(name)
				bar:SetTimeVisibility(false)
				bar:SetParent(status)
				bar:SetPoint("TOPLEFT",status,"BOTTOMLEFT",0,-3)
				if (UnitHealth("pet")==UnitHealthMax("pet")) then
					bar:SetColor(C:green())
				else
					bar:SetColor(C:orange())
				end
				bar:Set("u",floor(GetTime())+1)
				bar:Set("h",UnitHealth("pet"))
				bar:Set("r",UnitHealthMax("pet")/20) -- 5% health
				bar:SetDuration(10)
				bar:AddUpdateFunction(barupdate)
				bar:Start()
			end
		elseif (spell==Misdirection) then
			local bar=LibStub("LibCandyBar-3.0"):New("Interface\\TargetingFrame\\UI-StatusBar",100,15)
			local name,_,icon=GetSpellInfo(Misdirection)
			local status=self.petbar
			bar:SetIcon(icon)
			bar:SetLabel(name:sub(1,6))
			bar:Set("u",floor(GetTime())+1)
			bar:SetParent(status)
			bar:SetPoint("BOTTOMLEFT",status,"TOPLEFT",0,3)
			bar:SetColor(C:Azure())
			bar:SetDuration(20)
			bar:AddUpdateFunction(misCheck)
			bar:Start()
		elseif (spellid == CallPet1Id or (spellid>=CallPet2Id and spellid <= CallPet3Id)) then
			self.petcare:SetTitle(UnitName("pet"))
		end
	end
end
