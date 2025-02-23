{{
    Quadcopter Joystick Object
    
        -runs on the quadcopter and handles communications with the joystick module




  CHANGE LOG:

  
    2012.01.19  Enabled switching between 1 way fast and 2 way slow com modes.
                Simplified reporting varable code

    2012.01.20  Reconfigured joystick data packet to have sync_key be the first character, supplying the subsequent
                  joystick data immediately after a signal loss period.  Also, the cog outputs the last known balance
                  variables during a signal loss to try and not move. (NOT DOABLE YET: Balance variables come from PID loops, so
                                would need to send that data back, but not doable for 1way mode, so a standard set of balance vars
                                should be used when found)

                Joystick Serial Data Packet Format:

                   COM_MODE_1WAY : 1 way communication from joystick module to quad for fast responsiveness

                      Serial Data from Joystick Module to Quadcopter: 

                       16long   8chars | meaning
                       _______________________________
                        0          0,1 | sync_key    : specifies com mode, and maintains data frame alignment
                        1          2,3 | rudder      : joystick rudder position
                        2          4,5 | aileron     : joystick aileron position
                        3          6,7 | elevator    : joystick elevator position
                        4          8,9 | throttle    : joystick throttle position
                        5        10,11 | message     : joystick message data

                   COM_MODE_2WAY : 2 way communication back and forth between joystick module and quad for data reporting, debugging

                      Serial Data from Joystick Module to Quadcopter: 

                       16long   8chars | meaning
                       _______________________________
                        0          0,1 | sync_key    : specifies com mode, and maintains data frame alignment
                        1          2,3 | rudder      : joystick rudder position
                        2          4,5 | aileron     : joystick aileron position
                        3          6,7 | elevator    : joystick elevator position
                        4          8,9 | throttle    : joystick throttle position
                        5        10,11 | message     : joystick message data

                      Serial Data from Quadcopter to Joystick Module: (always follows immediately)
                      
                       16long   8chars     | meaning
                       _____________________________________
                       REP_VARS REP_VARSx2 | reports data  : multiple variables sent as a single chunk with longmove
                                                                   * REP_VARS must be the same in Joystick Module
                                                                     and Quadcopter cogs.  Mismatched REP_VARS and
                                                                     related constants' values will make data frame
                                                                     alignment impossible.

        
    2012.03.04  Added a temporary debugging variable to the reports system

    2012.08.12  Fixed problem with sync_key not zeroing if lost.  Now recovers from lost sync_key on next correct sync_key.

    2012.10.23  2 Way now works great.  Also renamed all variables from Joy to XBee and js to xb and such as there is no longer
                any joystick ivolved.                                                              



}}





CON

  TIME_OUT      = 10

  REP_VARS     = 62

  COM_MODE_1WAY = 420           'must be same as in XBeestick.spin
  COM_MODE_2WAY = 419

  SPK1          = 23
  SPK2          = 22

  COMCODE       = 32491        'must match code sent by UAV Control program

'  RST_PIN       = 6             'rst pin of XBee


OBJ

  xb            : "FullDuplexSerial"
'  pc            : "Parallax Serial Terminal"


VAR

  long XBee_cog
  long XBee_stack[100]
  long XBee_lock

  long outdata[REP_VARS]                                'outgoing reporting vars
  long outdata_c[REP_VARS]
  word sync_key                                         '16 bit packet synchronization key

DAT

        gs_message         long    0
        


PUB Start( rxpin, txpin, mode, baud, P0_Data, P1_Data, P2_Data, P3_Data ) : success

  if not XBee_lock := locknew                                         'Get a lock and stop if already running
    Stop

'  dira[RST_PIN]~~
'  outa[RST_PIN]~~
  success := ( XBee_cog := cognew( RunXBee(rxpin, txpin, mode, baud, P0_Data, P1_Data, P2_Data, P3_Data, XBee_lock), @XBee_stack ) + 1 )          'launch new cog

PUB Stop

  xb.Stop
              
  if XBee_cog                                                         'if it's on 
    cogstop( XBee_cog - 1 )                                          'kill cog
'  outa[RST_PIN]~


PUB XBeeData( dest )                       'retrieve the latest unpacked data set from the control device

  repeat until not lockset( XBee_lock )
  longmove( dest, @gs_message, 1 )
  lockclr( XBee_lock )                       


PUB SendReports( source )                   'copy the set of data to be transmitted for debugging

  repeat until not lockset( XBee_lock )
  longmove( @outdata, source, REP_VARS )
  lockclr( XBee_lock )                       

                                
PRI RunXBee( rxpin, txpin, mode, baud, P0_Data, P1_Data, P2_Data, P3_Data, lock ) | byt, gs_message_t, i, checksum, fast[12], slow[50], slow_index

'  dira[21]~~                    '1/2 Frequency Output Pin

  xb.Start(rxpin, txpin, mode, baud)
  waitcnt(clkfreq/5+cnt)

  sync_key~

'  pc.start(115200)


'  dira[27]~~

  slow_index~

  repeat


     'Get sync'd up
     
    sync_key := xb.Rx
    repeat until ((sync_key == COM_MODE_1WAY) OR (sync_key == COM_MODE_2WAY))
'      !outa[13]



       sync_key <<= 8            'realign data frame if misalligned
      if sync_key > COM_MODE_1WAY
        sync_key~
      sync_key |= xb.Rx



      'instead of / in addition to looking at the sync_key to determine signal loss, use a counter
      'and measure time between incriments somewhere else.- possibly on msp430
  
      if((sync_key <> COM_MODE_1WAY) AND (sync_key <> COM_MODE_2WAY))  'IMPORTANT SAFETY FEATURE 

        gs_message_t := 0

        repeat until not lockset( lock )
        gs_message := gs_message_t         
        lockclr( lock )
   
 
       'All sync'd up, get XBeestick data
        
    gs_message_t := xb.Rx         'get XBeestick data
    gs_message_t <<= 8
    gs_message_t |= xb.Rx

    checksum := xb.Rx
    checksum <<= 8
    checksum |= xb.Rx


    if( checksum == gs_message_t | COMCODE )
    

      if gs_message_t <> 0                              'zeros indicate 2 way and not given as commands (otherwise would dilute out)
        repeat until not lockset( lock )
        gs_message := gs_message_t         
'      if sync_key == COM_MODE_2WAY      
'        longmove( @outdata_c, @outdata, REP_VARS )
        lockclr( lock )

'      !outa[21] 
            

      if sync_key == COM_MODE_2WAY

      
        fast[0]  := LONG[P0_Data][6]
        longmove(@fast[1], @LONG[P2_Data][0], 4) 
        longmove(@fast[5], @LONG[P0_Data][0], 6) 
        fast[11] := LONG[P3_Data][10]

        longmove(@slow,     @LONG[P0_Data][7], 25)
        longmove(@slow[25], @LONG[P1_Data][0], 5)
        longmove(@slow[30], @LONG[P2_Data][4], 1)
        longmove(@slow[31], @LONG[P2_Data][7], 2)
        longmove(@slow[33], @LONG[P3_Data][0], 10)
        longmove(@slow[43], @LONG[P3_Data][11], 7)

        slow[31] := LONG[P2_Data][5]  'shimmy in the sonar and lidar numbers
        slow[32] := LONG[P2_Data][6]
        

        i~
        repeat 12
          tx32(fast[i++])

        tx32(slow[slow_index])
        tx16(slow_index++)

        if( slow_index > 50 )
          slow_index~ 
        
{{        

        i~
'        repeat REP_VARS
'          tx16(outdata_c[i++])
       
        repeat 6 
          tx16(outdata_c[i++])

        tx32(outdata_c[i++])

        repeat 3 
          tx16(outdata_c[i++])

        repeat 10 
          tx32(outdata_c[i++])

        repeat 40 
          tx16(outdata_c[i++])
          

}}



PUB tx16(val) | msb, lsb

  msb := val >> 8
  xb.Tx(msb)
  lsb := val - (msb << 8)
  xb.Tx(lsb)


PUB tx32(value) | n

  repeat n from 0 to 3
    xb.tx(value.byte[n])

PUB Alarm( num ) | i

  dira[SPK1]~~
  dira[SPK2]~~
  outa[SPK1]~
  outa[SPK2]~


  repeat num
    i~
    repeat 500
     
      outa[SPK1]~
      outa[SPK2]~~                             'make some noise!!!
      waitcnt(2000+i*10+cnt)
      outa[SPK1]~~
      outa[SPK2]~
      waitcnt(2000+i*10+cnt)
      i++
      outa[SPK1]~
      outa[SPK2]~~
      waitcnt(2000+cnt)
      
   
  outa[SPK1]~
  outa[SPK2]~



DAT
{{
┌───────────────────────────────────────────────────────────────────────────┐
│                    TERMS OF USE: MIT License                              │     
├───────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining      │
│a copy of this software and associated documentationfiles (the             │
│"Software"), to deal in the Software without restriction, including        │
│without limitation the rights to use, copy, modify, merge, publish,        │
│distribute, sublicense, and/or sell copies of the Software, and to         │
│permit persons to whom the Software is furnished to do so, subject to      │
│the following conditions:                                                  │     
│                                                                           │     
│The above copyright notice and this permission notice shall be included    │
│in all copies or substantial portions of the Software.                     │
│                                                                           │      
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS    │
│OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,│
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    │
│THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER        │
│DEALINGS IN THE SOFTWARE.                                                  │
└───────────────────────────────────────────────────────────────────────────┘
}}