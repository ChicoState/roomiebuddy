# coding: utf-8
"""This file will create the server and accept the backend processes."""

from datetime import datetime

from flask import Flask, request, jsonify, Response

from task import add_task, edit_task  # , get_user_task, get_group_task, add_user

app: Flask = Flask(__name__)


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


@app.route("/add_task", methods=["POST"])
def handle_add_task() -> Response:
    """Debug Def."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify([{"message": "Wrong request type"}], success=False)
        return response_json
    try:
        json_data: dict = request.get_json()
        task_name: str = json_data["task_name"]
        task_description: str = json_data["task_description"]
        task_due_year: int = (
            int(json_data["task_due_year"]) if "task_due_year" in json_data else 0
        )
        task_due_month: int = (
            int(json_data["task_due_month"]) if "task_due_month" in json_data else 0
        )
        task_due_date: int = (
            int(json_data["task_due_date"]) if "task_due_date" in json_data else 0
        )
        task_due_hour: int = (
            int(json_data["task_due_hour"]) if "task_due_hour" in json_data else 0
        )
        task_due_min: int = (
            int(json_data["task_due_min"]) if "task_due_min" in json_data else 0
        )
        task_est_day: int = (
            int(json_data["task_est_day"]) if "task_est_day" in json_data else 0
        )
        task_est_hour: int = (
            int(json_data["task_est_hour"]) if "task_est_hour" in json_data else 0
        )
        task_est_min: int = (
            int(json_data["task_est_min"]) if "task_est_min" in json_data else 0
        )
        assigner_id: str = json_data["assigner_id"]
        assign_id: str = json_data["assign_id"]
        group_id: str = json_data["group_id"] if "group_id" in json_data else ""

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
        )
    except Exception as e:
        response_json = jsonify(
            [{"message": e}], status=200, mimetype="application/json"
        )
        print(e)
        return response_json

    response_json = jsonify(
        [{"message": "success"}], status=200, mimetype="application/json"
    )
    return response_json


@app.route("/edit_task", methods=["POST"])
def handle_edit_task() -> Response:
    """Edit Task API."""
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
