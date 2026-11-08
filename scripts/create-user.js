const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function createUser() {
  const username = 'subbu';
  const password = '1234';
  const fullName = 'Subbu Manager';
  const roleId = 1; // Super Admin

  try {
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    console.log('Password hashed successfully');

    // Connect to database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'farm_manager',
    });

    console.log('Connected to database');

    // Check if user exists
    const [existing] = await connection.query(
      'SELECT id FROM users WHERE username = ?',
      [username]
    );

    if (existing.length > 0) {
      console.log('User already exists, updating password...');
      await connection.query(
        'UPDATE users SET password_hash = ? WHERE username = ?',
        [hashedPassword, username]
      );
      console.log('✅ Password updated for user:', username);
    } else {
      // Create new user
      await connection.query(
        'INSERT INTO users (username, password_hash, full_name, role_id, is_active, created_by) VALUES (?, ?, ?, ?, TRUE, 1)',
        [username, hashedPassword, fullName, roleId]
      );
      console.log('✅ User created successfully!');
    }

    console.log('\n--- Login Credentials ---');
    console.log('Username:', username);
    console.log('Password:', password);
    console.log('Role: Super Admin');
    console.log('------------------------\n');

    await connection.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createUser();
