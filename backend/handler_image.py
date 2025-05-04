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

    # @handle_backend_exceptions
    # def get_image_request(self) -> str:
    #     """Downloads an image."""
    #     request_data: dict[str, Any] = extract_request_data(
    #         request=self.user_request,
    #         required_fields=[
    #             "image_url",
    #             "user_id",
    #             "password",
    #         ],
    #     )
    #     return ImageController().get_image_control(
    #         image_url=request_data["image_url"],
    #         user_id=request_data["user_id"],
    #         password=request_data["password"],
    #         group_id=request_data.get("group_id", "0"),
    #     )

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
            ],
        )
        return ImageController().get_task_image_control(
            image_url=request_data["image_url"],
            user_id=request_data["user_id"],
            password=request_data["password"],
            task_id=request_data["task_id"],
            group_id=request_data.get("group_id", "0"),
        )


if __name__ == "__main__":
    print("This module is not meant to be run directly.")
