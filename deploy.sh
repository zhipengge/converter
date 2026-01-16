#!/bin/bash
# 部署脚本 - 配置systemd服务和nginx

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "========================================="
echo "文件转换器 - 外网访问部署脚本"
echo "========================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo "错误: 请使用root权限运行此脚本"
    echo "使用: sudo $0"
    exit 1
fi

# 1. 安装依赖
echo ""
echo "步骤 1: 检查并安装Python依赖..."
if ! command -v pipenv &> /dev/null; then
    echo "安装pipenv..."
    pip install pipenv
fi

pipenv install

# 2. 创建日志目录
echo ""
echo "步骤 2: 创建必要的目录..."
mkdir -p logs
chmod 755 logs

# 3. 配置systemd服务
echo ""
echo "步骤 3: 配置systemd服务..."

# 查找pipenv虚拟环境路径
VENV_PATH=$(pipenv --venv)
if [ -z "$VENV_PATH" ]; then
    echo "错误: 无法找到pipenv虚拟环境"
    exit 1
fi

# 更新service文件中的路径
sed -i "s|/root/.local/share/virtualenvs/converter-*/bin|$VENV_PATH/bin|g" converter.service
sed -i "s|/root/workspace/converter|$SCRIPT_DIR|g" converter.service

# 复制service文件
cp converter.service /etc/systemd/system/converter.service
systemctl daemon-reload
systemctl enable converter.service

echo "systemd服务已配置"
echo "使用以下命令管理服务:"
echo "  启动: sudo systemctl start converter"
echo "  停止: sudo systemctl stop converter"
echo "  重启: sudo systemctl restart converter"
echo "  状态: sudo systemctl status converter"
echo "  日志: sudo journalctl -u converter -f"

# 4. 配置nginx（可选）
echo ""
read -p "是否配置Nginx反向代理? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! command -v nginx &> /dev/null; then
        echo "安装nginx..."
        if command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y nginx
        elif command -v yum &> /dev/null; then
            yum install -y nginx
        else
            echo "错误: 无法自动安装nginx，请手动安装"
            exit 1
        fi
    fi
    
    # 更新nginx配置中的路径
    sed -i "s|/root/workspace/converter|$SCRIPT_DIR|g" nginx.conf
    
    # 复制nginx配置
    cp nginx.conf /etc/nginx/sites-available/converter
    ln -sf /etc/nginx/sites-available/converter /etc/nginx/sites-enabled/
    
    # 测试nginx配置
    if nginx -t; then
        systemctl reload nginx
        echo "Nginx配置已应用"
        echo "访问地址: http://您的服务器IP"
    else
        echo "警告: Nginx配置测试失败，请检查配置"
    fi
fi

# 5. 配置防火墙
echo ""
read -p "是否配置防火墙开放端口? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v ufw &> /dev/null; then
        echo "配置UFW防火墙..."
        ufw allow 8000/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        echo "防火墙规则已添加"
    elif command -v firewall-cmd &> /dev/null; then
        echo "配置firewalld..."
        firewall-cmd --permanent --add-port=8000/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
        echo "防火墙规则已添加"
    else
        echo "提示: 未检测到常见防火墙工具，请手动开放端口8000（或80/443如果使用nginx）"
    fi
fi

# 6. 启动服务
echo ""
read -p "是否现在启动服务? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl start converter
    sleep 2
    systemctl status converter --no-pager
    
    echo ""
    echo "========================================="
    echo "部署完成！"
    echo "========================================="
    echo "服务状态: sudo systemctl status converter"
    echo "查看日志: sudo journalctl -u converter -f"
    echo "访问地址: http://您的服务器IP:8000"
    if [ -f "/etc/nginx/sites-enabled/converter" ]; then
        echo "或通过Nginx: http://您的服务器IP"
    fi
fi

echo ""
echo "部署脚本执行完成！"
