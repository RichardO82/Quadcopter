{{
┌──────────────────────────────────────────┐
│ BMP085 Driver 1.0                        │
│ Author: Tim Moore                        │               
│ Copyright (c) May 2010 Tim Moore         │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

  I2C addresses is %1110_1110

  breakout board availble (http://www.sparkfun.com/commerce/product_info.php?products_id=9694)

  Note: GetPressureTemp and GetPressureTempA are only usable from a single Cog. Calling from multiple Cogs will confuse the state machine
}}
OBJ
  i2cObject   : "basic_i2c_driver"                      '0 Cog
  umath :       "umath"                                 '0 Cog

VAR
  long ac1, ac2, ac3, ac4, ac5, ac6, b1, b2, mb, mc, md 'see the datasheet for what these mean
  long state, time, temput
  long delays[4]

DAT
  shifts long 50000, 50000>>1, 50000>>2, 50000>>3
          
PUB Init(i2cSCL, _deviceAddress)
''initializes BMP085
''reads in sensor coefficients etc. from eeprom
'
  state := 0
  delays[0] := clkfreq/222                                                      '4.5ms
  delays[1] := clkfreq/133                                                      '7.5ms
  delays[2] := clkfreq/74                                                       '13.5ms
  delays[3] := clkfreq/39                                                       '25.5ms

'  i2cObject.Initialize(i2cSCL)

  result := true
  'read all the coefficient and sensor values from eeprom
  ac1 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $AA)
  ac2 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $AC)
  ac3 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $AE)
  ac4 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $B0)
  ac5 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $B2)
  ac6 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $B4)
  b1 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $B6)
  b2 := i2cObject.readLocation16(i2cSCL, _deviceAddress, $B8)
  mb := i2cObject.readLocation16(i2cSCL, _deviceAddress, $BA)
  mc := i2cObject.readLocation16(i2cSCL, _deviceAddress, $BC)
  md := i2cObject.readLocation16(i2cSCL, _deviceAddress, $BE)
  if ac1 == 0 OR ac2 == 0 OR ac3 == 0 OR ac4 == 0 OR ac5 == 0 OR ac6 == 0 OR b1 == 0 OR b2 == 0 OR mb == 0 OR mc == 0 OR md == 0
    result := false
  elseif ac1 == $ffff OR ac2 == $ffff OR ac3 == $ffff OR ac4 == $ffff OR ac5 == $ffff OR ac6 == $ffff OR b1 == $ffff OR {
}   b2 == $ffff OR mb == $ffff OR mc == $ffff OR md == $ffff
    result := false
  ~~ac1                                                                         'sign extend correctly, note ac4, ac5, ac6 are not sign extended
  ~~ac2
  ~~ac3
  ~~b1
  ~~b2
  ~~mb
  ~~mc
  ~~md

PUB GetPressureTemp(i2cSCL, _deviceAddress, mode, TempPtr, PressurePtr)
' Temp in 0.1°C
' Pressure in Pa
'
  repeat until result == true
    if (result := GetPressureTempA(i2cSCL, _deviceAddress, mode, TempPtr, PressurePtr)) == false
      waitcnt(delays[mode&3] + cnt)                                             '4.5ms/7.5/13.5/25.5

PUB GetPressureTempA(i2cSCL, _deviceAddress, mode, TempPtr, PressurePtr) | up
' mode is oversampling setting
'   0 - 1 sample every 4.5ms
'   1 - 2 samples every 7.5ms
'   2 - 4 samples every 13.5ms
'   3 - 8 samples every 25.5ms
' Temp in 0.1°C
' Pressure in Pa
'
  mode &= 3                                                                     'make sure 0-3
  case state
    0:
      i2cObject.WriteLocation(i2cSCL, _deviceAddress, $f4, $2e)                 'request for temp
      time := cnt
      state++
    1:
      if (cnt-time) > delays[0]                                                 '4.5ms
        temput := i2cObject.readLocation16(i2cSCL, _deviceAddress, $F6)

        i2cObject.WriteLocation(i2cSCL, _deviceAddress, $f4, $34|(mode<<6))     'request for pressure
        time := cnt
        state++

    2:
      if (cnt-time) > delays[mode]                                              '4.5ms/7.5/13.5/25.5
        up := i2cObject.readLocation24(i2cSCL, _deviceAddress, $F6)
        up >>= (8 - mode)
        state := 0
        Convert(temput, up, mode, TempPtr, PressurePtr)
        result := true

PRI Convert(ut, up, mode, TempPtr, PressurePtr) | x1, x2, b5, b6, x3, b3, p, b4, th
''
  x1 := ((ut - ac6) * ac5) ~> 15
  x2 := (mc << 11) / (x1 + md)
  b5 := x1 + x2
  long[TempPtr] := (b5 + 8) ~> 4
        
  b6 := b5 - 4000
  x1 := (b2 * ((b6 * b6) ~> 12)) ~> 11
  x2 := (ac2 * b6) ~> 11
  x3 := x1 + x2
  b3 := ((((ac1 << 2) + x3) << mode) + 2) ~> 2

  x1 := (ac3 * b6) ~> 13
  x2 := (b1 * ((b6 * b6) ~> 12)) ~> 16
  x3 := ((x1 + x2) + 2) ~> 2

  'b4 := (ac4 * (x3 + 32768)) >> 15                                             'unsigned 32 bit multiple
  b4 := umath.multdiv(ac4, (x3 + 32768), 32768)

  'b7 := (up - b3) * (50000 >> mode)                                            'unsigned 32 bit multiple
  'if b7 & $80000000
  '  p := (b7 / b4) << 1
  'else
  '  p := (b7 * 2) / b4
  p := umath.multdiv((up - b3), (100000 >> mode), b4)

  th := p ~> 8 
  x1 := th * th
  x1 := (x1 * 3038) ~> 16
  x2 := (-7357 * p) ~> 16
  long[PressurePtr] := p + ((x1 + x2 + 3791) ~> 4)
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