// KerbalLaunch.ks
//   Math-based launch script for Kerbal OS.
//   Author: Andy Cummings (@cydonian_monk)
//
//   Code assumes a vehicle designed to have a launch TWR of 1.05 to 1.1, with
//   similar ~1.0 TWRs of all upper stages.
//
//   NOTE: Remember to set your throttle to zero before running this script!
run lib_launch.
run lib_time.

declare VarCount to 20.

declare TarApo to 120000.
declare TarPer to 72000.
declare TarHoriAlt to 30000.
declare TarAzi to 90.
declare TarAoa to 0.
declare AscentAoA to 10.

declare SimDelay to 0.02.

declare TrajSlope to 90 / TarHoriAlt.
declare MinAoa to -30.
declare MaxAoA to 30.
declare CurAoA to 0.

declare ZLMCutin to 48000.
declare ZLMCutout to 48000.
declare AtmoCeiling to 52000.
declare PrevAlt to 0.
declare PrevApo to 0.
declare PrevPer to 0.

declare AEngine to 0.
declare BEngine to 0.
declare REngine to 0.
declare ZEngine to 0.
declare FairingList to list().
declare FairingDecoupleList to list().
declare FairingJettisonList to list().
declare FairingDeployList to list().

// Find all the engines and sort.
list engines in CurVessel.
for eng in CurVessel {
  if eng:tag = "blocka" {
    set AEngine to eng.
  }
  if eng:tag = "blockb" {
    set BEngine to eng.
  }  
  if eng:tag = "blockr" {
    set REngine to eng.
  }    
  if eng:tag = "blockz" {
    set ZEngine to eng.
  }      
}
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
  for TempPart in TempList {
    if TempPart = "ModuleProceduralFairing" {
	  FairingDeployList:ADD(FairingPart).
	  break.
	}
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
until VarCount < 2 {
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

lock steering to heading(90,90).
lock throttle to 1.0.

print "Liftoff.".
stage.

// Set the staging events for the engines we just found.
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    print "Block A burnout: " + AEngine:NAME + ".".  
    stage.
	set AEngine to 0.
  }
}
if BEngine <> 0 {
  when BEngine:FLAMEOUT then {
    print "Block B burnout: " + BEngine:NAME + ".".  
    stage.
	set BEngine to 0.	
  }
}
if REngine <> 0 {
  when REngine:FLAMEOUT then {
    print "Radial burnout: " + REngine:NAME + ".".  
    stage.
	set REngine to 0.	
  }
}
if ZEngine <> 0 {
  when altitude > AtmoCeiling then {
    print "LES Jettison: " + ZEngine:NAME + ".".  
    //stage.
	// TODO - find the LES decoupler and decouple after LES ignite.
	// This is better to do as a stage event.....
	set ZEngine to 0.	
  }
}

if FairingList <> 0 {
  when altitude > AtmoCeiling then {
    for FairPart in FairingDecoupleList {
      print "Fairings decoupled: " + FairPart:NAME.
	  FairPart:GETMODULE("ModuleEnginesRF"):DOEVENT("activate engine").
      FairPart:GETMODULE("ModuleDecouple"):DOEVENT("decouple").
    }	
    for FairPart in FairingJettisonList {
      print "Fairings jettisoned: " + FairPart:NAME.	  
      FairPart:GETMODULE("ProceduralFairingDecoupler"):DOEVENT("jettison").
    }
	for FairPart in FairingDeployList {
	  print "Fairings deployed: " + FairPart:NAME.
	  FairPart:GETMODULE("ModuleProceduralFairing"):DOEVENT("deploy").
	}
  }
}

set TarAoa to 90.
until airspeed > 100 {
  lock steering to heading(TarAzi,TarAoa).
}


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
}
unlock steering.
until ((altitude > ZLMCutout)
    or (apoapsis > TarApo)) {
  // TODO - Checks to make sure we're not deviating too far from the intended course.
  wait SimDelay.
}

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
  set CurAoA to CalcAoACruise(altitude, PrevAlt, apoapsis, PrevApo, TarApo, periapsis, PrevPer, TarPer, CurAoA, MaxAoA, MinAoA, (SimDelay * 4)).
}

lock throttle to 0.
print "Launch phase complete.".

wait 5.

unlock steering.
unlock throttle.