; Enumerate
; ---------
; Shows how to use the OpenAL device enumeration extension to locate
; all of the OpenAL devices on the user's system. The code also shows
; how to determine the capabilities of each device, including what
; version of OpenAL each device supports.

; Make sure you have OpenAL properly installed before running the program.
; You can download the redistributable OpenAL installer from the official
; OpenAL website:
;   https://www.openal.org/downloads/

; This example is also compatible with OpenAL Soft, an LGPL-licensed
; implementation of the OpenAL 3D API. The OpenAL Soft can be downloaded
; from the official website:
;   https://openal-soft.org/
; Note: When using OpenAL Soft, rename soft_oal.dll to either
;       openal32.dll (x86) or openal64.dll (x64).

IncludeFile "..\..\include\openal.pbi" ; OpenAL constants
IncludeFile "..\..\include\oalf.pb"    ; Common OpenAL Framework (OALF) code

; Initialize Console library
OpenConsole()
PrintN("Hello!!!")

; See if we have any available OpenAL devices
If ListSize(OALF_devices()) <> 0

	; List all the available OpenAL devices
	PrintN("All Available OpenAL Devices:")
	While NextElement(OALF_devices())
		list_item$ = " " + OALF_devices()
		xram_available = 0
		; Open the device and select a context to check the version info
		OAL_device = OALF_alcOpenDevice(OALF_devices())
		If OAL_device <> 0
			OAL_context = alcCreateContext(OAL_device, 0)
			If OAL_context <> 0
				alcMakeContextCurrent(OAL_context)
				iMajorVer.l = 0 : alcGetIntegerv(OAL_device, #ALC_MAJOR_VERSION, 4, @iMajorVer)
				iMinorVer.l = 0 : alcGetIntegerv(OAL_device, #ALC_MINOR_VERSION, 4, @iMinorVer)
				list_item$ + ", Spec Version " + Str(iMajorVer) + "." + Str(iMinorVer)
				; Check for XRAM support.
				If OALF_alIsExtensionPresent("EAX-RAM") <> #AL_FALSE : xram_available = 1 : EndIf
				alcMakeContextCurrent(0)
				alcDestroyContext(OAL_context)
			EndIf
			alcCloseDevice(OAL_device)
		EndIf
		PrintN(list_item$)
		If xram_available = 0 : DeleteElement(OALF_devices()) : EndIf
	Wend

	; Print the default device name
	PrintN("")
	PrintN("Default device: " + OALF_GetDefaultDeviceName())

	; List the devices supporting XRAM
	PrintN("")
	PrintN("Devices with XRAM support:")
	If ListSize(OALF_devices()) = 0
		PrintN(" None")
	Else
		FirstElement(OALF_devices())
		Repeat
			PrintN(" " + OALF_devices())
		Until NextElement(OALF_devices()) = 0
	EndIf

Else
	; An empty device list means some kind of OpenAL error
	PrintN("-ERR: Could not initialize OpenAL")
EndIf

PrintN("")
Print("Press any key to exit")
OALF_wait4numkeyevent()
CloseConsole()
End
