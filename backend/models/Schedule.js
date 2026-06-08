const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, required: true },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  subject: { type: String, required: true },
  topic: { type: String, required: true },
  description: { type: String },
  resources: [String],
  expectedDuration: { type: Number },
  status: { type: String, enum: ['Pending', 'Completed', 'Needs Revision', 'Not Understood'], default: 'Pending' },
  feedback: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('Schedule', scheduleSchema);
