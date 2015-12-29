// apoincrease.ks
//   Quick and dirty apoapsis increase script for kOS.
//   Author: Andy Cummings (@cydonian_monk)
set TarApo to 130000.

if ship:periapsis >= TarApo {
    set TarApo to ship:periapsis.
    print "Ship periapsis above target apoapsis. Target changed to " + ship:periapsis.
}
lock steering to ship:velocity:orbit.
wait 10.

print "Drifting to apoapsis.".
until eta:apoapsis < 10 {
  
}

print "Burning.".
set ship:control:mainthrottle to 100.
until TarApo <= ship:apoapsis {
    wait 0.1.
}
set ship:control:mainthrottle to 0.
print "Throttle Off".
unlock steering.
unlock throttle.

print "Apo Increase? " + ship:apoapsis + " by " + ship:periapsis.