#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, strutils, sequtils, macros]

const testPath = macros.getProjectPath()
const tmpTestPath = os.getTempDir() / "nimpretty_t" / "tests" / "spaces"
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
for p in walkPattern(tmpTestPath & "/*.nim"):
	if p.endswith("_err.nim"):
		continue
	assert execCmd(&"{testExe} -w -i 4 {p}") == 0
	let res = readFile(p)
	let expectPath = p & ".s.expect"
	let expected = readFile(expectPath)
	if res != expected:
		let (diff, _) = execCmdEx(&"diff -d -a -U 2 --color=always {p} {expectPath}")
		assert false, diff


os.removeDir(tmpTestPath)
