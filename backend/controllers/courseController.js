const Course = require('../models/Course');
const User = require('../models/User');
const path = require('path');

const toPublicUrl = (req, filePath) => {
  const normalized = filePath.split(path.sep).join('/');
  const marker = '/uploads/';
  const idx = normalized.lastIndexOf(marker);
  const suffix = idx >= 0 ? normalized.substring(idx + 1) : normalized;
  return `${req.protocol}://${req.get('host')}/${suffix}`;
};

const toLockedFlag = (value) => {
  if (value == null || value == '') {
    return true;
  }
  if (typeof value === 'string') {
    return value.toLowerCase() == 'true';
  }
  return Boolean(value);
};

const normalizePricing = (pricing = {}, fallbackPrice = 0) => {
  const safe = {
    monthly: Number(pricing.monthly || 0),
    quarterly: Number(pricing.quarterly || 0),
    semiAnnual: Number(pricing.semiAnnual || 0),
    yearly: Number(pricing.yearly || 0),
  };
  const basePrice = Number(fallbackPrice || 0);
  if (
    safe.monthly <= 0 &&
    safe.quarterly <= 0 &&
    safe.semiAnnual <= 0 &&
    safe.yearly <= 0 &&
    basePrice > 0
  ) {
    // Legacy single-price courses are treated as monthly plans
    // and expanded into longer billing cycles for checkout.
    safe.monthly = basePrice;
    safe.quarterly = Number((basePrice * 2.7).toFixed(2));
    safe.semiAnnual = Number((basePrice * 5).toFixed(2));
    safe.yearly = Number((basePrice * 9).toFixed(2));
  }
  return safe;
};

const lowestPrice = (pricing, fallbackPrice = 0) => {
  const values = [
    pricing.monthly,
    pricing.quarterly,
    pricing.semiAnnual,
    pricing.yearly,
  ]
    .map((value) => Number(value || 0))
    .filter((value) => value > 0);
  if (values.length == 0) {
    return Number(fallbackPrice || 0);
  }
  return Math.min(...values);
};

const normalizeOffer = (offer = {}, basePricing = {}, fallbackPrice = 0) => {
  const safePricing = normalizePricing(basePricing, fallbackPrice);
  const offerPricing = {
    monthly: Number(offer.pricing?.monthly || 0),
    quarterly: Number(offer.pricing?.quarterly || 0),
    semiAnnual: Number(offer.pricing?.semiAnnual || 0),
    yearly: Number(offer.pricing?.yearly || 0),
  };
  const hasOfferPrice = Object.values(offerPricing).some(
    (value) => Number(value) > 0
  );
  const expiresAt =
    offer.expiresAt && !Number.isNaN(new Date(offer.expiresAt).getTime())
      ? new Date(offer.expiresAt)
      : null;
  if (!hasOfferPrice || !expiresAt) {
    return {
      title: '',
      pricing: {
        monthly: 0,
        quarterly: 0,
        semiAnnual: 0,
        yearly: 0,
      },
      expiresAt: null,
    };
  }

  return {
    title: typeof offer.title === 'string' ? offer.title.trim() : '',
    pricing: {
      monthly:
        offerPricing.monthly > 0 &&
        (safePricing.monthly <= 0 || offerPricing.monthly < safePricing.monthly)
          ? offerPricing.monthly
          : 0,
      quarterly:
        offerPricing.quarterly > 0 &&
        (safePricing.quarterly <= 0 ||
          offerPricing.quarterly < safePricing.quarterly)
          ? offerPricing.quarterly
          : 0,
      semiAnnual:
        offerPricing.semiAnnual > 0 &&
        (safePricing.semiAnnual <= 0 ||
          offerPricing.semiAnnual < safePricing.semiAnnual)
          ? offerPricing.semiAnnual
          : 0,
      yearly:
        offerPricing.yearly > 0 &&
        (safePricing.yearly <= 0 || offerPricing.yearly < safePricing.yearly)
          ? offerPricing.yearly
          : 0,
    },
    expiresAt,
  };
};

const offerIsActive = (offer) => {
  if (!offer || !offer.expiresAt) {
    return false;
  }
  const expiresAt = new Date(offer.expiresAt);
  if (Number.isNaN(expiresAt.getTime()) || expiresAt <= new Date()) {
    return false;
  }
  return Object.values(offer.pricing || {}).some((value) => Number(value) > 0);
};

const activePricingForCourse = (course) => {
  const basePricing = normalizePricing(course.pricing, course.price);
  if (!offerIsActive(course.offer)) {
    return basePricing;
  }
  return {
    monthly: Number(course.offer.pricing?.monthly || 0) || basePricing.monthly,
    quarterly:
      Number(course.offer.pricing?.quarterly || 0) || basePricing.quarterly,
    semiAnnual:
      Number(course.offer.pricing?.semiAnnual || 0) || basePricing.semiAnnual,
    yearly: Number(course.offer.pricing?.yearly || 0) || basePricing.yearly,
  };
};

const billingCycleMonths = (billingCycle) => {
  switch (billingCycle) {
    case 'monthly':
      return 1;
    case 'quarterly':
      return 3;
    case 'semiAnnual':
      return 6;
    case 'yearly':
      return 12;
    default:
      return 0;
  }
};

const addMonths = (date, monthsToAdd) => {
  if (!(date instanceof Date) || Number.isNaN(date.getTime()) || monthsToAdd <= 0) {
    return null;
  }

  const targetMonth = date.getMonth() + monthsToAdd;
  const lastDayOfTargetMonth = new Date(
    date.getFullYear(),
    targetMonth + 1,
    0
  ).getDate();

  return new Date(
    date.getFullYear(),
    targetMonth,
    Math.min(date.getDate(), lastDayOfTargetMonth),
    date.getHours(),
    date.getMinutes(),
    date.getSeconds(),
    date.getMilliseconds()
  );
};

exports.getCourses = async (req, res, next) => {
  try {
    const courses = await Course.find().sort({ createdAt: -1 });
    return res.json(courses);
  } catch (error) {
    return next(error);
  }
};

exports.getCourseById = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    return res.json(course);
  } catch (error) {
    return next(error);
  }
};

exports.createCourse = async (req, res, next) => {
  try {
    const {
      title,
      description,
      instructor,
      price,
      pricing,
      offer,
      isLocked,
      thumbnail,
      lessons,
    } =
      req.body;
    const thumbnailUrl = req.file ? toPublicUrl(req, req.file.path) : thumbnail;
    const safeInstructor =
      instructor || (req.user && req.user.name ? req.user.name : 'Instructor');
    const safePrice = price == null || price == '' ? 0 : price;
    const safePricing = normalizePricing(pricing, safePrice);
    const safeOffer = normalizeOffer(offer, safePricing, safePrice);
    const course = await Course.create({
      title,
      description,
      instructor: safeInstructor,
      price: lowestPrice(safePricing, safePrice),
      pricing: safePricing,
      offer: safeOffer,
      isLocked: toLockedFlag(isLocked),
      thumbnail: thumbnailUrl,
      lessons: lessons || [],
    });
    return res.status(201).json(course);
  } catch (error) {
    return next(error);
  }
};

exports.updateCourse = async (req, res, next) => {
  try {
    const updateData = { ...req.body };
    const safePricing = normalizePricing(updateData.pricing, updateData.price);
    updateData.pricing = safePricing;
    updateData.price = lowestPrice(safePricing, updateData.price);
    if (
      Object.prototype.hasOwnProperty.call(updateData, 'offer') ||
      Object.prototype.hasOwnProperty.call(updateData, 'pricing') ||
      Object.prototype.hasOwnProperty.call(updateData, 'price')
    ) {
      updateData.offer = normalizeOffer(
        updateData.offer,
        safePricing,
        updateData.price
      );
    }
    if (Object.prototype.hasOwnProperty.call(updateData, 'isLocked')) {
      updateData.isLocked = toLockedFlag(updateData.isLocked);
    }
    if (req.file) {
      updateData.thumbnail = toPublicUrl(req, req.file.path);
    }

    const updated = await Course.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!updated) {
      return res.status(404).json({ message: 'Course not found' });
    }

    return res.json(updated);
  } catch (error) {
    return next(error);
  }
};

exports.deleteCourse = async (req, res, next) => {
  try {
    const deleted = await Course.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({ message: 'Course not found' });
    }
    return res.json({ message: 'Course deleted successfully' });
  } catch (error) {
    return next(error);
  }
};

exports.purchaseCourse = async (req, res, next) => {
  try {
    const { paymentMethod, billingCycle } = req.body;
    const course = await Course.findById(req.params.id);
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const safePricing = activePricingForCourse(course);
    const requestedCycle =
      typeof billingCycle === 'string' ? billingCycle.trim() : '';
    const cycleToPrice = {
      monthly: safePricing.monthly,
      quarterly: safePricing.quarterly,
      semiAnnual: safePricing.semiAnnual,
      yearly: safePricing.yearly,
    };
    const selectedCycle =
      requestedCycle && Number(cycleToPrice[requestedCycle]) > 0
        ? requestedCycle
        : course.price > 0
        ? Object.keys(cycleToPrice).find(
            (key) => Number(cycleToPrice[key]) > 0
          ) || 'monthly'
        : '';
    const amount =
      selectedCycle && Number(cycleToPrice[selectedCycle]) > 0
        ? Number(cycleToPrice[selectedCycle])
        : course.price || 0;
    const paidAt = new Date();
    const accessExpiresAt = addMonths(
      paidAt,
      billingCycleMonths(selectedCycle)
    );

    const alreadyEnrolled = user.enrolledCourses.some(
      (courseId) => String(courseId) === String(course._id)
    );
    if (!alreadyEnrolled) {
      user.enrolledCourses.push(course._id);
    }
    user.paymentHistory.push({
      courseId: course._id,
      courseTitle: course.title,
      amount,
      paymentMethod: paymentMethod || 'manual',
      billingCycle: selectedCycle,
      status: 'success',
      paidAt,
      accessExpiresAt,
    });
    await user.save();

    return res.json({
      message:
        amount > 0
          ? 'Course purchased successfully'
          : 'Course enrolled successfully',
      enrolledCourse: {
        id: course._id,
        title: course.title,
        price: course.price || 0,
        pricing: normalizePricing(course.pricing, course.price),
        thumbnail: course.thumbnail || '',
      },
    });
  } catch (error) {
    return next(error);
  }
};
