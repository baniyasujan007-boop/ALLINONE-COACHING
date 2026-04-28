const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    googleId: {
      type: String,
      default: '',
      trim: true,
      index: true,
    },
    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
    },
    password: {
      type: String,
      required: true,
      minlength: 6,
    },
    role: {
      type: String,
      enum: ['student', 'admin'],
      default: 'student',
    },
    phone: {
      type: String,
      default: '',
      trim: true,
    },
    address: {
      type: String,
      default: '',
      trim: true,
    },
    profileImage: {
      type: String,
      default: '',
      trim: true,
    },
    referralCode: {
      type: String,
      unique: true,
      sparse: true,
      uppercase: true,
      trim: true,
    },
    firstPaidPurchaseAt: {
      type: Date,
      default: null,
    },
    enrolledCourses: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Course',
      },
    ],
    paymentHistory: [
      {
        courseId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Course',
        },
        courseTitle: {
          type: String,
          default: '',
          trim: true,
        },
        amount: {
          type: Number,
          default: 0,
          min: 0,
        },
        paymentMethod: {
          type: String,
          default: 'manual',
          trim: true,
        },
        billingCycle: {
          type: String,
          default: '',
          trim: true,
        },
        status: {
          type: String,
          default: 'success',
          trim: true,
        },
        paidAt: {
          type: Date,
          default: Date.now,
        },
        accessExpiresAt: {
          type: Date,
          default: null,
        },
        originalAmount: {
          type: Number,
          default: 0,
          min: 0,
        },
        couponCode: {
          type: String,
          default: '',
          trim: true,
          uppercase: true,
        },
        couponDiscount: {
          type: Number,
          default: 0,
          min: 0,
        },
        referralCode: {
          type: String,
          default: '',
          trim: true,
          uppercase: true,
        },
        referralDiscount: {
          type: Number,
          default: 0,
          min: 0,
        },
        referredByUserId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
          default: null,
        },
        referrerRewardAmount: {
          type: Number,
          default: 0,
          min: 0,
        },
      },
    ],
  },
  {
    timestamps: {
      createdAt: true,
      updatedAt: false,
    },
  }
);

userSchema.pre('save', async function preSave(next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  return next();
});

userSchema.methods.matchPassword = function matchPassword(plainPassword) {
  return bcrypt.compare(plainPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
