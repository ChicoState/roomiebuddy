# coding: utf-8
"""This module handles the common functions for the backend."""

from contextlib import contextmanager
from functools import wraps
from sqlite3 import connect, Cursor
from typing import Callable, Any, Generator

from flask import Request, jsonify

from error import BackendError
from log import make_new_log

DEFAULT_DB_PATH = "data/data.db"


def extract_request_data(
    request: Request, required_fields: list[str]
) -> dict[str, Any]:
    """Extract and validate request data."""
    try:
        request_data: dict[str, Any] = request.get_json()
    except Exception as err:
        make_new_log("extract_request_data", err)
        raise BackendError(
            message="Failed to retrieve data from request!",
            error_code="199",
        ) from err

    # Check for missing fields
    missing_fields = [field for field in required_fields if not request_data.get(field)]
    if missing_fields:
        missing_parameter = "\n".join(f"- {field}" for field in missing_fields)
        raise BackendError(
            message=f"These fields are empty! \n{missing_parameter}",
            error_code="110",
        )

    return request_data


def error_handling_decorator(log_title: str) -> Callable:
    """Utility function to handle request and log errors."""

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except BackendError as err:
                return jsonify([{"error_no": err.error_code, "message": err.message}])
            except Exception as err:
                make_new_log(log_title, err)
                return jsonify(
                    [{"error_no": "200", "message": "Trouble with backend! Sorry!"}]
                )

        return wrapper

    return decorator


@contextmanager
def db_operation(db_name: str = DEFAULT_DB_PATH) -> Generator[Cursor, None, None]:
    """Context manager for database connection."""
    with connect(db_name) as data_con:
        try:
            data_cursor: Cursor = data_con.cursor()
            yield data_cursor
        except Exception as err:
            data_con.rollback()
            make_new_log("Database", err)
            raise BackendError(
                message="Trouble with backend! Sorry, but please notify the devs!",
                error_code="200",
            ) from err
        data_con.commit()


if __name__ == "__main__":
    print("This is a module and should not be run directly.")
