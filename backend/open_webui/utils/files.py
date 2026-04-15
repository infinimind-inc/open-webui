from open_webui.routers.images import (
    get_image_data,
    upload_image,
)

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Request,
    UploadFile,
)
from typing import Optional
from pathlib import Path
from urllib.parse import urlparse, unquote
import os

from open_webui.storage.provider import Storage

from open_webui.models.chats import Chats
from open_webui.models.files import Files
from open_webui.routers.files import upload_file_handler
from open_webui.retrieval.web.utils import validate_url

import mimetypes
import base64
import io
import re

import requests
import boto3
from botocore.config import Config

from open_webui.config import (
    S3_ACCESS_KEY_ID,
    S3_SECRET_ACCESS_KEY,
    S3_REGION_NAME,
    S3_ENDPOINT_URL,
    S3_USE_ACCELERATE_ENDPOINT,
    S3_ADDRESSING_STYLE,
)

BASE64_IMAGE_URL_PREFIX = re.compile(r"data:image/\w+;base64,", re.IGNORECASE)
MARKDOWN_IMAGE_URL_PATTERN = re.compile(r"!\[(.*?)\]\((.+?)\)", re.IGNORECASE)
S3_URL_PATTERN = re.compile(r"^s3://([^/]+)/(.+)$", re.IGNORECASE)


def _get_s3_client():
    config = Config(
        s3={
            "use_accelerate_endpoint": S3_USE_ACCELERATE_ENDPOINT,
            "addressing_style": S3_ADDRESSING_STYLE,
        }
    )
    if S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY:
        return boto3.client(
            "s3",
            region_name=S3_REGION_NAME,
            endpoint_url=S3_ENDPOINT_URL,
            aws_access_key_id=S3_ACCESS_KEY_ID,
            aws_secret_access_key=S3_SECRET_ACCESS_KEY,
            config=config,
        )
    return boto3.client(
        "s3",
        region_name=S3_REGION_NAME,
        endpoint_url=S3_ENDPOINT_URL,
        config=config,
    )


def _is_path_allowed(path: str, allowed_paths: list[str]) -> bool:
    if not allowed_paths:
        return True
    real_path = os.path.realpath(path)
    for base in allowed_paths:
        base_real = os.path.realpath(base)
        if base_real == os.path.commonpath(base_real, real_path):
            return True
    return False


def _build_data_uri(content: bytes, content_type: Optional[str]) -> Optional[str]:
    if not content:
        return None
    encoded = base64.b64encode(content).decode("utf-8")
    fallback_type = content_type or "application/octet-stream"
    return f"data:{fallback_type};base64,{encoded}"


def get_media_base64_from_url(
    url: str,
    max_size_mb: Optional[int] = None,
    allowed_paths: Optional[list[str]] = None,
) -> Optional[str]:
    try:
        if not url:
            return None

        if url.startswith("http"):
            validate_url(url)
            response = requests.get(url, stream=True)
            response.raise_for_status()
            content_length = response.headers.get("Content-Length")
            if content_length and max_size_mb:
                if int(content_length) > max_size_mb * 1024 * 1024:
                    return None
            content = response.content
            if max_size_mb and len(content) > max_size_mb * 1024 * 1024:
                return None
            content_type = response.headers.get("Content-Type")
            return _build_data_uri(content, content_type)

        if url.startswith("s3://"):
            match = S3_URL_PATTERN.match(url)
            if not match:
                return None
            bucket_name, key = match.groups()
            client = _get_s3_client()
            head = client.head_object(Bucket=bucket_name, Key=key)
            content_length = head.get("ContentLength")
            if content_length and max_size_mb:
                if int(content_length) > max_size_mb * 1024 * 1024:
                    return None
            obj = client.get_object(Bucket=bucket_name, Key=key)
            content = obj["Body"].read()
            if max_size_mb and len(content) > max_size_mb * 1024 * 1024:
                return None
            content_type = obj.get("ContentType") or mimetypes.guess_type(key)[0]
            return _build_data_uri(content, content_type)

        parsed = urlparse(url)
        if parsed.scheme == "file" or os.path.isabs(url):
            # Local filesystem reads are opt-in. Require a non-empty allowlist.
            if not allowed_paths:
                return None

            path = unquote(parsed.path) if parsed.scheme == "file" else url
            if not _is_path_allowed(path, allowed_paths):
                return None
            if not os.path.isfile(path):
                return None
            if max_size_mb and os.path.getsize(path) > max_size_mb * 1024 * 1024:
                return None
            with open(path, "rb") as media_file:
                content = media_file.read()
            content_type, _ = mimetypes.guess_type(path)
            return _build_data_uri(content, content_type)

        file = Files.get_file_by_id(url)
        if not file:
            return None

        if not file.path:
            return None

        file_path = Storage.get_file(file.path)
        file_path = Path(file_path)
        if not file_path.is_file():
            return None

        with open(file_path, "rb") as media_file:
            content = media_file.read()
        if max_size_mb and len(content) > max_size_mb * 1024 * 1024:
            return None
        content_type, _ = mimetypes.guess_type(file_path.name)
        return _build_data_uri(content, content_type)

    except Exception:
        return None


def get_image_base64_from_url(url: str) -> Optional[str]:
    return get_media_base64_from_url(url)


def get_image_url_from_base64(request, base64_image_string, metadata, user):
    if BASE64_IMAGE_URL_PREFIX.match(base64_image_string):
        image_url = ''
        # Extract base64 image data from the line
        image_data, content_type = get_image_data(base64_image_string)
        if image_data is not None:
            _, image_url = upload_image(
                request,
                image_data,
                content_type,
                metadata,
                user,
            )

        return image_url
    return None


def convert_markdown_base64_images(request, content: str, metadata, user):
    def replace(match):
        base64_string = match.group(2)
        MIN_REPLACEMENT_URL_LENGTH = 1024
        if len(base64_string) > MIN_REPLACEMENT_URL_LENGTH:
            url = get_image_url_from_base64(request, base64_string, metadata, user)
            if url:
                return f'![{match.group(1)}]({url})'
        return match.group(0)

    return MARKDOWN_IMAGE_URL_PATTERN.sub(replace, content)


def load_b64_audio_data(b64_str):
    try:
        if ',' in b64_str:
            header, b64_data = b64_str.split(',', 1)
        else:
            b64_data = b64_str
            header = 'data:audio/wav;base64'
        audio_data = base64.b64decode(b64_data)
        content_type = (
            header.split(';')[0].split(':')[1] if ';' in header else 'audio/wav'
        )
        return audio_data, content_type
    except Exception as e:
        print(f'Error decoding base64 audio data: {e}')
        return None, None


def upload_audio(request, audio_data, content_type, metadata, user):
    audio_format = mimetypes.guess_extension(content_type)
    file = UploadFile(
        file=io.BytesIO(audio_data),
        filename=f'generated-{audio_format}',  # will be converted to a unique ID on upload_file
        headers={
            'content-type': content_type,
        },
    )
    file_item = upload_file_handler(
        request,
        file=file,
        metadata=metadata,
        process=False,
        user=user,
    )
    url = request.app.url_path_for('get_file_content_by_id', id=file_item.id)
    return url


def get_audio_url_from_base64(request, base64_audio_string, metadata, user):
    if 'data:audio/wav;base64' in base64_audio_string:
        audio_url = ''
        # Extract base64 audio data from the line
        audio_data, content_type = load_b64_audio_data(base64_audio_string)
        if audio_data is not None:
            audio_url = upload_audio(
                request,
                audio_data,
                content_type,
                metadata,
                user,
            )
        return audio_url
    return None


def get_file_url_from_base64(request, base64_file_string, metadata, user):
    if BASE64_IMAGE_URL_PREFIX.match(base64_file_string):
        return get_image_url_from_base64(request, base64_file_string, metadata, user)
    elif 'data:audio/wav;base64' in base64_file_string:
        return get_audio_url_from_base64(request, base64_file_string, metadata, user)
    return None


def get_image_base64_from_file_id(id: str) -> Optional[str]:
    file = Files.get_file_by_id(id)
    if not file:
        return None

    if not file.path:
        return None

    try:
        file_path = Storage.get_file(file.path)
        file_path = Path(file_path)

        # Check if the file already exists in the cache
        if file_path.is_file():
            import base64

            with open(file_path, 'rb') as image_file:
                encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
                content_type, _ = mimetypes.guess_type(file_path.name)
                return f'data:{content_type};base64,{encoded_string}'
        else:
            return None
    except Exception as e:
        return None
