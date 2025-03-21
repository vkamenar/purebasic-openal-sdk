; PlayStream
; ----------
; Shows how to use OpenAL's buffer queuing mechanism to stream audio
; to an OpenAL source.

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
IncludeFile "..\..\include\wave.pb"    ; WAV file format related code

#NUMBUFFERS = 4
#BUFFERSIZE = 4096 ; size of buffers (in samples)

; Initialize Console library
OpenConsole()
EnableGraphicalConsole(1) ; Required in PureBasic v4 and newer
PrintN("PlayStream Test Application")

; See if we have any available OpenAL devices
If ListSize(OALF_devices()) = 0
	PrintN("-ERR: Could not initialize OpenAL")
Else
	; Get the default device name
	defaultDeviceName$ = OALF_GetDefaultDeviceName()

	; Print a menu with the available devices and highlight the default one
	PrintN("")
	PrintN("Select OpenAL device:")
	index = 0
	While NextElement(OALF_devices())
		index + 1
		menu_option$ = Str(index) + ". " + OALF_devices()
		If OALF_devices() = defaultDeviceName$ : menu_option$ + " (DEFAULT)" : EndIf
		PrintN(menu_option$)
	Wend

	; Wait for user input
	key_pressed_code = OALF_wait4numkeyevent()
	If key_pressed_code = 0 Or key_pressed_code > index : CloseConsole() : End : EndIf

	; Open the selected device
	SelectElement(OALF_devices(), key_pressed_code - 1)
	OAL_device = OALF_alcOpenDevice(OALF_devices())
	If OAL_device = 0
		PrintN("-ERR: Could not open the specified device")
	Else
		; Create a context and make it the current context
		OAL_context = alcCreateContext(OAL_device, 0)
		If OAL_context = 0
			PrintN("-ERR: Could not create a context")
		Else
			alcMakeContextCurrent(OAL_context)
			ConsoleCursor(0)
			ClearConsole()
			PrintN("Opened " + OALF_devices() + " Device")

			; Generate some AL buffers
			Dim OAL_buffers(#NUMBUFFERS)
			alGenBuffers(#NUMBUFFERS, @OAL_buffers(0))

			; Load wave file
			If alWAVEOpen("..\..\Media\stereo.wav") = 0
				PrintN("-ERR: Failed to load the WAV")
			Else

				; Generate a source to playback the buffer
				alGenSources(1, @OAL_source)

				; Preload all the buffers with audio data from the wavefile
				For i = 0 To #NUMBUFFERS - 1
					alWAVERead(OAL_buffers(i), #BUFFERSIZE)
					alSourceQueueBuffers(OAL_source, 1, @OAL_buffers(i))
				Next

				; Play source
				alSourcePlay(OAL_source)
				iTotalBuffersProcessed = 0

				; Update the 'buffers processed' prompt while streaming the wave
				Repeat
					Delay(20)

					; Request the number of OpenAL buffers have been processed (played) on the source
					iBuffers = 0
					alGetSourcei(OAL_source, #AL_BUFFERS_PROCESSED, @iBuffers)

					; Keep a running count of number of buffers processed (for logging purposes only)
					iTotalBuffersProcessed + iBuffers
					ConsoleLocate(0,1)
					Print("Buffers Processed: " + Str(iTotalBuffersProcessed) + "   ")

					; For each processed buffer, remove it from the source queue, read next chunk of audio
					; data from disk, fill buffer with new data and add it to the source queue
					While iBuffers
						lastbuffer_ID = 0
						alSourceUnqueueBuffers(OAL_source, 1, @lastbuffer_ID)
						If alWAVERead(lastbuffer_ID, #BUFFERSIZE) <> 0
							alSourceQueueBuffers(OAL_source, 1, @lastbuffer_ID)
						EndIf
						iBuffers - 1
					Wend

					; Check the status of the source. If it is not playing, then playback was completed,
					; or the source was starved of audio data and needs to be restarted
					alGetSourcei(OAL_source, #AL_SOURCE_STATE, @OAL_state)
					If OAL_state <> #AL_PLAYING

						; If there are buffers in the source queue then the source was starved of audio
						; data, so needs to be restarted (because there is more audio data to play)
						alGetSourcei(OAL_source, #AL_BUFFERS_QUEUED, @iBuffers)
						If iBuffers : alSourcePlay(OAL_source) : Else : Break : EndIf
					EndIf
				ForEver
				PrintN("")

				; Clean up by closing the wave file and deleting source and buffers
				alWAVEClose()
				alDeleteSources(1, @OAL_source)
				alDeleteBuffers(#NUMBUFFERS, @OAL_buffers(0))
			EndIf
			alcMakeContextCurrent(0) ; Always deselect the current context before destroying it!
			alcDestroyContext(OAL_context)
		EndIf
		alcCloseDevice(OAL_device)
	EndIf
EndIf

PrintN("")
Print("Press any key to exit")
OALF_wait4numkeyevent()
CloseConsole()
End
