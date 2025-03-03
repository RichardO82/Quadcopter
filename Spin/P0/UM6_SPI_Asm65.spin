
{{      
************************************************
*    SPI Engine for CH Robotics UM6 & UM6-LT   *
*           Author: Larry Wenddell             *
************************************************      
This assembly routine consists of one function that will perform
one of three tasks, depending on the first parameter "Command" .
A description of the parameters are as follows: 

  * Command  -  1 = Read a Data Register. 
                2 = Write to a Configuration Register
                3 = Send a Command.
  * MOSI_Pin  -  Propeller pin connected to UM6 MOSI pin.
  * MISO_Pin  -  Propeller pin connected to UM6 MISO pin.   
  * Sck_Pin   -  Propeller pin connected to UM6 Sck pin.        
  * SS_Pin    -  Propeller pin connected to UM6 SS pin.  
  * Register  -  The UM6 register to read from, to configure, or command.
  * CnfgValue -  The value that will be written to the configuration register.
}}


VAR
    long     cog, control

PUB start : okay
    stop
    okay := cog := cognew(@loop, @control) + 1
   
PUB stop
''  Stop SPI Engine - frees a cog
    if cog
       cogstop(cog~ - 1)
    control~

PUB  UM6_CMD(Command, MOSI_Pin, MISO_Pin, Sck_Pin, SS_Pin, Register, CnfgValue) | Value     
     control := @Command
     repeat while control       
     result := Value
    
'#####################################################################################

DAT           
                      org     0
'' UM6 SPI Engine - main loop                                         
loop          rdlong  t1, par    wz      ''Wait for command
        if_z  jmp     #loop
              mov     address, t1        ''Preserve address for passing variables back  
             
'--------------- Configure Pins ------------------------------------------------------ 

              rdlong  Cmd, t1    wz      ''Get command parameter 
              add     t1, #4   
              rdlong  t2, t1             ''Get parameter MOSI and set pin 
              mov     t3, #1             ''   Load mask
              shl     t3, t2             ''   Shift bit left as per perameter
              mov     mosi, t3   wz      ''   Save mask in MOSI
              muxnz   dira, mosi         ''   Set MOSI pin to output
              muxz    outa, mosi         ''   Set MOSI bit low              
              add     t1, #4
              rdlong  t2, t1             ''Get parameter MISO and set pin
              mov     t3, #1             ''   Load mask
              shl     t3, t2             ''   Shift bit left as per perameter
              mov     miso, t3   wz      ''   Save mask in MISO
              muxz    dira, miso         ''   Set MISO pin to input
              add     t1, #4
              rdlong  t2, t1             ''Get parameter SCK and set pin
              mov     t3, #1             ''   Load mask
              shl     t3, t2             ''   Shift bit left as per perameter
              mov     sck, t3    wz      ''   Save mask in SCK
              muxnz   dira, sck          ''   Set SCK pin to output
              muxz    outa, sck          ''   Set SCK bit low
              add     t1, #4                         
              rdlong  t2, t1             ''Get parameter SS and set pin
              mov     t3, #1             ''   Load mask
              shl     t3, t2             ''   Shift bit left as per perameter
              mov     ss, t3   wz        ''   Save mask in SS
              muxnz   dira, ss           ''   Set SS pin to output
              muxnz   outa, ss    
              add     t1, #4             ''Get Reg value     
              rdlong  Reg, t1                         
              add     t1, #4             ''Get value to write to UM6     
              rdlong  CnfgReg, t1                                    

'--------------- Lookup Command ------------------------------------------------------                          

              sub     Cmd, #1  wz        ''Lookup command; 
      if_z    jmp     #Rd_Reg            ''   1 = Read a Register
              sub     Cmd, #1  wz        ''   2 = Write to Configuration Register
      if_z    jmp     #Wt_Reg            ''   3 = Send a Command
              sub     Cmd, #1  wz
      if_z    jmp     #Send_Cmd  

'--------------- Read a UM6 Register -------------------------------------------------
                                        
Rd_Reg        mov       temp, #00        ''Send $00 for read operation    
              mov       ClockDelay, #12
              add       ClockDelay, cnt
              waitcnt   ClockDelay, #200
              xor       outa, ss         ''Output SS low                  
              call      #Send_Byte 
              mov       temp, Reg        ''Send Register to be read   
              call      #Send_Byte
              mov       temp, #0    wz   ''Set MOSI low
              muxnz     outa, mosi        
              call      #Rd_Value
              call      #Return_Value
              or        outa, ss         ''Output SS high
              wrlong    Zero, par        ''Set command = 0 to signify command completed    
              jmp       #loop

'--------------- Config Register -----------------------------------------------------                                        

Wt_Reg        mov       temp, #01        ''Send $01 for write operation    
              mov       ClockDelay, #12
              add       ClockDelay, cnt
              waitcnt   ClockDelay, #190 
              xor       outa, ss         ''Output SS low                  
              call      #Send_Byte 
              mov       temp, Reg        ''Send Config Register to be written to   
              call      #Send_Byte
              mov       temp,  CnfgReg   ''Get value to be sent to UM6 register
              call      #Send_Long
              or        outa, ss         ''Output SS High
              wrlong    Zero, par        ''Set command = 0 to signify command completed    
              jmp       #loop

'--------------- Send Long -----------------------------------------------------------                                                               

Send_Long     mov       t1, #32          ''Load bit counter
              mov       t2, #1           ''Load bit mask
              shl       t2, #31          ''Shift bit mask to point to MSB
:Send_Bit     test      temp, t2    wc   ''Test MSB to get value.  Carry = bit tested with mask
              muxc      outa, mosi
              shr       t2, #1           ''Shift mask to point to next bit
              call      #Clock_H
              call      #Clock_L
              djnz      t1, #:Send_Bit
Send_Long_Ret ret               

'--------------- Send Command  ------------------------------------------------------- 
       
Send_Cmd      mov       temp, #01        ''Send $01 for Command operation    
              mov       ClockDelay, #12   ''   A Write is is required to 
              add       ClockDelay, cnt  ''   send a command.   
              waitcnt   ClockDelay, #200
              xor       outa, ss         ''Output SS low                    
              call      #Send_Byte 
              mov       temp, Reg        ''Send command   
              call      #Send_Byte
              mov       temp, #0    wz   ''Set MOSI low
              muxnz     outa, mosi        
              call      #Rd_Value
              call      #Return_Value
              or        outa, ss         ''Output SS high
              wrlong    Zero, par        ''Set command = 0 to signify command completed    
              jmp       #loop
 
'--------------- Read Value ----------------------------------------------------------              

Rd_Value      mov       t1, #32          ''Load bit counter
:Get_Bit      Call      #Clock_H
              test      miso, ina   wc   ''Sets carry to state of miso bit
              rcl       Recvd, #1        ''Rotate bits received into Register t3  
              call      #Clock_L
              djnz      t1, #:Get_Bit    ''Get next bit unless last
Rd_Value_Ret  ret                      
               
'--------------- Send a Byte ---------------------------------------------------------

Send_Byte     mov       t1, #8           ''Set bit counter          
              mov       t2, #1           ''Load bit mask
              shl       t2, #7           ''Shift bit mask to point to MSB
:Send_Bit     test      temp, t2    wc   ''Test MSB to get value.  Carry = bit tested with mask
              muxc      outa, mosi
              shr       t2, #1           ''Shift mask to point to next bit
              call      #Clock_H
              call      #Clock_L
              djnz      t1, #:Send_Bit
Send_Byte_Ret ret

'--------------- Return Value---------------------------------------------------------    

Return_Value  add       address, #28     ''Point to parameter after Reg
              wrlong    Recvd, address                   ''Write data to hub address
Return_Value_ret   ret 

'--------------- Clock ---------------------------------------------------------------

Clock_H       waitcnt   ClockDelay, #148 ''Output clock high    
              or        outa, sck                                 
Clock_H_Ret   ret          


Clock_L       waitcnt   ClockDelay, #148 ''Output clock low     
              xor        outa, sck                                 
Clock_L_Ret   ret          

'--------------- Data and Variables     ----------------------------------------------  

t1                      long    0        ''Temporary variables     
t2                      long    0                                               
t3                      long    0                       
ClockDelay              long    0
Recvd                   long    0
temp                    long    0
Zero                    long    0    
address                 long    0         ''Arguments passed from Spin
Cmd                     long    0          
mosi                    long    0         
miso                    long    0
sck                     long    0
ss                      long    0           
Reg                     long    0
CnfgReg                 long    0
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}      