#!/bin/bash
# 外网访问诊断脚本

echo "========================================="
echo "外网访问诊断工具"
echo "========================================="
echo ""

# 1. 检查服务状态
echo "1. 检查服务状态..."
if pgrep -f "gunicorn.*app:app" > /dev/null; then
    echo "   ✓ 服务正在运行"
    ps aux | grep -E "gunicorn.*app:app" | grep -v grep | head -1
else
    echo "   ✗ 服务未运行"
    echo "   请运行: ./start.sh"
fi
echo ""

# 2. 检查端口监听
echo "2. 检查端口监听..."
PORT=$(grep -E "^PORT\s*=" config.py 2>/dev/null | sed "s/.*=\s*\([0-9]*\).*/\1/" || echo "8000")
if netstat -tlnp 2>/dev/null | grep -q ":$PORT " || ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo "   ✓ 端口 $PORT 正在监听"
    netstat -tlnp 2>/dev/null | grep ":$PORT " || ss -tlnp 2>/dev/null | grep ":$PORT "
else
    echo "   ✗ 端口 $PORT 未监听"
fi
echo ""

# 3. 检查本地访问
echo "3. 检查本地访问..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT 2>/dev/null | grep -q "200"; then
    echo "   ✓ 本地访问正常"
else
    echo "   ✗ 本地无法访问"
fi
echo ""

# 4. 获取服务器IP
echo "4. 服务器IP地址..."
get_server_ip() {
    local ip=""
    if command -v hostname &> /dev/null; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    if [ -z "$ip" ] && command -v ip &> /dev/null; then
        ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
    fi
    echo "$ip"
}
SERVER_IP=$(get_server_ip)
if [ -n "$SERVER_IP" ]; then
    echo "   服务器IP: $SERVER_IP"
    echo "   访问地址: http://$SERVER_IP:$PORT"
else
    echo "   ✗ 无法获取服务器IP"
fi
echo ""

# 5. 检查防火墙 (iptables)
echo "5. 检查iptables规则..."
if command -v iptables &> /dev/null; then
    if iptables -L INPUT -n 2>/dev/null | grep -q "REJECT\|DROP"; then
        echo "   ⚠ 发现iptables规则，可能阻止访问"
        echo "   查看规则: sudo iptables -L -n"
        echo "   开放端口: sudo iptables -I INPUT -p tcp --dport $PORT -j ACCEPT"
    else
        echo "   ✓ iptables未发现阻止规则"
    fi
else
    echo "   - iptables未安装"
fi
echo ""

# 6. 检查firewalld
echo "6. 检查firewalld..."
if systemctl is-active --quiet firewalld 2>/dev/null; then
    echo "   ⚠ firewalld正在运行"
    if firewall-cmd --list-ports 2>/dev/null | grep -q "$PORT"; then
        echo "   ✓ 端口 $PORT 已开放"
    else
        echo "   ✗ 端口 $PORT 未开放"
        echo "   开放端口: sudo firewall-cmd --permanent --add-port=$PORT/tcp && sudo firewall-cmd --reload"
    fi
else
    echo "   - firewalld未运行"
fi
echo ""

# 7. 检查ufw
echo "7. 检查ufw..."
if command -v ufw &> /dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo "   ⚠ ufw正在运行"
    if ufw status 2>/dev/null | grep -q "$PORT"; then
        echo "   ✓ 端口 $PORT 已开放"
    else
        echo "   ✗ 端口 $PORT 未开放"
        echo "   开放端口: sudo ufw allow $PORT/tcp"
    fi
else
    echo "   - ufw未运行"
fi
echo ""

# 8. 云服务器提示
echo "8. 云服务器安全组检查..."
echo "   如果是云服务器（阿里云、腾讯云、AWS等），请检查："
echo "   1. 登录云服务器控制台"
echo "   2. 找到安全组/防火墙规则"
echo "   3. 添加入站规则："
echo "      - 协议: TCP"
echo "      - 端口: $PORT"
echo "      - 源: 0.0.0.0/0 (允许所有IP) 或 特定IP"
echo ""

# 9. 测试外网访问
echo "9. 测试外网访问..."
if [ -n "$SERVER_IP" ]; then
    echo "   从服务器测试外网访问..."
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$SERVER_IP:$PORT 2>/dev/null | grep -q "200"; then
        echo "   ✓ 服务器可以访问自己（通过外网IP）"
    else
        echo "   ⚠ 服务器无法通过外网IP访问自己"
        echo "   这可能是安全组或防火墙问题"
    fi
fi
echo ""

# 10. 提供解决方案
echo "========================================="
echo "快速修复方案"
echo "========================================="
echo ""
echo "方案1: 开放iptables端口"
echo "  sudo iptables -I INPUT -p tcp --dport $PORT -j ACCEPT"
echo "  sudo iptables-save > /etc/iptables/rules.v4  # 保存规则（如果存在）"
echo ""
echo "方案2: 开放firewalld端口"
echo "  sudo firewall-cmd --permanent --add-port=$PORT/tcp"
echo "  sudo firewall-cmd --reload"
echo ""
echo "方案3: 开放ufw端口"
echo "  sudo ufw allow $PORT/tcp"
echo ""
echo "方案4: 检查云服务器安全组"
echo "  在云服务器控制台配置安全组规则，开放端口 $PORT"
echo ""
echo "方案5: 临时测试（关闭防火墙，仅用于测试）"
echo "  sudo iptables -F  # 清空所有规则（危险，仅测试用）"
echo ""
