import express from 'express';
import * as userController from '../controllers/userController';
import { authenticate, authorize } from '../middleware/auth';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

router.get('/', authorize(['USERS'], ['VIEW']), userController.getAllUsers);
router.get('/:id', authorize(['USERS'], ['VIEW']), userController.getUserById);
router.post(
  '/',
  authorize(['USERS'], ['EDIT']),
  userController.createUserValidation,
  userController.createUser
);
router.put(
  '/:id',
  authorize(['USERS'], ['EDIT']),
  userController.updateUserValidation,
  userController.updateUser
);
router.delete('/:id', authorize(['USERS'], ['EDIT']), userController.deleteUser);
router.post('/:id/reset-password', authorize(['USERS'], ['EDIT']), userController.resetUserPassword);

export default router;
