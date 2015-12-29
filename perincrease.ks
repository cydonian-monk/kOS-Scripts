// perincrease.ks
//   Quick and dirty periapsis increase script for kOS.
//   Author: Andy Cummings (@cydonian_monk)
set TarPer to 130000.

if ship:apoapsis <= TarPer {
    set TarPer to ship:apoapsis.
    print "Ship apoapsis below target periapsis. Target changed to " + ship:apoapsis.
}
lock steering to ship:velocity:orbit.
wait 10.

print "Drifting to apoapsis.".
until eta:apoapsis < 10 {
  
}

print "Burning.".
set ship:control:mainthrottle to 100.
until TarPer <= ship:periapsis {
    wait 0.1.
}
set ship:control:mainthrottle to 0.
print "Throttle Off".
unlock steering.
unlock throttle.

print "Peri Increase? " + ship:apoapsis + " by " + ship:periapsis.