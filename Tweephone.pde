#include <LiquidCrystal.h>
#include <LiquidCrystalRus.h>
LiquidCrystalRus lcd(12, 11, 5, 4, 3, 2);

const unsigned int  diskState = 7;
const unsigned int  diskCounter = 8;
const unsigned int  diskSend = 9;

const unsigned int  diskChangeInterval = 100;
const unsigned long diskNumberInterval = 1500;
const unsigned long diskInputInterval = 1000;

const String msgOn           = "Pick up to type ";
const String msgStart        = "Turn the dial   ";
const String msgSend         = "Hang up to send ";
const String msgError        = "Too long        ";
const String msgLoading      = "Loading...      ";
const char*  keyCodes[][9] = {
  {".", ",", "!", "?", "@", ":", "/", "#", "'"},
  {"a", "b", "c", "A", "B", "C"},
  {"d", "e", "f", "D", "E", "F"},
  {"g", "h", "i", "G", "H", "I"},
  {"j", "k", "l", "J", "K", "L"},
  {"m", "n", "o", "M", "N", "O"},
  {"p", "q", "r", "s", "P", "Q", "R", "S"},
  {"t", "u", "v", "T", "U", "V"},
  {"w", "x", "y", "z", "W", "X", "Y", "Z"},
  {" ", " "}
};

unsigned int  currDiskCount = 0;
unsigned int  prevDiskCount = 0;
unsigned int  saveDiskCount = 0;
unsigned int  currDiskTimes = 0;
unsigned int  currMsgState = 0;
unsigned int  prevDiskCountState = HIGH;
unsigned int  prevDiskSendState = LOW;
unsigned long holdTime = 0;
unsigned long prevMillis = 0;
unsigned long inputMillis = 0;

String msg = "";

void setup() {
  lcd.begin(16, 2);  
  printMsg("", true, 0);

  pinMode(diskState, INPUT);
  pinMode(diskCounter, INPUT);
  pinMode(diskSend, INPUT);

  Serial.begin(9600);
}

void loop() {
  unsigned int  currDiskState = digitalRead(diskState);
  unsigned int  currDiskCountState = digitalRead(diskCounter);
  unsigned int  currDiskSendState = digitalRead(diskSend);
  unsigned long currMillis = millis();

  // send is pressed
  if(currDiskSendState != prevDiskSendState) {
    if(msg.length() > 0) {
      sendMsg();
    }else if(currDiskSendState == HIGH){
      lcd.clear();
      lcd.noCursor();
      lcd.setCursor(0, 0);
      lcd.print(msgOn);
    }else{
      printMsg("", true, 0);
    }
    
    prevDiskSendState = currDiskSendState;
  // disk is moving
  }else if(currDiskState == HIGH) {    
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
        printMsg("", true, 0);
      }else{
        if(holdTime == 0) {
          holdTime = currMillis-prevMillis-diskChangeInterval*currDiskCount;
        }     

        // number
        if(holdTime > diskNumberInterval) {
          // let's print number
          printMsg(currDiskCount == 10 ? 0 : currDiskCount, true, 0);

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
              // remove two symbols
              msg = msg.substring(0, msg.length()-2);
              
              // print with space
              printMsg(" ", true, 1);
              
              // remove space
              msg = msg.substring(0, msg.length()-1);

              // print without space
              printMsg("", true, 0);

              // scroll display right for deleted symbols
              if(msg.length() == 14) {
                lcd.scrollDisplayRight();
              }else if(msg.length() >= 15) {
                for(int i = 0; i < 3; i++) {
                  lcd.scrollDisplayRight();
                }
              }
            }else{
              // let's print letter
              printMsg(getLetter(currDiskCount, currDiskTimes), false, 0);
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

              // let's print!
              printMsg(getLetter(currDiskCount, currDiskTimes), currDiskTimes == 1 ? true : false, 1);

            // another number
            }else if(prevMillis != 0 && prevDiskCount != 0 && prevDiskCount != currDiskCount) {
              currDiskTimes = 1;

              inputMillis = currMillis;
              prevMillis = 0;

              // let's print!
              printMsg(getLetter(currDiskCount, currDiskTimes), false, 1);
            }

            prevDiskCount = currDiskCount;
            currDiskCount = 0;
            delay(100);
          }
        }        
      }
    }
  }
}

void sendMsg() {
  lcd.clear();
  lcd.noCursor();
  lcd.setCursor(0, 0);
  lcd.print(msgLoading);
  
  // there will be sending to twitter
  Serial.println(msg);
  delay(1000);
  
  msg = "";
  lcd.clear();
  lcd.noCursor();
  lcd.setCursor(0, 0);
  lcd.print(msgOn);
}

void printMsg(String add, boolean newChar, int curOffset) {
  if(!newChar) {
    msg[msg.length()-1] = add[0];
  }else{
    msg += add;
  }

  // get cursor position
  int curPos = msg.length()-curOffset;

  // get current state
  if(msg.length() >= 140) {
    currMsgState = 2;
  }else if(msg.length() > 0) {
    currMsgState = 1;
  }else{
    currMsgState = 0;
  }
  
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
  for(int i = 0; i <= 8; i++) {
    if(keyCodes[currDiskCount-1][i]) {
      charsCount++;
    }
  }
  
  // get letter to print
  Serial.println((currDiskTimes-1)%charsCount);
  String addMsg = keyCodes[currDiskCount-1][(currDiskTimes-1)%charsCount];
  return addMsg;
}

