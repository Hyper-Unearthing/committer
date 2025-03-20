// Initialize SQLite database
import path from "path";
import sqlite3 from "sqlite3";
import fs from "fs";

export function initDatabase(dbPath) {
  return new Promise((resolve, reject) => {
    // Ensure the directory for the database exists
    const dbDir = path.dirname(dbPath);
    if (!fs.existsSync(dbDir)) {
      try {
        fs.mkdirSync(dbDir, { recursive: true });
        console.log(`Created directory: ${dbDir}`);
      } catch (err) {
        reject(`Error creating directory for database: ${err.message}`);
        return;
      }
    }

    const db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        reject(`Error opening database: ${err.message}`);
        return;
      }

      // Create commits table if it doesn't exist
      db.run(
        `CREATE TABLE IF NOT EXISTS commits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commit_hash TEXT NOT NULL UNIQUE,
        commit_hash_short TEXT NOT NULL,
        commit_date TEXT NOT NULL,
        author TEXT NOT NULL,
        commit_message TEXT NOT NULL,
        diff_content TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )`,
        (err) => {
          if (err) {
            reject(`Error creating table: ${err.message}`);
            return;
          }

          // Create evaluation_tests table if it doesn't exist
          db.run(
            `CREATE TABLE IF NOT EXISTS evaluation_tests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            diff TEXT,
            commit_message TEXT,
            commit_type TEXT,
            commit_body TEXT,
            commit_scope TEXT,
            commit_hash_short TEXT
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )`,
            (err) => {
              if (err) {
                reject(`Error creating evaluation_tests table: ${err.message}`);
              } else {
                console.log(`Connected to database at: ${dbPath}`);
                resolve(db);
              }
            }
          );
        }
      );
    });
  });
}

export function saveCommit(
  db,
  commitHash,
  commitHashShort,
  date,
  author,
  message,
  diff
) {
  return new Promise((resolve, reject) => {
    const stmt = db.prepare(`
      INSERT INTO commits (commit_hash, commit_hash_short, commit_date, author, commit_message, diff_content)
      VALUES (?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      commitHash,
      commitHashShort,
      date,
      author,
      message,
      diff,
      function (err) {
        if (err) {
          // Check if it's a UNIQUE constraint violation error (code 19 is SQLITE_CONSTRAINT)
          if (
            err.message.includes("UNIQUE constraint failed") ||
            err.code === 19
          ) {
            console.log(`Skipping duplicate commit ${commitHashShort}`);
            resolve(null); // Skip this commit and continue
          } else {
            reject(`Error inserting commit ${commitHashShort}: ${err.message}`);
          }
        } else {
          resolve(this.lastID);
        }
      }
    );

    stmt.finalize();
  });
}

export function saveEvaluationTest(
  db,
  { diff, commitMessage, commitType, commit_hash_short }
) {
  return new Promise((resolve, reject) => {
    const stmt = db.prepare(`
      INSERT INTO evaluation_tests (diff, commit_message, commit_type, commit_hash_short)
      VALUES (?, ?, ?, ?)
    `);

    stmt.run(
      diff,
      commitMessage,
      commitType,
      commit_hash_short,
      function (err) {
        if (err) {
          reject(`Error inserting evaluation test: ${err.message}`);
        } else {
          resolve(this.lastID);
        }
      }
    );

    stmt.finalize();
  });
}

export function getEvaluationTest(db, id) {
  return new Promise((resolve, reject) => {
    db.get(`SELECT * FROM evaluation_tests WHERE id = ?`, [id], (err, row) => {
      if (err) {
        reject(`Error retrieving evaluation test: ${err.message}`);
      } else {
        resolve(row);
      }
    });
  });
}

// Helper function to get all commits from the database
export function getAllCommits(db) {
  return new Promise((resolve, reject) => {
    db.all(
      'SELECT * FROM commits WHERE author NOT LIKE "%[bot]"',
      [],
      (err, rows) => {
        if (err) {
          reject(`Error retrieving commits: ${err.message}`);
        } else {
          resolve(rows);
        }
      }
    );
  });
}

export function getAllEvaluationTests(
  db,
  { limit = null, commitShortSha = null } = {}
) {
  return new Promise((resolve, reject) => {
    let query = `SELECT * FROM evaluation_tests`;
    const params = [];

    if (commitShortSha) {
      query += ` WHERE commit_hash_short = ?`;
      params.push(commitShortSha);
    }

    query += ` ORDER BY id DESC`;

    if (limit) {
      query += ` LIMIT ?`;
      params.push(limit);
    }

    db.all(query, params, (err, rows) => {
      if (err) {
        reject(`Error retrieving evaluation tests: ${err.message}`);
      } else {
        resolve(rows);
      }
    });
  });
}

// Helper function to drop the evaluation_tests table
export function dropEvaluationTestsTable(db) {
  return new Promise((resolve, reject) => {
    db.run(`DROP TABLE IF EXISTS evaluation_tests`, (err) => {
      if (err) {
        reject(`Error dropping evaluation_tests table: ${err.message}`);
      } else {
        console.log("Dropped existing evaluation_tests table");
        resolve();
      }
    });
  });
}

// Helper function to close the database connection
export function closeDatabase(db) {
  return new Promise((resolve, reject) => {
    db.close((err) => {
      if (err) {
        reject(`Error closing database: ${err.message}`);
      } else {
        resolve();
      }
    });
  });
}
