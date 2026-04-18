import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedTopic = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityService>().loadPosts();
    });
  }

  List<CommunityPost> _visiblePosts(List<CommunityPost> posts) {
    if (_selectedTopic == 'All') {
      return posts;
    }
    return posts
        .where((CommunityPost post) => post.topic == _selectedTopic)
        .toList();
  }

  Future<void> _openAskQuestionSheet(BuildContext context) async {
    final AppState appState = context.read<AppState>();
    final String authorName = appState.currentUser?.name ?? appState.userName;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _AskQuestionSheet(
        authorName: authorName,
      ),
    );
  }

  Future<void> _openAnswerSheet(
    BuildContext context,
    CommunityPost post,
  ) async {
    final AppState appState = context.read<AppState>();
    final String authorName = appState.currentUser?.name ?? appState.userName;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _AnswerQuestionSheet(
        post: post,
        authorName: authorName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityService>(
      builder: (BuildContext context, CommunityService community, _) {
        final List<CommunityPost> posts = _visiblePosts(community.posts);
        final List<String> topics = community.topics;

        return Scaffold(
          appBar: AppBar(title: const Text('Community')),
          body: RefreshIndicator(
            onRefresh: () => context.read<CommunityService>().loadPosts(force: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Ask the community',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Students can post topic-based questions, attach images, and get answers from other learners.',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => _openAskQuestionSheet(context),
                          icon: const Icon(Icons.add_comment_rounded),
                          label: const Text('Ask a Question'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topics.map((String topic) {
                    final bool selected = topic == _selectedTopic;
                    return ChoiceChip(
                      label: Text(topic),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedTopic = topic;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (community.loading && community.posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (community.error != null && community.posts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(community.error!),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context
                                .read<CommunityService>()
                                .loadPosts(force: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (posts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No community posts for this topic yet.'),
                    ),
                  )
                else
                  ...posts.map(
                    (CommunityPost post) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CommunityPostCard(
                        post: post,
                        onAnswer: () => _openAnswerSheet(context, post),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAskQuestionSheet(context),
            icon: const Icon(Icons.forum_rounded),
            label: const Text('New Post'),
          ),
        );
      },
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post, required this.onAnswer});

  final CommunityPost post;
  final VoidCallback onAnswer;

  String _timeAgo(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${math.max(diff.inMinutes, 1)} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  child: Text(post.authorName.isEmpty ? '?' : post.authorName[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _timeAgo(post.createdAt),
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(post.topic)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(post.message),
            if ((post.imageUrl ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  post.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 180,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              if (post.imageName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    post.imageName!,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Icon(
                  Icons.question_answer_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${post.answers.length} answer${post.answers.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAnswer,
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text('Answer'),
                ),
              ],
            ),
            if (post.answers.isNotEmpty) ...<Widget>[
              const Divider(height: 24),
              ...post.answers.map(
                (CommunityAnswer answer) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CommunityAnswerTile(answer: answer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunityAnswerTile extends StatelessWidget {
  const _CommunityAnswerTile({required this.answer});

  final CommunityAnswer answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.person_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(answer.message),
          if ((answer.imageUrl ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                answer.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 150,
                  color: Theme.of(context).colorScheme.surface,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AskQuestionSheet extends StatefulWidget {
  const _AskQuestionSheet({required this.authorName});

  final String authorName;

  @override
  State<_AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<_AskQuestionSheet> {
  static const List<String> _topicOptions = <String>[
    'Flutter',
    'Dart',
    'UI/UX',
    'Backend',
    'AI',
    'Career',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedTopic = 'Flutter';
  Uint8List? _imageBytes;
  String? _imageName;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file == null) {
      return;
    }
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    final String message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and question')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await context.read<CommunityService>().createPost(
        topic: _selectedTopic,
        title: title,
        message: message,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post question')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(
      context,
    ).viewInsets + const EdgeInsets.all(16);

    return SafeArea(
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Ask a question',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedTopic,
                items: _topicOptions
                    .map(
                      (String topic) => DropdownMenuItem<String>(
                        value: topic,
                        child: Text(topic),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedTopic = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Write a short title for your question',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Question details',
                  hintText: 'Explain your problem or doubt clearly',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Add Image'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                  if (_imageBytes != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageBytes = null;
                          _imageName = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Remove'),
                    ),
                ],
              ),
              if (_imageBytes != null) ...<Widget>[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (_imageName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_imageName!),
                  ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? 'Posting...' : 'Post Question'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerQuestionSheet extends StatefulWidget {
  const _AnswerQuestionSheet({
    required this.post,
    required this.authorName,
  });

  final CommunityPost post;
  final String authorName;

  @override
  State<_AnswerQuestionSheet> createState() => _AnswerQuestionSheetState();
}

class _AnswerQuestionSheetState extends State<_AnswerQuestionSheet> {
  final TextEditingController _answerController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _submitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file == null) {
      return;
    }
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  Future<void> _submit() async {
    final String message = _answerController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your answer')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await context.read<CommunityService>().createAnswer(
        postId: widget.post.id,
        message: message,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to post answer')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(
      context,
    ).viewInsets + const EdgeInsets.all(16);

    return SafeArea(
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Answer: ${widget.post.title}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Your answer',
                  hintText: 'Help the community with a clear answer',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Add Image'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                  if (_imageBytes != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageBytes = null;
                          _imageName = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Remove'),
                    ),
                ],
              ),
              if (_imageBytes != null) ...<Widget>[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.reply_rounded),
                  label: Text(_submitting ? 'Posting...' : 'Post Answer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
