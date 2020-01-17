local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:HF_Title("Pet Care",'RELNOTES')
self:HF_Paragraph("Description")
self:HF_Pre([[
PetCare manages your fighting pet needs:
keeps track of mend pet in a specific petframe
allow to cast mend pet,revive pet and misdirection directly via  petframe
shows your current aggro compared to yout pet's one
can play a sound and or show an alert when your pet falls under a customizable level of health
can play a sound if you enter a non PVP instance with Growl active
alerts can be disabled in PVP
]])
self:HF_Paragraph("Release Notes")
self:RelNotes(6,2,1,[[
Toc: 8.3.0
]])
self:RelNotes(6,2,0,[[
Feature: now tracks Beast Cleave
]])
self:RelNotes(6,1,3,[[
Feature: 8.2 update
]])
self:RelNotes(6,1,0,[[
Feature: Dropped old AlarShared framework, now uses LibInit
Fix: Non longer interfere with bagnon
]])
self:RelNotes(6,0,12,[[
Fix: Removed lua error spam
]])
self:RelNotes(6,0,7,[[
Fix: Typo in release notes (ouch)
]])
self:RelNotes(6,0,6,[[
Fix: Error when playing sounds
]])
self:RelNotes(1,3,1,[[
Toc: bumped to 7.1.0
]])
self:RelNotes(1,0,1,[[
Alerts Can be  disabled in PVP
]])self:RelNotes(1,0,0,[[
First public release
]])
end