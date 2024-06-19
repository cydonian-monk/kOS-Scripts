declare parameter TarApo is 150000.
declare parameter TarPer is 149999.

run libmonk.ks.

sas off.
rcs off.
lock throttle to 0.0.
unlock steering.
declare TimeLAUNCH to time:seconds.

print "Orbital Targets".
print " Apoapsis: " + TarApo.
print " Periapsis: " + TarPer.
print "Current Parameters".
print " Apoapsis:" + ROUND(apoapsis).
print " Periapsis:" + ROUND(periapsis).

orbitloop(TarApo, TarPer, TimeLAUNCH).

logT("Orbital adjustment complete; apo:" + ROUND(apoapsis) + " per:" + ROUND(periapsis), time:seconds - TimeLAUNCH).
unlock steering.
unlock throttle.
logT("Operation complete.", time:seconds - TimeLAUNCH).
