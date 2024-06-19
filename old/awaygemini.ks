// awaygemini.ks
//   Script to launch Gemini / Titan II for Twitch while AFK.
//   Author: Andy Cummings (@cydonian_monk)
//
run lib_camera.
run lib_time.
run lib_launch.

declare VarCount to 20.
declare CamFlag to 1.

declare TarApo to 210000.
declare TarPer to 200000.
declare TarHoriAlt to 60000.
declare TarAzi to 90.
declare AscentAoA to 5.

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
declare AEngine to 0.
declare BEngine to 0.

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

// Find the key engines for this launch vehicle.
list engines in CurVessel.
for eng in CurVessel {
  if eng:tag = "blocka" {
    set AEngine to eng.
  }
  if eng:tag = "blockb" {
    set BEngine to eng.
  }  
}

// Set the staging events for the engines we just found.
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    print "Block A burnout: " + AEngine:NAME + ".".  
	set VarCount to CamShift.
    stage.
	set AEngine to 0.
	set CamStage to 2.
  }
}
if BEngine <> 0 {
  when BEngine:FLAMEOUT then {
    print "Block B burnout: " + BEngine:NAME + ".".  
	set VarCount to CamShift.
    stage.
	set BEngine to 0.	
	set CamStage to 3.	
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
until VarCount < 11 {
  if (mod(VarCount,10) = 0) {
    PrintTTime(VarCount).
  }
  wait 1.
  set VarCount to VarCount - 1.
}
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
print "Liftoff.".
stage.


set CurAoA to 90.
// Don't start our Pitch-Over Maneuver until over 100m/s airspeed.
until airspeed > 100 {
  lock steering to heading(TarAzi,CurAoA).
}

set VarCount to CamShift.

print ("Starting Pitch-Over Maneuver.").
// Start the Pitch-Over Maneuver.
until apoapsis > TarApo {
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

  // TODO - Checks to make sure we're not deviating too far from the intended course.
  wait SimDelay.
}

// Camera - more stuff
print "Resuming guided flight. Current apoapsis: " + apoapsis.

set CurAoA to AscentAoA.
until (periapsis > TarPer) {
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

// Drop the orbital insertion stage, if it still exists.
if BEngine <> 0 {
  stage.
}
wait 10.

// Kill the headlights and put it in neutral. 
lock throttle to 0.0.
print "Launch complete.".
wait 1.
unlock steering.
unlock throttle.

// PROGRAM EXIT \\