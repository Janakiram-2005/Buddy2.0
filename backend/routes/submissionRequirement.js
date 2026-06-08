const express = require('express');
const router = express.Router();
const { createRequirement, getRequirements, deleteRequirement } = require('../controllers/submissionRequirementController');
const { protect, admin } = require('../middleware/auth');

router.post('/', protect, admin, createRequirement);
router.get('/', protect, getRequirements);
router.delete('/:id', protect, admin, deleteRequirement);

module.exports = router;
