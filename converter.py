import os
import zipfile
import tempfile
from PIL import Image
import img2pdf
from pdf2image import convert_from_path
from pdf2docx import Converter as Pdf2DocxConverter
from docx import Document
import io
from config import OUTPUT_FOLDER, PDF_DPI, IMAGE_QUALITY

class Converter:
    def __init__(self):
        self.output_folder = OUTPUT_FOLDER
    
    def convert(self, input_path, convert_type, options, task_id):
        """执行文件转换"""
        output_path = None
        
        if convert_type == 'pdf_to_word':
            output_path = self.pdf_to_word(input_path, task_id)
        
        elif convert_type == 'word_to_pdf':
            output_path = self.word_to_pdf(input_path, task_id)
        
        elif convert_type == 'pdf_to_images':
            output_path = self.pdf_to_images(input_path, task_id, options)
        
        elif convert_type == 'images_to_pdf':
            output_path = self.images_to_pdf(input_path, task_id)
        
        if output_path:
            return {
                'success': True,
                'output_path': output_path,
                'filename': os.path.basename(output_path)
            }
        else:
            raise Exception('转换失败')
    
    def pdf_to_word(self, pdf_path, task_id):
        """PDF转Word"""
        output_path = os.path.join(self.output_folder, f"{task_id}_output.docx")
        cv = Pdf2DocxConverter(pdf_path)
        cv.convert(output_path)
        cv.close()
        return output_path
    
    def word_to_pdf(self, docx_path, task_id):
        """Word转PDF"""
        output_path = os.path.join(self.output_folder, f"{task_id}_output.pdf")
        try:
            from docx2pdf import convert
            convert(docx_path, output_path)
        except Exception as e:
            # 如果docx2pdf不可用，尝试使用LibreOffice命令行
            import subprocess
            try:
                subprocess.run(['libreoffice', '--headless', '--convert-to', 'pdf', 
                              '--outdir', self.output_folder, docx_path], 
                             check=True, capture_output=True)
                # 重命名输出文件
                base_name = os.path.splitext(os.path.basename(docx_path))[0]
                temp_pdf = os.path.join(self.output_folder, f"{base_name}.pdf")
                if os.path.exists(temp_pdf):
                    os.rename(temp_pdf, output_path)
            except:
                raise Exception(f'Word转PDF失败: {str(e)}')
        return output_path
    
    def pdf_to_images(self, pdf_path, task_id, options):
        """PDF转图像"""
        images = convert_from_path(pdf_path, dpi=PDF_DPI)
        
        mode = options.get('mode', 'zip')  # 'zip' 或 'single'
        
        if mode == 'single':
            # 生成一张大拼图
            output_path = self._create_single_image(images, task_id)
        else:
            # 生成多张图片并压缩成zip
            output_path = self._create_image_zip(images, task_id)
        
        return output_path
    
    def _create_single_image(self, images, task_id):
        """创建单张大拼图"""
        if not images:
            raise Exception('PDF中没有页面')
        
        # 计算总尺寸
        max_width = max(img.width for img in images)
        total_height = sum(img.height for img in images)
        
        # 创建新图像
        combined = Image.new('RGB', (max_width, total_height), 'white')
        y_offset = 0
        
        for img in images:
            combined.paste(img, (0, y_offset))
            y_offset += img.height
        
        # 保存
        output_path = os.path.join(self.output_folder, f"{task_id}_output.png")
        combined.save(output_path, 'PNG', quality=IMAGE_QUALITY, optimize=True)
        
        return output_path
    
    def _create_image_zip(self, images, task_id):
        """创建图像zip文件"""
        zip_path = os.path.join(self.output_folder, f"{task_id}_output.zip")
        
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for i, img in enumerate(images, 1):
                # 压缩图像
                img_io = io.BytesIO()
                img.save(img_io, format='PNG', quality=IMAGE_QUALITY, optimize=True)
                img_io.seek(0)
                
                zipf.writestr(f"page_{i}.png", img_io.read())
        
        return zip_path
    
    def images_to_pdf(self, input_path, task_id):
        """图像转PDF"""
        output_path = os.path.join(self.output_folder, f"{task_id}_output.pdf")
        
        # 如果输入是zip文件，先解压
        if input_path.endswith('.zip'):
            # 解压到临时目录
            temp_dir = tempfile.mkdtemp()
            try:
                with zipfile.ZipFile(input_path, 'r') as zipf:
                    zipf.extractall(temp_dir)
                
                # 获取所有图像文件
                image_files = []
                for filename in sorted(os.listdir(temp_dir)):
                    if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp')):
                        image_files.append(os.path.join(temp_dir, filename))
                
                if not image_files:
                    raise Exception('ZIP文件中没有找到图像文件')
                
                # 使用img2pdf转换
                try:
                    with open(output_path, 'wb') as f:
                        f.write(img2pdf.convert(image_files))
                except:
                    # 如果img2pdf失败，使用PIL方法
                    images = [Image.open(f) for f in image_files]
                    rgb_images = []
                    for img in images:
                        if img.mode != 'RGB':
                            img = img.convert('RGB')
                        rgb_images.append(img)
                    rgb_images[0].save(output_path, 'PDF', resolution=100.0, save_all=True, append_images=rgb_images[1:])
            finally:
                # 清理临时目录
                import shutil
                shutil.rmtree(temp_dir, ignore_errors=True)
        else:
            # 单张图像
            try:
                with open(output_path, 'wb') as f:
                    f.write(img2pdf.convert([input_path]))
            except Exception as e:
                # 如果img2pdf失败，使用PIL方法
                try:
                    img = Image.open(input_path)
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                    # PIL保存PDF需要save_all参数
                    img.save(output_path, 'PDF', resolution=100.0, save_all=True)
                except Exception as e2:
                    raise Exception(f'图像转PDF失败: {str(e2)}')
        
        return output_path
    
