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

"""Exercise snapshot control flow and --update using an unmodified Moon.

Run with python3 test/file_snapshot_e2e.py [moon]. Fixtures and build artifacts
are confined to one temporary package, removed even when an assertion fails.
"""
import pathlib
import subprocess
import sys
import tempfile

core = pathlib.Path(__file__).resolve().parent.parent
moon = sys.argv[1] if len(sys.argv) > 1 else "moon"
for backend in ("wasm", "wasm-gc", "js"):
    with tempfile.TemporaryDirectory(prefix="snapshot_e2e_", dir=core / "internal") as temp:
        package = pathlib.Path(temp)
        relative = str(package.relative_to(core))
        (package / "moon.pkg").write_text('import { "moonbitlang/core/builtin", "moonbitlang/core/test" }\n')
        source = package / "workflow_test.mbt"
        baseline = package / "__snapshot__"

        def run(update=False, success=True):
            result = subprocess.run(
                [moon, "test", relative, "--target", backend, "--target-dir", str(package / "_build")]
                + (["--update", "--limit", "10"] if update else []),
                cwd=core, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            )
            assert (result.returncode == 0) == success, result.stdout
            return result.stdout

        source.write_text('''test "multiple snapshots" (t : @test.Test) {
  t.writeln("first")
  t.snapshot(filename="a.txt")
  t.write("second\\r\\n")
  t.snapshot(filename="nested/b.txt")
  t.write(String::make(262145, 'x'))
  t.snapshot(filename="large.txt")
  t.snapshot(filename="empty.txt")
  println("after all snapshots")
}''')
        output = run(success=False)
        assert "after all snapshots" not in output
        assert not baseline.exists()
        run(update=True)
        assert (baseline / "a.txt").read_bytes() == b"first\n"
        assert (baseline / "nested/b.txt").read_bytes() == b"second\r\n"
        assert (baseline / "large.txt").read_bytes() == b"x" * 262145
        assert not (baseline / "empty.txt").exists()
        assert "after all snapshots" in run()
        (baseline / "a.txt").write_bytes(b"f\ri\rrst\r\n")
        (baseline / "nested/b.txt").write_bytes(b"second\n")
        assert "after all snapshots" in run()
        (baseline / "large.txt").write_bytes(b"x" * 65536 + b"z" + b"x" * 196608)
        assert "after all snapshots" not in run(success=False)
        run(update=True)
        assert "after all snapshots" in run()

        for contents in (b"", b"x" * 262146):
            (baseline / "large.txt").write_bytes(contents)
            assert "after all snapshots" not in run(success=False)
        run(update=True)

        # Directory errors must raise instead of becoming an updatable mismatch.
        (baseline / "directory").mkdir()
        source.write_text('''test "directory error" (t : @test.Test) {
      t.write("content")
      try t.snapshot(filename="directory") catch {
        SnapshotError(_) => fail("expected an I/O error, not a snapshot mismatch")
        _ => println("caught I/O error")
      }
    }''')
        assert "caught I/O error" in run()
        assert (baseline / "directory").is_dir()

        # UTF-8 validation must precede CR normalization, including across chunks.
        source.write_text('''test "unicode snapshot" (t : @test.Test) {
  t.write(String::make(65535, 'x') + "中😀")
  t.snapshot(filename="unicode-中😀.txt")
  println("after unicode")
}''')
        run(update=True)
        assert "after unicode" in run()
        for invalid in (b"\xe4\r\xb8\xad", b"\xc0\x80", b"\xed\xa0\x80", b"\xf4\x90\x80\x80", b"\xe4\xb8"):
            (baseline / "unicode-中😀.txt").write_bytes(b"x" * 65535 + invalid)
            assert "not UTF-8" in run(success=False)

        source.write_text('''test "later assertion runs" (t : @test.Test) {
  t.writeln("first")
  t.snapshot(filename="a.txt")
  fail("later assertion reached")
}''')
        assert "later assertion reached" in run(success=False)
        source.write_text('''test "inline update" (t : @test.Test) {
  t.writeln("first")
  t.snapshot(filename="a.txt")
  inspect("new", content="old")
}''')
        run(update=True)
        assert '"old"' not in source.read_text()
        run()
print("PASS: wasm, wasm-gc, js; existing Moon, multiple snapshots, reset, CR normalization, chunk boundaries, UTF-8 errors, later assertions, --update")
