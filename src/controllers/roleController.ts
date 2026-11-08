import { Response } from 'express';
import { body, validationResult } from 'express-validator';
import db from '../config/database';
import logger from '../config/logger';
import { AuthRequest } from '../middleware/auth';

export const createRoleValidation = [
  body('name').trim().notEmpty().withMessage('Role name is required'),
  body('description').optional().trim(),
];

export const getAllRoles = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [roles] = await db.query(
      `SELECT r.*, 
              (SELECT COUNT(*) FROM users WHERE role_id = r.id) as user_count
       FROM roles r
       ORDER BY r.id ASC`
    );

    res.json({ roles });
  } catch (error) {
    logger.error('Get all roles error:', error);
    res.status(500).json({ error: 'Failed to fetch roles' });
  }
};

export const getRoleById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const [roles] = await db.query('SELECT * FROM roles WHERE id = ?', [id]);
    const role = (roles as any[])[0];

    if (!role) {
      res.status(404).json({ error: 'Role not found' });
      return;
    }

    // Get permissions for this role
    const [permissions] = await db.query(
      `SELECT p.*, rp.granted
       FROM permissions p
       LEFT JOIN role_permissions rp ON p.id = rp.permission_id AND rp.role_id = ?
       ORDER BY p.module, p.action`,
      [id]
    );

    res.json({ role, permissions });
  } catch (error) {
    logger.error('Get role by ID error:', error);
    res.status(500).json({ error: 'Failed to fetch role' });
  }
};

export const createRole = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { name, description } = req.body;

    // Check if role exists
    const [existing] = await db.query('SELECT id FROM roles WHERE name = ?', [name]);
    if ((existing as any[]).length > 0) {
      res.status(400).json({ error: 'Role name already exists' });
      return;
    }

    const [result] = await db.query(
      'INSERT INTO roles (name, description, is_system) VALUES (?, ?, FALSE)',
      [name, description || null]
    );

    const roleId = (result as any).insertId;

    logger.info(`Role created: ${name} by ${req.user!.username}`);

    res.status(201).json({
      message: 'Role created successfully',
      roleId,
    });
  } catch (error) {
    logger.error('Create role error:', error);
    res.status(500).json({ error: 'Failed to create role' });
  }
};

export const updateRole = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { id } = req.params;
    const { name, description } = req.body;

    // Check if role exists and is not system role
    const [roles] = await db.query('SELECT * FROM roles WHERE id = ?', [id]);
    const role = (roles as any[])[0];

    if (!role) {
      res.status(404).json({ error: 'Role not found' });
      return;
    }

    if (role.is_system) {
      res.status(400).json({ error: 'System roles cannot be modified' });
      return;
    }

    await db.query(
      'UPDATE roles SET name = ?, description = ?, updated_at = NOW() WHERE id = ?',
      [name || role.name, description !== undefined ? description : role.description, id]
    );

    logger.info(`Role updated: ID ${id} by ${req.user!.username}`);

    res.json({ message: 'Role updated successfully' });
  } catch (error) {
    logger.error('Update role error:', error);
    res.status(500).json({ error: 'Failed to update role' });
  }
};

export const deleteRole = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Check if role exists and is not system role
    const [roles] = await db.query('SELECT * FROM roles WHERE id = ?', [id]);
    const role = (roles as any[])[0];

    if (!role) {
      res.status(404).json({ error: 'Role not found' });
      return;
    }

    if (role.is_system) {
      res.status(400).json({ error: 'System roles cannot be deleted' });
      return;
    }

    // Check if any users have this role
    const [users] = await db.query('SELECT COUNT(*) as count FROM users WHERE role_id = ?', [id]);
    if ((users as any[])[0].count > 0) {
      res.status(400).json({ error: 'Cannot delete role. Users are assigned to this role.' });
      return;
    }

    await db.query('DELETE FROM roles WHERE id = ?', [id]);

    logger.info(`Role deleted: ID ${id} by ${req.user!.username}`);

    res.json({ message: 'Role deleted successfully' });
  } catch (error) {
    logger.error('Delete role error:', error);
    res.status(500).json({ error: 'Failed to delete role' });
  }
};

export const updateRolePermissions = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { permissions } = req.body; // Array of { permission_id, granted }

    if (!Array.isArray(permissions)) {
      res.status(400).json({ error: 'Permissions must be an array' });
      return;
    }

    // Check if role exists and is not system role
    const [roles] = await db.query('SELECT * FROM roles WHERE id = ?', [id]);
    const role = (roles as any[])[0];

    if (!role) {
      res.status(404).json({ error: 'Role not found' });
      return;
    }

    if (role.is_system && role.id === 1) {
      res.status(400).json({ error: 'Super Admin role permissions cannot be modified' });
      return;
    }

    // Delete existing permissions
    await db.query('DELETE FROM role_permissions WHERE role_id = ?', [id]);

    // Insert new permissions
    if (permissions.length > 0) {
      const values = permissions
        .filter((p: any) => p.granted)
        .map((p: any) => [id, p.permission_id, true]);

      if (values.length > 0) {
        await db.query(
          'INSERT INTO role_permissions (role_id, permission_id, granted) VALUES ?',
          [values]
        );
      }
    }

    logger.info(`Role permissions updated: ID ${id} by ${req.user!.username}`);

    res.json({ message: 'Permissions updated successfully' });
  } catch (error) {
    logger.error('Update role permissions error:', error);
    res.status(500).json({ error: 'Failed to update permissions' });
  }
};

export const getAllPermissions = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [permissions] = await db.query(
      'SELECT * FROM permissions ORDER BY module, action'
    );

    // Group by module
    const grouped: any = {};
    (permissions as any[]).forEach((perm) => {
      if (!grouped[perm.module]) {
        grouped[perm.module] = [];
      }
      grouped[perm.module].push(perm);
    });

    res.json({ permissions, grouped });
  } catch (error) {
    logger.error('Get all permissions error:', error);
    res.status(500).json({ error: 'Failed to fetch permissions' });
  }
};
