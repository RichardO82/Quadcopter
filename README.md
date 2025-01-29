# Quadcopter
Quadcopter project built from scratch: hardware, flight control PCB and firmware, ground control software, from 2015.

This project uses four Parallax Propeller microcontrollers and one MSP430.  The Propeller firmware is written in Parallax's "spin" language.  The MSP430 and ground station use C/C++.  Communication is through Xbee radios for the ground station and standard RC receiver and transmitter for RC flying.  The ESCs were flashed with SimonK firmware to enable a 500 Hz update rate.

I made this project early in my electronics journey, so take my labelling, commenting, and quirky engineering with a grain of salt.  The PID algorithms are really just PI, but the important thing is it works.  I'm considering remaking this project with modern tech and doing a video series on how to build a quadcopter.


Watch a video of the quadcopter flying under remote control:
[![Watch the video](https://github.com/RichardO82/Quadcopter/blob/main/QP-Small-300x183.jpg)](https://youtu.be/GqNNZwK2zFc)


PCB prototyping pictures:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/4%20chip%20pcb.jpg)

![alt text](https://github.com/RichardO82/Quadcopter/blob/main/FC_Board.jpg)


Parallel Processing "Cog" Allocation Chart (Not all fuctionality implemented [yet?]):
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/Cog_Allocation_Chart.jpg)


PCB Layout:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/PCB_Layout.jpg)


PID Control Chart (Not all fuctionality implemented [yet?]):
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/PID_Chart.jpg)


PCB Schematics:

P0 Chip:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20P0.jpg)

P1 Chip:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20P1.jpg)

P2 Chip:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20P2.jpg)

P3 Chip:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20P3.jpg)

ADCs, battery cell ballance monitoring, MSP430 heartbeat signal monitoring and automatic reboot:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20Battery%20and%20Reboot.jpg)

Connectors for Comms, microSD data logging:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20Comms.jpg)

Power rails:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20Power.jpg)

Motor servo outputs:
![alt text](https://github.com/RichardO82/Quadcopter/blob/main/SCH%20Servos.jpg)
