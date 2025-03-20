import { execSync, spawn } from "child_process";
import fs from "fs";

/**
 * Check if the given path is a valid git repository
 * @param {string} repoPath - Path to the repository
 * @returns {boolean} True if valid git repository
 */
export function isValidGitRepo(repoPath) {
  try {
    execSync("git rev-parse --is-inside-work-tree", { cwd: repoPath });
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Get a batch of commit hashes using pagination
 * @param {string} repoPath - Path to the repository
 * @param {string} startCommit - Starting commit (optional)
 * @param {string} endCommit - Ending commit (defaults to HEAD)
 * @param {number} skip - Number of commits to skip
 * @param {number} maxCount - Maximum number of commits to fetch
 * @returns {Promise<string[]>} Array of commit hashes
 */
export function getCommitBatch(
  repoPath,
  startCommit,
  endCommit,
  skip,
  maxCount
) {
  console.log(repoPath, startCommit, endCommit, skip, maxCount);
  return new Promise((resolve, reject) => {
    let commitRange = "";
    if (startCommit && endCommit !== "HEAD") {
      commitRange = `${startCommit}..${endCommit}`;
    } else if (startCommit) {
      commitRange = `${startCommit}..HEAD`;
    } else if (endCommit !== "HEAD") {
      commitRange = `${endCommit}`;
    }

    // Build the git log command with pagination
    const gitArgs = [
      "log",
      "--pretty=format:%H",
      "--skip",
      skip.toString(),
      "--max-count",
      maxCount.toString(),
    ];
    if (commitRange) {
      gitArgs.push(commitRange);
    }

    const gitProcess = spawn("git", gitArgs, { cwd: repoPath });
    let stdout = "";
    let stderr = "";

    gitProcess.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    gitProcess.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    gitProcess.on("close", (code) => {
      if (code !== 0) {
        reject(`Git error: ${stderr}`);
        return;
      }

      const commits = stdout.trim().split("\n").filter(Boolean);
      resolve(commits);
    });
  });
}

/**
 * Get commit information including author, date, and commit message
 * @param {string} repoPath - Path to the repository
 * @param {string} commitHash - Full commit hash
 * @returns {Object} Commit information with author, date, subject, body, and message
 */
export function getCommitInfo(repoPath, commitHash) {
  const commitInfo = execSync(
    `git show --pretty=format:"%an|%ad|%s%n%b" --no-patch ${commitHash}`,
    {
      encoding: "utf8",
      cwd: repoPath,
    }
  ).trim();

  const [authorDateSubject, ...bodyLines] = commitInfo.split("\n");
  const [author, date, ...subjectParts] = authorDateSubject.split("|");
  const subject = subjectParts.join("|"); // In case subject contained the delimiter
  const body = bodyLines.join("\n");
  const message = subject + (body ? "\n\n" + body : "");

  return {
    author,
    date,
    subject,
    body,
    message,
  };
}

/**
 * Get the diff content for a specific commit
 * @param {string} repoPath - Path to the repository
 * @param {string} commitHash - Full commit hash
 * @returns {string} Diff content
 */
export function getCommitDiff(repoPath, commitHash) {
  return execSync(`git show --no-commit-id --format="" --patch ${commitHash}`, {
    encoding: "utf8",
    cwd: repoPath,
  });
}
