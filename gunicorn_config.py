# Gunicorn配置文件
import multiprocessing
import os
from config import HOST, PORT

# 服务器socket
bind = f"{HOST}:{PORT}"
backlog = 2048

# 工作进程
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = 'sync'
worker_connections = 1000
timeout = 120
keepalive = 5

# 日志
accesslog = 'logs/access.log'
errorlog = 'logs/error.log'
loglevel = 'info'
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# 进程命名
proc_name = 'converter'

# 服务器机制
daemon = False
pidfile = 'gunicorn.pid'
umask = 0
user = None
group = None
tmp_upload_dir = None

# SSL (如果需要HTTPS，取消注释并配置)
# keyfile = '/path/to/keyfile'
# certfile = '/path/to/certfile'

# 确保日志目录存在
os.makedirs('logs', exist_ok=True)
