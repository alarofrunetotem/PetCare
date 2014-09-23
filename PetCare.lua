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
local MendPet=136
local Misdirection=34477
local RevivePet=982 --Note in WOD this spell actually switch between mend and revive based on pet status
--
local addon=LibStub("AlarLoader-3.0"):CreateAddon(me,true) --#PetCare
function addon:OnInitialized()
	if (self:Is('HUNTER')) then
		self:Init()
	else
		print(L['This addon is meaningless for non hunter'])
		self:Disable()
	end
end
function addon:Init()
	self:GenerateFrame()

end
function addon:GenerateFrame()
			local h=12
			local l=100
			local widget=LibStub("AceGUI-3.0"):Create("AlarCastHeader")
			_G.PC=widget
			widget.frame:SetAttribute("unit","pet")
			RegisterUnitWatch(widget.frame)
			local stable=self.db
			widget:SetStatusTable(stable)
			widget:ApplyStatus()
			widget:SetHeight(h+8)
			widget:SetWidth(l)
			widget:SetTitle(UnitName("pet") or "Pet")
--    SetModifiedCast(modifier,actiontype,button,value)
			if (toc<60000) then
				widget:SetModifiedCast('','spell','1',MendPet)
				widget:SetModifiedCast('','spell','3',RevivePet)
			else
				widget:SetModifiedCast('','spell','1',RevivePet)
			end
			widget:SetModifiedCast('','spell','2',Misdirection)

			widget:SetModifiedCast('','spell','2',Misdirection)
			local status=CreateFrame("StatusBar","PetCareStatus",nil,"TooltipStatusBarTemplate")
			status:SetHeight(h)
			status:SetWidth(l)
			status:SetMinMaxValues(0,100)
			status.TextString=_G.PetCareStatusText
			status.TextString:SetAllPoints()
			status.TextString:SetJustifyH("LEFT")
			status.elapsed=0
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
			print("Create le spell")
			widget:Show()
			self.petstatus=status
			self.petbar=petbar
			self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
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
local function barupdate(bar,elapsed)
	if (floor(GetTime()) > bar:Get("u")) then
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
		if (spellid==MendPet) then
			local status=self.petstatus
			if (status) then
				status:Show()
				local bar=LibStub("LibCandyBar-3.0"):New("Interface\\TargetingFrame\\UI-StatusBar",100,15)
				local name,_,icon=GetSpellInfo(MendPet)
				bar:SetIcon(icon)
				bar:SetLabel(name)
				bar:SetTimeVisibility(false)
				bar:SetParent(status)
				bar:SetPoint("TOPLEFT",status,"BOTTOMLEFT",0,-3)
				bar:SetColor(C:Orange())
				bar:Set("u",floor(GetTime()))
				bar:Set("h",UnitHealth("pet"))
				bar:Set("r",UnitHealthMax("pet")/20) -- 5% health
				bar:SetDuration(10)
				bar:AddUpdateFunction(barupdate)
				bar:Start()
			end
		elseif (spellid==Misdirection) then
			local bar=LibStub("LibCandyBar-3.0"):New("Interface\\TargetingFrame\\UI-StatusBar",100,15)
			local name,_,icon=GetSpellInfo(Misdirection)
			local status=self.petbar
			bar:SetIcon(icon)
			bar:SetLabel(name)
			bar:SetTimeVisibility(false)
			bar:SetParent(status)
			bar:SetPoint("BOTTOMLEFT",status,"TOPLEFT",0,3)
			bar:SetColor(C:Azure())
			bar:SetDuration(20)
			bar:Start()
		end
	end
end
