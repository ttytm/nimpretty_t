#? replace(sub = "\t", by = "  ")
import std/[osproc, strformat]

# Build nimpretty_t.
let buildCmd = &"nimble build"
assert execCmd(buildCmd) == 0

# assert execCmd("nimpretty_t ") == 0

# TODO: copy testdata to tmp directory
# TODO: format files and compare expected result and exit codes
