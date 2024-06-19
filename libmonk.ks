@LAZYGLOBAL off.

function logT {
	parameter Statement.
	parameter GuTimestamp is time:current.
	
	print "T+" + ROUND(GuTimestamp) + " | " + Statement.
}.

function orbadj {
  declare parameter TarApo is 150000.
  declare parameter TarPer is 149999.
  declare parameter OIBMaxPitch to 15.
  declare parameter OIBMinPitch to -15.
  declare parameter TimeLAUNCH to 0.

  local PitchCUR to 0.
  local PrevAlt to 0.
  local PrevApo to 0.
  local PrevPer to 0.
  local PrevTime to 0.
  local CurTime to 0.

  if (TarPer > TarApo) {
    print "Target Periapsis greater than Target Apoapsis. Swapping.".
    print "Please review values for correctness.".
    local tTar is TarApo.
    set TarApo to TarPer.
    set TarPer to tTar.
  }

  local tPID is list (PitchCUR,0,0,0).

  // if burning near apoapsis
  // then we're working on periapsis
  if ((altitude * 1.02) > apoapsis) {
  
    set PrevTime to time:seconds.
    set PrevApo to apoapsis.
    set PrevPer to periapsis.
    set PrevAlt to altitude. 
  
    if (TarPer > periapsis) {
      print "Raise Peri".
      RCS on.
      local tBear to CalcHeading(ship,prograde).
	  lock steering to heading(tBear,PitchCUR).
	  wait 2.
	  lock throttle to 1.0. 
  
	  if (TarPer > apoapsis) {
	    print "Raise Peri above Apo".
	    until (apoapsis + 5 >= TarApo) {
		  if (apoapsis > (TarApo * 1.1)) {
		    logT("EX-APO apo:" + ROUND(apoapsis), time:seconds - TimeLAUNCH).
		    break.
		  }
		  lock steering to heading(tBear,PitchCUR).
		  wait 0.1.
		  set CurTime to time:seconds.
		  set tPID to CalcPitch(tPID, PitchCUR, altitude, PrevAlt, apoapsis, PrevApo, CurTime, PrevTime, TarApo, OIBMaxPitch, OIBMinPitch).
		  set PitchCUR to tPID[0].
		  set PrevTime to CurTime.
		  set PrevApo to apoapsis.
		  set PrevAlt to altitude.    		
	    }		
	  }
	  else {
	    print "Raise Peri below Apo".
	    until (periapsis + 5 >= TarPer) {
		  if (apoapsis > (TarApo * 1.1)) {
		    logT("EX-APO apo:" + ROUND(apoapsis), time:seconds - TimeLAUNCH).
		    break.
		  }
		  lock steering to heading(tBear,PitchCUR).
		  wait 0.1.
		  set CurTime to time:seconds.
		  set tPID to CalcPitch(tPID, PitchCUR, altitude, PrevAlt, periapsis, PrevPer, CurTime, PrevTime, TarPer, OIBMaxPitch, OIBMinPitch).
		  set PitchCUR to tPID[0].
		  set PrevTime to CurTime.
		  set PrevApo to apoapsis.
		  set PrevAlt to altitude.    		
	    }
	  }
    }
    else if (periapsis = TarPer) {
	  print "Peri at Target".
    }
    else {
      print "Lower Peri".
      RCS on.
      local tBear to CalcHeading(ship,retrograde).
	  lock steering to heading(tBear,PitchCUR).
	  wait 2.
	  lock throttle to 1.0.
	
	  until (periapsis - 5 <= TarPer) {
		if (apoapsis > (TarApo * 1.1)) {
		  logT("EX-APO apo:" + ROUND(apoapsis), time:seconds - TimeLAUNCH).
		  break.
		}
	    lock steering to heading(tBear,PitchCUR).
	    wait 0.1.
	    set CurTime to time:seconds.
	    set tPID to CalcPitch(tPID, PitchCUR, altitude, PrevAlt, apoapsis, PrevPer, CurTime, PrevTime, TarPer, OIBMaxPitch, OIBMinPitch).
	    set PitchCUR to tPID[0].
	    set PrevTime to CurTime.
	    set PrevPer to periapsis.
	    set PrevAlt to altitude.    		
	  }  
    }
  }
  // otherwise we're not anywhere near apoapsis
  // and need to determine what to work on
  else {
 
    set PrevTime to time:seconds.
    set PrevApo to apoapsis.
    set PrevPer to periapsis.
    set PrevAlt to altitude.
  
    if (apoapsis > TarApo) {
      print "Lower Apo".
      RCS on.
      local tBear to CalcHeading(ship,retrograde).
	  lock steering to heading(tBear,PitchCUR).
	  wait 2.	  
	  lock throttle to 1.0.
	
	  if (TarApo < periapsis) {
  	    print "Lower Apo below Peri".
	    until (periapsis + 5 >= TarApo) {
		  lock steering to heading(tBear,PitchCUR).
		  wait 0.1.
		  set CurTime to time:seconds.
		  set tPID to CalcPitch(tPID, PitchCUR, altitude, PrevAlt, periapsis, PrevPer, CurTime, PrevTime, TarPer, OIBMaxPitch, OIBMinPitch).
		  set PitchCUR to tPID[0].
		  set PrevTime to CurTime.
		  set PrevPer to periapsis.
		  set PrevAlt to altitude.	  
	    }
	  }
	  else {
	    print "Lower Apo Above Peri".
	    until (apoapsis + 5 <= TarApo) {
		  lock steering to heading(tBear,PitchCUR).
		  wait 0.1.
		  set CurTime to time:seconds.
		  set tPID to CalcPitch(tPID, PitchCUR, altitude, PrevAlt, apoapsis, PrevApo, CurTime, PrevTime, TarApo, OIBMaxPitch, OIBMinPitch).
		  set PitchCUR to tPID[0].
		  set PrevTime to CurTime.
		  set PrevApo to apoapsis.
		  set PrevAlt to altitude.    		
	    }
	  }
    }
    else if (apoapsis = TarApo) {
	  print "Apo at Target Apo".
    }  
    else {
      print "Raise Apo".
      RCS on.
      local tBear to CalcHeading(ship,prograde).
	  lock steering to heading(tBear,PitchCUR).
	  wait 2.
	  lock throttle to 1.0.
	
	  until (apoapsis + 5 >= TarApo) {
		if (apoapsis > (TarApo * 1.1)) {
		  logT("EX-APO apo:" + ROUND(apoapsis), time:seconds - TimeLAUNCH).
		  break.
		}	  
	    lock steering to heading(tBear,PitchCUR).
	    wait 0.1.
	    set CurTime to time:seconds.
	    set tPID to CalcPitch(tPID, PitchCUR, altitude, PrevAlt, apoapsis, PrevApo, CurTime, PrevTime, TarApo, OIBMaxPitch, OIBMinPitch).
	    set PitchCUR to tPID[0].
	    set PrevTime to CurTime.
	    set PrevApo to apoapsis.
	    set PrevAlt to altitude.    		
	  }
    }  
  }

  lock throttle to 0.0.
  set ship:control:pilotmainthrottle to 0.
  RCS off.
}

function CalcPoM {
  parameter qAltCUR.
  parameter qAltHOR.
  parameter qAltPOM.
  parameter qPitchTAR is 0.
  
  local PitchNEW is 0.
  
  if qPitchTAR > 90 {
    set qPitchTAR to 90.
  }
  
  set PitchNEW to (90 - ((90 - qPitchTAR) * (qAltCUR - qAltPOM) / (qAltHOR - qAltPOM))).
  if PitchNEW > 90 {
    return 90.
  }
  if PitchNEW < -90 {
    return -90.
  }
  return PitchNEW.
}.

function CalcPitch {
  parameter qPID.
  parameter qPitch.
  parameter qAlt.
  parameter qPrevAlt.
  parameter qApo.
  parameter qPrevApo.
  parameter qTarApo.
  parameter qCurTime.
  parameter qPrevTime.  
  parameter qMaxPitch is 45.
  parameter qMinPitch is -60.
  
  local dTime is 0.
  set dTime to qCurTime - qPrevTime.

  if (dTime = 0) {
    return qPID.
  }
  
  local NewPitch is 0.
  local dApo is 0.
  local iApo is 0.  
  local qPitch is qPID[0].
  local dOldApo is qPID[1].
  local iOldApo is qPID[2].
  local OldPar is qPID[3].
  
  local Par is qTarApo - qApo.
  local dPar is (Par - OldPar) / dTime.
  
  
  set dApo to (qApo - qPrevApo) / dTime.
  set iApo to iOldApo + (Par * dTime).
  
  if (qAlt < qPrevAlt) {
	set NewPitch to qPitch + (0.3 * MIN(ABS(Par) / 100, 1)).
  }
  else if (Par < 0) {
    if (dApo < 0) {
      set NewPitch to qPitch.
	}
	else {
	  set NewPitch to qPitch + (1 * MAX(Par / 100, -1)).
	}
  }  
  else if (dApo < 0) {
	set NewPitch to qPitch + (0.1 * MIN(Par / 100, 1)).
  }
  else if (Par < ((qApo - qPrevApo) * 100)) {
	set NewPitch to qPitch - (0.25 * MIN(ABS(Par) / 100, 1)).
  }  
  else {
	set NewPitch to qPitch.
  }
  
  if NewPitch > qMaxPitch {
    set NewPitch to qMaxPitch.
  }
  if NewPitch < qMinPitch {
    set NewPitch to qMinPitch.
  } 
  
  set qPID[0] to NewPitch.
  set qPID[1] to dApo.
  set qPID[2] to iApo.
  set qPID[3] to Par.
  return qPID.
}.

function orbitloop {
  parameter TarApo is 0.
  parameter TarPer is 0.
  parameter TimeLAUNCH is 0.

  until (ABS(apoapsis - TarApo) < 1000) and (ABS(periapsis - TarPer) < 1000) {
    if (verticalspeed < 0)
    {
      lock throttle to 0.0.
      logT("COAST to periapsis: " + ROUND(periapsis), time:seconds - TimeLAUNCH).
      until ((altitude - 10) < periapsis) {
	    wait 1.
      }
	  if ABS(apoapsis - TarApo) >= 1000 {
        orbadj(TarApo,TarPer,20,-20,TimeLAUNCH).
	  }
	  wait 5.
    }
    else if (verticalspeed > 0) {
      lock throttle to 0.0.
      logT("COAST to apoapsis: " + ROUND(apoapsis), time:seconds - TimeLAUNCH).
      until ((altitude + 10) > apoapsis) {
        wait 1.
      }
	  if ABS(periapsis - TarPer) >= 1000 {
	    orbadj(TarApo,TarPer,20,-20,TimeLAUNCH).
	  }
	  wait 5.
    }
    else {
      logT("Indeterminate position.", time:seconds - TimeLAUNCH).
	  wait 1.
    }
  }
}

// from KSLib lib_navball.
// https://github.com/KSP-KOS/KSLib
// Copyright © 2015,2017,2019,2023 KSLib team 
// Lic. MIT
function CalcHeading {
  parameter ves is ship.
  parameter thing is "x".

  local pointing is ves:facing:forevector.
  if not thing:istype("string") {
    set pointing to type_to_vector(ves,thing).
  }

  local east is vcrs(ves:up:vector, ves:north:vector).

  local trig_x is vdot(ves:north:vector, pointing).
  local trig_y is vdot(east, pointing).
  local trig_z is vdot(ves:up:vector, pointing).

  local qheading is arctan2(trig_y, trig_x).
  if qheading < 0 {
    set qheading to 360 + qheading.
  }

  return qheading.
}

// from KSLib lib_navball.
// https://github.com/KSP-KOS/KSLib
// Copyright © 2015,2017,2019,2023 KSLib team 
// Lic. MIT
function type_to_vector {
  parameter ves,thing.
  if thing:istype("vector") {
    return thing:normalized.
  } else if thing:istype("direction") {
    return thing:forevector.
  } else if thing:istype("vessel") or thing:istype("part") {
    return thing:facing:forevector.
  } else if thing:istype("geoposition") or thing:istype("waypoint") {
    return (thing:position - ves:position):normalized.
  } else {
    print "type: " + thing:typename + " is not recognized by lib_navball".
  }
}
