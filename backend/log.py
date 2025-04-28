# coding: utf-8
"""Create a log file when an error occurs in the program."""

from datetime import datetime
from traceback import format_exc

from pytz import timezone  # type: ignore


def make_new_log(log_title: str, log_data: Exception) -> None:
    """Create a log file when an error occurs in the program."""
    with open("log/log.txt", mode="a", encoding="utf-8") as log_file:
        log_file.write(f'{datetime.now(timezone("America/Los_Angeles"))} \n')
        log_file.write(f"In {log_title}:\n")
        log_file.write(f"{log_data}\n")
        log_file.write(format_exc())
        log_file.write("\n" + "\n")


if __name__ == "__main__":
    print("This is a module for logging errors.")
