/*
 Reads out various potentiometer values and reports the values via serial communication
 */

#define c_AnalogInsCount 5
int _AnalogInPins[] = {3, 4, 5, 6, 7};
int _AnalogValues[c_AnalogInsCount];

void setup() {
  Serial.begin(115200);
}

void loop() {
  // read the analog values
  for(int i = 0; i < c_AnalogInsCount; i++)
  {
    int val = analogRead(_AnalogInPins[i]);

    _AnalogValues[i] = map(val, 0, 1023, 512, -512);
    Serial.print(_AnalogValues[i]);
    Serial.print(",");
  }
  Serial.println(); 
  
  delay(500);                           // waits for the servo to get there 
}
