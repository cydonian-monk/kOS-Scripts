// GuidanceR7.ks
//   Math-based launch script for Kerbal OS.
//   Author: Andy Cummings (@cydonian_monk)
//
//   Code assumes a vehicle designed to have a launch TWR of 1.05 to 1.1, with
//   similar ~1.0 TWRs of all upper stages.
//

declare VarCount to 30.

declare TarApo to 150000.
declare TarPer to 145000.
declare TarHoriAlt to 72000.
declare TarAzi to 90.
declare TarAoa to 0.
declare AscentAoA to 5.
declare MinAoa to -30.
declare MaxAoA to 30.
declare TrajSlope to 90 / TarHoriAlt.
declare ActiveStage to 0.
declare OrbitalStage to 3.
declare AtmoCeiling to 82000.

declare PrevAlt to 0.

declare AcceptDevApo to 12000.
declare AcceptDevPer to 0.

sas off.
lock throttle to 0.0.
lock steering to heading(90,90).

// Find all fairings that need to be jettisoned.
set FairList to SHIP:PARTSTAGGED("fairing").
// TODO AWC - run through all iterations of decouplers.... If possible to do with NREs.

// Find all the engines and select the ones we care about 
// for this launch vehicle.
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

until VarCount < 11
{
  if (mod(VarCount,10) = 0) {
    print "T minus " + VarCount + " seconds.".
  }
  wait 1.
  set VarCount  to VarCount - 1.
}
print "Entering final launch countdown sequence.".
set VarCount to 10.
until VarCount = 0 {
  print "T minus " + VarCount + ".".
  wait 1.
  set VarCount to VarCount - 1.
  if VarCount = 5 {
	print "Ignition.".
	lock throttle to 1.0.
	stage.
  }
}

print "Liftoff.".
stage.

// Set the staging events for the engines we just found.
when REngine:FLAMEOUT then {
  print "Block R burnout: " + REngine:NAME + ".".  
  stage.
  print "Booster Jettison.".
}
when AEngine:FLAMEOUT then {  print "Block A burnout:" + AEngine:NAME + ".".
  stage. 
}
when BEngine:FLAMEOUT then {
  print "Block B burnout:" + BEngine:NAME + ".".
  stage. 
}
//when CEngine:FLAMEOUT then {
//  print "Block C burnout:" + CEngine:NAME + ".".
//  stage. 
//}

// Set the event to jettison any fairings.
when altitude > AtmoCeiling then {
  for FairPart in FairList {
    //FairPart:GETMODULE("ModuleDecouple"):DOEVENT("decouple").
    FairPart:GETMODULE("ProceduralFairingDecoupler"):DOEVENT("jettison").
  }
  print "Fairings decoupled.".
}

set TarAoa to 90.
until airspeed > 100 {
  lock steering to heading(TarAzi,TarAoa).
}

until apoapsis > TarApo {
  if altitude > TarHoriAlt {
    break.
  }
  set TarAoa to (TarHoriAlt - altitude) * TrajSlope.
  if TarAoa < AscentAoA {
    set TarAoA to AscentAoA.
  }
  lock steering to heading(TarAzi,TarAoa).
}
set TarAoa to AscentAoA.
lock steering to heading(TarAzi,TarAoa).  

set PrevAlt to altitude.

print "Burning to Apoapsis.".
until apoapsis > TarApo {
  if (PrevAlt > altitude)
  {
    print "Altitude decay detected, post-Apo.".
    break.
  }
  set PrevAlt to altitude.
  wait 0.1.
}

print "Target Apoapsis achieved, continuing burn.".

set PrevApo to apoapsis.
lock steering to heading(TarAzi,TarAoa).

// TODO AWC - use percentage instead of hard-coded 
set PrevAlt to altitude.

until ((periapsis + 1000) > TarPer) {
  // If we're past the apoapsis, we need to burn upwards-ish.
  if (altitude < PrevAlt)
  {
	set TarAoa to TarAoA + 0.05.
  }
  // Otherwise we can continue with the normal script.
  else
  {
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
  if TarAoa < MinAoa {
    set TarAoa to MinAoa.
  }
  if TarAoA > MaxAoA {
    set TarAoA to MaxAoA.
  }
  lock steering to heading(TarAzi,TarAoa).
  wait 0.01. 
}

lock throttle to 0.0.
print "Launch complete.".

wait 1.

unlock steering.
unlock throttle.