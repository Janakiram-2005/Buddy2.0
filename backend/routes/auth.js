const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getMe, approveUser, getAllStudents, createStudentDirectly, deleteStudent, updateProfile } = require('../controllers/authController');
const { protect, admin } = require('../middleware/auth');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/me', protect, getMe);
router.get('/students', protect, admin, getAllStudents);
router.post('/students/create', protect, admin, createStudentDirectly);
router.patch('/approve/:id', protect, admin, approveUser);
router.delete('/students/:id', protect, admin, deleteStudent);
router.put('/profile', protect, updateProfile);

module.exports = router;

