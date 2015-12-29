// capture.ks
//   Quick and dirty capture script for kOS.
//   Author: Andy Cummings (@cydonian_monk)
if TarApo = 0 {
    set TarApo to 50000.
}
if ship:periapsis >= TarApo {
    set TarApo to ship:periapsis.
    print "Ship periapsis above target apoapsis. Target changed to " + ship:periapsis.
}
lock steering to (-1) * ship:velocity:orbit.
wait 10.
print "Throttle to Max".
set ship:control:mainthrottle to 100.
until TarApo >= ship:apoapsis {
    wait 0.1.
}
set ship:control:mainthrottle to 0.
print "Throttle Off".

print "Captured? " + ship:apoapsis + " by " + ship:periapsis.