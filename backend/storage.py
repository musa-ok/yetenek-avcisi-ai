import os
import uuid
from typing import Optional
from fastapi import UploadFile, HTTPException
from dotenv import load_dotenv
import boto3
from botocore.exceptions import NoCredentialsError, ClientError

load_dotenv()

class StorageService:
    """Cloud storage service for video files"""
    
    def __init__(self):
        self.use_s3 = os.getenv("AWS_ACCESS_KEY_ID") and os.getenv("AWS_SECRET_ACCESS_KEY")
        
        if self.use_s3:
            self.s3_client = boto3.client(
                's3',
                aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
                aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
                region_name=os.getenv("AWS_REGION", "us-east-1")
            )
            self.bucket_name = os.getenv("S3_BUCKET_NAME")
            if not self.bucket_name:
                raise ValueError("S3_BUCKET_NAME environment variable is required when using S3")
        else:
            # Fallback to local storage
            self.local_storage_path = os.getenv("LOCAL_STORAGE_PATH", "static/videos")
            os.makedirs(self.local_storage_path, exist_ok=True)
    
    async def upload_video(self, file: UploadFile, filename: Optional[str] = None) -> str:
        """Upload video file and return the URL/path"""
        
        if not filename:
            # Generate unique filename
            file_extension = os.path.splitext(file.filename)[1] if file.filename else '.mp4'
            filename = f"{uuid.uuid4()}{file_extension}"
        
        try:
            file_content = await file.read()
            
            if self.use_s3:
                return await self._upload_to_s3(file_content, filename)
            else:
                return await self._upload_to_local(file_content, filename)
                
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")
    
    async def _upload_to_s3(self, file_content: bytes, filename: str) -> str:
        """Upload file to S3"""
        try:
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=filename,
                Body=file_content,
                ContentType='video/mp4'
            )
            
            # Return S3 URL
            return f"https://{self.bucket_name}.s3.{os.getenv('AWS_REGION', 'us-east-1')}.amazonaws.com/{filename}"
            
        except NoCredentialsError:
            raise HTTPException(status_code=500, detail="AWS credentials not found")
        except ClientError as e:
            raise HTTPException(status_code=500, detail=f"S3 upload failed: {str(e)}")
    
    async def _upload_to_local(self, file_content: bytes, filename: str) -> str:
        """Upload file to local storage"""
        file_path = os.path.join(self.local_storage_path, filename)
        
        with open(file_path, "wb") as f:
            f.write(file_content)
        
        # Return relative URL for local development
        return f"/static/videos/{filename}"
    
    async def delete_file(self, file_url: str) -> bool:
        """Delete file from storage"""
        try:
            if self.use_s3 and file_url.startswith("https://"):
                # Extract filename from S3 URL
                filename = file_url.split("/")[-1]
                self.s3_client.delete_object(Bucket=self.bucket_name, Key=filename)
            else:
                # Local file deletion
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
