// lib_launch.ks
//   Functions useful during launch.
//   Author: Andy Cummings (@cydonian_monk)
//
@LAZYGLOBAL off.

FUNCTION CalcPoM {
  parameter AltCur.
  parameter AltTar.
  parameter AltPoM.

  local TrajSlope is 0.
  local NewAoA is 0.
  
  set TrajSlope to 90 / AltTar.

  // TODO AWC - Develop a better, math-based approach....
  // y(x) = (AltTar * AltCur)^0.5 + AltPoM.
  // NewAoA = y'(x) in degrees.
  // NewAoA = 1/(AltTar * AltCur)^0.5 ? 
  
  set NewAoA to (AltTar - AltCur) * TrajSlope.
  if NewAoA < AscentAoA {
    set NewAoA to AscentAoA.
  }
  if NewAoA > 90 {
    set NewAoA to 90.
  }
  
  return NewAoA.
}.

FUNCTION CalcAoA {
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

  // If we're not falling, and the apo is climbing, continue at present AoA.
  
  // If we're falling, we need to burn upwards.
  if (qAlt < qPrevAlt) {
	set NewAoA to qAoA + 0.1.
  }
  else {
    // We need to keep raising the Apo until we hit our target.
	// Once we're there, we want to keep pushing the Apo out from us, 
	// or we want to burn at Apo.
	// TODO - This code is ugly......
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
  // If we've gone over the requested limits, clip.
  if NewAoA > qMaxAoA {
    set NewAoA to qMaxAoA.
  }
  if NewAoA < MinAoa {
    set NewAoA to qMinAoa.
  } 
  return NewAoA.
}.

FUNCTION CalcAoACruise {
  parameter qAlt.
  parameter qpAlt.
  parameter qApo.
  parameter qpApo.
  parameter qtApo.
  parameter qPer.
  parameter qpPer.
  parameter qtPer.
  parameter qAoA.
  parameter qxAoA.
  parameter qnAoA.
  parameter qDelay.
  
  local NewAoA is 0.
  
  // If we're burning at apoapsis, rock on.
  if (abs(qtApo - qAlt) < 1000) {
    if (qAoA < 0) {
	  set NewAoA to qAoA + qDelay.
	}
	else if (qAoA > 0) {
	  set NewAoA to qAoA - qDelay.
	}
	return NewAoA.
  }
  // If the apo is near the target, keep rocking.
  else if (abs(qtApo - qApo) < 1000) {
    return qAoA.
  }

  // TODO AWC - Need to do something to account for excessive Apo.... We can fall and still be correct here.
  
  // If we're falling, fix it.
  if (qAlt < qpAlt) {
    set NewAoA to qAoA + qDelay.
  }
  
  // If we're here, then we're still climbing and 
  // our apo is nowhere near the target apo.
  // Keep pushing the apo.
  else {
    if (qApo < qtApo) {
	  set NewAoA to qAoA + qDelay.
	}
    else  {
	  set NewAoA to qAoA - qDelay.
	}
  }
  
  if (NewAoA < qnAoA) {
    set NewAoA to qnAoA.  
  }
  else if (NewAoA > qxAoA) {
    set NewAoA to qxAoA.
  }
  
  return NewAoA.
}.
