.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

VENV_NAME?=venv
VENV_ACTIVATE=. $(VENV_NAME)/bin/activate
PYTHON=${VENV_NAME}/bin/python3

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@${PYTHON} -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	${VENV_ACTIVATE} && flake8 waterrower_s4_apm tests

test: ## run tests quickly with the default Python
	${VENV_ACTIVATE} && pytest

test-all: ## run tests on every Python version with tox
	${VENV_ACTIVATE} && tox

coverage: ## check code coverage quickly with the default Python
	${VENV_ACTIVATE} && coverage run --source waterrower_s4_apm -m pytest
	${VENV_ACTIVATE} && coverage report -m
	${VENV_ACTIVATE} && coverage html
	$(BROWSER) htmlcov/index.html

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/waterrower_s4_apm.rst
	rm -f docs/modules.rst
	${VENV_ACTIVATE} && sphinx-apidoc -o docs/ waterrower_s4_apm
	${VENV_ACTIVATE} && $(MAKE) -C docs clean
	${VENV_ACTIVATE} && $(MAKE) -C docs html
	${VENV_ACTIVATE} && $(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

release: dist ## package and upload a release
	twine upload dist/*

dist: clean ## builds source and wheel package
	${PYTHON} setup.py sdist
	${PYTHON} setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	${PYTHON} setup.py install
