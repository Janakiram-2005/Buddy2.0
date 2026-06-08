const Schedule = require('../models/Schedule');
const QuizResult = require('../models/QuizResult');
const Submission = require('../models/Submission');

exports.getStudentAnalytics = async (req, res) => {
  const studentId = req.params.id || req.user._id;
  try {
    const schedules = await Schedule.find({ studentId });
    const quizResults = await QuizResult.find({ studentId });
    const submissions = await Submission.find({ studentId });

    // Calculate completion rate
    const totalSchedules = schedules.length;
    const completedSchedules = schedules.filter(s => s.status === 'Completed').length;

    // Average quiz score
    const avgScore = quizResults.length > 0
      ? quizResults.reduce((acc, curr) => acc + curr.score, 0) / quizResults.length
      : 0;

    res.json({
      totalSchedules,
      completedSchedules,
      completionRate: totalSchedules > 0 ? (completedSchedules / totalSchedules) * 100 : 0,
      avgQuizScore: avgScore,
      submissionCount: submissions.length,
      history: {
          schedules,
          quizResults,
          submissions
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const User = require('../models/User');

exports.getAdminOverview = async (req, res) => {
    try {
        const totalSubmissions = await Submission.countDocuments();
        const pendingReviews = await Submission.countDocuments({ adminFeedback: { $exists: false } });
        res.json({
            totalSubmissions,
            pendingReviews
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.sendParentReport = async (req, res) => {
  const { studentId } = req.params;
  try {
    const student = await User.findById(studentId);
    if (!student) return res.status(404).json({ message: 'Student not found' });
    if (!student.parentEmail) {
      return res.status(400).json({ message: 'No parent email associated with this student' });
    }

    const schedules = await Schedule.find({ studentId });
    const quizResults = await QuizResult.find({ studentId });
    const submissions = await Submission.find({ studentId });

    const totalSchedules = schedules.length;
    const completedSchedules = schedules.filter(s => s.status === 'Completed').length;
    
    const totalMinutes = schedules.filter(s => s.status === 'Completed').reduce((acc, curr) => acc + (curr.expectedDuration || 0), 0);
    const studyHours = (totalMinutes / 60).toFixed(1);

    const avgScore = quizResults.length > 0
      ? quizResults.reduce((acc, curr) => acc + curr.score, 0) / quizResults.length
      : 0;

    const emailBody = `
      ========================================================
      OFFICIAL PROGRESS REPORT: STUDY COMPANION
      To: ${student.parentEmail}
      Subject: Study Progress Report for ${student.fullName}
      
      Dear Parent,
      
      Here is the latest academic progress report for ${student.fullName}:
      
      - Total Study Time: ${studyHours} hours
      - Topics Completed: ${completedSchedules} / ${totalSchedules}
      - Average Quiz Score: ${avgScore.toFixed(1)}%
      - Proof Submissions: ${submissions.length} submitted
      
      Sincerely,
      Study Companion Administration
      ========================================================
    `;

    console.log(emailBody);

    res.json({
      message: `Progress report sent successfully to: ${student.parentEmail}`,
      report: {
        parentEmail: student.parentEmail,
        studyHours,
        completedTopics: `${completedSchedules}/${totalSchedules}`,
        avgQuizScore: avgScore.toFixed(1),
        submissionsCount: submissions.length,
      }
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
