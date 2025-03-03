{
 ************************************************************************************************************
 *                                                                                                          *
 *  AUTO-RECOVER NOTICE: This file was automatically recovered from an earlier Propeller Tool session.      *
 *                                                                                                          *
 *  ORIGINAL FOLDER:     C:\Users\ManServant\Documents\Propeller\UAV 2.0\P0\                                *
 *  TIME AUTO-SAVED:     10 hours, 18 minutes ago (4/17/2015 12:26:15 AM)                                   *
 *                                                                                                          *
 *  OPTIONS:             1)  RESTORE THIS FILE by deleting these comments and selecting File -> Save.       *
 *                           The existing file in the original folder will be replaced by this one.         *
 *                                                                                                          *
 *                           -- OR --                                                                       *
 *                                                                                                          *
 *                       2)  IGNORE THIS FILE by closing it without saving.                                 *
 *                           This file will be discarded and the original will be left intact.              *
 *                                                                                                          *
 ************************************************************************************************************
.}
{{      
************************************************
*         SPI Communications Demo for          *                
*               CH Robotics UM6           v1.0 *
*              Author: L. Wendell              *
* **********************************************
}}

OBJ
SPI     :       "UM6_SPI_Asm65"                    ''UM6 SPI Assembly engine
'Ser     :       "FullDuplexSerial"               ''Used in this DEMO for Debug
f       : "Float32"

CON

'       SPI Commands
        ReadReg   = 1

' Frequency Output        
        HALF_PIN                = 17                       


' Round Robin Indices
        STATUS                  = 0                       
        MX                      = 1               
        MY                      = 2
        MZ                      = 3
        TEMPER                  = 4
        LON                     = 5
        LAT                     = 6
        ALT                     = 7
        NORTH                   = 8
        EAST                    = 9
        HEIGHT                  = 10
        SPEED                   = 11
        COURSE                  = 12
        SATSUM                  = 13 


VAR
  long Reading, Temp

  long SPI_Stack[40]
  long SPI_cog

DAT

'        UM6_Status      long    0
        yaw             long    0
        pitch           long    0
        roll            long    0
        yawRate         long    0
        pitchRate       long    0
        rollRate        long    0
        RR              long    0
        RR_Var          long    0
         


PUB Start( mosi, miso, sck, ss, data ) : success

  if SPI_cog                                                         'if it's on 
    cogstop( SPI_cog - 1 )                                          'kill cog

  success := ( SPI_cog := cognew( UM6_SPI( mosi, miso, sck, ss, data ), @SPI_stack ) + 1 )          'launch new cog

PUB Stop

              
  if SPI_cog                                                         'if it's on 
    cogstop( SPI_cog - 1 )                                          'kill cog

  SPI.Stop


PRI UM6_SPI( mosi, miso, sck, ss, data )


'  dira[HALF_PIN]~~

'      Ser.start(31, 30, 0, 57_600)  


      RR := 0                   'set round robin index to 0

      SPI.start                   '' Initialize SPI Engine

'      f.start
          
      ''
        'When INS becomes a priority, split the data into two piles, fast and slow.  The fast data
        'will be collected each frame, and the slow data will be collected one datum per frame so the minimum
        'data amount of fast+1 will be sent each frame.(INS req's plus one "other")

      
      repeat 

          waitcnt(clkfreq/1000+cnt)                     'UM6 updates internally at ~500 Hz, so this delay gets us close to that
                                                                                ' (us at ~487 Hz measured with 6.5 MHz crystal) 

          Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $5C, 0)      
          Temp := Reading & $0000FFFF
          rollRate := ~~Temp
          Temp := Reading & $FFFF0000
          Temp >>= 16
          pitchRate := ~~Temp
          Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $5D, 0)  
          Temp := Reading & $FFFF0000
          Temp >>= 16
          yawRate := ~~Temp  
          


          Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $62, 0)      
          Temp := Reading & $0000FFFF
          roll := ~~Temp
          Temp := Reading & $FFFF0000
          Temp >>= 16
          pitch := ~~Temp
          Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $63, 0)  
          Temp := Reading & $FFFF0000
          Temp >>= 16
          yaw := ~~Temp  
               {{
          f_yaw := f.fMul( f.fRound(yaw), f.fRound(0.0109863) )
          f_pitch := f.fMul( f.fRound(pitch), f.fRound(-0.0109863) )
          f_roll := f.fMul( f.fRound(roll), f.fRound(0.0109863) )
          f_yawRate := f.fMul( f.fRound(yawRate), f.fRound(0.0610352) )
          f_pitchRate := f.fMul( f.fRound(pitchRate), f.fRound(-0.0610352) )
          f_rollRate := f.fMul( f.fRound(rollRate), f.fRound(0.0610352) )
                }}
                
          yaw   := ~~yaw / 91                       'apply sign and scale                        
          pitch := ~~pitch / 91
          roll  := ~~roll / -91
          yawRate   := ~~yawRate / 16
          pitchRate := ~~pitchRate / -16
          rollRate  := ~~rollRate / 16
                  



          case RR
            STATUS              : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $55, 0)
            
            MX                  : Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $60, 0)
                                  Temp := Reading & $0000FFFF
                                  RR_Var := ~~Temp
                                                              
            MY                  : Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $60, 0)
                                  Temp := Reading & $FFFF0000
                                  Temp >>= 16
                                  RR_Var := ~~Temp

            MZ                  : Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $61, 0)
                                  Temp := Reading & $FFFF0000
                                  Temp >>= 16
                                  RR_Var := ~~Temp    
      
            TEMPER              : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $76, 0)
                             
            LON                 : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $77, 0)
                                 
            LAT                 : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $78, 0)
                                 
            ALT                 : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $79, 0)
                                 
            NORTH               : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7A, 0)
                               
            EAST                : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7B, 0)
                                
            HEIGHT              : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7C, 0)
                              
            SPEED               : Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7D, 0)
                                  Temp := Reading & $0000FFFF
                                  RR_Var := ~~Temp
            
                               
            COURSE              : Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7D, 0)
                                  Temp := Reading & $FFFF0000
                                  Temp >>= 16
                                  RR_Var := ~~Temp
                                                    
            SATSUM              : RR_Var := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7E, 0)
'                                                        RR_Var := 123                   






          longmove( data, @yaw, 6 )
          LONG[data+(4*6)+(4*RR)] := RR_Var

          RR++
          if RR > 13
            RR := 0

'          !outa[HALF_PIN]







           
'          UM6_Status := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $55, 0)
'          Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $60, 0)      
'          Temp := Reading & $0000FFFF
'          mag_x := ~~Temp
'          Temp := Reading & $FFFF0000
'          Temp >>= 16
'          mag_y := ~~Temp
'          Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $61, 0)  
'          Temp := Reading & $FFFF0000
'         Temp >>= 16
'          mag_z := ~~Temp    
'          UM6_Temp := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $76, 0) 
'          GPS_Lon := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $77, 0)
'          GPS_Lat := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $78, 0)
'          GPS_Alt := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $79, 0)
'          pos_N := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7A, 0)
'          pos_E := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7B, 0)
'          pos_H := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7C, 0)
'          Reading := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7D, 0)
'          Temp := Reading & $0000FFFF
'          GPS_Speed := ~~Temp
'          Temp := Reading & $FFFF0000
'          Temp >>= 16
'          GPS_Course := ~~Temp
'          Satelite_Sum := SPI.UM6_CMD(ReadReg, MOSI, MISO, SCK, SS, $7E, 0)           
'          waitcnt(clkfreq/10 + cnt)
{{
          ser.tx(16)
          ser.tx(1)
          ser.dec(UM6_Status)
          ser.tx(13)
          ser.dec(gyro_x)
          ser.tx(13)
          ser.dec(gyro_y)
          ser.tx(13)
          ser.dec(gyro_z)
          ser.tx(13)
          ser.tx(13)
          ser.dec(accel_x)
          ser.tx(13)
          ser.dec(accel_y)
          ser.tx(13)
          ser.dec(accel_z)
          ser.tx(13)
          ser.tx(13)
          ser.dec(mag_x)
          ser.tx(13)
          ser.dec(mag_y)
          ser.tx(13)
          ser.dec(mag_z)
          ser.tx(13)
          ser.tx(13)
          ser.dec(UM6_Temp)
          ser.tx(13)
          ser.dec(GPS_Lon)
          ser.tx(13)
          ser.dec(GPS_Lat)
          ser.tx(13)
          ser.dec(GPS_Alt)
          ser.tx(13)
          ser.dec(pos_N)
          ser.tx(13)
          ser.dec(pos_E)
          ser.tx(13)
          ser.dec(pos_H)
          ser.tx(13)
          ser.dec(GPS_Speed)
          ser.tx(13)
          ser.dec(GPS_Course)
          ser.tx(13)
          ser.dec(Satelite_Sum)
          ser.tx(13)
          }}
                     
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
 