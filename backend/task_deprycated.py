# coding: utf-8
"""This python file will edit the tasklist in data.db."""


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
CREATE_GROUP_INVITES_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS group_invites"
    "(invite_id TEXT PRIMARY KEY, group_id TEXT NOT NULL, "
    "inviter_id TEXT NOT NULL, invitee_id TEXT NOT NULL, "
    "status TEXT NOT NULL, created_at REAL NOT NULL);"
)

# ---- Check Functions ----------------


# This code is bad:
# 1: It is doing more than one thing (checking and getting)
# 2: Should be split into two functions: one for checking and one for getting the data
#
#
# def check_invite_exists(data_con: Connection, invite_id: str = "",
#                         invitee_id: str = "", group_id: str = "") -> tuple[bool, str]:
#     """Check if an invite exists"""
#     data_cursor: Cursor = data_con.cursor()

#     if invite_id:
#         data_cursor.execute(
#             "SELECT status FROM group_invites WHERE invite_id = ?;",
#             (invite_id,),
#         )
#     elif invitee_id and group_id:
#         data_cursor.execute(
#             "SELECT status FROM group_invites WHERE invitee_id = ? AND group_id = ?;",
#             (invitee_id, group_id),
#         )
#     else:
#         return False, ""

#     result = data_cursor.fetchall()
#     if len(result) == 0:
#         return False, ""
#     return True, result[0][0]


# ---- Task Functions ----------------


if __name__ == "__main__":
    print("This is a 'task_editor' module, please run 'main.py'. Exiting...")
