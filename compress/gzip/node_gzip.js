const { gzipSync, gunzipSync } = require("node:zlib");

const mode = process.argv[2];

const chunks = [];
process.stdin.on("data", (chunk) => {
  chunks.push(chunk);
});

process.stdin.on("end", () => {
  const input = Buffer.concat(chunks);
  try {
    const output =
      mode === "compress"
        ? gzipSync(input, { mtime: 0 })
        : mode === "decompress"
          ? gunzipSync(input)
          : null;
    if (output === null) {
      process.stderr.write(`unknown mode: ${mode}\n`);
      process.exitCode = 2;
      return;
    }
    process.stdout.write(output);
  } catch (err) {
    const message = err && err.stack ? err.stack : String(err);
    process.stderr.write(message);
    if (!message.endsWith("\n")) {
      process.stderr.write("\n");
    }
    process.exitCode = 1;
  }
});
