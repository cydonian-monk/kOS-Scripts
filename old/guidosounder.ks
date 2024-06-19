// guido5k.ks
//   Small byte count launch script.
//   Author: Andy Cummings (@cydonian_monk)
//
declare VarCount to 20.
declare TarApo to 1500000.
declare REngine to 0.
declare AEngine to 0.
declare BEngine to 0.
declare CEngine to 0.


// PROGRAM ENTRY \\
sas off.
lock throttle to 0.0.
lock steering to heading(90,90).

// Find the key engines for this launch vehicle.
list engines in CurVessel.
for eng in CurVessel {
  if eng:tag = "blockr" {    
    set REngine to eng.    
  }
  if eng:tag = "blocka" {
    set AEngine to eng.
  }
  if eng:tag = "blockb" {
    set BEngine to eng.
  }  
  if eng:tag = "blockc" {
    set CEngine to eng.
  }    
}

// Set the staging events for the engines we just found.
if REngine <> 0 {
  when REngine:FLAMEOUT then {
    stage.
  }
}
if AEngine <> 0 {
  when AEngine:FLAMEOUT then {
    stage.
  }
}
if BEngine <> 0 {
  when BEngine:FLAMEOUT then {
    stage.
  }
}
if CEngine <> 0 {
  when CEngine:FLAMEOUT then {
    stage.
  }
}

until VarCount < 6 {
  wait 1.
  set VarCount to VarCount - 1.
}
lock throttle to 1.0.
stage.
until VarCount < 1 {
  wait 1.
  set VarCount to VarCount - 1.
}
stage.

until (apoapsis > TarApo) {
  wait 1.
}


wait 1.
unlock steering.
unlock throttle.

// PROGRAM EXIT \\