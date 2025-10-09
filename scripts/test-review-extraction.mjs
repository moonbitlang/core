#!/usr/bin/env node

/**
 * Quick test to verify review extraction works
 */

import { Codex } from "@openai/codex-sdk";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { readFile } from "fs/promises";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, "..");

async function test() {
  console.log("Testing review extraction...\n");
  
  const codex = new Codex();
  const thread = codex.startThread({ skipGitRepoCheck: true });
  
  // Read a small package file
  const filePath = join(projectRoot, "bool/pkg.generated.mbti");
  const content = await readFile(filePath, "utf-8");
  
  const prompt = `Review this MoonBit package interface file (bool/pkg.generated.mbti):

\`\`\`moonbit
${content}
\`\`\`

Please provide a brief 2-3 sentence assessment of the API design.`;

  console.log("Sending request...");
  const result = await thread.run(prompt);
  
  console.log("\n--- Raw result structure ---");
  console.log("Type:", typeof result);
  console.log("Keys:", Object.keys(result || {}));
  
  console.log("\n--- Extracted review ---");
  const reviewText = result?.finalResponse || JSON.stringify(result, null, 2);
  console.log(reviewText);
  
  console.log("\n✓ Test complete");
}

test().catch(console.error);
