const aiService = require('../services/aiService');

exports.generateSchedule = async (req, res) => {
  try {
    const { prompt } = req.body;
    const schedule = await aiService.generateSchedule(prompt);
    res.json(schedule);
  } catch (error) {
    res.status(500).json({ message: 'AI generation failed: ' + error.message });
  }
};

exports.generateQuiz = async (req, res) => {
  try {
    const { subject, topic, count } = req.body;
    const quiz = await aiService.generateQuiz(subject, topic, count);
    res.json(quiz);
  } catch (error) {
    res.status(500).json({ message: 'AI generation failed: ' + error.message });
  }
};

exports.recommendResources = async (req, res) => {
  try {
    const { topic } = req.body;
    const resources = await aiService.recommendResources(topic);
    res.json(resources);
  } catch (error) {
    res.status(500).json({ message: 'AI generation failed: ' + error.message });
  }
};

exports.analyticsSummary = async (req, res) => {
  try {
    const { metrics } = req.body;
    const summary = await aiService.analyticsSummary(metrics);
    res.json(summary);
  } catch (error) {
    res.status(500).json({ message: 'AI generation failed: ' + error.message });
  }
};
