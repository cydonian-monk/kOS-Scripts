// landingcurve.ks
//   Simple kOS landing script for pulse-based lander.
//   Author: Andy Cummings (@cydonian_monk)

// Function to manage landing.
// 		DescentBurn(AltCutOff, SpdVertical[, SpdGround]).
//			AltCutoff - Minimum Altitude for Burn.
declare function DescentBurn {
	parameter AltCutOff.
	parameter SpdVertical.
	parameter SpdGround.
	
	declare ThrVal to 1.
	
	if 0 = SpdGround {
		Set SpdGround to SpdVertical.
	}

	print "Descent until " + AltCutoff + " Vertical Speed " + SpdVertical + " Ground Speed " + SpdGround.
	
	until AltCutOff > alt:radar {
		if SpdGround < ship:groundspeed {
			set ThrVal to 1.
		}
		else if (-1.05 * SpdVertical) > ship:verticalspeed { 
			if 1 > ThrVal {
				set ThrVal to ThrVal + 0.01.
			}
		}
		else if (-0.95 * SpdVertical) < ship:verticalspeed {
			if 0 < ThrVal {
				set ThrVal to ThrVal - 0.01.
			}
		}
		lock throttle to ThrVal.
		lock steering to (-1) * ship:velocity:surface.
		
		if ship:status = "LANDED" {
			print "Landing detected...".
			return.
		}
	}

	return.
}.

sas off.
lock steering to (-1) * ship:velocity:surface.

set VarCount to 10.
until VarCount = 0 {
  print "T minus " + VarCount + ".".
  wait 1.
  set VarCount to VarCount - 1.
}

lock throttle to 1.0.

print "Starting de-orbit burn...".

until -1000 > periapsis {
	lock steering to (-1) * ship:velocity:surface.
}

print "Entering descent drift phase.".

until 0 > ship:verticalspeed {
	lock steering to (-1) * ship:velocity:surface.
}

print "Entering descent phase.".

DescentBurn(3000, 200, 300).
DescentBurn(2000, 30, 50).
DescentBurn(100, 25, 10).

print "Entering final descent phase.".

DescentBurn(0, 2, 10).

print "Validating landing...".
lock throttle to 0.
wait 1.
until 0.3 > ship:groundspeed {
	lock steering to heading(0,0).
}

lock throttle to 0.
sas on.
unlock steering.

print "Landed. Lat: " + ship:latitude + " Lon: " + ship:longitude + " Alt: " + ship:altitude.


