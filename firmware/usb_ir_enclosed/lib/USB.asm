;;*****************************************************************************
;;*****************************************************************************
;;  FILENAME: USB.asm
;;   Version: 1.5, Updated on 2005/08/17 at 15:01:28
;;  Generated by PSoC Designer ver 4.2  b1013 : 02 September, 2004
;;
;;  DESCRIPTION: USB Device User Module software implementation file
;;               for the enCoRe II family of devices
;;
;;  NOTE: User Module APIs conform to the fastcall convention for marshalling
;;        arguments and observe the associated "Registers are volatile" policy.
;;        This means it is the caller's responsibility to preserve any values
;;        in the X and A registers that are still needed after the API
;;        function returns. Even though these registers may be preserved now,
;;        there is no guarantee they will be preserved in future releases.
;;-----------------------------------------------------------------------------
;;  Copyright (c) Cypress Semiconductor 2004, 2005. All Rights Reserved.
;;*****************************************************************************
;;*****************************************************************************

include "m8c.inc"
include "USB_macros.inc"
include "USB.inc"
IF 0x2 & 0x10000000
PSOC_ERROR Please run the USB Setup Wizard.  Device Editor, Right Click the USB User Module
; This message will only appear if the USB Setup Wizard has not be run and the descriptors
; and associated data structures have been created.
; After running the USB Setup Wizard, you must also select the Config/Generate Application
; menu item from PSoC Designer in order to generate USB User Module data structures and
; descriptors.
ENDIF
;-----------------------------------------------
;  Global Symbols
;-----------------------------------------------
EXPORT USB_Start
EXPORT _USB_Start
EXPORT USB_Stop
EXPORT _USB_Stop
EXPORT USB_bCheckActivity
EXPORT _USB_bCheckActivity
EXPORT USB_bGetConfiguration
EXPORT _USB_bGetConfiguration
EXPORT USB_bGetEPState
EXPORT _USB_bGetEPState
EXPORT USB_bGetEPCount
EXPORT _USB_bGetEPCount
EXPORT USB_XLoadEP
EXPORT _USB_XLoadEP
EXPORT USB_EnableOutEP
EXPORT _USB_EnableOutEP
EXPORT USB_DisableOutEP
EXPORT _USB_DisableOutEP
EXPORT USB_EnableEP
EXPORT _USB_EnableEP
EXPORT USB_DisableEP
EXPORT _USB_DisableEP
EXPORT USB_Force
EXPORT _USB_Force
EXPORT USB_Suspend
EXPORT _USB_Suspend
EXPORT USB_Resume
EXPORT _USB_Resume
EXPORT USB_bRWUEnabled
EXPORT _USB_bRWUEnabled

AREA bss (RAM,REL)
;-----------------------------------------------
;  Variable Allocation
;-----------------------------------------------
;----------------------------------------------------------------------------
EXPORT USB_APITemp
 USB_APITemp:                          BLK   2 ; Two bytes of temporary
                                                ; storage shared by the API
                                                ; functions
EXPORT USB_APIEPNumber, _USB_APIEPNumber
_USB_APIEPNumber:
 USB_APIEPNumber:                      BLK   1 ; API storage for speed
EXPORT USB_APICount, _USB_APICount
_USB_APICount:
 USB_APICount:                         BLK   1 ; API storage for speed

EXPORT USB_bActivity
 USB_bActivity:                        BLK   1 ; Activity flag (Shared between the ISR and API)
;-----------------------------------------------
;  Constant Data Allocation
;-----------------------------------------------
AREA UserModules (ROM, REL)
EXPORT USB_USB_EP_BIT_LOOKUP
.LITERAL
USB_USB_EP_BIT_LOOKUP:  ;
    DB     01H                       ; EP0
    DB     02H                       ; EP1
    DB     04H                       ; EP2
.ENDLITERAL

AREA UserModules (ROM, REL)

;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_Start
;
;  DESCRIPTION:    Starts the USB User Module
;                    Sets the device selection
;                    Set the configuration to unconfigured
;                    Enables the SIE for Address 0
;                    Enables the USB pullup (D- for low speed, D+ for full speed)
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:    A is the desired device setting
;
;  RETURNS:
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_Start:
_USB_Start:
    MOV    REG[P10CR], 0x00            ; Disable the states
    MOV    REG[P11CR], 0x00            ; 

    MOV     [USB_bCurrentDevice], A    ; The app selects the desired device

    MOV     [USB_TransferType], USB_TRANS_STATE_IDLE ; Transaction Idle State
    MOV     [USB_Configuration], 0     ; Unconfigured
    MOV     [USB_DeviceStatus], 0      ; Clears device status

    MOV     [USB_EPDataToggle], 0      ; Clear all EP data toggles

; Flow here to enable the SIE
    MOV     REG[USB_ADDR], USB_ADDR_ENABLE ; Enable Address 0
    OR      REG[USB_USBXCR], USB_PULLUP_ENABLE ; Pullup D-
    MOV     REG[USB_EP0MODE], USB_MODE_STALL_IN_OUT ; ACK Setup/Stall IN/OUT
    NOP
    MOV     A, REG[USB_EP0MODE]        ; Read the mode register as a debug marker

    M8C_EnableIntMask INT_MSK1, (INT_MSK1_USB_ACTIVITY | INT_MSK1_USB_BUS_RESET | INT_MSK1_USB_EP0)
    RET
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_Stop
;
;  DESCRIPTION:
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:
;
;  RETURNS:
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_Stop:
_USB_Stop:
    MOV     [USB_bCurrentDevice], 0    ; The app selects the desired device

    MOV     [USB_TransferType], USB_TRANS_STATE_IDLE ; Transaction Idle State
    MOV     [USB_Configuration], 0     ; Unconfigured
    MOV     [USB_DeviceStatus], 0      ; Clear the  device status
    MOV     [USB_bActivity], 0         ; Clear the activity flag
    MOV     REG[USB_ADDR], 0           ; Clear the addfress and Address 0
    AND     REG[USB_USBXCR], ~USB_PULLUP_ENABLE ; Release D-
    M8C_DisableIntMask    INT_MSK1, (INT_MSK1_USB_ACTIVITY | INT_MSK1_USB_BUS_RESET | INT_MSK1_USB_EP0 | INT_MSK1_USB_EP1 | INT_MSK1_USB_EP2) ; Enable the interrupt

    RET
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_bCheckActivity
;
;  DESCRIPTION:
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:
;
;  RETURNS:
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;   The activity interrupt sets a RAM flag indicating activity and disables the
;   interrupt.  Disabling the interrupt keeps the bus activity from creating too
;   many interrupts.  bCheckActivity checks and clears the flag, the enables
;   interrupts for the next interval.
;
;-----------------------------------------------------------------------------
.SECTION
 USB_bCheckActivity:
_USB_bCheckActivity:
    MOV    A, [USB_bActivity]          ; Activity?
    CMP    A, 1                        ; 
    JZ     .active                     ; Jump on Activity
; Flow here on no activity
    RET
; Jump here if activity was detected
.active:
    MOV    [USB_bActivity], 0          ; Clear the activity flag for next time
    M8C_EnableIntMask INT_MSK1, INT_MSK1_USB_ACTIVITY ; Enable the activity interupt
    RET
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_bGetConfiguration
;
;  DESCRIPTION:   Returns the current configuration number
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:    None
;
;  RETURNS:      A contains the current configuration number
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_bGetConfiguration:
_USB_bGetConfiguration:
    MOV     A,[USB_Configuration]
    RET
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_bGetEPState
;
;  DESCRIPTION:   Returns the current endpoint state
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:   A: Endpoint Number
;
;  RETURNS:     A: NO_EVENT_ALLOWED
;                  EVENT_PENDING
;                  NO_EVENT_PENDING
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_bGetEPState:
_USB_bGetEPState:
    CMP     A, (USB_MAX_EP_NUMBER + 1) ; Range check
    JNC     .invalid_ep                ; Bail out
; Flow here to enable an endpoint        
    MOV     X, A                       ; Endpoint number is the index
    MOV     A, [X+USB_EndpointAPIStatus]; Get the state
    JMP     .exit                      ; Go to the common exit
; Jump here for an invalid endpoint
.invalid_ep:
    MOV     A, 0                       ; Return 0 for an invalid ep
; Jump or flow here for a common exit
.exit:
    RET                                ; All done
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_bRWUEnabled
;
;  DESCRIPTION:   Returns 1 if Remote Wake Up is enabled, otherwise 0
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:   None
;
;  RETURNS:     A: 1--Remote Wake Up Enabled
;                  0--Remote Wake Up Disabled
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_bRWUEnabled:
_USB_bRWUEnabled:
    TST     [USB_DeviceStatus], USB_DEVICE_STATUS_REMOTE_WAKEUP
    JNZ     .enabled                   ; Jump if enabled
; Flow here if RWU is disabled        
    MOV     A, 0                       ; Return disabled
    JMP     .exit                      ; Go to the common exit
; Jump when RWU is enabled
.enabled:
    MOV     A, 1                       ; Return enabled
; Jump or flow here for a common exit
.exit:
    RET                                ; All done
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_bGetEPCount
;
;  DESCRIPTION:
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:
;
;  RETURNS:
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_bGetEPCount:
_USB_bGetEPCount:
    CMP     A, (USB_MAX_EP_NUMBER + 1) ; Range check
    JNC     .invalid_ep                ; Bail out
; Flow here to get the endpoint count
    MOV     X, A                       ; Endpoint number is the index
    MOV     A, REG[X+EP0CNT]           ; Here is the count
    AND     A, 0x1F                    ; Mask off the count
    SUB     A, 2                       ; Ours includes the two byte checksum
    JMP     .exit                      ; Go to the common exit
; Jump here for an invalid endpoint
.invalid_ep:
    MOV     A, 0                       ; Return 0 for an invalid ep
; Jump or flow here for a common exit
.exit:
    RET
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_LoadEP
;
;  DESCRIPTION:    This function loads the specified endpoint buffer
;                  with the number of bytes previously set in the count
;                  register.
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:  A:X Pointer to the ram buffer containing the data to transfer
;              USB_APIEPNumber loaded with the endpoint number
;              USB_APICount loaded with the number of bytes to load
;
;  RETURNS:    NONE
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_XLoadEP:
_USB_XLoadEP:
; extern void USB_LoadEP(BYTE, BYTE*);
    CMP     [USB_APIEPNumber], (USB_MAX_EP_NUMBER + 1) ; Range check
    JNC     .exit                      ; Bail out
; Flow here to get the endpoint count
    MOV     [USB_APITemp], X           ; Use this temp as the MVI pointer

    MOV     A, [USB_APIEPNumber]       ; Get the endpoint number
    INDEX   EPREGPTR                   ; Get the address of the endpoint data register array
    MOV     X, A                       ; We are going to use index access to the register array
    
    MOV     A, [USB_APICount]          ; Get the count
    MOV     [USB_APITemp+1], A         ; Use this temp as the count
; Copy loop
.loop:
    DEC     [USB_APITemp+1]            ; Are we done?
    JC      .done                      ; Jump if we are
    MVI     A, [USB_APITemp]           ; Get the data, inc the pointer
    MOV     REG[X + 0], A              ; Store the data
    INC     X                          ; Index the next data register
    JMP     .loop                      ; Copy the next byte or finish

; Jump here when the copy is finished
.done:
    MOV     X, [USB_APIEPNumber]       ; Get the endpoint number
    MOV     A, X
    INDEX   USB_USB_EP_BIT_LOOKUP
    AND     A, [USB_EPDataToggle]
    JZ      .addcount
    MOV     A, USB_CNT_TOGGLE

.addcount:     
    OR      A, [USB_APICount]          ; Get the count

    MOV     [X + USB_EndpointAPIStatus], NO_EVENT_PENDING ; Set the state
    MOV     REG[X + EP0CNT], A         ; Update the count register
    MOV     REG[X + EP0MODE], USB_MODE_ACK_IN ; Enable the endpoint
; Jump or flow here for a common exit
.exit:
    RET
.LITERAL
EPREGPTR:    DB    EP0DATA, EP1DATA, EP2DATA
.ENDLITERAL
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_EnableEP
;
;  DESCRIPTION:    This function enables an OUT endpoint.  It should not be
;                  called for an IN endpoint.
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:      A contains the endpoint number
;
;  RETURNS:        None
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_EnableOutEP:
_USB_EnableOutEP:
 USB_EnableEP:
_USB_EnableEP:
    CMP     A, 0                       ; Can't enable EP0
    JZ      .exit                      ; Bail out
    CMP     A, (USB_MAX_EP_NUMBER + 1) ; Range check
    JNC     .exit                      ; Bail out
; Flow here to enable an endpoint        
    MOV     X, A                       ; Endpoint number is the index
    MOV     [X+USB_EndpointAPIStatus], NO_EVENT_PENDING ; For the API
    MOV     A, REG[X+EP0MODE]          ; Unlock the mode register
    MOV     REG[X+EP0MODE], USB_MODE_ACK_OUT ; Enable the endpoint
; Jump or flow here for a common exit
.exit:
    RET                                ; All done
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_DisableEP
;
;  DESCRIPTION:    This function disables an OUT endpoint.  It should not be
;                  called for an IN endpoint.
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:
;
;  RETURNS:
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_DisableOutEP:
_USB_DisableOutEP:
 USB_DisableEP:
_USB_DisableEP:
    CMP     A, 0                       ; Can't disable EP0
    JZ      .exit                      ; Bail out
    CMP     A, (USB_MAX_EP_NUMBER + 1) ; Range check
    JNC     .exit                      ; Bail out
; Flow here to disable an endpoint        
    MOV     X, A                       ; Endpoint number is the index
    MOV     A, REG[X+EP0MODE]          ; Unlock the mode register
    MOV     REG[X+EP0MODE], USB_MODE_NAK_OUT ; Disable the endpoint
; Jump or flow here for a common exit
.exit:
    RET                                ; All done
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_Force
;
;  DESCRIPTION:    Force the J/K/SE0 State of D+/D-
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:     A: USB_FORCE_J
;                    USB_FORCE_K
;                    USB_FORCE_SE0
;                    USB_FORCE_NONE
;
;  RETURNS:       Nothing
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_Force:
_USB_Force:
    CMP    A, USB_FORCE_NONE           ; Are we done forcing D+/D-?
    JZ     .none                       ; Jump if we are done
; Flow here to start checking 
    CMP    A, USB_FORCE_J              ; Force J?
    JNZ    .check_k                    ; Jump if not J
; Flow here to force J
    OR     [Port_1_Data_SHADE], 0x02   ; D- = 1
    AND    [Port_1_Data_SHADE], ~(0x01); D+ = 0
    JMP    .force                      ; Go set the force register
; Jump here to check Force K
.check_k:
    CMP    A, USB_FORCE_K              ; Force K?
    JNZ    .check_se0                  ; Jump if not K
; Flow here to force K
    OR     [Port_1_Data_SHADE], 0x01   ; D+ = 1
    AND    [Port_1_Data_SHADE], ~(0x02); D- = 0
    JMP    .force                      ; Go set the force register
; Jump here to check Force SE0
.check_se0:
    CMP    A, USB_FORCE_SE0            ; Force SE0?
    JZ     .invalid                    ; Jump if not SE0
; Flow here to force SE0
    AND    [Port_1_Data_SHADE], ~(0x03); D- = 0,  D+ = 0
; Jump or flow here to enable forcing (Port bits are set in the shadow register)
.force:
    MOV    A, [Port_1_Data_SHADE]      ; Get the shadow
    MOV    REG[P1DATA], A              ; Update the port
    OR     REG[USBXCR], USB_FORCE_STATE; Enable FORCING D+/D-
    RET                                ; Exit
; Jump here to clear forcing
.none:
    AND    REG[USBXCR], ~(USB_FORCE_STATE) ; Disable FORCING D+/D-
; Jump or flow here to exit on end forcing or an invalid parameter
.invalid:
    RET                                ; Exit
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_Suspend
;
;  DESCRIPTION:    Puts the USB Transceiver into power-down mode, while
;                  maintaining the USB address assigned by the USB host. 
;                  To restore the USB Transceiver to normal operation, the
;                  USB_Resume function should be called.
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:     None
;
;  RETURNS:       Nothing
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_Suspend:
_USB_Suspend:
    AND     REG[USB_ADDR], ~(USB_ADDR_ENABLE) ; Disable transceiver
    RET                                ; Exit
.ENDSECTION
;-----------------------------------------------------------------------------
;  FUNCTION NAME: USB_Resume
;
;  DESCRIPTION:    Puts the USB Transceiver into normal operation, following
;                  a call to USB_Suspend. It retains the USB address that had
;                  been assigned by the USB host.
;
;-----------------------------------------------------------------------------
;
;  ARGUMENTS:     None
;
;  RETURNS:       Nothing
;
;  SIDE EFFECTS: REGISTERS ARE VOLATILE: THE A AND X REGISTERS MAY BE MODIFIED!
;
;  THEORY of OPERATION or PROCEDURE:
;
;-----------------------------------------------------------------------------
.SECTION
 USB_Resume:
_USB_Resume:
    OR     REG[USB_ADDR], (USB_ADDR_ENABLE) ; Enable transceiver
    RET                                ; Exit
.ENDSECTION


;-----------------------------------------------
; Add custom application code for routines 
;-----------------------------------------------

   ;@PSoC_UserCode_BODY_1@ (Do not change this line.)
   ;---------------------------------------------------
   ; Insert your custom code below this banner
   ;---------------------------------------------------

   ;---------------------------------------------------
   ; Insert your custom code above this banner
   ;---------------------------------------------------
   ;@PSoC_UserCode_END@ (Do not change this line.)

; End of File USB.asm