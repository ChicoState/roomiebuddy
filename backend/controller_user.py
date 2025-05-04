# coding: utf-8
"""This module handles the functions related to user for database."""

from os import remove
from os.path import exists

from typing import Any
from uuid import uuid4

from error import BackendError
from utils import db_operation
from validator import Validator


class UserController:
    """This class handles the user functions for the database."""

    def __init__(self) -> None:
        """Initialize the UserController class."""
        return

    def add_user_control(self, username: str, email: str, password: str) -> str:
        """This function creates a new user."""
        user_id: str = str(uuid4())
        while Validator().check_duplicate_id(data_table="user", given_id=user_id):
            user_id = str(uuid4())
        if Validator().check_username(username=username):
            raise BackendError("Backend Error: Username already exists", "301")
        if Validator().check_email(email=email):
            raise BackendError("Backend Error: Email already exists", "302")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "INSERT INTO user VALUES (?, ?, ?, ?, ?);",
                (user_id, username, email, password, ""),
            )
        return user_id

    def login_user_control(
        self,
        email: str,
        password: str,
    ) -> dict[str, str]:
        """This will login a user."""
        if not Validator().check_login(email=email, password=password):
            raise BackendError("Backend Error: Email or Password is incorrect", "303")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT uuid, username FROM user WHERE email = ?;",
                (email,),
            )
            user_data = data_cursor.fetchone()
        return {"user_id": user_data[0], "username": user_data[1]}

    def edit_user_control(
        self,
        request_data: dict[str, Any],
    ) -> None:
        """Edits a user information."""
        if not Validator().check_user_exists(user_id=request_data["user_id"]):
            raise BackendError("Backend Error: User does not exist", "304")
        if Validator().check_username(username=request_data["username"]):
            raise BackendError("Backend Error: Username already exists", "301")
        if Validator().check_email(email=request_data["email"]):
            raise BackendError("Backend Error: Email already exists", "302")
        if not Validator().check_password(
            user_id=request_data["user_id"], password=request_data["password"]
        ):
            raise BackendError("Backend Error: Password is incorrect", "305")
        with db_operation() as data_cursor:
            data_cursor.execute(
                (
                    "UPDATE user SET username = ?, email = ?, "
                    "password = ? WHERE uuid = ?;"
                ),
                (
                    request_data["username"],
                    request_data["email"],
                    request_data["password"],
                    request_data["user_id"],
                ),
            )

    def delete_user_control(
        self,
        user_id: str,
        password: str,
    ) -> None:
        """Deletes a user from the database."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT image_path FROM user WHERE uuid = ?;",
                (user_id,),
            )
            result = data_cursor.fetchone()
            if result and result[0]:
                image_path = result[0]
                if exists(image_path):
                    try:
                        remove(image_path)
                    except Exception as err:
                        raise BackendError(
                            "Backend Error: Unable to delete image.", "203"
                        ) from err

            data_cursor.execute(
                "DELETE FROM user WHERE uuid = ?;",
                (user_id,),
            )
            data_cursor.execute(
                "DELETE FROM group_user WHERE user_id = ?;",
                (user_id,),
            )
            data_cursor.execute(
                "DELETE FROM task WHERE assigner_uuid = ? OR assign_uuid = ?;",
                (user_id, user_id),
            )
            data_cursor.execute(
                "DELETE FROM group_invites WHERE inviter_id = ? OR invitee_id = ?;",
                (user_id, user_id),
            )

            # Potential BUggy Behavior CAREFUL

            # data_cursor.execute(
            #     "SELECT FROM task_group WHERE owner_id = ?;",
            #     (user_id,),
            # )

            # if len(data_cursor.fetchall()) == 0:
            #     data_con.commit()
            #     data_con.close()
            #     return

            # data_cursor.execute(
            #     "SELECT FROM group_user WHERE group_id = ? AND user_id = ?;",
            #     (user_id,),
            # )


if __name__ == "__main__":
    raise ImportError("This module is not intended to be run directly.")
