{
 ************************************************************************************************************
 *                                                                                                          *
 *  AUTO-RECOVER NOTICE: This file was automatically recovered from an earlier Propeller Tool session.      *
 *                                                                                                          *
 *  ORIGINAL FOLDER:     C:\Users\ManServant\Documents\Propeller\BMP085\                                    *
 *  TIME AUTO-SAVED:     over 5 days ago (11/13/2013 6:56:11 PM)                                            *
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
CON

  BMP_ADR       = %1110_1110    '$EE





VAR


  long bmp_cog, bmp_stack[50]

OBJ

  pc    :       "Parallax Serial Terminal"
  bmp   :       "bmp085Object"




PUB Start( scl, n, data ) : success

  if bmp_cog                                                         'if it's on 
    cogstop( bmp_cog - 1 )                                          'kill cog

  bmp.init(SCL, BMP_ADR)

  success := ( bmp_cog := cognew( BMP_Read(scl, n, data ), @bmp_stack ) + 1 )          'launch new cog

PUB Stop

  if bmp_cog                                                         'if it's on 
    cogstop( bmp_cog - 1 )                                          'kill cog


PRI BMP_Read( scl, n, data ) | i, Temp, Pressure, presamp, cyc


  waitcnt(clkfreq+cnt)'?

  repeat
'    cyc := cnt
    pressure~
    repeat n
      bmp.GetPressureTemp(SCL, BMP_ADR, 3, @Temp, @presamp)
      pressure += presamp
    pressure /= n    

'    if pressure >= 65535
'      pressure -= 65535

    long[data][0] := pressure
     
     
'    cyc := cnt - cyc
'    pc.dec(temp)
'    pc.str(string(", "))
'    pc.dec(pressure)
'    pc.str(string(", "))
'    pc.dec(cyc/(clkfreq/1000))    
'    pc.newline