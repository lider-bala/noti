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
  final _searchController = TextEditingController();

  String? _selectedCategory;
  String? _selectedClassId;
  String? _filterCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
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
    _nameController.clear();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isUploading = false;
        var uploadComplete = false;
        double uploadProgress = 0;
        var fileNameText = '';
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (uploadComplete) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: context.greenTintFg,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        context.tr('Файл успешно загружен!'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.primaryTextColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        context.tr('Файл прикреплён и доступен в истории.'),
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        setState(() {});
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        context.tr('Готово!'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

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
                        controller: _topicController,
                        decoration: _inputDecoration(
                            context, context.tr('Тема')),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration: _inputDecoration(
                            context, context.tr('Описание')),
                        maxLines: 3,
                        minLines: 2,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                            context, context.tr('Название файла')),
                        onChanged: (value) => fileNameText = value,
                      ),
                      SizedBox(height: 12),
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
                          setDialogState(
                              () => _selectedCategory = value);
                        },
                      ),
                      SizedBox(height: 12),
                      AppSelectField<String?>(
                        value: _selectedClassId,
                        label: context.tr('Класс для файла'),
                        icon: Icons.meeting_room_rounded,
                        options: [
                          AppSelectOption<String?>(
                            value: null,
                            label:
                                context.tr('Без привязки к классу'),
                          ),
                          ...classes.map(
                            (item) => AppSelectOption<String?>(
                              value: item.id,
                              label: item.name,
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(
                              () => _selectedClassId = value);
                        },
                      ),
                      if (isUploading) ...[
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('Загрузка...'),
                                  style: TextStyle(
                                    color: context.secondaryTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${(uploadProgress * 100).toInt()}%',
                                  style: TextStyle(
                                    color: context.blueTintFg,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: uploadProgress,
                                minHeight: 10,
                                backgroundColor:
                                    const Color(0xFFE5E7EB),
                                valueColor:
                                    const AlwaysStoppedAnimation<
                                        Color>(Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr('Отмена')),
                ),
                FilledButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if ((_selectedCategory ?? '').trim().isEmpty) {
                            showAppSnackBar(
                              context,
                              context.tr('Выберите категорию файла.'),
                              backgroundColor:
                                  const Color(0xFFB91C1C),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                            uploadProgress = 0;
                          });

                          final addFailedText = context
                              .tr('Не удалось добавить файл.');
                          final uploadFailedText = context.tr(
                            'Не удалось загрузить файл. Проверьте Firebase Storage.',
                          );
                          try {
                            fp.FilePickerResult? pickerResult =
                                await fp.FilePicker.pickFiles(
                              type: fp.FileType.custom,
                              allowedExtensions: ['pdf'],
                              withData: true,
                            );

                            if (pickerResult == null ||
                                pickerResult.files.isEmpty) {
                              setDialogState(
                                  () => isUploading = false);
                              return;
                            }

                            final pickedFile =
                                pickerResult.files.first;
                            if (pickedFile.size >
                                5 * 1024 * 1024) {
                              if (mounted &&
                                  dialogContext.mounted) {
                                showAppSnackBar(
                                  context,
                                  context.tr(
                                      'Файл слишком большой. Максимум 5 МБ.'),
                                  backgroundColor:
                                      const Color(0xFFB91C1C),
                                );
                                setDialogState(
                                    () => isUploading = false);
                              }
                              return;
                            }

                            final ownerId =
                                appState.currentUser?.id ??
                                    'teacher';
                            final folderPath =
                                _selectedClassId == null
                                    ? 'schools/main/teacher-files/$ownerId'
                                    : 'schools/main/class-files/$_selectedClassId/$ownerId';

                            final storageRef = FirebaseStorage
                                .instance
                                .ref()
                                .child(
                                    '$folderPath/${pickedFile.name}');

                            UploadTask uploadTask;
                            if (kIsWeb) {
                              uploadTask = storageRef.putData(
                                  pickedFile.bytes!,
                                  SettableMetadata(
                                      contentType:
                                          'application/pdf'));
                            } else {
                              if (pickedFile.path != null) {
                                uploadTask = storageRef.putFile(
                                    File(pickedFile.path!),
                                    SettableMetadata(
                                        contentType:
                                            'application/pdf'));
                              } else {
                                uploadTask = storageRef.putData(
                                    pickedFile.bytes!,
                                    SettableMetadata(
                                        contentType:
                                            'application/pdf'));
                              }
                            }

                            uploadTask.snapshotEvents.listen(
                                (snapshot) {
                              if (snapshot.totalBytes > 0) {
                                final progress =
                                    snapshot.bytesTransferred /
                                        snapshot.totalBytes;
                                if (dialogContext.mounted) {
                                  setDialogState(() =>
                                      uploadProgress = progress);
                                }
                              }
                            });

                            final snapshot = await uploadTask;
                            final downloadUrl = await snapshot
                                .ref
                                .getDownloadURL();

                            final fileSizeMb =
                                '${(pickedFile.size / (1024 * 1024)).toStringAsFixed(1)} МБ';

                            if (!mounted ||
                                !dialogContext.mounted) {
                              return;
                            }
                            final fileName =
                                fileNameText.trim().isEmpty
                                    ? pickedFile.name
                                    : fileNameText.trim();
                            final fileResult =
                                await appState.createManagedFile(
                              name: fileName,
                              category: _selectedCategory!,
                              sizeLabel: fileSizeMb,
                              classId: _selectedClassId,
                              storagePath:
                                  storageRef.fullPath,
                              downloadUrl: downloadUrl,
                              contentType: 'application/pdf',
                              topic: _topicController.text,
                              description:
                                  _descriptionController.text,
                            );
                            if (!mounted ||
                                !dialogContext.mounted) {
                              return;
                            }
                            final file = fileResult.data;
                            if (file == null) {
                              showAppSnackBar(
                                context,
                                addFailedText,
                                backgroundColor:
                                    const Color(0xFFB91C1C),
                              );
                              setDialogState(
                                  () => isUploading = false);
                              return;
                            }

                            setDialogState(() {
                              isUploading = false;
                              uploadComplete = true;
                              uploadProgress = 1.0;
                            });
                            _nameController.clear();
                            _topicController.clear();
                            _descriptionController.clear();
                            _selectedCategory = null;
                            _selectedClassId = null;
                          } catch (_) {
                            if (!mounted ||
                                !dialogContext.mounted) {
                              return;
                            }
                            setDialogState(
                                () => isUploading = false);
                            showAppSnackBar(
                              context,
                              uploadFailedText,
                              backgroundColor:
                                  const Color(0xFFB91C1C),
                            );
                          }
                        },
                  child: isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
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

    final filteredFiles = allFiles.where((file) {
      if (_filterCategory != null && file.category != _filterCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = file.name.toLowerCase().contains(q);
        final topicMatch =
            (file.topic ?? '').toLowerCase().contains(q);
        final descMatch =
            (file.description ?? '').toLowerCase().contains(q);
        final catMatch = file.category.toLowerCase().contains(q);
        if (!nameMatch && !topicMatch && !descMatch && !catMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    final categories = _groupFilesByCategory(allFiles);
    final scopedFiles =
        allFiles.where((file) => file.classId != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFA855F7),
                Color(0xFFD946EF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                blurRadius: 32,
                offset: Offset(0, 20),
                color: Color(0x33000000),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Файлы'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.tr(
                  'Единый каталог материалов: файлы прикрепляются к классам и сразу видны в системе.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              title: context.tr('Всего файлов'),
              value: '${allFiles.length}',
              color: const Color(0xFF9333EA),
            ),
            _MetricCard(
              title: context.tr('Категорий'),
              value: '${categories.length}',
              color: context.blueTintFg,
            ),
            _MetricCard(
              title: context.tr('Файлы по классам'),
              value: '$scopedFiles',
              color: context.greenTintFg,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Search & filter
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 600;
            final searchField = TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('Поиск по файлам...'),
                hintStyle:
                    TextStyle(color: context.mutedTextColor),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                      color: Color(0xFF9333EA), width: 1.4),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            );
            final filterField = AppSelectField<String?>(
              value: _filterCategory,
              label: context.tr('Фильтр'),
              icon: Icons.filter_list_rounded,
              options: [
                AppSelectOption<String?>(
                  value: null,
                  label: context.tr('Все категории'),
                ),
                ...categories.keys.map(
                  (cat) => AppSelectOption<String?>(
                    value: cat,
                    label: context.tr(cat),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _filterCategory = value);
              },
            );

            if (stacked) {
              return Column(
                children: [
                  searchField,
                  const SizedBox(height: 12),
                  filterField,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                Expanded(child: filterField),
              ],
            );
          },
        ),
        SizedBox(height: 20),
        Text(
          context.tr('История файлов'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.primaryTextColor,
          ),
        ),
        SizedBox(height: 12),
        if (filteredFiles.isEmpty)
          _EmptyFilesState(
            title: _searchQuery.isNotEmpty || _filterCategory != null
                ? context.tr('Файлы не найдены')
                : context.tr('Файлы пока не добавлены'),
            subtitle: _searchQuery.isNotEmpty || _filterCategory != null
                ? context.tr('Попробуйте изменить поиск или фильтр.')
                : context.tr(
                    'Добавьте первый материал, чтобы он появился в каталоге школы.',
                  ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < filteredFiles.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentFileTile(file: filteredFiles[i]),
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
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorderColor),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              offset: Offset(0, 14),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_copy_rounded, color: color),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: context.primaryTextColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x12000000),
          ),
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
            child: const Icon(
              Icons.insert_drive_file_rounded,
              color: Color(0xFF9333EA),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((file.topic ?? '').isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    '${context.tr('Тема')}: ${file.topic}',
                    style: TextStyle(
                      color: context.blueTintFg,
                      fontSize: 13,
                    ),
                  ),
                ],
                if ((file.description ?? '').isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    file.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  [
                    context.tr(file.category),
                    if ((file.classId ?? '').isNotEmpty) file.classId!,
                    file.sizeLabel,
                  ].join(' • '),
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    MaterialLocalizations.of(context)
                        .formatShortDate(file.uploadedAt),
                    if (uploader != null) uploader.fullName,
                  ].join(' • '),
                  style: TextStyle(
                    color: context.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
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

  const _EmptyFilesState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_rounded,
            color: Color(0xFFA855F7),
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, List<ManagedSchoolFile>> _groupFilesByCategory(
  List<ManagedSchoolFile> files,
) {
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

InputDecoration _inputDecoration(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: context.secondaryTextColor),
    filled: true,
    fillColor: context.panelMutedColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFA855F7),
        width: 1.4,
      ),
    ),
  );
}
