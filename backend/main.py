"""This file will create the server and accept the backend processes."""

from datetime import datetime
from uuid import uuid4, UUID

from flask import Flask, request, jsonify, Response

from task import add_task


app: Flask = Flask(__name__)


@app.route("/add_task", methods=["POST"])
def handle_add_task() -> Response:
    """Debug Def."""
    response_json: Response
    if request.method != "POST":
        response_json = jsonify(success=False)
        return response_json
    try:
        task_name: str = request.form["task_name"]
        task_description: str = request.form["task_description"]
        task_due_year: int = int(request.form["task_due_year"])
        task_due_month: int = int(request.form["task_due_month"])
        task_due_date: int = int(request.form["task_due_date"])
        task_due_hour: int = int(request.form["task_due_hour"])
        task_due_min: int = int(request.form["task_due_min"])
        assigner_id: int = int(request.form["assigner_id"])
        assign_id: int = int(request.form["assign_id"])
        group_id: int = int(request.form["group_id"])

        task_due: float = datetime(
            task_due_year, task_due_month, task_due_date, task_due_hour, task_due_min, 0
        ).timestamp()
        task_id: UUID = uuid4()
    except Exception as e:
        response_json = jsonify(
            [{"message": e}], status=200, mimetype="application/json"
        )
        print(e)
        return response_json

    if (
        task_name == ""
        or assigner_id < 0
        or assign_id < 0
        or group_id < 0
    ):
        response_json = jsonify(
            [{"message": "Given data is invalid!"}], status=200, mimetype="application/json"
        )
        return response_json

    try:
        add_task(
            task_id=task_id,
            task_name=task_name,
            task_description=task_description,
            task_due=task_due,
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
