// lib_camera.ks
//   Camera control functions.
//   Author: Andy Cummings (@cydonian_monk)
//
@LAZYGLOBAL off.

FUNCTION SetCamera {
  PARAMETER CamNum.

  LOCAL CamList is LIST().
  LOCAL CamPart is 0.
  LOCAL TempList is LIST().
  LOCAL TempPart is 0.
  
  set CamList to SHIP:PARTSTAGGED("Cam" + CamNum).
  for CamPart in CamList {
    set TempList to CamPart:ALLMODULES().
	for TempPart in TempList {
	  if (TempPart = "MuMechModuleHullCameraZoom") {
	    CamPart:GETMODULE("MuMechModuleHullCameraZoom"):DOEVENT("activate camera").
		break.
	  }
	}
	break.
  }
}.
FUNCTION SwitchCamera {
  PARAMETER OldCam.
  PARAMETER NewCam.

  if NewCam = OldCam {
    return.
  }
  //print ("Switching from camera " + CamNum + " to camera " + NewCam + ".").  
  SetCamera(OldCam).
  SetCamera(NewCam).
}.

