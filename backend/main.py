# coding: utf-8
"""This file will create the server and accept the backend processes."""

from os.path import join
from datetime import datetime
from flask import Flask, request, jsonify, Response
from task import (
    add_task,
    add_user,
    login_user,
    edit_task,
    delete_task,
    get_user_task,
    get_group,
    create_group,
    leave_group,
    delete_group,
    invite_user_to_group,
    get_pending_invites,
    respond_to_invite,
    check_password
)  # edit_task, get_user_task, get_group_task,
from werkzeug.utils import secure_filename
from sqlite3 import connect

from log import make_new_log

app: Flask = Flask(__name__)


UPLOAD_FOLDER = "data/images"
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg"}
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER


def allowed_file(filename):
    """Check if the file is allowed."""
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route("/")
def handle_root() -> Response:
    """Sample root endpoint."""
    respose_json: Response = jsonify(
        [
            {
                "message": "This is a debug message, yes, the server is running.",
                "success": True,
            }
        ]
    )
    return respose_json


@app.route("/signup", methods=["POST"])
def handle_signup() -> Response:
    """Adds a new user to the database."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        request_data: dict = request.get_json()
        username: str = request_data.get("username", "")
        email: str = request_data.get("email", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("signup", e)
        return response_json

    if username == "" or email == "" or password == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        user_id: str = add_user(username=username, email=email, password=password)
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("signup", e)
        return response_json

    response_json = jsonify(
        [{"error_no": "0", "message": "success", "user_id": user_id}]
    )
    return response_json


@app.route("/login", methods=["POST"])
def handle_login() -> Response:
    """Login a user."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        request_data: dict = request.get_json()
        email: str = request_data.get("email", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("login", e)
        return response_json

    if email == "" or password == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        user_id: str = login_user(email=email, password=password)
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("login", e)
        return response_json

    response_json = jsonify(
        [{"error_no": "0", "message": "success", "user_id": user_id}]
    )
    return response_json


@app.route("/add_task", methods=["POST"])
def handle_add_task() -> Response:
    """Adds a new task to the database."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        request_data: dict = request.get_json()
        task_name: str = request_data.get("task_name", "")
        task_description: str = request_data.get("task_description", "")
        task_due_year: int = int(request_data.get("task_due_year", "2000"))
        task_due_month: int = int(request_data.get("task_due_month", "1"))
        task_due_date: int = int(request_data.get("task_due_date", "1"))
        task_due_hour: int = int(request_data.get("task_due_hour", "0"))
        task_due_min: int = int(request_data.get("task_due_min", "0"))
        task_est_day: int = int(request_data.get("task_est_day", "0"))
        task_est_hour: int = int(request_data.get("task_est_hour", "0"))
        task_est_min: int = int(request_data.get("task_est_min", "0"))
        assigner_id: str = request_data.get("assigner_id", "")
        assign_id: str = request_data.get("assign_id", "")
        group_id: str = request_data.get("group_id", "")
        task_due: float = datetime(
            task_due_year, task_due_month, task_due_date, task_due_hour, task_due_min, 0
        ).timestamp()
        recursive: int = int(request_data.get("recursive", "0"))
        priority: int = int(request_data.get("priority", "0"))
        password: str = request_data.get("password", "")

        file_name: str = "TODO CHANGE HERE"
        # image_file = request.files.get("image", None)
        # if image_file and image_file.filename != "":
        #     file_name: str = secure_filename(image_file.filename)
        #     image_file.save(join(app.config["UPLOAD_FOLDER"], file_name))
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("add_task", e)
        return response_json

    if task_name == "" or assigner_id == "" or assign_id == "" or group_id == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        add_task(
            task_name=task_name,
            task_description=task_description,
            task_due=task_due,
            task_est_day=task_est_day,
            task_est_hour=task_est_hour,
            task_est_min=task_est_min,
            assigner_id=assigner_id,
            assign_id=assign_id,
            group_id=group_id,
            recursive=recursive,
            priority=priority,
            image_path=file_name,
            password=password,
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("add_task", e)
        return response_json

    response_json = jsonify([{"error_no": "0", "message": "success"}])
    return response_json


@app.route("/edit_task", methods=["POST"])
def handle_edit_task() -> Response:
    """Edits a task."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        request_data: dict = request.get_json()
        task_id: str = request_data.get("task_id", "")
        task_name: str = request_data.get("task_name", "")
        task_description: str = request_data.get("task_description", "")
        task_due_year: int = int(request_data.get("task_due_year", "2000"))
        task_due_month: int = int(request_data.get("task_due_month", "1"))
        task_due_date: int = int(request_data.get("task_due_date", "1"))
        task_due_hour: int = int(request_data.get("task_due_hour", "0"))
        task_due_min: int = int(request_data.get("task_due_min", "0"))
        task_est_day: int = int(request_data.get("task_est_day", "0"))
        task_est_hour: int = int(request_data.get("task_est_hour", "0"))
        task_est_min: int = int(request_data.get("task_est_min", "0"))
        assigner_id: str = request_data.get("assigner_id", "")
        assign_id: str = request_data.get("assign_id", "")
        group_id: str = request_data.get("group_id", "")
        password: str = request_data.get("password", "")

        task_due: float = datetime(
            task_due_year, task_due_month, task_due_date, task_due_hour, task_due_min, 0
        ).timestamp()
    except Exception as e:
        response_json = jsonify(
            [{"message": f"There was an error! {e}", "error_no": "2"}]
        )
        print(e)
        return response_json

    if task_name == "" or assigner_id == "" or assign_id == "":
        response_json = jsonify(
            [{"message": "Given data is invalid!", "error_no": "3"}]
        )
        return response_json

    try:
        edit_task(
            task_id=task_id,
            task_name=task_name,
            task_description=task_description,
            task_due=task_due,
            task_est_day=task_est_day,
            task_est_hour=task_est_hour,
            task_est_min=task_est_min,
            assigner_id=assigner_id,
            assign_id=assign_id,
            group_id=group_id,
            password=password,
        )
    except Exception as e:
        response_json = jsonify(
            [{"message": f"Trouble with backend! Sorry! {e}", "error_no": "2"}]
        )
        print(e)
        return response_json

    response_json = jsonify([{"message": "success"}])

    return response_json


@app.route("/delete_task", methods=["POST"])
def handle_delete_task() -> Response:
    """Delete a task."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        request_data: dict = request.get_json()
        task_id: str = request_data.get("task_id", "")
        user_id: str = request_data.get("user_id", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("delete_task", e)
        return response_json

    if task_id == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        delete_task(
            user_id=user_id,
            task_id=task_id,
            password=password,
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("delete_task", e)
        return response_json

    response_json = jsonify([{"error_no": "0", "message": "success"}])
    return response_json


@app.route("/get_user_task", methods=["POST"])
def handle_get_user_task() -> Response:
    """Get all tasks for a user."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        request_data: dict = request.get_json()
        user_id: str = request_data.get("user_id", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("get_user_task", e)
        return response_json

    if user_id == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        tasks: dict[str, dict] = get_user_task(
            user_id=user_id,
            password=password
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("get_user_task", e)
        return response_json

    response_json = jsonify([{"error_no": "0", "message": tasks}])
    return response_json


@app.route("/get_group_list", methods=["POST"])
def handle_get_group_list() -> Response:
    """Get all groups for a user."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        request_data: dict = request.get_json()
        user_id: str = request_data.get("user_id", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("get_user_task", e)
        return response_json

    if user_id == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        groups: dict[str, dict] = get_group(user_id=user_id, password=password)
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("get_user_task", e)
        return response_json
    response_json = jsonify([{"error_no": "0", "message": groups}])
    return response_json


@app.route("/create_group", methods=["POST"])
def handle_create_group() -> Response:
    """Create a new group."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    
    try:
        request_data: dict = request.get_json()
        user_id: str = request_data.get("user_id", "")
        password: str = request_data.get("password", "")
        group_name: str = request_data.get("group_name", "")
        description: str = request_data.get("description", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("create_group", e)
        return response_json

    if user_id == "" or password == "" or group_name == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        group_id: str = create_group(
            user_id=user_id,
            group_name=group_name,
            description=description,
            password=password
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": str(e)}]
        )
        make_new_log("create_group", e)
        return response_json
    
    response_json = jsonify([{"error_no": "0", "message": {"group_id": group_id}}])
    return response_json


@app.route("/leave_group", methods=["POST"])
def handle_leave_group() -> Response:
    """Leave a group."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    
    try:
        request_data: dict = request.get_json()
        user_id: str = request_data.get("user_id", "")
        password: str = request_data.get("password", "")
        group_id: str = request_data.get("group_id", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("leave_group", e)
        return response_json

    if user_id == "" or password == "" or group_id == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        leave_group(
            user_id=user_id,
            group_id=group_id,
            password=password
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": str(e)}]
        )
        make_new_log("leave_group", e)
        return response_json
    
    response_json = jsonify([{"error_no": "0", "message": "Successfully left group"}])
    return response_json


@app.route("/delete_group", methods=["POST"])
def handle_delete_group() -> Response:
    """Delete a group."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    
    try:
        request_data: dict = request.get_json()
        user_id: str = request_data.get("user_id", "")
        password: str = request_data.get("password", "")
        group_id: str = request_data.get("group_id", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("delete_group", e)
        return response_json

    if user_id == "" or password == "" or group_id == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        delete_group(
            user_id=user_id,
            group_id=group_id,
            password=password
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": str(e)}]
        )
        make_new_log("delete_group", e)
        return response_json
    
    response_json = jsonify([{"error_no": "0", "message": "Successfully deleted group"}])
    return response_json


@app.route("/invite_to_group", methods=["POST"])
def handle_invite_to_group() -> Response:
    """Invite a user to join a group."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    
    try:
        request_data: dict = request.get_json()
        inviter_id: str = request_data.get("inviter_id", "")
        invitee_id: str = request_data.get("invitee_id", "")
        group_id: str = request_data.get("group_id", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("invite_to_group", e)
        return response_json

    if inviter_id == "" or invitee_id == "" or group_id == "" or password == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        # Verify password before inviting
        if not check_password(connect("../data/data.db"), inviter_id, password):
            response_json = jsonify(
                [{"error_no": "4", "message": "Password is incorrect"}]
            )
            return response_json
            
        invite_id: str = invite_user_to_group(
            inviter_id=inviter_id,
            invitee_id=invitee_id,
            group_id=group_id
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": str(e)}]
        )
        make_new_log("invite_to_group", e)
        return response_json
    
    response_json = jsonify([{"error_no": "0", "message": {"invite_id": invite_id}}])
    return response_json


@app.route("/get_pending_invites", methods=["POST"])
def handle_get_pending_invites() -> Response:
    """Get all pending group invites for a user."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    
    try:
        request_data: dict = request.get_json()
        user_id: str = request_data.get("user_id", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("get_pending_invites", e)
        return response_json

    if user_id == "" or password == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json

    try:
        invites: dict[str, dict] = get_pending_invites(
            user_id=user_id,
            password=password
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": str(e)}]
        )
        make_new_log("get_pending_invites", e)
        return response_json
    
    response_json = jsonify([{"error_no": "0", "message": invites}])
    return response_json


@app.route("/respond_to_invite", methods=["POST"])
def handle_respond_to_invite() -> Response:
    """Accept or reject a group invitation."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    
    try:
        request_data: dict = request.get_json()
        user_id: str = request_data.get("user_id", "")
        invite_id: str = request_data.get("invite_id", "")
        status: str = request_data.get("status", "")
        password: str = request_data.get("password", "")
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("respond_to_invite", e)
        return response_json

    if user_id == "" or invite_id == "" or status == "" or password == "":
        response_json = jsonify(
            [{"error_no": "3", "message": "Given data is invalid!"}]
        )
        return response_json
        
    if status not in ["accepted", "rejected"]:
        response_json = jsonify(
            [{"error_no": "3", "message": "Status must be 'accepted' or 'rejected'"}]
        )
        return response_json

    try:
        respond_to_invite(
            user_id=user_id,
            invite_id=invite_id,
            status=status,
            password=password
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": str(e)}]
        )
        make_new_log("respond_to_invite", e)
        return response_json
    
    response_json = jsonify([{"error_no": "0", "message": f"Successfully {status} invitation"}])
    return response_json


if __name__ == "__main__":
    print("Running main.py")
    make_new_log("main", "Server started")  # type: ignore
    # run(test_data())
    try:
        print("Setting Up the Server...")
        app.run()
    except Exception as e:
        print("There was a problem setting up the server here is the error info:")
        print(e)
        exit(-1)
