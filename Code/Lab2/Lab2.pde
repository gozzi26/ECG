
// Need G4P library
// You can remove the PeasyCam import if you are not using
// the GViewPeasyCam control or the PeasyCam library.
import grafica.*;
import g4p_controls.*;
import processing.serial.*;
import java.awt.Font;

GPlot plot;
Serial myPort;
String val;
String comma = ",";
String FitnessMode = "1";
String RelaxVStressMode = "2";
String MeditationMode = "3";
String SleepingMode = "4";
String Calibrating = "C";
String Resting = "R";
String Start = "S";
String Done = "D";

String Yes = "Y";
String No = "N";

String result="";
String currentMode = "";
String workoutTimeString = "";

//Starting modes
boolean started = false;
//Currently in modes
boolean workingOut = false;
boolean checkingStress = false;
boolean meditating = false;
boolean calibrating = false;

//
boolean stressed = false;
boolean sleeping = false;
boolean currentlyMeditating = true;
boolean workedOutLongEnough = false;
boolean lookingAtResults = false;

boolean firstContact = false;


int totalHeartRate = 0;
int totalConfidence = 0;
int totalOxygen = 0;
int totalPointsRead = 0;
int userAge;
int totalStressPoints = 0;
int totalUnStressedPoints = 0;
int maximumHeartRate;
int time = 0;
int previousRead = 0;
int currentRead = 0;
int[] veryLightBreath = new int[]{0, 0, 0};
int[] lightBreath = new int[]{0, 0, 0};
int[] moderateBreath = new int[]{0, 0, 0};
int[] hardBreath = new int[]{0, 0, 0};
int[] maximumBreath = new int[]{0, 0, 0};

long timeInVeryLight = 0;
long timeInLight = 0;
long timeInModerate = 0;
long timeInHard = 0;
long timeInMaximum = 0;
long startTime = 0;
long timeInRem = 0;

double minimumVeryLight = .5 * maximumHeartRate;
double maximumVeryLight = .6 * maximumHeartRate;

double minimumLight = .6 * maximumHeartRate;
double maximumLight = .7 * maximumHeartRate;

double minimumModerate = .7 * maximumHeartRate;
double maximumModerate = .8 * maximumHeartRate;

double minimumHard = .8 * maximumHeartRate;
double maximumHard = .9 * maximumHeartRate;

double minimumMaximum = .9 * maximumHeartRate;
double maximumMaximum = 1 * maximumHeartRate;

float globalAverageRestingHeartRate = 0.0;
float globalAverageRespiratoryRate = 0.0;

float averageRestingHeartRate = 0.0;
float averageRespiratoryRate = 0.0;

////G4P Groups
GGroup groupHome;
GGroup groupCalibrating;
GGroup groupResting;
GGroup groupSelect;
GGroup groupFitness;
GGroup groupFitnessAfter;
GGroup groupStress;
GGroup groupMeditation;
GGroup groupSleep;

//G4P Labels
GLabel lblEnterAge;
GLabel lblError; 
GLabel lblAge;
GLabel lblCalibrating; 
GLabel lblCalibratingTime;
GLabel lblCalibratingSeconds;
GLabel lblCalculateResting; 
GLabel lblRestingTime;
GLabel lblRestingSeconds;
GLabel lblWelcomeToFitness; 
GLabel lblWorkoutTime; 
GLabel lblVeryLightText; 
GLabel lblLightText; 
GLabel lblModerateText; 
GLabel lblHardText; 
GLabel lblMaximumText; 
GLabel lblWelcomeToStressMode; 
GLabel lblStressedTime;  
GLabel lblStressLevel; 
GLabel lblStressLevelRegular; 
GLabel lblVeryLightTextInfo; 
GLabel lblLightTextInfo; 
GLabel lblModerateTextInfo; 
GLabel lblHardTextInfo; 
GLabel lblMaximumTextInfo; 
GLabel lblAVGResting; 
GLabel lblRespiratoryRate; 
GLabel lblARHVal; 
GLabel lblRRVal; 
GLabel lblSelectMode; 
GLabel lblWelcomeToMeditationMode; 
GLabel lblMeditationTime; 
GLabel lblBreathRatio; 
GLabel lblMeditationRatio; 
GLabel lblSleepLevel;
GLabel lblSleepLevelVal;
GLabel lblWelcomeToSleepMode;
GLabel lblSleepTime;
GLabel lblDidntWorkout;

//G4P Textfields
GTextField txtAGE;

int previousReadingHR = 0;
int previousReadingIn = 0;
int previousReadingEx = 0;
int timeBetweenBeats = 0;
int inhaleLen = 0;
int exhaleLen = 0;

//G4P Buttons
GButton btnSubmit;
GButton btnStartRestingHeartRate;
GButton btnStartWorkout; 
GButton btnEndWorkout; 
GButton btnStartStressMode; 
GButton btnStopStressChecking;
GButton btnWorkout; 
GButton btnRelaxVStressMode; 
GButton btnSleep;
GButton btnMeditation; 
GButton btnStartMeditationMode; 
GButton btnStopMeditationMode; 
GButton btnFitnessHome; 
GButton btnFitnessAfterHome; 
GButton btnStressHome; 
GButton btnMeditationHome; 
GButton btnStartSleepMode;
GButton btnStopSleepMode;
GButton btnSleepHome;

public void setup(){
  size(480, 480);
  createGUI();
  customGUI();
  createGroups();
  
  String portName = Serial.list()[1]; // change list based on your computer ports 0...2 (usually)
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n'); 
 
  
    // heartrate plot
  plot = new GPlot(this);
  plot.setPos(40, 240);
  plot.setDim(300, 130);
  plot.getTitle().setText("Heartrate graph");
  plot.getXAxis().getAxisLabel().setText("Time (sec) ");
  plot.getYAxis().getAxisLabel().setText("Heartrate (bpm)");
  
}

public void draw(){
    background(#F3F3F3);
  
    // if looking at results

   if(lookingAtResults) {
     if(workedOutLongEnough){
       fill(0);
       lblDidntWorkout.setVisible(false);
       rect(16, 20, 444, 215);
     }
     else{
       fill(255);
        lblDidntWorkout.setVisible(true);
       rect(16, 20, 444, 215);
     }
     
  
    GPointsArray pointsArray = plot.getPoints();
    int numTotalPoints = pointsArray.getNPoints();
    // to set colors we must fist analyze all the collected points, not possible dynamically 
    color[] pointColors = new color[numTotalPoints];
    for (int i = 0; i < numTotalPoints; i++) {
     GPoint curr = pointsArray.get(i);
     float currBPM = curr.getY();  // y is the bpm
     int colorVal = heartRateLevelInt(int(currBPM));
     if (colorVal == 1) {
       pointColors[i] = color(153, 243, 255, 100);
     } else if (colorVal == 2) {
       pointColors[i] = color(135, 250, 162, 100);
     } else if (colorVal == 3) {
       pointColors[i] = color(247, 216, 124, 100);
     } else if (colorVal == 4) {
       pointColors[i] = color(243, 255, 112, 100);
     } else if (colorVal == 5) {
       pointColors[i] = color(255, 97, 129, 100);
     }

    }
  
  
    plot.setPointColors(pointColors);    
    // Draw the plot  
    plot.beginDraw();
    plot.drawBackground();
    plot.drawBox();
    plot.drawXAxis();
    plot.drawYAxis();
    plot.drawTitle();
    plot.drawGridLines(GPlot.BOTH);
    plot.drawLines();
    plot.drawPoints();
    plot.endDraw();
  
  }
  
  
  if(calibrating){
    delay(1000);
    time += 1;
    String timeString = str(time);
    lblCalibratingTime.setText(timeString);
    if(time == 6){ // after 5 seconds we do not calibrate any longer 
       calibrating = false;
       delay(2000);
       setRestingScreen();
    }
  }
  
  if(currentMode.equals(Resting) && started){
      delay(1000);
      time += 1;
      String timeString = str(time);
      lblRestingTime.setText(timeString);
      if(time == 31){ //stop resting calculations after 30 seconds 
         started = false;
         leaveResting();
     }
   }
  
  if(currentMode.equals(RelaxVStressMode) && checkingStress){
    delay(1000);
    time += 1;
    String stressTimeString = "";
    if(stressed){
      lblStressLevelRegular.setText("You seem pretty stressed.");
    }
    else{
      lblStressLevelRegular.setText("You don't seem stressed.");
    }
     
    if(time < 60){
      if(time < 10){
        stressTimeString = "00:0" + str(time);
      }
      else{
        stressTimeString = "00:" + str(time);
      }
    }
    else{
      int minutes = time /60;
      int seconds = time -(minutes * 60);
      if(minutes < 10){
        stressTimeString = "0" + str(minutes) + ":";
        if(seconds < 10){
          stressTimeString += "0" + str(seconds);
        }
        else{
           stressTimeString += str(seconds);
        }
      }
      else{
        stressTimeString = str(minutes) + ":";
        if(seconds < 10){
          stressTimeString += "0" + str(seconds);
        }
        else{
           stressTimeString += str(seconds);
        }
      }
    }
   
    lblStressedTime.setText(stressTimeString);
  }
  
  if(currentMode.equals(FitnessMode) && workingOut){
        delay(1000);
        time += 1;
         
         
        if(time < 60){
          if(time < 10){
            workoutTimeString = "00:0" + str(time);
          }
          else{
            workoutTimeString = "00:" + str(time);
          }
        }
        else{
          int minutes = time /60;
          int seconds = time -(minutes * 60);
          if(minutes < 10){
            workoutTimeString = "0" + str(minutes) + ":";
            if(seconds < 10){
              workoutTimeString += "0" + str(seconds);
            }
            else{
               workoutTimeString += str(seconds);
            }
          }
          else{
            workoutTimeString = str(minutes) + ":";
            if(seconds < 10){
              workoutTimeString += "0" + str(seconds);
            }
            else{
               workoutTimeString += str(seconds);
            }
          }
        }
       
        lblWorkoutTime.setText(workoutTimeString);
      }
      
      if(currentMode.equals(MeditationMode) && meditating){
        delay(1000);
        time += 1;
        String meditationTimeString = "";
        if(currentlyMeditating){
          lblMeditationRatio.setText("You are meditating.");
        }
        else{
          lblMeditationRatio.setText("Work on your breath ratio.");
        }
     
        if(time < 60){
          if(time < 10){
            meditationTimeString = "00:0" + str(time);
          }
          else{
            meditationTimeString = "00:" + str(time);
          }
        }
        else{
          int minutes = time /60;
          int seconds = time -(minutes * 60);
          if(minutes < 10){
            meditationTimeString = "0" + str(minutes) + ":";
            if(seconds < 10){
              meditationTimeString += "0" + str(seconds);
            }
            else{
               meditationTimeString += str(seconds);
            }
          }
          else{
            meditationTimeString = str(minutes) + ":";
            if(seconds < 10){
              meditationTimeString += "0" + str(seconds);
            }
            else{
               meditationTimeString += str(seconds);
            }
          }
        }
       
        lblMeditationTime.setText(meditationTimeString);
      }
      
    if(currentMode.equals(SleepingMode) && sleeping){
        delay(1000);
        time += 1;
        String sleepTimeString = "";
        if(time < 60){
          if(time < 10){
            sleepTimeString = "00:0" + str(time);
          }
          else{
            sleepTimeString = "00:" + str(time);
          }
        }
        else{
          int minutes = time /60;
          int seconds = time -(minutes * 60);
          if(minutes < 10){
            sleepTimeString = "0" + str(minutes) + ":";
            if(seconds < 10){
              sleepTimeString += "0" + str(seconds);
            }
            else{
               sleepTimeString += str(seconds);
            }
          }
          else{
            sleepTimeString = str(minutes) + ":";
            if(seconds < 10){
              sleepTimeString += "0" + str(seconds);
            }
            else{
               sleepTimeString += str(seconds);
            }
          }
        }
       
        lblSleepTime.setText(sleepTimeString);
      }

}

void serialEvent( Serial myPort) {
  val = myPort.readStringUntil('\n');
  //make sure our data isn't empty before continuing
  if (val != null) {
  //trim whitespace and formatting characters (like carriage return)
    val = trim(val);
    println(val);
    
    if(currentMode.equals(RelaxVStressMode) && checkingStress){
         String[] baseValues = split(val, '*');
         int value = int(baseValues[0]);
         int breathDuration = int(baseValues[1]); // current length of user's breath
       
         double bpm = 0.0;
         double avgDuration = (globalAverageRespiratoryRate * 1000) / 60;
         if(value > 0){
          bpm = 60000.0/value;
          
          // two criteria to determine stress: 
          // user is stressed if their bpm is above the threshold 
          // get avg breathe duration and if currently determined duration is much shorter, then we could say that the user is also stressed
         
          if(bpm > (globalAverageRestingHeartRate + 10) || breathDuration > avgDuration + 4){
            totalStressPoints += 1;
          }
          else {
            totalUnStressedPoints +=1; 
          }
          
          if(totalStressPoints >= 10){
            stressed = true;
            //totalStressPoints = 0; 
            
          }
          else if (totalUnStressedPoints >= 10) {
            stressed = false;
            //totalUnStressedPoints = 0;
          } else {
              // in limbo : not stressed
              stressed = false;
          }
          
          
       }
       
    }
    
    if(currentMode.equals(SleepingMode) && sleeping){    
         int value = int(val);
         double bpm = 0.0;
        if(value > 0){
        bpm = 60000.0/value;
       
        if(bpm > (globalAverageRestingHeartRate + 10)){
          timeInRem += 1;
        }
      }
    }
  
    if(currentMode.equals(MeditationMode) && meditating){
        if(val.equals(Yes)){
          currentlyMeditating = true;
        }
        else{
           currentlyMeditating = false;
        }
      
    }
    
    if(currentMode.equals(FitnessMode) && workingOut){
       
        // read in data 
        String[] baseValues = split(val, '$');
        previousReadingHR = timeBetweenBeats;
        previousReadingIn = inhaleLen;
        previousReadingEx = exhaleLen;
        timeBetweenBeats = int(baseValues[0]);
        inhaleLen = int(baseValues[1]);
        exhaleLen = int(baseValues[2]);
        int breathTime = int(baseValues[3]);
        // here would go the data for respitory stuff (Section I.4)
    
        int heartRate = 0; // users current bpm
        // convert time from "xx:xx" to millis
          
        // only plot and process data if we get a valid read from the sensor
         
          
        
        
        if(timeBetweenBeats > 0) {
          previousRead = currentRead;
          currentRead = millis();
          long time = abs(currentRead-previousRead);
          
          
          boolean addBreath = true;
          
          
          // bpm
          //if(previousReadingHR != timeBetweenBeats || previousReadingIn != inhaleLen || previousReadingEx !=  exhaleLen){
            heartRateLevel(heartRate,inhaleLen, exhaleLen, addBreath, time);
          //}      
          // set label to current calculated bpm
          
          //String level = heartRateLevel(heartRate); // this function seems to be repurposed
          // set label to current heartrate level
          
          String timeTmpArray[] = split(workoutTimeString, ':');
          int timeTempArray[] = new int[]{0,0};
           if(timeTmpArray[0].substring(0,1).equals("0")){
            timeTempArray[0] = int(timeTmpArray[0].substring(1,2));
          }
          else{
            timeTempArray[0] = int(timeTmpArray[0]);
          }
          
          if(timeTmpArray[1].substring(0,1).equals("0")){
            timeTempArray[1] = int(timeTmpArray[1].substring(1,2));
          }
          else{
            timeTempArray[1] = int(timeTmpArray[1]);
          }
          
          int graphTime = (timeTempArray[0] * 60) + (timeTempArray[1]);
          
           //workoutTimeStringParsed; // time to be plotted
          
          plot.addPoint(graphTime, heartRate, "(" + str(graphTime) + " , " + str(heartRate) + ")");
        }
    }
  
    if(val.contains("Resting:")){
        String[] baseValues = split(val, ':');
       
        globalAverageRestingHeartRate = int(baseValues[1])*2;
        globalAverageRespiratoryRate = int(baseValues[2])*2;
        String beats = str(globalAverageRestingHeartRate) + " (Beats/Minutes)";
        String breath = str(globalAverageRespiratoryRate) + " (Breaths/Minutes)";
        lblARHVal.setText(beats);
        lblRRVal.setText(breath);
    }
   
  } 
}


      
   
     
      
int heartRateLevelInt(int heartRate){
  if(heartRate < 5){
   
   return 0;
  }
  else if(heartRate <  maximumVeryLight){
    
    return 1;
  }
  else if(heartRate >= minimumLight && heartRate <  maximumLight){
   return 2;
  }
  else if(heartRate >= minimumModerate && heartRate <  maximumModerate){
    
    return 3;
  }
  else if(heartRate >= minimumHard && heartRate <  maximumHard){
    return 4;
  }
  else if(heartRate >= minimumMaximum){
    return 5;
  }
  else{
    return 6;
  } 
}





// Use this method to add additional statements
// to customise the GUI controls
public void customGUI(){
  txtAGE = new GTextField(this, 203, 154, 128, 36, G4P.SCROLLBARS_NONE);
  txtAGE.setPromptText("Enter your age");
  txtAGE.setOpaque(true);
  
  lblAge = new GLabel(this, 150, 153, 52, 36);
  lblAge.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblAge.setText("AGE:");
  lblAge.setOpaque(false);
  
  btnSubmit = new GButton(this, 150, 202, 180, 36);
  btnSubmit.setText("Next");
  btnSubmit.addEventHandler(this, "btnSubmitClick");
  
  lblError = new GLabel(this, 130, 118, 180, 27);
  lblError.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblError.setOpaque(false);
  
  lblCalibrating = new GLabel(this, 92, 32, 329, 39);
  lblCalibrating.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblCalibrating.setText("Please wait while we calibrate the device.");
  lblCalibrating.setOpaque(false);
  
  lblCalibratingTime = new GLabel(this, 166, 86, 106, 85);
  lblCalibratingTime.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblCalibratingTime.setText("0");
  lblCalibratingTime.setOpaque(false);
  
  lblDidntWorkout = new GLabel(this, 98, 98, 299, 67);
  lblDidntWorkout.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblDidntWorkout.setText("You didn't workout long enough to measure any levels. The graph below will have little detail.");
  lblDidntWorkout.setOpaque(false);
  
  lblCalibratingSeconds = new GLabel(this, 272, 117, 80, 20);
  lblCalibratingSeconds.setText("seconds");
  lblCalibratingSeconds.setOpaque(false);
  
  lblCalculateResting = new GLabel(this, 92, 32, 329, 39);
  lblCalculateResting.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblCalculateResting.setText("Let's calculate your resting heartrate and respiratory rate! The calculation will be done over 30 seconds. Click \"START\" when you are ready.");
  lblCalculateResting.setOpaque(false);
  
  btnStartRestingHeartRate = new GButton(this, 92, 180, 329, 80);
  btnStartRestingHeartRate.setText("START");
  btnStartRestingHeartRate.addEventHandler(this, "btnRestingHeartRateClick");
  
  lblRestingTime = new GLabel(this, 166, 86, 106, 85);
  lblRestingTime.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblRestingTime.setText("0");
  lblRestingTime.setOpaque(false);
  
  lblRestingSeconds = new GLabel(this, 272, 117, 80, 20);
  lblRestingSeconds.setText("seconds");
  lblRestingSeconds.setOpaque(false);
  
  lblAVGResting = new GLabel(this, 100, 20, 160, 25);
  lblAVGResting.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  lblAVGResting.setText("Average Resting Heartrate:");
  lblAVGResting.setOpaque(false);
  
  lblRespiratoryRate = new GLabel(this, 100, 50, 160, 25);
  lblRespiratoryRate.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  lblRespiratoryRate.setText("Respiratory Rate:");
  lblRespiratoryRate.setOpaque(false);
  
  lblARHVal = new GLabel(this, 260, 20, 120, 25);
  lblARHVal.setText("0");
  lblARHVal.setOpaque(false);
  
  lblRRVal = new GLabel(this, 260, 50, 120, 25);
  lblRRVal.setText("0");
  lblRRVal.setOpaque(false);
  
  lblSelectMode = new GLabel(this, 40, 81, 400, 33);
  lblSelectMode.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblSelectMode.setText("Select the mode you would like to use.");
  lblSelectMode.setOpaque(false);
  
  btnWorkout = new GButton(this, 41, 123, 400, 60);
  btnWorkout.setText("Working out?");
  btnWorkout.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
  btnWorkout.addEventHandler(this, "btnWorkoutClick");
  
  btnRelaxVStressMode = new GButton(this, 40, 200, 400, 60);
  btnRelaxVStressMode.setTextAlign(GAlign.CENTER, GAlign.CENTER);
  btnRelaxVStressMode.setText("Are you relaxed?");
  btnRelaxVStressMode.setLocalColorScheme(GCScheme.CYAN_SCHEME);
  btnRelaxVStressMode.addEventHandler(this, "btnRelaxVsStressClick");
  
  btnMeditation = new GButton(this, 40, 277, 400, 60);
  btnMeditation.setText("Meditating?");
  btnMeditation.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  btnMeditation.addEventHandler(this, "btnMeditationClick");
  
  btnSleep = new GButton(this, 40, 354, 400, 60);
  btnSleep.setText("Sleeping?");
  btnSleep.setLocalColorScheme(GCScheme.BLUE_SCHEME);
  btnSleep.addEventHandler(this, "btnSleepClick");
  
  lblWelcomeToFitness = new GLabel(this, 120, 25, 240, 29);
  lblWelcomeToFitness.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblWelcomeToFitness.setText("Welcome to Fitness Mode");
  lblWelcomeToFitness.setOpaque(false);
  
  btnStartWorkout = new GButton(this, 120, 167, 240, 60);
  btnStartWorkout.setText("Start Workout");
  btnStartWorkout.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnStartWorkout.addEventHandler(this, "btnStartWorkoutOnClick");
  
  btnEndWorkout = new GButton(this, 120, 242, 240, 60);
  btnEndWorkout.setText("End Workout");
  btnEndWorkout.setLocalColorScheme(GCScheme.RED_SCHEME);
  btnEndWorkout.addEventHandler(this, "btnEndWorkoutOnClick");
  
  lblWorkoutTime = new GLabel(this, 120, 65, 240, 80);
  lblWorkoutTime.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblWorkoutTime.setText("00:00");
  lblWorkoutTime.setOpaque(false);
  
  lblWelcomeToStressMode = new GLabel(this, 120, 20, 240, 20);
  lblWelcomeToStressMode.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblWelcomeToStressMode.setText("Welcome to stress mode.");
  lblWelcomeToStressMode.setOpaque(false);
  
  lblStressedTime = new GLabel(this, 120, 48, 240, 80);
  lblStressedTime.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblStressedTime.setText("00:00");
  lblStressedTime.setOpaque(false);
  
  btnStartStressMode = new GButton(this, 120, 167, 240, 60);
  btnStartStressMode.setText("Start Checking");
  btnStartStressMode.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnStartStressMode.addEventHandler(this, "btnStartStressModeOnClick");
  
  btnStopStressChecking = new GButton(this, 120, 242, 240, 60);
  btnStopStressChecking.setText("Stop Checking");
  btnStopStressChecking.addEventHandler(this, "btnStopStressCheckingOnClick");
  
  lblStressLevel = new GLabel(this, 120, 135, 80, 20);
  lblStressLevel.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  lblStressLevel.setText("Stress Level:");
  lblStressLevel.setOpaque(false);
  
  lblStressLevelRegular = new GLabel(this, 200, 135, 160, 20);
  lblStressLevelRegular.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblStressLevelRegular.setOpaque(false);
 
  
  lblWelcomeToSleepMode = new GLabel(this, 120, 20, 240, 20);
  lblWelcomeToSleepMode.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblWelcomeToSleepMode.setText("Welcome to sleep mode.");
  lblWelcomeToSleepMode.setOpaque(false);
  
  lblSleepTime = new GLabel(this, 120, 48, 240, 80);
  lblSleepTime.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblSleepTime.setText("00:00");
  lblSleepTime.setOpaque(false);
  
  btnStartSleepMode = new GButton(this, 120, 167, 240, 60);
  btnStartSleepMode.setText("Start Checking");
  btnStartSleepMode.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnStartSleepMode.addEventHandler(this, "btnStartSleepModeOnClick");
  
  btnStopSleepMode = new GButton(this, 120, 242, 240, 60);
  btnStopSleepMode.setText("Stop Checking");
  btnStopSleepMode.addEventHandler(this, "btnStopSleepModeOnClick");
  
  lblSleepLevel = new GLabel(this, 120, 135, 80, 20);
  lblSleepLevel.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  lblSleepLevel.setText("Sleep Status:");
  lblSleepLevel.setOpaque(false);
  
  lblSleepLevelVal = new GLabel(this, 200, 135, 160, 20);
  lblSleepLevelVal.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblSleepLevelVal.setOpaque(false);
  
  btnSleepHome = new GButton(this, 53, 13, 80, 30);
  btnSleepHome.setText("Home");
  btnSleepHome.addEventHandler(this, "btnSleepHomeOnClick");
  
 
  
  
  lblWelcomeToMeditationMode = new GLabel(this, 120, 20, 240, 20);
  lblWelcomeToMeditationMode.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblWelcomeToMeditationMode.setText("Welcome to meditation mode.");
  lblWelcomeToMeditationMode.setOpaque(false);
  
  lblMeditationTime = new GLabel(this, 120, 48, 240, 80);
  lblMeditationTime.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblMeditationTime.setText("00:00");
  lblMeditationTime.setOpaque(false);
  btnStartMeditationMode = new GButton(this, 120, 167, 240, 60);
  btnStartMeditationMode.setText("Start Checking");
  btnStartMeditationMode.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnStartMeditationMode.addEventHandler(this, "btnStartMeditationModeClick");
  btnStopMeditationMode = new GButton(this, 120, 242, 240, 60);
  btnStopMeditationMode.setText("Stop Checking");
  btnStopMeditationMode.setLocalColorScheme(GCScheme.RED_SCHEME);
  btnStopMeditationMode.addEventHandler(this, "btnStopMeditationModeOnClick");
  lblBreathRatio = new GLabel(this, 120, 135, 90, 20);
  lblBreathRatio.setTextAlign(GAlign.RIGHT, GAlign.MIDDLE);
  lblBreathRatio.setText("Breath Ratio:");
  lblBreathRatio.setOpaque(false);
  lblMeditationRatio = new GLabel(this, 210, 135, 150, 20);
  lblMeditationRatio.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  lblMeditationRatio.setOpaque(false);
  btnFitnessHome = new GButton(this, 53, 13, 80, 30);
  btnFitnessHome.setText("Home");
  btnFitnessHome.addEventHandler(this, "btnFitnessHomeOnClick");
  btnFitnessAfterHome = new GButton(this, 53, 13, 80, 30);
  btnFitnessAfterHome.setText("Home");
  btnFitnessAfterHome.addEventHandler(this, "btnFitnessAfterHomeOnClick");
  btnStressHome = new GButton(this, 53, 13, 80, 30);
  btnStressHome.setText("Home");
  btnStressHome.addEventHandler(this, "btnStressHomeOnClick");
  btnMeditationHome = new GButton(this, 53, 13, 80, 30);
  btnMeditationHome.setText("Home");
  btnMeditationHome.addEventHandler(this, "btnMeditationHomeOnClick");
}

public void createGroups(){
  groupHome = new GGroup(this);
  groupResting = new GGroup(this);
  groupCalibrating = new GGroup(this);
  groupSelect = new GGroup(this);
  groupFitness = new GGroup(this);
  groupFitnessAfter = new GGroup(this);
  groupStress = new GGroup(this);
  groupMeditation = new GGroup(this);
  groupSleep = new GGroup(this);
  
  
  groupHome.addControl(txtAGE);
  groupHome.addControl(btnSubmit);
  groupHome.addControl(lblError);
  groupHome.addControl(lblAge); 
  
  groupCalibrating.setVisible(0,false);
  groupCalibrating.addControl(lblCalibrating);
  groupCalibrating.addControl(lblCalibratingTime);
  groupCalibrating.addControl(lblCalibratingSeconds);
  lblCalibratingTime.setFont(new Font("Monospaced", Font.PLAIN, 60));
  
  groupResting.setVisible(0,false);
  groupResting.addControl(lblCalculateResting);
  groupResting.addControl(btnStartRestingHeartRate);
  groupResting.addControl(lblRestingTime);
  groupResting.addControl(lblRestingSeconds);
  lblRestingTime.setFont(new Font("Monospaced", Font.PLAIN, 60));
  
  groupSelect.setVisible(0,false);
  groupSelect.addControl(lblAVGResting);
  groupSelect.addControl(lblRespiratoryRate);
  groupSelect.addControl(lblARHVal);
  groupSelect.addControl(lblRRVal);
  groupSelect.addControl(lblSelectMode);
  groupSelect.addControl(btnWorkout);
  groupSelect.addControl(btnRelaxVStressMode);
  groupSelect.addControl(btnMeditation);
  groupSelect.addControl(btnSleep);
  
  groupFitness.setVisible(0,false);
  groupFitness.addControl(lblWelcomeToFitness);
  groupFitness.addControl(btnStartWorkout);
  groupFitness.addControl(btnEndWorkout);
  groupFitness.addControl(lblWorkoutTime);
  groupFitness.addControl(btnFitnessHome);
  lblWorkoutTime.setFont(new Font("Monospaced", Font.PLAIN, 60));
  
  
  groupFitnessAfter.setVisible(0,false);
  groupFitnessAfter.addControl(lblVeryLightText);
  groupFitnessAfter.addControl(lblLightText);
  groupFitnessAfter.addControl(lblModerateText);
  groupFitnessAfter.addControl(lblHardText);
  groupFitnessAfter.addControl(lblMaximumText);
  groupFitnessAfter.addControl(lblVeryLightTextInfo);
  groupFitnessAfter.addControl(lblLightTextInfo);
  groupFitnessAfter.addControl(lblModerateTextInfo);
  groupFitnessAfter.addControl(lblHardTextInfo);
  groupFitnessAfter.addControl(lblHardTextInfo);
  groupFitnessAfter.addControl(lblMaximumTextInfo);
  groupFitnessAfter.addControl(lblDidntWorkout);
  groupFitnessAfter.addControl(btnFitnessAfterHome);
  
  groupStress.setVisible(0,false);
  groupStress.addControl(lblWelcomeToStressMode);
  groupStress.addControl(lblStressedTime);
  groupStress.addControl(btnStartStressMode);
  groupStress.addControl(btnStopStressChecking);
  groupStress.addControl(lblStressLevel);
  groupStress.addControl(lblStressLevelRegular);
  groupStress.addControl(btnStressHome);
  lblStressedTime.setFont(new Font("Monospaced", Font.PLAIN, 60));
  
  groupSleep.setVisible(0,false);
  groupSleep.addControl(lblWelcomeToSleepMode);
  groupSleep.addControl(lblSleepTime);
  groupSleep.addControl(btnStartSleepMode);
  groupSleep.addControl(btnStopSleepMode);
  groupSleep.addControl(lblSleepLevel);
  groupSleep.addControl(lblSleepLevelVal);
  groupSleep.addControl(btnSleepHome);
  lblSleepTime.setFont(new Font("Monospaced", Font.PLAIN, 60));
  
  groupMeditation.setVisible(0, false);
  groupMeditation.addControl(lblWelcomeToMeditationMode);
  groupMeditation.addControl(lblMeditationTime);
  groupMeditation.addControl(btnStartMeditationMode);
  groupMeditation.addControl(btnStopMeditationMode);
  groupMeditation.addControl(lblBreathRatio);
  groupMeditation.addControl(lblMeditationRatio);
  groupMeditation.addControl(btnMeditationHome);
  lblMeditationTime.setFont(new Font("Monospaced", Font.PLAIN, 60));

}

public void setCalibratingScreen(){
   groupHome.setVisible(0, false);
   myPort.write(Calibrating);
   groupCalibrating.setVisible(0, true);
   calibrating = true;
   
}
//Screen setup methods
public void setRestingScreen(){
  groupCalibrating.setVisible(0, false);
  groupResting.setVisible(0,true);
  setMode(Resting);
}

public void leaveResting(){
   groupResting.setVisible(0,false);
   setSelectScreen();
}


public void setSelectScreen(){
   groupSelect.setVisible(0,true);
}

public void setFitnessDuringScreen(){
  setMode(FitnessMode);
  groupSelect.setVisible(0,false);
  lblWorkoutTime.setText("00:00");
  btnStartWorkout.setEnabled(true);
  btnFitnessHome.setEnabled(true);
  btnEndWorkout.setEnabled(false);
  groupFitness.setVisible(0,true);
}

public void setSleepScreen(){
  setMode(SleepingMode);
  groupSelect.setVisible(0,false);
  btnSleepHome.setEnabled(true);
  lblSleepTime.setText("00:00");
  btnStartSleepMode.setEnabled(true);
  btnStopSleepMode.setEnabled(false);
  groupSleep.setVisible(0,true);
}

public void setStressScreen(){
  setMode(RelaxVStressMode);
  groupSelect.setVisible(0,false);
  btnStressHome.setEnabled(true);
  lblStressedTime.setText("00:00");
  btnStartStressMode.setEnabled(true);
  btnStopStressChecking.setEnabled(false);
  groupStress.setVisible(0,true);
}

public void setMeditationScreen(){
  setMode(MeditationMode);
  groupSelect.setVisible(0,false);
  lblMeditationTime.setText("00:00");
  btnMeditationHome.setEnabled(true);
  btnStartMeditationMode.setEnabled(true);
  btnStopMeditationMode.setEnabled(false);
  groupMeditation.setVisible(0,true);
}

//Screen Update methods 
public void updateSleepScreen(boolean starting){
  if(starting){
   startTracking();
   sleeping = true;
   btnSleepHome.setEnabled(false);
   btnStartSleepMode.setEnabled(false);
   btnStopSleepMode.setEnabled(true);
  }
  else{
    btnSleepHome.setEnabled(true);
    btnStartSleepMode.setEnabled(false);
    btnStopSleepMode.setEnabled(false);
    String rem = "You spent";
    if(timeInRem > 60){
      long minutes = timeInRem / 60;
      rem += str(minutes) + "minutes in REM sleep"; 
    }
    else{
      rem += str(timeInRem) + "seconds in REM sleep"; 
    }   
    lblSleepLevelVal.setText(rem);
    myPort.write("D");
    sleeping = false;
  }
}


public void updateFitnessScreen(boolean starting){
  if(starting){
   startTracking();
   workingOut = true;
    workoutTimeString = "00:00";
   btnFitnessHome.setEnabled(false);
   btnStartWorkout.setEnabled(false);
   btnEndWorkout.setEnabled(true);
  }
  else{
    btnFitnessHome.setEnabled(true);
    btnStartWorkout.setEnabled(false);
    btnEndWorkout.setEnabled(false);
    workingOut = false;
    myPort.write("D");
    delay(2000);
    lookingAtResults = true;
    setFitnessAfterScreen();
  }
}

public void updateStressScreen(boolean starting){
   if(starting){
    startTracking();
    checkingStress = true;
     btnStressHome.setEnabled(false);
    btnStartStressMode.setEnabled(false);
    btnStopStressChecking.setEnabled(true);
  }
  else{
    btnStartStressMode.setEnabled(false);
    btnStopStressChecking.setEnabled(false);
     btnStressHome.setEnabled(true);
     myPort.write("D");
    checkingStress = false;
  }
}

public void updateMeditationScreen(boolean starting){
   if(starting){
    startTracking();
    meditating = true;
     btnMeditationHome.setEnabled(false);
    btnStartMeditationMode.setEnabled(false);
    btnStopMeditationMode.setEnabled(true);
  }
  else{
    btnMeditationHome.setEnabled(true);
    btnStartMeditationMode.setEnabled(false);
    btnStopMeditationMode.setEnabled(false);
    myPort.write("D");
    meditating = false;
  }
}

public void setHomeScreen(String previousScreen){
    if(previousScreen.equals("Stress Check")){
        groupStress.setVisible(0,false);
    }
    else if(previousScreen.equals("Working Out")){
         groupFitness.setVisible(0,false);
    }
    else if(previousScreen.equals("Workout Results")){
       groupFitnessAfter.setVisible(0,false);
       lookingAtResults = false;
    }
    else if(previousScreen.equals("Meditation Check")){
       groupMeditation.setVisible(0,false);
    }
    else if(previousScreen.equals("Sleep Check")){
       groupSleep.setVisible(0,false);
    }
    myPort.write("D");
    setSelectScreen();
}

public void setFitnessAfterScreen(){
   groupFitness.setVisible(0,false);
   lookingAtResults = true;
   long total = timeInVeryLight + timeInLight + timeInModerate +timeInHard +timeInMaximum;
   println(total);
   if(total < 60){ // we want to dismiss any zones that had less than a minute of activity due to their inconsistency in overall workout time 
     workedOutLongEnough = false;
     return;
   }
   
   float veryLightPercent = (float(str(timeInVeryLight)) / total)*416;
   float lightPercent= (float(str(timeInLight)) / total) * 416;
   float moderatePercent = (float(str(timeInModerate)) / total) * 416;
   float hardPercent = (float(str(timeInHard)) / total) * 416;
   float maximumPercent = (float(str(timeInMaximum)) / total) * 416;
   
   double veryLightRR = 0;
   int veryLightInhaleAvg = 0;
   int veryLightExhaleAvg = 0;
   
   double lightRR = 0;
   int lightInhaleAvg = 0;
   int lightExhaleAvg = 0;
   
   double moderateRR = 0;
   int moderateInhaleAvg =  0;
   int moderateExhaleAvg =  0;
   
   double hardRR = 0;
   int hardInhaleAvg =  0;
   int hardExhaleAvg =  0;
  
   double maximumRR = 0;
   int maximumInhaleAvg = 0;
   int maximumExhaleAvg = 0; 
   
   
   if(veryLightBreath[2] > 0 && timeInVeryLight > 0){
        veryLightInhaleAvg = veryLightBreath[0]/veryLightBreath[2];
        veryLightExhaleAvg = veryLightBreath[1]/veryLightBreath[2];
        veryLightRR = veryLightBreath[2]/ ceil((float(str(timeInVeryLight)))/60);
    }
   
   if(lightBreath[2] > 0 && timeInLight > 0){
        lightInhaleAvg = lightBreath[0]/lightBreath[2];
        lightExhaleAvg = lightBreath[1]/lightBreath[2];
        lightRR = lightBreath[2]/ceil((float(str(timeInLight)))/60);
   }
    
    if(moderateBreath[2] > 0 && timeInModerate > 0){
        moderateInhaleAvg = moderateBreath[0]/moderateBreath[2];
        moderateExhaleAvg = moderateBreath[1]/moderateBreath[2];
        moderateRR = moderateBreath[2]/ceil((float(str(timeInModerate)))/60);
    }
    if(hardBreath[2] > 0 && timeInHard > 0){
        hardInhaleAvg = hardBreath[0]/hardBreath[2];
        hardExhaleAvg = hardBreath[1]/hardBreath[2];
        hardRR =  hardBreath[2]/ ceil((float(str(timeInHard)))/60);
    }
    
    if(maximumBreath[2] > 0 && timeInMaximum > 0 ){
        maximumInhaleAvg = maximumBreath[0]/maximumBreath[2];
        maximumExhaleAvg = maximumBreath[1]/maximumBreath[2];
        maximumRR = maximumBreath[2]/ceil((float(str(timeInMaximum)))/60);
    }
   
   
   
   if(timeInVeryLight >= 0 && timeInVeryLight < 60){

   }
   else{
       String veryLightMin = "Inhale: " + veryLightInhaleAvg + "ms Exhale: " + veryLightExhaleAvg + "ms Resp: "+ veryLightRR + "BR/M";
       if(veryLightPercent >= 208){
         lblVeryLightText = new GLabel(this, 42, 40, veryLightPercent, 32);
         lblVeryLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblVeryLightText.setText(veryLightMin);
         lblVeryLightText.setLocalColorScheme(GCScheme.CYAN_SCHEME);
         lblVeryLightText.setOpaque(true);
         lblVeryLightText.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
       else{
         lblVeryLightText = new GLabel(this, 42, 40, veryLightPercent, 32);
         lblVeryLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblVeryLightText.setText("");
         lblVeryLightText.setLocalColorScheme(GCScheme.CYAN_SCHEME);
         lblVeryLightText.setOpaque(true);
         lblVeryLightTextInfo = new GLabel(this, 42+veryLightPercent, 40, 416-veryLightPercent, 32);
         lblVeryLightTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblVeryLightTextInfo.setText(veryLightMin);
         lblVeryLightTextInfo.setLocalColorScheme(GCScheme.CYAN_SCHEME);
         lblVeryLightTextInfo.setOpaque(false);
          lblVeryLightTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
   }
   
   if(timeInLight >= 0 && timeInLight < 60){
    
   }
   else{
       String lightMin = "Inhale: " + lightInhaleAvg  + "ms Exhale: " + lightExhaleAvg + "ms Resp: "+ lightRR + "BR/M";
       if(lightPercent >= 208){
         lblLightText = new GLabel(this, 42, 80, lightPercent, 32);
         lblLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblLightText.setText(lightMin);
         lblLightText.setLocalColorScheme(GCScheme.GREEN_SCHEME);
         lblLightText.setOpaque(true);
         lblLightText.setFont(new Font("Monospaced", Font.PLAIN,12));
       }
       else{
         lblLightText = new GLabel(this, 42, 80, lightPercent, 32);
         lblLightText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblLightText.setText("");
         lblLightText.setLocalColorScheme(GCScheme.GREEN_SCHEME);
         lblLightText.setOpaque(true);
         lblLightTextInfo = new GLabel(this, 42+lightPercent, 80, 416-lightPercent, 32);
         lblLightTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblLightTextInfo.setText(lightMin);
         lblLightTextInfo.setLocalColorScheme(GCScheme.GREEN_SCHEME);
         lblLightTextInfo.setOpaque(false);
         lblLightTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
      
   }
   
   if(timeInModerate >= 0 && timeInModerate < 60){
     
   }
   else{
       String moderateMin = "Inhale: " + moderateInhaleAvg  + "ms Exhale: " + moderateExhaleAvg + "ms Resp: "+ moderateRR + "BR/M";
       if(moderatePercent >= 208){
         lblModerateText = new GLabel(this, 42, 120, moderatePercent, 32);
         lblModerateText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblModerateText.setText(moderateMin);
         lblModerateText.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
         lblModerateText.setOpaque(true);
         lblModerateText.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
       else{
         lblModerateText = new GLabel(this, 42, 120, moderatePercent, 32);
         lblModerateText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblModerateText.setText("");
         lblModerateText.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
         lblModerateText.setOpaque(true);
         lblModerateTextInfo = new GLabel(this, 42+moderatePercent, 120, 416-moderatePercent, 32);
         lblModerateTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblModerateTextInfo.setText(moderateMin);
         lblModerateTextInfo.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
         lblModerateTextInfo.setOpaque(false);
         lblModerateTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
      
   }
   
   if(timeInHard >= 0 && timeInHard < 60){
    
   }
   else{
       String hardMin = "Inhale: " + hardInhaleAvg  + "ms Exhale: " + hardExhaleAvg + "ms Resp: " + hardRR + "BR/M";
       if(hardPercent >= 208){
         lblHardText = new GLabel(this, 42, 160, hardPercent, 32);
         lblHardText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblHardText.setText(hardMin);
         lblHardText.setLocalColorScheme(GCScheme.GOLD_SCHEME);
         lblHardText.setOpaque(true);
         lblHardText.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
       else{
         lblHardText = new GLabel(this, 42, 160, hardPercent, 32);
         lblHardText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblHardText.setText("");
         lblHardText.setLocalColorScheme(GCScheme.GOLD_SCHEME);
         lblHardText.setOpaque(true);
         lblHardTextInfo = new GLabel(this, 42+hardPercent, 160, 416-hardPercent, 32);
         lblHardTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblHardTextInfo.setText(hardMin);
         lblHardTextInfo.setLocalColorScheme(GCScheme.GOLD_SCHEME);
         lblHardTextInfo.setOpaque(false);
          lblHardTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
   }
   
   if(timeInMaximum >= 0 && timeInMaximum <= 60){
    
   }
   else{
      String maxMin = "Inhale: " + maximumInhaleAvg  + "ms Exhale: " + maximumExhaleAvg + "ms Resp: " + maximumRR+ "BR/M";
       if(maximumPercent >= 208){
         lblMaximumText = new GLabel(this, 42, 200, maximumPercent, 32);
         lblMaximumText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblMaximumText.setText(maxMin);
         lblMaximumText.setLocalColorScheme(GCScheme.RED_SCHEME);
         lblMaximumText.setOpaque(true);
         lblMaximumText.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
       else{
         lblMaximumText = new GLabel(this, 42, 200, maximumPercent, 32);
         lblMaximumText.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
         lblMaximumText.setText("");
         lblMaximumText.setLocalColorScheme(GCScheme.RED_SCHEME);
         lblMaximumText.setOpaque(true);
         lblMaximumTextInfo = new GLabel(this, 42+maximumPercent, 200, 416-maximumPercent, 32);
         lblMaximumTextInfo.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
         lblMaximumTextInfo.setText(maxMin);
         lblMaximumTextInfo.setLocalColorScheme(GCScheme.RED_SCHEME);
         lblMaximumTextInfo.setOpaque(false);
         lblMaximumTextInfo.setFont(new Font("Monospaced", Font.PLAIN, 12));
       }
    
   }
   btnFitnessAfterHome.setEnabled(true);
   workedOutLongEnough = true;
   groupFitnessAfter.setVisible(0,true);
  
   
}


// tracks stuff
void startTracking(){
  time = 0;
  started = true;
  myPort.write(Start);
}


//Setting Modes
void setMode(String mode){

  if(mode.equals(FitnessMode)){
     currentMode = FitnessMode;
     myPort.write(FitnessMode);
  }
  else if(mode.equals(RelaxVStressMode)){
     currentMode = RelaxVStressMode;
     myPort.write(RelaxVStressMode);
  }
  else if(mode.equals(Resting)){
     currentMode = Resting;
     myPort.write(Resting);
  }
   else if(mode.equals(MeditationMode)){
     currentMode = MeditationMode;
     myPort.write(MeditationMode);
  }     
  else if(mode.equals(SleepingMode)){
     currentMode = SleepingMode;
     myPort.write(SleepingMode);
  }
}


void heartRateLevel(int heartRate, int inhaleLen, int exhaleLen, boolean addBreath, long time){
  if( heartRate <=  maximumVeryLight){
    timeInVeryLight += 1;
    veryLightBreath[0] +=inhaleLen;
    veryLightBreath[1] +=exhaleLen;
    if(addBreath){
      veryLightBreath[2] += 1;
    }
    
  }
  else if(heartRate >= minimumLight && heartRate <  maximumLight){
    timeInLight += 1;
    lightBreath[0] +=inhaleLen;
    lightBreath[1] +=exhaleLen;
    if(addBreath){
      lightBreath[2] += 1;
    }
    
  }
  else if(heartRate >= minimumModerate && heartRate <  maximumModerate){
    timeInModerate += 1;
    moderateBreath[0] +=inhaleLen;
    moderateBreath[1] +=exhaleLen;
    if(addBreath){
      moderateBreath[2] += 1;
    }
   
  }
  else if(heartRate >= minimumHard && heartRate <  maximumHard){
    timeInHard += 1;
    hardBreath[0] +=inhaleLen;
    hardBreath[1] +=exhaleLen;
    if(addBreath){
      hardBreath[2] += 1;
    }
    
  }
  else{
    timeInMaximum += 1;
    maximumBreath[0] +=inhaleLen;
    maximumBreath[1] +=exhaleLen;
    if(addBreath){
      maximumBreath[2] += 1;
    }
  }
}



void setAgeAndHeartRateRange(int age){
     userAge = age;
     maximumHeartRate = 220 - userAge;
     minimumVeryLight = .5 * maximumHeartRate;
     maximumVeryLight = .6 * maximumHeartRate;
    
     minimumLight = .6 * maximumHeartRate;
     maximumLight = .7 * maximumHeartRate;
    
     minimumModerate = .7 * maximumHeartRate;
     maximumModerate = .8 * maximumHeartRate;
    
     minimumHard = .8 * maximumHeartRate;
     maximumHard = .9 * maximumHeartRate;
    
     minimumMaximum = .9 * maximumHeartRate;
     maximumMaximum = 1 * maximumHeartRate;
}

//Button click methods
public void btnSubmitClick(GButton source, GEvent event) { //_CODE_:btnSubmit:499834:
  String age = txtAGE.getText().trim();
  if(age.equals("")){
    lblError.setText("You did not enter an age.");
  }
  if(age.contains(" ")){
   lblError.setText("Your format entered was incorrect"); 
  }
  else{
      boolean correct = age.matches("-?[0-9]+");
      if(correct){
        setAgeAndHeartRateRange(int(age));
         setCalibratingScreen();
      }
      else{
         lblError.setText("You entered letters.");
      }
  }
}

public void btnRestingHeartRateClick(GButton source, GEvent event) { 
  startTracking();
  btnStartRestingHeartRate.setEnabled(false);
} 

//Mode Button Methods
public void btnWorkoutClick(GButton source, GEvent event) { 
  setFitnessDuringScreen();
} 

public void btnRelaxVsStressClick(GButton source, GEvent event) { 
  setStressScreen();
} 

public void btnMeditationClick(GButton source, GEvent event) { 
  setMeditationScreen();
} 

public void btnSleepClick(GButton source, GEvent event) { 
  setSleepScreen();
} 

//Start and Stop Workout Buttons
public void btnStartWorkoutOnClick(GButton source, GEvent event) { 
   updateFitnessScreen(true);
} 

public void btnEndWorkoutOnClick(GButton source, GEvent event) { 
  updateFitnessScreen(false);
}

//Start and Stop Stressed Buttons
public void btnStartStressModeOnClick(GButton source, GEvent event) { 
  updateStressScreen(true);
} 

public void btnStopStressCheckingOnClick(GButton source, GEvent event) { 
  updateStressScreen(false);
} 

public void btnStartSleepModeOnClick(GButton source, GEvent event) { 
  updateSleepScreen(true);
} 

public void btnStopSleepModeOnClick(GButton source, GEvent event) { 
  updateSleepScreen(false);
} 

public void btnStartMeditationModeClick(GButton source, GEvent event) { 
  updateMeditationScreen(true);
} 

public void btnStopMeditationModeOnClick(GButton source, GEvent event) { 
  updateMeditationScreen(false);
}

public void btnFitnessHomeOnClick(GButton source, GEvent event) { 
  setHomeScreen("Working Out");
} 

public void btnFitnessAfterHomeOnClick(GButton source, GEvent event) { 
  setHomeScreen("Workout Results");
} 

public void btnStressHomeOnClick(GButton source, GEvent event) { 
  setHomeScreen("Stress Check");
} 

public void btnMeditationHomeOnClick(GButton source, GEvent event) { 
  setHomeScreen("Meditation Check");
} 


public void btnSleepHomeOnClick(GButton source, GEvent event) { 
  setHomeScreen("Sleep Check");
} 
  
