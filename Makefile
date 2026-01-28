VENV_DIR := .venv
PYTHON ?= python3

.PHONY: all test setup venv install-pre-commit clean

all:
	# No default action

test:
	# No tests defined yet

setup: install-pre-commit
	. $(VENV_DIR)/bin/activate && pre-commit install --install-hooks

venv:
	@if [ ! -d "$(VENV_DIR)" ]; then \
		$(PYTHON) -m venv $(VENV_DIR) && \
		. $(VENV_DIR)/bin/activate && \
		pip install --upgrade pip; \
	fi

install-pre-commit: venv
	. $(VENV_DIR)/bin/activate && pip install pre-commit

clean:
	rm -rf $(VENV_DIR)
