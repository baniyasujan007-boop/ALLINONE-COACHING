const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');

const googleClient = new OAuth2Client();

const getJwtSecret = () => {
  if (process.env.JWT_SECRET) {
    return process.env.JWT_SECRET;
  }
  if (process.env.NODE_ENV === 'production') {
    throw new Error('JWT_SECRET is required in production');
  }
  return 'dev_secret';
};

const generateToken = (userId) => {
  return jwt.sign({ id: userId }, getJwtSecret(), {
    expiresIn: '7d',
  });
};

const mapEnrolledCourses = (courses) =>
  Array.isArray(courses)
    ? courses.map((course) => ({
        id: course._id,
        title: course.title,
        price: course.price || 0,
        pricing: course.pricing || {
          monthly: course.price || 0,
          quarterly: 0,
          semiAnnual: 0,
          yearly: 0,
        },
        thumbnail: course.thumbnail || '',
        accessExpiresAt: course.accessExpiresAt || null,
      }))
    : [];

const mapPaymentHistory = (payments) =>
  Array.isArray(payments)
    ? payments.map((payment) => ({
        courseId: payment.courseId,
        courseTitle: payment.courseTitle || '',
        amount: payment.amount || 0,
        paymentMethod: payment.paymentMethod || 'manual',
        billingCycle: payment.billingCycle || '',
        status: payment.status || 'success',
        paidAt: payment.paidAt,
        accessExpiresAt: payment.accessExpiresAt || null,
      }))
    : [];

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

const addMonths = (dateValue, monthsToAdd) => {
  const date = new Date(dateValue);
  if (Number.isNaN(date.getTime()) || monthsToAdd <= 0) {
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

const resolvePaymentAccessExpiry = (payment) => {
  if (!payment) {
    return null;
  }

  if (payment.accessExpiresAt) {
    const explicitExpiry = new Date(payment.accessExpiresAt);
    if (!Number.isNaN(explicitExpiry.getTime())) {
      return explicitExpiry;
    }
  }

  const months = billingCycleMonths(payment.billingCycle);
  if (months <= 0 || !payment.paidAt) {
    return null;
  }

  return addMonths(payment.paidAt, months);
};

const paymentSortTime = (payment) => {
  const date = payment?.paidAt ? new Date(payment.paidAt) : null;
  return date && !Number.isNaN(date.getTime()) ? date.getTime() : 0;
};

const getActiveEnrolledCourses = (courses, payments) => {
  const enrolledList = Array.isArray(courses) ? courses : [];
  const paymentList = Array.isArray(payments) ? payments : [];
  const latestPaymentByCourseId = new Map();

  for (const payment of paymentList) {
    const courseId = String(payment?.courseId || '');
    if (!courseId || payment?.status === 'failed') {
      continue;
    }
    const previousPayment = latestPaymentByCourseId.get(courseId);
    if (!previousPayment || paymentSortTime(payment) >= paymentSortTime(previousPayment)) {
      latestPaymentByCourseId.set(courseId, payment);
    }
  }

  const now = new Date();
  return enrolledList.filter((course) => {
    const courseId = String(course?._id || course?.id || '');
    if (!courseId) {
      return false;
    }
    const latestPayment = latestPaymentByCourseId.get(courseId);
    if (!latestPayment) {
      course.accessExpiresAt = null;
      return true;
    }
    const accessExpiresAt = resolvePaymentAccessExpiry(latestPayment);
    course.accessExpiresAt = accessExpiresAt
      ? accessExpiresAt.toISOString()
      : null;
    return !accessExpiresAt || accessExpiresAt > now;
  });
};

const buildPaymentHistoryResponse = (courses, payments) =>
  mapPaymentHistory(
    withAccessGrantEntries(courses, payments).map((payment) => ({
      ...payment,
      accessExpiresAt: resolvePaymentAccessExpiry(payment)?.toISOString() || null,
    }))
  );

const withAccessGrantEntries = (courses, payments) => {
  const paymentList = Array.isArray(payments) ? [...payments] : [];
  const enrolledList = Array.isArray(courses) ? courses : [];
  const coveredCourseIds = new Set(
    paymentList
      .map((payment) => String(payment.courseId || ''))
      .filter((courseId) => courseId.length > 0)
  );

  for (const course of enrolledList) {
    const courseId = String(course?._id || course?.id || '');
    if (!courseId || coveredCourseIds.has(courseId)) {
      continue;
    }
    paymentList.push({
      courseId,
      courseTitle: course.title || '',
      amount: 0,
      paymentMethod: 'manual',
      billingCycle: '',
      status: 'granted',
      paidAt: '',
    });
  }

  return paymentList;
};

const toAuthResponse = (user) => {
  const activeCourses = getActiveEnrolledCourses(
    user.enrolledCourses,
    user.paymentHistory
  );

  return {
    id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    phone: user.phone || '',
    address: user.address || '',
    profileImage: user.profileImage || '',
    enrolledCourses: mapEnrolledCourses(activeCourses),
    paymentHistory: buildPaymentHistoryResponse(
      activeCourses,
      user.paymentHistory
    ),
    token: generateToken(user._id),
  };
};

const getGoogleAudiences = () => {
  const raw = process.env.GOOGLE_CLIENT_IDS || process.env.GOOGLE_CLIENT_ID || '';
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
};

const verifyGoogleIdToken = async (idToken) => {
  const audiences = getGoogleAudiences();
  if (audiences.length === 0 && process.env.NODE_ENV === 'production') {
    throw new Error('GOOGLE_CLIENT_IDS is required in production');
  }

  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: audiences.length > 0 ? audiences : undefined,
  });
  return ticket.getPayload();
};

const verifyGoogleAccessToken = async (accessToken) => {
  if (typeof fetch !== 'function') {
    throw new Error('Global fetch is unavailable on this Node version');
  }

  const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error('Invalid Google access token');
  }

  const payload = await response.json();
  return payload && typeof payload === 'object' ? payload : null;
};

exports.register = async (req, res, next) => {
  try {
    const { name, email, password, role, phone, address, profileImage } =
      req.body;
    const normalizedEmail = email.toLowerCase();

    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const user = await User.create({
      name,
      email: normalizedEmail,
      password,
      role,
      phone: phone || '',
      address: address || '',
      profileImage: profileImage || '',
    });

    const hydrated = await User.findById(user._id).populate(
      'enrolledCourses',
      'title price pricing thumbnail'
    );

    return res.status(201).json(toAuthResponse(hydrated));
  } catch (error) {
    return next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = email.toLowerCase();
    const user = await User.findOne({ email: normalizedEmail }).populate(
      'enrolledCourses',
      'title price pricing thumbnail'
    );

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (!(await user.matchPassword(password))) {
      return res.status(401).json({ message: 'Incorrect password' });
    }

    return res.json(toAuthResponse(user));
  } catch (error) {
    return next(error);
  }
};

exports.googleLogin = async (req, res, next) => {
  try {
    const { idToken, accessToken } = req.body;

    let payload = null;
    if (typeof idToken === 'string' && idToken.trim()) {
      try {
        payload = await verifyGoogleIdToken(idToken.trim());
      } catch (error) {
        if (typeof accessToken !== 'string' || !accessToken.trim()) {
          throw error;
        }
      }
    }

    if (!payload && typeof accessToken === 'string' && accessToken.trim()) {
      payload = await verifyGoogleAccessToken(accessToken.trim());
    }

    if (!payload?.sub || !payload.email) {
      return res.status(401).json({ message: 'Invalid Google account details' });
    }

    if (payload.email_verified === false) {
      return res.status(401).json({ message: 'Google email is not verified' });
    }

    const normalizedEmail = payload.email.toLowerCase();
    let user = await User.findOne({
      $or: [{ googleId: payload.sub }, { email: normalizedEmail }],
    });

    if (!user) {
      user = await User.create({
        name: payload.name || normalizedEmail.split('@')[0],
        email: normalizedEmail,
        googleId: payload.sub,
        authProvider: 'google',
        password: crypto.randomBytes(32).toString('hex'),
        profileImage: payload.picture || '',
      });
    } else {
      user.googleId = payload.sub;
      user.authProvider = 'google';
      if (!user.name && payload.name) {
        user.name = payload.name;
      }
      if ((!user.profileImage || user.profileImage.trim() === '') && payload.picture) {
        user.profileImage = payload.picture;
      }
      await user.save();
    }

    const hydrated = await User.findById(user._id).populate(
      'enrolledCourses',
      'title price pricing thumbnail'
    );

    return res.json(toAuthResponse(hydrated));
  } catch (error) {
    if (error && /Wrong recipient|Invalid token|Token used too late|No pem/i.test(error.message || '')) {
      return res.status(401).json({ message: 'Google sign-in token is invalid' });
    }
    return next(error);
  }
};

exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id)
      .select('-password')
      .populate('enrolledCourses', 'title price pricing thumbnail');
    const activeCourses = getActiveEnrolledCourses(
      user.enrolledCourses,
      user.paymentHistory
    );
    return res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone || '',
      address: user.address || '',
      profileImage: user.profileImage || '',
      enrolledCourses: mapEnrolledCourses(activeCourses),
      paymentHistory: buildPaymentHistoryResponse(
        activeCourses,
        user.paymentHistory
      ),
    });
  } catch (error) {
    return next(error);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const { name, email, phone, address, profileImage } = req.body;

    if (email && email.toLowerCase() !== user.email) {
      const exists = await User.findOne({ email: email.toLowerCase() });
      if (exists && String(exists._id) !== String(user._id)) {
        return res.status(400).json({ message: 'Email already registered' });
      }
      user.email = email.toLowerCase();
    }

    if (name != null) user.name = name;
    if (phone != null) user.phone = phone;
    if (address != null) user.address = address;
    if (profileImage != null) user.profileImage = profileImage;

    await user.save();

    const hydrated = await User.findById(user._id).populate(
      'enrolledCourses',
      'title price pricing thumbnail'
    );
    const activeCourses = getActiveEnrolledCourses(
      hydrated.enrolledCourses,
      hydrated.paymentHistory
    );

    return res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone || '',
      address: user.address || '',
      profileImage: user.profileImage || '',
      enrolledCourses: mapEnrolledCourses(activeCourses),
      paymentHistory: buildPaymentHistoryResponse(
        activeCourses,
        hydrated.paymentHistory
      ),
    });
  } catch (error) {
    return next(error);
  }
};

exports.forgotPassword = async (req, res, next) => {
  try {
    const { email, newPassword } = req.body;
    const normalizedEmail = email.toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    if (!user) {
      return res.status(404).json({ message: 'Account not found for this email' });
    }

    user.password = newPassword;
    await user.save();

    return res.json({ message: 'Password reset successful' });
  } catch (error) {
    return next(error);
  }
};

exports.getUsersForAdmin = async (req, res, next) => {
  try {
    const users = await User.find()
      .select('-password')
      .populate('enrolledCourses', 'title price pricing thumbnail')
      .sort({ createdAt: -1 });

    const payload = users.map((user) => {
      const activeCourses = getActiveEnrolledCourses(
        user.enrolledCourses,
        user.paymentHistory
      );

      return {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone || '',
        address: user.address || '',
        profileImage: user.profileImage || '',
        createdAt: user.createdAt,
        enrolledCourses: mapEnrolledCourses(activeCourses),
        paymentHistory: buildPaymentHistoryResponse(
          activeCourses,
          user.paymentHistory
        ),
      };
    });

    return res.json(payload);
  } catch (error) {
    return next(error);
  }
};

exports.updateUserByAdmin = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const {
      name,
      email,
      role,
      phone,
      address,
      profileImage,
      enrolledCourseIds,
    } = req.body;

    if (email && email.toLowerCase() !== user.email) {
      const exists = await User.findOne({ email: email.toLowerCase() });
      if (exists && String(exists._id) !== String(user._id)) {
        return res.status(400).json({ message: 'Email already registered' });
      }
      user.email = email.toLowerCase();
    }

    if (name != null) user.name = name;
    if (role != null) user.role = role;
    if (phone != null) user.phone = phone;
    if (address != null) user.address = address;
    if (profileImage != null) user.profileImage = profileImage;
    if (Array.isArray(enrolledCourseIds)) {
      user.enrolledCourses = enrolledCourseIds;
    }

    await user.save();

    const hydrated = await User.findById(user._id)
      .select('-password')
      .populate('enrolledCourses', 'title price pricing thumbnail');
    const activeCourses = getActiveEnrolledCourses(
      hydrated.enrolledCourses,
      hydrated.paymentHistory
    );

    return res.json({
      id: hydrated._id,
      name: hydrated.name,
      email: hydrated.email,
      role: hydrated.role,
      phone: hydrated.phone || '',
      address: hydrated.address || '',
      profileImage: hydrated.profileImage || '',
      createdAt: hydrated.createdAt,
      enrolledCourses: mapEnrolledCourses(activeCourses),
      paymentHistory: buildPaymentHistoryResponse(
        activeCourses,
        hydrated.paymentHistory
      ),
    });
  } catch (error) {
    return next(error);
  }
};
