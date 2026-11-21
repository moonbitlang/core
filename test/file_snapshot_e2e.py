# Copyright 2026 International Digital Economy Academy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Exercise the paired Core/Moon candidate protocol. Pass the new Moon executable.

Fixtures are created inside this core module and always removed. No SDK files or
existing baselines are modified. Wasm exercises synchronous comparison after output generation.
"""
import pathlib
import subprocess
import sys
import tempfile

core = pathlib.Path(__file__).resolve().parent.parent
moon = str(pathlib.Path(sys.argv[1]).resolve())

for backend in ("wasm",):
    with tempfile.TemporaryDirectory(prefix="snapshot_e2e_", dir=core / "internal") as temp:
        package = pathlib.Path(temp)
        relative = str(package.relative_to(core))
        (package / "moon.pkg").write_text('''import {
  "moonbitlang/core/builtin", "moonbitlang/core/test",
}
options("allow-experimental-packages": true)
''')
        source = package / "workflow_test.mbt"
        baseline = package / "__snapshot__"

        def run(update=False, success=True, contains=()):
            result = subprocess.run(
                [moon, "test", relative, "--target", backend, "--target-dir", str(package / "_build")] + (["--update"] if update else []),
                cwd=core, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            )
            assert (result.returncode == 0) == success, result.stdout
            for text in contains:
                assert text in result.stdout, result.stdout
            return result.stdout

        # Exercise the ordinary synchronous driver without importing async.
        source.write_text('''test "synchronous file snapshots" (t : @test.Test) {
  t.create_file().snapshot(filename="sync-a.txt")
  t.create_file().snapshot(filename="sync-b.txt")
  println("after both synchronous snapshots")
}
''')
        baseline.mkdir()
        (baseline / "sync-a.txt").write_bytes(b"old text\r\n")
        (baseline / "sync-b.txt").write_bytes(b"\x00\xff")
        run(success=False, contains=("sync-a.txt", "sync-b.txt", "after both synchronous snapshots"))
        assert (baseline / "sync-a.txt").read_bytes() == b"old text\r\n"
        assert (baseline / "sync-b.txt").read_bytes() == b"\x00\xff"
        run(update=True)
        assert (baseline / "sync-a.txt").read_bytes() == b""
        assert (baseline / "sync-b.txt").read_bytes() == b""
        run()
        (baseline / "sync-a.txt").unlink()
        (baseline / "sync-b.txt").unlink()
        baseline.rmdir()

        # Async is only used to populate files; every snapshot comparison is sync.
        (package / "moon.pkg").write_text('''import {
  "moonbitlang/core/builtin", "moonbitlang/core/test",
  "moonbitlang/core/async", "moonbitlang/core/async/fs",
}
options("allow-experimental-packages": true)
''')
        source.write_text('''async test "multiple snapshots continue" (t : @test.Test) {
  let output = t.create_file()
  @fs.write_text(output.path(), "first\\n")
  output.snapshot(filename="a.txt")
  let output = t.create_file()
  @fs.write_binary(output.path(), b"\\x00\\xff")
  output.snapshot(filename="nested/b.bin")
  let output = t.create_file()
  @fs.write_binary(output.path(), Bytes::from_array(FixedArray::make(262145, 0)))
  output.snapshot(filename="large.bin")
  println("reached after all snapshots")
}
''')
        run(success=False, contains=("a.txt", "nested/b.bin", "reached after all snapshots"))
        assert not baseline.exists()
        run(update=True)
        assert (baseline / "a.txt").read_bytes() == b"first\n"
        assert (baseline / "nested/b.bin").read_bytes() == b"\x00\xff"
        assert (baseline / "large.bin").read_bytes() == bytes(262145)
        run()

        source.write_text('''async test "inline snapshots coexist" (t : @test.Test) {
  let output = t.create_file()
  @fs.write_text(output.path(), "inline companion")
  output.snapshot(filename="inline.txt")
  inspect("actual", content="outdated")
}
''')
        run(update=True)
        assert (baseline / "inline.txt").read_bytes() == b"inline companion"
        assert "outdated" not in source.read_text()
        run()

        source.write_text('''async test "body errors are not promoted" (t : @test.Test) {
  let output = t.create_file()
  @fs.write_text(output.path(), "bad replacement")
  output.snapshot(filename="a.txt")
  let output = t.create_file()
  @fs.write_text(output.path(), "new file")
  output.snapshot(filename="unapproved.txt")
  fail("body failed")
}
''')
        run(update=True, success=False, contains=("body failed",))
        assert (baseline / "a.txt").read_bytes() == b"first\n"
        assert not (baseline / "unapproved.txt").exists()

        source.write_text('''async test "unused files succeed" (t : @test.Test) {
  ignore(t.create_file())
}
''')
        run(update=True)
        source.write_text('''async test "caught comparison errors still fail" (t : @test.Test) {
  let file = t.create_file()
  @fs.remove(file.path())
  ignore(@test.expect_error(() => file.snapshot(filename="missing")))
}
''')
        run(update=True, success=False, contains=("comparison(s) did not complete",))

        source.write_text('''async test "passing owner" (t : @test.Test) {
  let output = t.create_file()
  @fs.write_text(output.path(), "first\\n")
  output.snapshot(filename="a.txt")
}
async test "conflicting owner" (t : @test.Test) {
  let output = t.create_file()
  @fs.write_text(output.path(), "different")
  output.snapshot(filename="a.txt")
}
''')
        run(update=True, success=False, contains=("conflicting snapshot baseline",))
        assert (baseline / "a.txt").read_bytes() == b"first\n"
        print(f"{backend}: synchronous driver, multi-file update, rerun, inline update, body failure, unused file, interrupted comparison, conflict passed")
