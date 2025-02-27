# VPN Troubleshooting Guide

This guide addresses common issues you might encounter when setting up and using your AWS VPN with Apple TV.

## AWS Setup Issues

### Cannot Connect to AWS CLI

**Symptoms:**
- `aws: command not found` error
- Authentication failures when running AWS commands

**Solutions:**
1. **Installation Issues:**
   - Mac: Run `brew install awscli`
   - Windows: Reinstall from https://aws.amazon.com/cli/
   - Linux: Run `pip3 install awscli --upgrade --user`

2. **Credentials Issues:**
   - Run `aws configure` and re-enter your AWS Access Key ID and Secret Access Key
   - Check if your AWS account has permissions to create EC2 instances

### EC2 Instance Creation Fails

**Symptoms:**
- Error messages during `setup.sh` script execution
- No EC2 instance appears in your AWS console

**Solutions:**
1. **Check AWS Region Compatibility:**
   - Some AMI IDs are region-specific. Edit the setup.sh script to use an AMI ID valid for your region.

2. **Quota Issues:**
   - Check if you've reached your EC2 instance limit
   - Visit AWS Console > Service Quotas > Amazon EC2 to request limit increases

3. **Billing Issues:**
   - Ensure your AWS account has valid payment information

### Security Group Issues

**Symptoms:**
- Cannot SSH into your EC2 instance
- VPN connection fails despite server running

**Solutions:**
1. Check if ports 22 (SSH) and 1194 (OpenVPN) are open:
   ```
   aws ec2 describe-security-groups --group-ids YOUR_SECURITY_GROUP_ID
   ```

2. Manually add the required rules:
   ```
   aws ec2 authorize-security-group-ingress --group-id YOUR_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id YOUR_SECURITY_GROUP_ID --protocol udp --port 1194 --cidr 0.0.0.0/0
   ```

## OpenVPN Server Issues

### OpenVPN Installation Fails

**Symptoms:**
- Error messages during `openvpn-install.sh` script execution
- OpenVPN service not starting

**Solutions:**
1. **Dependencies Issue:**
   ```
   sudo yum update -y
   sudo yum install -y epel-release
   sudo yum install -y openvpn easy-rsa
   ```

2. **Check Logs:**
   ```
   sudo cat /var/log/yum.log
   ```

### OpenVPN Won't Start

**Symptoms:**
- Error when starting OpenVPN service
- No connection possible to the VPN

**Solutions:**
1. **Check Service Status:**
   ```
   sudo systemctl status openvpn-server@server
   ```

2. **Check Configuration:**
   ```
   sudo cat /etc/openvpn/server/server.conf
   ```

3. **Check Logs:**
   ```
   sudo tail -f /var/log/openvpn/openvpn.log
   ```

4. **Restart Service:**
   ```
   sudo systemctl restart openvpn-server@server
   ```

### Client Configuration Generation Fails

**Symptoms:**
- Error when running the make_config.sh script
- Missing or incomplete .ovpn files

**Solutions:**
1. **Check CA Setup:**
   ```
   ls -la ~/openvpn-ca/pki/
   ```

2. **Regenerate Certificates:**
   ```
   cd ~/openvpn-ca
   ./easyrsa gen-req AppleTV nopass
   ./easyrsa sign-req client AppleTV
   ```

## Router VPN Client Issues

### Router Won't Connect to VPN

**Symptoms:**
- Router shows connection errors
- Connection attempts time out

**Solutions:**
1. **Check VPN File Format:**
   - Some routers are picky about .ovpn file format
   - Try removing comments from the file
   
2. **Router Compatibility:**
   - Not all routers support OpenVPN clients
   - Check your router's documentation or consider upgrading firmware
   
3. **Verify Server is Running:**
   ```
   ssh -i ~/.ssh/MyVPNKeyPair.pem ec2-user@YOUR_SERVER_IP
   sudo systemctl status openvpn-server@server
   ```

### Connected but No Internet

**Symptoms:**
- Router shows VPN as connected
- Devices can't access the internet

**Solutions:**
1. **Check NAT Configuration:**
   ```
   sudo sysctl net.ipv4.ip_forward
   ```
   (Should return 1)

2. **Check iptables Rules:**
   ```
   sudo iptables -t nat -L
   ```
   (Should see a MASQUERADE rule for your VPN subnet)

3. **Restart OpenVPN with NAT fix:**
   ```
   sudo sysctl -w net.ipv4.ip_forward=1
   sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
   sudo systemctl restart openvpn-server@server
   ```

## Apple TV Issues

### Apple TV Shows Local Content Only

**Symptoms:**
- Streaming apps still show your local country's content
- Geo-restricted content remains blocked

**Solutions:**
1. **Verify Router VPN Connection:**
   - Check if your router is actually routing through the VPN
   - Try visiting whatismyip.com on another device connected to the same router

2. **Restart Apple TV:**
   - Go to Settings > System > Restart
   
3. **Clear DNS Cache:**
   - Disconnect Apple TV from power for 30 seconds, then reconnect

4. **Check for DNS Leaks:**
   - Some streaming services detect VPNs through DNS leaks
   - Try setting manual DNS on your Apple TV to match your VPN country

### Smart DNS Not Working

**Symptoms:**
- Manual DNS settings don't unlock geo-restricted content

**Solutions:**
1. **Verify DNS Settings:**
   - Double-check that the DNS settings are correctly entered
   
2. **Try Alternative DNS Services:**
   - Some free DNS services: OpenDNS (208.67.222.222) or Google DNS (8.8.8.8)
   - Consider a paid Smart DNS service specifically for streaming

3. **Restart Network Connection:**
   - Disconnect and reconnect your network connection on Apple TV

## AWS Maintenance Issues

### High AWS Bills

**Symptoms:**
- Unexpected charges on your AWS bill

**Solutions:**
1. **Check EC2 Instance Type:**
   - Consider using a t2.micro or t3a.nano instance to reduce costs
   
2. **Check Data Transfer:**
   - Streaming video uses significant data
   - Set up AWS Budgets to alert you about costs
   
3. **Consider Scheduled Operation:**
   - Set up scripts to start/stop your EC2 instance when you need it

### VPN Stopped Working After Some Time

**Symptoms:**
- VPN worked initially but stopped after days/weeks

**Solutions:**
1. **Check if Server is Running:**
   ```
   aws ec2 describe-instances --instance-ids YOUR_INSTANCE_ID
   ```

2. **Check for Security Updates:**
   ```
   ssh -i ~/.ssh/MyVPNKeyPair.pem ec2-user@YOUR_SERVER_IP
   sudo yum update -y
   sudo systemctl restart openvpn-server@server
   ```

3. **IP Address Has Been Blocked:**
   - Some streaming services block known VPN IPs
   - Create a new EC2 instance in a different region
   - Assign an Elastic IP to easily change the server's public IP

## Streaming Service-Specific Issues

### Netflix Not Working

**Symptoms:**
- Netflix shows proxy/VPN error message

**Solutions:**
1. **Try Different AWS Regions:**
   - Some regions are more heavily blocked by Netflix
   
2. **Use Residential IP Addresses:**
   - AWS IPs are often known to streaming services
   - Consider a residential proxy service

### BBC iPlayer, Hulu, or Other Services Not Working

**Symptoms:**
- Service-specific error messages about location

**Solutions:**
1. **Country-Specific Configuration:**
   - Create region-specific VPN profiles for different services
   
2. **Check for Browser Cookies/Storage:**
   - Clear cache and cookies on your device if applicable

## When All Else Fails

If you've tried everything and still can't get your VPN working with Apple TV:

1. **Consider Commercial VPN Services:**
   - Services like ExpressVPN, NordVPN, etc. offer Apple TV-specific solutions
   
2. **Apple TV Screen Mirroring:**
   - Use screen mirroring from a device that can run a VPN client
   
3. **Seek Community Help:**
   - Visit forums like Reddit's r/VPN or Stack Exchange for specific troubleshooting 