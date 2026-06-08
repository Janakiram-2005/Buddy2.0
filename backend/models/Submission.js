const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  subject: { type: String, required: true },
  topic: { type: String, required: true },
  submissionType: { type: String, enum: ['Image', 'PDF', 'Screenshot'] },
  fileUrl: { type: String, required: true },
  comments: { type: String },
  adminFeedback: { type: String },
  submittedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Submission', submissionSchema);
