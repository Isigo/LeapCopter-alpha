/**
*Authors : Théo Baron, Raphaël Duchon-Doris
*Creation date : 17/12/2013
*Last update : 26/11/2014
*************************************************

LeapCopter is a LeapMotion application made for controlling a quadcopter Hubsan X4 with the LeapMotion controller.
Contact : theo.lucaroni@gmail.com

*************************************************
**/

import de.voidplus.leapmotion.*;
import processing.serial.*;

CopterModel copter;
CopterVisualisation visual;
int etat = 2;
int mode = 1;
int precisionMultiplicator = 50;
int stabilisation = 1;
int rudder_enabled = 0;
/*int circle_gesture_flip = 0;
int flips_enabled = 0;
int circle_millis = 20;
int keytap_millis = 0;
String clockwiseness = "clockwise";*/
long timeToWait = 10;
long lastTime;
int throttle_lock = 0;
float stabilisation_throttle = 0.60;
float stabilisation_tuning = 0.00;
String[] stabilisation_tuning_loaded;
String[] stabilisation_tuning_save;
PVector route_vector_final;
PVector route_vector1;
PVector route_vector2;
float distance;
int planification = 0;
int keytap_count = 0;
LeapMotion leap;

void setup()
{
  size(800, 640, P3D);
  background(255);
  lights();
 fill(50);
  //noFill();
  ellipseMode(CENTER);
  noStroke();
  frameRate(30);
  PFont font = createFont("SansSerif", 20);    
  textFont(font);
  textAlign(LEFT);
  copter = new CopterModel((PApplet)this);
  visual = new CopterVisualisation(copter, 0, 490, 100);
  lastTime = millis();
  leap = new LeapMotion(this).withGestures("key_tap, circle"); //leap detects key_tap and circle gestures, for a further use 
}
boolean newframe=false;
void draw()
{
  background(255);
  String[] stabilisation_tuning_loaded = loadStrings("stabilisation_tuning.txt");
  String stabilisation_tuning_joined = join(stabilisation_tuning_loaded, "");
  stabilisation_tuning_joined = stabilisation_tuning_joined.replace(",","");
  stabilisation_tuning = round(float(stabilisation_tuning_joined)*100)*0.01;//Rounding seems to reduce the amount of 0.049999997 type values caused by Processing's poor maths :)
  text("Stabilisation Tuning : "+round(stabilisation_tuning*100), 300, 620);//We still get such values so it's rounded this time to an integer for text
  /*if(stabilisation_tuning_joined.length() == 6) //Did all this for nothing apparently x)
  {
    char stab1 = stabilisation_tuning_joined.charAt(1);
    //println("charat1 ",stab1);
    char stab2 = stabilisation_tuning_joined.charAt(3);
    //println("charat3 ",stab2);
    char stab3 = stabilisation_tuning_joined.charAt(4);
    //println("charat4 ",stab3);
    stabilisation_tuning = -(int(stab1)-48) -((int(stab2)-48)*0.1) -((int(stab3)-48)*0.01);
    fill(0,0,255);
    text("Stabilisation Tuning : "+stabilisation_tuning, 300, 620);
  }
  else if(stabilisation_tuning_joined.length() == 5)
  {
    char stab1 = stabilisation_tuning_joined.charAt(0);
    //println("charat0 ",stab1);
    char stab2 = stabilisation_tuning_joined.charAt(2);
    //println("charat2 ",stab2);
    char stab3 = stabilisation_tuning_joined.charAt(3);
    //println("charat3",stab3);
    println(int(stab3));
    stabilisation_tuning = (int(stab1)-48) +(int(stab2)-48)*0.1 +(int(stab3)-48)*0.01;
    fill(0,0,255);
    text("Stabilisation Tuning : "+stabilisation_tuning, 300, 620);
  }*/
  //println("loaded", stabilisation_tuning);
  int fps = leap.getFrameRate();
  visual.update();
  copter.sendData();
  float stepSize = 0.01;  
  int finger_detected = 0;
  for(Hand hand : leap.getHands())
  {
     hand.draw();
    int     hand_id          = hand.getId();
    PVector hand_position    = hand.getPosition();
    PVector hand_stabilized  = hand.getStabilizedPosition();
    PVector hand_direction   = hand.getDirection();
    PVector hand_dynamics    = hand.getDynamics();
    float   hand_roll        = hand.getRoll();
    float   hand_pitch       = hand.getPitch();
    float   hand_yaw         = hand.getYaw();
    float   hand_time        = hand.getTimeVisible();
    PVector sphere_position  = hand.getSpherePosition();
    float   sphere_radius    = hand.getSphereRadius();
     //copter.rudder=hand_yaw/50;
    text("Hand Position :", 660, 490);
    text(hand_position.x, 660, 530);
    text(hand_position.y, 660, 560);
    text(hand_position.z, 660, 590);
    /*handX = hand_position.x/10;
    handY = hand_position.y/10;*/
     
     for(Finger finger : hand.getFingers()){
     finger.draw();
      int     finger_id         = finger.getId();
      PVector finger_position   = finger.getPosition();
      PVector finger_stabilized = finger.getStabilizedPosition();
      PVector finger_velocity   = finger.getVelocity();
      PVector finger_direction  = finger.getDirection();
      float   finger_time       = finger.getTimeVisible();
      int     touch_zone        = finger.getTouchZone();
      float   touch_distance    = finger.getTouchDistance();
      
      finger_detected = 1;
      switch(touch_zone) //touch zone declaration
      {
        case -1:
        break;
        
        case 0:
        hand.draw();
        rudder_enabled = 0;
        break;
        
        case 1:
        rudder_enabled = 1;          
        break;
        
      }
     } //end of for:fingers
     if(etat == 1)//if control on
      {
        if(mode == 1)//if leap mode
        {
          if(finger_detected == 1)// if hand opened
          {
            if (throttle_lock == 0)
            {
          copter.throttle=(hand_position.y/-200)+2.90; //Changed for less sensitive control
            }
          copter.elevator=(hand_roll/(-1*precisionMultiplicator))+0.15;
          copter.aileron=hand_pitch/(1*precisionMultiplicator);
          if(rudder_enabled == 1)
            {
              copter.rudder=(hand_yaw/90)-0.15;
            }
            else
            {
              copter.rudder = 0;
            }
          }
      if(finger_detected == 0) //self landing code part if you close your hand
      {
      if(stabilisation == 0)/// if stabilisation == 0 you have no control
      {
        copter.elevator = copter.aileron = 0;
        //self landing
      if(copter.throttle > 0)
      {
        if(copter.throttle < 0.5)
        {
        if (millis() - lastTime > timeToWait)
          {
            copter.throttle -= (stepSize);
            lastTime = millis();
          }
        }
        if(copter.throttle >= 0.5 && copter.throttle <= 1)// when copter.throttle = [0.5 ; 1]
        {
        if (millis() - lastTime > timeToWait)
          {
            copter.throttle -= (stepSize*0.5);
            lastTime = millis();
          }
        }
      }// end of self-landing condition
      }//end of if(stabilisation)
      }//end of if hand opened
      }//end of if leap mode
      }//end of if control on
      
  } //end of for:hand
      
      if(etat == 1) //if control on
      {
        if(mode == 1) //leap control
        {
          
          if (stabilisation == 1) //stabilisation code part
          {
            copter.throttle=stabilisation_throttle+stabilisation_tuning;
            copter.elevator=0;
            copter.aileron=0;
            copter.rudder = 0;

           
          }
          
         
        }
        if (mode == 2) //keyboard control
        {
          if (stabilisation == 1)//if stabilisation on
          {
            copter.throttle = stabilisation_throttle+stabilisation_tuning;
            copter.elevator = 0;
            copter.aileron = 0;
            copter.rudder = 0;
          }
        }
          
      }
      
     //maximum values
     if(copter.throttle > 2)
     {
       copter.throttle = 2;
     }
     if(copter.throttle < 0)
     {
       copter.throttle = 0;
     }
     if(copter.aileron > 0.5)
     {
       copter.aileron = 0.5;
     }
     if(copter.aileron < -0.5)
     {
       copter.aileron = -0.5;
     }
     if(copter.elevator > 0.5)
     {
       copter.elevator = 0.5;
     }
     if(copter.elevator < -0.5)
     {
       copter.elevator = -0.5;
     }
     if(copter.rudder > 0.5)
     {
        copter.rudder = 0.5;
     }
     if(copter.rudder < -0.5)
     {
        copter.rudder = -0.5;
     }   
     

  if(mode == 1)//if leap mode
  {
  if(finger_detected == 0){
  if(stabilisation == 0)
  {
    copter.elevator = copter.aileron = 0;
    
      if(copter.throttle > 0)// start descent when no hand
      {
        if(copter.throttle < 0.5)
        {
        if (millis() - lastTime > timeToWait)
          {
            copter.throttle -= (stepSize);
            lastTime = millis();
          }
        }
        if(copter.throttle >= 0.5 && copter.throttle <= 1)
        {
        if (millis() - lastTime > timeToWait)
          {
            copter.throttle -= (stepSize*0.5);
            lastTime = millis();
          }
        }
      }// end of descend condition
  }
  }
  }
  if(etat == 2) //if control off
    {
          copter.elevator = 0;
          copter.aileron = 0;
          copter.rudder = 0;
          //self landing timing
      if(copter.throttle > 0)
      {
        if(copter.throttle < 0.5)
        {
        if (millis() - lastTime > timeToWait)
          {
            copter.throttle -= stepSize;
            lastTime = millis();
          }
        }
        if(copter.throttle >= 0.5 && copter.throttle <= 1)// when copter.throttle = [0.5 ; 1]
        {
        if (millis() - lastTime > timeToWait)
          {
            copter.throttle -= (stepSize*0.5);
            lastTime = millis();
          }
        }
      }// end of self-landing condition
     copter.elevator = 0;
     copter.aileron = 0;
     copter.rudder = 0;
    }

}//end of void draw()

void leapOnKeyTapGesture(KeyTapGesture g){ //KeyTap Gesture Function
  int       id               = g.getId();
  Finger    finger           = g.getFinger();
  PVector   position         = g.getPosition();
  PVector   direction        = g.getDirection();
  long      duration         = g.getDuration();
  float     duration_seconds = g.getDurationInSeconds();
  
  
  if(etat == 1)//if control activated
  {
    if(mode == 1)//if mode Leap
    {
      if(planification == 1) 
      {
        if(keytap_count == 2) keytap_count = 0;
        keytap_count ++;
        if (keytap_count == 1) 
        {
          route_vector1 = g.getPosition();
        }
        if (keytap_count == 2)
        {
          route_vector2 = g.getPosition();
          route_vector_final.x = route_vector2.x - route_vector1.x;
          route_vector_final.y = route_vector2.y - route_vector1.y;
          route_vector_final.z = route_vector2.z - route_vector1.z;
          println(route_vector_final.x, route_vector_final.y, route_vector_final.z);
        }
      }//end of if planification
  }//end if mode
  }//end if etat
 }//end of keytap
 
 /*void leapOnCircleGesture(CircleGesture g, int state){ //A function for the circle gesture, may be used to "flip" later on
  int       id               = g.getId();
  Finger    finger           = g.getFinger();
  PVector   position_center  = g.getCenter();
  PVector   position_normal  = g.getNormal();
  float     radius           = g.getRadius();
  float     progress         = g.getProgress();
  long      duration         = g.getDuration();
  float     duration_seconds = g.getDurationInSeconds();

  switch(state){
    case 1: // Start
      break;
    case 2: // Update
      circle_millis = 60;
      break;
    case 3: // Stop
      //println("CircleGesture: "+id);
      circle_gesture_flip = 1;
      println(position_normal);
      if(position_normal.z < 50)
      {
      clockwiseness = "counterclockwise";
      } else {
      clockwiseness = "clockwise";
      }
      println(clockwiseness);
      break;
      
  } //end of switch state
    } //end of circle gesture*/

//beginning of the keyboard control code section
void keyPressed() {
  float stepSize=0.01;
  float stepSizekey=0.06;
  if (key == '5')
  {
    switch(planification)
    {
    case 0:
    planification = 1;
    println("PLANIFICATION ACTIVE");
    break;
    
    case 1:
    planification = 0;
    println("PLANIFICATION INACTIVE");
    break;
    }
  }
   if (key == '4')
  {
    switch(throttle_lock)
    {
    case 0:
    throttle_lock = 1;
    println("Throttle is locked");
    break;
    
    case 1:
    throttle_lock = 0;
    println("Throttle is unlocked");
    break;
    }
  }
  //rudder control on/off
  if (key == '3') {
    switch(rudder_enabled)
    {
      case 0:
      rudder_enabled = 1;
      println("Rudder control enabled");
      break;
      
      case 1:
      rudder_enabled = 0;
      println("Rudder control disabled");
      break;
    }
  }
  //switch stabilisation on/off
  if (key == '2') {
    switch(stabilisation)
    {
      case 0:
      stabilisation = 1;
      println("Stabilisation on");
      break;
      
      case 1:
      stabilisation = 0;
      println("Stabilisation off");
      break;
    }
  }
  //switch keyboard mode on/off
  if (key == '1') {
    switch(mode)
    {
      case 1:
      copter.aileron=0;
      copter.elevator=0;
      copter.throttle=1;
      mode = 2;
      println("Keyboard mode");
      break;
      
      case 2:
      mode = 1;
      println("Leap mode");
      break;
    }
  }
  //had to use logic operator !, dunno why it doesn't work with ==
if(etat !=2){//if control on
    if(mode !=1){//if keyboard mode
      if(stabilisation != 1)//if stabilisation off
      {
  if (key == 'a') {
    copter.throttle += stepSizekey;
    if(copter.throttle > 2)//maximum value
    {
      copter.throttle = 2;
    }
    
    println("Copter throttle ="+copter.throttle);
  }
  if (key == 'z') {
    copter.throttle -= stepSizekey;
    if (copter.throttle < 0)//minimum value
    {
      copter.throttle = 0;
    }
    println("Copter throttle ="+copter.throttle);
  }
  if (key == 'A' || key == 'Z') {
    copter.throttle = 0;
    println("Copter throttle ="+copter.throttle);
  }
}//end of if stab off
}//end of if keyboard mode
  }//end of if control on
  
  //switch control on/off
  if (key == '0') {
    switch(etat)
    {
      case 1:
      etat = 2;
      println("Control activated");
      break;
      
      case 2:
      etat = 1;
      println("Control desactivated");
      break;
    }
  }
  //settings of precision
  if (key == '+') {
    precisionMultiplicator = precisionMultiplicator+5;
  }
  if (key == '-') {
    precisionMultiplicator = precisionMultiplicator-5;
  } 
if(etat !=2){//if control on
    if(mode !=1){//if keyboard mode
      if(stabilisation != 1)//if stab off
      {
  if (key == CODED) {
    if (keyCode == UP) {
      copter.elevator+=stepSizekey;
      if (copter.elevator > 0.5)
      {
        copter.elevator = 0.5;
      }
      
      println("Copter elevator ="+copter.elevator);
    } 
    else if (keyCode == DOWN) {
      copter.elevator-=stepSizekey;
      if (copter.elevator < -0.5)
      {
        copter.elevator = -0.5;
      }
      println("Copter elevator ="+copter.elevator);
    } else    if (keyCode == RIGHT) {
      copter.aileron+=stepSizekey;
      if(copter.aileron > 0.5)
      {
        copter.aileron = 0.5;
      }
      println("Copter aileron ="+copter.aileron);
    } 
    else if (keyCode == LEFT) {
      copter.aileron-=stepSizekey;
      if(copter.aileron < -0.5)
      {
        copter.aileron = -0.5;
      }
      println("Copter aileron ="+copter.aileron);
    
    }
  }
}//end of if stab off
}//end of if keyboard mode
}  //end of if control on 
if (etat !=2 && stabilisation == 1 && key == CODED){ //Stabilisation tuning, as the stabilisation throttle depends on your evironment
  String stabilisation_tuning_string;
  if (keyCode == UP){
    println("up");
    stabilisation_tuning = stabilisation_tuning+0.01;
    stabilisation_tuning_string = str(stabilisation_tuning)+","; //added a comma to make a string array (to use saveStrings function)
    stabilisation_tuning_save = split(stabilisation_tuning_string, " , ");
    saveStrings("stabilisation_tuning.txt",stabilisation_tuning_save);
  }
  if (keyCode == DOWN){
    println("down");
    stabilisation_tuning = stabilisation_tuning-0.01;
    stabilisation_tuning_string = str(stabilisation_tuning)+","; //added a comma to make a string array (to use saveStrings function)
    stabilisation_tuning_save = split(stabilisation_tuning_string, " , ");
    saveStrings("stabilisation_tuning.txt",stabilisation_tuning_save);
  }
} //end of stabilisation tuning
} //end of void keyPressed function
