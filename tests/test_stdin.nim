#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, macros]

const testPath = macros.getProjectPath()
const tmpTestPath = os.getTempDir() / "nimpretty_t" / "tests" / "stdin"
const testExe = tmpTestPath / "nimpretty_t"

if not os.dirExists(tmpTestPath):
	os.createDir(tmpTestPath)


# Build nimpretty_t.
let buildCmd = &"nim c -o={testExe} {testPath}/../src/nimpretty_t"
assert execCmd(buildCmd) == 0
assert execCmd(&"{testExe} --version") == 0


let inputFile = testPath / "testdata" / "basic.nim"
let expectedFile = inputFile & ".t.expect"

let stdout = execCmdEx(&"{testExe} {inputFile}")
let expected = execCmdEx(&"cat {expectedFile}")
assert stdout[0] == expected[0]


os.removeDir(tmpTestPath)
