// LaunchSonata.ks
//   Math-based launch script for Kerbal OS.
//   Author: Andy Cummings (@cydonian_monk)
//
//   Intended for use only with LV-04 Sonata.
//   Code assumes a vehicle designed to have a launch TWR of 1.05 to 1.1, with
//   similar ~1.0 TWRs of all upper stages.
//
//   NOTE: Remember to set your throttle to zero before running this script!

declare TarApo to 130000.
declare TarPer to 120000.
declare TarHoriAlt to 44000.
declare TarSubHoriAlt to 52000.
declare TarAzi to 90.
declare TarAoa to 0.
declare MinAoa to -45.
declare TrajSlope to 90 / TarHoriAlt.
declare ActiveStage to 0.
declare OrbitalStage to 3.

list engines in CurVessel.
for eng in CurVessel {
  set LastEngine to eng.  
}

set VarCount to 10.
until VarCount = 0 {
  print "T minus " + VarCount + ".".
  wait 1.
  set VarCount to VarCount - 1.
}

lock steering to heading(90,90).
lock throttle to 1.0.

print "Ignition.".
stage.
set ActiveStage to ActiveStage + 1.

// TODO AWC - Allow for fairing jettison above select atmospheric limit.
// TODO AWC - Allow for non-destructive staging. The current method will
//            explode the previous stage from exhaust, resulting in debris.
when LastEngine:FLAMEOUT then {
  print "Radial burnout: " + LastEngine:NAME + ".".
  stage.
  print "Stage " + ActiveStage + " separation.".
  set ActiveStage to ActiveStage + 1.
}

when altitude > 52000 then {
  // decouple fairings.
}

when maxthrust = 0 then {
  print "Stage " + ActiveStage + " separation.".
  set ActiveStage to ActiveStage + 1.
  print "Beginning Stage " + ActiveStage + " burn.".
  stage.
  if (ActiveStage <= OrbitalStage) {
    preserve.
  }
}

set TarAoa to 90.
until airspeed > 100 {
  lock steering to heading(TarAzi,TarAoa).
}

until apoapsis > TarApo - 5000 {
  if altitude > TarHoriAlt {
    break.
  }
  set TarAoa to (TarHoriAlt - altitude) * TrajSlope.
  lock steering to heading(TarAzi,TarAoa).
}

print "Burning to Apoapsis.".

until apoapsis > TarApo - 5000 {
  set TarAoa to (TarSubHoriAlt - altitude) * TrajSlope.
  if (TarAoa < -15) {
    set TarAoa to -15.
  }
  if (TarAoa > 0) {
    set TarAoa to 0.
  }
  lock steering to heading(TarAzi,TarAoa).
}

// TODO AWC - Allow for multi-azimuth launches, such as GEO-bound launches from Canaveral.

print "Target Apoapsis achieved, continuing burn.".

lock throttle to 0.11.
set PrevApo to apoapsis.
lock steering to heading(TarAzi,TarAoa).

until periapsis + 1000 > altitude {
  if apoapsis > PrevApo {
    set TarAoa to TarAoa - 1.0.
  }
  else if apoapsis < PrevApo {
    set TarAoa to TarAoA + 1.0.
  }
  set PrevApo to apoapsis.
  if TarApo + 1000 < apoapsis {
    print "Excessive over-apo.".
    break.
  }
  if TarPer - 1000 < periapsis {
    print "Excessive over-peri.".
    break.
  }
  if TarAoa < MinAoa {
    set TarAoa to MinAoa.
  }
  lock steering to heading(TarAzi,TarAoa).
  wait 0.1.
}
set TarAzi to 90.
set TarAoa to 0.
lock steering to heading(TarAzi,TarAoa).
print "Target Apoapsis achieved. Drift to circularize.".

lock steering to heading(TarAzi,TarAoa).
lock throttle to 0.

// TODO AWC - This peculiar code is to account for aerodynamic drag during ascent. 
//            Need to find a more elegant method of handling this, such as down-burns.
// TODO AWC - Allow for dynamic calculation of time to apoapsis limit. We know orbital
//            velocity and we know our ship's characteristics, should be able to determine
//            time required to complete circularization burn.
// KNOWN ISSUE - At present, the circularization burn can push the ship's apoapsis 
//               beyond desired limits if the burn is expected to complete more than 
//               25 seconds beyond reaching apoapsis. Issue can be fixed by adjusting 
//               timer, and will be addressed by dynamic calculation, as discussed above.
until eta:apoapsis < 25 {
  if apoapsis < TarPer {
    lock throttle to 0.1.
	when apoapsis > TarApo then {
	  lock throttle to 0.
	}
  }
  wait 0.1.
}

print "Circularizing.".

lock throttle to 1.0.
lock steering to heading(TarAzi,TarAoa).

until periapsis > TarPer {
  wait 0.1.
}

lock throttle to 0.
print "Launch phase complete.".

unlock steering.
unlock throttle.