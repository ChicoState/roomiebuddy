# coding: utf-8
"""This will hold the information with errors."""


class BackendError(Exception):
    """ Custom exception class for backend errors."""

    def __init__(self, message, error_code) -> None:
        self.message = message
        super().__init__(self.message)
        self.error_code = error_code
        return

    def __list__(self) -> list:
        return [self.message, self.error_code]


if __name__ == "__main__":
    print("This is a module for handling backend errors.")
