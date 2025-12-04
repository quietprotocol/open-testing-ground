# OpenMANET-testing-ground

## GPS

### Goal

Get Seeed board GPS going

### What we use

**OpenMANET**
[https://github.com/OpenMANET/openwrt](https://github.com/OpenMANET/openwrt)
[https://openmanet.github.io/docs/](https://openmanet.github.io/docs/)

**WM1302**
[https://www.seeedstudio.com/WM1302-Pi-Hat-p-4897.html](https://www.seeedstudio.com/WM1302-Pi-Hat-p-4897.html)
[https://wiki.seeedstudio.com/WM1302_Pi_HAT/](https://wiki.seeedstudio.com/WM1302_Pi_HAT/)
[https://files.seeedstudio.com/products/113100022/WM1302%20Pi%20Hat%20v1.0.pdf](https://files.seeedstudio.com/products/113100022/WM1302%20Pi%20Hat%20v1.0.pdf)

**Quectel L76K GNSS module**
[https://www.waveshare.com/wiki/L76K_GPS_Module](https://www.waveshare.com/wiki/L76K_GPS_Module)
[https://wiki.seeedstudio.com/get_start_l76k_gnss/](https://wiki.seeedstudio.com/get_start_l76k_gnss/)

**Wio-WM6108 Wi-Fi HaLow mini-PCIe Module**
[https://www.seeedstudio.com/Wio-WM6180-Wi-Fi-HaLow-mini-PCIe-Module-p-6394.html](https://www.seeedstudio.com/Wio-WM6180-Wi-Fi-HaLow-mini-PCIe-Module-p-6394.html)
[https://wiki.seeedstudio.com/getting_started_with_wifi_halow_mini_pcie_module/](https://wiki.seeedstudio.com/getting_started_with_wifi_halow_mini_pcie_module/)

**GPS Antenna**
[https://www.aliexpress.com/item/1005006022171372.html](https://www.aliexpress.com/item/1005006022171372.html)

### GPS Antenna

**Antenna Parameters**

| Item                         | Value                              |
|------------------------------|-------------------------------------|
| Frequency Bands              | GPS: L1 / L2<br>BDS: B1 / B2 / B3<br>GLONASS: G1 / G2<br>GALILEO: E1 / E5B |
| Gain                         | ≤ 3.0 dBi                           |
| Antenna Axial Ratio          | ≤ 3.0 dB                            |
| Horizontal Coverage Angle    | 360°                                |
| Standing Wave Ratio (VSWR)   | ≤ 1.5                               |
| Phase Center Error           | ±2 mm                               |
| Polarization                 | Right-hand circular polarization    |
| Port Impedance               | 50 Ω                                |

**Electrical Parameters**

| Item                        | Value                |
|-----------------------------|----------------------|
| LNA Gain                    | 35 ± 3 dB            |
| Noise Figure                | ≤ 1.8 dB             |
| Output Standing Wave Ratio  | ≤ 2.0                |
| In-band Flatness            | ±2 dB                |
| Operating Voltage           | 3.0 – 18 V           |
| Operating Current           | ≤ 50 mA              |
| Differential Delay          | ≤ ns                 |

**Structural Characteristics**

| Item         | Value      |
|--------------|------------|
| Connector     | SMA-J     |
| Antenna Size  | 28 × 57 mm |
| Weight        | 20 g       |

**Working Environment**

| Item                  | Value              |
|-----------------------|--------------------|
| Operating Temperature | -40°C to +70°C     |
| Storage Temperature   | -55°C to +85°C     |
| Waterproof Rating     | IP68               |



### Useful Commands

**GPSD Control:**
```bash
/etc/init.d/gpsd stop
/etc/init.d/gpsd start
/etc/init.d/gpsd restart
/etc/init.d/gpsd status
```

**Read GPS Data:**
```bash
# Direct read from serial port
cat /dev/ttyAMA0

# Via GPSD
gpspipe -r          # Raw NMEA output
gpspipe -w          # Watch mode
gpsmon              # Monitor with GUI
```

**Check GPSD Configuration:**
```bash
cat /etc/config/gpsd
ps | grep gpsd
```

**UART Device Detection:**
```bash
# List available UART devices
ls -l /dev/ttyAMA* /dev/ttyS*

# Check kernel messages
dmesg | grep tty
dmesg | grep pl011

# Check device tree aliases
cat /proc/device-tree/aliases/serial0
```

### WM1302 Pi Hat GPIO Mapping

| No. | Raspberry Pi GPIO      | WM1302 Pi Hat Pin Name | IO Type | Function |
|-----|-------------------------|--------------------------|---------|----------|
| 1   | 3V3 power               | NC                       |         |          |
| 2   | 5V power                | 5V                       | Power   |          |
| 3   | GPIO 2 (SDA)            | I2C_SDA                  | DIO     | I2C Data for Temperature Sensor & Authentication chip |
| 4   | 5V power                | 5V                       | Power   |          |
| 5   | GPIO 3 (SCL)            | I2C_SCL                  | DI      | I2C Clock for Temperature Sensor & Authentication chip |
| 6   | Ground                  | GND                      | Ground  |          |
| 7   | GPIO 4 (GPCLK0)         | NC                       |         |          |
| 8   | GPIO 14 (TXD)           | GPS_RXD                  | DI      | GPS UART RXD |
| 9   | Ground                  | GND                      | Ground  |          |
| 10  | GPIO 15 (RXD)           | GPS_TXD                  | DO      | GPS UART TXD |
| 11  | GPIO 17                 | RESET                    | DI      | Reset Pin — Active High (SPI version), Active Low (USB version) |
| 12  | GPIO 18 (PCM_CLK)       | SX1262_BUSY              | DO      | SX1262 BUSY Pin |
| 13  | GPIO 27                 | NC                       |         |          |
| 14  | Ground                  | GND                      | Ground  |          |
| 15  | GPIO 22                 | NC                       |         |          |
| 16  | GPIO 23                 | SX1262_IO1               | DIO     | SX1262 DIO1 Pin |
| 17  | 3V3 power               | NC                       |         |          |
| 18  | GPIO 24                 | SX1262_IO2               | DO      | SX1262 DIO2 Pin |
| 19  | GPIO 10 (MOSI)          | SPI_MOSI                 | DI      | SPI MOSI |
| 20  | Ground                  | GND                      | Ground  |          |
| 21  | GPIO 9 (MISO)           | SPI_MISO                 | DO      | SPI MISO |
| 22  | GPIO 25                 | GPS_RST                  | DI      | Active high at least 10 ms to reset GPS module |
| 23  | GPIO 11 (SCLK)          | SPI_SCK                  | DI      | SPI Clock |
| 24  | GPIO 8 (CE0)            | SX1302_CSN               | DI      | SX1302 Chip select |
| 25  | Ground                  | GND                      | Ground  |          |
| 26  | GPIO 7 (CE1)            | NC                       |         |          |
| 27  | GPIO 0 (ID_SD)          | ID_SD                    | DIO     | I2C Data for EEPROM |
| 28  | GPIO 1 (ID_SC)          | ID_SC                    | DI      | I2C Clock for EEPROM |
| 29  | GPIO 5                  | SX1262_RST               | DI      | SX1262 Reset Pin |
| 30  | Ground                  | GND                      | Ground  |          |
| 31  | GPIO 6                  | SX1262_CSN               | DI      | SX1262 Chip Select |
| 32  | GPIO 12 (PWM0)          | GPS_WAKE_UP              | DI      | Active high for GPS module enter Standby mode |
| 33  | GPIO 13 (PWM1)          | NC                       |         |          |
| 34  | Ground                  | GND                      | Ground  |          |
| 35  | GPIO 19 (PCM_FS)        | NC                       |         |          |
| 36  | GPIO 16                 | NC                       |         |          |
| 37  | GPIO 26                 | NC                       |         |          |
| 38  | GPIO 20 (PCM_DIN)       | NC                       |         |          |
| 39  | Ground                  | GND                      | Ground  |          |
| 40  | GPIO 21 (PCM_DOUT)      | NC                       |         |          |

**Key GPS-Related GPIO Pins:**

- **GPIO 14 (TXD)** → GPS_RXD (GPS UART Receive)
- **GPIO 15 (RXD)** → GPS_TXD (GPS UART Transmit)
- **GPIO 25** → GPS_RST (Active high, at least 10 ms to reset GPS module)
- **GPIO 12 (PWM0)** → GPS_WAKE_UP (⚠️ **Active high = Standby mode**, Active low = Active mode)

**Important Finding**: GPIO 12 (GPS_WAKE_UP) description says "Active high for GPS module enter Standby mode" - this means:

- **HIGH (1) = GPS in Standby mode** (not active)
- **LOW (0) = GPS Active mode** (should be active)

**GPS UART Mapping**: GPIO 14/15 are the primary UART pins, which typically map to `/dev/ttyAMA0` on Raspberry Pi, not `/dev/ttyS0`. This could explain why GPSD configured for `/dev/ttyS0` isn't working.

**Note on `/dev/serial0`**: On Raspberry Pi OS (Raspbian), `/dev/serial0` is a symlink that points to the correct UART device. However, on OpenWrt (which this device uses), `/dev/serial0` does not exist, so we must use `/dev/ttyAMA0` directly. See [Raspberry Pi forum discussion](https://forums.raspberrypi.com/viewtopic.php?t=355288) for context on Pi OS behavior.

### Troubleshooting - GPS Not Working

**Initial System Check Commands:**

```bash
# Connect to device (replace with your device IP)
ssh root@<device-ip>

# Check system info
uname -a

# Check UART devices
ls -l /dev/ttyAMA* /dev/ttyS*
dmesg | grep tty
dmesg | grep pl011

# Check GPSD configuration
cat /etc/config/gpsd

# Check GPSD status
/etc/init.d/gpsd status
ps | grep gpsd

# Check serial port settings
stty -F /dev/ttyAMA0
```

**Current Status:**

- GPS is on `/dev/ttyAMA0` at 9600 baud (UART0, GPIO14/15)
- GPSD is configured for `/dev/ttyS0` in `/etc/config/gpsd`, but **actually runs on `/dev/ttyAMA0`**
- **✅ VERIFIED: GPSD does NOT lock `/dev/ttyAMA0`** - you CAN read directly from the port while GPSD is running
- GPS initialization script runs on boot via `/etc/rc.local`
- GPS outputs clean NMEA sentences once initialized

**Verified Test Results (2025-11-23):**

- ✅ GPS outputs valid NMEA sentences (`$GNGGA`, `$GNRMC`, etc.) with coordinates
- ✅ GPS outputs NMEA data **WITH GPSD running**
- ✅ GPS outputs NMEA data **WITHOUT GPSD running**
- ✅ GPS outputs continuously once initialized
- ✅ No console noise - clean NMEA sentences
- ✅ GPSD does NOT lock the port - direct reads work fine
- ✅ GPS works regardless of GPSD. GPSD is optional.

**GPSD Behavior:**
- GPSD runs on `/dev/ttyAMA0` (despite config saying `/dev/ttyS0`)
- GPSD process: `gpsd -n /dev/ttyAMA0`
- **You can read directly from `/dev/ttyAMA0` while GPSD is running** - no need to stop GPSD
- **Alternative**: Use GPSD's interface (`gpspipe`, `gpsmon`) to read GPS data via GPSD socket (port 2947)


**GPIO Pins for WM1302 GPS:**

- GPS_RST: GPIO 25 (reset pin) - Active high, at least 10 ms pulse to reset
- GPS_WAKE_UP: GPIO 12 (wake up pin) - ⚠️ **Active high = Standby, Active low = Active**

**GPIO Control Commands (CORRECTED):**

```bash
# Export GPIO pins
echo 25 > /sys/class/gpio/export
echo 12 > /sys/class/gpio/export

# Set as output
echo out > /sys/class/gpio/gpio25/direction
echo out > /sys/class/gpio/gpio12/direction

# Reset GPS (ensure LOW, pulse HIGH for at least 10ms, return to LOW)
echo 0 > /sys/class/gpio/gpio25/value
sleep 0.01
echo 1 > /sys/class/gpio/gpio25/value
sleep 0.02
echo 0 > /sys/class/gpio/gpio25/value

# Wake GPS (set LOW to activate - HIGH puts it in standby!)
echo 0 > /sys/class/gpio/gpio12/value
```

**Note**: GPIO 12 must be set to **LOW (0)** to activate GPS (HIGH = standby). The initialization script correctly sets this.

**Findings:**

- GPS outputs NMEA sentences on `/dev/ttyAMA0` at 9600 baud
- **✅ VERIFIED: GPSD does NOT lock `/dev/ttyAMA0`** - you can read directly from the port while GPSD is running
- GPS data appears when: GPIO initialized → GPS outputs continuously
- GPS outputs clean NMEA sentences once initialized (no console noise)
- Console is configured for ttyAMA0 but doesn't interfere (only GPS data visible)
- GPSD runs on `/dev/ttyAMA0` despite being configured for `/dev/ttyS0` in `/etc/config/gpsd`
- GPS works with or without GPSD - GPSD is optional

**GPS Requirements:**

1. GPS antenna connected to the "ANT" U.FL connector on the Pi Hat
2. Pi Hat properly seated and making good contact
3. Device outdoors with clear sky view (for satellite acquisition)

**Possible Issues:**

1. **Wrong UART device** - GPS uses GPIO 14/15 which map to `/dev/ttyAMA0` (primary UART), but GPSD is configured for `/dev/ttyS0`
2. GPS module may need different initialization sequence
3. Hardware connection issue (verify UART wiring)
4. GPS module may be faulty
5. GPS needs time to acquire satellites (cold start can take 30 seconds to several minutes)
6. Device must be outdoors with clear sky view for satellite acquisition

**GPS Control:**

To turn GPS OFF (standby mode - saves power):
```bash
echo 12 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio12/direction
echo 1 > /sys/class/gpio/gpio12/value  # HIGH = standby
```

To turn GPS ON (active mode):
```bash
echo 0 > /sys/class/gpio/gpio12/value  # LOW = active
```

To check GPS status:
```bash
cat /sys/class/gpio/gpio12/value  # 0=ON, 1=OFF
```


**GPS Status: ✅ WORKING**

- Outputs clean NMEA sentences on `/dev/ttyAMA0` at 9600 baud
- Works with or without GPSD
- Requires GPIO initialization (done on boot via `init_gps.sh`)
- No special requirements - just read from `/dev/ttyAMA0`

**Recommendations for ATAK COTS Program:**

**RECOMMENDED: Read directly from ttyAMA0**
- GPS works with or without GPSD
- Simple: Open `/dev/ttyAMA0` as file descriptor, read NMEA sentences
- Parse `$GNGGA` and `$GNRMC` sentences for coordinates
- No need to stop GPSD - it doesn't interfere

**Alternative: Use GPSD interface**
- Keep GPSD running
- Use `gpspipe -r` or connect to GPSD socket (port 2947)
- More complex but standard approach if you want GPSD's features

**Example NMEA Output:**
```
$GNGGA,170456.000,5529.87936,N,01314.33415,E,1,10,1.4,-28.1,M,35.4,M,,*5C
```

**Next Steps:**

1. **Use /dev/ttyAMA0** - GPIO 14/15 map to primary UART (ttyAMA0)
2. **Initialize GPIO pins** - GPIO 25 (reset) and GPIO 12 (wake) must be configured (script does this)
3. **GPS works with or without GPSD** - You can read directly from `/dev/ttyAMA0` even while GPSD is running
4. **Wait for cold start** - GPS needs 30 seconds to several minutes to acquire satellites
5. Verify GPS antenna connection to correct U.FL connector
6. Ensure device is outdoors with clear sky view
