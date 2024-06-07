{
----------------------------------------------------------------------------------------------------
    Filename:       VEML7700-Demo.spin
    Description:    Demo of the VEML7700 driver
    Author:         Jesse Burt
    Started:        Jan 25, 2023
    Updated:        Jun 7, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment the next two lines to use the bytecode-based I2C engine in the driver.
'#define VEML7700_I2C_BC
'#pragma exportdef(VEML7700_I2C_BC)


CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.light.veml7700" | SCL=28, SDA=29, I2C_FREQ=400_000


PUB main()

    setup()

    repeat
        ser.pos_xy(0, 3)
        ser.printf1(@"ALS: %4.4x\n\r", sensor.als_data())
        ser.printf1(@"White: %4.4x", sensor.white_data())


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"VEML7700 driver started")
    else
        ser.strln(@"VEML7700 driver failed to start - halting")
        repeat

    sensor.powered(true)


DAT
{
Copyright 2024 Jesse Burt

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

