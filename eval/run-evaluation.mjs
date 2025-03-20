import promptfoo from "promptfoo";
import { Command, Option } from "clipanion";
import { initDatabase, getAllEvaluationTests } from "./lib/database.mjs";
import path from "path";
import fs from "fs";
import BaseCommand from "./lib/base-command.mjs";

const commitMessagePromptPath = path.resolve(
  "./lib/committer/config/defaults/commit_message_only.prompt"
);

export function readCommitMessagePrompt({ vars, provider }) {
  const promptContent = fs.readFileSync(commitMessagePromptPath, "utf8");
  return promptContent
    .replaceAll("{{DIFF}}", vars.DIFF)
    .replaceAll("{{SCOPES}}", "");
}

export default class RunEvaluation extends BaseCommand {
  static paths = [[`run-evaluation`]];

  commitShortSha = Option.String("--sha", { required: false });
  limit = Option.String("--limit", { required: false });

  static usage = Command.Usage({
    description: `Run evaluation on commit data`,
    details: `
    Usage: node eval.mjs run-evaluation --eval-data-dir <directory_path> [--sha <commit_sha>] [--limit <number>]

    Required:
      --eval-data-dir <path>   Directory containing evaluation data (commits.db)

    Optional:
      --sha <commit_sha>       Evaluate a specific commit by its short SHA
      --limit <number>         Limit the number of tests to evaluate
    `,
    examples: [
      [
        "run evluation on all commits",
        "node eval.mjs run-evaluation --eval-data-dir ./electron-eval",
      ],
      [
        "run evaluation on a specific commit",
        "node eval.mjs run-evaluation --eval-data-dir ./electron-eval --sha 989918a5",
      ],
    ],
  });

  async execute() {
    await runEvaluation(
      this.dbPath(),
      this.commitShortSha,
      this.limit ? parseInt(this.limit, 10) : null
    );
  }
}

async function runEvaluation(dbPath, commitShortSha, limit) {
  try {
    // Set PROMPTFOO_DISABLE_TEMPLATING environment variable
    process.env.PROMPTFOO_DISABLE_TEMPLATING = "true";

    // Get tests using the refined database function
    const filteredTests = await getFilteredTests(dbPath, commitShortSha, limit);

    const testSuite = {
      description: "Getting started",
      prompts: [readCommitMessagePrompt],
      providers: [
        "anthropic:messages:claude-3-7-sonnet-20250219",
        "anthropic:messages:claude-3-5-haiku-20241022",
        "openai:gpt-4o",
        "openai:gpt-4o-mini",
      ],
      tests: filteredTests,
      writeLatestResults: !commitShortSha, // Only write results if not evaluating a single SHA
    };

    const options = {
      maxConcurrency: 5,
      showProgressBar: true,
      delay: 10,
    };

    const results = await promptfoo.evaluate(testSuite, options);

    // If evaluating a single SHA, display results in console instead of writing to file
    if (commitShortSha) {
      console.log(`Evaluation results for commit ${commitShortSha}:`);
      for (const result of results.results) {
        console.log(`Provider: ${result.provider.id}`);
        console.log(`output: ${result.response?.output}`);
        console.log(`Success: ${result.success}`);
        console.log(`Error: ${result.error}`);
        console.log("-----------------------------------");
      }
    }

    console.log("Evaluation completed successfully.");
  } catch (error) {
    console.error(`Error running evaluation: ${error}`);
    process.exit(1);
  }
}

// Helper function to get filtered tests from database
async function getFilteredTests(dbPath, commitShortSha, limit) {
  const db = await initDatabase(dbPath);
  const results = await getAllEvaluationTests(db, { limit, commitShortSha });

  return results.map((row, i) => ({
    vars: {
      DIFF: row.diff,
      commit_type: row.commit_type,
      sha_short: row.commit_hash_short,
    },
    assert: [
      { type: "regex", value: "[^()]*:s?.*" },
      { type: "regex", value: "^.*:s?.*$" },
      { type: "regex", value: `^(${row.commit_type})` },
    ],
    description: `Test #${i + 1} (${row.commit_hash_short})`,
  }));
}
