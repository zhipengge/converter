import os

# Flask配置
HOST = '0.0.0.0'
PORT = 8000
DEBUG = False

# 文件上传配置
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'outputs'
MAX_CONTENT_LENGTH = 100 * 1024 * 1024  # 100MB
ALLOWED_EXTENSIONS = {'pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg', 'gif', 'bmp'}

# 确保目录存在
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# PDF转图像配置
PDF_DPI = 200  # PDF转图像的分辨率
IMAGE_QUALITY = 85  # 图像压缩质量
