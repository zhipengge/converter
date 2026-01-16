from flask import Flask, request, jsonify, send_file, render_template
import os
import uuid
import zipfile
from werkzeug.utils import secure_filename
from config import *
from converter import Converter

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['OUTPUT_FOLDER'] = OUTPUT_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

converter = Converter()

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': '没有文件被上传'}), 400
    
    # 生成唯一ID
    task_id = str(uuid.uuid4())
    files = request.files.getlist('file')
    
    if not files or all(f.filename == '' for f in files):
        return jsonify({'error': '没有选择文件'}), 400
    
    saved_files = []
    
    # 处理多文件上传（图像转PDF）
    if len(files) > 1:
        # 创建临时zip文件包含所有图像
        zip_path = os.path.join(app.config['UPLOAD_FOLDER'], f"{task_id}_images.zip")
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for i, file in enumerate(files):
                if file and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    zipf.writestr(filename, file.read())
                    saved_files.append(filename)
        
        if not saved_files:
            return jsonify({'error': '不支持的文件类型'}), 400
        
        return jsonify({
            'task_id': task_id,
            'filename': f"{len(saved_files)}_images.zip",
            'filepath': zip_path
        })
    else:
        # 单文件上传
        file = files[0]
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], f"{task_id}_{filename}")
            file.save(filepath)
            
            return jsonify({
                'task_id': task_id,
                'filename': filename,
                'filepath': filepath
            })
    
    return jsonify({'error': '不支持的文件类型'}), 400

@app.route('/api/convert', methods=['POST'])
def convert_file():
    data = request.json
    task_id = data.get('task_id')
    convert_type = data.get('convert_type')
    options = data.get('options', {})
    
    if not task_id or not convert_type:
        return jsonify({'error': '缺少必要参数'}), 400
    
    # 查找上传的文件（可能有多个，取第一个匹配的）
    upload_path = None
    for filename in os.listdir(UPLOAD_FOLDER):
        if filename.startswith(task_id):
            upload_path = os.path.join(UPLOAD_FOLDER, filename)
            break
    
    if not upload_path or not os.path.exists(upload_path):
        return jsonify({'error': '文件不存在'}), 404
    
    try:
        result = converter.convert(upload_path, convert_type, options, task_id)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/download/<task_id>')
def download_file(task_id):
    # 查找输出文件
    output_path = None
    for filename in os.listdir(OUTPUT_FOLDER):
        if filename.startswith(task_id):
            output_path = os.path.join(OUTPUT_FOLDER, filename)
            break
    
    if not output_path or not os.path.exists(output_path):
        return jsonify({'error': '文件不存在'}), 404
    
    return send_file(output_path, as_attachment=True)

@app.route('/api/cleanup/<task_id>', methods=['DELETE'])
def cleanup_files(task_id):
    """清理上传和输出文件"""
    cleaned = []
    
    # 清理上传文件
    for filename in os.listdir(UPLOAD_FOLDER):
        if filename.startswith(task_id):
            filepath = os.path.join(UPLOAD_FOLDER, filename)
            try:
                os.remove(filepath)
                cleaned.append(f"upload: {filename}")
            except Exception as e:
                pass
    
    # 清理输出文件
    for filename in os.listdir(OUTPUT_FOLDER):
        if filename.startswith(task_id):
            filepath = os.path.join(OUTPUT_FOLDER, filename)
            try:
                os.remove(filepath)
                cleaned.append(f"output: {filename}")
            except Exception as e:
                pass
    
    return jsonify({'cleaned': cleaned})

if __name__ == '__main__':
    app.run(host=HOST, port=PORT, debug=DEBUG)
