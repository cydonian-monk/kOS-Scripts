// landingpulse.ks
//   Simple kOS landing script for pulse-based lander.
//   Author: Andy Cummings (@cydonian_monk)
declare Stationary to 0.

rcs on.
sas off.
lock steering to (-1) * ship:velocity:surface.
wait 5.
set ship:control:mainthrottle to 1.
set ship:control:fore to 1.

until 0 {
    if Stationary > 0 {
        if 1 > alt:radar {
            print "Landing Detected".
            break.
        }
        if -1 < ship:verticalspeed {
            set ship:control:mainthrottle to 0.
            set ship:control:fore to 0.
        }
        else if 1000 < alt:radar {
            if -100 > ship:verticalspeed {
                set ship:control:fore to 1.
                set ship:control:mainthrottle to 1.          
            }
            if -30 < ship:verticalspeed {
                set ship:control:mainthrottle to 0.
                set ship:control:fore to 0.
            }
        }
        else if 100 < alt:radar {
            if -30 > ship:verticalspeed {
                set ship:control:fore to 1.
                set ship:control:mainthrottle to 1.          
            }
            if -10 < ship:verticalspeed {
                set ship:control:mainthrottle to 0.
                set ship:control:fore to 0.
            }
        }
        else if 5 < alt:radar {
            if -1 > ship:verticalspeed {
                set ship:control:fore to 1.
            }
            if -4 > ship:verticalspeed {
                set ship:control:mainthrottle to 1.          
            }
        }
    }
    else {
        if 5 > ship:surfacespeed {
            set Stationary to 1.
        }
        if 100 > ship:surfacespeed {
            set ship:control:fore to 0.
        }
    }
    lock steering to (-1) * ship:velocity:surface.
}

set ship:control:mainthrottle to 0.
set ship:control:fore to 0.
unlock steering.
rcs off.

print "Landed. Lat: " + ship:latitude + " Lon: " + ship:longitude + " Alt: " + ship:altitude.