# coding: utf-8
"""This module handles image processing and storage."""

from os import remove
from os.path import exists, join
from typing import Any

from werkzeug.utils import secure_filename

from error import BackendError
from utils import db_operation
from validator import Validator, UPLOAD_FOLDER, ALLOWED_EXTENSIONS


class ImageController:
    """This class will handle the image."""

    def __init__(self) -> None:
        """Initialize the image controller."""
        return

    def allowed_file(self, filename: str) -> bool:
        """Check if the file has an allowed extension."""
        return (
            "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
        )

    def get_user_image_control(
        self,
        image_url: str,
        user_id: str,
        password: str,
    ) -> str:
        """Gets the user image."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not exists(image_url):
            raise BackendError("Backend Error: Image does not exist", "313")
        return image_url

    def get_task_image_control(
        self,
        request_data: dict[str, Any],
    ) -> str:
        """Gets the task image."""
        if not Validator().check_user_exists(user_id=request_data["user_id"]):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(
            user_id=request_data["user_id"], password=request_data["password"]
        ):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_task_exists(task_id=request_data["task_id"]):
            raise BackendError("Backend Error: Task does not exist", "309")
        if (request_data["group_id"] != "0") and not Validator().check_group_exists(
            group_id=request_data["group_id"]
        ):
            raise BackendError("Backend Error: Group does not exist", "306")
        if not exists(request_data["image_url"]):
            raise BackendError("Backend Error: Image does not exist", "313")
        return request_data["image_url"]

    def upload_user_image_control(
        self,
        user_id: str,
        password: str,
        file,
    ) -> str:
        """Uploads the user image."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")

        if not file or not self.allowed_file(file.filename):
            raise BackendError("Backend Error: Invalid file type", "312")

        filename = secure_filename(file.filename)
        file_path = join(UPLOAD_FOLDER, filename)
        file.save(file_path)

        with db_operation() as data_cursor:
            data_cursor.execute(
                "UPDATE user SET image_path = ? WHERE uuid = ?;",
                (file_path, user_id),
            )

        return file_path

    def upload_task_image_control(
        self,
        request_data: dict[str, Any],
        file,
    ) -> str:
        """Uploads the task image."""
        if not Validator().check_user_exists(user_id=request_data["user_id"]):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(
            user_id=request_data["user_id"], password=request_data["password"]
        ):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_task_exists(task_id=request_data["task_id"]):
            raise BackendError("Backend Error: Task does not exist", "309")
        if (request_data["group_id"] != "0") and not Validator().check_group_exists(
            group_id=request_data["group_id"]
        ):
            raise BackendError("Backend Error: Group does not exist", "306")

        if not file or not self.allowed_file(file.filename):
            raise BackendError("Backend Error: Invalid file type", "312")

        filename = secure_filename(file.filename)
        file_path = join(UPLOAD_FOLDER, filename)
        file.save(file_path)

        with db_operation() as data_cursor:
            data_cursor.execute(
                "UPDATE task SET image_path = ? WHERE uuid = ?;",
                (file_path, request_data["task_id"]),
            )

        return file_path

    def edit_user_image_control(
        self,
        user_id: str,
        password: str,
        file,
    ) -> str:
        """Edits the user image."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")

        if not file or not self.allowed_file(file.filename):
            raise BackendError("Backend Error: Invalid file type", "312")

        filename = secure_filename(file.filename)
        file_path = join(UPLOAD_FOLDER, filename)
        file.save(file_path)

        with db_operation() as data_cursor:
            data_cursor.execute(
                "UPDATE user SET image_path = ? WHERE uuid = ?;",
                (file_path, user_id),
            )

        return file_path

    def edit_task_image_control(
        self,
        request_data: dict[str, Any],
        file,
    ) -> str:
        """Edits the task image."""
        if not Validator().check_user_exists(user_id=request_data["user_id"]):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(
            user_id=request_data["user_id"], password=request_data["password"]
        ):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_task_exists(task_id=request_data["task_id"]):
            raise BackendError("Backend Error: Task does not exist", "309")
        if (request_data["group_id"] != "0") and not Validator().check_group_exists(
            group_id=request_data["group_id"]
        ):
            raise BackendError("Backend Error: Group does not exist", "306")

        if not file or not self.allowed_file(file.filename):
            raise BackendError("Backend Error: Invalid file type", "312")

        filename = secure_filename(file.filename)
        file_path = join(UPLOAD_FOLDER, filename)
        file.save(file_path)

        with db_operation() as data_cursor:
            data_cursor.execute(
                "UPDATE task SET image_path = ? WHERE uuid = ?;",
                (file_path, request_data["task_id"]),
            )

        return file_path

    def delete_user_image_control(
        self,
        user_id: str,
        password: str,
    ) -> None:
        """Deletes the user image."""
        if not Validator().check_user_exists(user_id=user_id):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(user_id=user_id, password=password):
            raise BackendError("Backend Error: Password is incorrect", "305")

        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT image_path FROM user WHERE uuid = ?;",
                (user_id,),
            )
            result = data_cursor.fetchone()
            if not result:
                raise BackendError("Backend Error: Image does not exist", "313")
            remove(result[0])
            try:
                remove(result[0])
            except FileNotFoundError as err:
                raise BackendError(
                    "Backend Error: Image does not exist", "313"
                ) from err
            except Exception as err:
                raise BackendError(
                    "Backend Error: Failed to delete image", "203"
                ) from err

            data_cursor.execute(
                "UPDATE user SET image_path = NULL WHERE uuid = ?;",
                (user_id,),
            )

    def delete_task_image_control(
        self,
        request_data: dict[str, Any],
    ) -> None:
        """Deletes the task image."""
        if not Validator().check_user_exists(user_id=request_data["user_id"]):
            raise BackendError("Backend Error: User does not exist", "304")
        if not Validator().check_password(
            user_id=request_data["user_id"], password=request_data["password"]
        ):
            raise BackendError("Backend Error: Password is incorrect", "305")
        if not Validator().check_task_exists(task_id=request_data["task_id"]):
            raise BackendError("Backend Error: Task does not exist", "309")
        if (request_data["group_id"] != "0") and not Validator().check_group_exists(
            group_id=request_data["group_id"]
        ):
            raise BackendError("Backend Error: Group does not exist", "306")

        with db_operation() as data_cursor:
            data_cursor.execute(
                "SELECT image_path FROM task WHERE uuid = ?;",
                (request_data["task_id"],),
            )
            result = data_cursor.fetchone()
            if not result:
                raise BackendError("Backend Error: Image does not exist", "313")
            remove(result[0])
            try:
                remove(result[0])
            except FileNotFoundError as err:
                raise BackendError(
                    "Backend Error: Image does not exist", "313"
                ) from err
            except Exception as err:
                raise BackendError(
                    "Backend Error: Failed to delete image", "203"
                ) from err

            data_cursor.execute(
                "UPDATE task SET image_path = NULL WHERE uuid = ?;",
                (request_data["task_id"],),
            )


if __name__ == "__main__":
    print("This module is not meant to be run directly.")
