{{RC_Receiver.spin
-----------------------------------------------------------------------------------------------
Read servo control pulses from a generic R/C receiver, modified to handle ONLY 6 pins
Use 4.7K resistors (or 4050 buffers) between each Propeller input and receiver signal output.

                   +5V
   ┌──────────────┐│     4.7K
 ──┤   R/C     [] ┣┼──────────• P[0..5] Propeller input(s) 
 ──┤ Receiver  [] ┣┘    Signal
 ──┤Channel(s) [] ┣┐
   └──────────────┘│
                   GND(VSS)

 Note: +5 and GND on all the receiver channels are usally interconnected,
 so to power the receiver only one channel need to be connected to +5V and GND.
-----------------------------------------------------------------------------------------------

This code is modified from its original version to read only 4 RC inputs, not 8.
The getrc function was modified to return values centered at zero instead of 1500.

}}
Con
  Mhz = 80 ' System clock frequency in Mhz.      'when previously adjusted to 104 to match current crystals,
                                                        'throttle signals became distorted, so I'm not sure
                                                        'this really matters that much, considering the
                                                        'calibration routine that is performed each time :)
   
VAR
  long  Cog
  long  Pins[4]
  long  PinMask                                          

PUB setpins(_pinmask)
'' Set pinmask for active input pins [0..3]
'' Example: setpins(%0000_1001) to read from pin 0, and 3
  PinMask := _pinmask

PUB start : status
'' Start driver (1 Cog)  
'' - Note: Call setpins() before start
  if not Cog
    Pins[0] := 0                                        ' Zero throttle pin
    repeat status from 1 to 3
      Pins[status] := Mhz * 1500                        ' Center Pins[1..5]
    status := Cog := cognew(@INIT, @Pins) + 1

PUB stop
'' Stop driver and release cog
  if Cog
    cogstop(Cog~ - 1)

PUB get(_pin) : value
'' Get receiver servo pulse width in µs. 
  value := Pins[_pin]                                   ' Get puls width from Pins[..]
  value /= Mhz                                          ' Pulse width in usec.


PUB getrc(_pin) : value
'' Get receiver servo pulse width as normal r/c values (±500) 
  value := Pins[_pin]                                   ' Get puls width from Pins[..]
  value /= Mhz                                          ' Pulse width in µsec.
  value -= 1500                                         ' Make 0 center

DAT
        org   0

INIT    mov   p1, par                           ' Get data pointer
        add   p1, #4*4                          ' Point to PinMask
        rdlong pin_mask, p1                     ' Read PinMask
'        rcl   pin_mask, #20     'get pins 20-24 :)
        andn  dira, pin_mask                    ' Set input pins

'=================================================================================

:loop   mov   d2, d1                            ' Store previous pin status
        waitpne d1, pin_mask                    ' Wait for change on pins
        mov   d1, ina                           ' Get new pin status 
        mov   c1, cnt                           ' Store change cnt                           
        and   d1, pin_mask                      ' Remove unrelevant pin changes
{
d2      1100
d1      1010
-------------
!d2     0011
&d1     1010
=       0010 POS edge

d2      1100
&!d1    0101
=       0100 NEG edge     
}
        ' Mask for POS edge changes
        mov   d3, d1
        andn  d3, d2

        ' Mask for NEG edge changes
        andn  d2, d1

'=================================================================================

:POS    tjz  d3, #:NEG                          ' Skip if no POS edge changes
'Pin 0
        test  d3, #%0000_0001   wz              ' Change on pin?
if_nz   mov   pe0, c1                           ' Store POS edge change cnt
'Pin 1
        test  d3, #%0000_0010   wz              ' ...
if_nz   mov   pe1, c1
'Pin 2
        test  d3, #%0000_0100   wz
if_nz   mov   pe2, c1
'Pin 3
        test  d3, #%0000_1000   wz
if_nz   mov   pe3, c1

'=================================================================================

:NEG    tjz   d2, #:loop                        ' Skip if no NEG edge changes
'Pin 0
        mov   p1, par                           ' Get data pointer
        test  d2, #%0000_0001   wz              ' Change on pin 0?
if_nz   mov   d4, c1                            ' Get NEG edge change cnt
if_nz   sub   d4, pe0                           ' Get pulse width
if_nz   wrlong d4, p1                           ' Store pulse width
'Pin 1
        add   p1, #4                            ' Get next data pointer
        test  d2, #%0000_0010   wz              ' ...
if_nz   mov   d4, c1              
if_nz   sub   d4, pe1             
if_nz   wrlong d4, p1             
'Pin 2
        add   p1, #4
        test  d2, #%0000_0100   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe2             
if_nz   wrlong d4, p1             
'Pin 3
        add   p1, #4
        test  d2, #%0000_1000   wz
if_nz   mov   d4, c1              
if_nz   sub   d4, pe3             
if_nz   wrlong d4, p1             

        jmp   #:loop

fit Mhz  ' Check for at least 1µs resolution with current clock speed

'=================================================================================

pin_mask long %0000_0000

c1      long  0
               
d1      long  0
d2      long  0
d3      long  0
d4      long  0

p1      long  0

pe0     long  0
pe1     long  0
pe2     long  0
pe3     long  0

        FIT   496