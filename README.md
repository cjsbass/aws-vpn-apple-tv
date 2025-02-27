# AWS VPN Server Setup

This project contains scripts and instructions for setting up a personal VPN server on AWS and connecting devices (including Apple TV) to it.

## Project Structure

- `setup.sh`: Script to create and configure an AWS EC2 instance with OpenVPN
- `openvpn-install.sh`: Script that gets uploaded to the EC2 instance to install and configure OpenVPN
- `config/`: Directory containing configuration files for the VPN server
- `client-configs/`: Directory containing client configuration profiles
- `step-by-step-guide.md`: Comprehensive guide for the entire setup process
- `apple-tv-setup-guide.md`: Specific guide for setting up Apple TV with the VPN
- `troubleshooting-guide.md`: Solutions for common issues you might encounter

## Prerequisites

- AWS account with access credentials
- AWS CLI installed and configured
- Basic understanding of terminal/command line

## Quick Start

1. **Install AWS CLI** if not already installed
   - Mac: `brew install awscli`
   - Windows: Download installer from https://aws.amazon.com/cli/
   - Linux: `pip3 install awscli --upgrade --user`

2. **Configure AWS CLI**
   ```
   aws configure
   ```

3. **Create SSH Key** for connecting to your EC2 instance
   ```
   aws ec2 create-key-pair --key-name MyVPNKeyPair --query "KeyMaterial" --output text > ~/.ssh/MyVPNKeyPair.pem
   chmod 400 ~/.ssh/MyVPNKeyPair.pem
   ```

4. **Run the setup script**
   ```
   ./setup.sh
   ```

5. **Follow the on-screen instructions** to:
   - Connect to your EC2 instance
   - Run the OpenVPN installation script
   - Download client configuration files
   - Configure your router or devices

## Detailed Guides

For more detailed information, please refer to:

- [Complete Step-by-Step Guide](step-by-step-guide.md) - Comprehensive walkthrough of the entire process
- [Apple TV Setup Guide](apple-tv-setup-guide.md) - Specific instructions for setting up Apple TV with your VPN
- [Troubleshooting Guide](troubleshooting-guide.md) - Solutions for common issues

## Cost Considerations

Running a VPN server on AWS will incur charges. The cost depends on:

- EC2 instance type (t2.micro is eligible for AWS Free Tier)
- Data transfer (streaming video can use significant bandwidth)
- Region selection (pricing varies by region)

Consider setting up AWS Budgets to monitor and alert you about costs.

## Security Considerations

This setup creates a personal VPN for accessing geo-restricted content. While it provides basic encryption:

- It's configured for convenience rather than maximum security
- Use only on networks you trust
- Consider additional security measures for highly sensitive data

## Contributing

If you improve these scripts or find/fix issues, please submit pull requests or open issues.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 