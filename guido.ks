// guido.ks
//   Generic Launch Guidance Script
//   Author: Andy Cummings (@cydonian_monk)
//
declare VarCount to 21.

declare TarApo to 250000.
declare TarPer to 235000.
declare TarHoriAlt to 42000.
declare TarAzi to 90.
declare AscentAoA to 15.

declare CurAoA to 0.
declare MinAoA to -45.
declare MaxAoA to 45.
declare TrajSlope to 90 / TarHoriAlt.
declare ZLMCutin to 4000.
declare ZLMCutout to 78000.
declare AtmoCeiling to 82000.
declare PrevAlt to 0.
declare PrevApo to 0.
declare REngine to 0.
declare AEngine to 0.
declare BEngine to 0.
declare CEngine to 0.
declare FairingList to list().
declare FairingJettisonList to list().

declare function CalcAoA {
  parameter qAlt.
  parameter qPrevAlt.
  parameter qApo.
  parameter qPrevApo.
  parameter qTarApo.
  parameter qAoA.
  parameter qTarAoA.
  parameter qMaxAoA.
  parameter qMinAoA.

  // If we're not falling, and the apo is climbing, continue at present AoA.
  
  // If we're falling, we need to burn upwards.
  if (qAlt < qPrevAlt) {
	set NewAoA to qAoA + 0.05.
  }
  else {
    // We need to keep raising the Apo until we hit our target.
	if (qApo > qPrevApo) {	
	  if (qAoA < (qTarAoA - 1)) {
	    set NewAoA to qAoA + 0.05.
	  }
	  else if (qAoA > (qTarAoA + 1)) {
	    set NewAoA to qAoA - 0.05.
	  }
	  else {
        set NewAoA to qTarAoA.
	  }
	}	
	else if (qApo < qTarApo) {
	  set NewAoA to qAoA + 0.05.
	  
	}	
    else if (qApo > qTarApo) {
      set NewAoA to qAoA - 0.05.
    }
  }
  // If we've gone over the requested limits, clip.
  if NewAoA > qMaxAoA {
    set NewAoA to qMaxAoA.
  }
  if NewAoA < MinAoa {
    set NewAoA to qMinAoa.
  } 
  return NewAoA.
}.

when apoapsis > TarApo then {
  set AscentAoA to 1.
}


// PROGRAM ENTRY \\
sas off.
lock throttle to 0.0.
lock steering to heading(0,90).

// Find all fairings that need to be jettisoned.
set FairingList to SHIP:PARTSTAGGED("fairing").
for FairingPart in FairingList {
  set TempList to FairingPart:ALLMODULES().
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
}

// Set the staging events for the engines we just found.
if REngine <> 0 {
  when REngine:FLAMEOUT then {
    print "Block R burnout: " + REngine:NAME + ". Jettisoned.". 
    stage.
  }
}
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    print "Block A burnout: " + AEngine:NAME + ".".  
    stage.
  }
}
if BEngine <> 0 {
  when BEngine:FLAMEOUT then {
    print "Block B burnout: " + BEngine:NAME + ".".  
    stage.
  }
}
if CEngine <> 0 {
  when CEngine:FLAMEOUT then {
    print "Block C burnout: " + CEngine:NAME + ".".  
    stage.
	set CEngine to 0.	
	RCS on.
  }
}

// Set the list of fairings to jettison.
if FairingList <> 0 {
  when altitude > AtmoCeiling then {
    for FairPart in FairingJettisonList {
      FairPart:GETMODULE("ProceduralFairingDecoupler"):DOEVENT("jettison").
      print "Fairings jettisoned: " + FairPart:NAME.	  
    }
  }
}

// Begin Countdown
until VarCount < 6 {
  if (mod(VarCount,10) = 0) {
    print "T minus " + VarCount + " seconds.".
  }
  wait 1.
  set VarCount to VarCount - 1.
}
print "Ignition.".
lock throttle to 1.0.
stage.
until VarCount < 1 {
  print "T minus " + VarCount + " seconds.".
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

print ("Starting Pitch-Over Maneuver.").
// Start the Pitch-Over Maneuver.
until apoapsis > TarApo {
  set CurAoA to (TarHoriAlt - altitude) * TrajSlope.
  if CurAoA < AscentAoA {
    set CurAoA to AscentAoA.
  }
  // Begin the POM or handle the post-ZLM.
  if (altitude < ZLMCutin) {
    lock steering to heading(TarAzi,CurAoA).
  }
  else if (altitude > ZLMCutin) {
    print ("Starting Zero-Lift Maneuver."). // TODO - only print if we're actually doing a ZLM.
    break.  
  }  
  wait 0.02.
}
unlock steering.
until (altitude > ZLMCutout) {
  // Checks to make sure we're not deviating too far from the intended course.
  wait 0.5.
}

print "Resuming guided flight. Current apoapsis: " + apoapsis.

set CurAoA to AscentAoA.
until (periapsis > TarPer) {
  lock steering to heading(TarAzi,CurAoA).
  if ((periapsis + 1000) > altitude) {
    break.
  }
  if (apoapsis > (TarApo * 1.2)) {
    print ("Excessive over-apoapsis.").
	lock throttle to 0.0.
	break.
  }
  set PrevApo to apoapsis.
  set PrevAlt to altitude.
  wait 0.02.
  set CurAoA to CalcAoA(altitude, PrevAlt, apoapsis, PrevApo, TarApo, CurAoA, AscentAoA, MaxAoA, MinAoA).
}
wait 5.

// Drop the orbital insertion stage, if it still exists.
if CEngine <> 0 {
  stage.
}
wait 10.

// Deploy solar panels and antennas.
AG10 on.
wait 10.
AG7 on.
wait 10.

// Kill the headlights and put it in neutral. 
lock throttle to 0.0.
print "Launch complete.".
wait 1.
unlock steering.
unlock throttle.

// PROGRAM EXIT \\