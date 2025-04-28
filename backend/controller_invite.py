"""This module handles the functions related toi invites for database."""

from datetime import datetime, timezone
from uuid import uuid4

from error import BackendError
from utils import db_operation
from validator import Validator


class InviteController:
    """This class handels the invite functions for the database."""

    def __init__(self) -> None:
        """Initialize the InviteController class."""
        return

    def create_invite_control(
        self, inviter_id: str, invitee_id: str, group_id: str, password: str
    ) -> str:
        """This will invite a user to a group"""
        if not Validator().check_user_exists(user_id=inviter_id):
            raise BackendError("Backend Error: Inviter does not exist", "304")
        if not Validator().check_password(user_id=inviter_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_user_exists(user_id=invitee_id):
            raise BackendError("Backend Error: Invitee does not exist", "304")
        if not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_in_group(user_id=inviter_id, group_id=group_id):
            raise BackendError("Backend Error: Inviter is not in the group", "310")
        if Validator().check_user_in_group(user_id=invitee_id, group_id=group_id):
            raise BackendError("Backend Error: Invitee is already in the group", "307")
        if Validator().check_invite(invitee_id, group_id):
            raise BackendError("Backend Error: Invitee already has an invite.", "311")

        # Create invitation
        invite_id: str = str(uuid4())
        while Validator().check_duplicate_id("invite", invite_id):
            invite_id = str(uuid4())
        day_created: str = datetime.now(timezone.utc).isoformat()

        with db_operation() as data_cursor:
            data_cursor.execute(
                "INSERT INTO group_invites VALUES (?, ?, ?, ?, ?);",
                (invite_id, group_id, invitee_id, inviter_id, day_created),
            )
        return invite_id

    def get_pending_control(
        self,
        user_id: str,
        password: str,
    ) -> dict[str, dict]:
        """Gets all pending invites for a user"""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        invites: dict[str, dict] = {}
        with db_operation() as data_cursor:
            data_cursor.execute(
                (
                    "SELECT invite_id, inviter_id group_id, created_at "
                    "FROM group_invites WHERE invitee_id = ?;"
                ),
                (user_id,),
            )
            invites_data: list[tuple] = data_cursor.fetchall()
            for invite_item in invites_data:
                invite_id: str = invite_item[0]
                inviter_id: str = invite_item[1]
                group_id: str = invite_item[2]
                created_at: str = invite_item[3]
                data_cursor.execute(
                    "SELECT name FROM task_group WHERE uuid = ?;",
                    (group_id),
                )
                group_name: str = data_cursor.fetchone()[0]
                data_cursor.execute(
                    "SELECT username FROM user WHERE uuid = ?;",
                    (inviter_id),
                )
                inviter_name: str = data_cursor.fetchone()[0]
                invites[invite_id] = {
                    "invite_id": invite_id,
                    "group_id": group_id,
                    "group_name": group_name,
                    "inviter_id": inviter_id,
                    "inviter_name": inviter_name,
                    "created_at": created_at,
                }
        return invites

    def sent_invite_control(
        self,
        user_id: str,
        group_id: str,
        password: str,
    ) -> dict[str, dict]:
        """Checks what invites has group sent."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_in_group(user_id=user_id, group_id=group_id):
            raise BackendError("Backend Error: User is not in the group", "310")
        invites: dict[str, dict] = {}
        with db_operation() as data_cursor:
            data_cursor.execute(
                (
                    "SELECT invite_id, inviter_id, invitee_id, created_at "
                    "FROM group_invites WHERE group_id = ?;"
                ),
                (group_id,),
            )
            invites_data: list[tuple] = data_cursor.fetchall()
            for invite_item in invites_data:
                invite_id: str = invite_item[0]
                inviter_id: str = invite_item[1]
                invitee_id: str = invite_item[2]
                created_at: str = invite_item[3]
                data_cursor.execute(
                    "SELECT username FROM user WHERE uuid = ?;",
                    (invitee_id),
                )
                invitee_name: str = data_cursor.fetchone()[0]
                data_cursor.execute(
                    "SELECT name FROM user WHERE uuid = ?;",
                    (inviter_id),
                )
                inviter_name: str = data_cursor.fetchone()[0]
                invites[invite_id] = {
                    "invite_id": invite_id,
                    "inviter_id": inviter_id,
                    "inviter_name": inviter_name,
                    "invitee_id": invitee_id,
                    "invitee_name": invitee_name,
                    "created_at": created_at,
                }
        return invites

    def respond_invite_control(
        self,
        user_id: str,
        group_id: str,
        password: str,
        accept: bool = True,
    ) -> None:
        """Accepts an invite"""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id, password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_invite(invitee_id=user_id, group_id=group_id):
            raise BackendError("Backend Error: Invite does not exist", "308")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT invite_id FROM group_invites WHERE group_id = ?;",
                (group_id,),
            )
            invite_id: str = data_cursor.fetchone()[0]
            if accept:
                data_cursor.execute(
                    "INSERT INTO group_user VALUES (?, ?, ?);",
                    (group_id, user_id, "member"),
                )
            data_cursor.execute(
                "DELETE FROM group_invites WHERE invite_id = ?;",
                (invite_id,),
            )

    def delete_invite_control(
        self, user_id: str, invitee_id: str, group_id: str, password: str
    ) -> None:
        """Deletes an invite"""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: Inviter does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_user_exists(user_id=invitee_id):
            raise BackendError("Backend Error: Invitee does not exist", "304")
        if not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_in_group(user_id=user_id, group_id=group_id):
            raise BackendError("Backend Error: Inviter is not in the group", "310")
        if not Validator().check_invite(invitee_id=invitee_id, group_id=group_id):
            raise BackendError("Backend Error: Invite does not exist", "308")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT invite_id FROM group_invites WHERE group_id = ?;",
                (group_id,),
            )
            invite_id: str = data_cursor.fetchone()[0]
            data_cursor.execute(
                "DELETE FROM group_invites WHERE invite_id = ?;",
                (invite_id,),
            )


if __name__ == "__main__":
    print("This module is not intended to be run directly.")
