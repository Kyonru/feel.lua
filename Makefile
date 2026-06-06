.PHONY: help docs test example love2d asteroidz g3d

help:
	@echo "Targets:"
	@echo "  docs     Serve documentation with Zensical"
	@echo "  test     Run Busted specs"
	@echo "  example  Run the LOVE2D example"
	@echo "  love2d   Alias for example"
	@echo "  asteroidz Run the Asteroidz LOVE2D example"
	@echo "  g3d      Run the g3d LOVE2D example"

docs:
	zensical serve

test:
	busted spec

example:
	love examples/love2d

love2d: example

asteroidz:
	love examples/asteroidz

g3d:
	love examples/3d
