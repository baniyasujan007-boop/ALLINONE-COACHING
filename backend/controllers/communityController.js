const CommunityPost = require('../models/CommunityPost');

const mapAnswer = (answer) => ({
  id: answer._id,
  authorName: answer.authorName,
  message: answer.message,
  imageUrl: answer.imageUrl || '',
  imageName: answer.imageName || '',
  createdAt: answer.createdAt,
});

const mapPost = (post) => ({
  id: post._id,
  topic: post.topic,
  authorName: post.authorName,
  title: post.title,
  message: post.message,
  imageUrl: post.imageUrl || '',
  imageName: post.imageName || '',
  createdAt: post.createdAt,
  answers: Array.isArray(post.answers) ? post.answers.map(mapAnswer) : [],
});

exports.getCommunityPosts = async (_req, res, next) => {
  try {
    const posts = await CommunityPost.find().sort({ createdAt: -1 });
    return res.json(posts.map(mapPost));
  } catch (error) {
    return next(error);
  }
};

exports.createCommunityPost = async (req, res, next) => {
  try {
    const { topic, title, message, imageUrl = '', imageName = '' } = req.body;
    const post = await CommunityPost.create({
      topic,
      title,
      message,
      imageUrl,
      imageName,
      author: req.user._id,
      authorName: req.user.name,
    });
    return res.status(201).json(mapPost(post));
  } catch (error) {
    return next(error);
  }
};

exports.addCommunityAnswer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { message, imageUrl = '', imageName = '' } = req.body;

    const post = await CommunityPost.findById(id);
    if (!post) {
      return res.status(404).json({ message: 'Community post not found' });
    }

    post.answers.push({
      author: req.user._id,
      authorName: req.user.name,
      message,
      imageUrl,
      imageName,
    });
    await post.save();

    return res.status(201).json(mapPost(post));
  } catch (error) {
    return next(error);
  }
};
