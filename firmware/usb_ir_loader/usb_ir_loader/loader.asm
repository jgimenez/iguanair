; **************************************************************************
; * loader.asm *************************************************************
; **************************************************************************
; *
; * Provides definitions of the locations loader variables in RAM.  These
; * variables must be accessible to body code and so must be stored at known
; * locations.  This file must be included in ANY firmware project.
; *
; * Copyright (C) 2007, IguanaWorks Incorporated (http://iguanaworks.net)
; * Author: Joseph Dunn <jdunn@iguanaworks.net>
; *
; * Distributed under the GPL version 2.
; * See LICENSE for license details.
; */

include "loader.inc"

; exported variables
export buffer
export buffer_ptr
export loader_flags
export tmp1
export tmp2
export tmp3
export tmp4
export last_pulse
export control_pkt

; pin down all the global variables
AREA pinned_bss (RAM, ABS, CON)
  ORG PINNED_VAR_START
buffer:
    BLK BUFFER_SIZE ; the main data buffer
buffer_ptr:
    BLK 1           ; current index into buffer
loader_flags:
    BLK 1           ; used for internal booleans

; temporary variables might as well be shared to save space
tmp1:
    BLK 1
tmp2:
    BLK 1
tmp3:
    BLK 1
tmp4:
    BLK 1
last_pulse:
    BLK 1

; intentionally overlap the control packet buffer with the
; bytes needed for reflashing pages so that we KNOW what is
; being destroyed by the functions used for flashing.
; NOTE: does not get counted in "RAM X% full" in PSoC Designer
AREA pkt_bss               (RAM, ABS, CON)
  org FIRST_FLASH_VAR
control_pkt:
    BLK PACKET_SIZE ; 8 byte buffer overlapping w/ ssc vars
