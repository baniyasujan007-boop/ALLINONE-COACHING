import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../models/course.dart';
import '../../services/course_service.dart';

class AdminCourseEditorPage extends StatefulWidget {
  const AdminCourseEditorPage({super.key, required this.courseId});

  final String courseId;

  @override
  State<AdminCourseEditorPage> createState() => _AdminCourseEditorPageState();
}

class _AdminCourseEditorPageState extends State<AdminCourseEditorPage> {
  Course? _course;
  bool _loading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<String?> _pickAndUploadCourseFile({
    required List<String> extensions,
  }) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final PlatformFile file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected file')),
        );
      }
      return null;
    }

    try {
      final String url = await CourseService.instance.uploadCourseFile(
        bytes: bytes,
        filename: file.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Uploaded: ${file.name}')));
      }
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
      return null;
    }
  }

  Future<String?> _pickAndUploadThumbnail() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final PlatformFile file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected image')),
        );
      }
      return null;
    }
    try {
      final String url = await CourseService.instance.uploadCourseThumbnail(
        bytes: bytes,
        filename: file.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thumbnail uploaded: ${file.name}')),
        );
      }
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thumbnail upload failed: $e')));
      }
      return null;
    }
  }

  Future<String?> _pickAndUploadThumbnailFromGallery() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) {
      return null;
    }
    final Uint8List bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected image')),
        );
      }
      return null;
    }
    try {
      final String url = await CourseService.instance.uploadCourseThumbnail(
        bytes: bytes,
        filename: picked.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thumbnail uploaded: ${picked.name}')),
        );
      }
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thumbnail upload failed: $e')));
      }
      return null;
    }
  }

  Future<void> _editCourseDetails() async {
    final Course? course = _course;
    if (course == null) return;

    final TextEditingController titleController = TextEditingController(
      text: course.title,
    );
    final TextEditingController descController = TextEditingController(
      text: course.description,
    );
    final TextEditingController thumbnailController = TextEditingController(
      text: course.thumbnailUrl,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool uploadingThumbnail = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setStateDialog) =>
            AlertDialog(
              title: const Text('Edit Course Details'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course title',
                      ),
                      validator: (String? value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      validator: (String? value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: thumbnailController,
                      decoration: const InputDecoration(
                        labelText: 'Thumbnail URL',
                      ),
                      validator: (String? value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: uploadingThumbnail
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    uploadingThumbnail = true;
                                  });
                                  final String? url =
                                      await _pickAndUploadThumbnailFromGallery();
                                  if (url != null) {
                                    thumbnailController.text = url;
                                  }
                                  setStateDialog(() {
                                    uploadingThumbnail = false;
                                  });
                                },
                          icon: uploadingThumbnail
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.photo_library_outlined),
                          label: const Text('Choose from Gallery'),
                        ),
                        OutlinedButton.icon(
                          onPressed: uploadingThumbnail
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    uploadingThumbnail = true;
                                  });
                                  final String? url =
                                      await _pickAndUploadThumbnail();
                                  if (url != null) {
                                    thumbnailController.text = url;
                                  }
                                  setStateDialog(() {
                                    uploadingThumbnail = false;
                                  });
                                },
                          icon: uploadingThumbnail
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: const Text('Upload File'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    await CourseService.instance.updateCourse(
                      courseId: widget.courseId,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      thumbnailUrl: thumbnailController.text.trim(),
                      price: _course?.price ?? 0,
                      pricing: _course?.pricing ?? const CoursePricing(),
                      offer: _course?.offer ?? const CourseOffer(),
                      isLocked: _course?.isLocked ?? false,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    _reload();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
    });
    await CourseService.instance.hydrateCourseDetails(widget.courseId);
    if (!mounted) return;
    setState(() {
      _course = CourseService.instance.getCourseById(widget.courseId);
      _loading = false;
    });
  }

  Future<void> _addLesson() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool uploading = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) =>
            AlertDialog(
              title: const Text('Add Video Lesson'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Lesson title',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'Video URL',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    uploading = true;
                                  });
                                  final String? url =
                                      await _pickAndUploadCourseFile(
                                        extensions: <String>[
                                          'mp4',
                                          'mov',
                                          'm4v',
                                          'avi',
                                          'mkv',
                                          'webm',
                                        ],
                                      );
                                  if (url != null) {
                                    urlController.text = url;
                                  }
                                  setStateDialog(() {
                                    uploading = false;
                                  });
                                },
                          icon: uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: const Text('Upload Video File'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)',
                        ),
                        validator: (String? v) {
                          final int? n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'Enter valid minutes';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    await CourseService.instance.addLesson(
                      courseId: widget.courseId,
                      title: titleController.text.trim(),
                      videoUrl: urlController.text.trim(),
                      durationMinutes: int.parse(
                        durationController.text.trim(),
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    _reload();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _editLesson(VideoLesson lesson) async {
    final TextEditingController titleController = TextEditingController(
      text: lesson.title,
    );
    final TextEditingController urlController = TextEditingController(
      text: lesson.videoUrl,
    );
    final TextEditingController durationController = TextEditingController(
      text: lesson.durationMinutes.toString(),
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool uploading = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) =>
            AlertDialog(
              title: const Text('Edit Lesson'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Lesson title',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'Video URL',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    uploading = true;
                                  });
                                  final String? url =
                                      await _pickAndUploadCourseFile(
                                        extensions: const <String>[
                                          'mp4',
                                          'mov',
                                          'm4v',
                                          'avi',
                                          'mkv',
                                          'webm',
                                        ],
                                      );
                                  if (url != null) {
                                    urlController.text = url;
                                  }
                                  setStateDialog(() {
                                    uploading = false;
                                  });
                                },
                          icon: uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: const Text('Upload Video File'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)',
                        ),
                        validator: (String? v) {
                          final int? n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) {
                            return 'Enter valid minutes';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    await CourseService.instance.updateLesson(
                      courseId: widget.courseId,
                      lessonId: lesson.id,
                      title: titleController.text.trim(),
                      videoUrl: urlController.text.trim(),
                      durationMinutes: int.parse(
                        durationController.text.trim(),
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    _reload();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _deleteLesson(VideoLesson lesson) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Delete "${lesson.title}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await CourseService.instance.deleteLesson(
      courseId: widget.courseId,
      lessonId: lesson.id,
    );
    if (!mounted) return;
    _reload();
  }

  Future<void> _addMaterial() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool uploading = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) =>
            AlertDialog(
              title: const Text('Add Study Material'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Material title',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'File URL (PDF/doc/video/etc)',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    uploading = true;
                                  });
                                  final String? url =
                                      await _pickAndUploadCourseFile(
                                        extensions: <String>[
                                          'pdf',
                                          'doc',
                                          'docx',
                                          'ppt',
                                          'pptx',
                                          'xls',
                                          'xlsx',
                                          'txt',
                                          'zip',
                                          'mp4',
                                          'mov',
                                          'm4v',
                                          'avi',
                                          'mkv',
                                          'webm',
                                        ],
                                      );
                                  if (url != null) {
                                    urlController.text = url;
                                  }
                                  setStateDialog(() {
                                    uploading = false;
                                  });
                                },
                          icon: uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.attach_file),
                          label: const Text('Upload PDF / File'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    await CourseService.instance.addStudyMaterial(
                      courseId: widget.courseId,
                      title: titleController.text.trim(),
                      pdfUrl: urlController.text.trim(),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    _reload();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _editMaterial(StudyMaterial material) async {
    final TextEditingController titleController = TextEditingController(
      text: material.title,
    );
    final TextEditingController urlController = TextEditingController(
      text: material.pdfUrl,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool uploading = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) =>
            AlertDialog(
              title: const Text('Edit Study Material'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Material title',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'File URL (PDF/doc/video/etc)',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  setStateDialog(() {
                                    uploading = true;
                                  });
                                  final String? url =
                                      await _pickAndUploadCourseFile(
                                        extensions: const <String>[
                                          'pdf',
                                          'doc',
                                          'docx',
                                          'ppt',
                                          'pptx',
                                          'xls',
                                          'xlsx',
                                          'txt',
                                          'zip',
                                          'mp4',
                                          'mov',
                                          'm4v',
                                          'avi',
                                          'mkv',
                                          'webm',
                                        ],
                                      );
                                  if (url != null) {
                                    urlController.text = url;
                                  }
                                  setStateDialog(() {
                                    uploading = false;
                                  });
                                },
                          icon: uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.attach_file),
                          label: const Text('Upload PDF / File'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    await CourseService.instance.updateStudyMaterial(
                      courseId: widget.courseId,
                      materialId: material.id,
                      title: titleController.text.trim(),
                      fileUrl: urlController.text.trim(),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    _reload();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _deleteMaterial(StudyMaterial material) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Study Material'),
        content: Text('Delete "${material.title}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await CourseService.instance.deleteStudyMaterial(
      courseId: widget.courseId,
      materialId: material.id,
    );
    if (!mounted) return;
    _reload();
  }

  Future<void> _addQuizQuestion() async {
    final TextEditingController questionController = TextEditingController();
    final List<TextEditingController> optionControllers =
        List<TextEditingController>.generate(4, (_) => TextEditingController());
    int correctIndex = 0;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) {
          return AlertDialog(
            title: const Text('Add Quiz Question'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Question text',
                      ),
                      validator: (String? v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    ...List<Widget>.generate(4, (int i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                          ),
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      );
                    }),
                    DropdownButtonFormField<int>(
                      initialValue: correctIndex,
                      decoration: const InputDecoration(
                        labelText: 'Correct option',
                      ),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 0, child: Text('Option 1')),
                        DropdownMenuItem(value: 1, child: Text('Option 2')),
                        DropdownMenuItem(value: 2, child: Text('Option 3')),
                        DropdownMenuItem(value: 3, child: Text('Option 4')),
                      ],
                      onChanged: (int? value) {
                        if (value != null) {
                          setStateDialog(() {
                            correctIndex = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  await CourseService.instance.addQuizQuestion(
                    courseId: widget.courseId,
                    question: questionController.text.trim(),
                    options: optionControllers
                        .map((TextEditingController c) => c.text.trim())
                        .toList(),
                    correctIndex: correctIndex,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _reload();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editQuizQuestion(QuizQuestion question) async {
    final TextEditingController questionController = TextEditingController(
      text: question.question,
    );
    final List<TextEditingController> optionControllers =
        List<TextEditingController>.generate(4, (int i) {
          final String value = i < question.options.length
              ? question.options[i]
              : '';
          return TextEditingController(text: value);
        });
    int correctIndex = question.correctIndex;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Quiz Question'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Question text',
                      ),
                      validator: (String? v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    ...List<Widget>.generate(4, (int i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                          ),
                          validator: (String? v) =>
                              (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      );
                    }),
                    DropdownButtonFormField<int>(
                      initialValue: correctIndex,
                      decoration: const InputDecoration(
                        labelText: 'Correct option',
                      ),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 0, child: Text('Option 1')),
                        DropdownMenuItem(value: 1, child: Text('Option 2')),
                        DropdownMenuItem(value: 2, child: Text('Option 3')),
                        DropdownMenuItem(value: 3, child: Text('Option 4')),
                      ],
                      onChanged: (int? value) {
                        if (value != null) {
                          setStateDialog(() {
                            correctIndex = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  await CourseService.instance.updateQuizQuestion(
                    courseId: widget.courseId,
                    quizId: question.quizId,
                    questionIndex: question.questionIndex,
                    question: questionController.text.trim(),
                    options: optionControllers
                        .map((TextEditingController c) => c.text.trim())
                        .toList(),
                    correctIndex: correctIndex,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _reload();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteQuizQuestion(QuizQuestion question) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Quiz Question'),
        content: const Text('Delete this question?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await CourseService.instance.deleteQuizQuestion(
      courseId: widget.courseId,
      quizId: question.quizId,
      questionIndex: question.questionIndex,
    );
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final Course? course = _course;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Editor')),
        body: const Center(child: Text('Course not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Manage: ${course.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              title: Text(course.title),
              subtitle: Text(
                '${course.description}\n\nThumbnail: ${course.thumbnailUrl}',
              ),
              isThreeLine: true,
              trailing: TextButton.icon(
                onPressed: _editCourseDetails,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: Text('Lessons (${course.lessons.length})'),
              children: <Widget>[
                ...course.lessons.map(
                  (VideoLesson l) => ListTile(
                    title: Text(l.title),
                    subtitle: Text('${l.durationMinutes} min • ${l.videoUrl}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _editLesson(l),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _deleteLesson(l),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addLesson,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lesson'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: Text('Study Materials (${course.studyMaterials.length})'),
              children: <Widget>[
                ...course.studyMaterials.map(
                  (StudyMaterial m) => ListTile(
                    title: Text(m.title),
                    subtitle: Text(m.pdfUrl),
                    trailing: Wrap(
                      spacing: 6,
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _editMaterial(m),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _deleteMaterial(m),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMaterial,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              title: Text('Quiz Questions (${course.quizQuestions.length})'),
              children: <Widget>[
                ...course.quizQuestions.map(
                  (QuizQuestion q) => ListTile(
                    title: Text(q.question),
                    subtitle: Text('Correct: Option ${q.correctIndex + 1}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _editQuizQuestion(q),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _deleteQuizQuestion(q),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addQuizQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Quiz Question'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
