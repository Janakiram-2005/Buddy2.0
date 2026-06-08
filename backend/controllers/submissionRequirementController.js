const SubmissionRequirement = require('../models/SubmissionRequirement');

exports.createRequirement = async (req, res) => {
  try {
    const { studentId, title, subject, topic, description, deadline } = req.body;
    
    if (!studentId || !title || !subject || !topic) {
      return res.status(400).json({ message: 'studentId, title, subject, and topic are required' });
    }

    const requirement = await SubmissionRequirement.create({
      studentId,
      title,
      subject,
      topic,
      description,
      deadline,
      status: 'Pending'
    });

    res.status(201).json(requirement);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getRequirements = async (req, res) => {
  try {
    let query = {};
    if (req.user.role === 'Admin') {
      if (req.query.studentId) {
        query.studentId = req.query.studentId;
      }
    } else {
      query.studentId = req.user._id;
    }

    const requirements = await SubmissionRequirement.find(query)
      .populate('studentId', 'fullName email phone')
      .sort({ createdAt: -1 });

    res.json(requirements);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteRequirement = async (req, res) => {
  try {
    const requirement = await SubmissionRequirement.findById(req.params.id);
    if (!requirement) {
      return res.status(404).json({ message: 'Requirement not found' });
    }

    await SubmissionRequirement.findByIdAndDelete(req.params.id);
    res.json({ message: 'Submission requirement deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
