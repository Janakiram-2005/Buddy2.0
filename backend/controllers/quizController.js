const Quiz = require('../models/Quiz');
const QuizResult = require('../models/QuizResult');

exports.createQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.create({ ...req.body, createdBy: req.user._id });
    res.status(201).json(quiz);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getQuizzes = async (req, res) => {
  try {
    let query = {};
    if (req.user.role === 'Student') {
      query = {
        $or: [
          { assignedStudentId: { $exists: false } },
          { assignedStudentId: null },
          { assignedStudentId: req.user._id }
        ]
      };
    }
    const quizzes = await Quiz.find(query).populate('assignedStudentId', 'fullName').lean();

    if (req.user.role === 'Student') {
      for (let quiz of quizzes) {
        quiz.attempts = await QuizResult.find({ quizId: quiz._id, studentId: req.user._id });
      }
    } else {
      for (let quiz of quizzes) {
        quiz.attempts = await QuizResult.find({ quizId: quiz._id }).populate('studentId', 'fullName');
      }
    }

    res.json(quizzes);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


exports.getQuizById = async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);
    if (!quiz) return res.status(404).json({ message: 'Quiz not found' });
    res.json(quiz);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.submitQuiz = async (req, res) => {
  try {
    const { score, totalQuestions, answers } = req.body;
    const result = await QuizResult.create({
      quizId: req.params.id,
      studentId: req.user._id,
      score,
      totalQuestions,
      answers
    });
    res.status(201).json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);
    if (!quiz) return res.status(404).json({ message: 'Quiz not found' });
    
    // Cascade delete all attempts
    await QuizResult.deleteMany({ quizId: req.params.id });

    await Quiz.findByIdAndDelete(req.params.id);
    res.json({ message: 'Quiz deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


exports.updateQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);
    if (!quiz) return res.status(404).json({ message: 'Quiz not found' });

    // Check if quiz has attempts
    const attemptsCount = await QuizResult.countDocuments({ quizId: req.params.id });
    if (attemptsCount > 0) {
      return res.status(400).json({ message: 'Cannot modify quiz: it has already been attempted by students.' });
    }

    const updatedQuiz = await Quiz.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updatedQuiz);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
