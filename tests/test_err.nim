#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, strutils, macros]

const testPath = macros.getProjectPath()
const tmpTestPath = os.getTempDir() / "nimpretty_t" / "tests" / "errors"
const testExe = tmpTestPath / "nimpretty_t"

if not os.dirExists(tmpTestPath):
	os.createDir(tmpTestPath)


# Build nimpretty_t.
let buildCmd = &"nim c -o={testExe} {testPath}/../src/nimpretty_t"
assert execCmd(buildCmd) == 0
assert execCmd(&"{testExe} --version") == 0


let testFile = tmpTestPath / "file.nim"
os.copyFile(testPath / "testdata" / "indentation_err.nim", testFile)
let (output, exitCode) = execCmdEx(&"{testExe} -w {testFile}")
assert exitCode == 1
assert output.contains("invalid indentation"), output
assert output.contains(&"failed to format file '{testFile}'"), output

let res = readFile(testFile)
let expectPath = testPath / "testdata" / "indentation_err.nim"
let expected = readFile(expectPath)
assert res == expected


os.removeDir(tmpTestPath)
