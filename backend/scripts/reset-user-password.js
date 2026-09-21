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
    const username = (await ask('Username: ')).trim();
    const password = await ask('New password: ');

    if (!username || !password) {
      throw new Error('Username and password are required.');
    }

    if (password.length < 12) {
      throw new Error('Password must be at least 12 characters.');
    }

    const passwordHash = await argon2.hash(password, {
      type: argon2.argon2id,
    });

    const result = await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE username = $2 RETURNING username, role',
      [passwordHash, username],
    );

    if (result.rowCount === 0) {
      throw new Error('User not found.');
    }

    console.log('Password updated successfully.');
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