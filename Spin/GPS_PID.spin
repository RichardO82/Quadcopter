CON
'  P3_BLOCK_SIZE                 = 57                               

  PID_NUM                       = 6             'number of things in the following list:
  
  VelN_REF                      = 0
  VelE_REF                      = 1
  Pressure_REF                  = 2             'indices for the arrays of P's,I's,D's, I_ptr's, and PrevErr's
  PosN_REF                      = 3
  PosE_REF                      = 4             
  PosH_REF                      = 5
  Distance_REF                  = 6

  F_MODE_RC                     = 41            'RC Control
  F_MODE_GPS                    = 42            'GPS Control
  F_MODE_RC_THR                 = 43            'RC Control + Pressure Controlled Alititude
  F_MODE_RC_DST                 = 44            'RC Control + Distance Sensor Controlled Altitude

  P0_YAW                        = 0
  P0_FMODE                      = 31
  P2_THR                        = 3
  P3_PRESSURE                   = 0

  P0_POSN                       = 14
  P1_GPS_PID_R                  = 0

  INP_SCALE                     = 5000          'scale for input of throttle signals, axis signals (0-this)
  Y_JOYMAG                      = 1            'PosN Joystick Magnitude

  GPS_HEIGHT_VARIANCE           = 15                  'to allow for some GPS drift, pressure may drift within this height (+/-m).  Outside this distance, pressure clips to GPS to correct for weather changes
  PRESSURE_VARIANCE_ADJ         = 10.0                  'intensity of adjustments made to correct for weather drift (speed of correction)


DAT



  PosN        long 0
  PosE        long 0
  PosH        long 0
  VelN        long 0
  VelE        long 0        
  VelH        long 0
  GPSSpeed    long 0
  GPSCourse   long 0
  Satelites   long 0

  F_Mode      long F_MODE_RC
  lF_Mode     long F_MODE_RC

  F_Mode_Sig  long 0

  yaw         long 0
  yaw_hold    long 0

  thr         long 0
  thr_delta   long 0

  pressure    long 0
  distance    long 0

  dVelN       long 0
  dVelE       long 0
  dVelH       long 0

  TarN        long 0.0
  TarE        long 0.0
  TarH        long 0.0

  qPosN       long 0
  qPosE       long 0

  lPosN       long 0
  lPosE       long 0
  lPosH       long 0
  lVelN       long 0
  lVelE       long 0
  lVelH       long 0

  t_acc       long 0               
  t_tck       long 0
  last        long 0               'PID timing measurement
  t_diff      long 0

  yaw_u       long 0               'PID control outputs
  pitch_u     long 0
  roll_u      long 0

  avg_pid_rate    long 0
  gps_rud         long 0
  gps_ail         long 0
  gps_ele         long 0
  gps_thr         long 0          
'        gps_but         long    0        




OBJ

'  pc            : "Parallax Serial Terminal"
  f             : "Float32"

VAR

  long pid_cog
  long pid_stack[60]

'  long P3Data_c[P3_BLOCK_SIZE]

  long Px[PID_NUM]
  long Ix[PID_NUM]
  long Dx[PID_NUM]
'  long PIDx[PID_NUM]
  long I_Accx[PID_NUM]
  long I_Max[PID_NUM]
  long PrevErrx[PID_NUM]
  long Targets[PID_NUM]

  long temp_stack[30]

  long l_thr[40]

 
PUB Start(P0_Data, P1_Data, P2_Data, P3_Data) : success

  if pid_cog                                    
    Stop
      
  success := ( pid_cog := cognew( GPSProcess(P0_Data, P1_Data, P2_Data, P3_Data), @pid_stack ) + 1 )          'launch new cog

PUB Stop

              
  if pid_cog                                                         'if it's on 
    cogstop( pid_cog - 1 )                                          'kill cog



PRI GPSProcess(P0_Data, P1_Data, P2_Data, P3_Data) | i, s, c



  PID_Setup

  f.start

'  cognew(t_cog, @temp_stack)

'pc.start(115200)

  repeat

    lPosN := PosN
    lPosE := PosE
    lPosH := PosH
    lVelN := VelN
    lVelE := VelE
    lVelH := VelH
  

      ''get sensor data / save reporting data

'    repeat until not lockset( data_lock )
    
    longmove(@PosN, @long[P0_Data][P0_POSN], 6)
    
    F_Mode   := long[P0_Data][P0_FMODE]
    yaw      := long[P0_Data][P0_YAW]
    thr      := long[P2_Data][P2_THR]
    pressure := long[P3_Data][P3_PRESSURE]
    distance := long[P2_Data][6]
    
    longmove(@long[P1_Data][P1_GPS_PID_R], @avg_pid_rate, 5)
        
'    lockclr( data_lock )

'    yaw := f.fFloat(yaw)      'duplicate of below
    

    VelN := f.fSub(PosN, lPosN)
    VelE := f.fSub(PosE, lPosE)
'    VelH := f.fSub(PosH, lPosH)
    dVelN := f.fSub(VelN, lVelN)
    dVelE := f.fSub(VelE, lVelE)
    dVelH := f.fSub(VelH, lVelH) 
    


    '''''''''''''PERFORM CHECKS ON GPS DATA''''''''''''''

    if (F_Mode == F_MODE_GPS) and (lF_Mode <> F_MODE_GPS) 'gps control has been switched on
      TarN := PosN
      TarE := PosE                 'set the target position to the current position
      TarH := PosH

      yaw_hold := yaw
      gps_thr := thr

      Targets[Pressure_REF] := f.fFloat(pressure)

    if (F_Mode == F_MODE_RC_THR) and (lF_Mode <> F_MODE_RC_THR) 'Pressure throttle only control has been switched on
      gps_thr := thr
      Targets[Pressure_REF] := f.fFloat(pressure)

    if (F_Mode == F_MODE_RC_DST) and (lF_Mode <> F_MODE_RC_DST) 'Distance throttle only control has been switched on
      gps_thr := thr
      Targets[Distance_REF] := f.fFloat(distance)

    if (F_Mode == F_MODE_RC)    'keep throttle close so no jerky transitions
      Targets[Pressure_REF] := f.fFloat(pressure)
      Targets[Distance_REF] := f.fFloat(distance)
      gps_thr := thr

      
    'set lasts  
    lF_mode := F_Mode


      'GPS altitude correction
{{
    if f.fRound(f.fSub(PosH, TarH)) > GPS_HEIGHT_VARIANCE
      Targets[Pressure_REF] := f.fAdd( Targets[Pressure_REF], PRESSURE_VARIANCE_ADJ)   'increase pressure to decrease height
    if f.fRound(f.fSub(TarH, PosH)) > GPS_HEIGHT_VARIANCE
      Targets[Pressure_REF] := f.fSub( Targets[Pressure_REF], PRESSURE_VARIANCE_ADJ)   'decrease pressure to increase height
}}



    ''''''''''''ROTATE TARGET POINT FROM GPS SPACE TO QUAD SPACE''''''''''''''''
    yaw := f.fFloat(yaw)                                                        'from here on yaw will need to be float

    qPosE := f.fSub(TarE, PosE)                     'x
    qPosN := f.fSub(TarN, PosN)                     'y  'coordinate space for rotation
    
    Targets[PosH_REF] := f.fSub(TarH, PosH)         'z                          'note z is the desired altitude in quad space 
                                                                                'with the quad being at 0.0 (origin).
    s := f.Sin(f.Radians(yaw))
    c := f.Cos(f.Radians(yaw))

    Targets[PosE_REF] := f.fSub(f.fMul(qPosE,c), f.fMul(qPosN,s))
    Targets[PosN_REF] := f.fAdd(f.fMul(qPosE,s), f.fMul(qPosN,c))    
    



''''''''''''WHY IS MEASUREMENT 0.0??????????

''''''''''''''WHY?     (below)


    '''''' BECAUSE: Everything is converted into the copter's coordinate system, so the measured position of the quad
                 '' is at the origin. ...see above

              
                  
              '''''''''''''PID CONTROL - done in floating point
                                                                          
'     result           =          pid(  I_ptr              Din   target              measurement     P             I               D              I_limit )


    Targets[VelN_REF] :=          fpid( @I_Accx[PosN_REF], VelN, Targets[PosN_REF],  0.0,            Px[PosN_REF], Ix[PosN_REF],   Dx[PosN_REF],  I_Max[PosN_REF] )
    Targets[VelE_REF] :=          fpid( @I_Accx[PosE_REF], VelE, Targets[PosE_REF],  0.0,            Px[PosE_REF], Ix[PosE_REF],   Dx[PosE_REF],  I_Max[PosE_REF] )
'    Targets[VelH_REF] :=          fpid( @I_Accx[PosH_REF], VelH, Targets[PosH_REF],  0.0,            Px[PosH_REF], Ix[PosH_REF],   Dx[PosH_REF],  I_Max[PosH_REF] )
 


      'now produce the angles which will impart acceleration to the quad body
    gps_ail           := f.fRound(fpid( @I_Accx[VelE_REF], dVelE, Targets[VelE_REF], f.fFloat(VelE), Px[VelE_REF], Ix[VelE_REF], Dx[VelE_REF], I_Max[VelE_REF] ))
    gps_ele           := -f.fRound(fpid( @I_Accx[VelN_REF], dVelN, Targets[VelN_REF], f.fFloat(VelN), Px[VelN_REF], Ix[VelN_REF], Dx[VelN_REF], I_Max[VelN_REF] ))
                          'negative elevator stick orientation

    gps_rud := yaw_hold - f.fRound(yaw)                'just maintain the same yaw. (simple P)


'    gps_thr           := f.fRound(fpid( @I_Accx[VelH_REF], dVelH, Targets[VelH_REF], f.fFloat(VelH), Px[VelH_REF], Ix[VelH_REF], Dx[VelH_REF], I_Max[VelH_REF] ))
    if( F_Mode == F_MODE_RC_DST )
      thr_delta :=          f.fRound(fpid( @I_Accx[Distance_REF], 0, Targets[Distance_REF], f.fFloat(distance), Px[Distance_REF], Ix[Distance_REF], Dx[Distance_REF], I_Max[Distance_REF] ))
      gps_thr += thr_delta
    else
      thr_delta :=          f.fRound(fpid( @I_Accx[Pressure_REF], 0, Targets[Pressure_REF], f.fFloat(pressure), Px[Pressure_REF], Ix[Pressure_REF], Dx[Pressure_REF], I_Max[Pressure_REF] ))
      gps_thr  -= thr_delta
                                'note, all the stuff before about thr_hold = last throttle[40], now doesnt' do anything :( ...":="

    ''''''''''''''''''''''' CONSTRAIN OUTPUTS

    if gps_thr > INP_SCALE
      gps_Thr := INP_SCALE

    if gps_thr < 0
      gps_thr := 0

    if gps_ail > INP_SCALE
      gps_ail := INP_SCALE

    if gps_ail < -INP_SCALE
      gps_ail := -INP_SCALE

    if gps_ele > INP_SCALE
      gps_ele := INP_SCALE

    if gps_ele < -INP_SCALE
      gps_ele := -INP_SCALE
    
    if gps_rud > INP_SCALE
      gps_rud := INP_SCALE

    if gps_rud < -INP_SCALE
      gps_rud := -INP_SCALE
    
     
'''''''''''''''''''''''''''''''''''''''''' ... ...   .  .  .
{{
    pc.clear
    i~
     
    pc.dec(f.fRound(PosN))
    pc.newline
    pc.dec(f.fRound(PosE))
    pc.newline
    pc.dec(f.fRound(PosH))
    pc.newline
    pc.newline
    pc.dec(f.fRound(TarN))
    pc.newline
    pc.dec(f.fRound(TarE))
    pc.newline
    pc.dec(f.fRound(TarH))
    pc.newline
    pc.newline
    pc.dec(f.fRound(yaw))
    pc.newline
    pc.dec(yaw_hold)
    pc.newline
    pc.newline
    pc.dec(gps_rud)
    pc.newline
    pc.dec(gps_ele)
    pc.newline
    pc.dec(gps_ail)
    pc.newline
    pc.dec(gps_thr)
    
  
    waitcnt(clkfreq/20+cnt)  
}}




                
                  ''''''''''' REPORT UPDATE FREQUENCY
    i := cnt
    t_diff := i-last
    last := i      
    t_acc += clkfreq/t_diff
    t_tck++  
    if t_tck > 100                              ' reset the average every 100 (~half second)
      avg_pid_rate := t_acc / t_tck
      t_tck~   'tracks the sample number (n)
      t_acc~   'accumulates data for cycles per second (Hz)



PUB fpid( ptr_I, D, target, state, P_gain, I_gain, D_gain, I_m ) : u | err, slope, P, I
{{  Floating Point PID
              ptr_I             : address of float to accumulate I
              D                 : integer, D input (measured)
              target            : float, desired value
              state             : float, measured value
              P_gain            : float
              I_gain            : float
              D_gain            : float
              I_m               : float, maximum and (*-1)minimum applied to I 
}}

  err := f.FSub( target, state )
  P := f.FMul( P_gain, err )

  long[ptr_I][0] := f.FAdd( long[ptr_I][0], err )

  if f.FCmp( long[ptr_I][0], I_m ) == 1
    long[ptr_I][0] := I_m

  if f.FCmp( long[ptr_I][0], f.fMul( I_m, f.FFloat(-1) ) ) == -1
    long[ptr_I][0] := f.fMUL( I_m, f.FFloat(-1) )

  D := f.FMul( D_gain, f.fFloat(D) )

'  u := f.FMul( PID_gain, f.FAdd( f.fAdd( P, f.fMul( long[ptr_I][0], I_gain ) ), D ) )
  u := f.FAdd( f.fAdd( P, f.fMul( long[ptr_I][0], I_gain ) ), D )

  return u   



PUB PID_Setup | i
  i~
  repeat PID_NUM                     'Set initial PID values
    I_Accx[i] := 0
    PrevErrx[i] := 0
    Targets[i] := 0 
    i++
  

  Px[VelN_REF]      := 4.0
  Ix[VelN_REF]      := 0.0
  Dx[VelN_REF]      := 0.0
  I_Max[VelN_REF]   := 10.0

  Px[VelE_REF]    := 4.0
  Ix[VelE_REF]    := 0.0
  Dx[VelE_REF]    := 0.0
  I_Max[VelE_REF] := 1000.0

  Px[Pressure_REF]     := 1.0
  Ix[Pressure_REF]     := 0.0
  Dx[Pressure_REF]     := 0.0
  I_Max[Pressure_REF]  := 1000.0

  Px[PosN_REF]       := 4.0
  Ix[PosN_REF]       := 0.0
  Dx[PosN_REF]       := 0.0
  I_Max[PosN_REF]    := 0.0

  Px[PosE_REF]     := 4.0
  Ix[PosE_REF]     := 0.0
  Dx[PosE_REF]     := 0.0 
  I_Max[PosE_REF]  := 100.0

  Px[PosH_REF]      := 4.0
  Ix[PosH_REF]      := 0.0
  Dx[PosH_REF]      := 0.0
  I_Max[PosH_REF]   := 100.0

  Px[Distance_REF]      := 4.0
  Ix[Distance_REF]      := 0.0
  Dx[Distance_REF]      := 0.0
  I_Max[Distance_REF]   := 100.0

{{

PRI t_cog | i

  pc.start(115200)

  repeat
    pc.clear
    i~

    pc.str(string("thr_delta: "))
    pc.dec(thr_delta)
    pc.newline
    pc.str(string("thr: "))
    pc.dec(thr)
    pc.newline
    pc.str(string("gps_thr: "))
    pc.dec(gps_thr)
    pc.newline
    pc.str(string("pressure: "))
    pc.dec(pressure)
    pc.newline
  
    waitcnt(clkfreq/20+cnt)  
  }}   