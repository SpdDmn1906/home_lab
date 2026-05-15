# Raspberry Pi DNS Project: Shopping List & Setup Guide

This guide details the hardware and software required to decouple your home DNS from your primary media server, ensuring network stability even during server maintenance or crashes.

---

## 🛒 **Shopping List**

### **Option A: The Performance Choice (Recommended)**
*Best for reliability and future-proofing.*
1.  **Raspberry Pi 4 (2GB or 4GB)**: Sufficient for DNS and small utility scripts.
2.  **Official USB-C Power Supply**: Avoids "Under-voltage" errors.
3.  **MicroSD Card (32GB/64GB)**: Get a **"High Endurance"** or **"Max Endurance"** card (e.g., SanDisk High Endurance). DNS generates many small writes.
4.  **Flirc Case or Aluminum Heat Sink Case**: Passive cooling (no fan noise).
5.  **Ethernet Cable**: **Mandatory** for DNS stability. Never use Wi-Fi for your primary DNS.

### **Option B: The Budget/Compact Choice**
*Ultra-low power and tiny footprint.*
1.  **Raspberry Pi Zero 2 W**: Surprisingly capable for DNS.
2.  **Micro-USB to Ethernet Adapter**: Crucial for stability.
3.  **Official Micro-USB Power Supply**.
4.  **High Endurance MicroSD Card**.

---

## 🛠️ **Step-by-Step Setup Guide**

### **Phase 1: OS Installation**
1.  **Download Raspberry Pi Imager** on your PC/Mac.
2.  **Choose OS**: `Other specialized-purpose OS` -> `DietPi`. 
    *   *Why DietPi?* It is significantly more lightweight than standard Raspberry Pi OS and has a "zero-touch" install for AdGuard Home and Unbound.
3.  **Flash to SD card** and insert into the Pi.
4.  **Connect Ethernet** and power it on.

### **Phase 2: Initial Configuration**
1.  **Find the IP**: Check your router for a new device named `DietPi`.
2.  **SSH into the Pi**: 
    ```bash
    ssh root@<PI_IP_ADDRESS>  # Default pass: dietpi
    ```
3.  **Follow the DietPi first-run wizard**: Change the password and let it update.
4.  **Set a Static IP**:
    *   Run `dietpi-config` -> `Network Options: Adapters` -> `Ethernet` -> `Static`.
    *   Set it to something memorable, like `192.168.1.5`.

### **Phase 3: Automated Software Install**
1.  Run `dietpi-software`.
2.  Select **Browse Software**.
3.  Check the boxes for:
    - [x] **AdGuard Home** (ID: 126)
    - [x] **Unbound** (ID: 182)
4.  Select **Install** and wait for completion.

### **Phase 4: Unbound & AdGuard Integration**
1.  **Configure Unbound**:
    DietPi configures Unbound to listen on `127.0.0.1:5335`. No manual file editing is usually needed.
2.  **Configure AdGuard Home**:
    - Open your browser to `http://<PI_IP_ADDRESS>:3000`.
    - Follow the setup wizard.
    - Go to **Settings -> DNS Settings**.
    - In **Upstream DNS Servers**, remove the defaults and add only:
      ```text
      127.0.0.1:5335
      ```
    - Scroll down to **DNS Services Configuration** and select **Parallel Queries** for speed.
    - Click **Apply**.

### **Phase 5: The "Cutover"**
1.  **Test**: On your PC, manually set your DNS to the Pi's IP. Try to browse the web.
2.  **Router Config**: 
    - Log into your **Asus/Eero Router (192.168.1.1)**.
    - Go to **LAN -> DHCP Server**.
    - Set **DNS Server 1** to your Raspberry Pi's Static IP.
    - Set **DNS Server 2** to `1.1.1.1` (Cloudflare) for emergency redundancy.
3.  **Reboot your devices** (or wait for DHCP lease renewal).

---

## 📈 **Next Steps After Setup**
- **Disable AdGuard on the Media Server**: Once the Pi is stable, shut down the AdGuard container on `mediaserver` to free up resources.
- **Backup**: Use the DietPi-Backup tool once a month to save your settings to a local file.
