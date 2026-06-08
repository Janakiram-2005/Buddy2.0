const mongoose = require('mongoose');

const quizSchema = new mongoose.Schema({
  title: { type: String, required: true },
  subject: { type: String, required: true },
  topic: { type: String, required: true },
  difficulty: { type: String },
  timeLimit: { type: Number },
  scheduledDate: { type: Date },
  questions: [
    {
      type: { type: String, enum: ['MCQ', 'TrueFalse', 'ShortAnswer'] },
      question: String,
      options: [String],
      correctAnswer: String,
      explanation: String
    }
  ],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  assignedStudentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  isAiGenerated: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Quiz', quizSchema);
