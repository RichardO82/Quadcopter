{{
**************************************************
* High Speed Prop to Prop Comm Receiver     v1.1 *
*                                                *
* Author: Beau Schwabe                           *
* Copyright (c) 2011 Parallax                    *
* See end of file for terms of use.              *
**************************************************

Revision History:
  Version 1.0   - original file created as a high speed Prop to Prop
  
  Version 1.1   - (03-29-2011) added routines to aid in handshaking
                  as well as data packet re-direction.

≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈

The Anatomy of the packet data:

When Receiving (RX) You must indicate in the PacketHeaderOut where you
want the received data to be stored.

Note: If TX sends a Destination offset value it will be added to the Data Address value
      and the incomming data will be written starting at the new offset location.
 
The Data Ready Flag is automatically set in the RX function.
 
PacketHeaderOut: 32-bit long 
%00000000000000_aaaaaaaaaaaaaa_cccc
                              
 └──Reserved──┘ └Data Address┘ │  │
    14-Bits       14-Bits      │  │
                               Data Ready Flag ; $0-busy $F-ready ... controlled by RX
                                 4-Bits

After data has been received then PacketHeaderIn contains information from the
transmitter such as Packet Size, Dest Offset (This is the offset value applied to the local
data address), and a Command Packet that provides a way for the transmitter side to send
specific instructions to the receiver side.

PacketHeaderIn: 32-bit long
%ssssssssssssss_aaaaaaaaaaaaaa_cccc
                              
 └ Packet Size┘ └ Dest Offset┘ │  │
    14-Bits       14-Bits      │  │ 
                              Packet Command
                                 4-Bits

- The data pin is only driven HIGH.  This is similar to an open collector mode with a PNP drive transistor.

- A pull-down resistor of 330 Ohms on both the Server and the Client side of the data pin
  keep the pin LOW.

Schematic:
                22              22
Server ──┳────────────────────────┳── Client
           330                      330 
                                        
         GND                            GND
          
DataPacket dataline:

      Packet Sync    PacketHeader
           │              │
           │              │        Packet Data #1   Packet Data #N
                                                      
         3.3us          3.2us         3.2us            3.2us
TX ...
RX ...
                     Packet #1     Packet #2        Packet #N
                │
       'Packet Sync' detected by RX, RX is ready to receive data

       Note: TX monitors the Sync detection from RX and if TX doesn't see the response
             from RX, then the 'Packet Sync' is sent again until it does.

             TX must send at least 2 packets in order to be a valid transmission.
}}

PUB  Stop 'Dumb code to prevent accidental running from this file
PUB RX(_Pin,_DataAddress)|PacketHeaderOut,PacketHeaderIn
    PacketHeaderOut := _DataAddress<<4              'Tell PacketHeader where to put the Data it receives
    Pin := _Pin                                     'Set receive pin to listen on
    cognew(@RX_Propeller,@PacketHeaderOut)          'request data
    repeat until (PacketHeaderOut& $F)==$F          '<-- Trap here until RX is done
    result := PacketHeaderIn                        'return feedback data from transmitter

DAT
' Start RX proceedure ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈
RX_Propeller  org
' Clear Status Flag ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈
              rdlong    DataSamples,         par        'read data samples
              andn      DataSamples,         #$F        'clear flag; data packet busy
              wrlong    DataSamples,         par        'update flag status               
' Get Address for Input Packet Header (Contents written here are from TX)
              mov       _PacketHeaderIn,     par        'Read Data Address Location
              add       _PacketHeaderIn,     #4
' Parse Output Packet Header so we know where to write the incomming data              
              rdlong    Buff,                par        'Read PacketHeader contents
              mov       DataIndex,           Buff
              and       DataIndex,           AddressMask 'DataIndex points to data buffer
              shr       DataIndex,           #4              
' Create Pin Mask for data transmission line              
              mov       PinMask,             #1         'Create Pin Mask for Input/Output pin
              shl       PinMask,             Pin
              or        outa,                PinMask    'Preset Pin HIGH
              andn      dira,                PinMask    'Make Pin an INPUT Hi-Z LOW              
' Setup Counter to count during data-pin HIGH times
              movi      ctra,                #%0_11010_000     'LOGIC A
              movs      ctra,                Pin
              mov       frqa,                #1
' Detect 3.3us Packet SYNC
''  ... Detects a LOW-HIGH-LOW transition ; HIGH time must be at least 3.3us
 Packet_SYNC
              waitpne   PinMask,             PinMask            'Wait for LOW
              mov       phsa,                #0    wz           'clear phsa and set Z flag
                                                                'Note: Z flag is used to
                                                                '      Determine DataSamples
                                                                '      further down in code
              waitpeq   PinMask,             PinMask            'Wait for HIGH
              waitpne   PinMask,             PinMask            'Wait for LOW
              mov       temp,                phsa               'read phsa
              cmp       temp,                #262  wc   '<- 264 clocks at 80MHz equals 3.3us
       if_c   jmp       #Packet_SYNC                    'Jump if pulse is less than 3.3us      
'' 3.3us pulse detected...
''     ... Respond by making dataline HIGH (Tell TX we're almost ready to receive)
              or        dira,                PinMask    'Make pin HIGH
''     ... Respond by making dataline LOW (Tell TX to start sending data)
              andn      dira,                PinMask    'Make Pin an INPUT Hi-Z LOW
'' Detect data long sync
''  ... wait for a HIGH of 100ns followed by a LOW of 50ns  
_RX
              waitpeq   PinMask,             PinMask                         'Wait for HIGH                            
              waitpne   PinMask,             PinMask                         'Wait for LOW
' Read 1 LONG after sync ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0
              test      PinMask,             ina wc     'Read RX pin into "C"
              rcl       Buff,#1                         'Rotate Buff left and place "C" in Bit0

' Detect Packet Size with first received long ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈
        if_z  mov       DataSamples,         Buff       'Set first reading to number of DataSamples
        if_z  shr       DataSamples,         #18        'Clear "Z" flag in the dnjz below, so this
                                                        'only gets executed once.
' Write Data and get next long ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈
        if_z  wrlong    Buff,          _PacketHeaderIn  'Write received value to Start Address +4

        if_z  and       Buff,                AddressMask 'Parse data and add Dest Offset to Index                   
        if_z  shr       Buff,                #2
        if_z  add       DataIndex,           Buff
         
       if_nz  wrlong    Buff,                DataIndex  'Write received value to Indexed Address

       if_nz  add       DataIndex,           #4         'Increment Index value
              djnz      DataSamples,         #_RX  wz   'Check to see if there are more data samples
' Set Status Flag ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈
              rdlong    DataSamples,         par        'read data samples
              or        DataSamples,         #$F        'set flag; data packet done
              wrlong    DataSamples,         par        'update flag status               
' Terminate RX proceedure ≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈
              cogid     temp                            'Get this COG ID
              cogstop   temp                            'STOP this COG

Pin           long      0              
PinMask       long      0
Buff          long      0
DataSamples   long      0
DataIndex     long      0
temp          long      0

AddressMask   long      $7FFF0
_PacketHeaderIn long    0
delay         long      0
DestOffset    long      0

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
