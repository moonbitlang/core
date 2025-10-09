#!/usr/bin/env node

/**
 * Script to list all pkg.generated.mbti files in the project
 * Usage: node scripts/list-mbti-files.mjs [options]
 *
 * Options:
 *   --relative    Show paths relative to project root (default)
 *   --absolute    Show absolute paths
 *   --count       Only show the count of files
 *   --json        Output as JSON array
 *   --review      Review files using Codex SDK (with concurrency control)
 *   --concurrency Number of concurrent reviews when using --review (default: 5)
 */

import { fileURLToPath } from "url";
import { dirname, join, relative } from "path";
import { readdir, readFile, writeFile, mkdir } from "fs/promises";
import { Codex } from "@openai/codex-sdk";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, "..");
const outputDir = join(__dirname, "output");

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  absolute: args.includes("--absolute"),
  count: args.includes("--count"),
  json: args.includes("--json"),
  relative: !args.includes("--absolute"), // default is relative
  review: args.includes("--review"),
  concurrency: parseInt(
    args.find((a) => a.startsWith("--concurrency="))?.split("=")[1] || "5"
  ),
};

/**
 * Recursively find all pkg.generated.mbti files
 */
async function findMbtiFiles(dir, results = []) {
  try {
    const entries = await readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = join(dir, entry.name);

      // Skip node_modules, target, and hidden directories
      if (entry.isDirectory()) {
        if (
          !entry.name.startsWith(".") &&
          entry.name !== "node_modules" &&
          entry.name !== "target"
        ) {
          await findMbtiFiles(fullPath, results);
        }
      } else if (entry.name === "pkg.generated.mbti") {
        results.push(fullPath);
      }
    }
  } catch (error) {
    // Skip directories we can't read
    if (error.code !== "EACCES" && error.code !== "EPERM") {
      console.error(`Error reading ${dir}:`, error.message);
    }
  }

  return results;
}

/**
 * Save review result to file
 */
async function saveReviewToFile(result) {
  try {
    // Create output directory if it doesn't exist
    await mkdir(outputDir, { recursive: true });

    // Generate filename from package path
    // e.g., "bytes/pkg.generated.mbti" -> "bytes.review.md"
    const fileName = result.file
      .replace(/\/pkg\.generated\.mbti$/, "")
      .replace(/\//g, "_") + ".review.md";
    
    const outputPath = join(outputDir, fileName);

    // Format the review content
    const content = `# Review: ${result.package}

**File:** \`${result.file}\`  
**Date:** ${new Date().toISOString()}  
**Status:** ${result.success ? "✓ Success" : "✗ Failed"}

${result.success ? "---\n\n" + result.review : `**Error:** ${result.error}`}
`;

    await writeFile(outputPath, content, "utf-8");
    return outputPath;
  } catch (error) {
    console.error(`Failed to save review for ${result.file}:`, error.message);
    return null;
  }
}

/**
 * Review a single mbti file using Codex
 */
async function reviewMbtiFile(filePath, codex) {
  const relativePath = relative(projectRoot, filePath);

  try {
    const content = await readFile(filePath, "utf-8");
    const packageName = content.match(/package "(.+?)"/)?.[1] || "unknown";

    const thread = codex.startThread({ skipGitRepoCheck: true });

    const prompt = `Review this MoonBit package interface file (${relativePath}):

\`\`\`moonbit
${content}
\`\`\`

Please provide:
1. A brief assessment of the API design
2. Any potential issues or inconsistencies
3. Suggestions for improvement (if any)

Keep the review concise and focused on the public API surface.`;

    const result = await thread.run(prompt);

    // Extract text from Codex SDK result - it returns an object with finalResponse
    const reviewText = result?.finalResponse || JSON.stringify(result, null, 2);

    return {
      file: relativePath,
      package: packageName,
      review: reviewText,
      success: true,
    };
  } catch (error) {
    return {
      file: relativePath,
      package: "unknown",
      review: null,
      success: false,
      error: error.message,
    };
  }
}

/**
 * Process files with concurrency limit
 */
async function processConcurrently(files, processor, concurrency) {
  const results = [];
  const executing = [];
  const startTime = Date.now();

  for (const file of files) {
    const fileStartTime = Date.now();

    const promise = processor(file).then(async (result) => {
      results.push(result);
      executing.splice(executing.indexOf(promise), 1);

      // Save review to file
      const outputPath = await saveReviewToFile(result);

      // Calculate timing
      const fileTime = ((Date.now() - fileStartTime) / 1000).toFixed(2);
      const totalTime = ((Date.now() - startTime) / 1000).toFixed(1);
      const avgTime = (totalTime / results.length).toFixed(2);
      const eta = ((files.length - results.length) * avgTime).toFixed(0);

      // Show progress with status indicator
      const status = result.success ? "✓" : "✗";
      const savedMsg = outputPath ? ` → ${relative(projectRoot, outputPath)}` : "";
      console.log(
        `${status} [${results.length}/${files.length}] ${result.file} (${fileTime}s, ETA: ${eta}s)${savedMsg}`
      );

      return result;
    });

    executing.push(promise);

    if (executing.length >= concurrency) {
      await Promise.race(executing);
    }
  }

  await Promise.all(executing);
  return results;
}

/**
 * Perform code review on mbti files
 */
async function performReview(files) {
  console.log(`\n🔍 Reviewing ${files.length} mbti file(s)...`);
  console.log(`Concurrency limit: ${options.concurrency}\n`);

  const codex = new Codex();
  const startTime = Date.now();

  const results = await processConcurrently(
    files,
    (file) => reviewMbtiFile(file, codex),
    options.concurrency
  );

  const duration = ((Date.now() - startTime) / 1000).toFixed(2);

  // Display results
  console.log("\n" + "=".repeat(80));
  console.log("REVIEW RESULTS");
  console.log("=".repeat(80) + "\n");

  const successful = results.filter((r) => r.success);
  const failed = results.filter((r) => !r.success);

  successful.forEach((result) => {
    console.log(`\n${"─".repeat(80)}`);
    console.log(`📦 ${result.package} (${result.file})`);
    console.log(`${"─".repeat(80)}\n`);
    console.log(result.review);
  });

  // Summary
  console.log("\n" + "=".repeat(80));
  console.log("SUMMARY");
  console.log("=".repeat(80));
  console.log(`Total files: ${results.length}`);
  console.log(`Successful: ${successful.length}`);
  console.log(`Failed: ${failed.length}`);
  console.log(`Duration: ${duration}s`);
  console.log(`Concurrency: ${options.concurrency}`);
  console.log(`Output directory: ${relative(projectRoot, outputDir)}`);

  if (failed.length > 0) {
    console.log("\n❌ Failed reviews:");
    failed.forEach((f) => {
      console.log(`  - ${f.file}: ${f.error}`);
    });
  }
  
  console.log(`\n💾 Reviews saved to: ${outputDir}`);
}

/**
 * Main function
 */
async function main() {
  const files = await findMbtiFiles(projectRoot);

  // Sort files alphabetically
  files.sort();

  // If review mode, perform reviews instead of listing
  if (options.review) {
    await performReview(files);
    return;
  }

  if (options.count) {
    console.log(files.length);
    return;
  }

  // Convert to relative paths if needed
  const displayFiles = options.absolute
    ? files
    : files.map((f) => relative(projectRoot, f));

  if (options.json) {
    console.log(JSON.stringify(displayFiles, null, 2));
  } else {
    displayFiles.forEach((f) => console.log(f));
  }
}

// Run the script
main().catch((error) => {
  console.error("Error:", error.message);
  process.exit(1);
});
