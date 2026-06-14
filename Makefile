.PHONY: help docs docs-gifs test lint example love2d asteroidz g3d menori core

help:
	@echo "Targets:"
	@echo "  docs     Serve documentation with Zensical"
	@echo "  docs-gifs Generate documentation feature GIFs"
	@echo "  test     Run Busted specs"
	@echo "  lint     Run Luacheck"
	@echo "  example  Run the LOVE2D example"
	@echo "  love2d   Alias for example"
	@echo "  asteroidz Run the Asteroidz LOVE2D example"
	@echo "  g3d      Run the g3d LOVE2D example"
	@echo "  menori   Run the Menori LOVE2D example"
	@echo "  core     Run the core-only (no LOVE) example"

docs:
	zensical serve

docs-gifs:
	lua scripts/generate_doc_gifs.lua

test:
	busted spec

lint:
	luacheck .

example:
	love examples/love2d

love2d: example

asteroidz:
	love examples/asteroidz

g3d:
	love examples/3d

menori:
	love examples/menori

core:
	lua examples/core/main.lua
