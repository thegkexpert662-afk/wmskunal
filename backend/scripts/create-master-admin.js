require('dotenv').config();

const readline = require('node:readline');
const argon2 = require('argon2');
const pool = require('../src/config/db');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

async function main() {
  try {
    const username = (await ask('Master Admin username: ')).trim();
    const fullName = (await ask('Full name: ')).trim();
    const password = await ask('Master Admin password: ');

    if (!username || !fullName || !password) {
      throw new Error('Username, full name and password are required.');
    }

    if (password.length < 12) {
      throw new Error('Password must be at least 12 characters.');
    }

    const existing = await pool.query(
      'SELECT id FROM users WHERE username = $1 LIMIT 1',
      [username],
    );

    if (existing.rowCount > 0) {
      throw new Error('Username already exists.');
    }

    const passwordHash = await argon2.hash(password, {
      type: argon2.argon2id,
    });

    const result = await pool.query(
      `INSERT INTO users
        (username, full_name, password_hash, role, is_active)
       VALUES ($1, $2, $3, 'master_admin', TRUE)
       RETURNING id, username, full_name, role`,
      [username, fullName, passwordHash],
    );

    console.log('Master Admin created successfully.');
    console.log(result.rows[0]);
  } catch (error) {
    console.error(`Failed: ${error.message}`);
    process.exitCode = 1;
  } finally {
    rl.close();
    await pool.end();
  }
}

main();