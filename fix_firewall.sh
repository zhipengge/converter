#!/bin/bash
# 防火墙配置脚本 - 开放8000端口

set -e

echo "========================================="
echo "配置防火墙开放端口"
echo "========================================="
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "错误: 请使用root权限运行此脚本"
    echo "使用: sudo $0"
    exit 1
fi

# 获取端口号
PORT=$(grep -E "^PORT\s*=" /root/workspace/converter/config.py 2>/dev/null | sed "s/.*=\s*\([0-9]*\).*/\1/" || echo "8000")

echo "正在开放端口 $PORT..."

# 1. 配置iptables
if command -v iptables &> /dev/null; then
    echo ""
    echo "1. 配置iptables..."
    
    # 检查规则是否已存在
    if iptables -C INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null; then
        echo "   ✓ 端口 $PORT 规则已存在"
    else
        # 在INPUT链的最前面插入规则
        iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
        echo "   ✓ 已添加iptables规则: 允许TCP端口 $PORT"
    fi
    
    # 尝试保存规则
    if [ -d "/etc/iptables" ]; then
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4 2>/dev/null && echo "   ✓ 规则已保存到 /etc/iptables/rules.v4"
    elif command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save 2>/dev/null && echo "   ✓ 规则已保存（使用netfilter-persistent）"
    elif [ -f "/etc/rc.local" ]; then
        echo "   提示: 请手动保存iptables规则，或添加到 /etc/rc.local"
    fi
fi

# 2. 配置firewalld
if systemctl is-active --quiet firewalld 2>/dev/null; then
    echo ""
    echo "2. 配置firewalld..."
    if firewall-cmd --list-ports 2>/dev/null | grep -q "$PORT/tcp"; then
        echo "   ✓ 端口 $PORT 已在firewalld中开放"
    else
        firewall-cmd --permanent --add-port=$PORT/tcp
        firewall-cmd --reload
        echo "   ✓ 已在firewalld中开放端口 $PORT"
    fi
fi

# 3. 配置ufw
if command -v ufw &> /dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo ""
    echo "3. 配置ufw..."
    if ufw status 2>/dev/null | grep -q "$PORT/tcp"; then
        echo "   ✓ 端口 $PORT 已在ufw中开放"
    else
        ufw allow $PORT/tcp
        echo "   ✓ 已在ufw中开放端口 $PORT"
    fi
fi

echo ""
echo "========================================="
echo "配置完成！"
echo "========================================="
echo ""
echo "请检查："
echo "1. 如果使用云服务器，还需要在云服务器控制台配置安全组规则"
echo "2. 开放端口: $PORT"
echo "3. 协议: TCP"
echo "4. 源: 0.0.0.0/0 (允许所有IP) 或特定IP"
echo ""
echo "测试访问: http://您的服务器IP:$PORT"
echo ""
