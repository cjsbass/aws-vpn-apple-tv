# Setting Up Apple TV with Your AWS VPN

Since Apple TV doesn't natively support VPN connections, we'll need to use one of several workaround methods. This guide will walk you through the options from simplest to most complex.

## Option 1: VPN-Enabled Router (Recommended)

Using a VPN-enabled router is the simplest way to get your Apple TV to use a VPN.

### What You'll Need:
- A router that supports VPN client connections (like ASUS with AsusWRT, or any router with DD-WRT or Tomato firmware)
- The OpenVPN configuration file (`AppleTV.ovpn`) from your AWS VPN server

### Step-by-Step Instructions:

1. **Access your router's admin panel**
   - Connect to your home WiFi
   - Open a web browser and enter your router's IP address (typically 192.168.1.1 or 192.168.0.1)
   - Log in with your admin credentials

2. **Import the OpenVPN configuration**
   - Find the VPN Client section in your router settings (location varies by router brand)
   - Look for an option to import an OpenVPN configuration or create a new VPN client connection
   - Upload or copy-paste the contents of your `AppleTV.ovpn` file

3. **Enable the VPN connection**
   - Save your settings and enable the VPN connection
   - Your router will now connect to your AWS VPN server

4. **Connect your Apple TV to this router**
   - All traffic from devices connected to this router will now go through your VPN
   - No configuration is needed on the Apple TV itself - it will automatically use the VPN

## Option 2: Smart DNS Service

If your primary goal is accessing geo-restricted content rather than encryption, a Smart DNS service might be simpler.

### Setting Up Smart DNS on Apple TV:

1. **On your Apple TV, go to Settings**

2. **Select Network**

3. **Select your current WiFi connection or Ethernet**

4. **Select "Configure DNS"**

5. **Change from "Automatic" to "Manual"**

6. **Enter the DNS server address from your VPN service**
   - For our AWS OpenVPN setup, you'll need to set up a dedicated Smart DNS service or use a DNS proxy

## Option 3: Create a VPN Gateway with Raspberry Pi

This is a more advanced option that involves setting up a Raspberry Pi as a VPN gateway.

### What You'll Need:
- Raspberry Pi (any model with Ethernet port)
- MicroSD card
- Ethernet cable
- Your OpenVPN configuration file

### High-Level Steps:
1. Install Raspberry Pi OS on the microSD card
2. Connect the Raspberry Pi to your network with an Ethernet cable
3. Install OpenVPN client on the Raspberry Pi
4. Configure the Raspberry Pi to share its VPN connection
5. Set up your Apple TV to use the Raspberry Pi as its gateway

Detailed instructions for this method require more advanced networking knowledge, so we recommend Option 1 (VPN router) for most users.

## Check If It's Working

After setting up any of these methods:

1. Turn on your Apple TV
2. Open a streaming app that offers content specific to other regions
3. If you can browse and watch content from the target region, your VPN setup is working!

For troubleshooting, visit websites like "whatismyip.com" through a browser on your Apple TV (if available) to verify your IP address has changed to the location of your VPN server. 