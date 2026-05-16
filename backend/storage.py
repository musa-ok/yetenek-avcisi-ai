import os
import uuid
import io
from typing import Optional
from fastapi import UploadFile, HTTPException
from dotenv import load_dotenv

load_dotenv()

# Cloudinary setup
try:
    import cloudinary
    import cloudinary.uploader
    _cld_url = os.getenv("CLOUDINARY_URL", "")
    if _cld_url:
        cloudinary.config(cloudinary_url=_cld_url)
        _use_cloudinary = True
        print("[StorageService] Cloudinary aktif")
    else:
        _use_cloudinary = False
        print("[StorageService] Cloudinary URL yok, local storage kullanılıyor")
except ImportError:
    _use_cloudinary = False
    print("[StorageService] cloudinary paketi yok, local storage kullanılıyor")


class StorageService:
    """Cloud storage service for video files"""

    def __init__(self):
        self.local_storage_path = os.getenv("LOCAL_STORAGE_PATH", "static/videos")
        os.makedirs(self.local_storage_path, exist_ok=True)

    async def upload_video(self, file: UploadFile, filename: Optional[str] = None) -> str:
        """Upload video file and return the URL/path"""
        file_extension = os.path.splitext(file.filename)[1] if file.filename else '.mp4'
        if not filename:
            filename = f"{uuid.uuid4()}{file_extension}"

        try:
            file_content = await file.read()

            if _use_cloudinary:
                return self._upload_to_cloudinary(file_content, filename)
            else:
                return self._upload_to_local(file_content, filename)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

    def _upload_to_cloudinary(self, file_content: bytes, filename: str) -> str:
        """Upload file to Cloudinary"""
        public_id = f"videos/{filename}"
        result = cloudinary.uploader.upload(
            io.BytesIO(file_content),
            public_id=public_id,
            resource_type="video",
            overwrite=True,
        )
        return result["secure_url"]

    def _upload_to_local(self, file_content: bytes, filename: str) -> str:
        """Upload file to local storage"""
        file_path = os.path.join(self.local_storage_path, filename)
        with open(file_path, "wb") as f:
            f.write(file_content)
        return f"/static/videos/{filename}"

    async def delete_file(self, file_url: str) -> bool:
        """Delete file from storage"""
        try:
            if _use_cloudinary and file_url.startswith("https://res.cloudinary.com"):
                parts = file_url.split("/upload/")
                if len(parts) == 2:
                    public_id = parts[1].rsplit(".", 1)[0]
                    cloudinary.uploader.destroy(public_id, resource_type="video")
            else:
                if file_url.startswith("/static/videos/"):
                    filename = file_url.replace("/static/videos/", "")
                    file_path = os.path.join(self.local_storage_path, filename)
                    if os.path.exists(file_path):
                        os.remove(file_path)
            return True
        except Exception as e:
            print(f"Failed to delete file {file_url}: {str(e)}")
            return False


# Global storage service instance
storage_service = StorageService()
