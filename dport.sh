#!/bin/bash

configure_iptables_rules() {
    # Ask for network interface name
    read -p "Enter your network interface name (ifconfig查看网卡名称, default: eth0): " network_interface
    network_interface=${network_interface:-eth0}

    # Ask for jump port
    read -p "Enter the jump port (指定端口, default: 10593): " jump_port
    jump_port=${jump_port:-10593}

    # Ask for destination port
    read -p "Enter the destination port (跳跃端口类似这样, default: 10595:11596): " destination_port
    destination_port=${destination_port:-10595:11596}

    iptables -t nat -A PREROUTING -i "$network_interface" -p udp --dport "$destination_port" -j DNAT --to-destination ":$jump_port"
    ip6tables -t nat -A PREROUTING -i "$network_interface" -p udp --dport "$destination_port" -j DNAT --to-destination ":$jump_port"
}

# Call the function to configure iptables rules
configure_iptables_rules

# Save the function to a script file
script_file="/etc/iptables-rules.sh"
echo -e "#!/bin/bash\n\nconfigure_iptables_rules" > "$script_file"
chmod +x "$script_file"

# Configure systemd service
systemd_service="/etc/systemd/system/apply-iptables-rules.service"
echo -e "[Unit]\nDescription=Apply iptables rules at startup\n\n[Service]\nExecStart=$script_file\n\n[Install]\nWantedBy=multi-user.target" > "$systemd_service"

# Enable systemd service
systemctl daemon-reload
systemctl enable apply-iptables-rules.service

# 提示用户是否重启
read -p "Do you want to reboot the system now? (y/n): " reboot_choice

# 检查用户的选择
if [ "$reboot_choice" = "y" ]; then
    # 用户选择重启
    reboot
else
    # 用户选择不重启
    echo "You chose not to reboot. The changes will take effect upon next system restart."
fi
