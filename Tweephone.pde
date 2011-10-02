#include <LiquidCrystal.h>
#include <LiquidCrystalRus.h>
LiquidCrystalRus lcd(12, 11, 10, 5, 4, 3, 2);

const unsigned int  diskState = 7;
const unsigned int  diskCounter = 8;
const unsigned int  diskChangeInterval = 100;
const unsigned long diskNumberInterval = 1500;
const unsigned long diskInputInterval = 1000;

const String msgStart        = "Turn the dial   ";
const String msgSend         = "Hang up to send ";
const String msgError        = "Too long        ";
const char*  keyCodes[][5] = {
  {".", ",", "!", "?", "@"},
  {"a", "b", "c"},
  {"d", "e", "f"},
  {"g", "h", "i"},
  {"j", "k", "l"},
  {"m", "n", "o"},
  {"p", "q", "r"},
  {"t", "u", "v"},
  {"w", "x", "y", "z"},
  {" "}
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
  printMsg("", true, 0);

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
        printMsg("", true, 0);
      }else{
        String addMsg = "";
        boolean newChar = true;
        int curOffset = 1;
        
        if(holdTime == 0) {
          holdTime = currMillis-prevMillis-diskChangeInterval*currDiskCount;
        }     

        // number
        if(holdTime > diskNumberInterval) {
          addMsg = currDiskCount == 10 ? 0 : currDiskCount;
          curOffset = 0;

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
            // backspace
            if(currDiskCount == 10 && currDiskTimes > 1) {
              msg = msg.substring(0, msg.length()-2);
              
              addMsg = " ";
              curOffset = 1;
              newChar = true;

              printMsg(addMsg, newChar, curOffset);
              
              msg = msg.substring(0, msg.length()-1);
              addMsg = "";
              curOffset = 0;
              newChar = true;

              // scroll 2 times right
              if(msg.length() == 14) {
                lcd.scrollDisplayRight();
              }else if(msg.length() >= 15) {
                lcd.scrollDisplayRight();
                lcd.scrollDisplayRight();
                lcd.scrollDisplayRight();
              }
            }else{
              addMsg = getLetter(currDiskCount, currDiskTimes);
              curOffset = 0;
              newChar = false;
            }

            inputMillis = 0;
            prevMillis = 0;
            currDiskCount = 0;
            saveDiskCount = 0;
            prevDiskCount = 0;
            currDiskTimes = 0;
            holdTime = 0;
          }else{            
            // same number next time
            if(prevMillis != 0 && (prevDiskCount == 0 || prevDiskCount == currDiskCount)) {
              currDiskTimes++;

              inputMillis = currMillis;
              prevMillis = 0;

              addMsg = getLetter(currDiskCount, currDiskTimes);
              newChar = currDiskTimes == 1 ? true : false;
              curOffset = 1;
            // another number
            }else if(prevMillis != 0 && prevDiskCount != 0 && prevDiskCount != currDiskCount) {  
              currDiskTimes = 1;

              inputMillis = currMillis;              
              prevMillis = 0;

              addMsg = getLetter(currDiskCount, currDiskTimes);
              newChar = false;
              curOffset = 0;
            }

            prevDiskCount = currDiskCount;
            currDiskCount = 0;
          }
        }
        
        if(addMsg != "" || msg != "") {
          currMsgState = 1;
        }else if(msg == "") {
          currMsgState = 0;
        }
        
        printMsg(addMsg, newChar, curOffset);
      }
    }
  }
}

void printMsg(String add, boolean newChar, int curOffset) {
  if(!newChar) {
    msg[msg.length()-1] = add[0];
  }else{
    msg += add;
  }

  int curPos = msg.length()-curOffset;
  
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
  if(newChar && msg.length() > 15 && add.length() > 0) {
    for(int i = 1; i <= add.length(); i++) {
      lcd.scrollDisplayLeft();
    }
  }
  
  lcd.setCursor(curPos, 1);
  lcd.cursor();  
  lcd.blink();
}

String getLetter(int currDiskCount, int currDiskTimes) {
  unsigned int charsCount = 0;
  for(int i = 0; i <= 4; i++) {
    if(keyCodes[currDiskCount-1][i]) {
      charsCount++;
    }
  }
  
  // get letter to print            
  String addMsg = keyCodes[currDiskCount-1][(currDiskTimes-1)%charsCount];
  return addMsg;
}

