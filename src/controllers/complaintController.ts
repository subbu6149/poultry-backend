import { Response } from 'express';
import { body, validationResult } from 'express-validator';
import db from '../config/database';
import logger from '../config/logger';
import { AuthRequest } from '../middleware/auth';

export const createComplaintValidation = [
  body('subject').trim().notEmpty().withMessage('Subject is required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('category_id').optional().isInt().withMessage('Invalid category'),
  body('priority').optional().isIn(['LOW', 'MEDIUM', 'HIGH', 'URGENT']).withMessage('Invalid priority'),
];

export const updateComplaintValidation = [
  body('status').optional().isIn(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'CANCELLED']).withMessage('Invalid status'),
  body('assigned_to').optional().isInt().withMessage('Invalid user ID'),
  body('resolution_notes').optional().trim(),
];

// Get all complaints (Super Admin sees all, Employees see only their own)
export const getAllComplaints = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const isSuperAdmin = req.user!.role_id === 1;

    let query = `
      SELECT c.*, 
             cc.name as category_name,
             s.name as site_name,
             b.name as batch_name,
             u1.full_name as reported_by_name,
             u2.full_name as assigned_to_name
      FROM complaints c
      LEFT JOIN complaint_categories cc ON c.category_id = cc.id
      LEFT JOIN sites s ON c.site_id = s.id
      LEFT JOIN batches b ON c.batch_id = b.id
      LEFT JOIN users u1 ON c.reported_by = u1.id
      LEFT JOIN users u2 ON c.assigned_to = u2.id
    `;

    const params: any[] = [];

    // Employees can only see their own complaints
    if (!isSuperAdmin) {
      query += ' WHERE c.reported_by = ?';
      params.push(userId);
    }

    query += ' ORDER BY c.created_at DESC';

    const [complaints] = await db.query(query, params);

    res.json({ complaints });
  } catch (error) {
    logger.error('Get all complaints error:', error);
    res.status(500).json({ error: 'Failed to fetch complaints' });
  }
};

// Get single complaint (with ownership check)
export const getComplaintById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;
    const isSuperAdmin = req.user!.role_id === 1;

    const [complaints] = await db.query(
      `SELECT c.*, 
              cc.name as category_name,
              s.name as site_name,
              b.name as batch_name,
              u1.full_name as reported_by_name,
              u2.full_name as assigned_to_name
       FROM complaints c
       LEFT JOIN complaint_categories cc ON c.category_id = cc.id
       LEFT JOIN sites s ON c.site_id = s.id
       LEFT JOIN batches b ON c.batch_id = b.id
       LEFT JOIN users u1 ON c.reported_by = u1.id
       LEFT JOIN users u2 ON c.assigned_to = u2.id
       WHERE c.id = ?`,
      [id]
    );

    const complaint = (complaints as any[])[0];

    if (!complaint) {
      res.status(404).json({ error: 'Complaint not found' });
      return;
    }

    // Check ownership - employees can only view their own complaints
    if (!isSuperAdmin && complaint.reported_by !== userId) {
      res.status(403).json({ error: 'You can only view your own complaints' });
      return;
    }

    res.json({ complaint });
  } catch (error) {
    logger.error('Get complaint by ID error:', error);
    res.status(500).json({ error: 'Failed to fetch complaint' });
  }
};

// Create complaint (Any authenticated user can create)
export const createComplaint = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const {
      category_id,
      site_id,
      batch_id,
      subject,
      description,
      priority = 'MEDIUM',
    } = req.body;

    const userId = req.user!.id;

    // Generate complaint number
    const [result] = await db.query(
      `INSERT INTO complaints (
        complaint_no, category_id, site_id, batch_id, subject, 
        description, priority, status, reported_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'OPEN', ?)`,
      [
        `CMP-${Date.now()}`,
        category_id || null,
        site_id || null,
        batch_id || null,
        subject,
        description,
        priority,
        userId,
      ]
    );

    const complaintId = (result as any).insertId;

    logger.info(`Complaint created: ID ${complaintId} by user ${userId}`);

    res.status(201).json({
      message: 'Complaint submitted successfully',
      complaintId,
    });
  } catch (error) {
    logger.error('Create complaint error:', error);
    res.status(500).json({ error: 'Failed to create complaint' });
  }
};

// Update complaint (Super Admin only)
export const updateComplaint = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { id } = req.params;
    const { status, assigned_to, resolution_notes, priority } = req.body;
    const userId = req.user!.id;

    // Check if complaint exists
    const [complaints] = await db.query('SELECT * FROM complaints WHERE id = ?', [id]);
    if ((complaints as any[]).length === 0) {
      res.status(404).json({ error: 'Complaint not found' });
      return;
    }

    const updates: string[] = [];
    const values: any[] = [];

    if (status) {
      updates.push('status = ?');
      values.push(status);

      if (status === 'RESOLVED' || status === 'CLOSED') {
        updates.push('resolved_date = NOW()');
      }
    }

    if (assigned_to !== undefined) {
      updates.push('assigned_to = ?');
      values.push(assigned_to);
    }

    if (resolution_notes !== undefined) {
      updates.push('resolution_notes = ?');
      values.push(resolution_notes);
    }

    if (priority) {
      updates.push('priority = ?');
      values.push(priority);
    }

    updates.push('updated_at = NOW()');
    values.push(id);

    await db.query(
      `UPDATE complaints SET ${updates.join(', ')} WHERE id = ?`,
      values
    );

    logger.info(`Complaint updated: ID ${id} by user ${userId}`);

    res.json({ message: 'Complaint updated successfully' });
  } catch (error) {
    logger.error('Update complaint error:', error);
    res.status(500).json({ error: 'Failed to update complaint' });
  }
};

// Delete/Cancel complaint
export const deleteComplaint = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;
    const isSuperAdmin = req.user!.role_id === 1;

    // Check if complaint exists
    const [complaints] = await db.query('SELECT * FROM complaints WHERE id = ?', [id]);
    const complaint = (complaints as any[])[0];

    if (!complaint) {
      res.status(404).json({ error: 'Complaint not found' });
      return;
    }

    // Employees can only cancel their own complaints if status is OPEN
    if (!isSuperAdmin) {
      if (complaint.reported_by !== userId) {
        res.status(403).json({ error: 'You can only cancel your own complaints' });
        return;
      }
      if (complaint.status !== 'OPEN') {
        res.status(400).json({ error: 'You can only cancel complaints that are in OPEN status' });
        return;
      }
    }

    // Soft delete by setting status to CANCELLED
    await db.query(
      'UPDATE complaints SET status = ?, updated_at = NOW() WHERE id = ?',
      ['CANCELLED', id]
    );

    logger.info(`Complaint cancelled: ID ${id} by user ${userId}`);

    res.json({ message: 'Complaint cancelled successfully' });
  } catch (error) {
    logger.error('Delete complaint error:', error);
    res.status(500).json({ error: 'Failed to cancel complaint' });
  }
};

// Get complaint categories
export const getCategories = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [categories] = await db.query(
      'SELECT * FROM complaint_categories WHERE is_active = TRUE ORDER BY name'
    );

    res.json({ categories });
  } catch (error) {
    logger.error('Get categories error:', error);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
};

// Get complaint statistics (Super Admin only)
export const getComplaintStats = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const [stats] = await db.query(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'OPEN' THEN 1 ELSE 0 END) as open,
        SUM(CASE WHEN status = 'IN_PROGRESS' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN status = 'RESOLVED' THEN 1 ELSE 0 END) as resolved,
        SUM(CASE WHEN status = 'CLOSED' THEN 1 ELSE 0 END) as closed,
        SUM(CASE WHEN priority = 'URGENT' AND status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED') THEN 1 ELSE 0 END) as urgent_pending
      FROM complaints
    `);

    res.json({ stats: (stats as any[])[0] });
  } catch (error) {
    logger.error('Get complaint stats error:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
};
