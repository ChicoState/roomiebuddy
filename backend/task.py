# coding: utf-8
"""This python file will edit the tasklist in data.db."""

from datetime import datetime
from sqlite3 import connect, Connection, Cursor, Error
from uuid import uuid4

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
# CREATE_GROUP_ROLES_TABLE: str = (
#     "CREATE TABLE IF NOT EXISTS group_roles "
#     "(group_id TEXT NOT NULL, uuid TEXT NOT NULL, "
#     "role_name TEXT NOT NULL, role_description TEXT, "
#     "role_permissions TEXT, admin INT NOT NULL);"
# )
CREATE_PENDING_INVITE_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS pending_invite "
    "(group_id TEXT NOT NULL, user_id TEXT NOT NULL);"
)

# ---- Check Functions ----------------


def check_table() -> Connection:
    """This will check if the task table exists."""

    try:
        data_con: Connection = connect("data/data.db")
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute(CREATE_TASK_TABLE)
    data_cursor.execute(CREATE_USER_TABLE)
    data_cursor.execute(CREATE_GROUP_TABLE)
    data_cursor.execute(CREATE_GROUP_USER_TABLE)
    data_cursor.execute(CREATE_PENDING_INVITE_TABLE)

    if (
        len(data_cursor.execute("SELECT * FROM task;").description) != 14
        or len(data_cursor.execute("SELECT * FROM user;").description) != 4
        or len(data_cursor.execute("SELECT * FROM task_group;").description) != 4
        or len(data_cursor.execute("SELECT * FROM group_user;").description) != 3
        or len(data_cursor.execute("SELECT * FROM pending_invite;").description) != 2
    ):
        data_con.close()
        raise BackendError(
            "Backend Error: Not Been Configured Correctly, Ask Developers",
            201,
        )

    return data_con


def check_user_exists(data_con: Connection, user_id: str) -> bool:
    """This will check if the user exists."""
    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute("SELECT * FROM user WHERE uuid = ?;", (user_id,))
    if len(data_cursor.fetchall()) == 0:
        return False
    return True


def check_group_exists(data_con: Connection, group_id: str) -> bool:
    """This will check if the group exists."""
    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute("SELECT * FROM task_group WHERE uuid = ?;", (group_id,))
    if len(data_cursor.fetchall()) == 0:
        return False
    return True


def check_task_exists(data_con: Connection, task_id: str) -> bool:
    """This will check if the task exists."""
    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute("SELECT * FROM task WHERE uuid = ?;", (task_id,))
    if len(data_cursor.fetchall()) == 0:
        return False
    return True


def check_user_in_group(data_con: Connection, user_id: str, group_id: str) -> bool:
    """This will check if the user is in the group."""
    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute(
        "SELECT * FROM group_user WHERE user_id = ? AND group_id = ?;",
        (user_id, group_id),
    )
    if len(data_cursor.fetchall()) == 0:
        return False
    return True


def check_id_exists(data_con: Connection, data_table: str, given_id: str) -> bool:
    """Checks if id is not in use."""
    data_cursor: Cursor = data_con.cursor()
    if data_table == "task":
        data_cursor.execute("SELECT * FROM task WHERE uuid = ?;", (given_id,))
    elif data_table == "user":
        data_cursor.execute("SELECT * FROM user WHERE uuid = ?;", (given_id,))
    elif data_table == "group":
        data_cursor.execute("SELECT * FROM task_group WHERE uuid = ?;", (given_id,))
    if len(data_cursor.fetchall()) == 0:
        return False
    return True


def check_password(data_con: Connection, user_id: str, password: str) -> bool:
    """Checks if password is correct."""
    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute(
        "SELECT * FROM user WHERE uuid = ? AND password = ?;",
        (user_id, password),
    )
    if len(data_cursor.fetchall()) == 0:
        return False
    return True


# ---- User Functions ----------------


def add_user(
    username: str,
    email: str,
    password: str,
) -> str:
    """This will add a user."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    user_id: str = str(uuid4())
    while check_id_exists(data_con, "user", user_id):
        user_id = str(uuid4())

    data_cursor.execute(
        "SELECT * FROM user WHERE username = ?;",
        (username,),
    )
    if len(data_cursor.fetchall()) != 0:
        data_con.close()
        raise BackendError("Backend Error: Username already exists", 301)

    data_cursor.execute(
        "SELECT * FROM user WHERE email = ?;",
        (email,),
    )
    if len(data_cursor.fetchall()) != 0:
        data_con.close()
        raise BackendError("Backend Error: Email already exists", 302)

    data_cursor.execute(
        "INSERT INTO user VALUES (?, ?, ?, ?);",
        (user_id, username, email, password),
    )

    data_con.commit()
    data_con.close()
    return user_id


def login_user(
    email: str,
    password: str,
) -> str:
    """This will login a user."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    data_cursor.execute(
        "SELECT * FROM user WHERE email = ? AND password = ?;",
        (email, password),
    )
    if len(data_cursor.fetchall()) == 0:
        data_con.close()
        raise BackendError("Backend Error: Email or Password is incorrect", 303)

    data_cursor.execute(
        "SELECT uuid FROM user WHERE email = ?;",
        (email,),
    )
    user_id: str = data_cursor.fetchone()[0]
    data_con.close()

    return user_id


def edit_user(
    user_id: str, username: str, email: str, password: str, new_password: str
) -> None:
    """Edits a user information."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    data_cursor.execute(
        "SELECT * FROM user WHERE username = ?;",
        (username,),
    )
    if len(data_cursor.fetchall()) != 0:
        data_con.close()
        raise BackendError("Backend Error: Username already exists", 301)

    data_cursor.execute(
        "SELECT * FROM user WHERE email = ?;",
        (email,),
    )
    if len(data_cursor.fetchall()) != 0:
        data_con.close()
        raise BackendError("Backend Error: Email already exists", 302)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    data_cursor.execute(
        "UPDATE user SET username = ?, email = ?, password = ? WHERE uuid = ?;",
        (username, email, new_password, user_id),
    )
    return


def delete_user(
    user_id: str,
    password: str,
) -> None:
    """Deletes a user from the database."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

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

    data_con.commit()
    data_con.close()
    return


# ---- Group Functions ----------------


def create_group(
    user_id: str,
    description: str,
    group_name: str,
    password: str,
) -> None:
    """This will create a group."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    group_id: str = str(uuid4())
    while check_id_exists(data_con, "group", group_id):
        group_id = str(uuid4())

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    data_cursor.execute(
        "INSERT INTO group VALUES (?, ?, ?, ?);",
        (group_id, group_name, description, user_id),
    )

    data_cursor.execute(
        "INSERT INTO group_user VALUES (?, ?);",
        (group_id, user_id),
    )

    data_con.commit()
    data_con.close()
    return


def add_user_to_group(
    user_id: str,
    group_id: str,
    password: str,
) -> None:
    """Adds a user to a group."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    if check_group_exists(data_con, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    if check_user_in_group(data_con, user_id, group_id):
        data_con.close()
        raise BackendError("Backend Error: User already in group", 307)

    data_cursor.execute(
        "INSERT INTO group_user VALUES (?, ?);",
        (group_id, user_id),
    )

    return


def remove_user_from_group(
    user_id: str,
    group_id: str,
    password: str,
) -> None:
    """Removes a user from a group."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    if check_group_exists(data_con, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    data_cursor.execute(
        "DELETE FROM group_user WHERE group_id = ? AND user_id = ?;",
        (group_id, user_id),
    )

    return


def delete_group(
    user_id: str,
    group_id: str,
    password: str,
) -> None:
    """Deletes a group."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_group_exists(data_con, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist in group", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    data_cursor.execute(
        "SELECT * FROM task_group WHERE uuid = ? AND owner_id = ?;",
        (group_id, user_id),
    )

    if len(data_cursor.fetchall()) == 0:
        data_con.close()
        raise BackendError("Backend Error: User is not the owner of the group", 308)

    data_cursor.execute(
        "DELETE FROM task_group WHERE uuid = ?;",
        (group_id,),
    )

    data_cursor.execute(
        "DELETE FROM group_user WHERE group_id = ?;",
        (group_id,),
    )

    return


def get_group(
    user_id: str,
    password: str,
) -> dict[str, dict]:
    """This will get the group from the user."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    data_cursor.execute(
        "SELECT * FROM group_user WHERE user_id = ?;",
        (user_id,),
    )

    group_list: list[tuple] = data_cursor.fetchall()
    new_group_list: dict[str, dict] = {}
    for group in group_list:
        new_group_list[group[0]] = {
            "group_id": group[0],
            "user_id": group[1],
            "role_id": group[2],
        }
    data_con.close()

    return new_group_list


# ---- Task Functions ----------------


def add_task(
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
) -> None:
    """This will add the task."""

    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if (
        check_user_exists(data_con, assigner_id) is False
        or check_user_exists(data_con, assign_id) is False
    ):
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if group_id != "0" and check_group_exists(data_con, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    if check_password(data_con, assigner_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    task_id: str = str(uuid4())
    while check_id_exists(data_con, "task", task_id):
        task_id = str(uuid4())

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

    data_con.commit()
    data_con.close()
    return


def edit_task(
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
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_task_exists(data_con, task_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Task does not exist", 309)

    if (
        check_user_exists(data_con, assigner_id) is False
        or check_user_exists(data_con, assign_id) is False
    ):
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if group_id != "0" and check_group_exists(data_con, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    if check_password(data_con, assigner_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

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

    data_con.commit()
    data_con.close()
    return True


def delete_task(
    user_id: str,
    task_id: str,
    password: str,
) -> None:
    """This will delete the task."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_task_exists(data_con, task_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Task does not exist", 309)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    data_cursor.execute("DELETE FROM task WHERE uuid = ?;", (task_id,))
    data_con.commit()
    data_con.close()

    return


def get_user_task(user_id: str, password: str) -> dict[str, dict]:
    """This will get the task from the user."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

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
    data_con.close()

    # print(new_task_list)

    return new_task_list


def get_group_task(
    user_id: str,
    group_id: str,
    password: str,
) -> dict[str, dict]:
    """This will get the task from the user."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    if check_group_exists(data_con, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    if check_user_in_group(data_con, user_id, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User is not in the group", 310)

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
    data_con.close()

    return new_task_list


def get_completed_task(
    user_id: str,
    group_id: str,
    password: str,
) -> dict[str, dict]:
    """This will get the completed task from the user."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_group_exists(data_con, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    if check_user_in_group(data_con, user_id, group_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User is not in the group", 310)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

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
    data_con.close()

    return new_task_list


def toggle_complete_task(
    task_id: str,
    user_id: str,
    password: str,
    completed: int,
) -> None:
    """This will complete the task."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if check_user_exists(data_con, user_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    if check_user_in_group(data_con, user_id, task_id) is False:
        data_con.close()
        raise BackendError("Backend Error: User is not in the group", 310)

    if check_task_exists(data_con, task_id) is False:
        data_con.close()
        raise BackendError("Backend Error: Task does not exist", 309)

    data_cursor.execute(
        "UPDATE task SET completed = ? WHERE uuid = ?;",
        (
            completed,
            task_id,
        ),
    )
    data_con.commit()
    data_con.close()

    return


if __name__ == "__main__":
    print("This is a 'task_editor' module, please run 'main.py'. Exiting...")
