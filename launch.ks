declare parameter TarApo is 80000.
declare parameter TarPer is 79999.
declare parameter TarAzi is 90.
declare parameter hotstart is 1.
declare parameter relight is 0.

run libmonk.ks.

declare VarCount to 10.
declare TarHoriAlt is 33000.
declare CurPitch to 0.
declare AscentPitch to 10.
declare AscentMaxPitch to 20.
declare AscentMinPitch to -20.
declare OIBPitch to 0.
declare OIBMaxPitch to 45.
declare OIBMinPitch to -45.
declare ClearAlt to 150.
declare TarBUGFAlt to 8000.
declare FairAlt to 60000.
declare IgnSec to 3.
declare ApoRatio to 1.05.

declare AltIni to 0.
declare POMAlt to 0.
declare TrajMult to 0.
declare PrevAlt to 0.
declare PrevApo to 0.
declare PrevTime to 0.
declare CurTime to 0.
declare LaunchTime to 0.

declare REngine to 0.
declare AEngine to 0.
declare BEngine to 0.
declare CEngine to 0.
declare PFairing1 to 0.
declare PFairing2 to 0.
declare tRoll to 0.

declare currstage to 0.

sas off.
lock throttle to 0.0.

list parts in CurVessel.
for pcheck in CurVessel {
  if pcheck:tag = "blockr" {    
    set REngine to pcheck.    
  }
  if pcheck:tag = "blocka" {
    set AEngine to pcheck.
  }
  if pcheck:tag = "blockb" {
    set BEngine to pcheck.
  }  
  if pcheck:tag = "blockc" {
    set CEngine to pcheck.
  }    
  if pcheck:tag = "fairing1" {
	set PFairing1 to pcheck.
  }
  if pcheck:tag = "fairing2" {
	set PFairing2 to pcheck.
  }
}

if REngine <> 0 {
  when REngine:FLAMEOUT then {
    stage.
	logT("RSEP", time:seconds - LaunchTime).
	print " alt:" + altitude.
  }
}
if AEngine <> 0 {
  when ((hotstart > 0) and (currstage > 0) and (SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT < 100)) then {
    logT("dV triggered BlockB hot start" + SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT, time:seconds - LaunchTime).
	BEngine:activate.
  }
  when AEngine:FLAMEOUT then {
    stage.
	RCS on.
	logT("ASEP", time:seconds - LaunchTime).
	set currstage to 2.
	print " alt:" + altitude.
  }
}
if BEngine <> 0 {
  when BEngine:FLAMEOUT then {
    stage.
	logT("BSEP", time:seconds - LaunchTime).
	set currstage to 3.
	print " alt:" + altitude.
  }
}
if CEngine <> 0 {
  when CEngine:FLAMEOUT then {
    stage.
	logT("CSEP", time:seconds - LaunchTime).
	set currstage to 4.
	print " alt:" + altitude.
  }
}
if PFairing1 <> 0 {
  when altitude > FairAlt then {
    PFairing1:GetModule("ProceduralFairingDecoupler"):DoEvent("jettison fairing").
	logT("FAIR", time:seconds - LaunchTime).
	print " alt:" + altitude.
  }
}
if PFairing2 <> 0 {
  when altitude > FairAlt then {
    PFairing2:GetModule("ProceduralFairingDecoupler"):DoEvent("jettison fairing").
	logT("FAIR", time:seconds - LaunchTime).
	print " alt:" + altitude.
  }
}

print "Entering Terminal Count".

if (TarPer > TarApo) {
  print "Target Periapsis greater than Target Apoapsis. Swapping.".
  print "Please review values for correctness.".
  local tTar is TarApo.
  set TarApo to TarPer.
  set TarPer to tTar.
}

print "Launch Targets".
print " Apoapsis: " + TarApo.
print " Periapsis: " + TarPer.
print " Azimuth: " + TarAzi.

set AltIni to altitude.
until VarCount <= IgnSec { 
  print VarCount.
  wait 1.
  set VarCount to VarCount - 1.
}
print "Ignition".
lock throttle to 1.0.
stage.
until VarCount < 1 {
  print VarCount.
  wait 1.
  set VarCount to VarCount - 1.
}
stage.
set LaunchTime to time:seconds.
logT("Liftoff",LaunchTime-LaunchTime).

set CurPitch to 90.
set tRoll to ship:facing:roll.
lock steering to heading(TarAzi,CurPitch,tRoll).

until altitude > (AltIni + ClearAlt) {
  wait 0.1.
}

set currstage to 1.

set tRoll to 0.
logT("ROLL", time:seconds - LaunchTime).
print " alt:" + altitude.
lock steering to heading(TarAzi,CurPitch,tRoll).

until airspeed > 100 {
  wait 0.1.
}

logT("POM", time:seconds - LaunchTime).
set POMAlt to altitude.
print " alt:" + POMAlt.
set TrajMult to CalcTrajMult(POMAlt, TarHoriAlt, POMAlt).
until ((apoapsis > TarPer) 
	or (altitude > TarHoriAlt)) {
  lock steering to heading(TarAzi,CurPitch). 
  wait 0.05.
  set CurPitch to CalcPoM(POMAlt, altitude, TarHoriAlt, TrajMult, POMAlt, AscentPitch).
}

logT("RGF", time:seconds - LaunchTime).
print " apo:" + apoapsis + " per:" + periapsis.

set CurPitch to AscentPitch.
set PrevTime to time:seconds.
set PrevApo to apoapsis.
set PrevAlt to altitude.  

declare tPID is list (CurPitch,0,0,0).

until (apoapsis > TarPer) {
  lock steering to heading(TarAzi,CurPitch).
  wait 0.1.
  set CurTime to time:seconds.
  set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, TarPer, CurTime, PrevTime, AscentMaxPitch, AscentMinPitch).
  set CurPitch to tPID[0].
  set PrevTime to CurTime.
  set PrevApo to apoapsis.
  set PrevAlt to altitude.
}

logT("OIB", time:seconds - LaunchTime).
print " apo:" + apoapsis + " per:" + periapsis.
lock throttle to 0.5.

set CurPitch to OIBPitch.
set PrevTime to time:seconds.
set PrevApo to apoapsis.
set PrevAlt to altitude.    

until (periapsis >= TarPer) {
  lock steering to heading(TarAzi,CurPitch).
  if (((periapsis + 10) > altitude) 
   and (apoapsis > TarApo))  {
	logT("OIB EX-PER per:" + periapsis, time:seconds - LaunchTime).
	break.
  }
  //if (((currstage = 1) and (BEngine <> 0)) or ((currstage = 2) and (CEngine <> 0))) {
    if (apoapsis > (TarApo * ApoRatio)) {
      logT("OIB EX-APO apo:" + apoapsis, time:seconds - LaunchTime).
	  break.
    }
  //}
  if (apoapsis > (TarApo * 0.95)) {
	lock throttle to 0.2.
  }
  if (verticalspeed < 0) {
	lock throttle to 1.0.
  }
  wait 0.1.
  set CurTime to time:seconds.  
  set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, TarApo, CurTime, PrevTime, OIBMaxPitch, OIBMinPitch).
  set CurPitch to tPID[0].
  set PrevTime to CurTime.
  set PrevApo to apoapsis.
  set PrevAlt to altitude.    
}

run orbadj(TarApo,TarPer,OIBMaxPitch,OIBMinPitch).

lock throttle to 0.0.
set ship:control:pilotmainthrottle to 0.
logT("Launch complete.", time:seconds - LaunchTime).
print " apo:" + apoapsis + " per:" + periapsis.
wait 2.
stage.
RCS off.
wait 5.
AG9 on.
AG10 on.
AG4 on.
wait 2.
unlock steering.
unlock throttle.
logT("Deploy complete.", time:seconds - LaunchTime).
