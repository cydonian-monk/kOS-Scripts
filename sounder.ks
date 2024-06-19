declare parameter TarAzi is 90.
declare parameter PitchASC is 90.
declare parameter HotStart is 1.

declare CurPitch to 0.
declare AltPOM to 0.
declare AEng to 0.
declare BEng to 0.

AG8 on.
lock throttle to 0.0.

list parts in CrV.
for pcheck in CrV {
  if pcheck:tag = "blocka" {
    set AEng to pcheck.
  }
  if pcheck:tag = "blockb" {
    set BEng to pcheck.
  }  
}

lock throttle to 1.0.
stage.
wait 3.
stage.

set CurPitch to 90.
lock steering to heading(TarAzi,CurPitch).

until airspeed > 100 {
  wait 0.1.
}

print "POM".
set AltPOM to altitude.

if AEng <> 0 {
  when (SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT < 50) then {
	BEng:activate.
  }
  when AEng:FLAMEOUT then {
    stage.
  }
}
if BEng <> 0 {
  when BEng:FLAMEOUT then {
    lock throttle to 0.0.
  }
}

until (altitude > 20000) {
  lock steering to heading(TarAzi,CurPitch).
  wait 0.05.
  
  set CurPitch to (90 - ((90 - PitchASC) * (altitude - AltPOM) / (20000 - AltPOM))).
  
  if CurPitch < PitchASC {
    set CurPitch to PitchASC.
  }
  if CurPitch > 90 {
    set CurPitch to 90.
  }
}

until verticalspeed < 0 {
  wait 1.
}
lock throttle to 0.0.
set ship:control:pilotmainthrottle to 0.
unlock steering.
stage.

until altitude < 2000 and airspeed < 350 {
  wait 1.
}
AG5 on.

print "END".
