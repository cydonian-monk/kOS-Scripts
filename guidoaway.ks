// guidoaway.ks
//   Script to launch Soyuz for Twitch while AFK.
//   Author: Andy Cummings (@cydonian_monk)
//
run lib_camera.
run lib_time.
run lib_launch.

declare VarCount to 10.

declare TarApo to 160000.
declare TarPer to 155000.
// Overly-aggressive THA for POM calculation.
declare TarHoriAlt to 72000. 
declare TarAzi to 90.
declare AscentAoA to 15.

declare TarAoa to 0.
declare MinAoa to -45.
declare MaxAoA to 30.
declare TrajSlope to 90 / TarHoriAlt.
declare ZLMCutin to 78000.
declare ZLMCutout to 78000.
declare AtmoCeiling to 82000.
declare PrevAlt to 0.
declare PrevApo to 0.
declare REngine to 0.
declare AEngine to 0.
declare BEngine to 0.
declare CEngine to 0.
declare ZEngine to 0.
declare FairingList to list().
declare FairingDecoupleList to list().
declare FairingJettisonList to list().
declare FlagZLM to 0.

// Camera Needs.
declare CamStage to 0.
declare CamNum to 0.
declare CamToggle to 0.
declare CamShift to 0.
set CamShift to 6 + round(10 * random()).
declare function SwitchCam {
  parameter NewCam.
  SwitchCamera(CamNum, NewCam).  
  set CamNum to NewCam.
}.
declare function CycleCam {
  parameter CamPos.
  
}.


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
	  FairPart:GETMODULE("ModuleEnginesRF"):DOEVENT("activate engine").
      FairPart:GETMODULE("ModuleDecouple"):DOEVENT("decouple").
      print "Fairings decoupled: " + FairPart:NAME.
    }	
    for FairPart in FairingJettisonList {
      FairPart:GETMODULE("ProceduralFairingDecoupler"):DOEVENT("jettison").
      print "Fairings jettisoned: " + FairPart:NAME.	  
    }
  }
}
if ZEngine <> 0 {
  when altitude > (AtmoCeiling + 5000) then {
    set VarCount to CamShift.
    SwitchCam(6).  
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


// Don't start our Pitch-Over Maneuver until over 100m/s airspeed.
set TarAoa to 90.
until airspeed > 100 {
  lock steering to heading(TarAzi,TarAoa).
}

set VarCount to CamShift.
SwitchCam(3).

set PrevAlt to altitude.
print ("Starting Pitch-Over Maneuver.").
// Start the Pitch-Over Maneuver and manage the post-Zero-Lift Maneuver.
until apoapsis > TarApo {
  if VarCount < 1 {
    if CamToggle < 1 {
	  SwitchCam(4).
	  set CamToggle to 1.
	}
  }
  if VarCount < -9 {
    set VarCount to CamShift.
	if CamStage > 2 {
	  SwitchCam(6).
	}
    else if CamStage > 1 {
	  SwitchCam(5).
	}
	else if CamStage > 0 {
	  SwitchCam(3).
	}
	else {
	  SwitchCam(2).
	}
	set CamToggle to 0.
  }  
  if (PrevAlt > altitude) {
    break.
  }  
  set TarAoa to (TarHoriAlt - altitude) * TrajSlope.
  if TarAoa < AscentAoA {
    set TarAoA to AscentAoA.
  }
  // Begin the POM or handle the post-ZLM.
  // TODO AWC - Abort modes and crew ejection....
  //print SHIP:DIRECTION:PITCH.
  //print SHIP:HEADING:PITCH.
  if (altitude < ZLMCutin) {
    lock steering to heading(TarAzi,TarAoa).
  }
  else if (altitude > ZLMCutout)
        //or (SHIP:DIRECTION:PITCH < AscentAoA) 
		{
    if (2 > FlagZLM) {
	  print ("Zero-Lift Maneuver completed; Resuming guided flight.").
	  set FlagZLM to FlagZLM + 1.
    }
    lock steering to heading(TarAzi,AscentAoA).
  }  
  else {
    if (1 > FlagZLM) {
      print ("Starting Zero-Lift Maneuver.").
	  set FlagZLM to FlagZLM + 1.
    }
    unlock steering.
  }
  set PrevAlt to altitude.
  wait 0.02.
  set VarCount to VarCount - 0.02.    
}

// Camera - more stuff
set VarCount to CamShift.
SwitchCam(4).

print "Continuing burn. Apoapsis: " + apoapsis.

set TarAoa to AscentAoA.
set PrevAlt to altitude.
set PrevApo to apoapsis.
lock steering to heading(TarAzi,TarAoa).

set PrevAlt to altitude.
until ((periapsis + 1000) > TarPer) {
  if VarCount < 1 {
    if CamToggle < 1 {
	  SwitchCam(5).
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
  if ((periapsis + 1000) > altitude) {
    break.
  }
  if (apoapsis > (TarApo * 1.2)) {
    print ("Excessive over-apoapsis.").
	lock throttle to 0.0.
	break.
  }
  if (altitude < PrevAlt) {
	set TarAoa to TarAoA + 0.05.
  }
  else {
    if ((apoapsis > PrevApo)
     or (apoapsis > TarApo)) {
      set TarAoa to TarAoa - 0.05.
    }
    else if ((apoapsis < PrevApo)
           or (apoapsis < TarApo - 1000)) {
      set TarAoa to TarAoA + 0.05.
    }	
  }
  set PrevApo to apoapsis.
  set PrevAlt to altitude.
  if TarAoA < MinAoa {
    set TarAoA to MinAoa.
  }
  if TarAoA > MaxAoA {
    set TarAoA to MaxAoA.
  }
  lock steering to heading(TarAzi,TarAoa).
  wait 0.02. 
  set VarCount to VarCount - 0.02.
}
SwitchCam(5).
wait 5.

// Drop the orbital insertion stage, if it still exists.
if BEngine <> 0 {
  SwitchCam(7).
  stage.
}
wait 10.

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