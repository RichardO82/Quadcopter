

//  Normal Startup Signal        :  Everything LOW
//  Emergency Fast Startup Signal:  START_MODE_PIN HIGH / SEC_PIN LOW


#include <msp430g2231.h>

#ifndef TIMER0_A1_VECTOR
#define TIMER0_A1_VECTOR    TIMERA1_VECTOR
#define TIMER0_A0_VECTOR    TIMERA0_VECTOR
#endif

#define START_MODE_PIN		BIT1
#define SEC_PIN				BIT0
#define P0RST				BIT6
#define P1RST				BIT7

#define RST_LOW				1	//reset modes
#define RST_WAIT			2

#define RST_LOW_TIME		100	//cycle times for delays
#define EDGE_WAIT_TIME		800

volatile long tempRaw=0;
volatile int FoundRisingEdge=0;
volatile int Resetting=0;
volatile unsigned int i;

void FaultRoutine(void);
void ConfigWDT(void);
void ConfigClocks(void);
void ConfigLEDs(void);
void ConfigADC10(void);
void ConfigTimerA2(void);

void WaitforRisingEdge(void);

void main(void)
{

  ConfigWDT();
  ConfigClocks();
  ConfigLEDs();
  ConfigADC10();
//  ConfigTimerA2();

  _BIS_SR(GIE);

 //Give Normal Startup Signal to P0, P1... RSTs HIGH / START_MODE_PIN LOW
  P1OUT = P0RST + P1RST;

  //Wait for the first rising edge, then start the timer
  WaitforRisingEdge();
  ConfigTimerA2();



  while(1)
  {
	  WaitforRisingEdge();
	  FoundRisingEdge = 1;

   /* if(P1IN & SEC_PIN)
    {
	   P1OUT |= BIT0;
	   for (i = 100; i > 0; i--);
	   P1OUT &= ~BIT0;
	   for (i = 10000; i > 0; i--);
    }*/
  }
}

void ConfigWDT(void)
 {
 WDTCTL = WDTPW + WDTHOLD;                 	// Stop watchdog timer
 }

void ConfigClocks(void)
 {
 if (CALBC1_1MHZ ==0xFF || CALDCO_1MHZ == 0xFF)
   FaultRoutine();		                    // If calibration data is erased
 				                            // run FaultRoutine()
  BCSCTL1 = CALBC1_1MHZ; 					// Set range
  DCOCTL = CALDCO_1MHZ;  					// Set DCO step + modulation
  BCSCTL3 |= LFXT1S_2;                      // LFXT1 = VLO
  IFG1 &= ~OFIFG;                           // Clear OSCFault flag
  BCSCTL2 |= SELM_0 + DIVM_3 + DIVS_3;      // MCLK = DCO/8, SMCLK = DCO/8
 }

void FaultRoutine(void)
 {
   P1OUT = BIT0;                            // P1.0 on (red LED)
   while(1); 			                    // TRAP
 }

void ConfigLEDs(void)
 {
  P1DIR = START_MODE_PIN + P0RST + P1RST;                         // SEC_PIN is input
  P1OUT = 0;                                // LEDs off
 }

void ConfigADC10(void)
 {
  ADC10CTL1 = INCH_10 + ADC10DIV_0;        // Temp Sensor ADC10CLK
 }

void ConfigTimerA2(void)
  {
   CCTL0 = CCIE;
   CCR0 = 12000;
   TACTL = TASSEL_1 + MC_2;
  }

#pragma vector=TIMER0_A0_VECTOR
__interrupt void Timer_A (void)
{
  ADC10CTL0 = SREF_1 + ADC10SHT_3 + REFON + ADC10ON;
  _delay_cycles(5);                         // Wait for ADC Ref to settle
  ADC10CTL0 |= ENC + ADC10SC;               // Sampling and conversion start
 // P1OUT |= BIT6; 			                // P1.6 on (green LED)
  _delay_cycles(100);
  ADC10CTL0 &= ~ENC;				   		// Disable ADC conversion
  ADC10CTL0 &= ~(REFON + ADC10ON);        	// Ref and ADC10 off
  tempRaw = ADC10MEM;						// Read conversion value
  P1OUT &= ~BIT0; 				                // green LED off
  //CCR0 +=12000;								// add 1 second to the timer


  // Resetting          - holds state of reset process, with 0 being no resetting
  // FoundRisingEdge	- holds state of security signal
  // P1OUT	            - holds state of outputs
  // CCR0               - time of next delay to add before the interrupt is run again

  switch( Resetting )
  {

  case RST_WAIT:
  	  if(FoundRisingEdge) Resetting = 0;	//go back to monitoring for reset
  	  CCR0 += EDGE_WAIT_TIME;
  	  break;

  case RST_LOW:
	  P1OUT = START_MODE_PIN + P0RST + P1RST;
	  Resetting = RST_WAIT;
	  CCR0 += EDGE_WAIT_TIME;
	  break;

  case 0:  // normal state
	  if(FoundRisingEdge) 			//A new rising edge was found
	  {
		  FoundRisingEdge = 0;		// set up for next pulse
		  CCR0 += EDGE_WAIT_TIME;
	  }
	  else
	  {
		  if(Resetting != RST_WAIT)	   // only if not in wait mode, have to give time for high P0RST,P1Rst to produce rising edge
		  {
			  P1OUT = START_MODE_PIN;	//put the resets low on P0 and P1 + emergency fast startup signal
			  Resetting = RST_LOW;			//temporarily
			  CCR0 += RST_LOW_TIME;
		  }
	  }
	  break;

  }

}




  /*

  if(Resetting == RST_WAIT)
  {
	  Resetting = 0;
  }

  if(Resetting == RST_LOW)
  {												// ...one little while later
	 P1OUT =  P0RST + P1RST + START_MODE_PIN; //keep emergency startup signal, turn props back on
	 Resetting = RST_WAIT;	 	 	 	 	 	 	 	 	 	// 'resetting' will remain until rising edge is found
  }


  if(FoundRisingEdge) 			//A new rising edge was found
  {
	  FoundRisingEdge = 0;		// set up for next pulse
//	  Resetting = 0;			// stop resetting
  }
  else
  {
	  if(Resetting != RST_WAIT)	   // only if not in wait mode, have to give time for high P0RST,P1Rst to produce rising edge
	  {
		  P1OUT = START_MODE_PIN;	//put the resets low on P0 and P1 + emergency fast startup signal
		  Resetting = RST_LOW;			//temporarilly
		  CCR0 += RST_LOW_TIME;
	  }
  }


  if( Resetting != RST_LOW ) CCR0 += EDGE_WAIT_TIME;								// add 1 second to the timer


}*/

void WaitforRisingEdge(void)
{
	while(P1IN & SEC_PIN);
	while(!(P1IN & SEC_PIN));
}

