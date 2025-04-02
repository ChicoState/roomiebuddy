# coding: utf-8
"""This file will create the server and accept the backend processes."""

from os.path import join
from datetime import datetime
from flask import Flask, request, jsonify, Response
from task import (
    add_task,
    add_user,
    login_user,
)  # edit_task, get_user_task, get_group_task,
from werkzeug.utils import secure_filename

from log import make_new_log

app: Flask = Flask(__name__)


UPLOAD_FOLDER = "data/images"
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg"}
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER


def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route("/")
def handle_root() -> Response:
    """Debug Def."""
    respose_json: Response = jsonify(
        [
            {
                "message": "This is a debug message, yes, the server is running.",
                "success": True,
            }
        ]
    )
    return respose_json


"""
@app.route("/test", methods=["GET", "POST"])
def handle_test() -> Response:
    response_json: Response
    try:
        print(request.args.get("name1", "name1 does not exist"))
        print(request.args.get("name2", "name2 does not exist"))
        print(request.args.get("name3", "name3 does not exist"))
    except Exception as e:
        response_json = jsonify([{"message": e}])
        print(e)
        return response_json
    response_json = jsonify([{"message": "success"}])

    return response_json
"""


@app.route("/signup", methods=["POST"])
def handle_signup() -> Response:
    """Adds a new user to the database."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        username: str = request.form.get("username", "")
        email: str = request.form.get("email", "")
        password: str = request.form.get("password", "")
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
        email: str = request.form.get("email", "")
        password: str = request.form.get("password", "")
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
    """Debug Def."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"error_no": "1", "message": "Wrong request type"}])
        return response_json
    try:
        task_name: str = request.form.get("task_name", "")
        task_description: str = request.form.get("task_description", "")
        task_due_year: int = int(request.form.get("task_due_year", "0"))
        task_due_month: int = int(request.form.get("task_due_month", "0"))
        task_due_date: int = int(request.form.get("task_due_date", "0"))
        task_due_hour: int = int(request.form.get("task_due_hour", "0"))
        task_due_min: int = int(request.form.get("task_due_min", "0"))
        task_est_day: int = int(request.form.get("task_est_day", "0"))
        task_est_hour: int = int(request.form.get("task_est_hour", "0"))
        task_est_min: int = int(request.form.get("task_est_min", "0"))
        assigner_id: str = request.form.get("assigner_id", "")
        assign_id: str = request.form.get("assign_id", "")
        group_id: str = request.form.get("group_id", "")
        task_due: float = datetime(
            task_due_year, task_due_month, task_due_date, task_due_hour, task_due_min, 0
        ).timestamp()
        recursive: int = int(request.form.get("recursive", "0"))
        priority: int = int(request.form.get("priority", "0"))

        imageFile = request.files.get("image", None)
        if imageFile and imageFile.filename != "":
            fileName: str = secure_filename(imageFile.filename)
            imageFile.save(join(app.config["UPLOAD_FOLDER"], fileName))
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
            image_path=fileName,
        )
    except Exception as e:
        response_json = jsonify(
            [{"error_no": "2", "message": "Trouble with backend! Sorry!"}]
        )
        make_new_log("add_task", e)
        return response_json

    response_json = jsonify([{"error_no": "0", "message": "success"}])
    return response_json


"""
@app.route("/edit_task", methods=["POST"])
def handle_edit_task() -> Response:
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"message": "Wrong request type"}], success=False)
        return response_json
    try:
        json_data: dict = request.get_json()
        task_id: str = json_data["task_id"]
        task_name: str = json_data["task_name"]
        task_description: str = json_data["task_description"]
        task_due_year: int = int(json_data["task_due_year"])
        task_due_month: int = int(json_data["task_due_month"])
        task_due_date: int = int(json_data["task_due_date"])
        task_due_hour: int = int(json_data["task_due_hour"])
        task_due_min: int = int(json_data["task_due_min"])
        task_est_day: int = int(json_data["task_est_day"])
        task_est_hour: int = int(json_data["task_est_hour"])
        task_est_min: int = int(json_data["task_est_min"])
        assigner_id: str = json_data["assigner_id"]
        assign_id: str = json_data["assign_id"]
        group_id: str = json_data["group_id"]

        task_due: float = datetime(
            task_due_year, task_due_month, task_due_date, task_due_hour, task_due_min, 0
        ).timestamp()
    except Exception as e:
        response_json = jsonify(
            [{"message": e}], status=200, mimetype="application/json"
        )
        print(e)
        return response_json

    if task_name == "" or assigner_id == "" or assign_id == "":
        response_json = jsonify(
            [{"message": "Given data is invalid!"}],
            status=200,
            mimetype="application/json",
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
        )
    except Exception as e:
        response_json = jsonify(
            [{"message": e}], status=200, mimetype="application/json"
        )
        print(e)
        return response_json

    response_json = jsonify([{"message": "success"}])

    return response_json
"""


if __name__ == "__main__":
    print("Running main.py")
    # run(test_data())
    try:
        print("Setting Up the Server...")
        app.run()
    except Exception as e:
        print("There was a problem setting up the server here is the error info:")
        print(e)
        exit(-1)
