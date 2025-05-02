# coding: utf-8
"""This module handles user-related operations."""

from typing import Any

from flask import Request
from error import BackendError, handle_backend_exceptions
from controller_user import UserController
from utils import extract_request_data


class UserHandle:
    """Class to handle user operations."""

    def __init__(self, input_request: Request) -> None:
        """Initialize the UserHandle class with a request object."""
        self.user_request: Request = input_request
        if self.user_request.method != "POST":
            raise BackendError(
                message="Wrong request type!",
                error_code="100",
            )

    @handle_backend_exceptions
    def add_user_request(self) -> str:
        """Adds a new user to the database."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "username",
                "email",
                "password",
            ],
        )
        username: str = request_data["username"]
        email: str = request_data["email"]
        password: str = request_data["password"]
        user_id: str = UserController().add_user_control(
            username=username, email=email, password=password
        )
        return user_id

    @handle_backend_exceptions
    def login_user_request(self) -> dict[str, str]:
        """ "Logs in a user."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "email",
                "password",
            ],
        )
        email: str = request_data["email"]
        password: str = request_data["password"]
        user_info: dict[str, str] = UserController().login_user_control(email=email, password=password)
        return user_info

    @handle_backend_exceptions
    def edit_user_request(self) -> None:
        """ "Edits user information."""

        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "user_id",
                "username",
                "email",
                "password",
                "new_password",
            ],
        )
        UserController().edit_user_control(request_data=request_data)

    @handle_backend_exceptions
    def delete_user_request(self) -> None:
        """ "Deletes a user."""

        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "user_id",
                "password",
            ],
        )
        user_id: str = request_data["user_id"]
        password: str = request_data["password"]
        UserController().delete_user_control(
            user_id=user_id,
            password=password,
        )


if __name__ == "__main__":
    print("This is a module for handling user operations.")
