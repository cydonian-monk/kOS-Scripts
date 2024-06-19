declare parameter TarApo is 150000.
declare parameter TarPer is 149999.
declare parameter OIBMaxPitch to 15.
declare parameter OIBMinPitch to -15.

run libmonk.ks.

declare CurPitch to 0.

declare PrevAlt to 0.
declare PrevApo to 0.
declare PrevPer to 0.
declare PrevTime to 0.
declare CurTime to 0.
declare LaunchTime to 0.

sas off.
rcs off.
lock throttle to 0.0.
set LaunchTime to time:seconds.

if (TarPer > TarApo) {
  print "Target Periapsis greater than Target Apoapsis. Swapping.".
  print "Please review values for correctness.".
  local tTar is TarApo.
  set TarApo to TarPer.
  set TarPer to tTar.
}

print "Orbital Targets".
print " Apoapsis: " + TarApo.
print " Periapsis: " + TarPer.

print "Current Parameters".
print " Apoapsis:" + apoapsis. 
print " Periapsis:" + periapsis.
logT("COAST", time:seconds - LaunchTime).

declare tPID is list (CurPitch,0,0,0).

if (verticalspeed < 0) {
  until (altitude - 10 < periapsis) {
    wait 0.1.
  }
  logT("OAB at Periapsis", time:seconds - LaunchTime).
  set PrevTime to time:seconds.
  set PrevApo to apoapsis.
  set PrevPer to periapsis.
  set PrevAlt to altitude.
  
  if (apoapsis > TarApo) {
    print "Lower Apo".
    RCS on.
    lock steering to retrograde.
	wait 2.
    local tBear to CalcHeading(ship,retrograde).
	lock throttle to 1.0.
	
	if (TarApo < periapsis) {
	  print "Lower Apo below Peri".
	  until ((periapsis + 1 > TarApo) and (altitude + 10 > apoapsis) ) {
		lock steering to heading(tBear,CurPitch).
		wait 0.1.
		set CurTime to time:seconds.
		set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, periapsis, PrevPer, CurTime, PrevTime, TarPer, OIBMaxPitch, OIBMinPitch).
		set CurPitch to tPID[0].
		set PrevTime to CurTime.
		set PrevPer to periapsis.
		set PrevAlt to altitude.    		
	  }	
	
	}
	else {
	  print "Lower Apo Above Peri".
	  until (apoapsis + 1 <= TarApo) {
		lock steering to heading(tBear,CurPitch).
		wait 0.1.
		set CurTime to time:seconds.
		set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, CurTime, PrevTime, TarApo, OIBMaxPitch, OIBMinPitch).
		set CurPitch to tPID[0].
		set PrevTime to CurTime.
		set PrevApo to apoapsis.
		set PrevAlt to altitude.    		
	  }
	}
  }
  else if (apoapsis = TarApo) {
	print "Apo at Target Apo".
  }  
  else {
    print "Raise Apo".
    RCS on.
    lock steering to prograde.
	wait 2.
    local tBear to CalcHeading(ship,prograde).
	lock throttle to 1.0.
	
	until (apoapsis + 1 > TarApo) {
	  lock steering to heading(tBear,CurPitch).
	  wait 0.1.
	  set CurTime to time:seconds.
	  set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, CurTime, PrevTime, TarApo, OIBMaxPitch, OIBMinPitch).
	  set CurPitch to tPID[0].
	  set PrevTime to CurTime.
	  set PrevApo to apoapsis.
	  set PrevAlt to altitude.    		
	}
  }
}
else {
  until (altitude + 10 > apoapsis) {
    wait 0.1.
  }
  logT("OAB at Apoapsis", time:seconds - LaunchTime).
  set PrevTime to time:seconds.
  set PrevApo to apoapsis.
  set PrevPer to periapsis.
  set PrevAlt to altitude. 
  
  if (TarPer > periapsis) {
    print "Raise Peri".
    RCS on.
    lock steering to prograde.
	wait 2.
    local tBear to CalcHeading(ship,prograde).
	lock throttle to 1.0. 
  
	if (TarPer > apoapsis) {
	  print "Raise Peri above Apo".
	  until ((apoapsis + 1 > TarApo) and (altitude - 10 < periapsis)) {
		lock steering to heading(tBear,CurPitch).
		wait 0.1.
		set CurTime to time:seconds.
		set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, CurTime, PrevTime, TarApo, OIBMaxPitch, OIBMinPitch).
		set CurPitch to tPID[0].
		set PrevTime to CurTime.
		set PrevApo to apoapsis.
		set PrevAlt to altitude.    		
	  }	
	
	}
	else {
	  print "Raise Peri below Apo".
	  until (periapsis + 1 >= TarPer) {
		lock steering to heading(tBear,CurPitch).
		wait 0.1.
		set CurTime to time:seconds.
		set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, periapsis, PrevPer, CurTime, PrevTime, TarPer, OIBMaxPitch, OIBMinPitch).
		set CurPitch to tPID[0].
		set PrevTime to CurTime.
		set PrevApo to apoapsis.
		set PrevAlt to altitude.    		
	  }
	}
  }
  else if (periapsis = TarPer) {
	print "Peri at Target Peri".
  }
  else {
    print "Lower Peri".
    RCS on.
    lock steering to retrograde.
	wait 2.
    local tBear to CalcHeading(ship,retrograde).
	lock throttle to 1.0.
	
	until (periapsis - 1 < TarPer) {
	  lock steering to heading(tBear,CurPitch).
	  wait 0.1.
	  set CurTime to time:seconds.
	  set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevPer, CurTime, PrevTime, TarPer, OIBMaxPitch, OIBMinPitch).
	  set CurPitch to tPID[0].
	  set PrevTime to CurTime.
	  set PrevPer to periapsis.
	  set PrevAlt to altitude.    		
	}  
  }
}

lock throttle to 0.0.
set ship:control:pilotmainthrottle to 0.
RCS off.
logT("Orbital adjustment complete.", time:seconds - LaunchTime).
print " apo:" + apoapsis + " per:" + periapsis.
unlock steering.
unlock throttle.
logT("Operation complete.", time:seconds - LaunchTime).
