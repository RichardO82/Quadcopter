{{

times                           Hz
        Clock Speed             1.04E+08
        PID Rate                475
        AHRS Update Rate        162
        P1->P0 Copy Rate        300
        Throttle Signal         120
}}





CON


''                                                        PINS                                                            
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  M1                            = 0             'Motors
  M2                            = 2                                     
  M3                            = 3
  M4                            = 1

  XBEE_RX                       = 5             'XBee
  XBEE_TX                       = 4



  AHRS_RX       = 22 
  AHRS_TX       = 23



  
  ADC_dpin                      = 8             'ADC
  ADC_cpin                      = 9
  ADC_spin                      = 7

''                                                      MEMORY                                                                                                                    
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'  P1_BLOCK_SIZE                 = 22            'Data bus sizes
  P0_BLOCK_SIZE                 = 22                               

  PID_NUM                       = 6             'number of things in the following list:
  
  dYAW_REF                      = 0
  dPITCH_REF                    = 1
  dROLL_REF                     = 2             'indices for the arrays of P's,I's,D's, I_ptr's, and PrevErr's
  YAW_REF                       = 3
  PITCH_REF                     = 4             
  ROLL_REF                      = 5

  LOG_BAL                       = 0                                                                                        
  LOG_dPID                      = 3
  LOG_PID                       = 6
  LOG_YPR                       = 9
  LOG_PID_RATE                  = 19                       
  
{{
  LOG_BAL                       = 0             'address of 4 longs of throttle levels
  LOG_XBEE                      = 3             'address of 5 longs of joystick data in P0_Data
  LOG_ADC                       = 9             'address of 8 ADC values
  LOG_PID_RATE                  = 18            '  "  refresh rate of PID loops  
  LOG_ON                        = 17            '  "  toggle on for data logging
}}
  P2_RC                         = 0                    'rc input index
  D_VALS                        = 16                    'derrivatives index
'  SONAR                         = LOG_ADC+2
  REP_VARS                      = 18                    'number of data reporting vars

''                                                      MOTOR CONTROL                                                                                                                    
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  PWM_FREQ                      = 500           'Thank you, SimonK
                                
  PWM_INV                       = 8192          'the value from which pulses are subtracted from to invert the PWM (ground = NPN on)
                                                 'based on the value chosen for pwm resolution (in this case 8192, always a multiple of 4)
  TH_FULL                       = 7618                                  '100% throttle
  TH_ZERO                       = 4341                                  '0% throttle
  TH_RES                        = TH_FULL - TH_ZERO                     'Resolution of the throttle; number of "steps"

  INP_SCALE                     = 5000          'scale for input of throttle signals, axis signals (0-this)
  INP_SCALE_F                   = 5000.0

  PR_JOYMAG                     = 22           'Pitch,Roll Joystick Magnitude           
  Y_JOYMAG                      = 1            'Yaw Joystick Magnitude

  LOW_THR_ON_THRESH             = 500            'Waits until throttle is below this before turning over control to the input system
  HI_THR_ON_THRESH              = 4000                  'both of these also used for emergency shutdown control                        

  LO_T_MIN                      = 1000           't_min is the low end of the throttle, the output of the throttle at the lowest throttle setting
  HI_T_MIN                      = 1500          'an alternate, higher t_min
  LO_T_MAX                      = 2500
  HI_T_MAX                      = 3000

  V_LOW                         = 500           ' low voltage threshold
  T_DN_RATE                     = 1000          ' rate at which throttle is reduced below low voltage threshold

  ADJ_AMT                       = 0.01           'ammount to increment/decrement adjustments of PID

  THRUST_USER_CONTROL           = 0             'selects user input to control throttle
  THRUST_AUTO_TAKEOFF           = 1             'selects auto takeoff method to control throttle
  THRUST_AUTO_LANDING           = 2             'selects auto landing method to control throttle

  BP_INC                        = 0.1           'increment ammount for balance point adjustment

  MAX_dYAW                      = 10            'threshold to detect and correct for meridian crossings of yaw axis
  PR_UNSAFE                     = 8100 '(90 deg.)           'square of angle that is considered unsafe and prompts shutdown and recovery system deployment

  CENTER_HOLE                   = 100            'a zone of muting to have reliable center snap positions that give zeros from joysticks
  
  FREEMODE_GAIN                 = 0.02                   'gain for accumulation of angle in FreeMode RC Control (no balance point snap)
  
  
''                                                      COMMAND CODES                                                                                                                    
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  M_OFF                         = 3
  M_ON                          = 4
  FDR_ON                        = 7
  FDR_OFF                       = 8
  TH_LOW                        = 9
  TH_HIGH                       = 10
  BALANCE                       = 1
  BAL_RST                       = 2
  BAL_YL                        = 24
  BAL_YR                        = 25
  BAL_PU                        = 26
  BAL_PD                        = 27
  BAL_RL                        = 28
  BAL_RR                        = 29
  CON_XBEE                       = 5
  CON_KEY                       = 6
  SEL_P                         = 11
  SEL_I                         = 12
  SEL_D                         = 13
  SEL_PD                        = 30
  SEL_ID                        = 31
  SEL_DD                        = 32
  SEL_aP                         = 33
  SEL_aI                         = 34
  SEL_aD                         = 35
  SEL_aPD                        = 36
  SEL_aID                        = 37
  SEL_aDD                        = 38
  SEL_PID                       = 14
  SEL_IMAX                      = 15
  SEL_INC                       = 16
  SEL_DEC                       = 17
  TUN_DY                        = 18
  TUN_DP                        = 19
  TUN_DR                        = 20
  TUN_Y                         = 21
  TUN_P                         = 22
  TUN_R                         = 23
  F_MODE_RC                     = 41
  F_MODE_GPS                    = 42
  F_MODE_RC_THR                 = 43
'  MSG_CLEAR                     = 44
  RC_MODE_BAL                   = 45
  RC_MODE_FREE                  = 46
  F_MODE_RC_DST                 = 47

''                                                      FAULT MODES                                                                                                                    
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  FAULT_PWM                     = 1             'Failure of pwm.start


  SEC_PIN                       = 16                    'P1.0 on MSP430, requires jumper
  START_MODE_PIN                = 15                    'P1.1 on MSP430, requires jumper
  

''                                    Servo Signal Elements                                                                                                                    
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  '80_000 is a tested low (10_000 increment) at 1_730_000 cycle time at 104 MHz
  '270_000  '' high

  'low  -> 769.2307692 microseconds
  'high -> 2596.153846 microseconds


  CYC_TIME      = 1_730_000 'clkfreq/60
  P_LOW         = 80_000   'clkfreq/1000
  P_HI          = 270_000   'clkfreq/500



  ESC_START_CAL   = 0
  ESC_START_FAST  = 1
  ESC_START_OK    = 2
DAT

        M1Bal           long    0
        M2Bal           long    0               'Stabilization Balance
        M3Bal           long    0
        M4Bal           long    0

        F_Mode          long    F_MODE_RC               'State selector for determining thrust output control type

        ThrustBase      long    0               'Raw thrust level, sans stabilization                     

        yaw             long    0'angle
        pitch           long    0               'measured values from AHRS
        roll            long    0
        yawRate         long    0'change in angle
        pitchRate       long    0
        rollRate        long    0
'        aX              long    0'acceleration
'        aY              long    0
'        aZ              long    0

        dyaw            long    0
        dpitch          long    0
        droll           long    0
        dyawRate        long    0
        dpitchRate      long    0
        drollRate       long    0

        lyaw            long    0
        lpitch          long    0
        lroll           long    0
        lyawRate        long    0
        lpitchRate      long    0
        lrollRate       long    0

'        sec_counter     long    0
        last_sec_c      long    0

        t_acc           long    0               
        t_tck           long    0
        last            long    0               'PID timing measurement
        t_diff          long    0
        avg_pid_rate    long    0

        yawRate_u       long    0               'PID control outputs
        pitchRate_u     long    0
        rollRate_u      long    0

        rudder          long    0               'input control vars
        aileron         long    0
        elevator        long    0
        throttle        long    0
        buttons         long    0
        buttons_last    long    0

        
        BalancePoint_Yaw        long            1.0       'storage for the balance point at which the quad hovers still.
        BalancePoint_Pitch      long            0.0      'measured values for near hover-ish balance vector
        BalancePoint_Roll       long            0.0  'needs update                        
'        BalancePoint_Thr        long            ???

        kill            long    0
        kbrd            long    0
        t_min           long    0

        fcount          long    0

        AimPoint_Elevator  long    0.0             'angle targets when in free flying mode (not bound to balance point)
        AimPoint_Aileron   long    0.0
        FreeFly         long    0               '0 for snap to balance, 1 for free flying (unbound)





OBJ

  PWM           : "PWMx8"
'  pc            : "Parallax Serial Terminal"
  f             : "Float32"

VAR

  long pid_cog
  long pid_stack[60]

  long P0_Data_c[P0_BLOCK_SIZE]

  long Px[PID_NUM]
  long Ix[PID_NUM]
  long Dx[PID_NUM]
  long I_Accx[PID_NUM]
  long I_Max[PID_NUM]
  long PrevErrx[PID_NUM]
  long Targets[PID_NUM]


PUB Start(P0_Data, P1_Data, P2_Data, fast) : success

  if pid_cog                                    
    Stop
      
  success := ( pid_cog := cognew( ThrottleProcess(P0_Data, P1_Data, P2_Data, fast), @pid_stack ) + 1 )          'launch new cog

PUB Stop

              
  if pid_cog                                                         'if it's on 
    cogstop( pid_cog - 1 )                                          'kill cog



PRI ThrottleProcess(P0_Data, P1_Data, P2_Data, fast) | hdr, i, P, D, e, sonar_tck, t_max, T_ret


  dira[27]~~                    '1/2 Frequency Output Pin

  dira[12]~~                    'Servo Signal Output for Eco FlyCam One
  outa[12]~~                    'Servo signal output pins produce output which is *inverted* to the prop chip output signal
  dira[SEC_PIN]~~               'Heartbeat signal for MSP430 to monitor and respond to in emergencies
  outa[SEC_PIN]~
  

  PID_Setup

  f.start

'  pc.start(115200)


  if fast
    ESC_StartUp( ESC_START_FAST )                   'start PWM cog and initialize ESCs, turn the props a bit to test
  else
    ESC_StartUp( ESC_START_OK )

    waitcnt(clkfreq+cnt)                                  'Wait for low throttle input for safety reasons
    throttle := LONG[P2_Data][P2_RC+3]
    repeat until throttle < LOW_THR_ON_THRESH                                  
      throttle := LONG[P2_Data][P2_RC+3]
    waitcnt(clkfreq+cnt)
    throttle := LONG[P2_Data][P2_RC+3]
    repeat until throttle > HI_THR_ON_THRESH                                  
      throttle := LONG[P2_Data][P2_RC+3]
    waitcnt(clkfreq+cnt)
    throttle := LONG[P2_Data][P2_RC+3]
    repeat until throttle < LOW_THR_ON_THRESH                                  
      throttle := LONG[P2_Data][P2_RC+3]
     





  

  t_min := LO_T_MIN
  t_max := LO_T_MAX
  kill~~
  kbrd~
  
  repeat

    lyaw       := yaw
    lpitch     := pitch
    lroll      := roll
    lyawRate   := yawRate
    lpitchRate := pitchRate
    lrollRate  := rollRate
    buttons_last := buttons
  

      ''get sensor / control data

    longmove( @yaw, P0_Data, 6 )                        'copy the 6 DOF numbers

    longmove( @rudder, P2_Data, 5)                      'copy RC controls including ground station message
     
    if( F_Mode == F_MODE_GPS )                          'replace with GPS controls if in GPS mode
      longmove( @rudder, @LONG[P1_Data][1], 4 )
     
    if( F_Mode == F_MODE_RC_THR )                       'only replace throttle if in Pressure sensor mode
      throttle := LONG[P1_Data][4]
     
    if( F_Mode == F_MODE_RC_DST )                       'only replace throttle if in Distance sensor mode
      throttle := LONG[P1_Data][4]

                               


    '''''''''''''PERFORM CHECKS ON UM6 DATA''''''''''''''

    

    if ( pitch >= 180 )
      repeat until pitch < 180
        pitch -= 360                    'an occasional (e.g.)358 comes instead of -2, so fix that here
    if ( pitch <= -180 )
      repeat until pitch > 180  
        pitch += 360
    if ( roll >= 180 )
      repeat until roll < 180  
        roll -= 360
    if ( roll <= -180 )
      repeat until roll > 180  
        roll += 360
                              
    dyaw       := yaw       - lyaw                      'create differentials
    dpitch     := pitch     - lpitch
    droll      := roll      - lroll
    dyawRate   := yawRate   - lyawRate
    dpitchRate := pitchRate - lpitchRate
    drollRate  := rollRate  - lrollRate

    if ( dyaw > MAX_dYAW ) or ( dyaw < -MAX_dYAW )                         'cancel out yaw meridian crossings
      BalancePoint_Yaw := f.fAdd(BalancePoint_Yaw, f.fFloat(dyaw))


    if ( pitch*pitch > PR_UNSAFE ) or ( roll*roll > PR_UNSAFE )    'stop motors and deploy chutes if out of safe angle zone
      fcount++
'      pc.dec(pitch)
'      pc.str(string(", "))
'      pc.dec(roll)
'      pc.str(string(", "))
'      pc.dec(fcount)
'      pc.newline
        
'      ReThrottle(0,0,0,0)
'     Fault(5)'DeployRecoverySystem
'      repeat                              
 
    '''''''''''''PERFORM CHECKS ON RC DATA''''''''''''''

    if ( LONG[P2_Data][0] > HI_THR_ON_THRESH ) AND ( LONG[P2_Data][1] < -HI_THR_ON_THRESH ) AND ( LONG[P2_Data][2] > HI_THR_ON_THRESH ) AND ( LONG[P2_Data][3] < LOW_THR_ON_THRESH )
      ReThrottle(0,0,0,0)
      Fault(20)'DeployRecoverySystem
      repeat                                            ' stop motors and deploy chutes via pushing both sticks in and down on RC

    
     '' make center hole:
    if( rudder < CENTER_HOLE ) AND ( rudder > -CENTER_HOLE )
      rudder~
    if( aileron < CENTER_HOLE ) AND ( aileron > -CENTER_HOLE )
      aileron~
    if( elevator < CENTER_HOLE ) AND ( elevator > -CENTER_HOLE )
      elevator~
                                    

    
{{
    dira[27]~~
    if buttons == 3
      outa[27]~~
    if buttons == 4
      outa[27]~
}}


'    pc.clear
'    pc.dec(yaw)
'    pc.newline

'    pc.dec(pitch)
'    pc.newline
'    pc.dec(roll)
'    pc.newline
'    pc.dec(fcount)
{{    pc.newline
    pc.dec(pitchRate)
    pc.newline
    pc.dec(rollRate)
    pc.newline
    pc.dec(rudder)
    pc.newline
    pc.dec(aileron)
    pc.newline
    pc.dec(throttle)
    pc.newline
    pc.dec(elevator)
    pc.newline
    pc.dec(buttons)
}}

    {{

    Send a signal to the MSP430 to be watched for and timed.  If there is not a signal when there should be,
    MSP430 will reset both Propeller chips.  Status pin allows the MSP430 to tell the Propeller chips that the
    startup is to be as fast as possible and returns directly to a state close to that was running just prior to
    the event which killed the heartbeat.

    
    if UM6_In[6] == (last_sec_c + 1)                  'Send Heartbeat signal
      !outa[SEC_PIN]
    last_sec_c := UM6_In[6]
    }}


    HandleGroundMessages                                'Obey commands from the ground station 

       
'    case ThrustControl
'      THRUST_USER_CONTROL:
    ThrustBase := f.fRound(f.fMul(f.fDiv(f.fFloat(throttle), INP_SCALE_F), f.fFloat(t_max-t_min)))+t_min
        
'      THRUST_AUTO_TAKEOFF:
'        if P0_Data_c[SONAR] 
        
'      THRUST_AUTO_LANDING:
 
                   
'    ThrustBase := f.fRound(f.fMul(f.fDiv(f.fFloat(throttle), f.fFloat(INP_SCALE)), f.fFloat(t_max-t_min)))+t_min


    'Desired Yaw = Previous Desired Yaw + Y_JOYMAG(rudder/INP_SCALE)

    'For yaw, BalancePoint_Yaw is a target for the desired yaw state.  For pitch and roll,
    '  BlanancePoint_Pitch and BalancePoint_Roll are trims of the true balance point (yaw not required to balance ;)
    '  when the input is to center position (center pitch, roll).
    '    - BALANCEPOINT_YAW ALWAYS CHANGES  
    
    BalancePoint_Yaw := f.fAdd(BalancePoint_Yaw,   f.fMul(f.fDiv(f.fFloat(rudder),   INP_SCALE_F), f.fFloat(Y_JOYMAG)))
    Targets[YAW_REF]   := BalancePoint_Yaw


      'Desired Pitch = Balance Point + JOYMAG(elevator/INP_SCALE)    - BALANCEPOINT_PITCH NEVER (seldom) CHANGES ;)

    if( FreeFly == 0 )          'enact FreeFly mode or Balance Snap mode
      Targets[PITCH_REF] := f.fAdd(BalancePoint_Pitch, f.fMul(f.fDiv(f.fFloat(elevator), INP_SCALE_F), f.fFloat(PR_JOYMAG)))  
      Targets[ROLL_REF]  := f.fAdd(BalancePoint_Roll,  f.fMul(f.fDiv(f.fFloat(aileron),  INP_SCALE_F), f.fFloat(PR_JOYMAG))) 

    else
      AimPoint_Elevator := f.fAdd(AimPoint_Elevator, f.fMul(f.fFloat(elevator), FREEMODE_GAIN))           'accumulate
      AimPoint_Aileron := f.fAdd(AimPoint_Aileron, f.fMul(f.fFloat(aileron), FREEMODE_GAIN))          
      Targets[PITCH_REF] := f.fAdd(BalancePoint_Pitch, f.fMul(f.fDiv(AimPoint_Elevator, INP_SCALE_F), f.fFloat(PR_JOYMAG)))  
      Targets[ROLL_REF]  := f.fAdd(BalancePoint_Roll,  f.fMul(f.fDiv(AimPoint_Aileron,  INP_SCALE_F), f.fFloat(PR_JOYMAG))) 
              
                  
              '''''''''''''PID CONTROL - done in floating point
                                                                          
'     result             =   pid( I_ptr                        Din         target               measurement          P               I               D               I_limit )

'   yawRate_0...                                                                                                                                                     
    Targets[dYAW_REF]   := fpid( @I_Accx[YAW_REF],             dyaw,       Targets[YAW_REF],    f.fFloat(yaw),       Px[YAW_REF],    Ix[YAW_REF],    Dx[YAW_REF],    I_Max[YAW_REF] )
    Targets[dPITCH_REF] := fpid( @I_Accx[PITCH_REF],           dpitch,     Targets[PITCH_REF],  f.fFloat(pitch),     Px[PITCH_REF],  Ix[PITCH_REF],  Dx[PITCH_REF],  I_Max[PITCH_REF] )
    Targets[dROLL_REF]  := fpid( @I_Accx[ROLL_REF],            droll,      Targets[ROLL_REF],   f.fFloat(roll),      Px[ROLL_REF],   Ix[ROLL_REF],   Dx[ROLL_REF],   I_Max[ROLL_REF] )
 


      'now produce the correction factors for the rate of angle from PID of the absolute angle targets
    pitchRate_u         := f.fRound(fpid( @I_Accx[dPITCH_REF], dpitchRate, Targets[dPITCH_REF], f.fFloat(pitchRate), Px[dPITCH_REF], Ix[dPITCH_REF], Dx[dPITCH_REF], I_Max[dPITCH_REF] ))
    rollRate_u          := f.fRound(fpid( @I_Accx[dROLL_REF],  drollRate,  Targets[dROLL_REF],  f.fFloat(rollRate),  Px[dROLL_REF],  Ix[dROLL_REF],  Dx[dROLL_REF],  I_Max[dROLL_REF] ))
      
    yawRate_u           := f.fRound(fpid( @I_Accx[dYAW_REF],   dyawRate,   Targets[dYAW_REF],   f.fFloat(yawRate),   Px[dYAW_REF],   Ix[dYAW_REF],   Dx[dYAW_REF],   I_Max[dYAW_REF] ))





                
                
                
                    '''''''''''''APPLY CHANGES TO MOTOR BALANCE VARS
    M1Bal := -yawRate_u + pitchRate_u + rollRate_u
    M2Bal := yawRate_u  + pitchRate_u - rollRate_u
    M3Bal := -yawRate_u - pitchRate_u - rollRate_u
    M4Bal := yawRate_u  - pitchRate_u + rollRate_u

    M1Bal += ThrustBase         'combine the thrustbase with the balancing
    M2Bal += ThrustBase
    M3Bal += ThrustBase
    M4Bal += ThrustBase


      'prevent overdriving the throttles - maintain stabilization at high throttle positions by subtracting the proportion above full from all

    if M1Bal > TH_FULL
      i := M1Bal - TH_FULL
      M1Bal -= i
      M2Bal -= i
      M3Bal -= i
      M4Bal -= i        

    if M2Bal > TH_FULL
      i := M2Bal - TH_FULL
      M1Bal -= i
      M2Bal -= i
      M3Bal -= i
      M4Bal -= i        

    if M3Bal > TH_FULL
      i := M3Bal - TH_FULL
      M1Bal -= i
      M2Bal -= i
      M3Bal -= i
      M4Bal -= i        

    if M4Bal > TH_FULL
      i := M4Bal - TH_FULL
      M1Bal -= i
      M2Bal -= i
      M3Bal -= i
      M4Bal -= i

                
    !outa[27]                                   'maintain a half frequency signal on pin 27
                  
    if(kill)
      ReThrottle(0,0,0,0)
    else
      ReThrottle( M1Bal, M2Bal, M3Bal, M4Bal )          'send the throttle changes
                 


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






    
    LONG[P0_Data][20] := f.fRound(BalancePoint_Yaw)                         'save values to log                 
    LONG[P0_Data][21] := f.fRound(BalancePoint_Pitch)                  
    LONG[P0_Data][22] := f.fRound(BalancePoint_Roll)
    LONG[P0_Data][23] := f.fRound(f.fMul(Px[dPITCH_REF], 1000.0))
    LONG[P0_Data][24] := f.fRound(f.fMul(Ix[dPITCH_REF], 1000.0))
    LONG[P0_Data][25] := f.fRound(f.fMul(Dx[dPITCH_REF], 1000.0))            
    LONG[P0_Data][26] := f.fRound(f.fMul(Px[PITCH_REF], 1000.0))
    LONG[P0_Data][27] := f.fRound(f.fMul(Ix[PITCH_REF], 1000.0))
    LONG[P0_Data][28] := f.fRound(f.fMul(Dx[PITCH_REF], 1000.0))
    LONG[P0_Data][29] := avg_pid_rate                                       'Hz
    LONG[P0_Data][30] := fcount
    LONG[P0_Data][31] := F_Mode

        
           
PUB ReThrottle( Speed1,Speed2,Speed3,Speed4 )' | h1,h2,h3,h4 
'   Updates the throttles of the motors, each Speed value has a resolution of TH_FULL - TH_ZERO = TH_RES 

  pwm.duty(M1,PWM_INV-(TH_ZERO+Speed1))
  pwm.duty(M2,PWM_INV-(TH_ZERO+Speed2))
  pwm.duty(M3,PWM_INV-(TH_ZERO+Speed3))
  pwm.duty(M4,PWM_INV-(TH_ZERO+Speed4))





PUB Fault ( code )
' Fault Routine

  repeat
    outa[27]~
    waitcnt(clkfreq+cnt)
    
    outa[27]~~
    repeat 3
      waitcnt(clkfreq+cnt)
    outa[27]~
    
    waitcnt(clkfreq+cnt)

    repeat code
      outa[27]~~
      waitcnt(clkfreq/2+cnt)
      outa[27]~
      waitcnt(clkfreq/2+cnt)




PUB ESC_StartUp( mode )

  if not pwm.start(0,  %0000_1111, PWM_FREQ)
    Fault( FAULT_PWM )

  case mode
'    ESC_START_CAL  :
{{      pwm.duty(M1,PWM_INV-TH_FULL)
      pwm.duty(M2,PWM_INV-TH_FULL)
      pwm.duty(M3,PWM_INV-TH_FULL)
      pwm.duty(M4,PWM_INV-TH_FULL)
     
      waitcnt(clkfreq+cnt)
     
      pwm.duty(M1,PWM_INV-TH_ZERO)
      pwm.duty(M2,PWM_INV-TH_ZERO)
      pwm.duty(M3,PWM_INV-TH_ZERO)
      pwm.duty(M4,PWM_INV-TH_ZERO)
     
      waitcnt(clkfreq+cnt)
     
    '  ReThrottle(TH_RES/6,TH_RES/6,TH_RES/6,TH_RES/6)      'test motors at low speed
      ReThrottle(TH_ZERO,TH_ZERO,TH_ZERO,TH_ZERO)
     
      waitcnt(clkfreq+cnt)
}}     
    ESC_START_FAST :
      pwm.duty(M1,PWM_INV-TH_ZERO)
      pwm.duty(M2,PWM_INV-TH_ZERO)
      pwm.duty(M3,PWM_INV-TH_ZERO)
      pwm.duty(M4,PWM_INV-TH_ZERO)
    
    ESC_START_OK   :
      waitcnt(clkfreq+cnt)
     
      pwm.duty(M1,PWM_INV-TH_ZERO)
      pwm.duty(M2,PWM_INV-TH_ZERO)
      pwm.duty(M3,PWM_INV-TH_ZERO)
      pwm.duty(M4,PWM_INV-TH_ZERO)
     
      waitcnt(clkfreq+cnt)
     
    '  ReThrottle(TH_RES/6,TH_RES/6,TH_RES/6,TH_RES/6)      'test motors at low speed
      ReThrottle(TH_ZERO,TH_ZERO,TH_ZERO,TH_ZERO)
     
      waitcnt(clkfreq+cnt)
     


PUB fpid( ptr_I, D, target, state, P_gain, I_gain, D_gain, I_m ) : u | err, slope, P, I
{{  Floating Point PID
              ptr_I             : address of float to accumulate I
              D                 : integer, D input (measured)
              target            : float, desired value
              state             : float, measured value
              P_gain            : float
              I_gain            : float
              D_gain            : float
              PID_gain          : float, master gain (usually 1 or 0)
              I_m               : float, maximum and (*-1)minimum applied to I 
}}

  err := f.FSub( target, state )
  P := f.FMul( P_gain, err )

  long[ptr_I][0] := f.FAdd( long[ptr_I][0], err )

  if f.FCmp( long[ptr_I][0], I_m ) == 1
    long[ptr_I][0] := I_m

  if f.FCmp( long[ptr_I][0], f.fMul( I_m, f.FFloat(-1) ) ) == -1
    long[ptr_I][0] := f.fMUL( I_m, f.FFloat(-1) )

'  D := f.FMul( D_gain, f.fFloat(D) )                   'D CURRENTLY NOT USED (all gains 0)

'  u := f.FAdd( f.fAdd( P, f.fMul( long[ptr_I][0], I_gain ) ), D )                        'FOR USE WITH D
  u := f.fAdd( P, f.fMul( long[ptr_I][0], I_gain ) )

  return u   



PUB PID_Setup | i
  i~
  repeat PID_NUM                     'Set initial PID values
    I_Accx[i] := 0
    PrevErrx[i] := 0
    Targets[i] := 0 
    i++
  

  Px[dYAW_REF]      := 4.0                                'values calibrated for stable flight.
  Ix[dYAW_REF]      := 0.0
  Dx[dYAW_REF]      := 0.0
  I_Max[dYAW_REF]   := 10.0

  Px[dPITCH_REF]    := 3.6
  Ix[dPITCH_REF]    := -0.1
  Dx[dPITCH_REF]    := 0.0
  I_Max[dPITCH_REF] := 1000.0

  Px[dROLL_REF]     := 3.6
  Ix[dROLL_REF]     := -0.1
  Dx[dROLL_REF]     := 0.0
  I_Max[dROLL_REF]  := 1000.0

  Px[YAW_REF]       := 4.0
  Ix[YAW_REF]       := 0.0
  Dx[YAW_REF]       := 0.0
  I_Max[YAW_REF]    := 0.0

  Px[PITCH_REF]     := 4.0
  Ix[PITCH_REF]     := -0.1
  Dx[PITCH_REF]     := 0.0 
  I_Max[PITCH_REF]  := 100.0

  Px[ROLL_REF]      := 4.0
  Ix[ROLL_REF]      := -0.1
  Dx[ROLL_REF]      := 0.0
  I_Max[ROLL_REF]   := 100.0


PUB DeployRecoverySystem | i

  dira[27]~~

  repeat
    !outa[27]
    waitcnt(clkfreq/8+cnt)


    
PRI HandleGroundMessages
                                 'ONLY RUNS if buttons has changed - produces a single instance per command.
                                  'repeats of the same command (e.g. non-state commands) require pause then change to an undefined number
    if buttons_last <> buttons
      case buttons
        BAL_YL                    : BalancePoint_Yaw   := f.fSub( BalancePoint_Yaw,   BP_INC )
        BAL_YR                    : BalancePoint_Yaw   := f.fAdd( BalancePoint_Yaw,   BP_INC )
        BAL_PU                    : BalancePoint_Pitch := f.fAdd( BalancePoint_Pitch, BP_INC )
        BAL_PD                    : BalancePoint_Pitch := f.fSub( BalancePoint_Pitch, BP_INC )
        BAL_RL                    : BalancePoint_Roll  := f.fSub( BalancePoint_Roll,  BP_INC )
        BAL_RR                    : BalancePoint_Roll  := f.fAdd( BalancePoint_Roll,  BP_INC )
        
        M_OFF                     : kill~~      
        M_ON                      : BalancePoint_Yaw := f.fFloat(Yaw)  'prevent yaw jumps
                                    kill~                                    
                                                 
        CON_XBEE                  : kbrd~
        CON_KEY                   : kbrd~~
        F_MODE_RC                 : F_Mode := F_MODE_RC
        F_MODE_GPS                : F_Mode := F_MODE_GPS
        F_MODE_RC_THR             : F_Mode := F_MODE_RC_THR
        F_MODE_RC_DST             : F_Mode := F_MODE_RC_DST

        RC_MODE_BAL               : FreeFly := 0
        RC_MODE_FREE              : FreeFly := 1
                                    AimPoint_Elevator := 0.0
                                    AimPoint_Aileron := 0.0                     'start from current angle
   
   
             'Apply buttons
   
       
  '    if buttons == FDR_ON'& %0000_0000_0000_0100
  '      P0_Data_c[LOG_ON] := 1
  '      FallingEdge(12)           'engage the FlyCam       'CAUSES SYSTEM CRASH HERE IF UNCOMMENTED
       
  '    if buttons == FDR_OFF'& %0000_0000_0001_0000
  '      P0_Data_c[LOG_ON] := 0
  '      FallingEdge(12)           'disengage the FlyCam    'CAUSES SYSTEM CRASH HERE IF UNCOMMENTED
       
      if buttons == TH_LOW'& %0000_0010_0000_0000
        t_min := LO_T_MIN
       
      if buttons == TH_HIGH'& %0000_0001_0000_0000
        t_min := HI_T_MIN
             
      if buttons == BALANCE '& %0000_0000_0000_0001
        BalancePoint_Yaw := Targets[YAW_REF]            
        BalancePoint_Pitch := Targets[PITCH_REF]
        BalancePoint_Roll := Targets[ROLL_REF]
         
      if buttons == BAL_RST'& %0000_0000_0000_0010
        BalancePoint_Yaw := 0.0
        BalancePoint_Pitch := 0.0
        BalancePoint_Roll := 0.0
   
      if buttons == SEL_P
        Px[dPITCH_REF] := f.fAdd( Px[dPITCH_REF], ADJ_AMT )
        Px[dROLL_REF]  := f.fAdd( Px[dROLL_REF],  ADJ_AMT )
  '      Tune_Mode := 0'@Px[Tune_Chan]
       
      if buttons == SEL_I
        Ix[dPITCH_REF] := f.fAdd( Ix[dPITCH_REF], ADJ_AMT )
        Ix[dROLL_REF]  := f.fAdd( Ix[dROLL_REF],  ADJ_AMT )
  '      Tune_Mode := 1'@Ix[Tune_Chan]
       
      if buttons == SEL_D
        Dx[dPITCH_REF] := f.fAdd( Dx[dPITCH_REF], ADJ_AMT )
        Dx[dROLL_REF]  := f.fAdd( Dx[dROLL_REF],  ADJ_AMT )
  '      Tune_Mode := 2'@Dx[Tune_Chan]
   
      if buttons == SEL_PD
        Px[dPITCH_REF] := f.fSub( Px[dPITCH_REF], ADJ_AMT )
        Px[dROLL_REF]  := f.fSub( Px[dROLL_REF],  ADJ_AMT )
   
      if buttons == SEL_ID
        Ix[dPITCH_REF] := f.fSub( Ix[dPITCH_REF], ADJ_AMT )
        Ix[dROLL_REF]  := f.fSub( Ix[dROLL_REF],  ADJ_AMT )
   
      if buttons == SEL_DD
        Dx[dPITCH_REF] := f.fSub( Dx[dPITCH_REF], ADJ_AMT )
        Dx[dROLL_REF]  := f.fSub( Dx[dROLL_REF],  ADJ_AMT )
       
      if buttons == SEL_aP
        Px[PITCH_REF] := f.fAdd( Px[PITCH_REF], ADJ_AMT )
        Px[ROLL_REF]  := f.fAdd( Px[ROLL_REF],  ADJ_AMT )
  '      Tune_Mode := 0'@Px[Tune_Chan]
       
      if buttons == SEL_aI
        Ix[PITCH_REF] := f.fAdd( Ix[PITCH_REF], ADJ_AMT )
        Ix[ROLL_REF]  := f.fAdd( Ix[ROLL_REF],  ADJ_AMT )
  '      Tune_Mode := 1'@Ix[Tune_Chan]
       
      if buttons == SEL_aD
        Dx[PITCH_REF] := f.fAdd( Dx[PITCH_REF], ADJ_AMT )
        Dx[ROLL_REF]  := f.fAdd( Dx[ROLL_REF],  ADJ_AMT )
  '      Tune_Mode := 2'@Dx[Tune_Chan]
   
      if buttons == SEL_aPD
        Px[PITCH_REF] := f.fSub( Px[PITCH_REF], ADJ_AMT )
        Px[ROLL_REF]  := f.fSub( Px[ROLL_REF],  ADJ_AMT )
   
      if buttons == SEL_aID
        Ix[PITCH_REF] := f.fSub( Ix[PITCH_REF], ADJ_AMT )
        Ix[ROLL_REF]  := f.fSub( Ix[ROLL_REF],  ADJ_AMT )
   
      if buttons == SEL_aDD
        Dx[PITCH_REF] := f.fSub( Dx[PITCH_REF], ADJ_AMT )
        Dx[ROLL_REF]  := f.fSub( Dx[ROLL_REF],  ADJ_AMT )
    