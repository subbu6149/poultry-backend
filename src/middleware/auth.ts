import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import db from '../config/database';
import logger from '../config/logger';

export interface AuthRequest extends Request {
  user?: {
    id: number;
    username: string;
    role_id: number;
    role_name: string;
  };
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
    req.user = decoded;
    next();
  } catch (error) {
    logger.error('Authentication error:', error);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

export const authorize = (modules: string[], actions: string[]) => {
  return async (
    req: AuthRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Authentication required' });
        return;
      }

      // Super Admin (role_id = 1) has all permissions
      if (req.user.role_id === 1) {
        next();
        return;
      }

      // Check permissions from database
      // For any action that modifies data, check for EDIT permission
      // For read-only operations, check for VIEW or EDIT permission
      const requiredActions = actions.includes('VIEW') 
        ? ['VIEW', 'EDIT']  // VIEW access accepts both VIEW and EDIT permissions
        : ['EDIT'];          // All other operations require EDIT permission

      const [permissions] = await db.query(
        `SELECT p.module, p.action 
         FROM role_permissions rp
         JOIN permissions p ON rp.permission_id = p.id
         WHERE rp.role_id = ? AND rp.granted = TRUE
         AND p.module IN (?) AND p.action IN (?)`,
        [req.user.role_id, modules, requiredActions]
      );

      if ((permissions as any[]).length === 0) {
        res.status(403).json({ error: 'Insufficient permissions' });
        return;
      }

      next();
    } catch (error) {
      logger.error('Authorization error:', error);
      res.status(500).json({ error: 'Authorization check failed' });
    }
  };
};
