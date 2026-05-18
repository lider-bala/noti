import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:firebase_storage/firebase_storage.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/app_theme.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController(text: '1.2 МБ');
  String? _selectedCategory;
  String? _selectedClassId;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _openAddFileDialog() {
    final appState = context.appState;
    final classes = appState.currentUser == null
        ? appState.schoolClasses
        : appState.classesForTeacher(appState.currentUser!.id);
    final categories = _categoriesFromState(appState.managedFiles);

    _topicController.clear();
    _descriptionController.clear();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isUploading = false;
        var uploadProgress = 0.0;
        var uploadComplete = false;
        var fileNameText = _nameController.text;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(context.tr('Добавить файл')),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                            context, context.tr('Название файла')),
                        onChanged: (value) => fileNameText = value,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _topicController,
                        decoration:
                            _inputDecoration(context, context.tr('Тема')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration:
                            _inputDecoration(context, context.tr('Описание')),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      AppSelectField<String>(
                        value: _selectedCategory,
                        label: context.tr('Категория'),
                        icon: Icons.category_rounded,
                        options: categories
                            .map(
                              (item) => AppSelectOption<String>(
                                value: item,
                                label: context.tr(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => _selectedCategory = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      AppSelectField<String?>(
                        value: _selectedClassId,
                        label: context.tr('Класс для файла'),
                        icon: Icons.meeting_room_rounded,
                        options: [
                          AppSelectOption<String?>(
                            value: null,
                            label: context.tr('Без привязки к классу'),
                          ),
                          ...classes.map(
                            (item) => AppSelectOption<String?>(
                              value: item.id,
                              label: item.name,
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() => _selectedClassId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sizeController,
                        decoration: _inputDecoration(
                            context, context.tr('Размер файла')),
                        readOnly: true,
                      ),
                      if (isUploading && !uploadComplete) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: uploadProgress,
                          backgroundColor: context.appBorderColor,
                          color: const Color(0xFF10B981),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                            fontSize: 16,
                          ),
                        ),
                      ],
                      if (uploadComplete) ...[
                        const SizedBox(height: 16),
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981), size: 48),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('Файл загружен!'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr('Отмена')),
                ),
                if (uploadComplete)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _nameController.clear();
                      _topicController.clear();
                      _descriptionController.clear();
                      _sizeController.text = 'Выбирается автоматически';
                      setState(() {
                        _selectedCategory = null;
                        _selectedClassId = null;
                      });
                    },
                    child: Text(context.tr('Готово!')),
                  )
                else
                  FilledButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            if ((_selectedCategory ?? '').trim().isEmpty) {
                              showAppSnackBar(
                                context,
                                context.tr('Выберите категорию файла.'),
                                backgroundColor: const Color(0xFFB91C1C),
                              );
                              return;
                            }

                            setDialogState(() {
                              isUploading = true;
                              uploadProgress = 0.0;
                            });

                            final addFailedText =
                                context.tr('Не удалось добавить файл.');
                            final uploadFailedText = context.tr(
                              'Не удалось загрузить файл. Проверьте Firebase Storage.',
                            );
                            try {
                              fp.FilePickerResult? pickerResult =
                                  await fp.FilePicker.pickFiles(
                                type: fp.FileType.custom,
                                allowedExtensions: [
                                  'pdf',
                                  'doc',
                                  'docx',
                                  'ppt',
                                  'pptx',
                                  'jpg',
                                  'png',
                                  'jpeg',
                                ],
                                withData: true,
                              );

                              if (pickerResult == null ||
                                  pickerResult.files.isEmpty) {
                                setDialogState(() => isUploading = false);
                                return;
                              }

                              final pickedFile = pickerResult.files.first;
                              if (pickedFile.size > 5 * 1024 * 1024) {
                                if (mounted && dialogContext.mounted) {
                                  showAppSnackBar(
                                    context,
                                    context.tr(
                                        'Файл слишком большой. Максимум 5 МБ.'),
                                    backgroundColor: const Color(0xFFB91C1C),
                                  );
                                  setDialogState(() => isUploading = false);
                                }
                                return;
                              }

                              final ownerId =
                                  appState.currentUser?.id ?? 'teacher';
                              final folderPath = _selectedClassId == null
                                  ? 'schools/main/teacher-files/$ownerId'
                                  : 'schools/main/class-files/$_selectedClassId/$ownerId';

                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child('$folderPath/${pickedFile.name}');

                              final ext =
                                  pickedFile.name.split('.').last.toLowerCase();
                              final contentType = _mimeType(ext);

                              UploadTask uploadTask;
                              final metadata =
                                  SettableMetadata(contentType: contentType);
                              if (kIsWeb) {
                                uploadTask = storageRef.putData(
                                    pickedFile.bytes!, metadata);
                              } else {
                                if (pickedFile.path != null) {
                                  uploadTask = storageRef.putFile(
                                      File(pickedFile.path!), metadata);
                                } else {
                                  uploadTask = storageRef.putData(
                                      pickedFile.bytes!, metadata);
                                }
                              }

                              uploadTask.snapshotEvents.listen((event) {
                                if (mounted && dialogContext.mounted) {
                                  final progress =
                                      event.bytesTransferred / event.totalBytes;
                                  setDialogState(
                                      () => uploadProgress = progress);
                                }
                              });

                              final snapshot = await uploadTask;
                              final downloadUrl =
                                  await snapshot.ref.getDownloadURL();

                              final fileSizeMb =
                                  '${(pickedFile.size / (1024 * 1024)).toStringAsFixed(1)} МБ';

                              if (!mounted || !dialogContext.mounted) {
                                return;
                              }
                              final fileName = fileNameText.trim().isEmpty
                                  ? pickedFile.name
                                  : fileNameText.trim();
                              final fileResult =
                                  await appState.createManagedFile(
                                name: fileName,
                                category: _selectedCategory!,
                                sizeLabel: fileSizeMb,
                                classId: _selectedClassId,
                                storagePath: storageRef.fullPath,
                                downloadUrl: downloadUrl,
                                contentType: contentType,
                                topic: _topicController.text,
                                description: _descriptionController.text,
                              );
                              if (!mounted || !dialogContext.mounted) {
                                return;
                              }
                              final file = fileResult.data;
                              if (file == null) {
                                showAppSnackBar(
                                  context,
                                  addFailedText,
                                  backgroundColor: const Color(0xFFB91C1C),
                                );
                                setDialogState(() => isUploading = false);
                                return;
                              }
                              setDialogState(() {
                                uploadComplete = true;
                                uploadProgress = 1.0;
                              });
                            } catch (_) {
                              if (!mounted || !dialogContext.mounted) {
                                return;
                              }
                              setDialogState(() => isUploading = false);
                              showAppSnackBar(
                                context,
                                uploadFailedText,
                                backgroundColor: const Color(0xFFB91C1C),
                              );
                            }
                          },
                    child: isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('Выбрать и загрузить')),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.appState;
    final allFiles = appState.managedFiles;
    final files = allFiles;
    final categories = _groupFilesByCategory(allFiles);
    final scopedFiles = allFiles.where((file) => file.classId != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFFD946EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 32,
                  offset: Offset(0, 20),
                  color: Color(0x33000000)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('Файлы'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                context.tr(
                    'Единый каталог материалов: файлы прикрепляются к классам и сразу видны в системе.'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
                title: context.tr('Всего файлов'),
                value: '${allFiles.length}',
                color: const Color(0xFF9333EA)),
            _MetricCard(
                title: context.tr('Категорий'),
                value: '${categories.length}',
                color: const Color(0xFF2563EB)),
            _MetricCard(
                title: context.tr('Файлы по классам'),
                value: '$scopedFiles',
                color: const Color(0xFF059669)),
          ],
        ),
        const SizedBox(height: 20),
        Text(context.tr('Папки'),
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600, color: context.primaryTextColor)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (context, index) {
            final entry = categories.entries.elementAt(index);
            return _FolderCard(
              name: entry.key,
              filesCount: entry.value.length,
              accent: _folderAccent(index),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
            files.length == allFiles.length
                ? context.tr('Недавние файлы')
                : context.tr('Результаты поиска'),
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600, color: context.primaryTextColor)),
        const SizedBox(height: 12),
        if (files.isEmpty)
          _EmptyFilesState(
            title: context.tr('Файлы не найдены'),
            subtitle: context.tr('Измените фильтры или добавьте файлы.'),
          )
        else
          Column(
            children: [
              for (var i = 0; i < files.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentFileTile(file: files[i]),
                ),
            ],
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openAddFileDialog,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: Icon(Icons.upload_file_rounded),
            label: Text(context.tr('+ Загрузить файл')),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorderColor),
          boxShadow: const [
            BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 14),
                color: Color(0x14000000)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_copy_rounded, color: color),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.primaryTextColor)),
            const SizedBox(height: 4),
            Text(title,
                style:
                    TextStyle(color: context.secondaryTextColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final int filesCount;
  final List<Color> accent;

  const _FolderCard(
      {required this.name, required this.filesCount, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
              blurRadius: 24,
              offset: Offset(0, 14),
              color: Color(0x14000000)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: accent),
            ),
            child: Icon(Icons.folder_rounded, color: Colors.white),
          ),
          const Spacer(),
          Text(context.tr(name),
              style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(context.trf('{value} файлов', {'value': '$filesCount'}),
              style:
                  TextStyle(color: context.secondaryTextColor, fontSize: 13)),
        ],
      ),
    );
  }
}

class _RecentFileTile extends StatelessWidget {
  final ManagedSchoolFile file;
  const _RecentFileTile({required this.file});

  @override
  Widget build(BuildContext context) {
    final uploader = context.appState.userById(file.uploadedByUserId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 10),
              color: Color(0x12000000)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                color: Color(0xFF9333EA)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: TextStyle(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w700)),
                if ((file.topic ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(file.topic!,
                      style: TextStyle(
                          color: Color(0xFF2563EB), fontSize: 13)),
                ],
                const SizedBox(height: 4),
                Text(
                    [
                      context.tr(file.category),
                      if ((file.classId ?? '').isNotEmpty) file.classId!,
                      file.sizeLabel,
                    ].join(' • '),
                    style: TextStyle(
                        color: context.secondaryTextColor, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                    [
                      MaterialLocalizations.of(context)
                          .formatShortDate(file.uploadedAt),
                      if (uploader != null) uploader.fullName,
                    ].join(' • '),
                    style: TextStyle(
                        color: context.secondaryTextColor, fontSize: 12)),
                if ((file.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(file.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.secondaryTextColor, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilesState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyFilesState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload_rounded,
              color: Color(0xFFA855F7), size: 34),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  color: context.primaryTextColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.secondaryTextColor)),
        ],
      ),
    );
  }
}

Map<String, List<ManagedSchoolFile>> _groupFilesByCategory(
    List<ManagedSchoolFile> files) {
  final result = <String, List<ManagedSchoolFile>>{};
  for (final file in files) {
    result.putIfAbsent(file.category, () => []).add(file);
  }
  return result;
}

List<String> _categoriesFromState(List<ManagedSchoolFile> files) {
  final categories = _groupFilesByCategory(files).keys.toList();
  const defaults = [
    'Учебные материалы',
    'Методические пособия',
    'Контрольные работы',
    'Презентации',
  ];
  for (final item in defaults) {
    if (!categories.contains(item)) {
      categories.add(item);
    }
  }
  return categories;
}

List<Color> _folderAccent(int index) {
  const accents = [
    [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    [Color(0xFFA855F7), Color(0xFF8B5CF6)],
    [Color(0xFFF97373), Color(0xFFFB7185)],
    [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  ];
  return accents[index % accents.length];
}

String _mimeType(String ext) {
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    default:
      return 'application/octet-stream';
  }
}

InputDecoration _inputDecoration(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: context.secondaryTextColor),
    filled: true,
    fillColor: context.panelMutedColor,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: context.appBorderColor)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: context.appBorderColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.4)),
  );
}
