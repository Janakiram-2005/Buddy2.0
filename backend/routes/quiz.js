const express = require('express');
const router = express.Router();
const { createQuiz, getQuizzes, getQuizById, submitQuiz } = require('../controllers/quizController');
const { protect, admin } = require('../middleware/auth');

router.get('/', protect, getQuizzes);
router.post('/', protect, admin, createQuiz);
router.get('/:id', protect, getQuizById);
router.post('/:id/submit', protect, submitQuiz);

module.exports = router;
