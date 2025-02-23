{{
***************************************
*  HighSpeed Client        DEMO v1.0a *
*  Author: Beau Schwabe               *
*  Copyright (c) 2011 Parallax, Inc.  *               
*  See end of file for terms of use.  *               
***************************************

Revision History:
  Version 1.0   - (09/20/2011) initial release
  Version 1.0a  - (09/26/2011) minor change to detect When the USB plug is connected
                               to the PC.  This prevents unwanted resets.

}}
CON
  ' Set up the processor clock in the standard way for 80MHz on DemoBoard
  _CLKMODE      = xtal1 + pll16x
  _XINFREQ      = 6_250_000 + 0000

    RX_Pin       = 23
    TX_Pin       = 24
    Command      = %0000  '' Feature not used in this demo
    Offset       = 0      '' Feature not used in this demo
    LED_PIN      = 27

    USB_Rx       = 31
    USB_Tx       = 30

    PAGE_SIZE     = 32
    BLINK_SPAN    = 1000
    XBEE_RX       = 6
    XBEE_TX       = 7


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



long    Stack[400], last, diff
long    fillstack[30]
long    pwm_stack[40]
long    dm_stack[15]

                                  
OBJ
  hsRX   : "HSp2pRX"                       'High Speed Receive driver
  hsTX   : "HSp2pTX"                       'High Speed Transmit driver
  PST    : "Parallax Serial Terminal"      'RS232 Serial Driver
  RC     : "RC_Receiver_4"
  XBee   : "XBee"
  sonar  : "FullDuplexSerial"              
  
PUB start|debugLED, i



'-------------------------------------------------------------------------------------------                                                        
    dira[LED_PIN]~~                                      '<- I/O direction for debug LEDs
    outa[LED_PIN]~~
'-------------------------------------------------------------------------------------------





  waitcnt(clkfreq/7+cnt)

  P2_Data := @OwnPage           
  P0_Data := @RX_Buf            
  P1_Data := @RX_Buf[PAGE_SIZE]    
  P3_Data := @RX_Buf[PAGE_SIZE*2]                                             


'-------------------------------------------------------------------------------------------
 '    if ina[USB_Rx] == 0        '' Check to see if USB port is powered
 '       outa[USB_Tx] := 0       '' Force Propeller Tx line LOW if USB not connected
 '    else                                
'        cognew(SerialDisplay,@Stack)    '' Initialize serial communication to the PC

  cognew(PWM_Acquire, @pwm_stack)
  cognew(Data_Manager, @dm_stack)


'    cognew(Fill, @fillstack)


  RC.setpins(%1111)
  RC.start


  
  XBee.Start( XBEE_RX, XBEE_TX,0, 38400, P0_Data, P1_Data, P2_Data, P3_Data )
        
'  pst.start(115200)

     
    repeat


      hsRX.RX(RX_Pin,@RX_Buf)                           '<- Receive Data from External Propeller

      longmove(@TX_Buf, P0_Data, PAGE_SIZE)                                    'P0
      longmove(@TX_Buf[PAGE_SIZE], P1_Data, PAGE_SIZE)                          'P1   all going to P3
      longmove(@TX_Buf[PAGE_SIZE*2], @OwnPage, PAGE_SIZE)                        'P2

      hsTX.TX(TX_Pin,PAGE_SIZE*3,@TX_Buf,Command,Offset)       '<- Transmit Data to External Propeller

      
'      waitcnt(clkfreq/4+cnt)
         'stuff goes here


      OwnPage[0] := (rc.get(2)-1950)*(-5000/600)  'rudder
      OwnPage[1] := (rc.get(1)-1960)*(-5000/600)  'aileron
      OwnPage[2] := (rc.get(0)-1950)*(-5000/600)  'elevator      
      OwnPage[3] := (rc.get(3)-1384)*(5000/1166)  'throttle

      XBee.XBeeData( @OwnPage[4] )


'-------------------------------------------------------------------------------------------
      debugLED++
      if debugLED > BLINK_SPAN
        outa[LED_PIN]~
        debugLED := 0
      if debugLED > 30
        outa[LED_PIN]~~
'-------------------------------------------------------------------------------------------      
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



PRI PWM_Acquire | begin, end, temp

dira[4]~

dira[5]~~
outa[5]~~
waitcnt(clkfreq+cnt)
outa[5]~
waitcnt(clkfreq/100+cnt)


repeat

    waitpeq( %10000, %10000, 0)                           'LIDAR
    begin := cnt
    waitpeq( %00000, %10000, 0)
    end := cnt
     
    temp := (end - begin) / 1000                    'convert to cm
     
    if temp < 5000                                         'filter out out-of-range (48.89 m)
      temp *= 98             'y=(51/52)x + (-)15.25
      temp -= 1525
      temp /= 100
      OwnPage[5] := temp
    else
      Ownpage[5] := 5000                                  ' max range if no counts



PRI Data_Manager | temp

  repeat
    temp := -1
    
    if LONG[P1_Data][5] > 0
      if LONG[P1_Data][5] < LONG[P2_Data][5]
        temp := LONG[P1_Data][5]

    if LONG[P2_Data][5] > 0
      if LONG[P2_Data][5] < LONG[P1_Data][5]
        temp := LONG[P2_Data][5]

    if temp < 0
      temp := 0

    OwnPage[6] := temp
    
    waitcnt(clkfreq/1500+cnt)      
      


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