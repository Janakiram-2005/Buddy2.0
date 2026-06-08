const express = require('express');
const router = express.Router();
const { getStudentAnalytics, getAdminOverview, sendParentReport } = require('../controllers/analyticsController');
const { protect, admin } = require('../middleware/auth');

router.get('/student', protect, getStudentAnalytics);
router.get('/student/:id', protect, getStudentAnalytics);
router.get('/overview', protect, admin, getAdminOverview);
router.post('/send-report/:studentId', protect, admin, sendParentReport);

module.exports = router;
