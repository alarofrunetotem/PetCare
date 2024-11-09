<?php
require '/home/giovanni/git/WOW/wowutils/app/help.lua';

Help::HF_Title("Pet Care",\'RELNOTES\')
Help::HF_Paragraph("Description")
Help::HF_Pre([[
PetCare manages your fighting pet needs:
keeps track of mend pet in a specific petframe
allow to cast mend pet,revive pet and misdirection directly via  petframe
shows your current aggro compared to yout pet\'s one
can play a sound and or show an alert when your pet falls under a customizable level of health
can play a sound if you enter a non PVP instance with Growl active
alerts can be disabled in PVP
]])
Help::HF_Paragraph("Release Notes")
Help::RelNotes(6,8,1,[[
Fix: Message: Interface/AddOns/PetCare/PetCare.lua:240: Usage: local r, g, b = GetThreatStatusColor(gameErrorIndex)
Feature: Widget can now be hidden when out of combat: check options
]])
Help::RelNotes(6,8,0,[[
Toc: 10.2.6
]])
Help::RelNotes(6,7,1,[[
 Fix: Now correctly chooses between Revive pet and Mend pet
]])
Help::RelNotes(6,2,1,[[
Toc: 8.3.0
]])
Help::RelNotes(6,2,0,[[
Feature: now tracks Beast Cleave
]])
Help::RelNotes(6,1,3,[[
Feature: 8.2 update
]])
Help::RelNotes(6,1,0,[[
Feature: Dropped old AlarShared framework, now uses LibInit
Fix: Non longer interfere with bagnon
]])
Help::RelNotes(6,0,12,[[
Fix: Removed lua error spam
]])
Help::RelNotes(6,0,7,[[
Fix: Typo in release notes (ouch)
]])
Help::RelNotes(6,0,6,[[
Fix: Error when playing sounds
]])
Help::RelNotes(1,3,1,[[
Toc: bumped to 7.1.0
]])
Help::RelNotes(1,0,1,[[
Alerts Can be  disabled in PVP
]])Help::RelNotes(1,0,0,[[
First public release
]])
