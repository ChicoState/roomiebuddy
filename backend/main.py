"""This file will create the server and accept the backend processes."""

from flask import Flask

app: Flask = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

if __name__ == "__main__":
    print("Setting Up the Server...")
    try:
        app.run()
    except Exception as e:
        print("There was a problem setting up the server here is the error info:")
        print(e)
        exit(-1)
