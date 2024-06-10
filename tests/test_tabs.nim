#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, strutils, macros]

const testPath = macros.getProjectPath()
const tmpTestDataPath = os.getTempDir() / "nimpretty_t" / "testdata"
const testExe = tmpTestDataPath / "nimpretty_t"

if not os.dirExists(tmpTestDataPath):
	os.createDir(tmpTestDataPath)

os.copyDir(testPath / "testdata", tmpTestDataPath)

# Build nimpretty_t.
let buildCmd = &"nim c -o={testExe} {testPath}/../src/nimpretty_t"
assert execCmd(buildCmd) == 0
assert execCmd(&"{testExe} --version") == 0

# Keep track of run tests to ensure this loop always finds test files in case paths change.
var testNum = 0
for p in walkPattern(tmpTestDataPath & "/*.nim"):
	inc(testNum)
	if p.endswith("_err.nim"):
		continue
	let expectPath = p & ".t.expect"
	assert execCmd(&"{testExe} -w {p}") == 0
	let res = readFile(p)
	let expected = readFile(expectPath)
	if res != expected:
		let (diff, _) = execCmdEx(&"diff -d -a -U 2 --color=always {p} {expectPath}")
		assert false, diff

assert testNum > 3

os.removeDir(tmpTestDataPath)