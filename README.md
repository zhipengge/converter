# 文件格式转换器

一个基于Flask的Web文件格式转换工具，支持PDF和Word互转，PDF和图像互转。

## 功能特性

- ✅ PDF ↔ Word 互转
- ✅ PDF → 图像（支持单张大拼图或多张图片ZIP压缩包）
- ✅ 图像 → PDF（支持单张或多张图像）
- ✅ 响应式设计，支持PC和手机浏览器
- ✅ 实时转换进度显示
- ✅ 自动下载转换结果
- ✅ 自动清理服务器临时文件

## 技术栈

- **后端**: Flask
- **前端**: HTML5, CSS3, JavaScript
- **Python库**:
  - pdf2docx: PDF转Word
  - docx2pdf: Word转PDF
  - pdf2image: PDF转图像
  - img2pdf: 图像转PDF
  - Pillow: 图像处理

## 安装步骤

### 1. 安装pipenv（如果还没有安装）

```bash
pip install pipenv
```

### 2. 安装项目依赖

**使用pipenv（推荐）:**
```bash
pipenv install
```

**或使用pip和requirements.txt:**
```bash
pip install -r requirements.txt
```

### 3. 安装系统依赖（PDF转图像需要）

**Ubuntu/Debian:**
```bash
sudo apt-get install poppler-utils
```

**macOS:**
```bash
brew install poppler
```

**Windows:**
下载并安装 [poppler for Windows](http://blog.alivate.com.au/poppler-windows/)

### 4. Word转PDF系统依赖（可选）

如果需要Word转PDF功能，需要安装LibreOffice：

**Ubuntu/Debian:**
```bash
sudo apt-get install libreoffice
```

**macOS:**
```bash
brew install --cask libreoffice
```

**Windows:**
下载并安装 [LibreOffice](https://www.libreoffice.org/)

## 运行项目

### 开发环境运行

**激活pipenv环境并运行:**

```bash
pipenv shell
python app.py
```

或者直接运行：

```bash
pipenv run python app.py
```

### 生产环境运行（外网访问）

**方式一：快速启动（使用gunicorn）**

```bash
chmod +x start.sh
./start.sh
```

**方式二：完整部署（推荐，使用systemd + nginx）**

```bash
chmod +x deploy.sh
sudo ./deploy.sh
```

详细部署说明请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

### 访问应用

- **开发环境**: `http://localhost:8000`
- **生产环境（直接访问）**: `http://您的服务器IP:8000`
- **生产环境（通过nginx）**: `http://您的服务器IP`

## 项目结构

```
converter/
├── app.py              # Flask主应用
├── config.py           # 配置文件
├── converter.py        # 转换功能实现
├── Pipfile             # pipenv依赖配置
├── requirements.txt    # pip依赖配置
├── README.md           # 项目说明
├── DEPLOYMENT.md       # 外网访问部署指南
├── gunicorn_config.py  # Gunicorn配置文件
├── converter.service   # systemd服务文件
├── nginx.conf          # Nginx反向代理配置
├── start.sh            # 快速启动脚本
├── deploy.sh           # 自动部署脚本
├── templates/          # HTML模板
│   └── index.html
├── static/             # 静态文件
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── main.js
├── uploads/            # 上传文件目录（自动创建）
├── outputs/            # 输出文件目录（自动创建）
└── logs/               # 日志目录（自动创建）
```

## 配置说明

在 `config.py` 中可以修改以下配置：

- `HOST`: 服务器主机地址（默认: 0.0.0.0）
- `PORT`: 服务器端口（默认: 80）
- `UPLOAD_FOLDER`: 上传文件目录
- `OUTPUT_FOLDER`: 输出文件目录
- `MAX_CONTENT_LENGTH`: 最大文件大小（默认: 100MB）
- `PDF_DPI`: PDF转图像的分辨率（默认: 200）
- `IMAGE_QUALITY`: 图像压缩质量（默认: 85）

## 使用说明

1. 选择要转换的文件类型卡片
2. 点击"选择文件"按钮上传文件
3. 对于PDF转图像，可以选择输出模式（多张图片ZIP或单张大拼图）
4. 点击"开始转换"按钮
5. 等待转换完成，文件会自动下载
6. 下载完成后，服务器上的临时文件会自动清理

## 注意事项

- 端口80需要root权限，如果无法使用，请修改 `config.py` 中的端口号
- Word转PDF功能需要系统安装LibreOffice
- PDF转图像功能需要系统安装poppler-utils
- 大文件转换可能需要较长时间，请耐心等待

## 许可证

MIT License
