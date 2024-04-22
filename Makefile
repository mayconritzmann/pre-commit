.PHONY: help
help:  ## Show available commands
	@echo "Available commands:"
	@echo
	@sed -n -E -e 's|^([A-Za-z/_-]+): .+## (.+)|\1@\2|p' $(MAKEFILE_LIST) | column -s '@' -t

.PHONY: pre-commit
pre-commit:  ## Run pre-commit
	pre-commit run --all-files --verbose --show-diff-on-failure --color always $(HOOK)
