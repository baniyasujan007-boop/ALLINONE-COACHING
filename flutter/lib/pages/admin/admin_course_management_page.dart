import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import 'admin_course_access_page.dart';
import 'admin_course_editor_page.dart';

class AdminCourseManagementPage extends StatefulWidget {
  const AdminCourseManagementPage({super.key});

  @override
  State<AdminCourseManagementPage> createState() =>
      _AdminCourseManagementPageState();
}

class _AdminCourseManagementPageState extends State<AdminCourseManagementPage> {
  List<Course> _courses = <Course>[];
  bool _loading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
    });
    await CourseService.instance.refreshCourses();
    if (!mounted) return;
    setState(() {
      _courses = CourseService.instance.getCourses();
      _loading = false;
    });
  }

  Future<void> _showCourseForm({Course? course}) async {
    final TextEditingController titleController = TextEditingController(
      text: course?.title ?? '',
    );
    final TextEditingController descController = TextEditingController(
      text: course?.description ?? '',
    );
    final TextEditingController thumbnailController = TextEditingController(
      text: course?.thumbnailUrl ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: course == null ? '' : course.price.toStringAsFixed(0),
    );
    final TextEditingController monthlyPriceController = TextEditingController(
      text: course == null || course.pricing.monthly <= 0
          ? ''
          : course.pricing.monthly.toStringAsFixed(0),
    );
    final TextEditingController quarterlyPriceController = TextEditingController(
      text: course == null || course.pricing.quarterly <= 0
          ? ''
          : course.pricing.quarterly.toStringAsFixed(0),
    );
    final TextEditingController semiAnnualPriceController = TextEditingController(
      text: course == null || course.pricing.semiAnnual <= 0
          ? ''
          : course.pricing.semiAnnual.toStringAsFixed(0),
    );
    final TextEditingController yearlyPriceController = TextEditingController(
      text: course == null || course.pricing.yearly <= 0
          ? ''
          : course.pricing.yearly.toStringAsFixed(0),
    );
    final TextEditingController offerTitleController = TextEditingController(
      text: course?.offer.title ?? '',
    );
    final TextEditingController offerMonthlyPriceController =
        TextEditingController(
          text: course == null || course.offer.pricing.monthly <= 0
              ? ''
              : course.offer.pricing.monthly.toStringAsFixed(0),
        );
    final TextEditingController offerQuarterlyPriceController =
        TextEditingController(
          text: course == null || course.offer.pricing.quarterly <= 0
              ? ''
              : course.offer.pricing.quarterly.toStringAsFixed(0),
        );
    final TextEditingController offerSemiAnnualPriceController =
        TextEditingController(
          text: course == null || course.offer.pricing.semiAnnual <= 0
              ? ''
              : course.offer.pricing.semiAnnual.toStringAsFixed(0),
        );
    final TextEditingController offerYearlyPriceController =
        TextEditingController(
          text: course == null || course.offer.pricing.yearly <= 0
              ? ''
              : course.offer.pricing.yearly.toStringAsFixed(0),
        );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool openContentEditorAfterSave = course == null;
    bool uploadingThumbnail = false;
    bool isLocked = course?.isLocked ?? true;
    bool offerEnabled = course?.offer.isActive ?? false;
    DateTime? offerExpiresAt = course?.offer.expiresAt;

    Future<void> uploadThumbnailFromGallery(
      BuildContext dialogContext,
      StateSetter setStateDialog,
    ) async {
      setStateDialog(() {
        uploadingThumbnail = true;
      });
      try {
        final XFile? picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
        );
        if (picked == null) {
          return;
        }
        final Uint8List bytes = await picked.readAsBytes();
        if (bytes.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Unable to read image')));
          return;
        }
        final String url = await CourseService.instance.uploadCourseThumbnail(
          bytes: bytes,
          filename: picked.name,
        );
        thumbnailController.text = url;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thumbnail uploaded: ${picked.name}')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thumbnail upload failed: $e')));
      } finally {
        if (dialogContext.mounted) {
          setStateDialog(() {
            uploadingThumbnail = false;
          });
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setStateDialog) {
          return AlertDialog(
            title: Text(course == null ? 'Add Course' : 'Edit Course'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course title',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: thumbnailController,
                      decoration: const InputDecoration(
                        labelText: 'Thumbnail URL',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a thumbnail URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: 'Rs ',
                      ),
                      validator: (String? value) {
                        final String raw = value?.trim() ?? '';
                        if (raw.isEmpty) {
                          return null;
                        }
                        final double? parsed = double.tryParse(raw);
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _pricingField(
                      controller: monthlyPriceController,
                      label: 'Monthly price',
                    ),
                    const SizedBox(height: 12),
                    _pricingField(
                      controller: quarterlyPriceController,
                      label: 'Quarterly price',
                    ),
                    const SizedBox(height: 12),
                    _pricingField(
                      controller: semiAnnualPriceController,
                      label: 'Semi-annual price',
                    ),
                    const SizedBox(height: 12),
                    _pricingField(
                      controller: yearlyPriceController,
                      label: 'Yearly price',
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: offerEnabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable limited-time offer'),
                      subtitle: const Text(
                        'Show this course in the home-page offer section',
                      ),
                      onChanged: (bool value) {
                        setStateDialog(() {
                          offerEnabled = value;
                          if (offerEnabled && offerExpiresAt == null) {
                            offerExpiresAt = DateTime.now().add(
                              const Duration(days: 7),
                            );
                          }
                        });
                      },
                    ),
                    if (offerEnabled) ...<Widget>[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: offerTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Offer title',
                          hintText: 'Flash sale, Festive offer, Weekend drop',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Offer ends'),
                        subtitle: Text(
                          offerExpiresAt == null
                              ? 'Choose offer end date and time'
                              : _formatDateTime(offerExpiresAt!),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: <Widget>[
                            TextButton(
                              onPressed: () async {
                                final DateTime now = DateTime.now();
                                final DateTime initialDate =
                                    offerExpiresAt ?? now.add(const Duration(days: 7));
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      context: dialogContext,
                                      initialDate: initialDate,
                                      firstDate: now,
                                      lastDate: now.add(const Duration(days: 365)),
                                    );
                                if (pickedDate == null || !dialogContext.mounted) {
                                  return;
                                }
                                final TimeOfDay initialTime = offerExpiresAt == null
                                    ? const TimeOfDay(hour: 23, minute: 59)
                                    : TimeOfDay.fromDateTime(offerExpiresAt!);
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                      context: dialogContext,
                                      initialTime: initialTime,
                                    );
                                if (pickedTime == null) {
                                  return;
                                }
                                setStateDialog(() {
                                  offerExpiresAt = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              },
                              child: const Text('Choose'),
                            ),
                            if (offerExpiresAt != null)
                              TextButton(
                                onPressed: () {
                                  setStateDialog(() {
                                    offerExpiresAt = null;
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _pricingField(
                        controller: offerMonthlyPriceController,
                        label: 'Offer monthly price',
                      ),
                      const SizedBox(height: 12),
                      _pricingField(
                        controller: offerQuarterlyPriceController,
                        label: 'Offer quarterly price',
                      ),
                      const SizedBox(height: 12),
                      _pricingField(
                        controller: offerSemiAnnualPriceController,
                        label: 'Offer semi-annual price',
                      ),
                      const SizedBox(height: 12),
                      _pricingField(
                        controller: offerYearlyPriceController,
                        label: 'Offer yearly price',
                      ),
                    ],
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: isLocked,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lock course'),
                      subtitle: const Text(
                        'Students must pay before they can use this course',
                      ),
                      onChanged: (bool value) {
                        setStateDialog(() {
                          isLocked = value;
                        });
                      },
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
                                  await uploadThumbnailFromGallery(
                                    dialogContext,
                                    setStateDialog,
                                  );
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
                                  final FilePickerResult? result =
                                      await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: const <String>[
                                          'jpg',
                                          'jpeg',
                                          'png',
                                          'webp',
                                        ],
                                        withData: true,
                                      );
                                  if (result != null &&
                                      result.files.isNotEmpty &&
                                      result.files.first.bytes != null) {
                                    if (!mounted) return;
                                    final ScaffoldMessengerState messenger =
                                        ScaffoldMessenger.of(context);
                                    try {
                                      final String url = await CourseService
                                          .instance
                                          .uploadCourseThumbnail(
                                            bytes: result.files.first.bytes!,
                                            filename: result.files.first.name,
                                          );
                                      thumbnailController.text = url;
                                      if (dialogContext.mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Thumbnail uploaded: ${result.files.first.name}',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (dialogContext.mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Thumbnail upload failed: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                  if (dialogContext.mounted) {
                                    setStateDialog(() {
                                      uploadingThumbnail = false;
                                    });
                                  }
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
                    if (course == null) ...<Widget>[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: openContentEditorAfterSave,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Open editor after create'),
                        subtitle: const Text('Add videos and files right away'),
                        onChanged: (bool value) {
                          setStateDialog(() {
                            openContentEditorAfterSave = value;
                          });
                        },
                      ),
                    ],
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

                  final String title = titleController.text.trim();
                  final String description = descController.text.trim();
                  final String thumbnailUrl = thumbnailController.text.trim();
                  final double fallbackPrice =
                      double.tryParse(priceController.text.trim()) ?? 0;
                  final CoursePricing pricing = CoursePricing(
                    monthly:
                        double.tryParse(monthlyPriceController.text.trim()) ?? 0,
                    quarterly:
                        double.tryParse(quarterlyPriceController.text.trim()) ?? 0,
                    semiAnnual:
                        double.tryParse(semiAnnualPriceController.text.trim()) ?? 0,
                    yearly:
                        double.tryParse(yearlyPriceController.text.trim()) ?? 0,
                  );
                  final CourseOffer offer = offerEnabled
                      ? CourseOffer(
                          title: offerTitleController.text.trim(),
                          pricing: CoursePricing(
                            monthly:
                                double.tryParse(
                                  offerMonthlyPriceController.text.trim(),
                                ) ??
                                0,
                            quarterly:
                                double.tryParse(
                                  offerQuarterlyPriceController.text.trim(),
                                ) ??
                                0,
                            semiAnnual:
                                double.tryParse(
                                  offerSemiAnnualPriceController.text.trim(),
                                ) ??
                                0,
                            yearly:
                                double.tryParse(
                                  offerYearlyPriceController.text.trim(),
                                ) ??
                                0,
                          ),
                          expiresAt: offerExpiresAt,
                        )
                      : const CourseOffer();
                  final double price =
                      pricing.lowest > 0 ? pricing.lowest : fallbackPrice;

                  if (course == null) {
                    await CourseService.instance.addCourse(
                      title: title,
                      description: description,
                      thumbnailUrl: thumbnailUrl,
                      price: price,
                      pricing: pricing,
                      offer: offer,
                      isLocked: isLocked,
                    );
                  } else {
                    await CourseService.instance.updateCourse(
                      courseId: course.id,
                      title: title,
                      description: description,
                      thumbnailUrl: thumbnailUrl,
                      price: price,
                      pricing: pricing,
                      offer: offer,
                      isLocked: isLocked,
                    );
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  await _reload();

                  if (!mounted ||
                      !openContentEditorAfterSave ||
                      course != null) {
                    return;
                  }

                  Course? created;
                  for (final Course c in _courses) {
                    if (c.title == title &&
                        c.description == description &&
                        c.thumbnailUrl == thumbnailUrl &&
                        c.price == price &&
                        c.isLocked == isLocked) {
                      created = c;
                      break;
                    }
                  }
                  created ??= _courses.isEmpty ? null : _courses.first;
                  if (created == null) return;
                  final Course createdCourse = created;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminCourseEditorPage(courseId: createdCourse.id),
                    ),
                  );
                  if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Course Management'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await AuthService.instance.logout();
              if (!context.mounted) {
                return;
              }
              Navigator.popUntil(
                context,
                (Route<dynamic> route) => route.isFirst,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCourseForm,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final Course course = _courses[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        course.title.isEmpty
                            ? '?'
                            : course.title.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(course.title),
                    subtitle: Text(
                      '${course.isLocked ? 'Locked' : 'Unlocked'} • ${course.offer.isActive ? 'Offer live' : 'Regular pricing'} • Starts at Rs ${(course.offer.isActive ? course.offer.pricing.lowest : (course.pricing.lowest > 0 ? course.pricing.lowest : course.price)).toStringAsFixed(0)} • ${course.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.lock_person_outlined),
                          tooltip: 'Manage Access',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AdminCourseAccessPage(course: course),
                              ),
                            );
                            if (!mounted) {
                              return;
                            }
                            _reload();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminCourseEditorPage(courseId: course.id),
                              ),
                            );
                            _reload();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showCourseForm(course: course),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await CourseService.instance.deleteCourse(
                              course.id,
                            );
                            await _reload();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _pricingField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rs ',
      ),
      validator: (String? value) {
        final String raw = value?.trim() ?? '';
        if (raw.isEmpty) {
          return null;
        }
        final double? parsed = double.tryParse(raw);
        if (parsed == null || parsed < 0) {
          return 'Enter a valid price';
        }
        return null;
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
  }
}
