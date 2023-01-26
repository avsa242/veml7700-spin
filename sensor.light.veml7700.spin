{
    --------------------------------------------
    Filename: sensor.light.veml7700.spin
    Description: VEML7700 ALS/Lux sensor driver
    Author: Jesse Burt
    Copyright (c) 2023
    Started Jan 25, 2023
    Updated Jan 26, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef VEML7700_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.veml7700.spin"              ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if (lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31))
    if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if (present{})          ' test device bus presence
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}

PUB defaults{}
' Set factory defaults
    als_gain(1_000)                             ' 1x gain
    als_integr_time(25)                         ' 25ms integration time
    powered(false)

PUB preset_active{}
' Like default settings, but enable sensor power
    defaults{}
    powered(true)

PUB present{}: ack | tmp
' Check for device presence
    i2c.start{}
    tmp := i2c.write(SLAVE_WR)
    i2c.stop{}
    return (tmp == i2c.ACK)

PUB als_data{}: als_adc
' Read Ambient Light Sensor data
'   Returns:
    readreg(core#ALS, 2, @als_adc)

PUB als_gain(gain): curr_gain
' Set sensor gain factor
'   Valid values: 1_000 (1x), 2_000 (2x), 125 (1/8), 250 (1/4)
'   Any other value polls the chip and returns the current setting
    curr_gain := 0
    readreg(core#ALS_CONF_0, 2, @curr_gain)
    case gain
        1_000, 2_000, 125, 250:
            gain := lookdownz(gain: 1_000, 2_000, 125, 250) << core#ALS_GAIN
            gain := ((curr_gain & core#ALS_GAIN_MASK) | gain)
            writereg(core#ALS_CONF_0, 2, @gain)
        other:
            curr_gain := ((curr_gain >> core#ALS_GAIN) & core#ALS_GAIN_BITS)
            return lookupz(curr_gain: 1_000, 2_000, 125, 250)

PUB als_integr_time(itime): curr_itime
' Set sensor integration time, in milliseconds
'   Valid values: 25, 50, 100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    curr_itime := 0
    readreg(core#ALS_CONF_0, 2, @curr_itime)
    case itime
        100, 200, 400, 800:
            itime := lookdownz(itime: 100, 200, 400, 800) << core#ALS_IT
        25:
            itime := %1100 << core#ALS_IT
        50:
            itime := %1000 << core#ALS_IT
        other:
            curr_itime := (curr_itime >> core#ALS_IT) & core#ALS_IT_BITS
            if (curr_itime < %1000)
                return lookupz(curr_itime: 100, 200, 400, 800)
            elseif (curr_itime == %1000)
                return 50
            elseif (curr_itime == %1100)
                return 25

    itime := ((curr_itime & core#ALS_IT_MASK) | itime)
    writereg(core#ALS_CONF_0, 2, @itime)

PUB int_duration(dur): curr_dur
' Set number of consecutive measurements outside set threshold necessary to generate an interrupt
'   Valid values: 1, 2, 4, 8
'   Any other value polls the chip and returns the current setting
    curr_dur := 0
    readreg(core#ALS_CONF_0, 2, @curr_dur)
    case dur
        1, 2, 4, 8:
            dur := lookdownz(dur: 1, 2, 4, 8) << core#ALS_PERS
            dur := ((curr_dir & core#ALS_PERS_MASK) | dur)
            writereg(core#ALS_CONF_0, 2, @dur)
        other:
            curr_dur := ((curr_dir >> core#ALS_PERS) & core#ALS_PERS_BITS)
            return lookupz(curr_dur: 1, 2, 4, 8)

PUB int_ena(state): curr_state
' Enable interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#ALS_CONF_0, 2, @curr_state)
    case ||(state)
        0, 1:
            state := ( (curr_state & core#ALS_SD_MASK) | ((state & 1) << core#ALS_INT_EN) )
            writereg(core#ALS_CONF_0, 2, @state)
        other:
            return (((curr_state >> core#ALS_INT_EN) & 1) == 1)

PUB int_hi_thresh{}: thresh
' Get currently set high interrupt threshold
    thresh := 0
    readreg(core#ALS_WH, 2, @thresh)

PUB int_lo_thresh{}: thresh
' Get currently set low interrupt threshold
    thresh := 0
    readreg(core#ALS_WL, 2, @thresh)

PUB int_set_hi_thresh(thresh)
' Set interrupt high threshold
'   Valid values: 0..65535 (clamped to range)
    thresh := 0 #> thresh <# 65535
    writereg(core#ALS_WH, 2, @thresh)

PUB int_set_lo_thresh(thresh)
' Set interrupt low threshold
'   Valid values: 0..65535 (clamped to range)
    thresh := 0 #> thresh <# 65535
    writereg(core#ALS_WL, 2, @thresh)

PUB interrupt{}: int_src
' Read interrupt flags
'   Bits
'       15: low threshold exceeded
'       14: high threshold exceeded
    int_src := 0
    readreg(core#ALS_INT, 2, @int_src)

PUB power_save_ena(state): curr_state
' Enable power saving mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#PWR_SAVING, 2, @curr_state)
    case ||(state)
        0, 1:
            state := ((curr_state & core#PSM_EN_MASK) | state)
            writereg(core#PSM_EN_MASK, 2, @state)
        other:
            return ((curr_state & 1) == 1)

PUB power_save_mode(mode): curr_mode
' Set power saving mode
'   Valid values: 1..4
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#PWR_SAVING, 2, @curr_mode)
    case mode
        1..4:
            mode := ((curr_mode & core#PSM_MASK) | (mode-1))
            writereg(core#PWR_SAVING 2, @mode)
        other:
            return ((curr_mode >> core#PSM) & core#PSM_BITS)

PUB powered(state): curr_state
' Enable sensor power
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#ALS_CONF_0, 2, @curr_state)
    case ||(state)
        0, 1:
            { ALS_SD is worded as a 'shut down' field, so 0 = power on, 1 = power off;
                flip the bit here before writing it back to the sensor }
            state := ((curr_state & core#ALS_SD_MASK) | ( (state ^ 1) & 1))
            writereg(core#ALS_CONF_0, 2, @state)
        other:
            return ((curr_state & 1) == 1)

PUB white_data{}: white_adc
' Read ambient light sensor data - wide spectral response
'   Returns:
    white_adc := 0
    readreg(core#WHITE, 2, @white_adc)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        $00..$06:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.start{}
            i2c.wr_byte(SLAVE_RD)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:                                  ' invalid reg_nr
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        $00..$02:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return


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

