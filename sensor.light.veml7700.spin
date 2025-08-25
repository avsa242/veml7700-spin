{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.light.veml7700.spin
    Description:    Driver for the VEML7700 ALS/Lux sensor
    Author:         Jesse Burt
    Started:        Jan 25, 2023
    Updated:        Aug 25, 2025
    Copyright (c) 2025 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O configuration - these can be overridden by the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000



    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core.I2C_MAX_FREQ

    ADC_MAX         = core.ADC_MAX


VAR

    long _lux_res, _lux_max
    long _als_gain, _als_itime


OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef VEML7700_I2C_BC
    i2c:    "com.i2c.nocog"                     ' BC I2C engine
#else
    i2c:    "com.i2c"                           ' PASM I2C engine
#endif
    core:   "core.con.veml7700.spin"            ' hw-specific low-level const's
    time:   "time"                              ' basic timing functions


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core.T_POR)             ' wait for device startup
            if ( present() )                    ' test device bus presence
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE


PUB stop()
' Stop the driver
    i2c.deinit()


PUB defaults()
' Set factory defaults
    als_gain(1_000)                             ' 1x gain
    als_integr_time(25)                         ' 25ms integration time
    powered(false)


PUB preset_active()
' Like default settings, but enable sensor power
    defaults()
    powered(true)


PUB present(): ack | tmp
' Check for device presence
    i2c.start()
    tmp := i2c.write(SLAVE_WR)
    i2c.stop()
    return (tmp == i2c.ACK)


PUB als_data(): d
' Read Ambient Light Sensor data
'   Returns:
    return readreg(core.ALS)


PUB als_gain(g): c
' Set sensor gain factor
'   Valid values: 1_000 (1x), 2_000 (2x), 125 (1/8), 250 (1/4)
'   Any other value polls the chip and returns the current setting
    c := readreg(core.ALS_CONF_0)
    case g
        1_000, 2_000, 125, 250:
            _als_gain := g
            g := lookdownz(g: 1_000, 2_000, 125, 250) << core.ALS_GAIN
            g := ((c & core.ALS_GAIN_MASK) | g)
            writereg(core.ALS_CONF_0, g)
        other:
            c := ((c >> core.ALS_GAIN) & core.ALS_GAIN_BITS)
            return lookupz(c: 1_000, 2_000, 125, 250)

    update_lux_res()


PUB als_integr_time(t): c
' Set sensor integration time, in milliseconds
'   Valid values: 25, 50, 100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    c := readreg(core.ALS_CONF_0)
    case t
        100, 200, 400, 800:
            _als_itime := t
            t := lookdownz(t: 100, 200, 400, 800) << core.ALS_IT
        25:
            _als_itime := t
            t := %1100 << core.ALS_IT
        50:
            _als_itime := t
            t := %1000 << core.ALS_IT
        other:
            c := (c >> core.ALS_IT) & core.ALS_IT_BITS
            if (c < %1000)
                return lookupz(c: 100, 200, 400, 800)
            elseif (c == %1000)
                return 50
            elseif (c == %1100)
                return 25

    t := ((c & core.ALS_IT_MASK) | t)
    writereg(core.ALS_CONF_0, t)
    update_lux_res()


PUB int_duration(d): c
' Set number of consecutive measurements outside set threshold necessary to generate an interrupt
'   Valid values: 1, 2, 4, 8
'   Any other value polls the chip and returns the current setting
    c := readreg(core.ALS_CONF_0)
    case d
        1, 2, 4, 8:
            d := lookdownz(d: 1, 2, 4, 8) << core.ALS_PERS
            d := ((c & core.ALS_PERS_MASK) | d)
            writereg(core.ALS_CONF_0, d)
        other:
            c := ((c >> core.ALS_PERS) & core.ALS_PERS_BITS)
            return lookupz(c: 1, 2, 4, 8)


PUB int_ena(s): c
' Enable interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    c := readreg(core.ALS_CONF_0)
    case ||(s)
        0, 1:
            s := ( (c & core.ALS_SD_MASK) | ((s & 1) << core.ALS_INT_EN) )
            writereg(core.ALS_CONF_0, s)
        other:
            return ( ( (c >> core.ALS_INT_EN) & 1) == 1)


PUB int_hi_thresh(): t
' Get currently set high interrupt threshold
    return readreg(core.ALS_WH)


PUB int_lo_thresh(): t
' Get currently set low interrupt threshold
    return readreg(core.ALS_WL)


PUB int_set_hi_thresh(t)
' Set interrupt high threshold
'   Valid values: 0..65535 (clamped to range)
    t := 0 #> t <# 65535
    writereg(core.ALS_WH, t)


PUB int_set_lo_thresh(t)
' Set interrupt low threshold
'   Valid values: 0..65535 (clamped to range)
    t := 0 #> t <# 65535
    writereg(core.ALS_WL, t)


PUB interrupt(): s
' Read interrupt flags
'   Bits
'       15: low threshold exceeded
'       14: high threshold exceeded
    return readreg(core.ALS_INT)


PUB lux(): l
' Return lux from live measurement
    return ( als_data() * _lux_res )


PUB lux_maximum(): l
' Get the maximum possible lux reading, given the current gain and integration time settings
    return _lux_max


PUB power_save_ena(s): c
' Enable power saving mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    c := readreg(core.PWR_SAVING)
    case ||(s)
        0, 1:
            s := ((c & core.PSM_EN_MASK) | s)
            writereg(core.PSM_EN_MASK, s)
        other:
            return ((c & 1) == 1)


PUB power_save_mode(m): c
' Set power saving mode
'   Valid values: 1..4
'   Any other value polls the chip and returns the current setting
'   mode        als_integr_time()       refresh time (ms)   current (uA)    resolution (lx/bit)
'   ----        -----------------       -----------------   ------------    -------------------
'   1           100                     600                 8               0.0288
'   2           100                     1100                5               0.0288
'   3           100                     2100                3               0.0288
'   4           100                     4100                2               0.0288
'   1           200                     700                 13              0.0144
'   2           200                     1200                8               0.0144
'   3           200                     2200                5               0.0144
'   4           200                     4200                3               0.0144
'   1           400                     900                 20              0.0072
'   2           400                     1400                13              0.0072
'   3           400                     2400                8               0.0072
'   4           400                     4400                5               0.0072
'   1           800                     1300                28              0.0036
'   2           800                     1800                20              0.0036
'   3           800                     2800                13              0.0036
'   4           800                     4800                8               0.0036
    c := readreg(core.PWR_SAVING)
    case m
        1..4:
            m := ((c & core.PSM_MASK) | (m-1))
            writereg(core.PWR_SAVING, m)
        other:
            return ((c >> core.PSM) & core.PSM_BITS)


PUB powered(s): c
' Enable sensor power
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    c := readreg(core.ALS_CONF_0)
    case ||(s)
        0, 1:
            { ALS_SD is worded as a 'shut down' field, so 0 = power on, 1 = power off;
                flip the bit here before writing it back to the sensor }
            s := ((c & core.ALS_SD_MASK) | ( (s ^ 1) & 1))
            writereg(core.ALS_CONF_0, s)
        other:
            return ((c & 1) == 1)


PUB update_lux_res()
' Update lux resolution (lux per ADC LSB)
    case _als_gain
        2_000:
            _lux_res := 2_8800 / _als_itime
        1_000:
            _lux_res := 5_7600 / _als_itime
        0_250:
            _lux_res := 23_0400 / _als_itime
        0_125:
            _lux_res := 46_0800 / _als_itime

    _lux_max := (_lux_res * ADC_MAX)


PUB white_data(): d
' Read ambient light sensor data - wide spectral response
'   Returns: ADC counts
    return readreg(core.WHITE)


PRI readreg(reg_nr): v | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    v := 0
    case reg_nr                                 ' validate register num
        $00..$06:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.start()
            i2c.wr_byte(SLAVE_RD)
            i2c.rdblock_lsbf(@v, 2, i2c.NAK)
            i2c.stop()
        other:                                  ' invalid reg_nr
            return


PRI writereg(reg_nr, val) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        $00..$02:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(@val, 2)
            i2c.stop()
        other:
            return


DAT
{
Copyright 2025 Jesse Burt

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

