import express from 'express';
import * as roleController from '../controllers/roleController';
import { authenticate, authorize } from '../middleware/auth';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

router.get('/permissions', authorize(['ROLES'], ['VIEW']), roleController.getAllPermissions);
router.get('/', authorize(['ROLES'], ['VIEW']), roleController.getAllRoles);
router.get('/:id', authorize(['ROLES'], ['VIEW']), roleController.getRoleById);
router.post(
  '/',
  authorize(['ROLES'], ['CREATE']),
  roleController.createRoleValidation,
  roleController.createRole
);
router.put(
  '/:id',
  authorize(['ROLES'], ['EDIT']),
  roleController.createRoleValidation,
  roleController.updateRole
);
router.delete('/:id', authorize(['ROLES'], ['DELETE']), roleController.deleteRole);
router.put('/:id/permissions', authorize(['ROLES'], ['EDIT']), roleController.updateRolePermissions);

export default router;
