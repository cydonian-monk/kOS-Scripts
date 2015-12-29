// LaunchMath.ks
//   Math-based launch script for Kerbal OS.
//   Author: Andy Cummings (@cydonian_monk)
//
//   Code assumes a vehicle designed to have a launch TWR of 1.05 to 1.1, with
//   similar ~1.0 TWRs of all upper stages.
//
//   NOTE: Remember to set your throttle to zero before running this script!

declare TarApo to 100000.
declare TarPer to 72000.
declare TarHoriAlt to 43000.
declare TarAzi to 90.
declare TarAoa to 0.
declare TrajSlope to 90 / TarHoriAlt.
declare ActiveStage to 0.
declare OrbitalStage to 2.

lock steering to heading(90,90).
lock throttle to 1.0.

print "Launching.".
stage.
set ActiveStage to ActiveStage + 1.

// TODO AWC - Allow for fairing jettison above select atmospheric limit.
// TODO AWC - Adapt for multi-staged vehicles; ex: Soyuz and STS. This will 
//            require detection of parallel stages which lose thrust.... 
//            Might be something that's better hard-coded.
// TODO AWC - Allow for hot-staging, which will need to check for fuel 
//            remaining in the current stage.
// TODO AWC - Allow for non-destructive staging. The current method will
//            explode the previous stage from exhaust, resulting in debris.
when maxthrust = 0 then {
  print "Stage " + ActiveStage + " separation.".
  //stage. 
  set ActiveStage to ActiveStage + 1.    
  print "Beginning Stage " + ActiveStage + " burn.".
  stage.
  if (ActiveStage < OrbitalStage) {
    preserve.
  }
}

// TODO AWC - airspeed?
set TarAoa to 90.
until ship:velocity:surface:mag > 100 {
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

// TODO AWC - Allow for down-burns. (Where heading goes below 0 degrees.) 
//            Not important in stock, but in RSS/RO this will allow for burns to 
//            apoapsis without wasting ignitions.

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

print "Launch phase complete.".

unlock steering.
unlock throttle.