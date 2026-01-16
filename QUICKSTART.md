# 快速开始指南

## 1. 安装依赖

```bash
# 安装pipenv（如果还没有）
pip install pipenv

# 安装Python依赖
pipenv install

# 安装系统依赖（Ubuntu/Debian）
sudo apt-get install poppler-utils libreoffice
```

## 2. 运行应用

```bash
# 方式1: 激活环境后运行
pipenv shell
python app.py

# 方式2: 直接运行
pipenv run python app.py
```

## 3. 访问应用

打开浏览器访问: `http://localhost`

**注意**: 
- 端口80需要root权限，如果无法使用，请修改 `config.py` 中的 `PORT = 8080`
- 然后访问 `http://localhost:8080`

## 4. 使用说明

1. 选择要转换的文件类型卡片
2. 点击"选择文件"上传文件
3. 对于PDF转图像，可以选择输出模式
4. 点击"开始转换"
5. 等待转换完成，文件会自动下载

## 常见问题

### Q: 端口80无法使用？
A: 修改 `config.py` 中的 `PORT = 8080`，然后访问 `http://localhost:8080`

### Q: PDF转图像失败？
A: 确保已安装 `poppler-utils`:
```bash
sudo apt-get install poppler-utils  # Ubuntu/Debian
brew install poppler  # macOS
```

### Q: Word转PDF失败？
A: 确保已安装 LibreOffice:
```bash
sudo apt-get install libreoffice  # Ubuntu/Debian
brew install --cask libreoffice  # macOS
```
