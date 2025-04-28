# coding: utf-8
"""This python file will edit the tasklist in data.db."""

from datetime import datetime
from sqlite3 import connect, Connection, Cursor, Error
from uuid import uuid4
from time import time

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
CREATE_GROUP_INVITES_TABLE: str = (
    "CREATE TABLE IF NOT EXISTS group_invites"
    "(invite_id TEXT PRIMARY KEY, group_id TEXT NOT NULL, "
    "inviter_id TEXT NOT NULL, invitee_id TEXT NOT NULL, "
    "status TEXT NOT NULL, created_at REAL NOT NULL);"
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
    data_cursor.execute(CREATE_GROUP_INVITES_TABLE)

    if (
        len(data_cursor.execute("SELECT * FROM task;").description) != 14
        or len(data_cursor.execute("SELECT * FROM user;").description) != 4
        or len(data_cursor.execute("SELECT * FROM task_group;").description) != 4
        or len(data_cursor.execute("SELECT * FROM group_user;").description) != 3
        or len(data_cursor.execute("SELECT * FROM group_invites;").description) != 6
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


def check_invite_exists(data_con: Connection, invite_id: str = "", 
                        invitee_id: str = "", group_id: str = "") -> tuple[bool, str]:
    """Check if an invite exists"""
    data_cursor: Cursor = data_con.cursor()
    
    if invite_id:
        data_cursor.execute(
            "SELECT status FROM group_invites WHERE invite_id = ?;",
            (invite_id,),
        )
    elif invitee_id and group_id:
        data_cursor.execute(
            "SELECT status FROM group_invites WHERE invitee_id = ? AND group_id = ?;",
            (invitee_id, group_id),
        )
    else:
        return False, ""
        
    result = data_cursor.fetchall()
    if len(result) == 0:
        return False, ""
    return True, result[0][0]


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
) -> str:
    """This will create a group."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
      raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg
    
    # Verify user exists and password is correct
    if not check_user_exists(data_con, user_id):
        data_con.close()
        raise Exception("User does not exist.")
        
    if not check_password(data_con, user_id, password):
        data_con.close()
        raise Exception("Password is incorrect.")

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
        "INSERT INTO task_group VALUES (?, ?, ?, ?);",
        (group_id, group_name, description, user_id),
    )

    data_cursor.execute(
        "INSERT INTO group_user VALUES (?, ?, ?);",
        (group_id, user_id, None),
    )

    data_con.commit()
    data_con.close()
    return group_id


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


def invite_user_to_group(
    inviter_id: str,
    invitee_id: str,
    group_id: str,
) -> str:
    """This will invite a user to a group"""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise e_msg

    # Check if inviter, invitee, and group exist
    if not check_user_exists(data_con, inviter_id):
        data_con.close()
        raise Exception("Inviter does not exist.")
    
    if not check_user_exists(data_con, invitee_id):
        data_con.close()
        raise Exception("Invitee does not exist.")
    
    if not check_group_exists(data_con, group_id):
        data_con.close()
        raise Exception("Group does not exist.")
    
    # Check if inviter is in the group
    if not check_user_in_group(data_con, inviter_id, group_id):
        data_con.close()
        raise Exception("Inviter is not a member of the group.")
    
    # Check if invitee is already in the group
    if check_user_in_group(data_con, invitee_id, group_id):
        data_con.close()
        raise Exception("User is already in the group.")
    
    # Check if invitee has a pending invitation
    invite_exists, status = check_invite_exists(data_con, invitee_id=invitee_id, group_id=group_id)
    if invite_exists and status == "pending":
        data_con.close()
        raise Exception("User already has a pending invitation to this group.")
    
    # Create invitation
    invite_id: str = str(uuid4())
    created_at: float = time()
    
    data_cursor.execute(
        "INSERT INTO group_invites VALUES (?, ?, ?, ?, ?, ?);",
        (invite_id, group_id, inviter_id, invitee_id, "pending", created_at),
    )
    
    data_con.commit()
    data_con.close()
    return invite_id


def leave_group(
    user_id: str,
    group_id: str,
    password: str,
) -> None:
    """Removes a user from a group"""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    # Verify user exists and password is correct
    if not check_user_exists(data_con, user_id):
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if check_password(data_con, user_id, password) is False:
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    # Verify group exists
    if not check_group_exists(data_con, group_id):
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)
        
    # Verify user is in the group
    if not check_user_in_group(data_con, user_id, group_id):
        data_con.close()
        raise Exception("User is not in the group.")

    # Remove user from group
    data_cursor.execute(
        "DELETE FROM group_user WHERE group_id = ? AND user_id = ?;",
        (group_id, user_id),
    )
    
    # Check if group is now empty
    data_cursor.execute(
        "SELECT COUNT(*) FROM group_user WHERE group_id = ?;",
        (group_id,),
    )
    
    count = data_cursor.fetchone()[0]
    
    # If group is empty, delete it
    if count == 0:
        data_cursor.execute(
            "DELETE FROM task_group WHERE uuid = ?;",
            (group_id,),
        )
        
        # Also delete any pending invites for this group
        data_cursor.execute(
            "DELETE FROM group_invites WHERE group_id = ?;",
            (group_id,),
        )

    data_con.commit()
    data_con.close()
    return


def delete_group(
    user_id: str,
    group_id: str,
    password: str,
) -> None:
    """Deletes a group"""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    # Verify group exists
    if not check_group_exists(data_con, group_id):
        data_con.close()
        raise BackendError("Backend Error: Group does not exist", 306)

    # Verify user exists and password is correct
    if not check_user_exists(data_con, user_id):
        data_con.close()
        raise BackendError("Backend Error: User does not exist in group", 304)
        
    if not check_password(data_con, user_id, password):
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)
    
    # Verify user is in the group
    if not check_user_in_group(data_con, user_id, group_id):
        data_con.close()
        raise Exception("User is not a member of the group.")

    data_cursor.execute(
        "SELECT * FROM task_group WHERE uuid = ? AND owner_id = ?;",
        (group_id, user_id),
    )

    if len(data_cursor.fetchall()) == 0:
        data_con.close()
        raise BackendError("Backend Error: User is not the owner of the group", 308)

    # Delete the group
    data_cursor.execute(
        "DELETE FROM task_group WHERE uuid = ?;",
        (group_id,),
    )

    # Delete all users from the group
    data_cursor.execute(
        "DELETE FROM group_user WHERE group_id = ?;",
        (group_id,),
    )
    
    # Delete all invites for the group
    data_cursor.execute(
        "DELETE FROM group_invites WHERE group_id = ?;",
        (group_id,),
    )
    
    data_con.commit()
    data_con.close()
    return


def get_group(
    user_id: str,
    password: str,
) -> dict[str, dict]:
    """Gets all groups a user is a member of"""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    if not check_user_exists(data_con, user_id):
        data_con.close()
        raise BackendError("Backend Error: User does not exist", 304)

    if not check_password(data_con, user_id, password):
        data_con.close()
        raise BackendError("Backend Error: Password is incorrect", 305)

    # Get all groups the user is a member of
    data_cursor.execute(
        """
        SELECT g.uuid, g.name, g.description, g.owner_id 
        FROM task_group g
        JOIN group_user gu ON g.uuid = gu.group_id
        WHERE gu.user_id = ?
        """,
        (user_id,),
    )
    
    groups_data = data_cursor.fetchall()
    groups: dict[str, dict] = {}
    
    for group in groups_data:
        group_id, name, description, owner_id = group
        
        # Get all members of this group
        data_cursor.execute(
            """
            SELECT u.uuid, u.username
            FROM user u
            JOIN group_user gu ON u.uuid = gu.user_id
            WHERE gu.group_id = ?
            """,
            (group_id,),
        )
        
        members_data = data_cursor.fetchall()
        members = []
        
        for member in members_data:
            member_id, member_name = member
            members.append({
                "user_id": member_id,
                "username": member_name
            })
        
        groups[group_id] = {
            "group_id": group_id,
            "name": name,
            "description": description,
            "owner_id": owner_id,  # Keeping for compatibility
            "members": members
        }
    
    data_con.close()
    return groups


def get_pending_invites(
    user_id: str,
    password: str,
) -> dict[str, dict]:
    """Gets all pending invites for a user"""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise e_msg
    
    # Check if user exists and password is correct
    if not check_user_exists(data_con, user_id):
        data_con.close()
        raise Exception("User does not exist.")
    
    if not check_password(data_con, user_id, password):
        data_con.close()
        raise Exception("Password is incorrect.")
    
    # Get all pending invites for the user
    data_cursor.execute(
        """
        SELECT i.invite_id, i.group_id, i.inviter_id, i.created_at, g.name, u.username
        FROM group_invites i
        JOIN task_group g ON i.group_id = g.uuid
        JOIN user u ON i.inviter_id = u.uuid
        WHERE i.invitee_id = ? AND i.status = 'pending'
        """,
        (user_id,),
    )
    
    invites_data = data_cursor.fetchall()
    invites: dict[str, dict] = {}
    
    for invite in invites_data:
        invite_id, group_id, inviter_id, created_at, group_name, inviter_name = invite
        invites[invite_id] = {
            "invite_id": invite_id,
            "group_id": group_id,
            "group_name": group_name,
            "inviter_id": inviter_id,
            "inviter_name": inviter_name,
            "created_at": created_at,
        }
    
    data_con.close()
    return invites


def respond_to_invite(
    user_id: str,
    invite_id: str,
    status: str,
    password: str,
) -> None:
    """Responds to a group invitation (accept or reject)"""
    if status not in ["accepted", "rejected"]:
        raise Exception("Invalid status. Must be 'accepted' or 'rejected'.")
    
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise e_msg
    
    # Check if user exists and password is correct
    if not check_user_exists(data_con, user_id):
        data_con.close()
        raise Exception("User does not exist.")
    
    if not check_password(data_con, user_id, password):
        data_con.close()
        raise Exception("Password is incorrect.")
    
    # Check if invite exists
    invite_exists, invite_status = check_invite_exists(data_con, invite_id=invite_id)
    if not invite_exists:
        data_con.close()
        raise Exception("Invitation does not exist.")
    
    if invite_status != "pending":
        data_con.close()
        raise Exception(f"Invitation has already been {invite_status}.")
    
    # Check if the invite is for this user
    data_cursor.execute(
        "SELECT group_id, invitee_id FROM group_invites WHERE invite_id = ?;",
        (invite_id,),
    )
    
    result = data_cursor.fetchone()
    if not result or result[1] != user_id:
        data_con.close()
        raise Exception("This invitation is not for you.")
    
    group_id = result[0]
    
    # Update the invitation status
    data_cursor.execute(
        "UPDATE group_invites SET status = ? WHERE invite_id = ?;",
        (status, invite_id),
    )
    
    # If accepted, add the user to the group
    if status == "accepted":
        if not check_user_in_group(data_con, user_id, group_id):
            data_cursor.execute(
                "INSERT INTO group_user VALUES (?, ?, ?);",
                (group_id, user_id, None),
            )
    
    data_con.commit()
    data_con.close()
    return


# ---- NEW FUNCTION ----
def get_group_members(user_id: str, group_id: str, password: str) -> list[dict]:
    """Retrieves a list of members for a given group."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    # Check user authentication
    if not check_password(data_con, user_id, password):
        data_con.close()
        raise BackendError("Backend Error: Invalid Password", 303)

    # Check if the requesting user is part of the group
    if not check_user_in_group(data_con, user_id, group_id):
        data_con.close()
        raise BackendError("Backend Error: User not in the specified group", 404) # Or appropriate error

    # Fetch user IDs from the group
    data_cursor.execute(
        "SELECT user_id FROM group_user WHERE group_id = ?;",
        (group_id,),
    )
    member_ids = [row[0] for row in data_cursor.fetchall()]

    if not member_ids:
        data_con.close()
        return [] # Return empty list if group has no members (or only the requester)

    # Fetch user details for each member ID
    # Using placeholders for IN clause to avoid SQL injection vulnerabilities
    placeholders = ','.join('?' for _ in member_ids)
    query = f"SELECT uuid, username FROM user WHERE uuid IN ({placeholders});"
    data_cursor.execute(query, member_ids)

    members = [
        {"user_id": row[0], "username": row[1]} for row in data_cursor.fetchall()
    ]

    data_con.close()
    return members

# ---- END NEW FUNCTION ----

# ---- Task Functions ----------------


# ---- MODIFIED FUNCTION ----
def add_task(
    task_name: str,
    task_description: str,
    task_due: float, # Expecting Unix timestamp
    assigner_id: str,
    assign_id: str,
    group_id: str,
    password: str,
    # Optional parameters with defaults
    priority: int = 0, # Default priority (e.g., 0 for Low)
    task_est_day: int = 0,
    task_est_hour: int = 0,
    task_est_min: int = 0,
    recursive: int = 0, # Default to not recursive
    image_path: str = "", # Default to empty string
) -> None:
    """Adds a task to the database."""
    try:
        data_con: Connection = check_table()
        data_cursor: Cursor = data_con.cursor()
    except Error as e_msg:
        raise BackendError("Backend Error: Cannot Connect to Database", 200) from e_msg

    # Check user authentication
    if not check_password(data_con, assigner_id, password):
        data_con.close()
        raise BackendError("Backend Error: Invalid Password", 303)

    # Check if assigner and assignee are in the group
    if not check_user_in_group(data_con, assigner_id, group_id):
        data_con.close()
        raise BackendError("Backend Error: Assigner not in group", 404)
    if not check_user_in_group(data_con, assign_id, group_id):
        data_con.close()
        raise BackendError("Backend Error: Assignee not in group", 405)


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
            task_est_day, # Using optional value
            task_est_hour, # Using optional value
            task_est_min, # Using optional value
            assigner_id,
            assign_id,
            group_id,
            0,  # completed (defaults to false)
            priority, # Using optional value
            recursive, # Using optional value
            image_path, # Using optional value
        ),
    )
    data_con.commit()
    data_con.close()

# ---- END MODIFIED FUNCTION ----


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

    # Select all relevant columns, including priority and image_path
    data_cursor.execute("SELECT uuid, name, description, due, est_day, est_hour, est_min, assigner_uuid, assign_uuid, group_uuid, completed, priority, recursive, image_path FROM task WHERE assign_uuid = ?;", (user_id,))

    task_list: list[tuple] = data_cursor.fetchall()
    new_task_list: dict[str, dict] = {}
    for task in task_list:
        new_task_list[task[0]] = {
            "name": task[1],
            "description": task[2],
            # Return the raw float timestamp directly
            "due_timestamp": float(task[3]) if task[3] is not None else None,
            "est_day": int(task[4]),
            "est_hour": int(task[5]),
            "est_min": int(task[6]),
            "assigner_id": task[7],
            "assign_id": task[8],
            "group_id": task[9],
            "completed": bool(task[10]),
            # Add priority and image_path
            "priority": int(task[11]) if task[11] is not None else 0, # Default to 0 if null
            "recursive": int(task[12]), # Assuming recursive is index 12
            "image_path": task[13], # Assuming image_path is index 13
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

