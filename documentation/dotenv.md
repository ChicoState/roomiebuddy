This is a memo for how to create an venv to run the python backend.

https://python.land/virtual-environments/virtualenv

- 1: Make sure your terminal is in the `roomiebuddy`.

<!--
- OBSOLETE SHIT, LOOK BELOW PLEASE
- 2: run `pip install virtualenv`
    + If throw error due to debian shit, try running the alternate method below.
- 3: run `virtualenv .env`
- 4: run `source .env/bin/activate`
- -->

- 2: run `python3 -m venv .env`
    + They might ask you for to install venv, so do it.
- 3: run `source .env/bin/activate`
- 4: or run with `.env/bin/python3 [PATH_TO_PYTHON_FILE]`
- 4.5: or run with `.env/bin/pip3 [SOME PIP COMMAND]`

Note: If you use vscode, make sure the inteperter is set to the `python3.xx` (xx is the version number) that is inside the `.env/bin/` folder.
