const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function createAdminUser() {
  const phone = '9999';
  const password = '9999';
  const fullName = 'Super Admin';
  const roleId = 1; // Super Admin role

  const username = `user_${phone}`;

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
      'SELECT id FROM users WHERE phone = ?',
      [phone]
    );

    if (existing.length > 0) {
      console.log('User already exists, updating...');
      await connection.query(
        'UPDATE users SET password_hash = ?, full_name = ?, role_id = ?, username = ? WHERE phone = ?',
        [hashedPassword, fullName, roleId, username, phone]
      );
      console.log('✅ User updated successfully!');
    } else {
      // Create new user
      await connection.query(
        'INSERT INTO users (username, password_hash, full_name, phone, role_id, is_active, created_by) VALUES (?, ?, ?, ?, ?, TRUE, 1)',
        [username, hashedPassword, fullName, phone, roleId]
      );
      console.log('✅ User created successfully!');
    }

    console.log('\n--- Super Admin Login Credentials ---');
    console.log('Phone:', phone);
    console.log('Password:', password);
    console.log('Role: Super Admin');
    console.log('-------------------------------------\n');

    await connection.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createAdminUser();
