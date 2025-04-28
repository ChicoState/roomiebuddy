# coding: utf-8
"""This function checks if the given data is valid."""

from utils import db_operation

from error import BackendError

CREATE_TASK_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS task"
    "(uuid TEXT PRIMARY KEY, name TEXT NOT NULL, "
    "description TEXT, due REAL, "
    "est_day INT, est_hour INT, "
    "est_min INT, assigner_uuid TEXT NOT NULL, "
    "assign_uuid TEXT NOT NULL, group_uuid TEXT NOT NULL, "
    "completed INT NOT NULL, priority INT, "
    "recursive INT, image_path TEXT);"
)
CREATE_USER_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS user"
    "(uuid TEXT PRIMARY KEY, username TEXT NOT NULL, "
    "email TEXT NOT NULL, password TEXT NOT NULL);"
)
CREATE_GROUP_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS task_group"
    "(uuid TEXT PRIMARY KEY, name TEXT NOT NULL, "
    "description TEXT, owner_id INT NOT NULL);"
)
CREATE_GROUP_USER_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS group_user"
    "(group_id TEXT NOT NULL, user_id TEXT NOT NULL, "
    "role_id TEXT);"
)
CREATE_GROUP_INVITES_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS group_invites"
    "(invite_id TEXT PRIMARY KEY, group_id TEXT NOT NULL, "
    "inviter_id TEXT NOT NULL, invitee_id TEXT NOT NULL, "
    "day_created REAL NOT NULL);"
)


class Validator:
    """This class checks if the given data is valid."""

    def __init__(self) -> None:
        """This function initializes the class."""
        return

    def initializer(self) -> None:
        """This function initializes to create the database."""

        with db_operation() as data_cursor:
            data_cursor.execute(CREATE_TASK_TABLE)
            data_cursor.execute(CREATE_USER_TABLE)
            data_cursor.execute(CREATE_GROUP_TABLE)
            data_cursor.execute(CREATE_GROUP_USER_TABLE)
            data_cursor.execute(CREATE_GROUP_INVITES_TABLE)

            if (
                len(data_cursor.execute("SELECT * FROM task;").description) != 14
                or len(data_cursor.execute("SELECT * FROM user;").description) != 4
                or len(data_cursor.execute("SELECT * FROM task_group;").description)
                != 4
                or len(data_cursor.execute("SELECT * FROM group_user;").description)
                != 3
                or len(data_cursor.execute("SELECT * FROM group_invites;").description)
                != 5
            ):
                raise BackendError(
                    "Backend Error: Not Been Configured Correctly, Ask Developers",
                    "201",
                )

    def check_user_exists(self, user_id: str) -> bool:
        """This function checks if the user exists."""
        with db_operation() as data_cursor:
            data_cursor.execute("SELECT * FROM user WHERE uuid = ?;", (user_id,))
            result = data_cursor.fetchone()
        return result is not None

    def check_group_exists(self, group_id: str) -> bool:
        """This function checks if the group exists."""
        with db_operation() as data_cursor:
            data_cursor.execute("SELECT * FROM task_group WHERE uuid = ?;", (group_id,))
            result = data_cursor.fetchone()
        return result is not None

    def check_task_exists(self, task_id: str) -> bool:
        """This function checks if the task exists."""
        with db_operation() as data_cursor:
            data_cursor.execute("SELECT * FROM task WHERE uuid = ?;", (task_id,))
            result = data_cursor.fetchone()
        return result is not None

    def check_user_in_group(self, user_id: str, group_id: str) -> bool:
        """This function checks if the user is in the group."""
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM group_user WHERE user_id = ? AND group_id = ?;",
                (user_id, group_id),
            )
            result = data_cursor.fetchone()
        return result is not None

    def check_duplicate_id(self, data_table: str, given_id: str) -> bool:
        """Checks if id is not in use."""
        with db_operation() as data_cursor:
            if data_table == "task":
                data_cursor.execute("SELECT * FROM task WHERE uuid = ?;", (given_id,))
            elif data_table == "user":
                data_cursor.execute("SELECT * FROM user WHERE uuid = ?;", (given_id,))
            elif data_table == "group":
                data_cursor.execute("SELECT * FROM task_group WHERE uuid = ?;", (given_id,))
            elif data_table == "invite":
                data_cursor.execute(
                    "SELECT * FROM group_invites WHERE invite_id = ?;", (given_id,)
                )
            result = data_cursor.fetchone()
        return result is not None

    def check_password(self, user_id: str, password: str) -> bool:
        """Checks if password is correct."""
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM user WHERE uuid = ? AND password = ?;",
                (user_id, password),
            )
            result = data_cursor.fetchone()
        return result is not None

    def check_login(self, email: str, password: str) -> bool:
        """Checks if the user entered the correct credentials."""
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM user WHERE email = ? AND password = ?;",
                (email, password),
            )
            result = data_cursor.fetchone()
        return result is not None

    def check_username(self, username: str) -> bool:
        """Checks if the username is already used."""
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM user WHERE username = ?;",
                (username,),
            )
            result = data_cursor.fetchone()
        return result is not None

    def check_email(self, email: str) -> bool:
        """Checks if the email is already used."""
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM user WHERE email = ?;",
                (email,),
            )
            result = data_cursor.fetchone()
        return result is not None

    def check_invite(
        self, invitee_id: str, group_id: str
    ) -> bool:
        """Checks if the invite exists."""
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM group_invites WHERE invitee_id = ? AND group_id = ?;",
                (invitee_id, group_id),
            )
            result = data_cursor.fetchone()
        return result is not None


if __name__ == "__main__":
    print("This module is not intended to be run directly.")
