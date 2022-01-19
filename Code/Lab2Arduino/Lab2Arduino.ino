
//Processing data
char val;
char mode;
bool started = false;
bool calibrate = false;
//FSR Variables 
int FSRArray[100];
int FSRTimeArray[100];
int fsrReading;
int fsrCount = 0;
int fsrPrevVal = 0;
int breathCount = 0;
int userThreshold = 200; // default
int  numBelowThreshold = 0;

double ratio = 0.0;

long inhaleLen;
long exhaleLen;
unsigned long fsrCurrentTime = 0;
unsigned long fsrPreviousTime = 0;
unsigned long breathTime = 0;


bool breathStarted = false;
bool fsrFull = false;
bool stopTemp = true;

//ECG Variables
int ECGArray[100];
int ECGTimeArray[100];
int beatCount = 0;
int heartPrevVal = 0;
int heartCount = 0;

unsigned long ecgTimeStamp = 0;
unsigned long ecgCurrentTime = 0;
unsigned long ecgPreviousTime = 0;
unsigned long ecgTimeBetweenBeats = 0;

float ecgReading = 0;
float ecgReadingAvg = 0;
float ecgReadingPrevTwo = 0;
float ecgReadingPrevOne = 0;

bool newBeat = true;
bool ecgFull = false;
bool meditating = false;
int meditativeState = 0;




void setup() {
  Serial.begin(115200);
  pinMode(10, INPUT); // Setup for leads off detection LO +
  pinMode(11, INPUT); // Setup for leads off detection LO -
  resetFSRArray();
  resetFSRTimeArray();
  resetECGArray();
  resetECGTimeArray();
}

void loop() {
  // put your main code here, to run repeatedly:
  if (Serial.available() > 0) { // If data is available to read,
      val = Serial.read();
      //Serial.println(val);
      if(val == 'C'){
        Serial.println("Calibrating");
        calibrate = true;
      }

      if(val == 'S'){
        started = true;
        //Serial.println("Starting");
      }

      if(val == 'D'){
        //meditating
        started = false;
      }

      if(val == 'R'){
        mode = 'R';
        //Serial.println("Resting");
      }

      if(val == '1'){
        mode = 'F';
      }

      if(val == '2'){
        mode = 'S';
      }

      if(val == '3'){
        mode = 'M';
      }

      if(val == '4'){
        mode = 'L';
      }

     
      
  }
  
  if(calibrate){
      calibrateFsr();
      calibrate = false;
  }
  
  if(started){
    if(mode == 'R')
    {
      //Serial.println("Resting");
      calculateResting();
    }

    if(mode == 'F'){
      //calculateFitness();

      // send over formatted values as such: 
      // timeBetweenBeats$other stuff$more stuff$ other more stuff$
      // need to add stress mode check to our FSR and ECG reading functions
      fsrReading = analogRead(A2);
      evaluateFsrReading();
      if(!(digitalRead(10) == 1 || digitalRead(11) == 1)){
        evaluateECGReading();
      }

    }
    
    if(mode == 'S'){
      fsrReading = analogRead(A2);
      evaluateFsrReading();
      if(!(digitalRead(10) == 1 || digitalRead(11) == 1)){
        evaluateECGReading();
      }
      String stress = ecgTimeBetweenBeats + "*" + breathTime;
      Serial.println(stress);
      delay(100); 
    }

    if(mode == 'L'){
      fsrReading = analogRead(A2);
      evaluateFsrReading();
      if(!(digitalRead(10) == 1 || digitalRead(11) == 1)){
        evaluateECGReading();
      }
      Serial.println(ecgTimeBetweenBeats);
      delay(100); 
    }

     if(mode == 'M'){
      fsrReading = analogRead(A2);
      evaluateFsrReading();
      if(!(digitalRead(10) == 1 || digitalRead(11) == 1)){
        evaluateECGReading();
      }
      if(ratio < 3.0){
        meditativeState++;
        if(meditativeState >= 3){
          Serial.println("N");
        }
        else{
          Serial.println("Y");
        }
      }
      else{
        meditativeState = 0;
        Serial.println("Y");
      }
      delay(100);
    }
  }
}

void calibrateFsr(){
  unsigned long functionStart = millis();
  long calibCount = 0;
  long long calib = 0;
  while(abs(millis()-functionStart) <= 5000){
    fsrReading = analogRead(A2);
    if (fsrReading != 0) {
       calib += fsrReading;
       calibCount++;
    }
  }
  userThreshold = ((calib / calibCount) / 1.33); 
//  String threshold = "threshhold = " + userThreshold;
//  Serial.print("threshhold = ");
//  Serial.println(userThreshold);
}


void calculateResting(){
  unsigned long startTime = millis();
//  while(millis() <= startTime + 30000){
  do {
    fsrReading = analogRead(A2);
    evaluateFsrReading();
    if(!(digitalRead(10) == 1 || digitalRead(11) == 1)){
      evaluateECGReading();
    }
  } while(abs(millis()-startTime) <= 30000);
  
  String resting = "Resting:" + String(beatCount) + ":" + String(breathCount);
  Serial.println(resting);
  mode = '-';
  started = false;
}




//Reset Array Functions
void resetFSRArray(){
    for(int i = 0; i < 100; i++){
      FSRArray[i] = 0;
    }
}

void resetFSRTimeArray() {
   for(int i = 0; i < 100; i++){
    FSRTimeArray[i] = 0;
  }
}

void resetECGArray() {

  for (int i = 0; i < 100; i++) {
    ECGArray[i] = 0;
  }
}


void resetECGTimeArray() {

  for (int i = 0; i < 100; i++) {
    ECGTimeArray[i] = 0;
  }
}

//Get index functions
int getIndexLastFSRReading() {

   int ret = 100; 
   for(int i = 0; i < 100; i++){
    if(FSRArray[i] == 0) {
      ret = i-1; //first encounter of 0 means we did not populate this
      break;
    }
  }

  return ret; 
}

int getIndexLastHeartReading() {

  int ret = 100;
  for (int i = 0; i < 100; i++) {
    if (ECGArray[i] == 0) {
      ret = i - 1; //first encounter of 0 means we did not populate this
      break;
    }
  }

  return ret;
}

//Calculate peak functions 
void calculateHeartPeak() {

  int maxIndex = 0; //index of the peak god damn it allison (hi TAs)
  for (int i = 0; i < 100; i++) {
    if (ECGArray[maxIndex] < ECGArray[i]) {
      maxIndex = i; // replace stored index holding peak with current peak
    }
  }

  
//    Serial.print("Your peak value = ");
//    Serial.println(ECGArray[maxIndex]);
//  
//    Serial.print("Time of your peak heartrate= ");
//    Serial.println(ECGTimeArray[maxIndex]);
  //delay(50);
  // clear out arrays after each breath
  resetECGTimeArray();
  resetECGArray();
  //delay(100);
}

void calculateBreathPeak(long breathTime) {
  
  int maxIndex = 0; //index of the peak god damn it allison (hi TAs)
  for (int i = 0; i < 100; i++) {
    if (FSRArray[maxIndex] < FSRArray[i]) {
      maxIndex = i; // replace stored index holding peak with current peak
    }
  }
//  Serial.print("\n\n");
//  Serial.print("Your peak breath = ");
//  Serial.println(FSRArray[maxIndex]);

//  Serial.print("Time of your peak= ");
//  Serial.println(FSRTimeArray[maxIndex] / 1000); 


  //Serial.print("length of inhale=");
  inhaleLen = (FSRTimeArray[maxIndex] - FSRTimeArray[0]); 
  //Serial.println(inhaleLen);

 
  //Serial.print("peak time; start time");

  //Serial.print(FSRTimeArray[maxIndex]);
  //Serial.print(", ");
  //Serial.print(FSRTimeArray[0]);


  //Serial.print("length of exhale=");
  exhaleLen = breathTime - inhaleLen;
  //Serial.println( exhaleLen);

  //Serial.print("ratio of out/in= ");
  
  if(inhaleLen <= 0.1){
   ratio  = 0 ;
  }
  else{
   ratio = ((double) exhaleLen) / ((double)inhaleLen) ;
  }
//  Serial.println(ratio); 
//  delay(500);


 
  // clear out arrays after each breath
  resetFSRTimeArray();
  resetFSRArray();

  //delay(500);
  
}

void evaluateFsrReading(){
    delay(100);
  
    if(FSRArray[99] != 0){
      fsrFull = true;
    }

    if(fsrFull){  
      if(fsrReading > userThreshold){
         if(!breathStarted){
            fsrCurrentTime = millis();
            breathStarted = true;
         }
         memcpy(FSRArray, &FSRArray[1], sizeof(FSRArray) - sizeof(int));
         FSRArray[99] = fsrReading;
         fsrPrevVal = fsrReading;
  
         memcpy(FSRTimeArray, &FSRTimeArray[1], sizeof(FSRTimeArray) - sizeof(int));
         FSRTimeArray[99] = millis();
  
         numBelowThreshold = 0; // we have no values below yet
  
         FSRTimeArray[0] = fsrCurrentTime; // hardcode first index to start of breath time 
        
      }
      else{
        numBelowThreshold++;
        //if(prevVal > 0){
        if (numBelowThreshold > 3 && fsrPrevVal > 0) {
            breathStarted = false;
            fsrPreviousTime = fsrCurrentTime;
            fsrCurrentTime = millis();
            breathTime = fsrCurrentTime - fsrPreviousTime;
            breathCount += 1;
            calculateBreathPeak(breathTime);
            fsrFull = false;
            fsrPrevVal = 0;
            fsrCount = 0;
        }
      //prevVal = 0;
    }
  }
  else{
    if(fsrReading > userThreshold ){
       if(!breathStarted){
          fsrCurrentTime = millis();
          breathStarted = true;
       }
       FSRArray[fsrCount] = fsrReading;
       fsrPrevVal = fsrReading; 
       numBelowThreshold = 0; // we have no values below yet
       FSRTimeArray[fsrCount] = millis();
       fsrCount++;
    }
    else{
      // below threshhold, increase count below
      numBelowThreshold++;
      //if(prevVal > 0){
      if (numBelowThreshold > 3 && fsrPrevVal > 0) {
          breathStarted = false;
          fsrPreviousTime = fsrCurrentTime;
          fsrCurrentTime = millis();
          breathTime = fsrCurrentTime - fsrPreviousTime;
          breathCount += 1;
          calculateBreathPeak(breathTime);
          fsrFull = false;
          fsrCount = 0;
          fsrPrevVal = 0;
      }
      //prevVal = 0;
    }
  }
 }


void evaluateECGReading(){
    ecgReadingPrevTwo = ecgReadingPrevOne;
    ecgReadingPrevOne = ecgReading;
    ecgReading = analogRead(A0);
    ecgReadingAvg = (ecgReading + ecgReadingPrevOne + ecgReadingPrevTwo) / 3;
    ecgCurrentTime = millis();

    if (ecgReadingAvg > 100 && ecgReadingAvg < 1000) {
      //Serial.println(ecgReadingAvg);
      //ecgReadingAvg=ecgReading;

      if (ECGArray[99] != 0) {
        ecgFull = true;
      }

      if (ecgFull) {
        // heart rate crossed threshold
        if (ecgReadingAvg > 640 && newBeat == true) {
          ecgPreviousTime = ecgTimeStamp;
          ecgTimeStamp = millis();
          ecgTimeBetweenBeats = abs(ecgTimeStamp - ecgPreviousTime);
//          if(mode == 'S'){
//            Serial.print(ecgTimeBetweenBeats);
//            Serial.print("*"); 
//            Serial.println(breathTime);
//          }

          
          newBeat = false;

          delay(100);

          memcpy(ECGArray, &ECGArray[1], sizeof(ECGArray) - sizeof(int));
          ECGArray[99] = ecgReadingAvg;
          
          heartPrevVal = ecgReadingAvg;

          memcpy(ECGTimeArray, &ECGTimeArray[1], sizeof(ECGTimeArray) - sizeof(int));
          ECGTimeArray[99] = millis();


          ECGTimeArray[0] = ecgTimeStamp; // hardcode first index to when heartrate crosses threshold
          beatCount += 1;
          calculateHeartPeak();
          ecgFull = false;
          heartCount = 0;

        } 
        else {
          // below threshold
          //beatCount +=1;
          //calculateHeartPeak();
          //ecgFull = false;
          //heartPrevVal = 0;
          //heartCount = 0;
          newBeat = true;
        }
      }  
      else {
        

        // heart rate crossed threshold
        if (ecgReadingAvg > 640 && newBeat == true) {
          ecgPreviousTime = ecgTimeStamp;
          ecgTimeStamp = millis();
          ecgTimeBetweenBeats = abs(ecgTimeStamp - ecgPreviousTime);
//          if(mode == 'S'){
//            Serial.print(ecgTimeBetweenBeats);
//            Serial.print("*"); 
//            Serial.println(breathTime);
//          }
          if(mode == 'F'){
            Serial.print(ecgTimeBetweenBeats);
            Serial.print("$"); 
            Serial.print(inhaleLen);
            Serial.print("$");
            Serial.println(exhaleLen);
        }
          newBeat = false;
          delay(100);

          ECGArray[heartCount] = ecgReadingAvg;
          //heartPrevVal = ecgReadingAvg;

          ECGTimeArray[heartCount] = ecgTimeStamp; // hardcode first index to when heartrate crosses threshold
          heartCount++;

          // below threshold
          beatCount += 1;
          calculateHeartPeak();
          ecgFull = false;
          //heartPrevVal = 0;
        } 
        else {
          // below threshold
          // beatCount +=1;
          //calculateHeartPeak();
          //ecgFull = false;
          //heartPrevVal = 0;
          //heartCount = 0;
          newBeat = true;
        }
      }
    }
    //Wait for a bit to keep serial data from saturating
   // delay(5);

      //    if (millis() >= 30000) {
      //
      //      //beats  after 30 sec
      //      String tempheartCount = "Heartbeat Count: " + String(beatCount);
      //      Serial.println(tempheartCount);
      //      delay(10000);
      //    }
}
