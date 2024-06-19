RCS on.
lock steering to retrograde.
until verticalspeed < 0 {
  wait 1.
}
until altitude < 72000 {
  wait 1.
}

list parts in CurVessel.
for pcheck in CurVessel {
  if pcheck:tag = "descent" {
	if pcheck:HasModule("ModuleDecouple") {
	  pcheck:GetModule("ModuleDecouple"):DoEvent("decouple").
	}
	if pcheck:HasModule("ModuleRCSFX") {
	  if pcheck:GetModule("ModuleRCSFX"):HasField("rcs") {
	    pcheck:GetModule("ModuleRCSFX"):SetField("rcs",true).
      }
	}
  }
}
AG4 off.
until altitude < 5000 and airspeed < 600 {
  wait 1.
}
unlock steering.
AG6 on.
until altitude < 2000 and airspeed < 343 {
  wait 1.
}
AG5 on.
until airspeed < 10 {
  wait 1.
}
AG4 on.
