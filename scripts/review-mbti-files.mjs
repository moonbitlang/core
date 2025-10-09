#!/usr/bin/env node

/**
 * Script to review pkg.generated.mbti files using Codex SDK
 * Usage: node scripts/review-mbti-files.mjs [options]
 *
 * Options:
 *   --all         Review all mbti files (default)
 *   --changed     Only review changed files in git
 *   --files       Specific files to review (comma-separated)
 *   --concurrency Number of concurrent reviews (default: 5)
 *   --verbose     Show detailed progress
 */

import { fileURLToPath } from "url";
import { dirname, join, relative, basename } from "path";
import { readdir, readFile, writeFile, mkdir } from "fs/promises";
import { Codex } from "@openai/codex-sdk";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, "..");
const outputDir = join(__dirname, "output");

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  all: args.includes("--all") || !args.includes("--changed"),
  changed: args.includes("--changed"),
  concurrency: parseInt(
    args.find((a) => a.startsWith("--concurrency="))?.split("=")[1] || "5"
  ),
  verbose: args.includes("--verbose"),
  files:
    args
      .find((a) => a.startsWith("--files="))
      ?.split("=")[1]
      ?.split(",") || null,
};

/**
 * Recursively find all pkg.generated.mbti files
 */
async function findMbtiFiles(dir, results = []) {
  try {
    const entries = await readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = join(dir, entry.name);

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
    if (error.code !== "EACCES" && error.code !== "EPERM") {
      console.error(`Error reading ${dir}:`, error.message);
    }
  }

  return results;
}

/**
 * Get changed mbti files from git
 */
async function getChangedMbtiFiles() {
  try {
    const { stdout } = await execAsync("git diff --name-only HEAD", {
      cwd: projectRoot,
    });
    const changedFiles = stdout
      .split("\n")
      .filter((f) => f.endsWith("pkg.generated.mbti"))
      .map((f) => join(projectRoot, f));

    if (changedFiles.length === 0) {
      console.log("No changed pkg.generated.mbti files found");
      return [];
    }

    return changedFiles;
  } catch (error) {
    console.error("Error getting changed files:", error.message);
    return [];
  }
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

  if (options.verbose) {
    console.log(`Reviewing: ${relativePath}`);
  }

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
 * Main function
 */
async function main() {
  console.log("🔍 Starting mbti file review...\n");

  // Determine which files to review
  let filesToReview = [];

  if (options.files) {
    filesToReview = options.files.map((f) => join(projectRoot, f));
    console.log(`Reviewing ${filesToReview.length} specified file(s)`);
  } else if (options.changed) {
    filesToReview = await getChangedMbtiFiles();
    console.log(`Found ${filesToReview.length} changed mbti file(s)`);
  } else {
    filesToReview = await findMbtiFiles(projectRoot);
    console.log(`Found ${filesToReview.length} mbti file(s) to review`);
  }

  if (filesToReview.length === 0) {
    console.log("No files to review. Exiting.");
    return;
  }

  console.log(`Using concurrency limit: ${options.concurrency}\n`);

  // Initialize Codex
  const codex = new Codex();

  // Process files with concurrency control
  const startTime = Date.now();
  const results = await processConcurrently(
    filesToReview,
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

  successful.forEach((result, index) => {
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

// Run the script
main().catch((error) => {
  console.error("Error:", error.message);
  process.exit(1);
});
