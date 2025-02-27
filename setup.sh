#!/bin/bash

# Exit on any error
set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}   AWS VPN Server Setup Script          ${NC}"
echo -e "${GREEN}=========================================${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}AWS CLI is not installed. Please install it first:${NC}"
    echo "https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${YELLOW}AWS CLI is not configured with your credentials.${NC}"
    echo "Please run 'aws configure' and enter your AWS credentials."
    exit 1
fi

echo -e "\n${GREEN}Step 1: Creating a security group for your VPN server...${NC}"
# Create security group
SG_ID=$(aws ec2 create-security-group \
    --group-name VPN-SecurityGroup-$(date +%s) \
    --description "Security group for VPN server" \
    --query 'GroupId' \
    --output text)

echo "Security Group created: $SG_ID"

# Allow SSH access (port 22)
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Allow OpenVPN access (port 1194 UDP)
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol udp \
    --port 1194 \
    --cidr 0.0.0.0/0

echo -e "\n${GREEN}Step 2: Creating EC2 instance...${NC}"
# Create EC2 instance (using Amazon Linux 2 for eu-west-2 region)
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0eebf19cec0b40d10 \
    --instance-type t2.micro \
    --key-name MyVPNKeyPair \
    --security-group-ids $SG_ID \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "EC2 Instance created: $INSTANCE_ID"
echo "Waiting for instance to initialize..."

# Wait for the instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get the public IP of the instance
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "\n${GREEN}Instance is now running!${NC}"
echo "Public IP: $PUBLIC_IP"

# Save the instance details to a config file
mkdir -p config
cat > config/instance-details.txt << EOF
INSTANCE_ID=$INSTANCE_ID
PUBLIC_IP=$PUBLIC_IP
SECURITY_GROUP_ID=$SG_ID
EOF

echo -e "\n${GREEN}Step 3: Next steps - Connecting to your instance${NC}"
echo -e "Use the following command to connect to your instance:"
echo -e "ssh -i ~/.ssh/MyVPNKeyPair.pem ec2-user@$PUBLIC_IP"
echo -e "\nRun the openvpn-install.sh script after connecting to set up OpenVPN."

# Create the OpenVPN installation script
cat > openvpn-install.sh << 'EOF'
#!/bin/bash

# This script will be run on the EC2 instance to install OpenVPN

# Exit on any error
set -e

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}   OpenVPN Server Installation Script    ${NC}"
echo -e "${GREEN}=========================================${NC}"

# Update system packages
echo -e "\n${GREEN}Updating system packages...${NC}"
sudo yum update -y

# Install required packages
echo -e "\n${GREEN}Installing required packages...${NC}"
sudo yum install -y epel-release
sudo yum install -y openvpn easy-rsa

# Set up the CA directory
echo -e "\n${GREEN}Setting up Certificate Authority...${NC}"
mkdir -p ~/openvpn-ca
cp -r /usr/share/easy-rsa/3/* ~/openvpn-ca/

# Initialize the PKI
cd ~/openvpn-ca
./easyrsa init-pki

# Build the CA
echo -e "\n${GREEN}Building the Certificate Authority...${NC}"
./easyrsa build-ca nopass << EOF2
VPN-CA
EOF2

# Generate server key and certificate
echo -e "\n${GREEN}Generating server certificate and key...${NC}"
./easyrsa gen-req server nopass << EOF2
server
EOF2

# Sign the server certificate
./easyrsa sign-req server server << EOF2
yes
EOF2

# Generate Diffie-Hellman parameters
echo -e "\n${GREEN}Generating Diffie-Hellman parameters (this may take some time)...${NC}"
./easyrsa gen-dh

# Generate TLS key
echo -e "\n${GREEN}Generating TLS key...${NC}"
openvpn --genkey --secret pki/ta.key

# Create server configuration directory
echo -e "\n${GREEN}Setting up OpenVPN server configuration...${NC}"
sudo mkdir -p /etc/openvpn/server
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem pki/ta.key /etc/openvpn/server/

# Create OpenVPN server configuration
echo -e "\n${GREEN}Creating server configuration...${NC}"
sudo tee /etc/openvpn/server/server.conf > /dev/null << 'EOF2'
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
cipher AES-256-CBC
auth SHA256
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"
keepalive 10 120
user nobody
group nobody
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
EOF2

# Create log directory
sudo mkdir -p /var/log/openvpn

# Enable IP forwarding
echo -e "\n${GREEN}Enabling IP forwarding...${NC}"
sudo sysctl -w net.ipv4.ip_forward=1
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Set up NAT
echo -e "\n${GREEN}Setting up NAT rules...${NC}"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_INTERFACE=$(ip route get $PUBLIC_IP | awk 'NR==1 {print $(NF-2)}')
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $PUBLIC_INTERFACE -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables.rules

# Configure iptables to load on boot
sudo tee /etc/systemd/system/iptables-restore.service > /dev/null << 'EOF2'
[Unit]
Description=Restore iptables rules
Before=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables.rules
ExecReload=/sbin/iptables-restore /etc/iptables.rules
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF2

sudo systemctl enable iptables-restore.service

# Start and enable OpenVPN
echo -e "\n${GREEN}Starting OpenVPN server...${NC}"
sudo systemctl start openvpn-server@server
sudo systemctl enable openvpn-server@server

# Set up client configuration directory
echo -e "\n${GREEN}Setting up client configuration directory...${NC}"
mkdir -p ~/client-configs/files
chmod 700 ~/client-configs/files

# Create base client configuration
echo -e "\n${GREEN}Creating base client configuration...${NC}"
cat > ~/client-configs/base.conf << EOF2
client
dev tun
proto udp
remote $PUBLIC_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
key-direction 1
verb 3
EOF2

# Create client configuration generation script
echo -e "\n${GREEN}Creating client configuration generation script...${NC}"
cat > ~/client-configs/make_config.sh << 'EOF2'
#!/bin/bash

# First argument: Client name

KEY_DIR=~/openvpn-ca/pki
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf

if [ -z "$1" ]; then
    echo "Usage: $0 client-name"
    exit 1
fi

# Generate client key and certificate
cd ~/openvpn-ca
./easyrsa gen-req $1 nopass
./easyrsa sign-req client $1 << EOF3
yes
EOF3

# Create the client configuration
cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/issued/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/private/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>\nkey-direction 1') \
    > ${OUTPUT_DIR}/${1}.ovpn

echo "Client configuration created: ${OUTPUT_DIR}/${1}.ovpn"
EOF2

chmod 700 ~/client-configs/make_config.sh

# Generate a client configuration for AppleTV
echo -e "\n${GREEN}Generating client configuration for AppleTV...${NC}"
~/client-configs/make_config.sh AppleTV

echo -e "\n${GREEN}OpenVPN server setup complete!${NC}"
echo -e "Your client configuration file is: ~/client-configs/files/AppleTV.ovpn"
echo -e "You can download this file to configure your devices."
echo -e "\nFor Apple TV configuration, you will need to install a VPN app on your"
echo -e "router or use a feature called 'Smart DNS' if your VPN provider supports it."
echo -e "\nAlternatively, you can use a VPN-enabled router or a device like"
echo -e "Raspberry Pi to create a VPN gateway for your Apple TV."

EOF

chmod +x openvpn-install.sh

echo -e "\n${GREEN}All done! Follow the instructions above to connect to your VPN server.${NC}"
EOF 