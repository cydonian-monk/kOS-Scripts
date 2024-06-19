local a is 0, b is 0.
list parts in h. for t in h{if t:tag = "blocka"{set a to t.} if t:tag = "blockb"{set b to t.}}
AG8 on. lock throttle to 1. stage. wait 3. stage. lock steering to up. wait 5.
when SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT < 50 then{b:activate.}
when a:FLAMEOUT then{stage.}
until verticalspeed < 0{wait 1.}
stage.
until altitude < 2000 and airspeed < 350{wait 1.}
stage. AG5 on.