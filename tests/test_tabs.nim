#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, strutils, macros, sequtils]

const testPath = macros.getProjectPath()
const tmpTestPath = os.getTempDir() / "nimpretty_t" / "tests" / "tabs"
const testExe = tmpTestPath / "nimpretty_t"

if not os.dirExists(tmpTestPath):
	os.createDir(tmpTestPath)
os.copyDir(testPath / "testdata", tmpTestPath)


# Build nimpretty_t.
let buildCmd = &"nim c -o={testExe} {testPath}/../src/nimpretty_t"
assert execCmd(buildCmd) == 0
assert execCmd(&"{testExe} --version") == 0


let paths = toSeq(walkPattern(tmpTestPath & "/*.nim"))
assert paths.len > 5

for _, p in paths:
	if p.endswith("_err.nim"):
		continue
	assert execCmd(&"{testExe} -w {p}") == 0
	let res = readFile(p)
	let expectPath = p & ".t.expect"
	let expected = readFile(expectPath)
	if res != expected:
		let (diff, _) = execCmdEx(&"diff -d -a -U 2 --color=always {p} {expectPath}")
		assert false, diff


os.removeDir(tmpTestPath)
