// guidonew.ks
//   New guidance script. Fresh start.
//   Author: Andy Cummings (@cydonian_monk)
//
@LAZYGLOBAL off.

declare tApo to 150000.
declare tPer to 145000.
declare tAzi to 90.


declare FUNCTION CalcAoA {
  parameter qAlt.
  parameter qpAlt.
  parameter qApo.
  parameter qpApo.
  parameter qtApo.
  parameter qAoA.
  parameter qtAoA.
  parameter qmxAoA.
  parameter qmnAoA.
  
  local rAoA is 0.

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







// 6: Ignition. Wait for engines to spool up.
stage.
wait 5.

// 5: Liftoff.
stage.


// 4: Start POM once EAS > 100.



// 3: Maintain guided flight or allow for ZLM.





// 2: We need to continue climbing until our Apoapsis is within a selected range of the target.
//




// 1: Want to keep the Apoapsis unchanged, once reached. 
//  a: Unless we're falling, then we need to do everything we can to keep from falling.
//  b: Burning at apoapsis is the most efficient approach... when burning at an AoA of near 0 degrees.



// 0: Deploy orbital needs.

// TODO AWC - Starting from the end game.
