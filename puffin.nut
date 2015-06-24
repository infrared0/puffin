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

 
function blink() {
  
  local xval = -(x.read() - 32768)/6000;
  local yval = (y.read() - 32768)/6000;
  
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
 
  // schedule imp to wakeup in .5 seconds and do it again. 
  imp.wakeup(0.01, blink);
}
 
// start the loop
blink();