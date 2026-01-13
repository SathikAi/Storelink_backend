import os
import uuid
from typing import Optional, Tuple
from fastapi import UploadFile, HTTPException, status
from PIL import Image
import io
from app.config import settings


class FileUploadService:
    
    ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
    ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    MAX_IMAGE_SIZE = settings.MAX_FILE_SIZE
    
    @staticmethod
    def validate_image(file: UploadFile) -> None:
        if not file.content_type in FileUploadService.ALLOWED_MIME_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid file type. Allowed types: {', '.join(FileUploadService.ALLOWED_MIME_TYPES)}"
            )
        
        file_ext = os.path.splitext(file.filename)[1].lower()
        if file_ext not in FileUploadService.ALLOWED_IMAGE_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid file extension. Allowed extensions: {', '.join(FileUploadService.ALLOWED_IMAGE_EXTENSIONS)}"
            )
    
    @staticmethod
    async def save_image(file: UploadFile, folder: str = "logos", max_width: int = 800) -> Tuple[str, str]:
        FileUploadService.validate_image(file)
        
        contents = await file.read()
        
        if len(contents) > FileUploadService.MAX_IMAGE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File size exceeds maximum allowed size of {FileUploadService.MAX_IMAGE_SIZE / 1024 / 1024}MB"
            )
        
        try:
            image = Image.open(io.BytesIO(contents))
            
            if image.width > max_width:
                ratio = max_width / image.width
                new_height = int(image.height * ratio)
                image = image.resize((max_width, new_height), Image.LANCZOS)
            
            file_extension = os.path.splitext(file.filename)[1].lower()
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            
            upload_folder = os.path.join(settings.UPLOAD_DIR, folder)
            os.makedirs(upload_folder, exist_ok=True)
            
            file_path = os.path.join(upload_folder, unique_filename)
            
            if file_extension in [".jpg", ".jpeg"]:
                image = image.convert("RGB")
                image.save(file_path, "JPEG", quality=85, optimize=True)
            elif file_extension == ".png":
                image.save(file_path, "PNG", optimize=True)
            elif file_extension == ".webp":
                image.save(file_path, "WEBP", quality=85)
            else:
                image.save(file_path)
            
            relative_path = f"{folder}/{unique_filename}"
            return file_path, relative_path
            
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid image file or processing error: {str(e)}"
            )
    
    @staticmethod
    def delete_file(file_path: str) -> bool:
        try:
            full_path = os.path.join(settings.UPLOAD_DIR, file_path) if not file_path.startswith(settings.UPLOAD_DIR) else file_path
            if os.path.exists(full_path):
                os.remove(full_path)
                return True
            return False
        except Exception:
            return False
    
    @staticmethod
    def get_file_url(relative_path: Optional[str]) -> Optional[str]:
        if not relative_path:
            return None
        return f"/uploads/{relative_path}"
