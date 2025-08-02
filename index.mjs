// @ts-check
import { exec } from "node:child_process";
import { promisify } from "node:util";
import fs from "fs-extra";
import { ChatOpenAI } from "@langchain/openai";
import { DynamicStructuredTool } from "@langchain/core/tools";
import { z } from "zod";
import { randomUUID } from "node:crypto";

const systemMessage = `
You are a MoonBit programming language expert. Review the following MoonBit interface definitions (MBTI) and provide constructive feedback on the API design, consistency, naming conventions, and any potential improvements.

You have access to a tool called \`read_file_block\` that allows you to read specific blocks of MoonBit source files. MoonBit code is organized in blocks separated by \`///|\` markers. Use this tool to examine implementation details if needed during your review.

### Review Criteria
1. Clarity and readability of the interface definitions.
2. Consistency in naming conventions and structure.
3. Suggestions for improving usability and functionality.
4. Be specific on the review. Point out the API that is problematic, together with arguments, and suggested improvements.

### API Guidelines
1. We have limited manpower, so we rather not having too many helper functions that user can define themselves, unless such function can only be defined internally to achieve the best performance.
2. We prefer to follow the Rust standard library's design principles, which emphasize simplicity, performance, and safety.
3. We aim to provide a familiarity for AIs (like you), so that they can easily understand and use the interfaces without extensive documentation. As a result, we prefer to follow the naming conventions of existing programming languages like Rust, Python, JavaScript, and Go.

You will be provided with some relevant MoonBit interfaces. They often represent a similar data structure, such as HashMap & SortedMap & immutable HashMap, etc.
You also need to review the consistency of the interfaces, such as whether the naming conventions are consistent across different interfaces, and whether the same functionality is provided in a similar way across different interfaces.

Please provide your review in a structured format, highlighting strengths and areas for improvement. Use bullet points for clarity and ensure your feedback is actionable.

### Complementary Information
- tilde in parameter names (\`init~\`) indicates that the parameter is optional. The \`= ..\` syntax indicates a default value.
- The \`Self[A]\` syntax stands for the type that the method belongs to. For example \`Self[A]\` in \`Array::map\` means \`Array[A]\`.
`;

const execPromise = promisify(exec);

// Create directory for storing MBTI data and reviews
const MBTI_DIR = "./mbti_data";
const REVIEWS_DIR = "./mbti_reviews";

async function ensureDirectories() {
  await fs.ensureDir(MBTI_DIR);
  await fs.ensureDir(REVIEWS_DIR);
}

/**
 * Extract MBTI interface for a given type using mbti_inspector
 * @param {string} typeName - The name of the type to inspect
 * @returns {Promise<string>} - The MBTI interface content
 */
async function extractMbti(typeName) {
  try {
    console.log(`Extracting MBTI interface for ${typeName}...`);
    const { stdout } = await execPromise(`mbti_inspector.exe ${typeName}`);
    const outputPath = `${MBTI_DIR}/${typeName}_interface.txt`;
    await fs.writeFile(outputPath, stdout);
    console.log(`Saved ${typeName} interface to ${outputPath}`);
    return stdout;
  } catch (error) {
    console.error(`Error extracting MBTI for ${typeName}:`, error);
    throw error;
  }
}

/**
 * Create the read_file_block tool using LangChain's DynamicStructuredTool
 */
const extractCommentTool = new DynamicStructuredTool({
  name: "extract_comment_tool",
  description:
    "Get the comment of a MoonBit interface by reading the file block up to a specific line number.",
  schema: z.object({
    file: z.string().describe("The path to the file to read"),
    line: z
      .number()
      .int()
      .positive()
      .describe("The target line number to read up to (1-indexed)"),
  }),
  func: async ({ file, line }) => {
    try {
      console.log(`Reading file block from ${file} up to line ${line}...`);

      // Read the entire file
      const content = await fs.readFile(file, "utf-8");
      const lines = content.split("\n");

      // Validate target line
      if (line < 1 || line > lines.length) {
        throw new Error(
          `Target line ${line} is out of range. File has ${lines.length} lines.`
        );
      }

      // Find the closest `///|` marker before the target line
      let blockStartLine = 0; // Default to start of file if no marker found

      for (let i = line - 2; i >= 0; i--) {
        // line - 1 for 0-indexed, -1 more to look before
        if (lines[i].trim() === "///|") {
          blockStartLine = i;
          break;
        }
      }

      // Extract lines from block start to target line (inclusive)
      const blockLines = lines.slice(blockStartLine, line);
      const result = blockLines.join("\n");

      console.log(
        `Found block starting at line ${blockStartLine + 1}, reading ${
          blockLines.length
        } lines`
      );
      return result;
    } catch (error) {
      console.error(`Error reading file block from ${file}:`, error);
      throw error;
    }
  },
});

/**
 * Review MBTI interfaces using LangChain ChatOpenAI with tools
 * @param {Object} interfaces - Object containing interface names and their content
 * @param {string} model - The OpenAI model to use for the review
 * @returns {Promise<string>} - The review from the AI
 */
async function reviewInterfaces(interfaces, model) {
  try {
    console.log("Requesting review from OpenAI with LangChain...");

    // Initialize ChatOpenAI with tools
    const llm = new ChatOpenAI({
      model,
      temperature: 0,
      maxTokens: 4000,
    });

    // Bind tools to the model
    const llmWithTools = llm.bindTools([extractCommentTool]);

    const prompt = Object.entries(interfaces)
      .map(([name, content]) => `${name} Interface:\n${content}\n\n`)
      .join("\n");

    const userMessage = `Please review these MoonBit interfaces and provide your expert opinion on their design, usability, and any suggestions for improvement:\n\n${prompt}`;

    // Initial response
    const response = await llmWithTools.invoke([
      { role: "system", content: systemMessage },
      { role: "user", content: userMessage },
    ]);

    let finalResponse = response.content;

    if (typeof finalResponse !== "string") {
      console.warn("Response content is not a string, converting to string.");
      finalResponse = JSON.stringify(finalResponse);
    }

    return finalResponse ?? "No review provided.";
  } catch (error) {
    console.error("Error getting review from OpenAI:", error);
    throw error;
  }
}

/**
 * Main function to run the MBTI reviewer
 */
async function main() {
  try {
    await ensureDirectories();

    // Types to review
    const types = process.argv.slice(2);

    if (types.length === 0) {
      console.error(
        "No types provided for review. Please specify types as command line arguments."
      );
    } else {
      console.log(`Reviewing types: ${types.join(", ")}.`);
    }

    // Extract MBTI for each type
    const interfaces = {};
    for (const type of types) {
      interfaces[type] = await extractMbti(type);
    }

    const model = process.env.MODEL ?? "gpt-4"; // or a suitable model

    // Get review from OpenAI
    const review = await reviewInterfaces(interfaces, model);

    // Save the review
    const reviewPath = `${REVIEWS_DIR}/interface-review-${types.join(
      "-"
    )}-${randomUUID()}.md`;
    await fs.writeFile(
      reviewPath,
      `---
time : ${new Date().toISOString()}
model : ${model}
---
${review}`
    );

    console.log(`Review completed and saved to ${reviewPath}`);
    console.log("Summary of review:");
    console.log(review.substring(0, 200) + "...");
  } catch (error) {
    console.error("Error in MBTI reviewer:", error);
  }
}

// Run the main function
main();
