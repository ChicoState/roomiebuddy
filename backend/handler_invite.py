# coding: utf-8
"""Ths will hold the invite handling functions."""

from typing import Any

from flask import Request
from error import BackendError, handle_backend_exceptions
from controller_invite import InviteController
from utils import extract_request_data


class InviteHandle:
    """Class to handle invite related tasks."""

    def __init__(self, input_request: Request) -> None:
        """Initialize the handler."""
        self.user_request: Request = input_request
        if self.user_request.method != "POST":
            raise BackendError(
                message="Wrong request type!",
                error_code="100",
            )

    @handle_backend_exceptions
    def create_invite_request(self) -> str:
        """Handle the invite."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "inviter_id",
                "invitee_id",
                "group_id",
                "password",
            ],
        )
        inviter_id: str = request_data["inviter_id"]
        invitee_id: str = request_data["invitee_id"]
        group_id: str = request_data["group_id"]
        password: str = request_data["password"]
        return InviteController().create_invite_control(
            inviter_id=inviter_id,
            invitee_id=invitee_id,
            group_id=group_id,
            password=password,
        )

    @handle_backend_exceptions
    def respond_invite_request(self) -> None:
        """Handle the invite."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "user_id",
                "group_id",
                "password",
                "accept",
            ],
        )
        user_id: str = request_data["user_id"]
        group_id: str = request_data["group_id"]
        password: str = request_data["password"]
        accept: bool = request_data["accept"]
        return InviteController().respond_invite_control(
            user_id=user_id,
            group_id=group_id,
            password=password,
            accept=accept,
        )

    @handle_backend_exceptions
    def get_pending_request(self) -> dict[str, dict[str, Any]]:
        """Get the pending invites."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "user_id",
                "password",
            ],
        )
        user_id: str = request_data["user_id"]
        password: str = request_data["password"]
        return InviteController().get_pending_control(
            user_id=user_id,
            password=password,
        )

    @handle_backend_exceptions
    def delete_invite_request(self) -> None:
        """Delete the invite."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "user_id",
                "invitee_id",
                "group_id",
                "password",
            ],
        )
        user_id: str = request_data["user_id"]
        invitee_id: str = request_data["invitee_id"]
        group_id: str = request_data["group_id"]
        password: str = request_data["password"]
        return InviteController().delete_invite_control(
            user_id=user_id,
            invitee_id=invitee_id,
            group_id=group_id,
            password=password,
        )

    @handle_backend_exceptions
    def sent_invite_request(self) -> dict[str, dict[str, Any]]:
        """Get the sent invites."""
        request_data: dict[str, Any] = extract_request_data(
            request=self.user_request,
            required_fields=[
                "user_id",
                "group_id",
                "password",
            ],
        )
        user_id: str = request_data["user_id"]
        group_id: str = request_data["group_id"]
        password: str = request_data["password"]
        return InviteController().sent_invite_control(
            user_id=user_id,
            group_id=group_id,
            password=password,
        )


if __name__ == "__main__":
    print("This file is not meant to be run directly.")
