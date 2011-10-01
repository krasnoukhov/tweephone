#include <LiquidCrystal.h>
#include <LiquidCrystalRus.h>
LiquidCrystalRus lcd(12, 11, 10, 5, 4, 3, 2);

const unsigned int  diskState = 7;
const unsigned int  diskCounter = 8;
const unsigned int  diskChangeInterval = 100;
const unsigned long diskNumberInterval = 1500;
const unsigned long diskInputInterval = 1000;

const String msgStart        = "Start type text:";
const String msgSend         = "Send/cancel     ";
const String msgError        = "Too long        ";
const char*  keyCodes[10][4] = {
  {".", ",", "!", "?"},
  {"a", "b", "c", ""},
  {"d", "e", "f", ""},
  {"g", "h", "i", ""},
  {"j", "k", "l", ""},
  {"m", "n", "o", ""},
  {"p", "q", "r", "s"},
  {"t", "u", "v", ""},
  {"w", "x", "y", "z"},
  {" ", "", "", ""}
};

unsigned int  currDiskCount = 0;
unsigned int  prevDiskCount = 0;
unsigned int  saveDiskCount = 0;
unsigned int  currDiskTimes = 0;
unsigned int  currMsgState = 0;
unsigned int  prevDiskCountState = HIGH;
unsigned long holdTime = 0;
unsigned long prevMillis = 0;
unsigned long inputMillis = 0;

String msg = "";

void setup() {
  lcd.begin(16, 2);  
  printMsg("");

  pinMode(diskState, INPUT);
  pinMode(diskCounter, INPUT);

  Serial.begin(115200);
}

void loop() {
  unsigned int  currDiskState = digitalRead(diskState);
  unsigned int  currDiskCountState = digitalRead(diskCounter);
  unsigned long currMillis = millis();

  // disk is moving
  if(currDiskState == HIGH) {
    if(prevMillis == 0) {
      prevMillis = currMillis;
      inputMillis = 0;
    }
    
    if(prevDiskCountState == HIGH && currDiskCountState == LOW) {
      currDiskCount++;
      delay(diskChangeInterval);
    }
    
    prevDiskCountState = currDiskCountState;
  }else{
    // disk reverted and we have some number
    if(currDiskCount != 0 || prevDiskCount != 0) {
      // we got max msg
      if(msg.length() >= 140) {
        currMsgState = 2;
        printMsg("");
      }else{
        String addMsg = "";
        if(holdTime == 0) {
          holdTime = currMillis-prevMillis-diskChangeInterval*currDiskCount;
        }     

        // number
        if(holdTime > diskNumberInterval) {
          addMsg = currDiskCount;

          currDiskCount = 0;
          prevDiskCount = 0;
          holdTime = 0;
          prevMillis = 0;
        // letter
        }else{
          // start timer to input
          if(inputMillis == 0) {
            inputMillis = currMillis;
            saveDiskCount = currDiskCount;
          }else{
            currDiskCount = saveDiskCount;
          }
          
          if(currMillis-inputMillis >= diskInputInterval) {
            unsigned int charsCount = 0;
            for(int i = 0; i <= 3; i++) {
              if(keyCodes[currDiskCount-1][i] != "") {
                charsCount++;
              }
            }

            // get letter to print            
            addMsg = keyCodes[currDiskCount-1][(currDiskTimes-1)%charsCount];

            inputMillis = 0;
            prevMillis = 0;
            currDiskCount = 0;
            saveDiskCount = 0;
            prevDiskCount = 0;
            currDiskTimes = 0;
          }else{            
            // same number next time
            if(prevMillis != 0 && (prevDiskCount == 0 || prevDiskCount == currDiskCount)) {
              currDiskTimes++;

              inputMillis = currMillis;
              prevMillis = 0;

            // another number
            }else if(prevMillis != 0 && prevDiskCount != 0 && prevDiskCount != currDiskCount) {  
              currDiskTimes = 1;

              inputMillis = currMillis;              
              prevMillis = 0;
            }

            prevDiskCount = currDiskCount;
            currDiskCount = 0;
          }
        }
        
        if(addMsg != "") {
          currMsgState = 1;
        }
        printMsg(addMsg);
      }
    }
  }
}

void printMsg(String add) {
  msg += add;
  
  lcd.setCursor((msg.length() > 15 ? msg.length()-15 : 0), 0);
  switch(currMsgState) {
      case 0:
        lcd.print(msgStart);
      break;
      case 1:
        lcd.print(msgSend);
      break;
      case 2:
        lcd.print(msgError);
      break;
  }

  lcd.setCursor(0, 1);
  lcd.print(msg);
  
  // scroll display
  if(msg.length() > 15 && add.length() > 0) {
    for(int i = 1; i <= add.length(); i++) {
      lcd.scrollDisplayLeft();
    }
  }
  
  lcd.setCursor(msg.length(), 1);
  lcd.cursor();
}

