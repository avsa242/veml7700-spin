{
    --------------------------------------------
    Filename: VEML7700-Demo.spin
    Description: Demo of the VEML7700 driver
    Author: Jesse Burt
    Copyright (c) 2023
    Started Jan 25, 2023
    Updated Jan 26, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000

' --

OBJ

    cfg   : "boardcfg.flip"
    ser   : "com.serial.terminal.ansi"
    time  : "time"
    sensor: "sensor.light.veml7700"

PUB main{}

    setup{}

    repeat
        ser.pos_xy(0, 3)
        ser.hexs(sensor.als_data{}, 4)

PUB setup

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.strln(string("Serial terminal started"))

    if (sensor.startx(SCL_PIN, SDA_PIN, I2C_FREQ))
        ser.strln(string("VEML7700 driver started"))
    else
        ser.strln(string("VEML7700 driver failed to start - halting"))
        repeat

    sensor.powered(true)

DAT
{
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

