.PHONY: help docs test example love2d

help:
	@echo "Targets:"
	@echo "  docs     Serve documentation with Zensical"
	@echo "  test     Run Busted specs"
	@echo "  example  Run the LOVE2D example"
	@echo "  love2d   Alias for example"

docs:
	zensical serve

test:
	busted spec

example:
	love examples/love2d

love2d: example
