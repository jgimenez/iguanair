;;*****************************************************************************
;;*****************************************************************************
;;  FILENAME: USB_descr.asm
;;   Version: 1.6, Updated on 2009/10/9 at 10:6:29
;;  Generated by PSoC Designer 5.0.1127.0
;;
;;  DESCRIPTION: USB User Module Descriptors
;;
;;  NOTE: User Module APIs conform to the fastcall convention for marshalling
;;        arguments and observe the associated "Registers are volatile" policy.
;;        This means it is the caller's responsibility to preserve any values
;;        in the X and A registers that are still needed after the API
;;        function returns. Even though these registers may be preserved now,
;;        there is no guarantee they will be preserved in future releases.
;;-----------------------------------------------------------------------------
;;  Copyright (c) Cypress Semiconductor 2009. All Rights Reserved.
;;*****************************************************************************
;;*****************************************************************************

include "m8c.inc"
include "USB.inc"
include "USB_macros.inc"

WIZARD: equ 1
WIZARD_DEFINED_REPORT_STORAGE:    EQU    1
   ;--------------------------------------------------- 
   ;@PSoC_UserCode_BODY_1@ (Do not change this line.)
   ;---------------------------------------------------
   ; Insert your custom code below this banner
   ;---------------------------------------------------
   ; Redefine the WIZARD equate to 0 below by 
   ; uncommenting the WIZARD: equ 0 line 
   ; to allow your custom descriptor to take effect
   ;--------------------------------------------------- 

   ; WIZARD: equ 0
   ; WIZARD_DEFINED_REPORT_STORAGE:    EQU    0

   ;---------------------------------------------------
   ; Insert your custom code above this banner
   ;---------------------------------------------------
   ;@PSoC_UserCode_END@ (Do not change this line.)

IF WIZARD
;-----------------------------------------------
; USB Descriptors--Generated by the USB Setup Wizard
;-----------------------------------------------
AREA  UserModules     (ROM,REL,CON)
;----------------------------------------------------------------------
; Descriptor Dispatch Tables
;   The following tables provide the dispatching pointers and
;   descriptor lengths necessary for the request handler to
;   respond to USB requests.
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; Device Dispatch Table
;   for User Module: (USB)
;----------------------------------------------------------------------
AREA  func_lit     (ROM,REL,CON)
EXPORT USB_DEVICE_LOOKUP
.LITERAL
USB_DEVICE_LOOKUP:                               ;
  LT_START    1                                  ; Number of devices defined for USB
  LT_ENTRY    USB_D0_CONFIG_LOOKUP, USB_D0_CONFIG_DESCR_TABLE
.ENDLITERAL

;----------------------------------------------------------------------
; Configuration Dispatch Table
;   for Device: (USB_D0)
;----------------------------------------------------------------------
AREA  func_lit     (ROM,REL,CON)
EXPORT USB_D0_CONFIG_LOOKUP
.LITERAL
USB_D0_CONFIG_LOOKUP:                            ;
  LT_START    1                                  ; Number of configurations
  LT_ENTRY    NULL_PTR, NULL_PTR                 ; No HID Class Descriptors
.ENDLITERAL

;----------------------------------------------------------------------
; Endpoint Setup Table
; 
; This table provides the data to configure the endpoint mode registers
; for IN/OUT direction.
;----------------------------------------------------------------------
AREA  func_lit     (ROM,REL,CON)
.LITERAL
USB_D0_C1_EP_SETUP:                              ;
  DB    USB_DIR_IN                               ; Endpoint EP1(IN)
  DB    USB_DIR_OUT                              ; Endpoint EP2(OUT)
.ENDLITERAL

;----------------------------------------------------------------------
; Interface Lookup Table
; 
; This table is indexed by interface number.
;
;----------------------------------------------------------------------
EXPORT USB_D0_C1_INTERFACE_RPT_LOOKUP
.LITERAL
USB_D0_C1_INTERFACE_RPT_LOOKUP:                  ;
  DW    0                                        ; HID Class Reports not defined for this interface
.ENDLITERAL

;----------------------------------------------------------------------
; HID Class Descriptor transfer descriptor table
;----------------------------------------------------------------------
AREA  func_lit     (ROM,REL,CON)
EXPORT USB_D0_C1_HID_CLASS_DESCR_TABLE
.LITERAL
USB_D0_C1_HID_CLASS_DESCR_TABLE:                 ;
  TD_START_TABLE 1                               ; Number of interfaces/HID Class Descriptors
  TD_ENTRY       USB_DS_ROM, 0, NULL_PTR, NULL_PTR
.ENDLITERAL

;----------------------------------------------------------------------
; Configuration Descriptor Table
;  for (USB_D0)
;
;	This table provides transfer descriptors for each USB Configuration
; Descriptor
;----------------------------------------------------------------------
AREA  func_lit     (ROM,REL,CON)
.LITERAL
USB_D0_CONFIG_DESCR_TABLE:                       ;
  TD_START_TABLE 1                               ; Number of configurations
  TD_ENTRY       USB_DS_ROM, USB_D0_C1_DESCR_SIZE, USB_D0_C1_DESCR_START, NULL_PTR
.ENDLITERAL

;----------------------------------------------------------------------
; Device Descriptor Table
;
;	This table provides transfer descriptors for each USB Device Descriptor
;----------------------------------------------------------------------
AREA  func_lit     (ROM,REL,CON)
EXPORT USB_DEVICE_DESCR_TABLE
.LITERAL
USB_DEVICE_DESCR_TABLE:                          
  TD_START_TABLE 1                               ; Number of devices
  TD_ENTRY       USB_DS_ROM, USB_D0_DESCR_SIZE, USB_D0_DESCR_START, NULL_PTR
.ENDLITERAL
;----------------------------------------------------------------------
;----------------------------------------------------------------------
; Device Descriptor (USB_D0)
; This marks the beginning of the Device Descriptor.  This descriptor
; concatenates all of the descriptors in the following format:
;	Device Descriptor
;		Configuration Descriptor (1)
;	  	Interface 1 Descriptor
;				HID Descriptor 1
;			  	Endpoint Descriptor(s)
;			Interface 2 Descriptor
;				HID Descriptor 2
;					Endpoint Descriptor(s)
;		Configuration Descriptor (2)
;			Interface/HID/Endpoint...
;----------------------------------------------------------------------
AREA  UserModules     (ROM,REL,CON)
.LITERAL
USB_D0_DESCR_START:                              ;
  DB    18                                       ; Device Descriptor Length (18)
  DB    1                                        ; bDescriptorType: DEVICE
  DWL   0200H                                    ; bcdUSB (ver 2.0)
  DB    0                                        ; bDeviceClass
  DB    0                                        ; bDeviceSubClass 
  DB    0                                        ; bDeviceProtocol 
  DB    8                                        ; bMaxPacketSize0
  DWL   1781H                                    ; idVendor
  DWL   0938H                                    ; idProduct
  DWL   0000H                                    ; bcdDevice
  DB    STR_HASH_2                               ; iManufacturer
  DB    STR_HASH_3                               ; iProduct
  DB    STR_HASH_0                               ; iSerialNumber
  DB    1                                        ; bNumConfigurations
USB_D0_DESCR_END:                                ;
USB_D0_DESCR_SIZE:  EQU    USB_D0_DESCR_END - USB_D0_DESCR_START

;----------------------------------------------------------------------
; Configuration Descriptor (USB_D0_C1)
; This marks the beginning of the Configuration Descriptor.  This descriptor
; concatenates all of the descriptors in the following format:
; Configuration Descriptor
;	Interface 1 Descriptor
;		HID Descriptor 1
;			Endpoint Descriptor(s)
;	Interface 2 Descriptor
;		HID Descriptor 2
;			Endpoint Descriptor(s)
;----------------------------------------------------------------------
USB_D0_C1_DESCR_START:                           ;
  DB    9                                        ; Configuration Descriptor Length (9)
  DB    2                                        ; bDescriptorType: CONFIGURATION
  DWL   USB_D0_C1_DESCR_SIZE                     ; wTotalLength
  DB    1                                        ; bNumInterfaces
  DB    1                                        ; bConfigurationValue
  DB    STR_HASH_0                               ; iConfiguration
  DB    80H | (0 << 6) | (0 << 5)                ; bmAttributes >
  DB    50                                       ; bMaxPower
;----------------------------------------------------------------------
; Interface Descriptor (USB_D0_C1_I0)
;----------------------------------------------------------------------
  DB    9                                        ; Interface Descriptor Length (9)
  DB    4                                        ; bDescriptorType: INTERFACE
  DB    0                                        ; bInterfaceNumber (zero based)
  DB    0                                        ; bAlternateSetting
  DB    2                                        ; bNumEndpoints
  DB    0                                        ; bInterfaceClass
  DB    0                                        ; bInterfaceSubClass
  DB    0                                        ; bInterfaceProtocol
  DB    STR_HASH_0                               ; iInterface
;----------------------------------------------------------------------
; Endpoint Descriptor (USB_D0_C1_I0_E0)
;----------------------------------------------------------------------
  DB    7                                        ; Endpoint Descriptor Length (7)
  DB    5                                        ; bDescriptorType: ENDPOINT
  DB    (EP1 | USB_DIR_IN)                       ; bEndpointAddress
  DB    3                                        ; bmAttributes
  DWL   8                                        ; wMaxPacketSize
  DB    10                                       ; bInterval
;----------------------------------------------------------------------
; Endpoint Descriptor (USB_D0_C1_I0_E1)
;----------------------------------------------------------------------
  DB    7                                        ; Endpoint Descriptor Length (7)
  DB    5                                        ; bDescriptorType: ENDPOINT
  DB    (EP2 | USB_DIR_OUT)                      ; bEndpointAddress
  DB    3                                        ; bmAttributes
  DWL   8                                        ; wMaxPacketSize
  DB    10                                       ; bInterval
;----------------------------------------------------------------------
USB_D0_C1_DESCR_END:
USB_D0_C1_DESCR_SIZE:	EQU	(USB_D0_C1_DESCR_END - USB_D0_C1_DESCR_START)
.ENDLITERAL
;----------------------------------------------------------------------
; HID Class Report Descriptors
;
; This section contains the HID Class Report Descriptors generated
; by the USB User Module Descriptor Generator
;
;----------------------------------------------------------------------
;----------------------------------------------------------------------
; USB String Descriptors
;
; This section contains the USB String Descriptors generated
; by the USB User Module Descriptor Generator
;
; Note:  The string labels are internally generated by the
; descriptor generator
;
; Descriptors that reference string descriptors, use a hashed
; symbol that is set in an EQU directive with each string
; descriptor.
;----------------------------------------------------------------------
STR_HASH_0:  EQU    0                            ; String Hash for the null string
AREA  UserModules     (ROM,REL,CON)
EXPORT USB_StringTable
.LITERAL
USB_StringTable:                                 
  TD_START_TABLE 3                               ; Number of USB Strings
  TD_ENTRY       USB_DS_ROM, LANGID_DESCR_SIZE, LANGID_DESCR_START, NULL_PTR
  TD_ENTRY       USB_DS_ROM, STRING_2_DESCR_SIZE, STRING_2_DESCR_START, NULL_PTR
  TD_ENTRY       USB_DS_ROM, STRING_3_DESCR_SIZE, STRING_3_DESCR_START, NULL_PTR
;----------------------------------------------------------------------
; LANGID Descriptor
;----------------------------------------------------------------------
LANGID_DESCR_START:                              
  DB    ((1 * 2) + 2)                            ; bLength (N+2)
  DB    3                                        ; bDescriptorType (STRING)
  DWL   1033                                     ;
LANGID_DESCR_END:                                
LANGID_DESCR_SIZE:  EQU    (LANGID_DESCR_END - LANGID_DESCR_START)
;----------------------------------------------------------------------
; String Desciptor
;----------------------------------------------------------------------
STR_HASH_2:  EQU    1                            ; String Hash
STRING_2_DESCR_START:                            
  DB    STRING_2_DESCR_SIZE                      ; bLength
  DB    3                                        ; bDescriptorType (STRING)
  DSU   "IguanaWorks"                            ;
STRING_2_DESCR_END:                              
STRING_2_DESCR_SIZE:  EQU    (STRING_2_DESCR_END - STRING_2_DESCR_START)
;----------------------------------------------------------------------
; String Desciptor
;----------------------------------------------------------------------
STR_HASH_3:  EQU    2                            ; String Hash
STRING_3_DESCR_START:                            
  DB    STRING_3_DESCR_SIZE                      ; bLength
  DB    3                                        ; bDescriptorType (STRING)
  DSU   "USB IR Transceiver"                     ;
STRING_3_DESCR_END:                              
STRING_3_DESCR_SIZE:  EQU    (STRING_3_DESCR_END - STRING_3_DESCR_START)
.ENDLITERAL

;-----------------------------------------------
; End of Descriptors
;-----------------------------------------------

ENDIF
   ;---------------------------------------------------
   ;@PSoC_UserCode_BODY_2@ (Do not change this line.)
   ;---------------------------------------------------
   ; Redefine your descriptor table below. You might
   ; cut and paste code from the WIZARD descriptor
   ; above and then make your changes.
   ;---------------------------------------------------

   
   ;---------------------------------------------------
   ; Insert your custom code above this banner
   ;---------------------------------------------------
   ;@PSoC_UserCode_END@ (Do not change this line.)

; End of File USB_descr.asm
