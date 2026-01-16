#!/bin/bash
# 启动脚本 - 使用gunicorn运行应用

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查pipenv环境
if ! command -v pipenv &> /dev/null; then
    echo "错误: 未找到pipenv，请先安装: pip install pipenv"
    exit 1
fi

# 检查并安装依赖
if [ ! -f "Pipfile.lock" ]; then
    echo "检测到未安装依赖，正在安装..."
    pipenv install
elif ! pipenv run python -c "import gunicorn" 2>/dev/null; then
    echo "检测到gunicorn未安装，正在安装依赖..."
    pipenv install
fi

# 确保日志目录存在
mkdir -p logs

# 验证gunicorn是否可用
if ! pipenv run gunicorn --version &>/dev/null; then
    echo "错误: gunicorn未正确安装，请运行: pipenv install"
    exit 1
fi

# 获取服务器IP地址
get_server_ip() {
    # 尝试多种方法获取IP地址
    local ip=""
    
    # 方法1: 使用hostname -I (最简单)
    if command -v hostname &> /dev/null; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # 方法2: 使用ip命令
    if [ -z "$ip" ] && command -v ip &> /dev/null; then
        ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
    fi
    
    # 方法3: 使用ifconfig
    if [ -z "$ip" ] && command -v ifconfig &> /dev/null; then
        ip=$(ifconfig | grep -oP 'inet\s+\K[\d.]+' | grep -v '127.0.0.1' | head -n1)
    fi
    
    # 如果还是获取不到，尝试从网络接口获取
    if [ -z "$ip" ]; then
        for iface in $(ls /sys/class/net/ | grep -v lo); do
            ip=$(ip -4 addr show $iface 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
            if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
                break
            fi
        done
    fi
    
    echo "$ip"
}

SERVER_IP=$(get_server_ip)
PORT=$(grep -E "^PORT\s*=" config.py 2>/dev/null | sed "s/.*=\s*\([0-9]*\).*/\1/" || echo "8000")

# 启动gunicorn
echo "========================================="
echo "正在启动文件转换器服务..."
echo "========================================="
echo "本地访问: http://localhost:${PORT}"
if [ -n "$SERVER_IP" ]; then
    echo "外网访问: http://${SERVER_IP}:${PORT}"
else
    echo "外网访问: http://您的服务器IP:${PORT}"
    echo "提示: 无法自动获取IP地址，请手动查看服务器IP"
fi
echo "========================================="
echo "按 Ctrl+C 停止服务"
echo ""

pipenv run gunicorn -c gunicorn_config.py app:app
