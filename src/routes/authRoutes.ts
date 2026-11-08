import express from 'express';
import * as authController from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = express.Router();

router.post('/login', authController.loginValidation, authController.login);
router.get('/me', authenticate, authController.getCurrentUser);
router.post(
  '/change-password',
  authenticate,
  authController.changePasswordValidation,
  authController.changePassword
);

export default router;
