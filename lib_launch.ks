// lib_launch.ks
//   Functions useful during launch.
//   Author: Andy Cummings (@cydonian_monk)
//
@LAZYGLOBAL off.

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