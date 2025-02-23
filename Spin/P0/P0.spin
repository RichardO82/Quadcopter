{{
***************************************
*  HighSpeed Server         DEMO v1.0 *
*  Author: Beau Schwabe               *
*  Copyright (c) 2011 Parallax, Inc.  *               
*  See end of file for terms of use.  *               
***************************************

Revision History:
  Version 1.0   - (09/20/2011) initial release


}}
CON
  ' Set up the processor clock in the standard way for 80MHz on DemoBoard
  _CLKMODE      = xtal1 + pll16x
  _XINFREQ      = 6_250_000 + 0000

    RX_Pin       = 23
    TX_Pin       = 24
    Command      = %0000  '' Feature not used in this demo
    Offset       = 0      '' Feature not used in this demo
    SEC_PIN      = 16
    LED_PIN      = 27

    PAGE_SIZE     = 32
    BLINK_SPAN    = 1000

  lowDigit = 16                  'Low digit cathode
  digits = 4                    'Number of digits to display
  Segment0 = 8                  'Segment start pin

{{

Round Robin configuration using 2 Propellers:

   ┌────────────────────────────//────────────────────────────┐
   │ ┌─────────────────┐               ┌─────────────────┐    │
   │ │   Propeller 1   │               │   Propeller 2   │    │
   ┣─┤RX             TX├──┳───//───┳─┤RX             TX├──┫
    │     Client      │             │     Server      │    
    └─────────────────┘             └─────────────────┘    
  Vss                      Vss      Vss                      Vss
       

Round Robin configuration using 3 or more Propellers:

   ┌────────────────────────────/.../────────────────────────────────/.../────────────────────────────┐
   │ ┌─────────────────┐                  ┌─────────────────┐                  ┌─────────────────┐    │
   │ │   Propeller 2   │                  │   Propeller N   │                  │   Propeller 1   │    │
   ┣─┤RX             TX├──┳───/.../───┳─┤RX             TX├──┳───/.../───┳─┤RX             TX├──┫
    │     Client      │                │     Client      │                │     Server      │    
    └─────────────────┘                └─────────────────┘                └─────────────────┘    
  Vss                      Vss         Vss                      Vss         Vss                      Vss



Note: All resistors tied to Vss are 330 Ohm and are there to establish a transmission line
Note: All resistors between TX and RX are 100 Ohm and are there to current limit the I/O's in the chance
      of a collision.


With round robin, the idea is that you have one buffer that propagated around and around inside the
round robin loop.  To avoid any data collisions, all Propellers are capable of reading any location
within the buffer, however each Propeller has a specific (assigned by the programmer) location that
it can write to.

So in the Demo, there is a 1K long buffer (4K bytes).  As an example Propeller 1 may only write to
locations 0 to 255.  While Propeller 2 can write to locations 256 to 511.  Propellers 3 & 4 depicted
as N because of the expandable nature of round robin would write to the remaining 512 to 1023 locations.
 

}}
VAR

                      'Ring Buffer Components
                      
long    RX_Buf[PAGE_SIZE*3]     'RX buffer, all data except data from this chip
long    TX_Buf[PAGE_SIZE*3]     'TX buffer, all data except data from next chip
long    OwnPage[PAGE_SIZE]      'This chip's data page                          'keep locked


long    P0_Data, P1_Data, P2_Data, P3_Data              'addresses of first long in each data set's buffer

long    cogstack[60], last, diff

long    Stack[40]

long    fillstack[30]


OBJ
  hsRX   : "HSp2pRX"                       'High Speed Receive driver
  hsTX   : "HSp2pTX"                       'High Speed Transmit driver
'  sevseg : "SevenSegment"
'  f     : "float32full"
  PST   : "Parallax Serial Terminal"
  UM6   : "UM6_Data_SPI"
  PID   : "P0_PID"

  
PUB start|debugLED, i, hold

'-------------------------------------------------------------------------------------------                                                        
    dira[LED_PIN]~~                                      '<- I/O direction for debug LEDs
    outa[LED_PIN]~~
'-------------------------------------------------------------------------------------------


  waitcnt(clkfreq/3+cnt)


  P0_Data := @OwnPage           'writable               'P0_Data included for code compatibility, but better to use OwnPage to
  P1_Data := @RX_Buf               'read only                            'differentiate between read only and writable vars
  P2_Data := @RX_Buf[PAGE_SIZE]    'read only
  P3_Data := @RX_Buf[PAGE_SIZE*2]  'read only                                            


'    cognew(SerialDisplay,@Stack)    '' Initialize serial communication to the PC

'    cognew(SEC_Cog, @cogstack)

'    cognew(Fill, @fillstack)

    UM6.start( 11, 10, 9, 8, @OwnPage[0] )

    PID.START( P0_Data, P1_Data, P2_Data, 0 )
    
'    PST.start(115200)

'    sevseg.start(lowDigit, digits, Segment0, true)


'    waitcnt(clkfreq/10+cnt)

   ' bytemove(@OwnPage,@TestMessage,strsize(@TestMessage)) '<- Moves TestMessage into Buffer

'    Buffer[64] := 511

'    Buffer[64] := 65535
    

    i~

    last~
    
    repeat

      longmove(@TX_Buf, @OwnPage, PAGE_SIZE)                                    'P0
      longmove(@TX_Buf[PAGE_SIZE], P2_Data, PAGE_SIZE)                          'P2     all going to P1
      longmove(@TX_Buf[PAGE_SIZE*2], P3_Data, PAGE_SIZE)                        'P3
      
      hsTX.TX(TX_Pin,PAGE_SIZE*3,@TX_Buf,Command,Offset)       '<- Transmit Data to next P8X32A chip



      
'      waitcnt(clkfreq/4+cnt)
          'stuff goes here

      
      debugLED++                                                                          
      if debugLED > BLINK_SPAN
        outa[LED_PIN]~
        debugLED := 0
      if debugLED > 30
        outa[LED_PIN]~~

'      pst.newline
'      pst.dec(OwnPage[1])
'      pst.newline
'      pst.dec(OwnPage[2])



      hsRX.RX(RX_Pin,@RX_Buf)                           '<- Receive Data from last P8X32A chip


'      i~
'      repeat i from 0 to PAGE_SIZE-1
'        OwnPage[i] := i
'      OwnPage[0] := 4190
'      OwnPage[1] := 4190 
      

      


PRI SEC_Cog | out

'    f.start

'  dira[SEC_PIN]~~
  repeat
'    !outa[SEC_PIN]
    waitcnt(clkfreq/200+cnt)
'      out := f.fRound(f.fDiv(1.0,f.fDiv(f.fFloat(diff),f.fFloat(clkfreq))))

'      sevseg.SetValue(out)
            

Dat

TestMessage   BYTE "Test message", 0

PUB SerialDisplay | i               'DEBUG ONLY 
    PST.Start(115200)
    repeat
      PST.clear
      repeat i from 0 to PAGE_SIZE-1
{{        PST.dec(RX_Buf[i])
        PST.str(string(", "))
        PST.dec(RX_Buf[i+PAGE_SIZE])
        PST.str(string(", "))
        PST.dec(RX_Buf[i+PAGE_SIZE*2])
        PST.newline                       }}

        PST.dec(OwnPage[i])
        PST.newline  
      waitcnt(clkfreq/20+cnt)



PRI Fill | i

      i~
      repeat i from 0 to PAGE_SIZE-1
        OwnPage[i] := i


CON
{{
┌───────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                     │                                                            
├───────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and  │
│associated documentation files (the "Software"), to deal in the Software without restriction,      │
│including without limitation the rights to use, copy, modify, merge, publish, distribute,          │
│sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is      │
│furnished to do so, subject to the following conditions:                                           │
│                                                                                                   │
│The above copyright notice and this permission notice shall be included in all copies or           │
│ substantial portions of the Software.                                                             │
│                                                                                                   │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT  │
│NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND             │
│NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,       │
│DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,                   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE        │
│SOFTWARE.                                                                                          │     
└───────────────────────────────────────────────────────────────────────────────────────────────────┘
}}