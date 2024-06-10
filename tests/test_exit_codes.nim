#? replace(sub = "\t", by = "  ")
import std/[os, osproc, strformat, macros]

const testPath = macros.getProjectPath()
const tmpTestPath = os.getTempDir() / "nimpretty_t" / "tests" / "exit_codes"
const testExe = tmpTestPath / "nimpretty_t"

if not os.dirExists(tmpTestPath):
	os.createDir(tmpTestPath)


# Build nimpretty_t.
let buildCmd = &"nim c -o={testExe} {testPath}/../src/nimpretty_t"
assert execCmd(buildCmd) == 0
assert execCmd(&"{testExe} --version") == 0


# Prepare a temporary test file.
let testFile = tmpTestPath / "file.nim"
os.copyFile(testPath / "testdata" / "fizz_buzz.nim", testFile)

assert execCmd(&"{testExe} -l {testFile}") == 1
assert execCmd(&"{testExe} -d {testFile}") == 1
assert execCmd(&"{testExe} -w {testFile}") == 0
assert execCmd(&"{testExe} -l {testFile}") == 0
assert execCmd(&"{testExe} -d {testFile}") == 0

os.removeDir(tmpTestPath)
