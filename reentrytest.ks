sas off.
set AntList to SHIP:PARTSTAGGED("recoveryAnt").
// Set heading to deorbit.

until (5 > alt:radar)
{
  wait 1.
}

wait 1.
unlock steering.