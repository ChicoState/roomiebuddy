# coding: utf-8
"""This module handles the functions related to group for database."""

from uuid import uuid4

from error import BackendError
from utils import db_operation
from validator import Validator


class GroupController:
    """This class handles the group functions for the database."""

    def __init__(self) -> None:
        """Initialize the GroupController class."""
        return

    def create_group_control(
        self,
        user_id: str,
        description: str,
        group_name: str,
        password: str,
    ) -> str:
        """This will create a group."""
        if not Validator().check_user_exists(user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        group_id: str = str(uuid4())
        while Validator().check_duplicate_id("group", group_id):
            group_id = str(uuid4())
        with db_operation() as data_cursor:
            data_cursor.execute(
                "INSERT INTO task_group VALUES (?, ?, ?, ?);",
                (group_id, group_name, description, user_id),
            )
            data_cursor.execute(
                "INSERT INTO group_user VALUES (?, ?, ?);",
                (group_id, user_id, None),
            )
        return group_id

    def add_user_to_group_control(
        self,
        user_id: str,
        group_id: str,
        password: str,
    ) -> None:
        """Adds a user to a group."""
        if not Validator().check_user_exists(user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_group_exists(group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if Validator().check_user_in_group(user_id, group_id):
            raise BackendError("Backend Error: User already in group", "307")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "INSERT INTO group_user VALUES (?, ?);",
                (group_id, user_id),
            )

    def leave_group_control(
        self,
        user_id: str,
        group_id: str,
        password: str,
    ) -> None:
        """Removes a user from a group"""
        if not Validator().check_user_exists(user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_group_exists(group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_in_group(user_id, group_id):
            raise BackendError("Backend Error: User not in group", "308")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "DELETE FROM group_user WHERE group_id = ? AND user_id = ?;",
                (group_id, user_id),
            )
            data_cursor.execute(
                "SELECT COUNT(*) FROM group_user WHERE group_id = ?;",
                (group_id,),
            )
            count = data_cursor.fetchone()[0]
            if count == 0:
                data_cursor.execute(
                    "DELETE FROM task_group WHERE uuid = ?;",
                    (group_id,),
                )
                data_cursor.execute(
                    "DELETE FROM group_invites WHERE group_id = ?;",
                    (group_id,),
                )

    def delete_group_control(
        self,
        user_id: str,
        group_id: str,
        password: str,
    ) -> None:
        """Deletes a group"""
        if not Validator().check_group_exists(group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_exists(user_id):
            raise BackendError("Backend Error: User does not exist in group", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_user_in_group(user_id, group_id):
            raise Exception("User is not a member of the group.")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM task_group WHERE uuid = ? AND owner_id = ?;",
                (group_id, user_id),
            )
            if data_cursor.fetchone() is None:
                raise BackendError(
                    "Backend Error: User is not the owner of the group", "308"
                )
            data_cursor.execute(
                "DELETE FROM task_group WHERE uuid = ?;",
                (group_id,),
            )
            data_cursor.execute(
                "DELETE FROM group_user WHERE group_id = ?;",
                (group_id,),
            )
            data_cursor.execute(
                "DELETE FROM group_invites WHERE group_id = ?;",
                (group_id,),
            )

    def get_group_control(
        self,
        user_id: str,
        password: str,
    ) -> dict[str, dict]:
        """Gets all groups a user is a member of and their members."""
        if not Validator().check_user_exists(user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        with db_operation() as data_cursor:
            data_cursor.execute(
                """
                SELECT group_id
                FROM group_user
                WHERE user_id = ?
                """,
                (user_id,),
            )
            group_ids = [row[0] for row in data_cursor.fetchall()]
            if not group_ids:
                return {}

            placeholders = ",".join("?" for _ in group_ids)
            data_cursor.execute(
                f"""
                SELECT uuid, name, description, owner_id
                FROM task_group
                WHERE uuid IN ({placeholders})
                """,
                group_ids,
            )
            groups_data = data_cursor.fetchall()

            groups: dict[str, dict] = {}
            for group in groups_data:
                group_id, name, description, owner_id = group
                data_cursor.execute(
                    """
                    SELECT user_id
                    FROM group_user
                    WHERE group_id = ?
                    """,
                    (group_id,),
                )
                user_ids = [row[0] for row in data_cursor.fetchall()]

                if user_ids:
                    placeholders = ",".join("?" for _ in user_ids)
                    data_cursor.execute(
                        f"""
                        SELECT uuid, username
                        FROM user
                        WHERE uuid IN ({placeholders})
                        """,
                        user_ids,
                    )
                    members_data = data_cursor.fetchall()
                else:
                    members_data = []
                members = [
                    {"user_id": member_id, "username": member_name}
                    for member_id, member_name in members_data
                ]

                groups[group_id] = {
                    "group_id": group_id,
                    "name": name,
                    "description": description,
                    "owner_id": owner_id,
                    "members": members,
                }
        return groups


if __name__ == "__main__":
    print("This is a module and should not be run directly.")
