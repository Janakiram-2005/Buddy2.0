const Schedule = require('../models/Schedule');

exports.createSchedule = async (req, res) => {
  try {
    const schedule = await Schedule.create(req.body);

    // Emit real-time update to student
    const io = req.app.get('socketio');
    io.to(req.body.studentId.toString()).emit('scheduleCreated', schedule);

    res.status(201).json(schedule);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getStudentSchedules = async (req, res) => {
  try {
    const schedules = await Schedule.find({ studentId: req.user._id });
    res.json(schedules);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateScheduleStatus = async (req, res) => {
  try {
    const schedule = await Schedule.findById(req.params.id);
    if (!schedule) return res.status(404).json({ message: 'Schedule not found' });

    // Only the assigned student can update their own schedule
    if (schedule.studentId.toString() !== req.user._id.toString()) {
        return res.status(403).json({ message: 'Not authorized' });
    }

    schedule.status = req.body.status || schedule.status;
    schedule.feedback = req.body.feedback || schedule.feedback;
    await schedule.save();
    res.json(schedule);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getAllSchedules = async (req, res) => {
  try {
    const schedules = await Schedule.find().populate('studentId', 'fullName');
    res.json(schedules);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteSchedule = async (req, res) => {
  try {
    const schedule = await Schedule.findById(req.params.id);
    if (!schedule) return res.status(404).json({ message: 'Schedule not found' });
    await schedule.deleteOne();
    res.json({ message: 'Schedule deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
