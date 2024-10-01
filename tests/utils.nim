#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, macros]

const testPath* = macros.getProjectPath()
const tmpTestPath* = os.getTempDir() / "nimpretty_t" / "tests"
const testExe* = tmpTestPath / "nimpretty_t"

proc buildNimprettyT*() =
	let buildCmd = &"nim c -o={testExe} {testPath}/../src/nimpretty_t"
	assert execCmd(buildCmd) == 0
	assert execCmd(&"{testExe} --version") == 0
