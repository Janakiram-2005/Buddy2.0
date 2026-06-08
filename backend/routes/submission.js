const express = require('express');
const router = express.Router();
const { createSubmission, getStudentSubmissions, getAllSubmissions, addFeedback } = require('../controllers/submissionController');
const { protect, admin } = require('../middleware/auth');

router.get('/', protect, getStudentSubmissions);
router.post('/', protect, createSubmission);
router.get('/all', protect, admin, getAllSubmissions);
router.patch('/:id/feedback', protect, admin, addFeedback);

module.exports = router;
