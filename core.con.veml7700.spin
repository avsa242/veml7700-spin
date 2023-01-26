{
    --------------------------------------------
    Filename: core.con.veml7700.spin
    Description: VEML7700-specific constants
    Author: Jesse Burt
    Copyright (c) 2023
    Started Jan 25, 2023
    Updated Jan 26, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

' I2C Configuration
    I2C_MAX_FREQ        = 400_000                   ' device max I2C bus freq
    SLAVE_ADDR          = $10 << 1                  ' 7-bit format slave address
    T_POR               = 1_000                         ' startup time (usecs)

    ADC_MAX             = 65535

' Register definitions
    ALS_CONF_0          = $00
    ALS_CONF_0_MASK     = $1BF3
        ALS_GAIN        = 11
        ALS_GAIN_BITS   = %11
        ALS_GAIN_MASK   = (ALS_GAIN_BITS << ALS_GAIN) & !ALS_CONF_0_MASK
        ALS_IT          = 6
        ALS_IT_BITS     = %1111
        ALS_IT_MASK     = (ALS_IT_BITS << ALS_IT) & !ALS_CONF_0_MASK
        ALS_PERS        = 4
        ALS_PERS_BITS   = %11
        ALS_PERS_MASK   = (ALS_PERS_BITS << ALS_PERS) & !ALS_CONF_0_MASK
        ALS_INT_EN      = 1
        ALS_INT_EN_MASK = (1 << ALS_INT_EN) & !ALS_CONF_0_MASK
        ALS_SD          = 0
        ALS_SD_MASK     = 1 & !ALS_CONF_0_MASK

    ALS_WH              = $01

    ALS_WL              = $02

    PWR_SAVING          = $03
    PWR_SAVING_MASK     = $0007
        PSM             = 1
        PSM_BITS        = %11
        PSM_MASK        = (PSM_BITS << PSM) & !PWR_SAVING_MASK
        PSM_EN          = 0
        PSM_EN_MASK     = 1 & !PWR_SAVING_MASK

    ALS                 = $04

    WHITE               = $05

    ALS_INT             = $06
    ALS_INT_MASK        = $C000
        INT_TH_LOW      = 15
        INT_TH_HI       = 14


PUB null{}
' This is not a top-level object

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

