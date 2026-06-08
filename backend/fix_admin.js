require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

async function fixAdmin() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  // Delete the corrupted admin record (double-hashed password)
  const result = await User.deleteOne({ email: process.env.ADMIN_EMAIL });
  console.log(`Deleted admin records: ${result.deletedCount}`);

  // Also clean up any users with empty string email/phone that might cause index issues
  await User.deleteMany({ email: '' });
  await User.deleteMany({ phone: '' });
  console.log('Cleaned up empty email/phone records');

  await mongoose.disconnect();
  console.log('Done! Admin will be auto-created fresh on next login.');
}

fixAdmin().catch(console.error);
