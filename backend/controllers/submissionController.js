const Submission = require('../models/Submission');
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

exports.createSubmission = async (req, res) => {
  try {
    let fileUrl = req.body.fileUrl;
    if (req.body.imageBase64) {
      const uploadResult = await cloudinary.uploader.upload(req.body.imageBase64, {
        folder: 'study_companion'
      });
      fileUrl = uploadResult.secure_url;
    }
    
    if (!fileUrl) {
      return res.status(400).json({ message: 'File URL or base64 image is required' });
    }

    const submission = await Submission.create({
      studentId: req.user._id,
      subject: req.body.subject,
      topic: req.body.topic,
      submissionType: req.body.submissionType || 'Image',
      fileUrl,
      comments: req.body.comments
    });
    res.status(201).json(submission);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getStudentSubmissions = async (req, res) => {
  try {
    const submissions = await Submission.find({ studentId: req.user._id });
    res.json(submissions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getAllSubmissions = async (req, res) => {
  try {
    const submissions = await Submission.find().populate('studentId', 'fullName');
    res.json(submissions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.addFeedback = async (req, res) => {
  try {
    const submission = await Submission.findById(req.params.id);
    if (!submission) return res.status(404).json({ message: 'Submission not found' });

    submission.adminFeedback = req.body.feedback;
    await submission.save();
    res.json(submission);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
