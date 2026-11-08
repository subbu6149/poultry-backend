import express from 'express';
import * as complaintController from '../controllers/complaintController';
import { authenticate, authorize } from '../middleware/auth';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Categories - anyone with complaint access can view
router.get('/categories', complaintController.getCategories);

// Statistics - Super Admin only
router.get(
  '/stats',
  authorize(['COMPLAINTS'], ['EDIT']),
  complaintController.getComplaintStats
);

// CRUD operations
router.get('/', authorize(['COMPLAINTS'], ['VIEW']), complaintController.getAllComplaints);
router.get('/:id', authorize(['COMPLAINTS'], ['VIEW']), complaintController.getComplaintById);

// Anyone with VIEW access can create complaints
router.post(
  '/',
  authorize(['COMPLAINTS'], ['VIEW']),
  complaintController.createComplaintValidation,
  complaintController.createComplaint
);

// Only Super Admin can update complaints (assign, change status, etc.)
router.put(
  '/:id',
  authorize(['COMPLAINTS'], ['EDIT']),
  complaintController.updateComplaintValidation,
  complaintController.updateComplaint
);

// Employees can cancel their own OPEN complaints, Super Admin can cancel any
router.delete('/:id', authorize(['COMPLAINTS'], ['VIEW']), complaintController.deleteComplaint);

export default router;
