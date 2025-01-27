CON

  ADC_dpin      = 8
  ADC_cpin      = 9
  ADC_spin      = 7

  SDEV_MUL  = 1                 'standard deviation multiplier for ADC filter
  SAMP_N    = 4

  GATE  = 10              'multiplies numbers by this to get decimal figures using longs
  
OBJ
  ADC           : "MCP3208_fast"
'  pc    :"Parallax Serial Terminal"
'  F     : "Float32Full"

VAR
  long ADC_In[16]

  long adc_cog, adc_stack[30], adc_lock
  



PUB Start(dpin1, cpin1, spin1, dpin2, cpin2, spin2, ADC_Data) : success

  if adc_cog  
    Stop

'  adc_lock := locknew
     
  success := ( adc_cog := cognew( ADC_Cycle( dpin1, cpin1, spin1, dpin2, cpin2, spin2, ADC_Data ), @adc_stack ) + 1 )          'launch new cog

PUB Stop

              
  if adc_cog                                                         'if it's on 
    cogstop( adc_cog - 1 )                                          'kill cog



{{PUB ADCData( dest )                       'retrieve the latest unpacked data set from the control device

'  repeat until not lockset( adc_lock )                 'freezes
  longmove( dest, @ADC_Data, 8 )
'  lockclr( adc_lock )                       

  }}

PRI ADC_Cycle( dpin1, cpin1, spin1, dpin2, cpin2, spin2, ADC_Data ) | chan

'  ADC.start( dpin, cpin, spin, 0 )

'  pc.start(115200)
'  f.start

  repeat
  
      'ADC #1
    ADC.start( dpin1, cpin1, spin1, 0 )

    chan := 0                             
    repeat 8
      ADC_In[chan] := MeanIn(chan, 11)'FilterIn(chan)
      chan++

    ADC.stop




          'Calibrated Voltage Meters:
{{
    ADC_In[2] *= 10                  'Battery 1 Cell 1
    ADC_In[3] *= 10                  'Battery 1 Cell 2
    ADC_In[4] *= 10                  'Battery 1 Cell 3                 
    ADC_In[5] *= 10                  'Battery 2 Cell 1
    ADC_In[6] *= 10                  'Battery 2 Cell 2
    ADC_In[1] *= 10                  'Battery 2 Cell 3

    ADC_In[2] /= 714
    ADC_In[3] /= 718
    ADC_In[4] /= 810
    ADC_In[5] /= 704
    ADC_In[6] /= 818
    ADC_In[1] /= 831

    ADC_In[2] -= 5
    ADC_In[3] -= 9
    ADC_In[4] -= 4
    ADC_In[5] -= 6
    ADC_In[6] -= 4
    ADC_In[1] -= 5
    
}}    


      'ADC #2
    ADC.start( dpin2, cpin2, spin2, 0 )

    chan := 0                             
    repeat 8
      ADC_In[chan+8] := MeanIn(chan, 11)'FilterIn(chan)
      chan++

    ADC.stop


      'Calibrated Ammeter
'    ADC_In[8] *= 10000                                  'convert to higher digit form
'    ADC_In[8] := ADC_In[7] / 46 + 14214                'apply calibrated line formula
'    ADC_In[8] /= 10                                     'convert to miliamps 


    longmove( ADC_Data, @ADC_In, 16 )


PRI MeanIn(channel, n) : average | acc

  average~
  repeat n
    average += ADC.In(channel)

  average /= n

  return average    
  
PRI FilterIn(channel) : filtrate | avg, sdev, i, tmp, acc, samp[SAMP_N]

repeat  

  i~
  repeat SAMP_N
    samp[i] := ADC.In(channel)
    i++

'  sdev := StdDev(@samp,SAMP_N)
  avg := Mean(@samp,SAMP_N)

  i~
  acc~
  tmp~
  repeat SAMP_N        
    if( samp[i] > avg )
      if( (samp[i] - avg) =< GATE )'sdev * SDEV_MUL)                        'if no more than standard deviation away
        acc += samp[i]                                         'accumulate and incrament averaging count
        tmp++
    else
      if( (avg - samp[i]) =< GATE )'sdev * SDEV_MUL)
        acc += samp[i]
        tmp++
    i++     

  filtrate := acc / tmp

  return filtrate


{{PUB StdDev(data, n) : SDev | avg_f, avg_squares, tmp, n_f, SDev_f, i
' returns the standard deviation of data[] of n elements

  n_f := F.FFloat(n)
  avg_f := F.FFloat(0)

  i~
  repeat n
    avg_f := F.FAdd( avg_f, F.FFloat( long[data][i] ) )
    i++
    
  avg_f := F.FDiv( avg_f, n_f )
  
  avg_squares := F.FFloat(0)

  i~
  repeat n
    tmp := F.FSub( F.FFloat( long[data][i] ), avg_f )
    i++
    avg_squares := F.FAdd( avg_squares, F.FMul( tmp, tmp ) )
    
  avg_squares := F.FDiv( avg_squares, n_f )
  
  SDev_f := F.FSqr( avg_squares )

  SDev := F.FRound( SDev_f )

  return SDev

}}
PUB Mean(data, n) : Mn | Accumulator, i

  i~
  Accumulator~
  repeat n
    Accumulator += long[data][i]
    i++

  Mn := Accumulator / n 'F.FRound( F.FDiv( F.FFloat( Accumulator ), F.FFloat( n ) ) )

  return Mn

  {{

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

}}