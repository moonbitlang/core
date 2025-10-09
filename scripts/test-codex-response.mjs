#!/usr/bin/env node

/**
 * Test script to see what Codex SDK returns
 */

import { Codex } from "@openai/codex-sdk";

async function test() {
  console.log("Testing Codex SDK response structure...\n");
  
  const codex = new Codex();
  const thread = codex.startThread({ skipGitRepoCheck: true });
  
  const result = await thread.run("Say hello in one sentence.");
  
  console.log("Result type:", typeof result);
  console.log("\nResult keys:", Object.keys(result || {}));
  console.log("\nFull result:");
  console.log(JSON.stringify(result, null, 2));
  
  console.log("\n--- Accessing properties ---");
  console.log("result.text:", result?.text);
  console.log("result.content:", result?.content);
  console.log("result.message:", result?.message);
  console.log("result.response:", result?.response);
}

test().catch(console.error);
