const express = require('express');
const router = express.Router();
const { generateSchedule, generateQuiz, recommendResources, analyticsSummary, chatWithAI, suggestTopics } = require('../controllers/aiController');
const { protect, admin } = require('../middleware/auth');

router.post('/generate-schedule', protect, admin, generateSchedule);
router.post('/generate-quiz', protect, admin, generateQuiz);
router.post('/recommend-resources', protect, admin, recommendResources);
router.post('/analytics-summary', protect, admin, analyticsSummary);
router.post('/chat', protect, chatWithAI);
router.post('/suggest-topics', protect, suggestTopics);

module.exports = router;


