local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- MUST BE LINE 1
local toc=select(4,GetBuildInfo())
local me, ns = ...
local pp=print
local addon=LibStub("LibInit"):NewAddon(ns,me,{noswitch=false,profile=true,enhancedProfile=true},'AceHook-3.0','AceEvent-3.0','AceTimer-3.0') --#Addon
local L=addon:GetLocale()
local C=addon:GetColorTable()
--local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
--local C=LibStub("AlarCrayon-3.0"):GetColorTable()
--local addon=LibStub("AlarLoader-3.0")(__FILE__,me,ns):CreateAddon(me,true) --#Addon
local print=ns.print or print
local debug=ns.debug or print
local InCombatLockdown,GameTooltip=InCombatLockdown,GameTooltip
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
local GrowlId=2649
local Growl=''
local BeastCleaveId=118455
local BeastCleave=''
local MultiShotId=2643
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
		[tostring(SOUNDKIT.RAID_WARNING)]="RaidWarning",
		[tostring(SOUNDKIT.READY_CHECK)]="ReadyCheck"
}
local throttled
local alert
local growlalert
local soundalert
local screenalert
local iconalert
local sound="RaidWarning"
local limit=50
local alertmessage=''
local iconrem
local function HasBuff(unit,id,filter)
  filter = filter or "CANCELABLE"
  local index,res=1,true
  while res do
    res=select(10,UnitBuff(unit,index,filter))
    if res and res == id then return index end
    index=index+1
  end
end
--
--local addon=LibStub("AlarLoader-3.0"):CreateAddon(me,true) --#PetCare
function addon:OnInitialized()
	_G.PC=self
	if (self:Is('HUNTER')) then
		self:Init()
		self:AddLabel(L["Settings"])
		self:AddSlider("LIMIT",60,10,90,L["Health limit"],L["Health in percent under which alerts can be performed"])
		self:AddText('').width="full"
		self:AddToggle("SCREENALERT",false,L["On screen Alert"],L["Send an alert on screen when when pet life is under limit"]).width="full"
		self:AddToggle("SOUNDALERT",false,L["Sound alert"],L["Play a sound when pet life is under limit"]).width="full"
		self:AddToggle("ICONALERT",false,L["Visual alert"],L["Show a cast icon reminder when pet life is under limit"]).width="full"
    --self:AddSelect('CORNER',"br",positionScheme,L['Level text aligned to'],L['Position']).width="full"
		self:AddSelect("SOUND",tostring(SOUNDKIT.READY_CHECK),Sounds,L["Choose the sound you want to play"])
		self:AddToggle("NOPVP",true,L["No alerts in pvp"],L["Disables all pet alerts in pvp instances"])
		self:AddAction("PetAlert",format(L["Test %s alert"],MendPet))
		self:AddText('').width="full"
		self:AddToggle("INSTANCE",true,Growl,format(L["Warn if you have %s on autocast"],Growl))
		self:AddAction("GrowlAlert",format(L["Test %s alert"],Growl))
		self:loadHelp()
		self:Apply()
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self:ScheduleRepeatingTimer("PetCheck", 1)
	else
		print(L['This addon is meaningless for non hunter'])
		self:Disable()
		DisableAddOn(me)
	end
	return true
end
function addon:Apply()
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
	RevivePet=GetSpellInfo(RevivePetId) or ''
	DismissPet=GetSpellInfo(DismissPetId) or ''
	CallPet1=GetSpellInfo(CallPet1Id) or ''
	CallPet2=GetSpellInfo(CallPet2Id) or ''
	CallPet3=GetSpellInfo(CallPet3Id) or ''
	CallPet4=GetSpellInfo(CallPet4Id) or ''
	CallPet5=GetSpellInfo(CallPet5Id) or ''
	Growl=GetSpellInfo(GrowlId) or ''
	self:GenerateFrame()

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
			widget:SetModifiedCast('','spell','1',RevivePet)
			tooltip=tooltip .. KEY_BUTTON1 .. ': ' .. MendPet .. "\n"
			widget:SetModifiedCast('','spell','2',Misdirection)
			tooltip=tooltip .. KEY_BUTTON2 .. ': ' .. Misdirection .. "\n"
			widget:SetModifiedCast('ctrl-','spell','2',DismissPet)
			tooltip=tooltip .. CTRL_KEY .. '+' .. KEY_BUTTON2 .. ': ' .. DismissPet .. "\n"
			widget:SetTooltipText(C(tooltip,'green'))
			local status=CreateFrame("StatusBar","PetCareStatus",nil,"TooltipStatusBarTemplate")
			status:SetHeight(h)
			status:SetWidth(l)
			status:SetMinMaxValues(0,100)
			status.TextString=_G.PetCareStatus.Text
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
			local petbar=CreateFrame("Frame",nil,nil,BackdropTemplateMixin and "BackdropTemplate")
			local mebar=CreateFrame("Frame",nil,nil,BackdropTemplateMixin and "BackdropTemplate")
			self:GenThreatBar(petbar,"pet","pettarget")
			self:GenThreatBar(mebar,"player","pettarget")
			widget:Append(status)
			widget:Append(petbar)
			mebar:SetParent(petbar)
			petbar:SetPoint("BOTTOMLEFT",petbar:GetParent(),"TOPLEFT",0,0)
			mebar:SetPoint("TOPLEFT",mebar:GetParent(),"TOPRIGHT",-10,0)
			status:SetPoint("TOPLEFT",status:GetParent(),"BOTTOMLEFT",0,-3)
			status:Show()
			widget:Show()
			self.petstatus=status
			self.petbar=petbar
			iconrem=CreateFrame("Frame")
			iconrem.icon=iconrem:CreateTexture(nil,"ARTWORK")
			iconrem.icon:SetAllPoints()
      iconrem.icon:SetTexture(GetSpellTexture(MendPetId))
			iconrem:Hide()
			iconrem:SetAlpha(0.4)
			iconrem:SetPoint("CENTER")
			iconrem:SetWidth(128)
			iconrem:SetHeight(128)
end
function addon:PetAlert()
		if soundalert then
			if sound then
			    local s=tonumber(sound)
			    if s then
			       PlaySound(sound)
          else
  					if type(sound)=="string" then
  							if sound ~= "none" then PlaySoundFile(sound) end
  					end
          end
			end
		end
		if (screenalert) then
			UIErrorsFrame:AddMessage(alertmessage, 1,0,0, 1.0, 40);
		end
		if (iconalert) then
			iconrem:Show()
		end
end
function addon:PetCheck(value)
	if not alert then return end
	if (not(UnitExists("pet"))) then return end
	local health=self.petstatus:GetValue()
	if (value) then health = value end
	if (health >limit) then
		throttled=false
		iconrem:Hide()
		return
	end
	if (HasBuff("Pet",MendPetId)) then return end -- Already has mend pet
	if (not throttled) then
		throttled=true
		self:PetAlert()
	end
end
local	function threatRefresh(self,elapsed)
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
local function showTooltip(self)
	if self.tooltipText and not InCombatLockdown() then
		GameTooltip:SetOwner(self, self.anchor or "ANCHOR_TOP")
		GameTooltip:AddLine(self.tooltipText)
		GameTooltip:Show()
	end
end
local function hideTooltip(self)
	GameTooltip:Hide()
end
function addon:GenThreatBar(threatbar,unit,target)
	threatbar.t=-1
	threatbar.unit=unit
	threatbar.target=target
	threatbar:SetHeight(15)
	threatbar:SetWidth(60)
	local backdrop = {
	bgFile = "Interface\\TargetingFrame\\NumericThreatBorder", tile = false, tileSize = 4,
	edgeFile = nil, edgeSize = 0,
	insets = {left = 0, right = 0, top = 0, bottom = -15},
	}
	local text=threatbar:CreateFontString(nil,"OVERLAY","TextStatusBarText")
	text:SetJustifyH("CENTER")
	text:SetJustifyV("BOTTOM")
	text:SetPoint("BOTTOM")
	text:SetHeight(15)
	text:SetWidth(40)
	threatbar.text=text
	threatbar:SetBackdrop(backdrop)
	--threatbar:SetBackdropColor(a) sass
	threatbar.elapsed=1
	if unit=="pet" then
		--threatbar.anchor="ANCHOR_LEFT"
		threatbar.tooltipText=L["Pet aggro"]
	else
		--threatbar.anchor="ANCHOR_RIGHT"
		threatbar.tooltipText=L["My aggro"]
	end
	threatbar:SetScript("OnEnter",showTooltip)
	threatbar:SetScript("OnLeave",hideTooltip)
	threatbar:SetScript("OnUpdate",threatRefresh)
end

local function misCheck(bar,elapsed)
	if (floor(GetTime()) > bar:Get("u")) then
		if (not HasBuff("pet",MisdirectionId)) then
			bar:Stop()
		end
	end
end
local function beastcleaveCheck(bar,elapsed)
  if (floor(GetTime()) > bar:Get("u")) then
    if (not HasBuff("pet",BeastCleaveId)) then
      bar:Stop()
    end
  end
end
local function barupdate(bar,elapsed)
	if (floor(GetTime()) > bar:Get("u")) then
		if (not HasBuff("pet",MendPetId)) then
			bar:Stop()
			return
		end
		local p=bar:Get("h") -- old health
		local h=UnitHealth("pet") -- current health
		local r=bar:Get("r")
		if (tonumber(p) and tonumber(h) and tonumber(r)) then
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
		else
			return
		end
	end
end
function addon:GrowlAlert()
	--PlaySound("Growl")
	UIErrorsFrame:AddMessage("******* "..strupper(Growl).." ******", 1,0,0, 1.0, 40)
	PlaySound(SOUNDKIT.RAID_WARNING)
end
function addon:ZoneCheck()
	local inInstance, instanceType = IsInInstance();
	if (inInstance and (instanceType == "party" or instanceType == "raid")) then
		if (select(2,GetSpellAutocast(GrowlId))) then
			self:GrowlAlert()
		end
	end
end
function addon:ZONE_CHANGED_NEW_AREA(event)
	self:ScheduleTimer("ZoneCheck",5)
end
function addon:UNIT_SPELLCAST_SUCCEEDED(event, caster,spelldata,spellid)
	if (caster == "player") then
		if (spellid==MendPetId) then
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
          print(C:green())
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
		elseif (spellid==MisdirectionId) then
			local bar=LibStub("LibCandyBar-3.0"):New("Interface\\TargetingFrame\\UI-StatusBar",100,15)
			local name,_,icon=GetSpellInfo(MisdirectionId)
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
    elseif (spellid==MultiShotId) then
      local bar=LibStub("LibCandyBar-3.0"):New("Interface\\TargetingFrame\\UI-StatusBar",100,15)
      local name,_,icon=GetSpellInfo(BeastCleaveId)
      local status=self.petbar
      bar:SetIcon(icon)
      --bar:SetLabel(name:sub(1,6))
      bar:SetLabel(name)
      bar:Set("u",floor(GetTime())+1)
      bar:SetParent(status)
      bar:SetPoint("BOTTOMLEFT",status,"TOPLEFT",0,16)
      bar:SetColor(C:Orange())
      bar:SetDuration(4)
      bar:AddUpdateFunction(beastcleaveCheck)
      bar:Start()
		elseif (spellid == CallPet1Id or (spellid>=CallPet2Id and spellid <= CallPet3Id)) then
			self.petcare:SetTitle(UnitName("pet"))
		end
	end
end
function AAA()
  local index,res=1,true
  while res do
    print(UnitBuff("pet",index,"CANCELABLE"))
    res=UnitBuff("pet",index,"CANCELABLE")
    index=index+1
  end
end
