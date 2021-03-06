// awaysputnik.ks
//   Script to launch Sputnik for Twitch while AFK.
//   Author: Andy Cummings (@cydonian_monk)
//
run lib_camera.
run lib_time.
run lib_launch.

declare VarCount to 30.
declare CamFlag to 1.
declare TarApo to 160000.
declare TarPer to 155000.
declare TarHoriAlt to 73000.
declare TarAzi to 110.

declare TarAoa to 0.
declare AscentAoA to 12.
declare MinAoa to -45.
declare MaxAoA to 30.
declare TrajSlope to 90 / TarHoriAlt.
declare AtmoCeiling to 82000.
declare PrevAlt to 0.
declare PrevApo to 0.
declare REngine to 0.
declare AEngine to 0.

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

sas off.
lock throttle to 0.0.
lock steering to heading(90,90).

// Find the key engines for this launch vehicle.
list engines in CurVessel.
for eng in CurVessel {
  if eng:tag = "blockr" {    
    set REngine to eng.    
  }
  if eng:tag = "blocka" {
    set AEngine to eng.
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
SwitchCam(0).
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
SwitchCam(1).
print "Liftoff.".
stage.

// Set the staging events for the engines we just found.
if REngine <> 0 {
  when REngine:FLAMEOUT then {
    SwitchCam(2).
	set VarCount to 20.
    print "Block R burnout: " + REngine:NAME + ". Jettisoned.".  
	set CamStage to 2.
    stage.
  }
}
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    print "Block A burnout: " + AEngine:NAME + ".".
    stage.
  }
}

set TarAoa to 90.

set VarCount to 8.
until VarCount < 1 {
  wait 1.
  set VarCount to VarCount - 1.
}

until airspeed > 100 {
  lock steering to heading(TarAzi,TarAoa).
}

set VarCount to 10.
SwitchCam(2).

set PrevAlt to altitude.
until apoapsis > TarApo {
  if VarCount < 1 {
    SwitchCam(0).
  }
  if VarCount < -10 {
    set VarCount to 10.
	if CamStage > 1 {
	  SwitchCam(2).
	}
	else {
	  SwitchCam(1).
	}
  }  
  if (PrevAlt > altitude) {
    break.
  }  
  set TarAoa to (TarHoriAlt - altitude) * TrajSlope.
  if TarAoa < AscentAoA {
    set TarAoA to AscentAoA.
  }
  lock steering to heading(TarAzi,TarAoa).
  set PrevAlt to altitude.
  wait 0.02.
  set VarCount to VarCount - 0.02.  
}

print "Continuing burn. Apoapsis: " + apoapsis.

set TarAoa to AscentAoA.
set PrevAlt to altitude.
set PrevApo to apoapsis.
lock steering to heading(TarAzi,TarAoa).

set PrevAlt to altitude.
until ((periapsis + 1000) > TarPer) {
  if VarCount < 1 {
    SwitchCam(0).
  }
  if VarCount < -10 {
    set VarCount to 10.
	SwitchCam(2).
  }
  if ((periapsis + 1000) > altitude) {
    break.
  }
  if (altitude < PrevAlt) {
	set TarAoa to TarAoA + 0.05.
  }
  else {
    if ((apoapsis > PrevApo)
     or (apoapsis > TarApo + 1000)) {
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

SwitchCam(0).

lock throttle to 0.0.
print "Launch complete.".
wait 1.
unlock steering.
unlock throttle.

wait 5.
print "Fairing cap jettison.".
stage.
wait 5.
SwitchCam(3).
wait 5.
print "Payload deployment.".
stage.

wait 10.
SwitchCam(0).
wait 5.
