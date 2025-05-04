# coding: utf-8
"""This will hold the information with task handle."""

from typing import Any

from flask import Request
from error import BackendError, handle_backend_exceptions
from controller_task import TaskController
from utils import extract_request_data


class TaskHandle:
    """This class will handle the task."""

    def __init__(self, input_request: Request) -> None:
        """ ""This will initialize the task handle."""
        self.user_request: Request = input_request
        if self.user_request.method != "POST":
            raise BackendError(
                message="Wrong request type!",
                error_code="100",
            )

    @handle_backend_exceptions
    def add_task_request(self) -> str:
        """This will add a task."""

        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "task_name",
                "assigner_id",
                "assign_id",
                "group_id",
                "password",
            ],
        )
        return TaskController().add_task_control(
            request_data=request_data,
        )

    @handle_backend_exceptions
    def edit_task_request(self) -> None:
        """Edits a task."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "task_id",
                "task_name",
                "assigner_id",
                "assign_id",
                "group_id",
                "password",
            ],
        )
        TaskController().edit_task_control(
            request_data=request_data,
        )

    @handle_backend_exceptions
    def delete_task_request(self) -> None:
        """Deletes a task."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=["task_id", "user_id", "password"],
        )
        task_id: str = request_data["task_id"]
        user_id: str = request_data["user_id"]
        password: str = request_data["password"]
        return TaskController().delete_task_control(
            user_id=user_id,
            task_id=task_id,
            password=password,
        )

    @handle_backend_exceptions
    def get_user_task_request(self) -> dict[str, dict[str, Any]]:
        """Gets the user task."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=["user_id", "password"],
        )
        user_id: str = request_data["user_id"]
        password: str = request_data["password"]
        return TaskController().get_user_task_control(
            user_id=user_id, password=password
        )


if __name__ == "__main__":
    print("This is a module and should not be run directly.")
