# coding: utf-8
"""This module handles image processing and storage."""

from os.path import exists


from validator import Validator
from error import BackendError
# from utils import db_operation


class ImageController:
    """This class will handle the image."""

    def __init__(self) -> None:
        """Initialize the image controller."""
        return

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


if __name__ == "__main__":
    print("This module is not meant to be run directly.")
