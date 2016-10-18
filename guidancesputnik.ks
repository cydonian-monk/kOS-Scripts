// GuidanceR7.ks
//   Math-based launch script for Kerbal OS.
//   Author: Andy Cummings (@cydonian_monk)
//
//   Code assumes a vehicle designed to have a launch TWR of 1.05 to 1.1, with
//   similar ~1.0 TWRs of all upper stages.
//

declare TarApo to 220000.
declare TarPer to 200000.
declare TarHoriAlt to 82000.
declare TarAzi to 90.
declare TarAoa to 0.
declare MinAoa to -90.
declare TrajSlope to 90 / TarHoriAlt.
declare ActiveStage to 0.
declare OrbitalStage to 3.

declare AcceptDevApo to 12000.
declare AcceptDevPer to 0.

set VarCount to 10.

sas off.
lock throttle to 0.0.
lock steering to heading(90,90).

until VarCount < 11
{
  if (mod(VarCount,10) = 0) {
    print "T minus " + VarCount + " seconds.".
  }
  wait 1.
  set VarCount  to VarCount - 1.
}

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

print "liftoff.".
stage.

list engines in CurVessel.
for eng in CurVessel {  if eng:name = "rn.r7.bvgd.engine" {    set LastEngine to eng.    }}

when LastEngine:FLAMEOUT then {
  print "Radial burnout: " + LastEngine:NAME + ".".  
  stage.
  print "Booster Jettison.".
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
  lock steering to heading(TarAzi,TarAoa).
}
set TarAoa to 0.
lock steering to heading(TarAzi,TarAoa).  

print "Burning to Apoapsis.".
until apoapsis > TarApo {
  wait 0.1.
}

print "Target Apoapsis achieved, continuing burn.".

set PrevApo to apoapsis.
lock steering to heading(TarAzi,TarAoa).

// TODO AWC - use percentage instead of hard-coded 

// This is the culprit.....
//until (((periapsis + 1000) > TarPer)
//    or ((apoapsis - AcceptDevApo) > TarApo)){
until ((periapsis + 1000) > TarPer) {
  if ((apoapsis > PrevApo)
   or (apoapsis > TarApo + 1000)) {
    set TarAoa to TarAoa - 0.05.
  }
  else if ((apoapsis < PrevApo)
         or (apoapsis < TarApo - 1000)) {
    set TarAoa to TarAoA + 0.05.
  }
  set PrevApo to apoapsis.
  if TarAoa < MinAoa {
    set TarAoa to MinAoa.
  }
  lock steering to heading(TarAzi,TarAoa).
  wait 0.01. // TODO AWC - Too many samples?
}

lock throttle to 0.0.
print "Launch complete.".

wait 5.
print "Fairing cap jettison.".
stage.
wait 10.
print "Payload deployment.".
stage.


unlock steering.
unlock throttle.