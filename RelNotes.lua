local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:HF_Title("Pet Care","Description")
self:HF_Paragraph("Description")
self:HF_Pre([[
PetCare manages your fighting pet needs:
	keeps track of mend pet
	allow to cast mend pet,revive pet and misdirection directly via it's frame
	shows your current aggro compared to yout pet's one
	can play a sound and or show an alert when your pet falls under a customizable level of health
	can play a sound if you enter a non PVP instance with Growl active
	alerts can be disabled in PVP
]])
self:RelNotes(1,0,1,[[
Alerts Can be  disabled in PVP
]])self:RelNotes(1,0,0,[[
First public release
]])
end