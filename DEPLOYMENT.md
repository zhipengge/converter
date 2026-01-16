# 外网访问部署指南

本指南将帮助您配置文件转换器，使其可以从外网访问。

## 部署方式

### 方式一：快速启动（开发/测试环境）

适用于快速测试，但不适合生产环境：

```bash
# 1. 安装依赖
pipenv install

# 2. 直接启动（使用gunicorn）
chmod +x start.sh
./start.sh
```

服务将在 `http://0.0.0.0:8000` 启动，可以通过 `http://您的服务器IP:8000` 访问。

### 方式二：生产环境部署（推荐）

使用systemd服务和nginx反向代理，适合生产环境：

#### 1. 自动部署（推荐）

```bash
# 使用自动部署脚本
chmod +x deploy.sh
sudo ./deploy.sh
```

脚本会自动完成：
- 安装依赖
- 配置systemd服务
- 配置nginx反向代理（可选）
- 配置防火墙（可选）
- 启动服务

#### 2. 手动部署

##### 步骤1: 安装依赖

```bash
pipenv install
```

##### 步骤2: 配置systemd服务

```bash
# 查找pipenv虚拟环境路径
pipenv --venv

# 编辑converter.service，更新路径
# 将 /root/.local/share/virtualenvs/converter-*/bin 替换为实际的虚拟环境路径
# 将 /root/workspace/converter 替换为实际的项目路径

# 复制service文件
sudo cp converter.service /etc/systemd/system/

# 重新加载systemd
sudo systemctl daemon-reload

# 启用服务（开机自启）
sudo systemctl enable converter

# 启动服务
sudo systemctl start converter

# 查看状态
sudo systemctl status converter

# 查看日志
sudo journalctl -u converter -f
```

##### 步骤3: 配置Nginx反向代理（推荐）

```bash
# 安装nginx（如果未安装）
sudo apt-get install nginx  # Ubuntu/Debian
# 或
sudo yum install nginx      # CentOS/RHEL

# 编辑nginx配置文件，更新路径
# 将 /root/workspace/converter 替换为实际的项目路径

# 复制nginx配置
sudo cp nginx.conf /etc/nginx/sites-available/converter

# 创建符号链接
sudo ln -s /etc/nginx/sites-available/converter /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载nginx
sudo systemctl reload nginx
```

##### 步骤4: 配置防火墙（重要！）

**自动配置（推荐）:**
```bash
chmod +x fix_firewall.sh
sudo ./fix_firewall.sh
```

**手动配置iptables:**
```bash
# 开放端口
sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

# 保存规则（重要：确保重启后仍生效）
sudo iptables-save > /etc/iptables/rules.v4
# 或使用 netfilter-persistent
sudo netfilter-persistent save
```

**UFW (Ubuntu/Debian):**
```bash
sudo ufw allow 8000/tcp  # 直接访问gunicorn
sudo ufw allow 80/tcp    # nginx HTTP
sudo ufw allow 443/tcp   # nginx HTTPS
```

**firewalld (CentOS/RHEL):**
```bash
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

**云服务器安全组（必须配置）:**
- 在云服务商控制台（阿里云、腾讯云、AWS等）配置安全组规则
- 开放端口：8000（直接访问）或 80/443（nginx）
- 协议：TCP
- 源：0.0.0.0/0（允许所有IP）或特定IP

## 访问应用

部署完成后，可以通过以下方式访问：

1. **直接访问gunicorn**: `http://您的服务器IP:8000`
2. **通过nginx**: `http://您的服务器IP` (如果配置了nginx)

## 服务管理

### systemd服务管理

```bash
# 启动服务
sudo systemctl start converter

# 停止服务
sudo systemctl stop converter

# 重启服务
sudo systemctl restart converter

# 查看状态
sudo systemctl status converter

# 查看日志
sudo journalctl -u converter -f

# 禁用开机自启
sudo systemctl disable converter
```

### 查看应用日志

```bash
# Gunicorn访问日志
tail -f logs/access.log

# Gunicorn错误日志
tail -f logs/error.log

# systemd日志
sudo journalctl -u converter -f
```

## 配置说明

### 修改端口

编辑 `config.py`:
```python
PORT = 8000  # 修改为您想要的端口
```

然后更新：
- `gunicorn_config.py` 中的 `bind` 参数
- `nginx.conf` 中的 `upstream` 端口
- 防火墙规则

### 修改工作进程数

编辑 `gunicorn_config.py`:
```python
workers = multiprocessing.cpu_count() * 2 + 1  # 根据服务器性能调整
```

### 配置HTTPS

1. 获取SSL证书（Let's Encrypt免费证书）:
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

2. 或编辑 `nginx.conf`，取消HTTPS配置部分的注释，并配置证书路径。

## 性能优化

1. **增加工作进程**: 根据CPU核心数调整 `gunicorn_config.py` 中的 `workers`
2. **使用nginx缓存**: 在nginx配置中添加缓存规则
3. **启用gzip压缩**: 在nginx配置中添加gzip设置
4. **使用CDN**: 将静态文件托管到CDN

## 故障排查

### 诊断工具

使用诊断脚本快速检查问题：
```bash
chmod +x check_access.sh
./check_access.sh
```

### 服务无法启动

```bash
# 检查服务状态
sudo systemctl status converter

# 查看详细错误
sudo journalctl -u converter -n 50

# 检查端口是否被占用
sudo netstat -tlnp | grep 8000
# 或
sudo ss -tlnp | grep 8000
```

### 无法外网访问（最常见问题）

**使用诊断脚本:**
```bash
./check_access.sh
```

**手动检查步骤:**

1. **检查服务是否运行**
   ```bash
   ps aux | grep gunicorn
   ```

2. **检查端口是否监听**
   ```bash
   netstat -tlnp | grep 8000
   # 应该看到: 0.0.0.0:8000
   ```

3. **检查本地访问**
   ```bash
   curl http://localhost:8000
   ```

4. **检查防火墙规则（最重要）**
   ```bash
   # 检查iptables
   sudo iptables -L INPUT -n | grep 8000
   
   # 如果没有规则，添加并保存:
   sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
   sudo iptables-save > /etc/iptables/rules.v4
   
   # 或使用自动脚本
   sudo ./fix_firewall.sh
   ```

5. **检查云服务器安全组**
   - 登录云服务器控制台
   - 找到安全组/防火墙规则
   - 确保已添加入站规则：TCP端口8000

6. **检查nginx配置**（如果使用nginx）
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   ```

### 文件上传失败

1. **检查文件大小限制**: `config.py` 中的 `MAX_CONTENT_LENGTH`
2. **检查nginx配置**: `client_max_body_size` 设置
3. **检查磁盘空间**: `df -h`

## 安全建议

1. **使用HTTPS**: 配置SSL证书
2. **限制访问IP**: 在nginx中配置IP白名单
3. **定期更新**: 保持系统和依赖包更新
4. **监控日志**: 定期检查访问日志和错误日志
5. **备份数据**: 定期备份重要配置和上传的文件

## 常见问题

### Q: 如何修改监听地址？

A: 编辑 `config.py` 中的 `HOST` 和 `PORT`，然后重启服务。

### Q: 如何查看实时日志？

A: 使用 `sudo journalctl -u converter -f` 查看systemd日志，或 `tail -f logs/error.log` 查看应用日志。

### Q: 如何重启服务？

A: `sudo systemctl restart converter`

### Q: 端口8000已被占用怎么办？

A: 修改 `config.py` 中的 `PORT` 为其他端口（如8080），然后更新相关配置。

### Q: 如何卸载服务？

A: 
```bash
sudo systemctl stop converter
sudo systemctl disable converter
sudo rm /etc/systemd/system/converter.service
sudo systemctl daemon-reload
```
