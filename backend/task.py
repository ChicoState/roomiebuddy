"""This python file will edit the tasklist in data.db."""

from sqlite3 import connect, Connection, Cursor, Error
from uuid import UUID

CREATE_TASK_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS task"
    "(uuid BLOB PRIMARY KEY, name TEXT NOT NULL, "
    "description TEXT, due REAL NOT NULL, "
    "assigner INT NOT NULL, assign INT NOT NULL, "
    "group INT);"
)


INSERT_TASK: str = (
    "INSERT INTO task VALUES (?, ?, ?, ?, ?, ?, ?)"
)


def add_task(
    task_id: UUID,
    task_name: str,
    task_description: str,
    task_due: float,
    assigner_id: int,
    assign_id: int,
    group_id: int,
) -> None:
    """This will add the task."""

    # Connect to table if not exist.
    try:
        data_con: Connection = connect("data/data.db")
    except Error as e_msg:
        raise e_msg

    data_cursor: Cursor = data_con.cursor()
    data_cursor.execute(CREATE_TASK_TABLE)

    if (
        len(data_cursor.execute("SELECT * FROM test;").description) != 7
    ):
        data_con.close()
        raise Exception("User Database has not been configured successfully.")

    data_cursor.execute(
        INSERT_TASK,
        (
            task_id,
            task_name,
            task_description,
            task_due,
            assigner_id,
            assign_id,
            group_id
        )
    )
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


def get_task(
    task_name: str, assigner_id: int, assign_id: int, group_id: int
) -> dict[str, str]:
    return {}


if __name__ == "__main__":
    print("This is a 'task_editor' module, please run 'main.py'. Exiting...")
