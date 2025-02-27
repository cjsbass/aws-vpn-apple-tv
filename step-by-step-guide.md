# Complete Step-by-Step Guide: AWS VPN Setup for Apple TV

This guide will walk you through the entire process of setting up your own VPN server on AWS and connecting your Apple TV to it.

## Prerequisites

Before you begin, make sure you have:

1. An AWS account with billing set up
2. AWS CLI installed on your computer (instructions below if needed)
3. A computer with terminal/command line access
4. Basic knowledge of following instructions

## Step 1: Install AWS CLI (if not already installed)

### On Mac:
```
brew install awscli
```
or download the installer from the AWS website.

### On Windows:
Download and run the installer from: https://aws.amazon.com/cli/

### On Linux:
```
pip3 install awscli --upgrade --user
```

## Step 2: Configure AWS CLI

Open a terminal or command prompt and run:

```
aws configure
```

You'll be prompted to enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json is recommended)

You can find your AWS access keys in the AWS Management Console under:
Security Credentials > Access keys

## Step 3: Create SSH Key for Connecting to EC2

If you don't already have an SSH key for AWS, create one:

### On Mac/Linux:
```
aws ec2 create-key-pair --key-name MyVPNKeyPair --query "KeyMaterial" --output text > ~/.ssh/MyVPNKeyPair.pem
chmod 400 ~/.ssh/MyVPNKeyPair.pem
```

### On Windows:
```
aws ec2 create-key-pair --key-name MyVPNKeyPair --query "KeyMaterial" --output text > MyVPNKeyPair.pem
```
Then move the file to a secure location and restrict access.

## Step 4: Run the VPN Setup Script

1. Navigate to the folder containing your setup.sh script:
```
cd /path/to/your/vpn/folder
```

2. Make the script executable (if not already done):
```
chmod +x setup.sh
```

3. Run the setup script:
```
./setup.sh
```

4. The script will:
   - Create a security group
   - Launch an EC2 instance
   - Configure OpenVPN on the instance
   - Generate all necessary configuration files

5. Once complete, note the public IP address of your server

## Step 5: Connect to Your EC2 Instance

1. Use the SSH command displayed in the script's output:
```
ssh -i ~/.ssh/MyVPNKeyPair.pem ec2-user@YOUR_INSTANCE_IP
```

2. If prompted about host authenticity, type "yes"

## Step 6: Set Up OpenVPN on the Server

1. Once connected to your EC2 instance, run the OpenVPN installation script:
```
./openvpn-install.sh
```

2. This script will:
   - Install OpenVPN
   - Configure the server
   - Create client configuration files
   - Generate a specific configuration for your Apple TV

3. Wait for the script to complete (this may take 5-10 minutes)

## Step 7: Download the Client Configuration File

1. While still connected to your EC2 instance, locate the client configuration:
```
ls -la ~/client-configs/files/
```

2. You should see a file named `AppleTV.ovpn`

3. Download this file to your local computer using SCP:

### On Mac/Linux (run this from your local terminal, not the EC2 instance):
```
scp -i ~/.ssh/MyVPNKeyPair.pem ec2-user@YOUR_INSTANCE_IP:~/client-configs/files/AppleTV.ovpn ./
```

### On Windows with PowerShell:
```
scp -i "C:\path\to\MyVPNKeyPair.pem" ec2-user@YOUR_INSTANCE_IP:~/client-configs/files/AppleTV.ovpn ./
```

## Step 8: Configure Your Router (Recommended Method)

Since Apple TV doesn't directly support VPN connections, we'll set up your router to connect to the VPN:

1. Log into your router's admin panel (typically by visiting 192.168.1.1 or 192.168.0.1 in your web browser)

2. Look for the VPN Client settings (this varies by router brand):
   - ASUS: Advanced Settings > VPN
   - TP-Link: Advanced > VPN Server > OpenVPN
   - Netgear: Advanced > VPN Service
   - DD-WRT: Services > VPN

3. Upload or import the `AppleTV.ovpn` file

4. Enable the VPN connection

5. Make sure your Apple TV is connected to this router via WiFi or Ethernet

## Step 9: Alternative Methods (If Router Method Not Possible)

### Option A: Smart DNS Method
If your router doesn't support VPN clients, you can try the Smart DNS method on your Apple TV:

1. On your Apple TV, go to Settings > Network
2. Select your WiFi network or Ethernet
3. Select "Configure DNS"
4. Change from "Automatic" to "Manual"
5. Enter DNS server addresses that support geo-unblocking services

### Option B: Raspberry Pi VPN Gateway
For more advanced users, see the detailed instructions in apple-tv-setup-guide.md.

## Step 10: Test Your Setup

1. Turn on your Apple TV
2. Open a streaming app that's geo-restricted (like BBC iPlayer if you're outside the UK)
3. If you can browse and play content normally, your VPN setup is working!

## Troubleshooting

### VPN Not Connecting
- Check if the security group allows UDP traffic on port 1194
- Verify that your EC2 instance is running
- Check OpenVPN logs on the server: `sudo tail -f /var/log/openvpn/openvpn.log`

### Apple TV Still Showing Local Content
- Verify that your router is successfully connected to the VPN
- Try restarting both your router and Apple TV
- Make sure your Apple TV is connecting through the VPN-enabled router

### Router Doesn't Support VPN Client
- Consider purchasing a VPN-compatible router
- Try the Smart DNS method
- Set up a Raspberry Pi VPN gateway

## Maintaining Your VPN Server

### Checking Status
Connect to your EC2 instance and run:
```
sudo systemctl status openvpn-server@server
```

### Restarting the VPN Service
If you need to restart the VPN service:
```
sudo systemctl restart openvpn-server@server
```

### Creating Configurations for Additional Devices
On your EC2 instance, run:
```
~/client-configs/make_config.sh DeviceName
```
This will create a new .ovpn file in ~/client-configs/files/

## Conclusion

You now have your own private VPN running on AWS that allows your Apple TV to access content from other regions. Since you control the server, you can customize it further to suit your needs or add additional security features.

Remember that streaming services are constantly updating their systems to detect VPNs, so this solution may require occasional maintenance or updates. 