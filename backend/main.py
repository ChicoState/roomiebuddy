# coding: utf-8
"""This file will create the server and accept the backend processes."""

# from os.path import join
from typing import Any

from flask import Flask, request, jsonify, Response, send_file

# from werkzeug.utils import secure_filename
from validator import Validator

from utils import error_handling_decorator, make_new_log

from handler_user import UserHandle
from handler_task import TaskHandle
from handler_group import GroupHandle
from handler_invite import InviteHandle
from handler_image import ImageHandle

app: Flask = Flask(__name__)

UPLOAD_FOLDER: str = "data/images"
ALLOWED_EXTENSIONS: set[str] = {"png", "jpg", "jpeg"}
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
                "error_no": "0",
                "message": "This is a debug message, yes, the server is running.",
            }
        ]
    )
    return respose_json


# ----- User Handlers ----


@app.route("/signup", methods=["POST"])
@error_handling_decorator("signup")
def handle_signup() -> Response:
    """Adds a new user to the database."""
    user_id: str = UserHandle(request).add_user_request()
    return jsonify([{"error_no": "0", "message": "success", "user_id": user_id}])


@app.route("/login", methods=["POST"])
@error_handling_decorator("login")
def handle_login() -> Response:
    """Login a user."""
    user_info: dict[str, str] = UserHandle(request).login_user_request()
    # Extract user_id and username
    user_id: str = user_info["user_id"]
    username: str = user_info["username"]
    return jsonify(
        # Include both user_id and username in the response
        # (Front end expects this and needs it to store user info)
        [
            {
                "error_no": "0",
                "message": "success",
                "user_id": user_id,
                "username": username,
            }
        ]
    )


@app.route("/edit_user", methods=["POST"])
@error_handling_decorator("edit_user")
def handle_edit_user() -> Response:
    """Edit a user."""
    UserHandle(request).edit_user_request()
    return jsonify([{"error_no": "0", "message": "success"}])


@app.route("/delete_user", methods=["POST"])
@error_handling_decorator("delete_user")
def handle_delete_user() -> Response:
    """Delete a user."""
    UserHandle(request).delete_user_request()
    return jsonify([{"error_no": "0", "message": "success"}])


# ----- Task Handlers ----


@app.route("/add_task", methods=["POST"])
@error_handling_decorator("add_task")
def handle_add_task() -> Response:
    """Adds a new task to the database."""
    task_id: str = TaskHandle(request).add_task_request()
    return jsonify([{"error_no": "0", "message": "success", "task_id": task_id}])


@app.route("/edit_task", methods=["POST"])
@error_handling_decorator("edit_task")
def handle_edit_task() -> Response:
    """Edits a task."""
    TaskHandle(request).edit_task_request()
    return jsonify([{"error_no": "0", "message": "success"}])


@app.route("/delete_task", methods=["POST"])
@error_handling_decorator("delete_task")
def handle_delete_task() -> Response:
    """Delete a task."""
    TaskHandle(request).delete_task_request()
    return jsonify([{"error_no": "0", "message": "success"}])


@app.route("/get_user_task", methods=["POST"])
@error_handling_decorator("get_user_task")
def handle_get_user_task() -> Response:
    """Get all tasks for a user."""
    tasks: dict[str, dict[str, Any]] = TaskHandle(request).get_user_task_request()
    return jsonify([{"error_no": "0", "message": "success", "tasks": tasks}])


# ----- Group Handlers ----


@app.route("/get_group_list", methods=["POST"])
@error_handling_decorator("get_group_list")
def handle_get_group_list() -> Response:
    """Get all groups for a user."""
    groups: dict[str, dict[str, Any]] = GroupHandle(request).get_group_list_request()
    return jsonify([{"error_no": "0", "message": "success", "groups": groups}])


@app.route("/create_group", methods=["POST"])
@error_handling_decorator("create_group")
def handle_create_group() -> Response:
    """Create a new group."""
    group_id: str = GroupHandle(request).create_group_request()
    return jsonify([{"error_no": "0", "message": "success", "group_id": group_id}])


@app.route("/leave_group", methods=["POST"])
@error_handling_decorator("leave_group")
def handle_leave_group() -> Response:
    """Leave a group."""
    GroupHandle(request).leave_group_request()
    return jsonify([{"error_no": "0", "message": "success"}])


@app.route("/delete_group", methods=["POST"])
@error_handling_decorator("delete_group")
def handle_delete_group() -> Response:
    """Delete a group."""
    GroupHandle(request).delete_group_request()
    return jsonify([{"error_no": "0", "message": "success"}])


@app.route("/get_group_members", methods=["POST"])
@error_handling_decorator("get_group_members")
def handle_get_group_members() -> Response:
    """Get all members of a specific group."""
    members = GroupHandle(request).get_group_members_request()
    return jsonify([{"error_no": "0", "message": "success", "members": members}])


# ----- Invite Handlers ----


@app.route("/create_invite", methods=["POST"])
@error_handling_decorator("create_invite")
def handle_create_invite() -> Response:
    """Invite a user to join a group."""
    invite_id: str = InviteHandle(request).create_invite_request()
    return jsonify([{"error_no": "0", "message": "success", "invite_id": invite_id}])


@app.route("/respond_invite", methods=["POST"])
@error_handling_decorator("respond_invite")
def handle_respond_invite() -> Response:
    """Respond to an invite."""
    InviteHandle(request).respond_invite_request()
    return jsonify([{"error_no": "0", "message": "success"}])


@app.route("/get_pending", methods=["POST"])
@error_handling_decorator("get_pending")
def handle_get_pending() -> Response:
    """Get all pending invites for a user."""
    invites: dict[str, dict[str, Any]] = InviteHandle(request).get_pending_request()
    return jsonify([{"error_no": "0", "message": "success", "invites": invites}])


@app.route("/delete_invite", methods=["POST"])
@error_handling_decorator("delete_invite")
def handle_delete_invite() -> Response:
    """Delete an invite."""
    InviteHandle(request).delete_invite_request()
    return jsonify([{"error_no": "0", "message": "success"}])


@app.route("/sent_invite", methods=["POST"])
@error_handling_decorator("sent_invite")
def handle_sent_invite() -> Response:
    """Get all sent invites for a user."""
    invites: dict[str, dict[str, Any]] = InviteHandle(request).sent_invite_request()
    return jsonify([{"error_no": "0", "message": "success", "invites": invites}])


# ----- File Download ----


@app.route("/get_user_image", methods=["POST"])
@error_handling_decorator("get_user_image")
def handle_get_user_image() -> Response:
    """Get an image."""
    return send_file(ImageHandle(request).get_user_image_request(), mimetype="image/jpeg")

@app.route("/get_task_image", methods=["POST"])
@error_handling_decorator("get_task_image")
def handle_get_task_image() -> Response:
    """Get an image."""
    return send_file(ImageHandle(request).get_task_image_request(), mimetype="image/jpeg")


if __name__ == "__main__":
    print("Running main.py")
    make_new_log("main", "Server started")  # type: ignore
    try:
        print("Setting Up the Server...")
        Validator().initializer()
        print("Server Initialized!")
        print("Starting the server...")
        app.run()
    except Exception as e:
        print("There was a problem setting up the server here is the error info:")
        print(e)
