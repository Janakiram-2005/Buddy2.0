const express = require('express');
const router = express.Router();
const { createSchedule, getStudentSchedules, updateScheduleStatus, getAllSchedules, deleteSchedule } = require('../controllers/scheduleController');
const { protect, admin } = require('../middleware/auth');

router.get('/', protect, getStudentSchedules);
router.post('/', protect, admin, createSchedule);
router.patch('/:id', protect, updateScheduleStatus);
router.delete('/:id', protect, admin, deleteSchedule);
router.get('/all', protect, admin, getAllSchedules);

module.exports = router;
