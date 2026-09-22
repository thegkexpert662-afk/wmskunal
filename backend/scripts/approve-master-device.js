require('dotenv').config();

const readline = require('node:readline');
const argon2 = require('argon2');
const pool = require('../src/config/db');

if (process.env.NODE_ENV === 'production') {
  console.error('Refusing local bootstrap approval while NODE_ENV=production.');
  process.exit(1);
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

function askSecret(question) {
  return new Promise((resolve) => {
    process.stdout.write(question);
    process.stdin.setRawMode(true);
    process.stdin.resume();
    let value = '';

    const onData = (chunk) => {
      const input = chunk.toString('utf8');

      for (const char of input) {
        if (char === '\\u0003') {
          process.stdin.setRawMode(false);
          process.stdin.removeListener('data', onData);
          process.exit(130);
        }

        if (char === '\\r' || char === '\\n') {
          process.stdin.setRawMode(false);
          process.stdin.removeListener('data', onData);
          process.stdout.write('\\n');
          resolve(value);
          return;
        }

        if (char === '\\u007f' || char === '\\b') {
          value = value.slice(0, -1);
          continue;
        }

        value += char;
      }
    };

    process.stdin.on('data', onData);
  });
}

async function main() {
  const client = await pool.connect();

  try {
    const username = (await ask('Master Admin username: ')).trim();
    const password = await askSecret('Master Admin password: ');

    if (!username || !password) {
      throw new Error('Username and password are required.');
    }

    const userResult = await client.query(
      `SELECT id, username, full_name, role, is_active, password_hash, company_id
       FROM users
       WHERE username = $1
       LIMIT 1`,
      [username],
    );

    if (userResult.rowCount === 0) {
      throw new Error('Master Admin account not found.');
    }

    const user = userResult.rows[0];

    if (user.role !== 'master_admin' || !user.is_active) {
      throw new Error('The supplied account is not an active Master Admin.');
    }

    const passwordValid = await argon2.verify(user.password_hash, password);

    if (!passwordValid) {
      throw new Error('Invalid Master Admin credentials.');
    }

    const devicesResult = await client.query(
      `SELECT id, device_name, device_type, credential_id, first_registered_at
       FROM devices
       WHERE user_id = $1
         AND status = 'pending'
       ORDER BY first_registered_at ASC`,
      [user.id],
    );

    if (devicesResult.rowCount === 0) {
      console.log('No pending device was found for this Master Admin.');
      return;
    }

    console.log('\\nPending devices:');
    devicesResult.rows.forEach((device, index) => {
      console.log(
        `[${index + 1}] ${device.id} | ${device.device_name || 'Unnamed'} | ${device.device_type || 'Unknown'} | registered ${device.first_registered_at.toISOString()}`,
      );
    });

    const deviceId = (await ask('\\nEnter the exact Device ID to approve: ')).trim();

    if (!devicesResult.rows.some((device) => device.id === deviceId)) {
      throw new Error('That Device ID is not one of the pending devices for this Master Admin.');
    }

    await client.query('BEGIN');

    const updateResult = await client.query(
      `UPDATE devices
       SET status = 'approved',
           approved_by = $1,
           approved_at = NOW()
       WHERE id = $2
         AND user_id = $1
         AND status = 'pending'
       RETURNING id, device_name, device_type, status, approved_at`,
      [user.id, deviceId],
    );

    if (updateResult.rowCount !== 1) {
      throw new Error('Device approval failed because its state changed or it no longer belongs to this Master Admin.');
    }

    await client.query(
      `INSERT INTO audit_logs
        (company_id, user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, $2, 'DEVICE_APPROVED_BOOTSTRAP', 'device', $3, $4::jsonb)`,
      [
        user.company_id || null,
        user.id,
        deviceId,
        JSON.stringify({
          method: 'local_bootstrap',
          reason: 'initial_master_admin_device_enrollment',
        }),
      ],
    );

    await client.query('COMMIT');

    console.log('\\nDevice approved successfully.');
    console.log(updateResult.rows[0]);
    console.log('You can now log in from that Chrome device.');
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {
      // Ignore rollback errors after a failed transaction.
    }
    console.error(`\\nFailed: ${error.message}`);
    process.exitCode = 1;
  } finally {
    client.release();
    rl.close();
    await pool.end();
  }
}

main();
