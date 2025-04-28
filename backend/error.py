# coding: utf-8
"""This will hold the information with errors."""

from typing import Callable
from log import make_new_log


class BackendError(Exception):
    """Custom exception class for backend errors."""

    def __init__(self, message: str, error_code: str) -> None:
        """Initialize the BackendError with a message and error code."""
        self.message = message
        super().__init__(self.message)
        self.error_code = error_code


def handle_backend_exceptions(method: Callable) -> Callable:
    """Decorator to handle exceptions in GroupHandle methods."""

    def wrapper(*args, **kwargs):
        """Wrapper function to handle exceptions."""

        try:
            return method(*args, **kwargs)
        except BackendError as err:
            raise BackendError(message=err.message, error_code=err.error_code) from err
        except Exception as err:
            make_new_log(method.__name__, err)
            raise BackendError(
                message="Trouble with backend! Sorry, but please notify the devs!",
                error_code="200",
            ) from err

    return wrapper


if __name__ == "__main__":
    print("This is a module for handling backend errors.")
