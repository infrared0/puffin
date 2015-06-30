// wifi disconnect version with powersave


//Device will stay active if disconnects unexpectedly
//For more complicated response, write function and use server.onunexpecteddisconnect(function)

server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 30);


//Wifi disconnect policy: disconnect immediately
//Nothing logged because that would trigger a connect

server.disconnect();


//Disable blinkup (probably not necessary)

//imp.enableblinkup(false);


//Setting Pins

//wakeup from deep sleep pin (optional callback not implemented):
hardware.pin1.configure(DIGITAL_IN_WAKEUP);

//remember to implement a pulldown for the wakeup pin!
//mouse movement or puff triggered wakeup

uart <- hardware.uart57;
uart.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);

pressure <- hardware.pin2;

pressure.configure(ANALOG_IN);

x <- hardware.pin9;
y <- hardware.pin8;

x.configure(ANALOG_IN);
y.configure(ANALOG_IN);
 
// 1 is puff, 0 is sip
press <- 0;
duration <- 0;

drag <- 0; // dragging the left mouse button?

//TODO
// for deep sleep 
maxidle <- 60000; //default 10 min! add ability to change this
sleepcounter <- 0;

 
function mouse() {
  
  local xval = -(x.read() - 32768)/2000;
  local yval = (y.read() - 32768)/2000;
  
  //server.log("x: " + xval.tostring()
  //           + ", y: " +  yval.tostring());
  
  local oldpress = press;
  local pressure_reading = pressure.read();
  if (pressure_reading > 33500)
    press = 1;
  else if (pressure_reading < 32500)
    press = 0;
  else
    duration = 0;

  if (press != oldpress)
    duration = 0;
  else
    duration++;
    
  if (duration == 5) {
    //server.log(duration.tostring() + " times at press " + press.tostring())
    if (press == 0)
      server.log("Sip!");
    else {
      server.log("Puff!");
      drag = 0;
    }
    
    uart.write(0xFD);
    uart.write(0x00);
    uart.write(0x03);
    
    uart.write(2 - press);
    uart.write(0x00);
    uart.write(0x00);
  
    uart.write(0x00);
    uart.write(0x00);
    uart.write(0x00);
  } else if (duration == 25) {
    //server.log(duration.tostring() + " times at press " + press.tostring())
    if (press == 0)
      server.log("Long Sip!");
    else {
      server.log("Long Puff!");
      drag = 1;
    }
  } else {
      uart.write(0xFD);
      uart.write(0x00);
      uart.write(0x03);
      
      uart.write(drag);
      uart.write(xval);
      uart.write(yval);
      
      uart.write(0x00);
      uart.write(0x00);
      uart.write(0x00);
  }

//TODO
//if no movement or sip puff{
//sleepcounter++;
//}
 
// if not idle too long, schedule imp to wakeup in .01 sec
//if sleepcounter <= maxidle {
  imp.wakeup(0.01, mouse);
//}
//else {
//imp.onidle(function() { imp.deepsleepfor(2419198) });
//}


//TODO
// sleep code to be tested:
// fall asleep when idle for 10 (variable number?) min
// meaning no mouse motion or sip or puff
// then wake on trigger 
// every 60000 wakeups with no change, fall asleep 

}
 
// start the loop
imp.onidle(mouse);
