# coding: utf-8
"""Handles image processing and storage."""

from typing import Any

from flask import Request
from error import BackendError, handle_backend_exceptions
from controller_image import ImageController
from utils import extract_request_data


class ImageHandle:
    """This class will handle the image."""

    def __init__(self, input_request: Request) -> None:
        """Initialize the image handle."""
        self.user_request: Request = input_request
        if self.user_request.method != "POST":
            raise BackendError(
                message="Wrong request type!",
                error_code="100",
            )

    @handle_backend_exceptions
    def get_user_image_request(self) -> str:
        """Gets the user image."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
            ],
        )
        return ImageController().get_user_image_control(
            image_url=request_data["image_url"],
            user_id=request_data["user_id"],
            password=request_data["password"],
        )

    @handle_backend_exceptions
    def get_task_image_request(self) -> str:
        """Gets the task image."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
                "task_id",
                "group_id",
            ],
        )
        return ImageController().get_task_image_control(
            request_data=request_data,
        )

    @handle_backend_exceptions
    def upload_user_image_request(self) -> str:
        """Uploads the user image."""
        if "file" not in self.user_request.files:
            raise BackendError(
                message="No file part in the request",
                error_code="314",
            )
        file = self.user_request.files["file"]
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
            ],
        )
        return ImageController().upload_user_image_control(
            user_id=request_data["user_id"],
            password=request_data["password"],
            file=file,
        )

    @handle_backend_exceptions
    def upload_task_image_request(self) -> str:
        """Uploads the task image."""
        if "file" not in self.user_request.files:
            raise BackendError(
                message="No file part in the request",
                error_code="314",
            )
        file = self.user_request.files["file"]
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
                "task_id",
                "group_id",
            ],
        )
        return ImageController().upload_task_image_control(
            request_data=request_data,
            file=file,
        )

    @handle_backend_exceptions
    def edit_user_image_request(self) -> str:
        """Edits the user image."""
        if "file" not in self.user_request.files:
            raise BackendError(
                message="No file part in the request",
                error_code="314",
            )
        file = self.user_request.files["file"]
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
            ],
        )
        return ImageController().edit_user_image_control(
            user_id=request_data["user_id"],
            password=request_data["password"],
            file=file,
        )

    @handle_backend_exceptions
    def edit_task_image_request(self) -> str:
        """Edits the task image."""
        if "file" not in self.user_request.files:
            raise BackendError(
                message="No file part in the request",
                error_code="314",
            )
        file = self.user_request.files["file"]
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
                "task_id",
                "group_id",
            ],
        )
        return ImageController().edit_task_image_control(
            request_data=request_data,
            file=file,
        )

    @handle_backend_exceptions
    def delete_user_image_request(self) -> None:
        """Deletes the user image."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
            ],
        )
        ImageController().delete_user_image_control(
            user_id=request_data["user_id"],
            password=request_data["password"],
        )

    @handle_backend_exceptions
    def delete_task_image_request(self) -> None:
        """Deletes the task image."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "image_url",
                "user_id",
                "password",
                "task_id",
                "group_id",
            ],
        )
        ImageController().delete_task_image_control(
            request_data=request_data,
        )


if __name__ == "__main__":
    print("This module is not meant to be run directly.")
