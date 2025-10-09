#!/usr/bin/env node

/**
 * Utility to clean up broken review files that contain "[object Object]"
 */

import { readdir, readFile, unlink } from "fs/promises";
import { join } from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const outputDir = join(__dirname, "output");

async function cleanBrokenReviews() {
  console.log("🧹 Cleaning up broken review files...\n");
  
  try {
    const files = await readdir(outputDir);
    const reviewFiles = files.filter(f => f.endsWith('.review.md') && !f.includes('example'));
    
    let removed = 0;
    
    for (const file of reviewFiles) {
      const filePath = join(outputDir, file);
      const content = await readFile(filePath, 'utf-8');
      
      // Check if file contains [object Object]
      if (content.includes('[object Object]')) {
        console.log(`  Removing: ${file}`);
        await unlink(filePath);
        removed++;
      }
    }
    
    console.log(`\n✓ Removed ${removed} broken review file(s)`);
    console.log(`  Remaining: ${reviewFiles.length - removed} file(s)`);
    console.log('\n💡 You can now re-run the review script to generate proper reviews.');
    
  } catch (error) {
    console.error("Error:", error.message);
  }
}

cleanBrokenReviews();
