@LAZYGLOBAL off.

function CalcPoM {
  parameter qAltIni.
  parameter qAltCur.
  parameter qAltHori.
  parameter qTrajMult.
  parameter qPoMAlt.
  parameter qAscentPitch is 5.
  
  local NewPitch is 0.
  
  set qTrajMult to 90 / (qAltHori - qPoMAlt).

  set NewPitch to (qAltHori - (qAltCur - qPoMAlt)) * qTrajMult.
  if NewPitch < qAscentPitch {
    set NewPitch to qAscentPitch.
  }
  if NewPitch > 90 {
    set NewPitch to 90.
  }
  
  return NewPitch.
}.

function CalcTrajMult {
  parameter qAltIni.
  parameter qAltHori.
  parameter qPoMAlt.
  
  local qTrajMult is 0.

  set qTrajMult to 90 / (qAltHori - qPoMAlt).
  return qTrajMult.
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

function logT {
	parameter Statement.
	parameter GuTimestamp is time:current.
	
	print ROUND(GuTimestamp) + " | " + Statement.
}.

// from lib_navball.
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
