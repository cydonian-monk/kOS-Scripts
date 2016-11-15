// LaunchMath.ks
//   Math-based launch script for Kerbal OS.
//   Author: Andy Cummings (@cydonian_monk)
//
//   Code assumes a vehicle designed to have a launch TWR of 1.05 to 1.1, with
//   similar ~1.0 TWRs of all upper stages.
//
//   NOTE: Remember to set your throttle to zero before running this script!

declare TarApo to 100000.
declare TarPer to 90000.
declare TarHoriAlt to 44000.
declare TarAzi to 90.
declare TarAoa to 0.
declare MinAoa to -45.
declare TrajSlope to 90 / TarHoriAlt.
declare ActiveStage to 0.
declare OrbitalStage to 3.

sas off.
lock steering to heading(90,90).

set VarCount to 10.
until VarCount = 0 {
  print "T minus " + VarCount + ".".
  wait 1.
  set VarCount to VarCount - 1.
}

lock throttle to 1.0.
print "Ignition.".
stage.
set ActiveStage to ActiveStage + 1.

// TODO AWC - Allow for fairing jettison above select atmospheric limit.
when altitude > 52000 then {
  // TODO AWC - decouple fairings.
}

// TODO AWC - Allow for hot-staging, which will need to check for fuel 
//            remaining in the current stage.
// TODO AWC - Allow for non-destructive staging. The current method will
//            explode the previous stage from exhaust, resulting in debris.

when maxthrust = 0 then {
  print "Stage " + ActiveStage + " separation: Shroud Jettison.".
// NOTE - comment out if no interstage fairing between first and second stage!  
  stage. 
  set ActiveStage to ActiveStage + 1.    
  print "Beginning Stage " + ActiveStage + " burn.".
  stage.
  if (ActiveStage < OrbitalStage) {
    preserve.
  }
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

// TODO AWC - Allow for multi-azimuth launches, such as GEO-bound launches from Canaveral.

print "Burning to Apoapsis.".
until apoapsis > TarApo {
  wait 0.1.
}


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
lock throttle to 0.
print "Target Apoapsis achieved. Drift to circularize.".


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