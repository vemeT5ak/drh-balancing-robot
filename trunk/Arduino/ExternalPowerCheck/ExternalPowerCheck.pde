/*
Measures the scaled external voltage (~12V).
The external voltage is scaled down by a pair of resistors:

Vin --- 68k --- AnalogIn --- 22k --- GND

*/

#include "WProgram.h"

#define scaledExternalVoltageInPin 0
#define Vext_Vscaled_Ratio 0.0134  // ratio between external voltage and analog read value (defined by volatage divider)

void setup()
{
  analogReference(EXTERNAL); // we set the analog reference for the analog to digital converters to 3.3V
 
  Serial.begin(115200); 
}

void loop()
{ 
  int scaledVoltage = analogRead(scaledExternalVoltageInPin);    // read the input pin
  float externalVoltage = scaledVoltage * Vext_Vscaled_Ratio;

  Serial.println(externalVoltage, 2);
  delay(1000); 
}

