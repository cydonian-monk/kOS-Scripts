sas off.lock throttle to 0.0.lock steering to heading(270,0).
set AntList to SHIP:PARTSTAGGED("recoveryAnt").set ChuteList to SHIP:PARTSTAGGED("recoveryChute").
// Set heading to deorbit.// Spin up orbiter.// Decouple reentry pod and fire engines.when (altitude < 10000){  for recoveryChute in ChuteList {    recoveryChute:GetModule("RealChuteModule").DOEVENT("arm").  }}when airspeed < 10 {  for recoveryAnt in AntList {    recoveryAnt:GetModule("ModuleRTAntenna"):DOEVENT("activate").  }}

until (5 > alt:radar)
{
  wait 1.
}

wait 1.
unlock steering.unlock throttle.