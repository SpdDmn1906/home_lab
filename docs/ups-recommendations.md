# UPS (Uninterruptible Power Supply) Recommendations

## Why You Need a UPS

### Critical Issues Without UPS:
1. **Data Corruption**: Sudden power loss can corrupt files, databases, and Docker volumes
2. **Boot Errors**: Power interruptions can cause filesystem corruption leading to boot failures
3. **Hardware Damage**: Sudden power loss can damage hard drives and SSDs
4. **Service Interruption**: Media server, Plex, and other services go offline
5. **Incomplete Transactions**: Downloads, backups, and file transfers interrupted

### Benefits of UPS:
- **Graceful Shutdown**: Allows system to shut down properly during power loss
- **Data Protection**: Prevents corruption from sudden power loss
- **Hardware Protection**: Protects against power surges and brownouts
- **Continuous Operation**: Keeps system running during short outages
- **Monitoring**: Provides power status and alerts

## Power Requirements Calculation

### Calculate Your Load:

**Components to Consider:**
1. **Desktop Media Server**: ~150-300W (depends on components)
2. **Monitor** (if always on): ~30-50W
3. **NAS (Synology)**: ~20-50W
4. **External HDD**: ~10-20W
5. **Router/Modem**: ~10-20W
6. **Total Estimated**: ~250-450W

**Calculation Formula:**
```
Total Power (Watts) = Sum of all device power consumption
VA Rating Needed = Total Power × 1.5 (safety factor)
Runtime Needed = Desired shutdown time (typically 5-10 minutes)
```

**Example:**
- Total Power: 300W
- VA Rating Needed: 300W × 1.5 = 450VA minimum
- Recommended: 600-1000VA for 5-10 minute runtime

## UPS Recommendations

### Budget Option (<$150)

**APC Back-UPS 600VA (BE600M1)**
- Capacity: 600VA/330W
- Runtime: ~5-10 minutes at 300W load
- Features: 6 outlets (3 battery backup, 3 surge only)
- Software: PowerChute (basic)
- Price: ~$80-100
- **Best For**: Basic protection, single server

**CyberPower CP1500AVRLCD**
- Capacity: 1500VA/900W
- Runtime: ~5-10 minutes at 300W load
- Features: LCD display, 10 outlets, AVR
- Software: PowerPanel (better than basic)
- Price: ~$120-150
- **Best For**: Better runtime, more outlets

### Mid-Range Option ($150-300)

**APC Smart-UPS 1000VA (SMT1000)**
- Capacity: 1000VA/600W
- Runtime: ~10-15 minutes at 300W load
- Features: Pure sine wave, network management card compatible
- Software: PowerChute Business Edition
- Price: ~$200-250
- **Best For**: Better quality, longer runtime, network monitoring

**CyberPower OR1500LCDRM1U**
- Capacity: 1500VA/900W
- Runtime: ~10-15 minutes at 300W load
- Features: Rackmount, LCD, network management
- Software: PowerPanel Business
- Price: ~$200-250
- **Best For**: Rack installation, good runtime

### Professional Option ($300+)

**APC Smart-UPS 1500VA (SMT1500)**
- Capacity: 1500VA/980W
- Runtime: ~15-20 minutes at 300W load
- Features: Pure sine wave, extended runtime capable
- Software: PowerChute Business Edition
- Price: ~$350-400
- **Best For**: Longer runtime, professional setup

**Tripp Lite SMART1500LCD**
- Capacity: 1500VA/900W
- Runtime: ~15-20 minutes at 300W load
- Features: LCD, network management, AVR
- Software: PowerAlert
- Price: ~$300-350
- **Best For**: Good value, long runtime

## Features to Consider

### 1. Pure Sine Wave vs. Simulated Sine Wave

**Pure Sine Wave:**
- Better for sensitive electronics
- Recommended for PSUs with active PFC
- More expensive

**Simulated Sine Wave:**
- Adequate for most computers
- Less expensive
- May cause issues with some PSUs

**Recommendation**: Pure sine wave if budget allows, especially for media server with active PFC PSU.

### 2. Automatic Voltage Regulation (AVR)

**Benefits:**
- Corrects voltage without using battery
- Extends battery life
- Protects against brownouts

**Recommendation**: Highly recommended, especially in areas with unstable power.

### 3. Network Management

**Features:**
- Remote monitoring via network
- SNMP support
- Email/SMS alerts
- Integration with monitoring systems

**Recommendation**: Recommended for professional setup, allows integration with Prometheus/Grafana.

### 4. Runtime

**Considerations:**
- Need enough time for graceful shutdown (5-10 minutes minimum)
- Consider how long outages typically last in your area
- Can add external battery packs for extended runtime

**Recommendation**: 10+ minutes runtime at your expected load.

### 5. Software Integration

**Options:**
- **NUT (Network UPS Tools)**: Open source, works with most UPS brands
- **APC PowerChute**: APC-specific, feature-rich
- **CyberPower PowerPanel**: CyberPower-specific

**Recommendation**: Check if your chosen UPS is supported by NUT for Linux integration.

## Setup and Configuration

### Physical Setup

1. **Placement:**
   - Well-ventilated area (UPS generates heat)
   - Easy access for maintenance
   - Protected from moisture
   - Adequate clearance for cables

2. **Connections:**
   - Connect critical devices to battery-backed outlets
   - Non-critical devices to surge-only outlets
   - Use proper cable management

3. **Initial Testing:**
   - Charge UPS for 24 hours before first use
   - Test by unplugging power (simulate outage)
   - Verify graceful shutdown works

### Software Configuration

**Install NUT (Network UPS Tools):**
```bash
# Ubuntu/Debian
sudo apt-get install nut nut-client nut-server

# Configure UPS
sudo nano /etc/nut/ups.conf
```

**Example Configuration:**
```
[ups]
    driver = usbhid-ups
    port = auto
    desc = "APC Back-UPS 600VA"
```

**Configure Monitoring:**
```bash
sudo nano /etc/nut/upsmon.conf
```

**Integration with System:**
```bash
# Auto-shutdown script
sudo nano /etc/nut/upssched.conf
```

**Start Services:**
```bash
sudo systemctl enable nut-server nut-client
sudo systemctl start nut-server nut-client
```

### Docker Integration

**Create NUT Container:**
```yaml
nut-server:
  image: instantlinux/nut-upsd
  container_name: nut-server
  devices:
    - /dev/bus/usb:/dev/bus/usb
  volumes:
    - ./nut/config:/etc/nut
  privileged: true
  restart: unless-stopped
```

**Prometheus Exporter:**
```yaml
nut-exporter:
  image: oliver006/nut_exporter
  container_name: nut-exporter
  environment:
    - NUT_HOST=nut-server
    - NUT_USERNAME=monuser
    - NUT_PASSWORD=secret
  ports:
    - "9995:9995"
  depends_on:
    - nut-server
```

## Maintenance

### Regular Maintenance

**Monthly:**
- Check battery status via software
- Verify self-test passes
- Clean UPS exterior and vents
- Check for error indicators

**Quarterly:**
- Run full battery test (simulate outage)
- Check battery runtime matches specifications
- Review UPS logs for issues

**Annually:**
- Consider battery replacement (typically 3-5 year lifespan)
- Professional inspection (if available)

### Battery Replacement

**Signs Battery Needs Replacement:**
- Reduced runtime
- Frequent beeping/alerts
- Battery test failures
- Age > 3-5 years

**Replacement:**
- Purchase compatible replacement battery
- Follow manufacturer instructions
- Test after replacement
- Dispose of old battery properly (recycling center)

## Monitoring Integration

### Prometheus Metrics

**Metrics to Monitor:**
- Battery voltage
- Battery charge percentage
- Battery runtime (remaining)
- Load percentage
- Input/output voltage
- Temperature
- Status (online/on battery/low battery)

### Grafana Dashboard

Create dashboard to visualize:
- Current battery status
- Historical battery usage
- Power events (outages, brownouts)
- Runtime trends
- Alerts for low battery

### Alerts

**Critical Alerts:**
- UPS on battery (power outage)
- Low battery (<20%)
- Battery failure
- UPS overload

**Warning Alerts:**
- Battery test failure
- High temperature
- Voltage fluctuations

## Budget Considerations

### Minimum Viable Setup
- **UPS**: 600VA (~$80-100)
- **Software**: NUT (free, open source)
- **Total**: ~$100

### Recommended Setup
- **UPS**: 1000-1500VA with AVR (~$200-250)
- **Software**: NUT + Prometheus exporter (free)
- **Monitoring**: Integrated with existing Grafana
- **Total**: ~$250

### Professional Setup
- **UPS**: 1500VA+ with network management (~$300-400)
- **External Battery Pack** (optional, +$150-200)
- **Software**: NUT + monitoring integration
- **Total**: ~$350-600

## Recommendation for Your Setup

Based on your requirements (media server, NAS, boot error concerns):

**Recommended: APC Smart-UPS 1000VA (SMT1000) or CyberPower OR1500LCD**

**Why:**
- Adequate runtime (10+ minutes) for graceful shutdown
- Pure sine wave (better for active PFC PSUs)
- AVR (protects against brownouts)
- Network management capability
- Good software support (NUT compatible)
- Reasonable price point (~$200-250)

**Next Steps:**
1. Measure actual power consumption (use kill-a-watt meter)
2. Determine required runtime (5-10 minutes minimum)
3. Select UPS based on calculated needs
4. Install and configure NUT
5. Set up monitoring and alerts
6. Test graceful shutdown procedure



