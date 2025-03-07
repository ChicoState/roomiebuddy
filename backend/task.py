# coding: utf-8
"""This python file will edit the tasklist in data.db."""

from datetime import datetime
from sqlite3 import connect, Connection, Cursor, Error
from uuid import uuid4, UUID

CREATE_TASK_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS task"
    "(uuid TEXT PRIMARY KEY, name TEXT NOT NULL, "
    "description TEXT, due REAL NOT NULL, "
    "est_day INT NOT NULL, est_hour INT NOT NULL, "
    "est_min INT NOT NULL, assigner_id INT NOT NULL, "
    "assign_id INT NOT NULL, group_id INT NOT NULL);"
)

GET_TASK_FROM_USER: str = "SELECT * FROM task WHERE assign_id = ?;"


INSERT_TASK: str = "INSERT INTO task VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"


def check_task_table() -> Connection:
    """This will check if the task table exists."""

    try:
        data_con: Connection = connect("data/data.db")
    except Error as e_msg:
        raise e_msg

    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute(CREATE_TASK_TABLE)

    if len(data_cursor.execute("SELECT * FROM task;").description) != 10:
        data_con.close()
        raise Exception("User Database has not been configured successfully.")

    return data_con


def delete_everything() -> None:
    """This will delete everything in the task table. DANGER!"""

    try:
        data_con: Connection = check_task_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise e_msg

    data_cursor.execute("DELETE FROM task;")
    data_con.commit()
    data_con.close()
    return


def test_task() -> None:
    """This will test the task table."""

    try:
        data_con: Connection = check_task_table()
        data_con.close()
    except Error as e_msg:
        raise e_msg

    # DANGER! MAKE SURE TO COMMENT THIS OUT ON REAL USE!
    delete_everything()

    uuid_1: UUID = uuid4()
    print("test1")
    add_task(
        task_id=uuid_1,
        task_name="Test Task",
        task_description="This is a test task.",
        task_due=0,
        task_est_day=0,
        task_est_hour=0,
        task_est_min=0,
        assigner_id=0,
        assign_id=0,
        group_id=0,
    )
    print("test1 done")

    uuid_2: UUID = uuid4()
    print("test2")
    add_task(
        task_id=uuid_2,
        task_name="Test Task 2",
        task_description="This is a test task.",
        task_due=0,
        task_est_day=0,
        task_est_hour=0,
        task_est_min=0,
        assigner_id=0,
        assign_id=0,
        group_id=0,
    )
    print("test2 done")

    print("test get")
    data = get_task_from_user(0)
    print(data)
    print("test get done")

    return


def add_task(
    task_id: UUID,
    task_name: str,
    task_description: str,
    task_due: float,
    task_est_day: int,
    task_est_hour: int,
    task_est_min: int,
    assigner_id: int,
    assign_id: int,
    group_id: int,
) -> None:
    """This will add the task."""

    try:
        data_con: Connection = check_task_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise e_msg

    # print(
    #     task_id,
    #     task_name,
    #     task_description,
    #     task_due,
    #     task_est_day,
    #     task_est_hour,
    #     task_est_min,
    #     assigner_id,
    #     assign_id,
    #     group_id,
    # )

    data_cursor.execute(
        INSERT_TASK,
        (
            str(task_id),
            task_name,
            task_description,
            task_due,
            task_est_day,
            task_est_hour,
            task_est_min,
            assigner_id,
            assign_id,
            group_id,
        ),
    )

    data_con.commit()
    data_con.close()
    return


def edit_task(
    task_id: UUID,
    task_name: str,
    task_description: str,
    task_due: float,
    assigner_id: int,
    assign_id: int,
    group_id: int,
) -> bool:
    return True


def get_task_from_user(user_id: int) -> dict[str, dict]:
    """This will get the task from the user."""
    try:
        data_con: Connection = check_task_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise e_msg

    data_cursor.execute(GET_TASK_FROM_USER, (user_id,))
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
            "assigner_id": int(task[7]),
            "assign_id": int(task[8]),
            "group_id": int(task[9]),
        }
    data_con.close()

    return new_task_list


if __name__ == "__main__":
    test_task()
    print("This is a 'task_editor' module, please run 'main.py'. Exiting...")
