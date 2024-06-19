declare parameter TarApo is 80000.
declare parameter TarPer is 79999.
declare parameter TarInc is 0.

run lib_lazcalc.ks.

print "Target Azimuth: " + LAZcalc(LAZcalc_init(TarApo,TarInc)).



// vDESTaprox = (3531600000000 / (600000 + TarApo))^0.5
// vROTx = 174.9422 (changes by latitude)
// vDESTx = vDESTaprox * sin(TarInc)
// vDESTy = vDESTaprox * cos(TarInc)
// vLAUNCHx = vDESTx - vROTx
// vLAUNCHy = vDESTy - 0
// vLAUNCH = (vLAUNCHx^2 + vLAUNCHy^2)^0.5
// TarAzi = arctan(vLAUNCHx/vLAUNCHy)
// declare TarAzi is ...

