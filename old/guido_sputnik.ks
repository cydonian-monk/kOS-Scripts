// guido-sputnik.ks
//	Primary Launch Guidance Script for Raider Nick's Sputnik / R7 launcher in RSS/RO.
// 	Author: Andy Cummings (@cydonian_monk)
//
// Launch Profile
//	1. 	Enters terminal count, providing an overview of the target parameters.
//	2. 	IGN: At IgnSec, main engines are ignited. 
// 	3. 	LO: At zero, launch clamps are released and liftoff (hopefully) occurs.
//	4. 	Vehicle will climb vertically until airspeed exceeds 100m/s.
//	5. 	ROLL: Roll to azimuth heading.
//	6. 	POM: Pitch-Over Maneuver begins.
//	7. 	Resume Guided Flight. This phase will continue until Apoapsis is above
//		the target Periapsis.
//	8. 	OIB: Orbital Insertion Burn. Will continue until craft is either at 
//		target orbit, or until the Apoapsis is above the Target Apoapsis.
//
//
// Vessel Design Requirements
//	1. Ascent engines must be tagged with the following names:
//		Radial Boosters: 	blockr
//		First Stage Core: 	blocka
//	2. Fairings must be tagged with the follwoing name:
//		Payload Fairing:	fairing
//	   Fairing should also be unstaged.
//	3. Stage.
//		This script assumes first stage engines are on a stage earlier than 
//		the launch clamps. 
//

// Default the launch parameters to something sane and safe.
// Actual orbital elevations from Sputnik 1 Launch - 939x215
// Intended orbital elevations - 1450x223
//declare parameter TarApo is 939000.
//declare parameter TarPer is 215000.
declare parameter TarApo is 1450000.
declare parameter TarPer is 223000.
declare parameter TarAzi is 45.96.
declare parameter TarHoriAlt is 52000.


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

// logT - Log Statement with current Timestamp.\\
declare FUNCTION logT {
	parameter Statement.
	parameter Timestamp is time:current.
	
	print ROUND(Timestamp) + " | " + Statement.
}.

// Program Variables \\

// Total countdown length.
declare VarCount to 10.

declare CurPitch to 0.
declare AscentPitch to 18.
declare AscentMaxPitch to 20.
declare AscentMinPitch to -20.
declare OIBPitch to 0.
declare OIBMaxPitch to 45.
declare OIBMinPitch to -45.

declare ClearAlt to 150.
declare IgnSec to 5.

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

// PROGRAM ENTRY \\
sas off.
lock throttle to 0.0.

// Find the key engines for this launch vehicle.
list parts in CurVessel.
for pcheck in CurVessel {
  if pcheck:tag = "blockr" {    
    set REngine to pcheck.    
  }
  if pcheck:tag = "blocka" {
    set AEngine to pcheck.
  }
}

// Set the staging events for the engines and fairings.
if REngine <> 0 {
  when REngine:FLAMEOUT then {
    stage.
	logT("Booster Sep", time:seconds - LaunchTime).
	print " alt:" + altitude.
  }
}
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    stage.
	logT("Core Burnout", time:seconds - LaunchTime).
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
	or (altitude > TarHoriAlt)) {
  lock steering to heading(TarAzi,CurPitch). 
  wait 0.05.
  set CurPitch to CalcPoM(POMAlt, altitude, TarHoriAlt, TrajMult, AscentPitch).
}

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
  if (apoapsis > (TarApo * 1.01)) {
    logT("OIB EX-APO apo:" + apoapsis, time:seconds - LaunchTime).
	break.
  }
  wait 0.1.
  set CurTime to time:seconds.  
  set tPID to CalcPitch(tPID, CurPitch, altitude, PrevAlt, apoapsis, PrevApo, TarApo, CurTime, PrevTime, OIBMaxPitch, OIBMinPitch).
  set CurPitch to tPID[0].
  set PrevTime to CurTime.
  set PrevApo to apoapsis.
  set PrevAlt to altitude.    
}

//until (maxthrust = 0) {
//	wait 1.
//}

lock throttle to 0.0.
set ship:control:pilotmainthrottle to 0.
logT("Launch complete.", time:seconds - LaunchTime).
print " apo:" + apoapsis + " per:" + periapsis.
wait 2.
stage.
wait 2.
stage.
unlock steering.
unlock throttle.
logT("Deploy complete.", time:seconds - LaunchTime).

// PROGRAM EXIT \\