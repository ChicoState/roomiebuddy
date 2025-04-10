# coding: utf-8
"""This script will create a dummy user and password for testing purposes."""

from sqlite3 import connect, Connection, Cursor, Error


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
CREATE_GROUP_ROLES_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS group_roles"
    "(group_id TEXT NOT NULL, uuid TEXT NOT NULL, "
    "role_name TEXT NOT NULL, role_description TEXT, "
    "role_permissions TEXT, admin INT NOT NULL);"
)


def create_dummy_user():
    """Create a dummy user in the database."""
    # Connect to the database
    conn = connect("data/data.db")
    cursor = conn.cursor()

    # Create a dummy user
    cursor.execute(
        "INSERT INTO user (uuid, username, email, password) VALUES (?, ?, ?, ?)",
        ("dummy_id", "dummy_user", "dummy_email", "dummy_password"),
    )

    # Commit the changes and close the connection
    conn.commit()
    conn.close()


def create_dummy_group():
    """Create a dummy group in the database."""
    # Connect to the database
    conn = connect("data/data.db")
    cursor = conn.cursor()

    # Create a dummy group
    cursor.execute(
        "INSERT INTO task_group (uuid, name, description, owner_id) VALUES (?, ?, ?, ?)",
        ("dummy_group_id", "dummy_group", "dummy_description", "dummy_owner_id"),
    )

    # Create a dummy group user
    cursor.execute(
        "INSERT INTO group_user (group_id, user_id, role_id) VALUES (?, ?, ?)",
        ("dummy_group_id", "dummy_user", "dummy_role"),
    )

    # Commit the changes and close the connection
    conn.commit()
    conn.close()


def delete_dummy_user():
    """Delete the dummy user from the database."""
    # Connect to the database
    conn = connect("data/data.db")
    cursor = conn.cursor()

    # Delete the dummy user
    cursor.execute(
        "DELETE FROM user WHERE username = ?",
        ("dummy_user",),
    )

    # Commit the changes and close the connection
    conn.commit()
    conn.close()


def delete_dummy_group():
    """Delete the dummy group from the database."""
    # Connect to the database
    conn = connect("data/data.db")
    cursor = conn.cursor()

    # Delete the dummy group
    cursor.execute(
        "DELETE FROM task_group WHERE name = ?",
        ("dummy_group",),
    )

    # Delete the dummy group user
    cursor.execute(
        "DELETE FROM group_user WHERE group_id = ?",
        ("dummy_group_id",),
    )

    # Commit the changes and close the connection
    conn.commit()
    conn.close()


def delete_everything() -> None:
    """This will delete everything in the task table. DANGER!"""

    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise e_msg

    data_cursor.execute("DELETE FROM task;")
    data_cursor.execute("DELETE FROM user;")
    data_cursor.execute("DELETE FROM task_group;")
    data_cursor.execute("DELETE FROM group_user;")
    data_con.commit()
    data_con.close()
    return


def check_table() -> Connection:
    """This will check if the task table exists."""

    try:
        data_con: Connection = connect("data/data.db")
    except Error as e_msg:
        raise e_msg

    data_cursor: Cursor = data_con.cursor()
    print(CREATE_TASK_TABLE)
    data_cursor.execute(CREATE_TASK_TABLE)
    print(CREATE_USER_TABLE)
    data_cursor.execute(CREATE_USER_TABLE)
    print(CREATE_GROUP_TABLE)
    data_cursor.execute(CREATE_GROUP_TABLE)
    print(CREATE_GROUP_USER_TABLE)
    data_cursor.execute(CREATE_GROUP_USER_TABLE)

    if (
        len(data_cursor.execute("SELECT * FROM task;").description) != 14
        or len(data_cursor.execute("SELECT * FROM user;").description) != 4
        or len(data_cursor.execute("SELECT * FROM task_group;").description) != 4
        or len(data_cursor.execute("SELECT * FROM group_user;").description) != 3
    ):
        data_con.close()
        raise Exception("User Database has not been configured successfully.")

    data_con.commit()
    data_cursor.close()

    return data_con


if __name__ == "__main__":
    # prompt the user for action
    check_table()
    action = input("Do you want to create or delete a dummy user? ([c]reate/[d]elete): ")
    if action[0] == "c":
        create_dummy_user()
        create_dummy_group()
        print("Dummy user created.")
    elif action[0] == "d":
        delete_dummy_user()
        delete_dummy_group()
        print("Dummy user deleted.")
    else:
        print("Invalid action. Please enter 'create' or 'delete'.")
