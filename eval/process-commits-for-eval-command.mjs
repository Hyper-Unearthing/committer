import { Command, Option } from "clipanion";
import path from "path";
import fs from "fs/promises";
import {
  initDatabase,
  saveEvaluationTest,
  getAllCommits,
  closeDatabase,
  dropEvaluationTestsTable,
} from "./lib/database.mjs";
import BaseCommand from "./lib/base-command.mjs";

// Load amendments.json
async function loadAmendments(amendmentsPath) {
  try {
    const data = await fs.readFile(amendmentsPath, "utf8");
    return JSON.parse(data);
  } catch (error) {
    console.error(`Error loading amendments.json: ${error.message} skipping`);
    return {}; // Return empty object if file cannot be loaded
  }
}

export default class ProcessCommitsForEvaluation extends BaseCommand {
  static paths = [[`process-commits`]];

  static usage = Command.Usage({
    description: `Will process dumped commits this command will always drop and rebuild eval table.`,
    details: `
    Usage: node eval.mjs process-commits --eval-data-dir <directory_path>

    Required:
      --eval-data-dir <path>     Directory containing evaluation data (commits.db and amendments.json)
    `,
    examples: [
      [
        "process all commits cointained in ./electron-eval/commits.db using the amendments in ./electron-eval/amendments.json",
        "node eval.mjs process-commits  --eval-data-dir ./electron-eval",
      ],
    ],
  });

  async execute() {
    processCommitsForEvaluation(this.dbPath(), this.amendmentsPath());
  }
}

async function processCommitsForEvaluation(dbPath, ammendmentsPath) {
  try {
    let db = await initDatabase(dbPath);
    await dropEvaluationTestsTable(db);
    db = await initDatabase(dbPath);

    // Get all commits from the commits table
    const commits = await getAllCommits(db);
    console.log(`Found ${commits.length} commits to process`);

    const ammendments = ammendmentsPath
      ? await loadAmendments(ammendmentsPath)
      : {};
    // Process each commit and save to evaluation_tests
    let processedCount = 0;
    for (const commit of commits) {
      await processRow(db, commit, ammendments);
      processedCount++;
    }

    console.log(`\nEvaluation Processing Complete:`);
    console.log(`Total commits processed: ${processedCount}`);
    console.log(`All evaluation data has been saved to the database.`);

    // Close database connection
    await closeDatabase(db);
    console.log("Database connection closed.");
  } catch (error) {
    console.error(`Error processing commits: ${error}`);
    process.exit(1);
  }
}

export function extractTypes(commitMessage, ammendedTypes = []) {
  // Original matches with potential scopes
  let matches = commitMessage.match(
    /\b(?:feat|fix|docs|style|refactor|perf|test|build|ci)(\(\w+\))?:/g
  );
  if (!matches) {
    return null;
  }
  matches = matches.map((match) => match.replace(/:/g, ""));
  // New map to remove scopes from matches
  const matchesWithoutScopes = matches.map((match) =>
    match.replace(/\(\w+\)/g, "")
  );
  // Convert to a Set to remove duplicates, then join with |
  return [...new Set([...matchesWithoutScopes, ...ammendedTypes])].join("|");
}

async function processRow(db, commit, ammendments) {
  const { diff_content, commit_message, commit_hash_short } = commit;

  let ammendedTypes = ammendments[commit_hash_short] || [];
  let commitType = extractTypes(commit_message, ammendedTypes);
  if (!commitType) {
    console.log(`[${commit_hash_short}] Skipping commit with no valid type`);
    return;
  }
  // Save to evaluation_tests table
  await saveEvaluationTest(db, {
    diff: diff_content,
    commitMessage: commit_message,
    commitType,
    commit_hash_short,
  });
  console.log(
    `[${commit_hash_short}] Processed commit with types ${commitType}, ammendments found ${ammendedTypes.length}`
  );
}
