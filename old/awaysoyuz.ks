// awaysoyuz.ks
//   Script to launch Soyuz for Twitch while AFK.
//   Author: Andy Cummings (@cydonian_monk)
//
copypath("0:/lib_camera.ks","").
copypath("0:/lib_time.ks","").
copypath("0:/lib_launch.ks","").

run lib_camera.
run lib_time.
run lib_launch.

declare VarCount to 20.
declare CamFlag to 0.

declare TarApo to 320000.
declare TarPer to 160000.
declare TarHoriAlt to 60000.
declare TarAzi to 37.
declare AscentAoA to 15.

declare SimDelay to 0.02.
declare TarAoA to 0.
declare MinAoA to -30.
declare MaxAoA to 30.
declare TrajSlope to 90 / TarHoriAlt.
declare ZLMCutin to 78000.
declare ZLMCutout to 78000.
declare AtmoCeiling to 82000.
declare PrevAlt to 0.
declare PrevApo to 0.
declare PrevPer to 0.
declare REngine to 0.
declare AEngine to 0.
declare BEngine to 0.
declare CEngine to 0.
declare ZEngine to 0.
declare FairingList to list().
declare FairingDecoupleList to list().
declare FairingJettisonList to list().

// Camera Needs.
declare CamStage to 0.
declare CamNum to 0.
declare CamToggle to 0.
declare CamShift to 0.
set CamShift to 6 + round(10 * random()).

declare function SwitchCam {
  parameter NewCam.
  
  if CamFlag > 0 {
    SwitchCamera(CamNum, NewCam).
  }
  set CamNum to NewCam.
}.

when apoapsis > TarApo then {
  set AscentAoA to 1.
}
when (altitude > (TarApo * 0.90)) then { 
  set MinAoA to MinAoA / 2.
  set MaxAoA to MaxAoA / 2.
}


// PROGRAM ENTRY \\
sas off.
lock throttle to 0.0.
lock steering to heading(90,90).

// Find all fairings that need to be jettisoned.
set FairingList to SHIP:PARTSTAGGED("fairing").
for FairingPart in FairingList {
  set TempList to FairingPart:ALLMODULES().
  for TempPart in TempList {
    if TempPart = "ModuleDecouple" {
	  FairingDecoupleList:ADD(FairingPart).
	  break.
	}
  }
  for TempPart in TempList {
    if TempPart = "ProceduralFairingDecoupler" {
	  FairingJettisonList:ADD(FairingPart).
	  break.
	}
  }  
}
// Find the key engines for this launch vehicle.
list engines in CurVessel.
for eng in CurVessel {
  if eng:tag = "blockr" {    
    set REngine to eng.    
  }
  if eng:tag = "blocka" {
    set AEngine to eng.
  }
  if eng:tag = "blockb" {
    set BEngine to eng.
  }  
  if eng:tag = "blockc" {
    set CEngine to eng.
  }  
  if eng:tag = "blockz" {
    set ZEngine to eng.
  }
}

// Set the staging events for the engines we just found.
if REngine <> 0 {
  when REngine:FLAMEOUT then {
    print "Block R burnout: " + REngine:NAME + ". Jettisoned.". 
	set VarCount to CamShift.
	SwitchCam(3).
    stage.
	set REngine to 0.
	set CamStage to 1.
  }
}
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    print "Block A burnout: " + AEngine:NAME + ".".  
	set VarCount to CamShift.
	SwitchCam(4).	
    stage.
	set AEngine to 0.
	set CamStage to 2.
  }
}
if BEngine <> 0 {
  when BEngine:FLAMEOUT then {
    print "Block B burnout: " + BEngine:NAME + ".".  
	set VarCount to CamShift.
	SwitchCam(5).
    stage.
	set BEngine to 0.	
	set CamStage to 3.	
  }
}
if CEngine <> 0 {
  when CEngine:FLAMEOUT then {
    print "Block C burnout: " + CEngine:NAME + ".".  
    stage.
	set VarCount to CamShift.
	SwitchCam(7).	
	set CEngine to 0.	
	set CamStage to 4.
	RCS on.
  }
}

// Set the list of fairings to jettison.
if FairingList <> 0 {
  when altitude > AtmoCeiling then {
    // Camera - in Fairing, forward.
	set VarCount to CamShift.
	SwitchCam(5).
    for FairPart in FairingDecoupleList {
      print "Fairings decoupled: " + FairPart:NAME.
	  FairPart:GETMODULE("ModuleEnginesRF"):DOEVENT("activate engine").
      FairPart:GETMODULE("ModuleDecouple"):DOEVENT("decouple").
    }	
    for FairPart in FairingJettisonList {
      print "Fairings jettisoned: " + FairPart:NAME.	  
      FairPart:GETMODULE("ProceduralFairingDecoupler"):DOEVENT("jettison").
    }
  }
}
if ZEngine <> 0 {
  when altitude > (AtmoCeiling - 10000) then {
    set VarCount to CamShift.
    SwitchCam(9).  
	print "Launch escape tower jettisoned: " + ZEngine:NAME.
    ZEngine:getmodule("ModuleEnginesRF"):doevent("activate engine").
    ZEngine:getmodule("ModuleDecouple"):doevent("decouple").
  }
}


// Begin Countdown
until VarCount < 21 {
  if (mod(VarCount,10) = 0) {
    PrintTTime(VarCount).
  }
  wait 1.
  set VarCount to VarCount - 1.
}
SwitchCam(2).
until VarCount < 11 {
  if (mod(VarCount,10) = 0) {
    PrintTTime(VarCount).
  }
  wait 1.
  set VarCount to VarCount - 1.
}
SwitchCam(1).
print "Entering final launch countdown sequence.".
until VarCount < 6 {
  PrintTTime(VarCount).
  wait 1.
  set VarCount to VarCount - 1.
}
print "Ignition.".
lock throttle to 1.0.
stage.
until VarCount < 1 {
  PrintTTime(VarCount).
  wait 1.
  set VarCount to VarCount - 1.
}
SwitchCam(2).
print "Liftoff.".
stage.


set CurAoA to 90.
// Don't start our Pitch-Over Maneuver until over 100m/s airspeed.
until airspeed > 100 {
  lock steering to heading(TarAzi,CurAoA).
}

set VarCount to CamShift.
SwitchCam(3).

print ("Starting Pitch-Over Maneuver.").
// Start the Pitch-Over Maneuver.
until apoapsis > TarApo {
  if VarCount < 1 {
    if CamToggle < 1 {
	  SwitchCam(0).
	  set CamToggle to 1.
	}
  }
  if VarCount < -9 {
    set VarCount to CamShift.
	if CamStage > 2 {
	  SwitchCam(5).
	}
    else if CamStage > 1 {
	  SwitchCam(4).
	}
	else if CamStage > 0 {
	  SwitchCam(3).
	}
	else {
	  SwitchCam(2).
	}
	set CamToggle to 0.
  }  
  set CurAoA to CalcPoM(altitude, TarHoriAlt, 0).
  
  // Begin the POM or handle the post-ZLM.
  if (altitude < ZLMCutin) {
    lock steering to heading(TarAzi,CurAoA).
  }
  else if (altitude > ZLMCutin) {
    if (ZLMCutin < ZLMCutout) {
      print ("Starting Zero-Lift Maneuver.").
	}
    break.  
  }  
  wait SimDelay.
  set VarCount to VarCount - SimDelay.    
}
unlock steering.
set VarCount to 5.
until ((altitude > ZLMCutout)
    or (apoapsis > TarApo)) {
  if VarCount < 1 {
    if CamToggle < 1 {
	  SwitchCam(0).
	  set CamToggle to 1.
	}
  }
  if VarCount < -9 {
    set VarCount to CamShift.
	if CamStage > 2 {
	  SwitchCam(5).
	}
    else if CamStage > 1 {
	  SwitchCam(4).
	}
	else if CamStage > 0 {
	  SwitchCam(3).
	}
	else {
	  SwitchCam(2).
	}
	set CamToggle to 0.
  }  

  // TODO - Checks to make sure we're not deviating too far from the intended course.
  wait SimDelay.
  set VarCount to VarCount - SimDelay.
}

// Camera - more stuff
set VarCount to CamShift.
SwitchCam(4).
print "Resuming guided flight. Current apoapsis: " + apoapsis.

set CurAoA to AscentAoA.
until (periapsis > TarPer) {
  if VarCount < 1 {
    if CamToggle < 1 {
	  SwitchCam(0).
	  set CamToggle to 1.
	}
  }
  if VarCount < -9 {
    set VarCount to CamShift.
	if CamStage > 2 {
	  SwitchCam(6).
	}
	else if CamStage > 1 {
	  SwitchCam(4).
	}
	else {
	  SwitchCam(3).
	}
	set CamToggle to 0.
  }  
  lock steering to heading(TarAzi,CurAoA).
  if ((periapsis + 1000) > altitude) {
    print "Target periapsis achieved.".
    break.
  }
  if (apoapsis > (TarApo * 1.5)) {
    print "Excessive over-apoapsis.".
	break.
  }
  set PrevApo to apoapsis.
  set PrevAlt to altitude.
  set PrevPer to periapsis.
  wait SimDelay.
  set CurAoA to CalcAoACruise(altitude, PrevAlt, apoapsis, PrevApo, TarApo, periapsis, PrevPer, TarPer, CurAoA, MaxAoA, MinAoA, SimDelay).
  set VarCount to VarCount - SimDelay.  
}
lock throttle to 0.0.
wait 5.
SwitchCam(5).
wait 5.

// Drop the orbital insertion stage, if it still exists.
if BEngine <> 0 {
  SwitchCam(7).
  stage.
}
wait 10.

SwitchCam(5).
// Deploy solar panels and antennas.
AG10 on.
wait 10.
AG7 on.
SwitchCam(6).
wait 10.

// Kill the headlights and put it in neutral. 
lock throttle to 0.0.
print "Launch complete.".
wait 1.
unlock steering.
unlock throttle.

SwitchCam(0).
// PROGRAM EXIT \\