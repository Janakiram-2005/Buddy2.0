const express = require('express');
const router = express.Router();
const { createTask, getStudentTasks, updateTaskStatus } = require('../controllers/taskController');
const { protect, admin } = require('../middleware/auth');

router.get('/', protect, getStudentTasks);
router.post('/', protect, admin, createTask);
router.patch('/:id', protect, updateTaskStatus);

module.exports = router;
