// Smoke test: lib.typ parses and exports the planned public API.
// Functions are stubs at v0.1.0 — importing the symbols (without
// calling them) is enough to prove the package compiles.

#import "../lib.typ": read-resume, parse-resume
