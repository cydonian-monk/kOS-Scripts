// landingcurve.ks
//   Simple kOS landing script for pulse-based lander.
//   Author: Andy Cummings (@cydonian_monk)

declare TRate to 1.

sas off.
lock steering to (-1) * ship:velocity:surface.

set VarCount to 10.
until VarCount = 0 {
  print "T minus " + VarCount + ".".
  wait 1.
  set VarCount to VarCount - 1.
}

lock throttle to TRate.

print "Starting descent burn...".

until -1000 > periapsis {
	lock steering to (-1) * ship:velocity:surface.
}

print "Entering first descent phase.".

until 0 > ship:verticalspeed {
	lock steering to (-1) * ship:velocity:surface.
}

print "Entering second descent phase.".

until 2000 > alt:radar {
	if 200 < ship:groundspeed {
		set TRate to 1.
	}
	else if -200 > ship:verticalspeed { 
		if 1 > TRate {
			set TRate to TRate + 0.01.
		}
	}
	else if -180 < ship:verticalspeed {
		if 0 < TRate {
			set TRate to TRate - 0.01.
		}
	}
	lock throttle to TRate.
	lock steering to (-1) * ship:velocity:surface.
}

print "Entering third descent phase.".

until 1000 > alt:radar {
	if 50 < ship:groundspeed {
		set TRate to 1.
	}
	if -30 > ship:verticalspeed { 
		if 1 > TRate {
			set TRate to TRate + 0.01.
		}
	}
	else if -25 < ship:verticalspeed {
		if 0 < TRate {
			set TRate to TRate - 0.01.
		}
	}
	lock throttle to TRate.
	lock steering to (-1) * ship:velocity:surface.
}

print "Entering third descent phase.".

until 100 > alt:radar {
	if 25 < ship:groundspeed {
		set TRate to 1.
	}
	if -12 > ship:verticalspeed { 
		if 1 > TRate {
			set TRate to TRate + 0.01.
		}
	}
	else if -10 < ship:verticalspeed {
		if 0 < TRate {
			set TRate to TRate - 0.01.
		}
	}
	lock throttle to TRate.
	lock steering to (-1) * ship:velocity:surface.	
}

print "Entering final descent phase.".

until 1 > alt:radar {
	if 10 < ship:groundspeed {
		set TRate to 1.
	}
	if -4 > ship:verticalspeed { 
		if 1 > TRate {
			set TRate to TRate + 0.01.
		}
	}
	else if -1 < ship:verticalspeed {
		if 0 < TRate {
			set TRate to TRate - 0.01.
		}
	}
	lock throttle to TRate.
	lock steering to (-1) * ship:velocity:surface.	
}

print "Landing check...".
wait 1.
until 0.1 > ship:groundspeed {
	lock steering to (-1) * ship:velocity:surface.	
}

lock throttle to 0.
sas on.
unlock steering.

print "Landed. Lat: " + ship:latitude + " Lon: " + ship:longitude + " Alt: " + ship:altitude.