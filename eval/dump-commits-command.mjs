import { Command, Option, runExit } from "clipanion";
import fs from "fs";
import path from "path";
import BaseCommand from "./lib/base-command.mjs";
import { initDatabase, saveCommit } from "./lib/database.mjs";
import {
  isValidGitRepo,
  getCommitBatch,
  getCommitInfo,
  getCommitDiff,
} from "./lib/git-utils.mjs";

export default class DumpCommits extends BaseCommand {
  static paths = [[`dump-commits`]];
  repoPath = Option.String("--repo", { required: true });

  startCommit = Option.String("--start-commit", { required: false });
  endCommit = Option.String("--end-commit", { required: false });
  maxCommits = Option.String("--max-commits", { required: false });

  static usage = Command.Usage({
    description: `Dump commits from a repository to a specified sqlite path.`,
    details: `
    Usage: node eval.mjs --repo <repository_path> --eval-data-dir <directory_path> [options]

    Required:
  
      --repo <path>              Path to the Git repository
      --eval-data-dir <path>     Directory to store evaluation data (commits.db will be created in this directory)

    Options:
      
      --start-commit <hash>      Starting commit (if omitted, starts from the first commit)
      --end-commit <hash>        Ending commit (defaults to HEAD)
      --max-commits <number>     Maximum number of commits to process
    `,
    examples: [
      [
        "dump first 50 commits from electron repository",
        "node eval.mjs dump-commits --eval-data-dir ./electron-eval --repo ../electron --max-commits 50",
      ],
    ],
  });

  async execute() {
    // Get absolute paths
    // If DB_PATH is not absolute, make it absolute based on current working directory

    // Check if repository exists
    if (!fs.existsSync(this.repoPath)) {
      console.error(`Error: Repository path does not exist: ${REPO_PATH}`);
      process.exit(1);
    }

    // Check if it's a git repository
    if (!isValidGitRepo(this.repoPath)) {
      console.error(`Error: Not a valid git repository: ${REPO_PATH}`);
      process.exit(1);
    }

    let maxCommits = Infinity;
    if (this.maxCommits) {
      maxCommits = parseInt(this.maxCommits, 10);
      if (maxCommits <= 0 || isNaN(maxCommits)) {
        console.error("Error: --max-commits must be a positive number");
        process.exit(1);
      }
    }

    processCommits(
      this.dbPath(),
      resolvePath(this.repoPath),
      maxCommits,
      this.startCommit,
      this.endCommit
    );
  }
}

function resolvePath(unresolvedPath) {
  if (!path.isAbsolute(unresolvedPath)) {
    return path.resolve(process.cwd(), unresolvedPath);
  }
  return unresolvedPath;
}

// Main function to process commits
async function processCommits(
  DB_PATH,
  REPO_PATH,
  MAX_COMMITS = Infinity,
  START_COMMIT = "",
  END_COMMIT = "HEAD"
) {
  console.log(`DB_PATH: ${DB_PATH}`);
  console.log(`REPO_PATH: ${REPO_PATH}`);
  try {
    // Initialize database
    const db = await initDatabase(DB_PATH);

    // Counter for processed commits (excluding skipped ones)
    let processedCount = 0;
    let emptyCount = 0;
    let totalFetched = 0;

    // Process commits in batches to avoid buffer overflow
    const BATCH_SIZE = 50; // Adjust this value as needed
    let skip = 0;
    let keepFetching = true;

    console.log(
      `Starting commit extraction with max commits: ${
        MAX_COMMITS === Infinity ? "unlimited" : MAX_COMMITS
      }`
    );

    while (keepFetching && totalFetched < MAX_COMMITS) {
      // Calculate how many commits to fetch in this batch
      const fetchCount = Math.min(BATCH_SIZE, MAX_COMMITS - totalFetched);

      // Get commit batch
      console.log(`Fetching commits batch: skip=${skip}, count=${fetchCount}`);
      const commitBatch = await getCommitBatch(
        REPO_PATH,
        START_COMMIT,
        END_COMMIT,
        skip,
        fetchCount
      );

      // Break if no more commits
      if (commitBatch.length === 0) {
        console.log("No more commits found.");
        break;
      }

      console.log(`Processing batch of ${commitBatch.length} commits...`);

      // Process each commit in the batch
      for (let i = 0; i < commitBatch.length; i++) {
        const COMMIT = commitBatch[i];
        totalFetched++;

        // Get short commit hash (first 8 characters)
        const SHORT_HASH = COMMIT.substring(0, 8);

        console.log(`[${totalFetched}] Processing commit ${SHORT_HASH}`);

        try {
          // Get commit information
          const { author, date, message } = getCommitInfo(REPO_PATH, COMMIT);

          // Get diff content
          const diffOutput = getCommitDiff(REPO_PATH, COMMIT);

          // Skip if commit is empty (no changes)
          if (!diffOutput.trim()) {
            console.log(` Skipping empty commit ${SHORT_HASH}`);
            emptyCount++;
            continue;
          }

          // Save to database
          await saveCommit(
            db,
            COMMIT,
            SHORT_HASH,
            date,
            author,
            message,
            diffOutput
          );

          console.log(` Saved commit ${SHORT_HASH} to database`);
          processedCount++;
        } catch (error) {
          console.error(
            ` Error processing commit ${SHORT_HASH}: ${error.message}`
          );
        }
      }

      // Update skip for next batch
      skip += commitBatch.length;

      // Break if we didn't get a full batch (means we're at the end)
      if (commitBatch.length < fetchCount) {
        keepFetching = false;
      }
    }

    console.log(`\nGit Diff Extraction Complete:`);
    console.log(`Total commits fetched: ${totalFetched}`);
    console.log(`Empty commits skipped: ${emptyCount}`);
    console.log(`Commits saved to database: ${processedCount}`);
    console.log(
      `All commit data has been saved to the database at: ${DB_PATH}`
    );

    // Close database connection
    db.close((err) => {
      if (err) {
        console.error(`Error closing database: ${err.message}`);
      } else {
        console.log("Database connection closed.");
      }
    });
  } catch (error) {
    console.error(`Error: ${error}`);
    process.exit(1);
  }
}
