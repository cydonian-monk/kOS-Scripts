// launch.ks
//	Primary Launch Guidance Script.
// 	Author: [redacted] (@cydonian-monk)
//
// Usage: run launch(TarApo, TarPer, TarAzi, HotStart).
//		TarApo		- Target Apoapsis.
//		TarPer 		- Target Periapsis.
//		TarAzi		- Target Azimuth.
//		HotStart	- BlockA dV estimate for when BlockB HotStart should occur.
//
declare parameter TarApo is 80000.
declare parameter TarPer is 79999.
declare parameter TarAzi is 0.
declare parameter HotStart is 0.

run libmonk.ks.

// Vessel Design Assumptions
//	1. Ascent engines tagged with the following names:
//		Radial Boosters: 	blockr
//		First Stage Core: 	blocka
//		Second Stage Core: 	blockb
//		Third Stage Core: 	blockc
//	2. Fairings tagged with the follwoing name:
//		Payload Fairing:	fairing
//	   Fairing should also be unstaged.
//	3. Deployable parts in the following action groups:
//		AG1: 	Orbital Primary Engines
//		AG2: 	Orbital Maneuvering Systems
//		AG4:	Communications Equipment
//		AG8:	Science Experiments Start
//		AG9:	Reaction Wheels
//		AG10: 	Power Generation / Solar Panels
//	4. Stages.
//		This script assumes first stage engines are one stage 
//		earlier than any launch clamps.
//
declare PitchCUR to 0.
declare PitchHOR to 0.
declare PitchASCMax to 30.
declare PitchASCMin to -30.
declare PitchOIBMax to 10.
declare PitchOIBMin to -45.
declare AltHOR is 32000.
declare AltCLEAR to 150.
declare AltFAIR to 55000.
declare AltSAFE to 72000.
declare AltIni to 0.
declare AltPOM to 0.
declare AltPREV to 0.
declare ApoPREV to 0.
declare TimePREV to 0.
declare TimeCUR to 0.
declare TimeLAUNCH to 10.
declare TimeIGN to 3.

declare EngRAD to 0.
declare EngA to 0.
declare EngB to 0.
declare EngC to 0.
declare FairPRC to 0.
declare tRoll to 0.

list parts in CurVessel.
for pcheck in CurVessel {
  if pcheck:tag = "blockr" {    
    set EngRAD to pcheck.    
  }
  if pcheck:tag = "blocka" {
    set EngA to pcheck.
  }
  if pcheck:tag = "blockb" {
    set EngB to pcheck.
  }  
  if pcheck:tag = "blockc" {
    set EngC to pcheck.
  }    
  if pcheck:tag = "fairing" {
	set FairPRC to pcheck.
  }
}

SAS off.
lock throttle to 0.0.

if (TarPer > TarApo) {
  print "Target Periapsis greater than Target Apoapsis. Swapping.".
  print "Please review values for correctness.".
  local tTar is TarApo.
  set TarApo to TarPer.
  set TarPer to tTar.
}
print "Launch Targets".
print " Apoapsis: " + TarApo.
print " Periapsis: " + TarPer.
print " Azimuth: " + TarAzi.

print "Entering Terminal Count".
set AltIni to altitude.
until TimeLAUNCH <= TimeIGN { 
  print "T-" + TimeLAUNCH.
  wait 1.
  set TimeLAUNCH to TimeLAUNCH - 1.
}
lock throttle to 1.0.
stage.
print "T-" + TimeLAUNCH + " | Ignition".
wait 1.
set TimeLAUNCH to TimeLAUNCH - 1.
until TimeLAUNCH < 1 {
  print "T-" + TimeLAUNCH.
  wait 1.
  set TimeLAUNCH to TimeLAUNCH - 1.
}
stage.
set TimeLAUNCH to time:seconds.
logT("Liftoff",0).

set PitchCUR to 90.
set tRoll to ship:facing:roll.
lock steering to heading(TarAzi,PitchCUR,tRoll).

until altitude > (AltIni + AltCLEAR) {
  wait 0.1.
}

if EngRAD <> 0 {
  when EngRAD:FLAMEOUT then {
    stage.
	logT("RSEP alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
  }
}
if EngA <> 0 {
  if (HotStart > 0) {
    when (SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT < HotStart) then {
      logT("dV triggered BlockB hot start " + ROUND(SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT), time:seconds - TimeLAUNCH).
	  EngB:activate.
 	  RCS on.
	  wait 1.
	  EngA:shutdown.
	  stage.
	  logT("ASEP alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
	}
  }
  else {
    when EngA:FLAMEOUT then {
      stage.
	  RCS on.
	  logT("ASEP alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
	}
  }
}
if EngB <> 0 {
  when EngB:FLAMEOUT then {
    stage.
	logT("BSEP alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
  }
}
if EngC <> 0 {
  when EngC:FLAMEOUT then {
    stage.
	logT("CSEP alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
  }
}
if FairPRC <> 0 {
  when altitude > AltFAIR then {  
    list parts in CurVessel.
    for pcheck in CurVessel {
      if pcheck:tag = "fairing" {
	    if pcheck:HasModule("ProceduralFairingDecoupler") {
	      pcheck:GetModule("ProceduralFairingDecoupler"):DoEvent("jettison fairing").
		}
	    else if pcheck:HasModule("FairingDecoupler") {
	      pcheck:GetModule("ProceduralFairingDecoupler"):DoEvent("jettison").
		}
		// TODO check other types of decouple for fairings
      }
    }  
	logT("FAIR alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
  }
}

set tRoll to 0.
logT("Roll Program alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
lock steering to heading(TarAzi,PitchCUR,tRoll).
until airspeed > 100 {
  wait 0.1.
}

logT("Pitch-Over Maneuver alt:" + ROUND(altitude), time:seconds - TimeLAUNCH).
set AltPOM to altitude.
until (altitude > AltHOR) {
  lock steering to heading(TarAzi,PitchCUR). 
  if (apoapsis > TarPer) {
    break.
  }
  wait 0.1.
  set PitchCUR to CalcPoM(altitude, AltHOR, AltPOM, PitchHOR).
  if (PitchCUR < PitchASCMin) {
    set PitchCUR to PitchASCMin.
  }
}

// TODO - Unguided Flight?

logT("Resume Guided Flight; apo:" + ROUND(apoapsis) + " per:" + ROUND(periapsis), time:seconds - TimeLAUNCH).
set TimePREV to time:seconds.
set ApoPREV to apoapsis.
set AltPREV to altitude.  

declare tPID is list (PitchCUR,0,0,0).
until (apoapsis > TarPer) {
  lock steering to heading(TarAzi,PitchCUR).
  wait 0.1.
  set TimeCUR to time:seconds.
  set tPID to CalcPitch(tPID, PitchCUR, altitude, AltPREV, apoapsis, ApoPREV, TarPer, TimeCUR, TimePREV, PitchASCMax, PitchASCMin).
  set PitchCUR to tPID[0].
  set TimePREV to TimeCUR.
  set ApoPREV to apoapsis.
  set AltPREV to altitude.
}

logT("Orbital Insertion Burn; apo:" + ROUND(apoapsis) + " per:" + ROUND(periapsis), time:seconds - TimeLAUNCH).
set TimePREV to time:seconds.
set ApoPREV to apoapsis.
set AltPREV to altitude.
local PitchOIBLocalMax to PitchOIBMax.
local PitchOIBLocalMin to PitchOIBMin.
until (periapsis >= TarPer) {
  lock steering to heading(TarAzi,PitchCUR).
  // If we're burning at Periapsis and the Apo is high enough, break.
  if (((periapsis + 10) > altitude) 
   and (apoapsis > TarApo))  {
	logT("OIB EX-PER per:" + ROUND(periapsis), time:seconds - TimeLAUNCH).
	break.
  }
  // If the Apoapsis goes too far over, break.
  if (apoapsis > (TarApo * 1.05)) {
    logT("OIB EX-APO apo:" + ROUND(apoapsis), time:seconds - TimeLAUNCH).
    break.
  }
  else if (apoapsis > TarApo) {
    set PitchOIBLocalMax to -5.
    set PitchOIBLocalMin to -60.
  }
  else if (apoapsis > (TarApo * 0.90)) {
    set PitchOIBLocalMax to 0.
	lock throttle to 0.2.
  }
  else if (apoapsis <= TarApo) {
    set PitchOIBLocalMax to PitchOIBMax.
	set PitchOIBLocalMin to PitchOIBMin.
  }
  if (verticalspeed < 0) {
    set PitchOIBLocalMax to 45.
	lock throttle to 1.0.
  }
  wait 0.1.
  set TimeCUR to time:seconds.  
  set tPID to CalcPitch(tPID, PitchCUR, altitude, AltPREV, apoapsis, ApoPREV, TarApo, TimeCUR, TimePREV, PitchOIBLocalMax, PitchOIBLocalMin).
  set PitchCUR to tPID[0].
  set TimePREV to TimeCUR.
  set ApoPREV to apoapsis.
  set AltPREV to altitude.    
}

if (verticalspeed < 0) and (periapsis < AltSAFE) {
  logT("EMERG burn, periapsis unsafe at: " + ROUND(periapsis), time:seconds - TimeLAUNCH).
  orbadj(TarApo,TarPer,90,-20,TimeLAUNCH).
}
wait 1.
sas off.
rcs off.
lock throttle to 0.0.
unlock steering.
orbitloop(TarApo, TarPer, TimeLAUNCH).

lock throttle to 0.0.
set ship:control:pilotmainthrottle to 0.
logT("Launch complete. apo:" + ROUND(apoapsis) + " per:" + ROUND(periapsis), time:seconds - TimeLAUNCH).
wait 2.
// Check to see if the deployment separator is still present.
list parts in CurVessel.
for pcheck in CurVessel {
  if pcheck:tag = "deploy" {
	if pcheck:HasModule("ModuleDecouple") {
	  if pcheck:GetModule("ModuleDecouple"):HasEvent("decouple") {
	    pcheck:GetModule("ModuleDecouple"):DoEvent("decouple").
      }
	}
	if pcheck:HasModule("ModuleRCSFX") {
	  if pcheck:GetModule("ModuleRCSFX"):HasField("rcs") {
	    pcheck:GetModule("ModuleRCSFX"):SetField("rcs",true).
      }
	}	
  }
}

wait 5.
AG4 on.
AG8 on.
AG10 on.
wait 1.
unlock steering.
unlock throttle.
RCS off.
logT("Deploy complete.", time:seconds - TimeLAUNCH).
