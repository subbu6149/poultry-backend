import { Response } from 'express';
import bcrypt from 'bcryptjs';
import { body, validationResult } from 'express-validator';
import db from '../config/database';
import logger from '../config/logger';
import { AuthRequest } from '../middleware/auth';

export const createUserValidation = [
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('phone').trim().notEmpty().withMessage('Phone number is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role_id').isInt({ min: 1 }).withMessage('Valid role is required'),
];

export const updateUserValidation = [
  body('full_name').optional().trim().notEmpty().withMessage('Full name cannot be empty'),
  body('phone').optional().trim().notEmpty().withMessage('Phone cannot be empty'),
  body('role_id').optional().isInt({ min: 1 }).withMessage('Valid role is required'),
];

export const getAllUsers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [users] = await db.query(
      `SELECT u.id, u.username, u.full_name, u.phone, u.role_id, 
              r.name as role_name, u.is_active, u.last_login, u.created_at
       FROM users u
       LEFT JOIN roles r ON u.role_id = r.id
       ORDER BY u.created_at DESC`
    );

    res.json({ users });
  } catch (error) {
    logger.error('Get all users error:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
};

export const getUserById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const [users] = await db.query(
      `SELECT u.id, u.username, u.full_name, u.phone, u.role_id, 
              r.name as role_name, u.is_active, u.last_login, u.created_at, u.updated_at
       FROM users u
       LEFT JOIN roles r ON u.role_id = r.id
       WHERE u.id = ?`,
      [id]
    );

    const user = (users as any[])[0];

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.json({ user });
  } catch (error) {
    logger.error('Get user by ID error:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
};

export const createUser = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { full_name, phone, password, role_id } = req.body;

    // Auto-generate username from phone number
    const username = `user_${phone}`;

    // Check if phone already exists
    const [existing] = await db.query(
      'SELECT id FROM users WHERE phone = ?',
      [phone]
    );

    if ((existing as any[]).length > 0) {
      res.status(400).json({ error: 'Phone number already exists' });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert user
    const [result] = await db.query(
      `INSERT INTO users (username, password_hash, full_name, phone, role_id, created_by)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [username, hashedPassword, full_name, phone, role_id, req.user!.id]
    );

    const userId = (result as any).insertId;

    // Audit log
    await db.query(
      'INSERT INTO audit_log (user_id, action, entity_type, entity_id, new_values) VALUES (?, ?, ?, ?, ?)',
      [req.user!.id, 'CREATE', 'USER', userId, JSON.stringify({ username, full_name, phone })]
    );

    logger.info(`User created: ${username} by ${req.user!.username}`);

    res.status(201).json({
      message: 'User created successfully',
      userId,
      username,
    });
  } catch (error) {
    logger.error('Create user error:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
};

export const updateUser = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { id } = req.params;
    const { full_name, phone, role_id, is_active } = req.body;

    // Check if user exists
    const [users] = await db.query('SELECT * FROM users WHERE id = ?', [id]);
    const user = (users as any[])[0];

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    // Prevent admin from deactivating themselves
    if (id === String(req.user!.id) && is_active === false) {
      res.status(400).json({ error: 'You cannot deactivate your own account' });
      return;
    }

    const updates: string[] = [];
    const values: any[] = [];

    if (full_name) {
      updates.push('full_name = ?');
      values.push(full_name);
    }
    if (phone !== undefined) {
      updates.push('phone = ?');
      values.push(phone);
    }
    if (role_id) {
      updates.push('role_id = ?');
      values.push(role_id);
    }
    if (is_active !== undefined) {
      updates.push('is_active = ?');
      values.push(is_active);
    }

    updates.push('updated_by = ?', 'updated_at = NOW()');
    values.push(req.user!.id);

    values.push(id);

    await db.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
      values
    );

    // Audit log
    await db.query(
      'INSERT INTO audit_log (user_id, action, entity_type, entity_id, old_values, new_values) VALUES (?, ?, ?, ?, ?, ?)',
      [req.user!.id, 'UPDATE', 'USER', id, JSON.stringify(user), JSON.stringify(req.body)]
    );

    logger.info(`User updated: ID ${id} by ${req.user!.username}`);

    res.json({ message: 'User updated successfully' });
  } catch (error) {
    logger.error('Update user error:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
};

export const deleteUser = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Prevent deleting yourself
    if (id === String(req.user!.id)) {
      res.status(400).json({ error: 'You cannot delete your own account' });
      return;
    }

    // Check if user exists
    const [users] = await db.query('SELECT * FROM users WHERE id = ?', [id]);
    const user = (users as any[])[0];

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    // Soft delete by deactivating
    await db.query('UPDATE users SET is_active = FALSE, updated_by = ?, updated_at = NOW() WHERE id = ?', [
      req.user!.id,
      id,
    ]);

    // Audit log
    await db.query(
      'INSERT INTO audit_log (user_id, action, entity_type, entity_id, old_values) VALUES (?, ?, ?, ?, ?)',
      [req.user!.id, 'DELETE', 'USER', id, JSON.stringify(user)]
    );

    logger.info(`User deleted: ID ${id} by ${req.user!.username}`);

    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    logger.error('Delete user error:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
};

export const resetUserPassword = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      res.status(400).json({ error: 'Password must be at least 6 characters' });
      return;
    }

    // Check if user exists
    const [users] = await db.query('SELECT id, username FROM users WHERE id = ?', [id]);
    if ((users as any[]).length === 0) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await db.query('UPDATE users SET password_hash = ?, updated_by = ?, updated_at = NOW() WHERE id = ?', [
      hashedPassword,
      req.user!.id,
      id,
    ]);

    logger.info(`Password reset for user ID ${id} by ${req.user!.username}`);

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    logger.error('Reset password error:', error);
    res.status(500).json({ error: 'Failed to reset password' });
  }
};
