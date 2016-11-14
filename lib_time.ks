// lib_time.ks
//   Time functions.
//   Author: Andy Cummings (@cydonian_monk)
//
@LAZYGLOBAL off.


FUNCTION PrintTTime {
  PARAMETER SecVal.
  if (1 < floor(SecVal/60)) {
    if (0 = round(mod(SecVal,60))) {
	  print "T minus " + floor(SecVal/60) + " minutes.".
	}
	else {
      print "T minus " + floor(SecVal/60) + " minutes and " + round(mod(SecVal,60)) + " seconds.".
	}
  }
  else if (1 = floor(SecVal/60)) {
    if (0 = round(mod(SecVal,60))) {
	  print "T minus " + floor(SecVal/60) + " minute.".
	}
	else {
      print "T minus " + floor(SecVal/60) + " minute and " + round(mod(SecVal,60)) + " seconds.".
	}
  }
  else {
    print "T minus " + round(mod(SecVal,60)) + " seconds.".
  }
}