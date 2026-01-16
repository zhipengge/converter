// 存储任务ID
const taskData = {};

// 文件选择事件
document.querySelectorAll('.file-input').forEach(input => {
    input.addEventListener('change', function(e) {
        const label = this.nextElementSibling;
        if (this.files && this.files.length > 0) {
            label.classList.add('file-selected');
            if (this.files.length === 1) {
                label.textContent = `已选择: ${this.files[0].name}`;
            } else {
                label.textContent = `已选择: ${this.files.length} 个文件`;
            }
        }
    });
});

// 开始转换
async function startConvert(convertType) {
    const card = document.querySelector(`[data-type="${convertType}"]`);
    const fileInput = card.querySelector('.file-input');
    const convertBtn = card.querySelector('.convert-btn');
    const progressContainer = card.querySelector('.progress-container');
    const progressFill = card.querySelector('.progress-fill');
    const progressText = card.querySelector('.progress-text');

    // 检查文件是否已选择
    if (!fileInput.files || fileInput.files.length === 0) {
        alert('请先选择文件！');
        return;
    }

    // 禁用按钮
    convertBtn.disabled = true;
    convertBtn.textContent = '转换中...';

    // 显示进度条
    progressContainer.style.display = 'block';
    progressFill.style.width = '0%';
    progressText.textContent = '上传文件中...';

    try {
        // 步骤1: 上传文件
        const formData = new FormData();
        if (fileInput.multiple && fileInput.files.length > 1) {
            // 多文件上传（图像转PDF）
            for (let file of fileInput.files) {
                formData.append('file', file);
            }
        } else {
            // 单文件上传
            formData.append('file', fileInput.files[0]);
        }

        progressFill.style.width = '20%';
        progressText.textContent = '上传文件中...';

        const uploadResponse = await fetch('/api/upload', {
            method: 'POST',
            body: formData
        });

        if (!uploadResponse.ok) {
            throw new Error('文件上传失败');
        }

        const uploadData = await uploadResponse.json();
        const taskId = uploadData.task_id;

        // 存储任务ID
        taskData[convertType] = taskId;

        // 步骤2: 开始转换
        progressFill.style.width = '40%';
        progressText.textContent = '转换中...';

        // 获取选项
        const options = {};
        if (convertType === 'pdf_to_images') {
            const mode = card.querySelector('input[name="pdf_to_images_mode"]:checked').value;
            options.mode = mode;
        }

        const convertResponse = await fetch('/api/convert', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                task_id: taskId,
                convert_type: convertType,
                options: options
            })
        });

        if (!convertResponse.ok) {
            const errorData = await convertResponse.json();
            throw new Error(errorData.error || '转换失败');
        }

        const convertData = await convertResponse.json();

        // 步骤3: 模拟进度
        progressFill.style.width = '80%';
        progressText.textContent = '转换完成，准备下载...';

        // 等待一下让用户看到进度
        await new Promise(resolve => setTimeout(resolve, 500));

        // 步骤4: 下载文件
        progressFill.style.width = '100%';
        progressText.textContent = '正在下载...';

        const downloadUrl = `/api/download/${taskId}`;
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.download = convertData.filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        // 等待下载完成
        await new Promise(resolve => setTimeout(resolve, 1000));

        // 步骤5: 清理服务器文件
        progressText.textContent = '清理中...';
        await fetch(`/api/cleanup/${taskId}`, {
            method: 'DELETE'
        });

        // 完成
        progressText.textContent = '转换完成！';
        progressFill.style.width = '100%';

        // 重置UI
        setTimeout(() => {
            progressContainer.style.display = 'none';
            convertBtn.disabled = false;
            convertBtn.textContent = '开始转换';
            fileInput.value = '';
            const label = fileInput.nextElementSibling;
            label.classList.remove('file-selected');
            // 重置标签文本
            const labelFor = label.getAttribute('for');
            if (labelFor === 'pdf_to_word_file') {
                label.textContent = '选择PDF文件';
            } else if (labelFor === 'word_to_pdf_file') {
                label.textContent = '选择Word文件';
            } else if (labelFor === 'pdf_to_images_file') {
                label.textContent = '选择PDF文件';
            } else if (labelFor === 'images_to_pdf_file') {
                label.textContent = '选择图像文件或ZIP';
            }
        }, 2000);

    } catch (error) {
        console.error('转换错误:', error);
        progressText.textContent = `错误: ${error.message}`;
        progressFill.style.width = '0%';
        convertBtn.disabled = false;
        convertBtn.textContent = '开始转换';
        alert(`转换失败: ${error.message}`);
    }
}
