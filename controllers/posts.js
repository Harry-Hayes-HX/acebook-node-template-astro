const Post = require('../models/post');

const PostsController = {
  Index: async function(req, res) {
    const posts = await Post.find();
    res.render('posts/home', { posts: posts });
  },
  New: function(req, res) {
    res.render('posts/new', {});
  },
  Create: async function(req, res) {
    const post = new Post(req.body);
    await post.save();
    res.status(201).redirect('/posts');
  }
};

module.exports = PostsController;
