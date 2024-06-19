// guido.ks
//	Primary Launch Guidance Script.
// 	Author: [redacted] (@cydonian_monk)
//
// Usage: run guido(TarApo, TarPer, TarAzi, TarHoriAlt, throttleable, hotstage, relight).
//
// Launch Profile
//	1. 	Enters terminal count, providing an overview of the target parameters.
//	2. 	IGN: At IgnSec, main engines are ignited. 
// 	3. 	LO: At zero, launch clamps are released and liftoff (hopefully) occurs.
//	4. 	Vehicle will climb vertically until airspeed exceeds 100m/s.
//	5. 	ROLL: Roll to azimuth heading.
//	6. 	POM: Pitch-Over Maneuver begins.
//	7. 	BUGF: Begin UnGuided Flight (optional), during which the craft will 
//		rely on aerodynamic forces and gravity for steering.
//	8. 	Resume Guided Flight. This phase will continue until Apoapsis is above
//		the target Periapsis.
//	9. 	OIB: Orbital Insertion Burn. Will continue until craft is either at 
//		target orbit, or until the Apoapsis is above the Target Apoapsis.
//	10. COAST: Coast phase (optional). If not in target orbit, will drift until 
//		vehicle is at or near Apoapsis.
//	11. OIB2: Second Orbital Insertion Burn (optional). Will commence once craft 
//		has reached Apoapsis and will continue until target orbit achieved.
//
//
// Vessel Design Requirements
//	1. Ascent engines must be tagged with the following names:
//		Radial Boosters: 	blockr
//		First Stage Core: 	blocka
//		Second Stage Core: 	blockb
//		Third Stage Core: 	blockc
//	2. Fairings must be tagged with the follwoing name:
//		Payload Fairing:	fairing
//	   Fairing should also be unstaged.
//	3. Deployable parts must be in the following action groups:
//		AG1: 	Orbital Primary Engines
//		AG2: 	Orbital Maneuvering Systems (RCS)
//		AG4:	Communications
//		AG8:	Science Experiments
//		AG9:	Reaction Wheels
//		AG10: 	Power Generation
//	4. Stages.
//		This script assumes first stage engines are one stage earlier than 
//		launch clamps. 
//

// Default launch parameters to something sane and safe.
declare parameter TarApo is 120000.
declare parameter TarPer is 79000.
declare parameter TarAzi is 90.
declare parameter TarHoriAlt is 32000.

// Whether or not stages can be throttled down.
declare parameter throttleable is 0.
declare parameter hotstage is 1.
declare parameter relight is 0.

// Function - CalcPoM \\
//
// Calculate the ascent slope during the initial Pitch-Over Maneuver of launch.
//
// Required Parameters
//	qAltIni			- Altitude at which the POM was initiated.
//	qAltCur			- Current Altitude.
//	qAltHori		- Reference horizontal altitude for level flight.
//	qTrajMult		- Calculated Trajectory Multiplier.
// Optional Parameters
//	qAscentPitch	- Minimum Pitch during Ascent.	
//
// Returns
//	NewPitch		- New Angle of Attack needed to achieve horizontal flight at AltHori.
//
declare FUNCTION CalcPoM {
  parameter qAltIni.
  parameter qAltCur.
  parameter qAltHori.
  parameter qTrajMult.
  parameter qAscentPitch is 5.

  local NewPitch is 0.
  
  set TrajMult to 90 / (qAltHori - POMAlt).

  set NewPitch to (qAltHori - (qAltCur - POMAlt)) * qTrajMult.
  if NewPitch < qAscentPitch {
    set NewPitch to qAscentPitch.
  }
  if NewPitch > 90 {
    set NewPitch to 90.
  }
  
  return NewPitch.
}.

// Function - CalcTrajMult \\
//
// Calculate the probably bogus multiplier used to calculate the angle of
// attack for the pitch-Over Maneuver.
//
// Required Parameters
//	qAltIni		- Altitude at which the POM was initiated.
//	qAltHori	- Reference horizontal altitude for level flight.
// 
// Returns
//	TrajMult	- Calculated Trajectory Multiplier.
//

declare FUNCTION CalcTrajMult {
  parameter qAltIni.
  parameter qAltHori.
  
  local TrajMult is 0.

  set TrajMult to 90 / (qAltHori - POMAlt).
  return TrajMult.
}.

// Function - CalcPitch \\
//
// Calculate our desired pitch during launches or complex orbital adjustments.
//
// Required Parameters 
//	qPitch		- Current Pitch.
//	qAlt 		- Current (or reference, if not live) Altitude
//	qPrevAlt 	- Previous altitude.
//	qApo 		- Current Apoapsis.
//	qPrevApo	- Previous Apoapsis.
//	qTarApo		- Target Apoapsis.
//	qCurTime	- 
//	qPrevTime	- 
// Optional Parameters
//	qMaxPitch	- Optional parameter to override the Maximum Pitch.
//	qMinPitch	- Optional parameter to override the Minimum Pitch.
//
// Returns
//	qPID		- List of PID parameters.
//
declare FUNCTION CalcPitch {
  parameter qPID.
  parameter qPitch.
  parameter qAlt.
  parameter qPrevAlt.
  parameter qApo.
  parameter qPrevApo.
  parameter qTarApo.
  parameter qCurTime.
  parameter qPrevTime.  
  parameter qMaxPitch is 45.
  parameter qMinPitch is -60.
  
  // TODO - specify K values in call.

  local dTime is 0.
  set dTime to qCurTime - qPrevTime.

  // If time hasn't changed, pitch can't change.
  if (dTime = 0) {
    return qPID.
  }
  
  local NewPitch is 0.
  local dApo is 0.
  local iApo is 0.  
  local qPitch is qPID[0].
  local dOldApo is qPID[1].
  local iOldApo is qPID[2].
  local OldPar is qPID[3].
  //local tAlt is (qTarApo - qAlt).
  
  local Par is qTarApo - qApo.
  local dPar is (Par - OldPar) / dTime.
  
  
  //set Der to (Par - OldPar) / dTime.

  set dApo to (qApo - qPrevApo) / dTime.
  set iApo to iOldApo + (Par * dTime).
  
  // If rate of change is increasing, might be an issue?
  //if (dApo > dOldApo) {
	// 
  //}

  // If we're sinking, aggressively pull up the pitch. 
  // This covers all cases where our Apoapsis is "behind" us.
  if (qAlt < qPrevAlt) {
	set NewPitch to qPitch + (0.3 * MIN(ABS(Par) / 100, 1)).
  }
  // Bring the Apoapsis down if we've overshot.
  else if (Par < 0) {
    if (dApo < 0) {
      set NewPitch to qPitch.
	}
	else {
	  set NewPitch to qPitch + (1 * MAX(Par / 100, -1)).
	}
  }  
  // If the apoapsis is no longer rising, 
  // bring it up based on how much of a delta we have left.
  else if (dApo < 0) {
	set NewPitch to qPitch + (0.1 * MIN(Par / 100, 1)).
  }
  // If we're approaching the desired apoapsis, we 
  // want to start scaling down our ascent angle.
  else if (Par < ((qApo - qPrevApo) * 100)) {
	set NewPitch to qPitch - (0.25 * MIN(ABS(Par) / 100, 1)).
  }  
  // Otherwise, leave it alone.
  else {
	set NewPitch to qPitch.
  }
  
  if NewPitch > qMaxPitch {
    set NewPitch to qMaxPitch.
  }
  if NewPitch < qMinPitch {
    set NewPitch to qMinPitch.
  } 
  
  set qPID[0] to NewPitch.
  set qPID[1] to dApo.
  set qPID[2] to iApo.
  set qPID[3] to Par.
  return qPID.
}.

// logT - Log Statement with current GuTimestamp.\\
declare FUNCTION logT {
	parameter Statement.
	parameter GuTimestamp is time:current.
	
	print ROUND(GuTimestamp) + " | " + Statement.
}.

// Program Variables \\

// Total countdown length.
declare VarCount to 10.

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

declare ApoRatio to 1.01.

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
declare PFairing to 0.
declare tRoll to 0.

declare currstage to 0.

// PROGRAM ENTRY \\
sas off.
lock throttle to 0.0.

// Find the key engines for this launch vehicle,
// and any fairings that need deployed during flight.
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
  if pcheck:tag = "fairing" {
	set PFairing to pcheck.
  }
}

// Set the staging events for the engines and fairings.
if REngine <> 0 {
  when REngine:FLAMEOUT then {
    stage.
	logT("RSEP", time:seconds - LaunchTime).
	print " alt:" + altitude.
  }
}
if AEngine <> 0 {
  // ullage test
  when ((hotstage > 0) and (currstage > 0) and (SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT < 100)) then {
    logT("dV hot stage " + SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT, time:seconds - LaunchTime).
    stage.
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
if PFairing <> 0 {
  when altitude > FairAlt then {
  // TODO AWC - need to make this safe in case deploy doesn't exist.
    PFairing:GetModule("ModuleProceduralFairing"):DoEvent("deploy").
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
logT("ROLL", time:seconds - LaunchTime).
print " alt:" + altitude.
lock steering to heading(TarAzi,CurPitch).

until airspeed > 100 {
//  lock steering to heading(TarAzi,CurPitch).
  wait 0.1.
}

logT("POM", time:seconds - LaunchTime).
print " alt:" + altitude.
set POMAlt to altitude.
set TrajMult to CalcTrajMult(POMAlt, TarHoriAlt).
until ((apoapsis > TarPer) 
//	or (altitude > TarBUGFAlt)) {
	or (altitude > TarHoriAlt)) {
  lock steering to heading(TarAzi,CurPitch). 
  wait 0.05.
  set CurPitch to CalcPoM(POMAlt, altitude, TarHoriAlt, TrajMult, AscentPitch).
}

//logT("BUGF", time:seconds - LaunchTime).
//print " alt:" + altitude.
//unlock steering.
//until ((apoapsis > TarPer) 
//	or (altitude > TarHoriAlt)) {
//  wait 0.1.	
//}

// Resume Guided Flight will attempt to bring our apoapsis up to our
// target periapsis. 
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

// Orbital Insertion Burn will attempt to burn into the target orbit.
// If RGF succeeded, we should be burning at our target periapsis. 
logT("OIB", time:seconds - LaunchTime).
print " apo:" + apoapsis + " per:" + periapsis.
if (throttleable > 0) {
  lock throttle to 0.5.
}

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
  // only break into OIB if there is a next stage
  if (((currstage = 1) and (BEngine <> 0)) or ((currstage = 2) and (CEngine <> 0))) {
    if (apoapsis > (TarApo * ApoRatio)) {
      logT("OIB EX-APO apo:" + apoapsis, time:seconds - LaunchTime).
	  break.
    }
  }
  if (throttleable > 0) {
    if (apoapsis > (TarApo * 0.96)) {
  	  lock throttle to 0.2.
    }
    if (verticalspeed < 0) {
	  lock throttle to 1.0.
    }
  }
  wait 0.1.
  set CurTime to time:seconds.  
  set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, TarApo, CurTime, PrevTime, OIBMaxPitch, OIBMinPitch).
  set CurPitch to tPID[0].
  set PrevTime to CurTime.
  set PrevApo to apoapsis.
  set PrevAlt to altitude.    
}


// Coast phase only works if engine can be restarted or if there is another engine. 
// If not, we need to work in a staging event here.
if (periapsis < TarPer) {
//until (periapsis >= TarPer) {
    logT("COAST", time:seconds - LaunchTime).
	print " apo:" + apoapsis + " per:" + periapsis.
	lock throttle to 0.0.
	lock steering to prograde.
	wait 1.
	// If relight is zero, we can't restart this engine. Just stage it away.
	if (relight <= 0) {
	  stage.
	}
	until ((TarApo - 10 < altitude)
		or (verticalspeed < 0)){	
		wait 0.1.
	}

	logT("OIB2", time:seconds - LaunchTime).
	print " apo:" + apoapsis + " per:" + periapsis.
	//set CurPitch to 0.
	RCS on.
	lock steering to prograde.
	wait 2.	
	declare tBear to ABS(ship:bearing).
	lock throttle to 0.5.
	
	set PrevTime to time:seconds.
	set PrevApo to apoapsis.
	set PrevAlt to altitude.    
	
	until (periapsis > TarPer) {
// Need to account for scenario where Apo at start of burn is below TarPer.	
		//lock steering to prograde.
		lock steering to heading(tBear,CurPitch).
		if ((periapsis + 50) > altitude) {
			logT("OIB2 EX-PER per:" + periapsis, time:seconds - LaunchTime).
			break.
		}
		if (apoapsis > (TarApo * 1.05)) {
			logT("OIB2 EX-APO apo:" + apoapsis, time:seconds - LaunchTime).
			break.
		}
		if (verticalspeed < 0) {
			lock throttle to 1.0.
		}
		else if (apoapsis > (TarApo)) {
			lock throttle to 0.1.
		}  
		
		wait 0.1.
		set CurTime to time:seconds.
		set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, CurTime, PrevTime, TarApo, OIBMaxPitch, OIBMinPitch).
		set CurPitch to tPID[0].
		set PrevTime to CurTime.
		set PrevApo to apoapsis.
		set PrevAlt to altitude.    		
	}
}


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

// PROGRAM EXIT \\