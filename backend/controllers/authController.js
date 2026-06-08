const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'super_secret_buddy_key', { expiresIn: '30d' });
};

exports.registerUser = async (req, res) => {
  const { fullName, parentEmail } = req.body;
  const email = req.body.email?.trim() || undefined;
  const phone = req.body.phone?.trim() || undefined;
  const role  = req.body.role;

  try {
    if (!fullName) return res.status(400).json({ message: 'Full name is required' });
    if (!email && !phone) return res.status(400).json({ message: 'Email or phone number is required' });

    // Check if user exists
    if (email) {
      const emailExists = await User.findOne({ email });
      if (emailExists) return res.status(400).json({ message: 'Email already registered' });
    }
    if (phone) {
      const phoneExists = await User.findOne({ phone });
      if (phoneExists) return res.status(400).json({ message: 'Phone already registered' });
    }

    // Default password as requested
    const defaultPassword = "BUDDY@123";

    // Prevent self-registration as Admin
    const userRole = role === 'Admin' ? 'Student' : (role || 'Student');

    const user = await User.create({
      fullName,
      ...(email && { email }),
      ...(phone && { phone }),
      password: defaultPassword,
      role: userRole,
      ...(parentEmail && { parentEmail }),
      status: 'Pending'
    });

    res.status(201).json({
      message: 'Registration request sent. Waiting for Admin approval.',
      _id: user._id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.loginUser = async (req, res) => {
  const { identifier, password } = req.body;

  try {
    if (!identifier || !password) {
      return res.status(400).json({ message: 'Email/phone and password are required' });
    }

    // 1. Check for hardcoded Admin from env or defaults
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@buddy.com';
    const adminPassword = process.env.ADMIN_PASSWORD || '123';
    if (identifier === adminEmail && password === adminPassword) {
      // Find or create the admin record in DB (so other references work)
      let admin = await User.findOne({ email: adminEmail });
      if (!admin) {
        // Pass PLAIN password — the pre-save hook hashes it once
        admin = await User.create({
          fullName: 'System Admin',
          email: adminEmail,
          password: adminPassword,   // ← plain text; pre-save hook will hash
          role: 'Admin',
          status: 'Approved'
        });
      }
      return res.json({
        _id: admin._id,
        fullName: admin.fullName,
        email: admin.email,
        role: 'Admin',
        token: generateToken(admin._id),
      });
    }

    // 2. Regular User Login (email or phone)
    const user = await User.findOne({
      $or: [{ email: identifier }, { phone: identifier }]
    });

    if (user && (await user.comparePassword(password))) {
      if (user.status !== 'Approved') {
        return res.status(403).json({ message: 'Your account is pending admin approval.' });
      }
      return res.json({
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        token: generateToken(user._id),
      });
    }

    return res.status(401).json({ message: 'Invalid credentials' });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getMe = async (req, res) => {
  res.json(req.user);
};

// Admin only actions
exports.approveUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) return res.status(404).json({ message: 'User not found' });
        user.status = 'Approved';
        await user.save();
        res.json({ message: 'User approved' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getAllStudents = async (req, res) => {
    try {
        const students = await User.find({ role: 'Student' });
        res.json(students);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createStudentDirectly = async (req, res) => {
  const { fullName, email, phone, parentEmail } = req.body;
  try {
    if (!fullName) return res.status(400).json({ message: 'Full name is required' });
    if (!email && !phone) return res.status(400).json({ message: 'Email or phone number is required' });

    if (email) {
      const emailExists = await User.findOne({ email });
      if (emailExists) return res.status(400).json({ message: 'Email already registered' });
    }
    if (phone) {
      const phoneExists = await User.findOne({ phone });
      if (phoneExists) return res.status(400).json({ message: 'Phone already registered' });
    }

    const defaultPassword = "BUDDY@123";

    const user = await User.create({
      fullName,
      ...(email && { email }),
      ...(phone && { phone }),
      password: defaultPassword,
      role: 'Student',
      ...(parentEmail && { parentEmail }),
      status: 'Approved'
    });

    res.status(201).json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
