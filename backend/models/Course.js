const mongoose = require('mongoose');

const pricingSchema = new mongoose.Schema(
  {
    monthly: { type: Number, default: 0, min: 0 },
    quarterly: { type: Number, default: 0, min: 0 },
    semiAnnual: { type: Number, default: 0, min: 0 },
    yearly: { type: Number, default: 0, min: 0 },
  },
  { _id: false }
);

const offerSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      default: '',
      trim: true,
    },
    pricing: {
      type: pricingSchema,
      default: () => ({
        monthly: 0,
        quarterly: 0,
        semiAnnual: 0,
        yearly: 0,
      }),
    },
    expiresAt: {
      type: Date,
      default: null,
    },
  },
  { _id: false }
);

const courseSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    instructor: {
      type: String,
      required: true,
      trim: true,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    pricing: {
      type: pricingSchema,
      default: () => ({
        monthly: 0,
        quarterly: 0,
        semiAnnual: 0,
        yearly: 0,
      }),
    },
    offer: {
      type: offerSchema,
      default: () => ({
        title: '',
        pricing: {
          monthly: 0,
          quarterly: 0,
          semiAnnual: 0,
          yearly: 0,
        },
        expiresAt: null,
      }),
    },
    isLocked: {
      type: Boolean,
      default: true,
    },
    thumbnail: {
      type: String,
      default: '',
      trim: true,
    },
    lessons: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Lesson',
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

module.exports = mongoose.model('Course', courseSchema);
