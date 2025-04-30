# coding: utf-8
"""This will hold the group handle class."""

from typing import Any
from flask import Request
from error import BackendError, handle_backend_exceptions
from controller_group import GroupController
from utils import extract_request_data


class GroupHandle:
    """This class handles the group-related operations."""

    def __init__(self, input_request: Request) -> None:
        """Initialize the group handle with the request."""
        self.user_request: Request = input_request
        if self.user_request.method != "POST":
            raise BackendError(
                message="Wrong request type!",
                error_code="100",
            )

    @handle_backend_exceptions
    def get_group_list_request(self) -> dict[str, dict[str, Any]]:
        """Get the group list for the user."""
        request_data = extract_request_data(
            request=self.user_request, required_fields=["user_id", "password"]
        )
        user_id = request_data["user_id"]
        password = request_data["password"]
        return GroupController().get_group_control(user_id=user_id, password=password)

    @handle_backend_exceptions
    def create_group_request(self) -> str:
        """Create a group for the user."""
        request_data = extract_request_data(
            request=self.user_request,
            required_fields=["user_id", "password", "group_name"],
        )
        user_id = request_data["user_id"]
        password = request_data["password"]
        group_name = request_data["group_name"]
        description = request_data.get("description", "")
        return GroupController().create_group_control(
            user_id=user_id,
            password=password,
            description=description,
            group_name=group_name,
        )

    @handle_backend_exceptions
    def leave_group_request(self) -> None:
        """Leave a group for the user."""
        request_data = extract_request_data(
            request=self.user_request,
            required_fields=["user_id", "password", "group_id"],
        )
        user_id = request_data["user_id"]
        password = request_data["password"]
        group_id = request_data["group_id"]
        GroupController().leave_group_control(
            user_id=user_id, group_id=group_id, password=password
        )

    @handle_backend_exceptions
    def delete_group_request(self) -> None:
        """Delete a group."""
        request_data = extract_request_data(
            request=self.user_request,
            required_fields=["user_id", "password", "group_id"],
        )
        user_id = request_data["user_id"]
        password = request_data["password"]
        group_id = request_data["group_id"]
        GroupController().delete_group_control(
            user_id=user_id, group_id=group_id, password=password
        )

    @handle_backend_exceptions
    def get_group_members_request(self) -> list[dict]:
        """Get all members of a specific group."""
        request_data = extract_request_data(
            request=self.user_request,
            required_fields=["user_id", "group_id", "password"],
        )
        user_id = request_data["user_id"]
        group_id = request_data["group_id"]
        password = request_data["password"]
        return GroupController().get_group_members_control(
            user_id=user_id, group_id=group_id, password=password
        )


if __name__ == "__main__":
    print("This is a module and should not be run directly.")
