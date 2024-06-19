// guido.ks
//   Small byte count launch script.
//   Author: Andy Cummings (@cydonian_monk)
//
declare VarCount to 2.
declare TarApo to 120000.
declare TarPer to 72000.
declare TarHoriAlt to 32000.
declare TarAzi to 90.
declare AscentAoA to 20.
declare MinAoA to -45.
declare MaxAoA to 30.

declare FUNCTION CalcPoM {
  parameter AltCur.
  parameter AltTar.
  parameter AltPoM.

  local TrajSlope is 0.
  local NewAoA is 0.
  
  set TrajSlope to 90 / AltTar.

  set NewAoA to (AltTar - AltCur) * TrajSlope.
  if NewAoA < AscentAoA {
    set NewAoA to AscentAoA.
  }
  if NewAoA > 90 {
    set NewAoA to 90.
  }
  
  return NewAoA.
}.

declare FUNCTION CalcAoA {
  parameter qAlt.
  parameter qPrevAlt.
  parameter qApo.
  parameter qPrevApo.
  parameter qTarApo.
  parameter qAoA.
  parameter qTarAoA.
  parameter qMaxAoA.
  parameter qMinAoA.
  
  local NewAoA is 0.

  if (qAlt < qPrevAlt) {
	set NewAoA to qAoA + 0.1.
  }
  else {
	if (qApo > qTarApo) {
      set NewAoA to qAoA - 0.1.
	}
	else {
  	  if (qApo > qPrevApo) {
        set NewAoA to qAoA.
	  }	
	  else {
	    set NewAoA to qAoA + 0.1.
	  }
    }	
  }
  if NewAoA > qMaxAoA {
    set NewAoA to qMaxAoA.
  }
  if NewAoA < MinAoa {
    set NewAoA to qMinAoa.
  } 
  return NewAoA.
}.

declare PrevAlt to 0.
declare PrevApo to 0.
declare REngine to 0.
declare AEngine to 0.
declare BEngine to 0.
declare CEngine to 0.

when apoapsis > TarApo then {
  set AscentAoA to 1.
}
when (altitude > (TarApo * 0.98)) then { 
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
    stage.
  }
}
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    stage.
  }
}
if BEngine <> 0 {
  when BEngine:FLAMEOUT then {
    stage.
  }
}
if CEngine <> 0 {
  when CEngine:FLAMEOUT then {
    stage.
  }
}

lock throttle to 1.0.
stage.
until VarCount < 1 {
  wait 1.
  set VarCount to VarCount - 1.
}
stage.

set CurAoA to 90.
until airspeed > 100 {
  lock steering to heading(TarAzi,CurAoA).
}
print "POM".
until apoapsis > TarApo {
  set CurAoA to CalcPoM(altitude, TarHoriAlt, 0).
  
  lock steering to heading(TarAzi,CurAoA).
 
  wait 0.02.
}
unlock steering.
until ((altitude > TarHoriAlt)
    or (apoapsis > TarApo)) {
  wait 0.5.
}
print "RGF " + apoapsis.
set CurAoA to AscentAoA.
until (periapsis > TarPer) {
  lock steering to heading(TarAzi,CurAoA).
  if ((periapsis + 1000) > altitude) {
    print "TPA".
    break.
  }
  if (apoapsis > (TarApo * 1.5)) {
    print "EOA".
	break.
  }
  set PrevApo to apoapsis.
  set PrevAlt to altitude.
  wait 0.02.
  set CurAoA to CalcAoA(altitude, PrevAlt, apoapsis, PrevApo, TarApo, CurAoA, AscentAoA, MaxAoA, MinAoA).
}
lock throttle to 0.0.
print "Launch complete.".
AG10 on.
AG7 on.
wait 1.
unlock steering.
unlock throttle.

// PROGRAM EXIT \\