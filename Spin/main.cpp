/* UAV CONTROL TERMINAL

  Send and receive commands to the UAV Via XBee wireless comm link
  
    \author  Richard Overman
  
  GL Graphics taken from example program written by:
              
    \author  Written by Nigel Stewart November 2003

    \author  Portions Copyright (C) 2004, the OpenGLUT project contributors. <br>
             OpenGLUT branched from freeglut in February, 2004.
 
    \image   html openglut_shapes.png OpenGLUT Geometric Shapes Demonstration
    \include demos/shapes/shapes.c
*/

#include <GL/freeglut.h>

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
//#include "rs232.h"

#ifdef _MSC_VER
/* DUMP MEMORY LEAKS */
#include <crtdbg.h>
#endif

/*
 * This macro is only intended to be used on arrays, of course.
 */
#define NUMBEROF(x) ((sizeof(x))/(sizeof(x[0])))

#define BYTETOBINARYPATTERN "%d%d%d%d%d%d%d%d"
#define BYTETOBINARY(byte)  \
  (byte & 0x80 ? 1 : 0), \
  (byte & 0x40 ? 1 : 0), \
  (byte & 0x20 ? 1 : 0), \
  (byte & 0x10 ? 1 : 0), \
  (byte & 0x08 ? 1 : 0), \
  (byte & 0x04 ? 1 : 0), \
  (byte & 0x02 ? 1 : 0), \
  (byte & 0x01 ? 1 : 0)





#define COMPORT     "COM4"
#define COMCODE     32491                       // code or'd into checksum - "the magic word" - please

#define PIDTUNE     1
#define NORMCON     0

#define PID_NUM     6                           // number of PID controlled parameters

#define M_OFF       3
#define M_ON        4
#define FDR_ON      7
#define FDR_OFF     8
#define TH_LOW      9
#define TH_HIGH     10
#define BALANCE     1
#define BAL_RST     2
#define CON_JOY     5
#define CON_KEY     6

#define SEL_P       11
#define SEL_I       12
#define SEL_D       13
#define SEL_PD       30
#define SEL_ID       31
#define SEL_DD       32

#define SEL_aP       33
#define SEL_aI       34
#define SEL_aD       35
#define SEL_aPD       36
#define SEL_aID       37
#define SEL_aDD       38

#define SEL_PID     14

#define SEL_IMAX    15
#define SEL_INC     16
#define SEL_DEC     17
#define TUN_DY      18
#define TUN_DP      19
#define TUN_DR      20
#define TUN_Y       21
#define TUN_P       22
#define TUN_R       23
#define REQUEST     24

#define  BAL_YL     24
#define  BAL_YR     25
#define  BAL_PU     26
#define  BAL_PD     27
#define  BAL_RL     28
#define  BAL_RR     29

#define TAKEOFF     33
#define LANDING     34

#define BAL_MAX_INC 39
#define BAL_MAX_DEC 40

#define F_MODE_RC      41
#define F_MODE_GPS     42
#define F_MODE_RC_THR  43                       //RC pitch/roll control maintaining height by automatic throttle control

#define MSG_CLEAR      44                       // use to clear the message buffer

#define RC_MODE_BAL    45
#define RC_MODE_FREE   46
#define F_MODE_RC_DST  47




#define dYAW_REF    0
#define dPITCH_REF  1
#define dROLL_REF   2

#define YAW_REF     3
#define PITCH_REF   4
#define ROLL_REF    5

#define ADJ_AMT     0.1

#define REP_VARS    62 // 12 fast + 50 slow


/*
 * These global variables control which object is drawn,
 * and how it is drawn.  No object uses all of these
 * variables.
 */
static int function_index;
static int slices = 16;
static int stacks = 16;
static double irad = .25;
static double orad = 1.0;
static int depth = 4;
static double offset[ 3 ] = { 0, 0, 0 };
static GLboolean show_info = GL_TRUE;


int StreamOn=0;

//int com_err=0;

int con_mode=NORMCON;  //0 is normal throttle con, 1 is pid tuning
int tune_chan=18;  //18=dYaw, 19=dPitch, 20=dRoll, 21=Yaw, 22=Pitch, 23=Roll
int TuneMode=0;


int fdr_on=0;

int but=0;
int rud=0;
int ail=0;
int ele=0;
int thr=0;

int rudd=0;
int elev=0;
int aile=0;

int QData[REP_VARS];

int fetchData=0;

//     int fast[12];
     int slow[50];
     int slow_in;
     int slow_index;




float Px[PID_NUM] = { 0.0,1.0,1.0,0.0,1.0,1.0 };
float Ix[PID_NUM] = { 0.0,0.0,0.0,0.0,0.0,0.0 };
float Dx[PID_NUM] = { 0.0,1.0,1.0,0.0,0.0,0.0 };
float PIDx[PID_NUM] = { 1.0,1.0,1.0,1.0,1.0,1.0 };
float I_Max[PID_NUM] = { 10.0,100.0,100.0,0.0,0.0,0.0 };

HANDLE hSerial;
unsigned char szBuff[32]; // don't go higher than 32!

int test_pos=0;
int test_neg=0;
int test_num=0;

char SerOK=0;

time_t tcnt, startcnt, endcnt;
time_t rawtime;
struct tm * timeinfo;
FILE *fp;
bool FDR_On=0;


/*
 * These one-liners draw particular objects, fetching appropriate
 * information from the above globals.  They are just thin wrappers
 * for the OpenGLUT objects.
 */
static void drawSolidTetrahedron(void)         { glutSolidTetrahedron ();                      }
static void drawWireTetrahedron(void)          { glutWireTetrahedron ();                       }
static void drawSolidCube(void)                { glutSolidCube(1);                             }
static void drawWireCube(void)                 { glutWireCube(1);                              }
static void drawSolidOctahedron(void)          { glutSolidOctahedron ();                       }
static void drawWireOctahedron(void)           { glutWireOctahedron ();                        }
static void drawSolidDodecahedron(void)        { glutSolidDodecahedron ();                     }
static void drawWireDodecahedron(void)         { glutWireDodecahedron ();                      }
static void drawSolidRhombicDodecahedron(void) { glutSolidRhombicDodecahedron ();              }
static void drawWireRhombicDodecahedron(void)  { glutWireRhombicDodecahedron ();               }
static void drawSolidIcosahedron(void)         { glutSolidIcosahedron ();                      }
static void drawWireIcosahedron(void)          { glutWireIcosahedron ();                       }
static void drawSolidSierpinskiSponge(void)    { glutSolidSierpinskiSponge (depth, offset, 1); }
static void drawWireSierpinskiSponge(void)     { glutWireSierpinskiSponge (depth, offset, 1);  }
static void drawSolidTeapot(void)              { glutSolidTeapot(1);                           }
static void drawWireTeapot(void)               { glutWireTeapot(1);                            }
static void drawSolidTorus(void)               { glutSolidTorus(irad,orad,slices,stacks);      }
static void drawWireTorus(void)                { glutWireTorus (irad,orad,slices,stacks);      }
static void drawSolidSphere(void)              { glutSolidSphere(1,slices,stacks);             }
static void drawWireSphere(void)               { glutWireSphere(1,slices,stacks);              }
static void drawSolidCone(void)                { glutSolidCone(1,1,slices,stacks);             }
static void drawWireCone(void)                 { glutWireCone(1,1,slices,stacks);              }
static void drawSolidCylinder(void)            { glutSolidCylinder(1,1,slices,stacks);         }
static void drawWireCylinder(void)             { glutWireCylinder(1,1,slices,stacks);          }

//static void drawAttitudeIndicator(void)             { glutAttitudeIndicator(1,1,slices,stacks);          }




void SendCommands(int buttons, int rudder, int aileron, int elevator, int throttle);
void FetchData(int buttons, int rudder, int aileron, int elevator, int throttle);

int sRead( int n );
int sWrite( int n );
void tx16( int val );
int rx16( void );
int rx32( void );
void StartFDR( void );
void WriteFDR( void );
void EndFDR(void );
void WaitFor (unsigned int secs);






#define RADIUS    0.3f

static void drawSolidCuboctahedron(void)
{
  glBegin( GL_TRIANGLES );
    glNormal3d( 0.577350269189, 0.577350269189, 0.577350269189); glVertex3d( RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS, RADIUS ); glVertex3d( RADIUS, 0.0, RADIUS );
    glNormal3d( 0.577350269189, 0.577350269189,-0.577350269189); glVertex3d( RADIUS, RADIUS, 0.0 ); glVertex3d( RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0, RADIUS,-RADIUS );
    glNormal3d( 0.577350269189,-0.577350269189, 0.577350269189); glVertex3d( RADIUS,-RADIUS, 0.0 ); glVertex3d( RADIUS, 0.0, RADIUS ); glVertex3d( 0.0,-RADIUS, RADIUS );
    glNormal3d( 0.577350269189,-0.577350269189,-0.577350269189); glVertex3d( RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS,-RADIUS ); glVertex3d( RADIUS, 0.0,-RADIUS );
    glNormal3d(-0.577350269189, 0.577350269189, 0.577350269189); glVertex3d(-RADIUS, RADIUS, 0.0 ); glVertex3d(-RADIUS, 0.0, RADIUS ); glVertex3d( 0.0, RADIUS, RADIUS );
    glNormal3d(-0.577350269189, 0.577350269189,-0.577350269189); glVertex3d(-RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS,-RADIUS ); glVertex3d(-RADIUS, 0.0,-RADIUS );
    glNormal3d(-0.577350269189,-0.577350269189, 0.577350269189); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS, RADIUS ); glVertex3d(-RADIUS, 0.0, RADIUS );
    glNormal3d(-0.577350269189,-0.577350269189,-0.577350269189); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d(-RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0,-RADIUS,-RADIUS );
  glEnd();

  glBegin( GL_QUADS );
    glNormal3d( 1.0, 0.0, 0.0 ); glVertex3d( RADIUS, RADIUS, 0.0 ); glVertex3d( RADIUS, 0.0, RADIUS ); glVertex3d( RADIUS,-RADIUS, 0.0 ); glVertex3d( RADIUS, 0.0,-RADIUS );
    glNormal3d(-1.0, 0.0, 0.0 ); glVertex3d(-RADIUS, RADIUS, 0.0 ); glVertex3d(-RADIUS, 0.0,-RADIUS ); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d(-RADIUS, 0.0, RADIUS );
    glNormal3d( 0.0, 1.0, 0.0 ); glVertex3d( RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS,-RADIUS ); glVertex3d(-RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS, RADIUS );
    glNormal3d( 0.0,-1.0, 0.0 ); glVertex3d( RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS, RADIUS ); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS,-RADIUS );
    glNormal3d( 0.0, 0.0, 1.0 ); glVertex3d( RADIUS, 0.0, RADIUS ); glVertex3d( 0.0, RADIUS, RADIUS ); glVertex3d(-RADIUS, 0.0, RADIUS ); glVertex3d( 0.0,-RADIUS, RADIUS );
    glNormal3d( 0.0, 0.0,-1.0 ); glVertex3d( RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0,-RADIUS,-RADIUS ); glVertex3d(-RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0, RADIUS,-RADIUS );
  glEnd();
}

#undef RADIUS
#define RADIUS    0.5f


static void drawWireCuboctahedron(void)
{
  glBegin( GL_LINE_LOOP );
    glNormal3d( 1.0, 0.0, 0.0 ); glVertex3d( RADIUS, RADIUS, 0.0 ); glVertex3d( RADIUS, 0.0, RADIUS ); glVertex3d( RADIUS,-RADIUS, 0.0 ); glVertex3d( RADIUS, 0.0,-RADIUS );
  glEnd();
  glBegin( GL_LINE_LOOP );
    glNormal3d(-1.0, 0.0, 0.0 ); glVertex3d(-RADIUS, RADIUS, 0.0 ); glVertex3d(-RADIUS, 0.0,-RADIUS ); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d(-RADIUS, 0.0, RADIUS );
  glEnd();
  glBegin( GL_LINE_LOOP );
    glNormal3d( 0.0, 1.0, 0.0 ); glVertex3d( RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS,-RADIUS ); glVertex3d(-RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS, RADIUS );
  glEnd();
  glBegin( GL_LINE_LOOP );
    glNormal3d( 0.0,-1.0, 0.0 ); glVertex3d( RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS, RADIUS ); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS,-RADIUS );
  glEnd();
  glBegin( GL_LINE_LOOP );
    glNormal3d( 0.0, 0.0, 1.0 ); glVertex3d( RADIUS, 0.0, RADIUS ); glVertex3d( 0.0, RADIUS, RADIUS ); glVertex3d(-RADIUS, 0.0, RADIUS ); glVertex3d( 0.0,-RADIUS, RADIUS );
  glEnd();
  glBegin( GL_LINE_LOOP );
    glNormal3d( 0.0, 0.0,-1.0 ); glVertex3d( RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0,-RADIUS,-RADIUS ); glVertex3d(-RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0, RADIUS,-RADIUS );
  glEnd();
}

#undef RADIUS

/*
 * This structure defines an entry in our function-table.
s */
typedef struct
{
    const char * const name;
    void (*solid) (void);
    void (*wire)  (void);
} entry;

#define ENTRY(e) {#e, drawSolid##e, drawWire##e}
static const entry table [] =
{
    ENTRY (Tetrahedron),
    ENTRY (Cube),
    ENTRY (Octahedron),
    ENTRY (Dodecahedron),
    ENTRY (RhombicDodecahedron),
    ENTRY (Icosahedron),
    ENTRY (SierpinskiSponge),
    ENTRY (Teapot),
    ENTRY (Torus),
    ENTRY (Sphere),
    ENTRY (Cone),
    ENTRY (Cylinder),
    ENTRY (Cuboctahedron)
};
#undef ENTRY

/*!
    Does printf()-like work using freeglut/OpenGLUT
    glutBitmapString().  Uses a fixed font.  Prints
    at the indicated row/column position.

    Limitation: Cannot address pixels.
    Limitation: Renders in screen coords, not model coords.
*/
static void shapesPrintf (int row, int col, const char *fmt, ...)
{
    static char buf[256];
    int viewport[4];
    void *font = GLUT_BITMAP_HELVETICA_10;
    va_list args;

    va_start(args, fmt);
#if defined(WIN32) && !defined(__CYGWIN__)
    (void) _vsnprintf (buf, sizeof(buf), fmt, args);
#else
    (void) vsnprintf (buf, sizeof(buf), fmt, args);
#endif
    va_end(args);

    glGetIntegerv(GL_VIEWPORT,viewport);

    glPushMatrix();
    glLoadIdentity();

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();

        glOrtho(0,viewport[2],0,viewport[3],-1,1);

        glRasterPos2i
        (
              glutBitmapWidth(font, ' ') * col,
            - glutBitmapHeight(font) * (row+2) + viewport[3]
        );
        glutBitmapString (font, (unsigned char*)buf);

    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
}

static void LshapesPrintf (int row, int col, const char *fmt, ...)
{
    static char buf[256];
    int viewport[4];
    void *font = GLUT_BITMAP_TIMES_ROMAN_24;
    va_list args;

    va_start(args, fmt);
#if defined(WIN32) && !defined(__CYGWIN__)
    (void) _vsnprintf (buf, sizeof(buf), fmt, args);
#else
    (void) vsnprintf (buf, sizeof(buf), fmt, args);
#endif
    va_end(args);

    glGetIntegerv(GL_VIEWPORT,viewport);

    glPushMatrix();
    glLoadIdentity();

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();

        glOrtho(0,viewport[2],0,viewport[3],-1,1);

        glRasterPos2i
        (
              glutBitmapWidth(font, ' ') * col,
            - glutBitmapHeight(font) * (row+2) + viewport[3]
        );
        glutBitmapString (font, (unsigned char*)buf);

    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
}




/* GLUT callback Handlers */

static void
resize(int width, int height)
{
    const float ar = (float) width / (float) height;

    glViewport(0, 0, width, height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glFrustum(-ar, ar, -1.0, 1.0, 2.0, 100.0);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity() ;
}

static void display(void)
{
    const double t = glutGet(GLUT_ELAPSED_TIME) / 1000.0;
    const double a = t*90.0;
    float FData[11];
    
    
    int i;

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnable(GL_LIGHTING);

    glColor3d(0,1,1-((float)thr/5000.0));

//for(i=0;i<100;i++)
//{
    glPushMatrix();
        glTranslated(0,-8,-20);
//        glRotated(60,1,0,0);

          // X,Y,Z corresponds to Pitch, Yaw, Roll axis respectively

        glRotated( ((float)(QData[5]+0)/45.0)*45.0, 0,-1,0);
        glRotated( ((float)QData[6]/45.0)*45.0, -1,0,0);
        glRotated( ((float)QData[7]/45.0)*45.0, 0,0,1);
        drawSolidCuboctahedron ();
        drawWireCuboctahedron ();
//        table [function_index].wire ();



  glBegin( GL_LINE_LOOP );
    glNormal3d( 0.0, 0.0, 1.0f ); 
      glVertex3d( -1.5,  0.0,  1.5 ); 
      glVertex3d(  1.5,  0.0,  1.5 ); 
      glVertex3d(  1.5,  0.0, -1.5 ); 
      glVertex3d( -1.5,  0.0, -1.5 );
      glVertex3d( -1.5,  0.0,  1.5 ); 
      glVertex3d(  0.0,  0.0,  0.0 );
      glVertex3d(  0.0,  0.0,  -5.0 );
      glVertex3d(  0.0,  0.0,  0.0 );
      glVertex3d(  1.5,  0.0,  1.5 ); 
  glEnd();
        

//  glBegin( GL_QUADS );
 //   glNormal3d( 0.0, 0.0, -1.0 ); glVertex3d( 1.0, 1.0, -100.0 ); glVertex3d( 1.0, 0.0, 1.0 ); glVertex3d( 1.0,-1.0, 0.0 ); glVertex3d( 1.0, 0.0,100.0 );
//    glNormal3d(-1.0, 0.0, 0.0 ); glVertex3d(-1.0f, 1.0f, 0.0 ); glVertex3d(-RADIUS, 0.0,-RADIUS ); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d(-RADIUS, 0.0, RADIUS );
//    glNormal3d( 0.0, 1.0, 0.0 ); glVertex3d( RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS,-RADIUS ); glVertex3d(-RADIUS, RADIUS, 0.0 ); glVertex3d( 0.0, RADIUS, RADIUS );
//    glNormal3d( 0.0,-1.0, 0.0 ); glVertex3d( RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS, RADIUS ); glVertex3d(-RADIUS,-RADIUS, 0.0 ); glVertex3d( 0.0,-RADIUS,-RADIUS );
//    glNormal3d( 0.0, 0.0, 1.0 ); glVertex3d( RADIUS, 0.0, RADIUS ); glVertex3d( 0.0, RADIUS, RADIUS ); glVertex3d(-RADIUS, 0.0, RADIUS ); glVertex3d( 0.0,-RADIUS, RADIUS );
 //   glNormal3d( 0.0, 0.0,-1.0 ); glVertex3d( RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0,-RADIUS,-RADIUS ); glVertex3d(-RADIUS, 0.0,-RADIUS ); glVertex3d( 0.0, RADIUS,-RADIUS );
//  glEnd();





        
        
    glPopMatrix();
//}
/*
    glPushMatrix();
        glTranslated(0,-1.2,-6);
        glRotated(60,1,0,0);
        glRotated(a,1,0,1);
        table [function_index].wire ();
    glPopMatrix();
*/
    glDisable(GL_LIGHTING);
    glColor3d(0.1,0.1,0.4);

    if(fetchData == 1)
    {
//         test_num = test_pos = 0;
         startcnt = clock();
//         for( test_num = 0; test_num < 1; test_num++ )
//         {
         FetchData(but,rud,ail,ele,thr);
//           if( QData[0] == 62 )  test_pos++;
 //        }
         endcnt = clock();
         tcnt = endcnt - startcnt;
         
         test_num++;
         if( ((((float)tcnt)/CLOCKS_PER_SEC) < 0.7 ) && (SerOK == 0) ) test_pos++;   //positive test if time taken is correct
         else test_neg++;
         shapesPrintf( 35, 0, "Last Data Fetch Time = %.3f Seconds", ((float)tcnt)/CLOCKS_PER_SEC);
         
         fetchData = 0;
    }



     // Convert floating point format ints to floats:

      FData[0] = *(float *)&QData[0];
      
      for(i=0;i<10;i++) FData[i+1] = *(float *)&QData[i+15];


   
      
      
      if( SerOK != 0 ) LshapesPrintf( 0, 80, "COM PORT FAILURE");



//     float ff = *(float *)&QData[10];
      
      

      shapesPrintf( 0, 1, "Fast Priority:");
      
      shapesPrintf( 2, 4, "UM6 Status: %d",  FData[0]);//QData[0]);

      shapesPrintf( 4, 4, "Rudder: %d",   QData[1]);
      shapesPrintf( 5, 4, "Aileron: %d",  QData[2]);
      shapesPrintf( 6, 4, "Elevator: %d", QData[3]);
      shapesPrintf( 7, 4, "Throttle: %d", QData[4]);

      shapesPrintf( 9, 4, "yaw: %d",        QData[5]);
      shapesPrintf( 10, 4, "pitch: %d",     QData[6]);
      shapesPrintf( 11, 4, "roll: %d",      QData[7]);
      shapesPrintf( 12, 4, "yawRate: %d",   QData[8]);
      shapesPrintf( 13, 4, "pitchRate: %d", QData[9]);
      shapesPrintf( 14, 4, "rollRate: %d",  QData[10]);
           
      shapesPrintf( 16, 4, "Ammeter: %d",   QData[11]);


      
      shapesPrintf( 0, 50, "Slow Priority:");

      shapesPrintf( 2, 50, "Throttle PID Rate: %d Hz", QData[34]);

      shapesPrintf( 2, 100, "Ring Buffer Update (1 chip): %.0f Hz", 1.0/((float)QData[46]/100000000.0));

      shapesPrintf( 4, 50, "Balance_Yaw: %d",   QData[25]);
      shapesPrintf( 5, 50, "Balance_Pitch: %d", QData[26]);
      shapesPrintf( 6, 50, "Balance_Roll: %d",  QData[27]);

      shapesPrintf( 8, 50, "mag_x: %d", QData[12]);
      shapesPrintf( 9, 50, "mag_y: %d", QData[13]);
      shapesPrintf( 10, 50, "mag_z: %d", QData[14]);

      shapesPrintf( 12, 50, "dPitch P: %d", QData[28]);
      shapesPrintf( 13, 50, "dPitch I: %d", QData[29]);
      shapesPrintf( 14, 50, "dPitch D: %d", QData[30]);
      shapesPrintf( 15, 50, "Pitch P: %d",  QData[31]);
      shapesPrintf( 16, 50, "Pitch I: %d",  QData[32]);
      shapesPrintf( 17, 50, "Pitch D: %d",  QData[33]);

      shapesPrintf( 19, 50, "Temperature: %.2f", FData[1]);//QData[15]);
      shapesPrintf( 20, 50, "Air Pressure: %d", QData[45]);

//      shapesPrintf( 22, 50, "BAL_MAX: %d",       QData[35]);
      shapesPrintf( 23, 50, "F_Mode: %d",        QData[36]);
      shapesPrintf( 24, 50, "GS Message: %d", QData[42]);

      shapesPrintf( 26, 50, "LIDAR: %d cm", QData[43] );
      shapesPrintf( 27, 50, "Concensus Dist: %d cm", QData[44] );


      
//      shapesPrintf( 26, 50, "Distance Rate: %.2f Hz", (1/((float)QData[43]/100000)));
//      if( QData[44] < 16) shapesPrintf( 27, 50, "Distance: 0 cm" );
//      else shapesPrintf( 27, 50, "Distance: %d cm", QData[44] );

      shapesPrintf( 29, 50, "Pitch/Roll Alarms: %d", QData[35]);








      shapesPrintf( 4, 100, "GPS PID Rate: %d Hz", QData[37]);
      shapesPrintf( 5, 100, "GPS Rudder: %d",        QData[38]);
      shapesPrintf( 6, 100, "GPS Aileron: %d",       QData[39]);
      shapesPrintf( 7, 100, "GPS Elevator: %d",      QData[40]);
      shapesPrintf( 8, 100, "GPS Throttle: %d",      QData[41]);

      shapesPrintf( 9, 100, "GPS Longitude: %f", FData[2]);//QData[16]);
      shapesPrintf( 10, 100, "GPS_Latitude: %f", FData[3]);// QData[17]);
      shapesPrintf( 11, 100, "GPS_Altitude: %f", FData[4]);// QData[18]);

      shapesPrintf( 13, 100, "NEH_North: %f",  FData[5]);//QData[19]);
      shapesPrintf( 14, 100, "NEH_Eeast: %f",  FData[6]);//QData[20]);
      shapesPrintf( 15, 100, "NEH_Height: %f", FData[7]);//QData[21]);

      shapesPrintf( 17, 100, "Speed: %f",  FData[8]);//QData[22]);
      shapesPrintf( 18, 100, "Course: %f", FData[9]);//QData[23]);

      shapesPrintf( 20, 100, "SatSum:");
      shapesPrintf( 20, 115, BYTETOBINARYPATTERN, BYTETOBINARY(QData[24]>>24));
      shapesPrintf( 20, 132, BYTETOBINARYPATTERN, BYTETOBINARY(QData[24]>>16));
      shapesPrintf( 20, 149, BYTETOBINARYPATTERN, BYTETOBINARY(QData[24]>>8));
      shapesPrintf( 20, 166, BYTETOBINARYPATTERN, BYTETOBINARY(QData[24]));
      
      shapesPrintf( 22, 100, "Batt 1 Cell 1: %d V", QData[47]);
      shapesPrintf( 23, 100, "Batt 1 Cell 2: %d V", QData[48]);
      shapesPrintf( 24, 100, "Batt 1 Cell 3: %d V", QData[49]);
      shapesPrintf( 25, 100, "Batt 2 Cell 1: %d V", QData[50]);
      shapesPrintf( 26, 100, "Batt 2 Cell 2: %d V", QData[51]);
      shapesPrintf( 27, 100, "Batt 2 Cell 3: %d V", QData[52]);

      shapesPrintf( 29, 100, "Trim Pot ADC: %d", QData[53]);
      shapesPrintf( 30, 100, "ADC 7: %d",  QData[54]);
      shapesPrintf( 31, 100, "ADC 9: %d",  QData[55]);
      shapesPrintf( 32, 100, "ADC 10: %d", QData[56]);
      shapesPrintf( 33, 100, "ADC 11: %d", QData[57]);
      shapesPrintf( 34, 100, "ADC 12: %d", QData[58]);
      shapesPrintf( 35, 100, "ADC 13: %d", QData[59]);
      shapesPrintf( 36, 100, "ADC 14: %d", QData[60]);
      shapesPrintf( 37, 100, "ADC 15: %d", QData[61]);

      shapesPrintf( 32, 0, "Data Fetches Sent       = %d", test_num);
      shapesPrintf( 33, 0, "Data Fetches Received   = %d", test_pos);
      
      shapesPrintf( 34, 0, "Data Fetches Failed     = %d", (test_neg));
      shapesPrintf( 35, 0, "Last Data Fetch Time = %.3f Seconds", ((float)tcnt)/CLOCKS_PER_SEC);



// print command keys

      shapesPrintf( 5, 180, "Command Keys:");

      shapesPrintf( 7, 200, "w,s / a,d :  Adjust Balance Point Pitch / Roll");
      shapesPrintf( 8, 200, "` : Motors Off (under ESCape key)");
      shapesPrintf( 9, 200, "1 : Motors On");

      shapesPrintf( 11, 200, "h : Flight Mode = RC Control");
      shapesPrintf( 12, 200, "j : Flight Mode = RC Control + Pressure Controlled Altitude");
      shapesPrintf( 13, 200, "f : Flight Mode = RC Control + Distance Sensor Altitude");
      shapesPrintf( 14, 200, "g : Flight Mode = GPS Controlled Position + Pressure Controlled Altitude");

      shapesPrintf( 16, 200, "k : RC Mode = Snap to Balance Point");
      shapesPrintf( 17, 200, "l : RC Mode = Free Floating");
      
      shapesPrintf( 19, 200, "b : Set Balance Point to current angles");

      shapesPrintf( 21, 200, "ESC : Close Program");
      



///////////
/*

      shapesPrintf( 2, 4, "mag_x: %d", QData[0]);
      shapesPrintf( 3, 4, "mag_y: %d", QData[1]);
      shapesPrintf( 4, 4, "mag_z: %d", QData[2]);
//      shapesPrintf( 5, 4, "accel_x: %d", QData[3]);
//      shapesPrintf( 6, 4, "accel_y: %d", QData[4]);
//      shapesPrintf( 7, 4, "accel_z: %d", QData[5]);
//      shapesPrintf( 8, 4, "mag_x: %d", QData[7]);
//      shapesPrintf( 9, 4, "mag_y: %d", QData[8]);
//      shapesPrintf( 10, 4, "mag_z: %d", QData[9]);
      shapesPrintf( 11, 4, "UM6_Status: %f", FData[6]);
      shapesPrintf( 12, 4, "UM6_Temp  : %f", FData[1]);//QData[10]);
      shapesPrintf( 13, 4, "GPS_Longitude: %f", FData[2]);
      shapesPrintf( 14, 4, "GPS_Latitude : %f", FData[3]);
      shapesPrintf( 15, 4, "GPS_Altitude : %f", FData[4]);
      shapesPrintf( 16, 4, "N,E,H: %.3f, %.3f, %.3f", FData[5], FData[6], FData[7]);
      shapesPrintf( 17, 4, "GPS_Speed : %.2f", ((float)QData[17])/100.0);
      shapesPrintf( 18, 4, "GPS_Course: %.2f", ((float)QData[18])/100.0);
      shapesPrintf( 19, 4, "Satelite Summary: %f", FData[10]);
      shapesPrintf( 20, 4, "B1Cell1 : %.1f V", ((float)QData[20])/10.0);
      shapesPrintf( 21, 4, "B1Cell2 : %.1f V", ((float)QData[21])/10.0);
      shapesPrintf( 22, 4, "B1Cell3 : %.1f V", ((float)QData[22])/10.0);
      shapesPrintf( 23, 4, "B2Cell1 : %.1f V", ((float)QData[23])/10.0);
      shapesPrintf( 24, 4, "B2Cell2 : %.1f V", ((float)QData[24])/10.0);
      shapesPrintf( 25, 4, "B2Cell3 : %.1f V", ((float)QData[25])/10.0);
      shapesPrintf( 26, 4, "Air Pressure: %d", QData[26]);
      if(QData[59] == 1421) shapesPrintf( 27, 4, "Current Below Range");
      else shapesPrintf( 27, 4, "Current: %.3f A", ((float)QData[59])/1000.0);
      shapesPrintf( 28, 4, "GPS PID Rate: %d", QData[27]);

      shapesPrintf( 30, 4, "GPS Rudder  : %d", QData[28]);
      shapesPrintf( 31, 4, "GPS Aileron : %d", QData[29]);
      shapesPrintf( 32, 4, "GPS Elevator: %d", QData[30]);
      shapesPrintf( 33, 4, "GPS Throttle: %d", QData[31]);

      shapesPrintf( 30, 50, "P0 Rudder  : %d", QData[32]);
      shapesPrintf( 31, 50, "P0 Aileron : %d", QData[33]);
      shapesPrintf( 32, 50, "P0 Elevator: %d", QData[34]);
      shapesPrintf( 33, 50, "P0 Throttle: %d", QData[35]);

      shapesPrintf( 32, 90, "Buttons: %d", QData[36]);

      shapesPrintf( 0, 50, "P0 Data:");
      
      shapesPrintf( 2, 54, "BalancePiontYaw   : %d", QData[37]);
      shapesPrintf( 3, 54, "BalancePiontPitch : %d", QData[38]);
      shapesPrintf( 4, 54, "BalancePointRoll  : %d", QData[39]);
      shapesPrintf( 5, 54, "Rate P : %.3f", (float)QData[40]/1000);
      shapesPrintf( 6, 54, "Rate I : %.3f", (float)QData[41]/1000);
      shapesPrintf( 7, 54, "Rate D : %.3f", (float)QData[42]/1000);
      shapesPrintf( 8, 54, "Absolute Angle P : %.3f", (float)QData[43]/1000);
      shapesPrintf( 9, 54, "Absolute Angle I : %.3f", (float)QData[44]/1000);
      shapesPrintf( 10, 54, "Absolute Angle D : %.3f", (float)QData[45]/1000);
      shapesPrintf( 11, 54, "yaw   : %d", QData[46]);
      shapesPrintf( 12, 54, "pitch : %d", QData[47]);
      shapesPrintf( 13, 54, "roll  : %d", QData[48]);
      shapesPrintf( 14, 54, "yawRate   : %d", QData[49]);
      shapesPrintf( 15, 54, "pitchRate : %d", QData[50]);
      shapesPrintf( 16, 54, "rollRate  : %d", QData[51]);

      shapesPrintf( 17, 54, "M1Bal: %d", QData[52]);
      shapesPrintf( 18, 54, "M1Bal: %d", QData[53]);
      shapesPrintf( 19, 54, "M1Bal: %d", QData[54]);
      shapesPrintf( 20, 54, "M1Bal: %d", QData[55]);

      shapesPrintf( 21, 54, "PID RATE (Hz): %d", QData[56]);
      shapesPrintf( 22, 54, "BAL_MAX: %d", QData[57]);
      shapesPrintf( 23, 54, "F_Mode: %d", QData[58]);
      
      shapesPrintf( 24, 70, "Data Fetches Sent       = %d", test_num);
      shapesPrintf( 25, 70, "Data Fetches Received   = %d", test_pos);
      
      shapesPrintf( 26, 70, "Data Fetches Failed     = %d", (test_neg));
      shapesPrintf( 27, 70, "Last Data Fetch Time = %.3f Seconds", ((float)tcnt)/CLOCKS_PER_SEC);
      shapesPrintf( 28, 54, "Sonar = %d cm", QData[60]);
      
*/
    if( con_mode == PIDTUNE )
    {
      shapesPrintf( 24, 135, "PID TUNING ACTIVE" );

      shapesPrintf( 25, 140, "1 = Increase Rate P" );
      shapesPrintf( 26, 140, "2 = Increase Rate I" );
      shapesPrintf( 27, 140, "3 = Increase Rate D" );
      shapesPrintf( 28, 140, "4 = Increase Absolute Angle P" );
      shapesPrintf( 29, 140, "5 = Increase Absolute Angle I" );
      shapesPrintf( 30, 140, "6 = Increase Absolute Angle D" );
      shapesPrintf( 31, 140, "7 = Increase Throttle Balance Limit" );
      shapesPrintf( 32, 140, "+SHIFT = Decrease" );
      
    }

//    WriteFDR();
    if(StreamOn)
    {
         fetchData = 1;
         if(!fdr_on) StartFDR();
         WriteFDR();
    }                 





    
    glutSwapBuffers();




}


static void
key(unsigned char key, int x, int y)
{
              
             
    switch (key)
    {


    // Esc = Exit
    case 27: glutLeaveMainLoop () ;      break;


    case 'R': 
    case 'r':
         switch(StreamOn)
         {
                         case 1:
                              StreamOn=0;
                              break;
                         case 0:
                              StreamOn=1;
                              break;
         }
                               
         
    //     fetchData = 1;
     //    if(!fdr_on) StartFDR();
      //   WriteFDR();
         break;


    case '~': 
    case '`': 
         but = M_OFF;
         SendCommands(but,rud,ail,ele,thr);
//         SendCommands(but,rud,ail,ele,thr);
//         SendCommands(but,rud,ail,ele,thr);
//         SendCommands(but,rud,ail,ele,thr);
//         SendCommands(but,rud,ail,ele,thr);
//         SendCommands(but,rud,ail,ele,thr);
         break;
         
    case 'C': 
    case 'c': 
         but = FDR_ON;
         SendCommands(but,rud,ail,ele,thr);                    
         break;

    case 'V': 
    case 'v': 
         but = FDR_OFF;
         SendCommands(but,rud,ail,ele,thr);                    
         break;

    case 'B': 
    case 'b': 
         but = BALANCE;
         SendCommands(but,rud,ail,ele,thr);                    
         // INSERT: Wait a sufficient time - here and on down
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         break;

    case 'N': 
    case 'n': 
         but = BAL_RST;
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         aile=0;
         elev=0;
         rudd=0;
         break;


    case 'J': 
    case 'j': 
         but = F_MODE_RC_THR;//LANDING;
         SendCommands(but,rud,ail,ele,thr);                    
/*         SendCommands(but,rud,ail,ele,thr);                    
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    */
         break;

//    case 'K': 
 //   case 'k': 
  //       but = CON_KEY;
   //      SendCommands(but,rud,ail,ele,thr);                    
    //     break;




/*    case 'F': 
    case 'f': 
         but = TAKEOFF;
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         break;
*/
    case 'G': 
    case 'g': 
         but = F_MODE_GPS;//LANDING;
         SendCommands(but,rud,ail,ele,thr);                    
/*         SendCommands(but,rud,ail,ele,thr);    //takes a little time to propogate
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    */
         break;


    case 'H': 
    case 'h': 
         but = F_MODE_RC;
         SendCommands(but,rud,ail,ele,thr);                    
/*         SendCommands(but,rud,ail,ele,thr);                    
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    */
         break;

    case 'F': 
    case 'f': 
         but = F_MODE_RC_DST;
         SendCommands(but,rud,ail,ele,thr);                    
         break;


    case 'K': 
    case 'k': 
         but = RC_MODE_BAL;
         SendCommands(but,rud,ail,ele,thr);                    
         break;

    case 'L': 
    case 'l': 
         but = RC_MODE_FREE;
         SendCommands(but,rud,ail,ele,thr);                    
         break;



    case 'W': 
    case 'w': 
         but = BAL_PD;
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         elev -= 100;
         break;

    case 'S': 
    case 's': 
         but = BAL_PU;
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         elev += 100;
         break;

    case 'A': 
    case 'a': 
         but = BAL_RL;
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         aile -= 100;
         break;

    case 'D': 
    case 'd': 
         but = BAL_RR;
         SendCommands(but,rud,ail,ele,thr);  
         WaitFor(1);
         but = MSG_CLEAR;
         SendCommands(but,rud,ail,ele,thr);                    
         aile += 100;
         break;

    case 'Q': 
    case 'q': 
         but = BAL_YL;
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         rudd -= 100;
         break;

    case 'E': 
    case 'e': 
         but = BAL_YR;
         SendCommands(but,rud,ail,ele,thr);                    
         but = 0;
         SendCommands(but,rud,ail,ele,thr);                    
         rudd += 100;
         break;

/*    case 9:
         rud *= 2;
         ail *= 2;
         ele *= 2;
         thr *= 2;
         SendCommands(but,rud,ail,ele,thr);                    
         break;
*/
    case 'Z': 
    case 'z': 
         rud=ail=ele=thr=0;
         SendCommands(but,rud,ail,ele,thr);                    
         break;


    default:
         but=rud=ail=ele=thr=0;
         break;
    }
    

    if( con_mode == NORMCON )
        switch( key )
        {

        case '-':
        case '_': 
             but = TH_LOW;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '=': 
        case '+': 
             but = TH_HIGH;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
                
        case '>':
        case '.': 
             con_mode = PIDTUNE;
             break;
    
        case '1': 
        case '!': 
             but = M_ON;
             thr = 0;
             SendCommands(but,rud,ail,ele,thr);                    
/*             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);                    
             SendCommands(but,rud,ail,ele,thr);       */             
             break;
/*    
        case '2': 
        case '@': 
             but = M_ON;
             thr = 500;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '3': 
        case '#': 
             but = M_ON;
             thr = 1500;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '4': 
        case '$': 
             but = M_ON;
             thr = 2000;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '5': 
        case '%': 
             but = M_ON;
             thr = 2500;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '6': 
        case '^': 
             but = M_ON;
             thr = 3000;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '7': 
        case '&': 
             but = M_ON;
             thr = 3500;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '8': 
        case '*': 
             but = M_ON;
             thr = 4000;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '9': 
        case '(': 
             but = M_ON;
             thr = 4500;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '0': 
        case ')': 
             but = M_ON;
             thr = 5000;
             SendCommands(but,rud,ail,ele,thr);                    
             break;*/
        }

    if( con_mode == PIDTUNE )
        switch( key )
        {
/*
        case '-':
        case '_': 
             
             switch( TuneMode )
             {
                     case 0: //P
                          Px[tune_chan-18] -= ADJ_AMT;
                          break;
             
                     case 1: 
                          Ix[tune_chan-18] -= ADJ_AMT;
                          break;
             
                     case 2:
                          Dx[tune_chan-18] -= ADJ_AMT;
                          break;
             
                     case 3: 
                          PIDx[tune_chan-18] -= ADJ_AMT;
                          break;
             
                     case 4:
                          I_Max[tune_chan-18] -= ADJ_AMT;
                          break;
             }
             
             
             but = SEL_DEC;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
    
        case '=': 
        case '+': 

             switch( TuneMode )
             {
                     case 0: //P
                          Px[tune_chan-18] += ADJ_AMT;
                          break;
             
                     case 1: 
                          Ix[tune_chan-18] += ADJ_AMT;
                          break;
             
                     case 2: 
                          Dx[tune_chan-18] += ADJ_AMT;
                          break;
             
                     case 3: 
                          PIDx[tune_chan-18] += ADJ_AMT;
                          break;
             
                     case 4:
                          I_Max[tune_chan-18] += ADJ_AMT;
                          break;
             }

             but = SEL_INC;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
  */              
        case '<':
        case ',': 
             con_mode = NORMCON;
             break;
    
        case '1': 
             but = SEL_P;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=0;
             break;
    
        case '2': 
             but = SEL_I;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=1;
             break;
    
        case '3': 
             but = SEL_D;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=2;
             break;
    
        case '4': 
             but = SEL_aP;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=3;
             break;
    
        case '5': 
             but = SEL_aI;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=4;
             break;
    
        case '6': 
             but = SEL_aD;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=4;
             break;

        case '7': 
             but = BAL_MAX_INC;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             break;

        case '!': 
             but = SEL_PD;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=0;
             break;
    
        case '@': 
             but = SEL_ID;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=1;
             break;
    
        case '#': 
             but = SEL_DD;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=2;
             break;
    
        case '$': 
             but = SEL_aPD;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=3;
             break;
    
        case '%': 
             but = SEL_aID;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=4;
             break;
    
        case '^': 
             but = SEL_aDD;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             TuneMode=4;
             break;

        case '&': 
             but = BAL_MAX_DEC;
             SendCommands(but,rud,ail,ele,thr);                    
             but = 0;
             SendCommands(but,rud,ail,ele,thr);                    
             break;


/*             if( tune_chan++ >= 23 ) tune_chan = 18;             
             but = tune_chan;
             SendCommands(but,rud,ail,ele,thr);                    
             break;
  */      }

    
     // apply constraints
   if( rud > 5000 ) rud = 5000;
   if( rud < -5000 ) rud = -5000;
    
   if( ail > 5000 ) ail = 5000;
   if( ail < -5000 ) ail = -5000;

   if( ele > 5000 ) ele = 5000;
   if( ele < -5000 ) ele = -5000;

   if( thr > 5000 ) thr = 5000;
    
    

    glutPostRedisplay();
}

static void special (int key, int x, int y)
{
    switch (key)
    {
    case GLUT_KEY_PAGE_UP:    ++function_index; break;
    case GLUT_KEY_PAGE_DOWN:  --function_index; break;
    case GLUT_KEY_UP:         orad *= 2;        break;
    case GLUT_KEY_DOWN:       orad /= 2;        break;

    case GLUT_KEY_RIGHT:      irad *= 2;        break;
    case GLUT_KEY_LEFT:       irad /= 2;        break;

    default:
        break;
    }

    if (0 > function_index)
        function_index = NUMBEROF (table) - 1;

    if (NUMBEROF (table) <= ( unsigned )function_index)
        function_index = 0;        
}


static void
idle(void)
{
    glutPostRedisplay();
}

const GLfloat light_ambient[]  = { 0.0f, 0.0f, 0.0f, 1.0f };
const GLfloat light_diffuse[]  = { 1.0f, 1.0f, 1.0f, 1.0f };
const GLfloat light_specular[] = { 1.0f, 1.0f, 1.0f, 1.0f };
const GLfloat light_position[] = { 2.0f, 5.0f, 5.0f, 0.0f };

const GLfloat mat_ambient[]    = { 0.7f, 0.7f, 0.7f, 1.0f };
const GLfloat mat_diffuse[]    = { 0.8f, 0.8f, 0.8f, 1.0f };
const GLfloat mat_specular[]   = { 1.0f, 1.0f, 1.0f, 1.0f };
const GLfloat high_shininess[] = { 100.0f };

/* Program entry point */

int
main(int argc, char *argv[])
{
    glutInitWindowSize(1024,600);
    glutInitWindowPosition(10,10);
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH | GLUT_MULTISAMPLE);

    glutCreateWindow("UAV Ground Station");

    glutReshapeFunc(resize);
    glutDisplayFunc(display);
    glutKeyboardFunc(key);
    glutSpecialFunc(special);
    glutIdleFunc(idle);

    glutSetOption ( GLUT_ACTION_ON_WINDOW_CLOSE, GLUT_ACTION_CONTINUE_EXECUTION ) ;

    glClearColor(1,1,1,1);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    glEnable(GL_LIGHT0);
    glEnable(GL_NORMALIZE);
    glEnable(GL_COLOR_MATERIAL);

    glLightfv(GL_LIGHT0, GL_AMBIENT,  light_ambient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE,  light_diffuse);
    glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
    glLightfv(GL_LIGHT0, GL_POSITION, light_position);

    glMaterialfv(GL_FRONT, GL_AMBIENT,   mat_ambient);
    glMaterialfv(GL_FRONT, GL_DIFFUSE,   mat_diffuse);
    glMaterialfv(GL_FRONT, GL_SPECULAR,  mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, high_shininess);


//inits
//    if(OpenComport(COM2, 9600))
  //    com_err = 1;
    
    
    ++function_index;
    ++function_index;
    ++function_index;







SerOK=0;



hSerial = CreateFile(COMPORT,
GENERIC_READ | GENERIC_WRITE,
0,
0,
OPEN_EXISTING,
FILE_ATTRIBUTE_NORMAL,
0);
if(hSerial==INVALID_HANDLE_VALUE){
if(GetLastError()==ERROR_FILE_NOT_FOUND){
//serial port does not exist. Inform user.
  SerOK=1;
}
//some other error occurred. Inform user.
  SerOK=2;
}    
    
    
    
    
DCB dcbSerialParams = {0};
dcbSerialParams.DCBlength=sizeof(dcbSerialParams);
if (!GetCommState(hSerial, &dcbSerialParams)) {
//error getting state
  SerOK=3;
}
dcbSerialParams.BaudRate=CBR_38400;
dcbSerialParams.ByteSize=8;
dcbSerialParams.StopBits=ONESTOPBIT;
dcbSerialParams.Parity=NOPARITY;
if(!SetCommState(hSerial, &dcbSerialParams)){
//error setting serial port state
  SerOK=4;
}    





COMMTIMEOUTS timeouts={0};
timeouts.ReadIntervalTimeout=50;
timeouts.ReadTotalTimeoutConstant=150;
timeouts.ReadTotalTimeoutMultiplier=10;
timeouts.WriteTotalTimeoutConstant=50;
timeouts.WriteTotalTimeoutMultiplier=10;
if(!SetCommTimeouts(hSerial, &timeouts)){
//error occureed. Inform user
  SerOK=5;
}











//    StartFDR();

    glutMainLoop();

    EndFDR();
    
    CloseHandle(hSerial);    

    
// de-inits    
//    CloseComport(COM2);
    

#ifdef _MSC_VER
    /* DUMP MEMORY LEAK INFORMATION */
    _CrtDumpMemoryLeaks () ;
#endif

    return EXIT_SUCCESS;
}



void SendCommands(int buttons, int rudder, int aileron, int elevator, int throttle)
{
     
   tx16(420);
   tx16(buttons);
   tx16(buttons|COMCODE);
   
}

void FetchData(int buttons, int rudder, int aileron, int elevator, int throttle)
{
     
     
     int i=0, d=0;
     
   tx16(419);
   tx16(buttons);
   tx16(buttons|COMCODE);

   for(i=0;i<12;i++) QData[i] = rx32();
   slow_in = rx32();
   slow_index = rx16();
   
//   for(i=0;i<12;i++) QData[i] = fast[i];
  
   slow[slow_index] = slow_in;
   
   
   
   for(i=0;i<50;i++) QData[i+12] = slow[i];
  
   /*
   d=0;
   for(i=0;i<6;i++) QData[d++] = rx16();
   
   QData[d++] = rx32();
   
   for(i=0;i<3;i++) QData[d++] = rx16();
   
   for(i=0;i<10;i++) QData[d++] = rx32();
   
   for(i=0;i<40;i++) QData[d++] = rx16();   */
}


int sRead( int n ) //read n bytes
{
  for( int i=0; i<32; i++ ) szBuff[i] = 0;
  DWORD dwBytesRead = 0;
  if(!ReadFile(hSerial, szBuff, n, &dwBytesRead, NULL)){
    //error occurred. Report to user.
    char lastError[1024];
    FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL,
      GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      lastError,
      1024,
      NULL);
  }
  
  return dwBytesRead;

}


int sWrite( int n ) //read n bytes
{
  DWORD dwBytesWrote = 0;
  if(!WriteFile(hSerial, szBuff, n, &dwBytesWrote, NULL)){
    //error occurred. Report to user.
    char lastError[1024];
    FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL,
      GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      lastError,
      1024,
      NULL);
  }
  
  return dwBytesWrote;

}

void tx16( int val )
{
     char msb=0;
     char lsb=0;
     
     msb = val >> 8;
     
     szBuff[0] = msb;
//     sWrite(1);
     
     lsb = val - ( msb << 8 );
     
     szBuff[1] = lsb;
     sWrite(2);
}

int rx16( void )
{
    unsigned int val=0;
    sRead(2);
    
    val = szBuff[0];
    val <<= 8;
    val |= szBuff[1];
    
    if( val > 32767 ) val = -32768 + (val-32768);
    
    
    return val;
}

int rx32( void )
{
    unsigned int val=0;
    sRead(4);
    
    val = szBuff[3];
    val <<= 8;
    val |= szBuff[2];
    val <<= 8;
    val |= szBuff[1];
    val <<= 8;
    val |= szBuff[0];
    
//    if( val > 2147483647 ) val = -2147483648 + (val-2147483648);
    
    
    return val;
}


void StartFDR( void )
{
  char timestamp[32];
  char *ts;
  int i;
  
  if ( !FDR_On )
  {
      time (&rawtime);
      timeinfo = localtime (&rawtime);
      ts = asctime (timeinfo);
      
                  // make timestamp filename friendly
      for(i=0;i<24;i++) timestamp[i] = ts[i];
      timestamp[13] = '.';
      timestamp[16] = '.';
      
      for(i=0;i<20;i++) timestamp[i] = timestamp[i+4];
      for(i=0;i<20;i++) timestamp[i+3] = timestamp[i+4];
      
      timestamp[19] = '.';
      timestamp[20] = 't';
      timestamp[21] = 'x';
      timestamp[22] = 't';
      timestamp[23] = 0;
      
      fp=fopen(timestamp, "w");       // open file for writing, filename is the date and time
      
      FDR_On = 1;
  }
  
}

void WriteFDR( void )
{
  int i=0;
     
  char *timestamp;

  if( FDR_On )
  {
      time (&rawtime);
      timeinfo = localtime (&rawtime);
      timestamp = asctime (timeinfo);
      timestamp[24]=0;
      
      fprintf(fp, "%s", timestamp);
     
      for(i=0;i<REP_VARS;i++)
      {
         if( (i==6) || ( (i>9) && (i<20) ) ) fprintf(fp, ", %f", *(float *)&QData[i]);
         else fprintf(fp, ", %d", QData[i]);
      }
      
      fprintf(fp, ", %d, %d, %d, %.3f\n",  test_num, test_pos, test_neg, ((float)tcnt)/CLOCKS_PER_SEC);
      
//      fprintf(fp, "%s, %d, %d, %d, %d, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.1f, %.1f, %.1f, %d, %d, %d, %d, %d, %d, %d, %d, %d, %.3f\n", timestamp, SerOK, QData[0], QData[1], QData[2], (float)QData[3]/1000, (float)QData[4]/1000, (float)QData[5]/1000, (float)QData[6]/1000, (float)QData[7]/1000, (float)QData[8]/1000, (float)QData[9]/10, (float)QData[10]/10, (float)QData[11]/10, QData[12], QData[13], QData[14], QData[15], QData[16], QData[17], test_num, test_pos, test_neg, ((float)tcnt)/CLOCKS_PER_SEC);
  }  
  
}

void EndFDR( void )
{
  if( FDR_On )
  {     
     fclose(fp);
     FDR_On = 0;
  }
     
}


void WaitFor (unsigned int secs) {
  unsigned int retTime;
    retTime = time(0) + secs;     // Get finishing time.
    while (time(0) < retTime);    // Loop until it arrives.
}
