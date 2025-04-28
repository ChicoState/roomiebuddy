# coding: utf-8
"""This module controls the task data between the sqlite database."""

from datetime import datetime
from uuid import uuid4

from error import BackendError
from utils import db_operation
from validator import Validator


class TaskController:
    """This class controls the task data between the sqlite database."""

    def __init__(self) -> None:
        """Initialize the TaskController with the database path."""
        return

    def add_task_control(
        self,
        task_name: str,
        task_description: str,
        task_due: float,
        task_est_day: int,
        task_est_hour: int,
        task_est_min: int,
        assigner_id: str,
        assign_id: str,
        group_id: str,
        recursive: int,
        priority: int,
        image_path: str,
        password: str,
    ) -> str:
        """This will add the task."""
        if not Validator().check_user_exists(
            user_id=assigner_id
        ) or not Validator().check_user_exists(user_id=assign_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if group_id != "0" and not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_password(user_id=assigner_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        task_id: str = str(uuid4())
        while Validator().check_duplicate_id(data_table="task", given_id=task_id):
            task_id = str(uuid4())
        with db_operation() as data_cursor:
            data_cursor.execute(
                "INSERT INTO task VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
                (
                    task_id,
                    task_name,
                    task_description,
                    task_due,
                    task_est_day,
                    task_est_hour,
                    task_est_min,
                    assigner_id,
                    assign_id,
                    group_id,
                    0,  # completed = 0
                    priority,
                    recursive,
                    image_path,
                ),
            )
        return task_id

    def edit_task_control(
        self,
        task_id: str,
        task_name: str,
        task_description: str,
        task_due: float,
        task_est_day: int,
        task_est_hour: int,
        task_est_min: int,
        assigner_id: str,
        assign_id: str,
        group_id: str,
        recursive: int,
        priority: int,
        completed: int,
        image_path: str,
        password: str,
    ) -> bool:
        """This will edit the task."""
        if not Validator().check_task_exists(task_id=task_id):
            raise BackendError("Backend Error: Task does not exist", "309")
        if not Validator().check_user_exists(
            user_id=assigner_id
        ) or not Validator().check_user_exists(user_id=assign_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if group_id != "0" and not Validator().check_group_exists(group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if Validator().check_password(user_id=assigner_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "UPDATE task SET name = ?, description = ?, due = ?, est_day = ?, "
                "est_hour = ?, est_min = ?, assigner_uuid = ?, assign_uuid = ?, group_id = ? "
                "recursive = ?, priority = ?, image_path = ? completed = ? "
                "WHERE uuid = ?;",
                (
                    task_name,
                    task_description,
                    task_due,
                    task_est_day,
                    task_est_hour,
                    task_est_min,
                    assigner_id,
                    assign_id,
                    group_id,
                    recursive,
                    priority,
                    image_path,
                    completed,
                    task_id,
                ),
            )
        return True

    def delete_task_control(
        self,
        user_id: str,
        task_id: str,
        password: str,
    ) -> None:
        """This will delete the task."""
        if not Validator().check_task_exists(task_id=task_id):
            raise BackendError("Backend Error: Task does not exist", "309")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        with db_operation() as data_cursor:
            data_cursor.execute("DELETE FROM task WHERE uuid = ?;", (task_id,))

    def get_user_task_control(self, user_id: str, password: str) -> dict[str, dict]:
        """This will get the task from the user."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        with db_operation() as data_cursor:
            data_cursor.execute("SELECT * FROM task WHERE assign_uuid = ?;", (user_id,))
            task_list: list[tuple] = data_cursor.fetchall()
        new_task_list: dict[str, dict] = {}
        for task in task_list:
            new_task_list[task[0]] = {
                "name": task[1],
                "description": task[2],
                "due": datetime.fromtimestamp(float(task[3])),
                "est_day": int(task[4]),
                "est_hour": int(task[5]),
                "est_min": int(task[6]),
                "assigner_id": task[7],
                "assign_id": task[8],
                "group_id": task[9],
                "completed": bool(task[10]),
            }
        return new_task_list

    def get_group_task_control(
        self,
        user_id: str,
        group_id: str,
        password: str,
    ) -> dict[str, dict]:
        """This will get the task from the user."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_in_group(user_id=user_id, group_id=group_id):
            raise BackendError("Backend Error: User is not in the group", "310")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM task WHERE group_id = ?;",
                (group_id),
            )
            task_list: list[tuple] = data_cursor.fetchall()
        new_task_list: dict[str, dict] = {}
        for task in task_list:
            new_task_list[task[0]] = {
                "name": task[1],
                "description": task[2],
                "due": datetime.fromtimestamp(float(task[3])),
                "est_day": int(task[4]),
                "est_hour": int(task[5]),
                "est_min": int(task[6]),
                "assigner_id": task[7],
                "assign_id": task[8],
                "group_id": task[9],
                "completed": bool(task[10]),
            }
        return new_task_list

    def get_completed_task_control(
        self,
        user_id: str,
        group_id: str,
        password: str,
    ) -> dict[str, dict]:
        """This will get the completed task from the user."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_in_group(user_id=user_id, group_id=group_id):
            raise BackendError("Backend Error: User is not in the group", "310")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT * FROM task WHERE assign_id = ? "
                "OR group_id IN (SELECT group_id FROM group_user WHERE user_id = ?) "
                "AND completed = 1;",
                (
                    group_id,
                    user_id,
                ),
            )
            task_list: list[tuple] = data_cursor.fetchall()
        new_task_list: dict[str, dict] = {}
        for task in task_list:
            new_task_list[task[0]] = {
                "name": task[1],
                "description": task[2],
                "due": datetime.fromtimestamp(float(task[3])),
                "est_day": int(task[4]),
                "est_hour": int(task[5]),
                "est_min": int(task[6]),
                "assigner_id": task[7],
                "assign_id": task[8],
                "group_id": task[9],
                "completed": bool(task[10]),
            }
        return new_task_list

    def toggle_complete_task_control(
        self,
        task_id: str,
        user_id: str,
        group_id: str,
        password: str,
        completed: int,
    ) -> None:
        """This will complete the task."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_group_exists(group_id=group_id):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not Validator().check_user_in_group(user_id=user_id, group_id=group_id):
            raise BackendError("Backend Error: User is not in the group", "310")
        if not Validator().check_task_exists(task_id=task_id):
            raise BackendError("Backend Error: Task does not exist", "309")
        with db_operation() as data_cursor:
            data_cursor.execute(
                "UPDATE task SET completed = ? WHERE uuid = ?;",
                (
                    completed,
                    task_id,
                ),
            )


if __name__ == "__main__":
    print("This module is not intended to be run directly.")
