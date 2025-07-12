# Python Package Management with uv

Use uv exclusively for Python package management in this project.

## Package Management Commands

- All Python dependencies **must be installed, synchronized, and locked** using uv
- Never use pip, pip-tools, poetry, or conda directly for dependency management

Use these commands:

- Install dependencies: `uv add <package>`
- Remove dependencies: `uv remove <package>`
- Sync dependencies: `uv sync`
- Run commands from python packages, e.g. black: `uvx black`

## Running Python Code

- Run a Python script with `uv run <script-name>.py`
- Run Python tools like Pytest with `uv run pytest` or `uv run ruff`
- Launch a Python repl with `uv run python`

## Managing Scripts with PEP 723 Inline Metadata

- Run a Python script with inline metadata (dependencies defined at the top of the file) with: `uv run script.py`
- You can add or remove dependencies manually from the `dependencies =` section at the top of the script, or
- Or using uv CLI:
  - `uv add package-name --script script.py`
  - `uv remove package-name --script script.py`

## Validating changes

1. Run agent unit tests with pytest
2. Check typing by running `uvx ty check .`
3. Format & Lint with `uvx ruff`, `uvx black` and `uvx sqlfluff`
