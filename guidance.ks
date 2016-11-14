// Guidance.ks
//   General Kerbal OS guidance script.
//   Author: Andy Cummings (@cydonian_monk)
//
declare VarCount to 30.

declare TarApo to 200000.
declare TarPer to 195000.
declare TarHoriAlt to 73000.
declare TarAzi to 90.

declare TarAoa to 0.
declare AscentAoA to 10.
declare MinAoa to -45.
declare MaxAoA to 30.
declare TrajSlope to 90 / TarHoriAlt.
declare AtmoCeiling to 82000.
declare PrevAlt to 0.
declare PrevApo to 0.
declare REngine to 0.
declare AEngine to 0.
declare BEngine to 0.
declare CEngine to 0.
declare FairingList to list().
declare FairingDecoupleList to list().
declare FairingJettisonList to list().

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
}

until VarCount < 11
{
  if (mod(VarCount,10) = 0) {
    print "T minus " + VarCount + " seconds.".
  }
  wait 1.
  set VarCount to VarCount - 1.
}
print "Entering final launch countdown sequence.".
until VarCount < 6 {
  print "T minus " + VarCount + ".".
  wait 1.
  set VarCount to VarCount - 1.
}
print "Ignition.".
lock throttle to 1.0.
stage.
until VarCount < 1 {
  print "T minus " + VarCount + ".".
  wait 1.
  set VarCount to VarCount - 1.
}
print "Liftoff.".
stage.

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
  }
}

// Set the list of fairings to jettison.
if FairingList <> 0 {
  when altitude > AtmoCeiling then {
    for FairPart in FairingDecoupleList {
      FairPart:GETMODULE("ModuleDecouple"):DOEVENT("decouple").
      print "Fairings decoupled: " + FairPart:NAME.
    }	
    for FairPart in FairingJettisonList {
      FairPart:GETMODULE("ProceduralFairingDecoupler"):DOEVENT("jettison").
      print "Fairings jettisoned: " + FairPart:NAME.	  
    }
  }
}

set TarAoa to 90.
until airspeed > 100 {
  lock steering to heading(TarAzi,TarAoa).
}

set PrevAlt to altitude.
until apoapsis > TarApo {
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
}

print "Continuing burn. Apoapsis: " + apoapsis.

set TarAoa to AscentAoA.
set PrevAlt to altitude.
set PrevApo to apoapsis.
lock steering to heading(TarAzi,TarAoa).

set PrevAlt to altitude.
until ((periapsis + 1000) > TarPer) {
  if ((periapsis + 1000) > altitude) {
    break.
  }
//  if ((apoapsis - 25000) > TarApo) {
//    break.
//  }
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
}

lock throttle to 0.0.
print "Launch complete.".
wait 1.
unlock steering.
unlock throttle.