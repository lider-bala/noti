import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_theme.dart';

class StudentFilesScreen extends StatelessWidget {
  const StudentFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final classId = appState.currentUser?.schoolClass;
    final visibleFiles = appState.managedFiles.where((file) {
      return file.classId == null || file.classId == classId;
    }).toList();
    final folders = _foldersFromFiles(visibleFiles);
    final recentFiles = visibleFiles.map(_recentFromManagedFile).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeaderCard(),
        const SizedBox(height: 16),
        _StorageCard(filesCount: visibleFiles.length),
        const SizedBox(height: 24),
        Text(
          context.tr('По предметам'),
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _FoldersGrid(folders: folders),
        const SizedBox(height: 24),
        Text(
          context.tr('Недавние файлы'),
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (recentFiles.isEmpty)
          _EmptyFilesState()
        else
          Column(
            children: [
              for (int i = 0; i < recentFiles.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                _RecentFileCard(file: recentFiles[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 26,
            offset: Offset(0, 18),
            color: Color(0x33000000),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Мои файлы'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.tr('Учебные материалы и документы'),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  final int filesCount;

  const _StorageCard({required this.filesCount});

  @override
  Widget build(BuildContext context) {
    final usageFactor =
        filesCount == 0 ? 0.0 : (filesCount / 20).clamp(0.05, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('Использовано хранилище'),
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
              Text(
                context.trf('{value} файлов', {'value': '$filesCount'}),
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 12,
              color: context.appBorderColor,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: usageFactor,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Folder {
  final String name;
  final int filesCount;
  final List<Color> colors;

  const _Folder({
    required this.name,
    required this.filesCount,
    required this.colors,
  });
}

class _FoldersGrid extends StatelessWidget {
  final List<_Folder> folders;

  const _FoldersGrid({required this.folders});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          itemCount: folders.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2 : 1.4,
          ),
          itemBuilder: (context, index) {
            return _FolderCard(folder: folders[index]);
          },
        );
      },
    );
  }
}

class _FolderCard extends StatelessWidget {
  final _Folder folder;

  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: folder.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.folder_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(folder.name),
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.trf('{value} файлов', {'value': '${folder.filesCount}'}),
            style: TextStyle(
              color: context.secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

enum FileType { pdf, excel, powerpoint, image }

class _RecentFile {
  final String name;
  final String subject;
  final String date;
  final String size;
  final FileType type;
  final String? downloadUrl;

  const _RecentFile({
    required this.name,
    required this.subject,
    required this.date,
    required this.size,
    required this.type,
    this.downloadUrl,
  });
}

class _RecentFileCard extends StatelessWidget {
  final _RecentFile file;

  const _RecentFileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    final typeStyle = _typeStyle(file.type);
    final iconData = _typeIcon(file.type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: typeStyle.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconData,
              color: typeStyle.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(file.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.appBorderColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr(file.subject),
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      file.size,
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () async {
              final url = file.downloadUrl;
              if (url != null && url.isNotEmpty) {
                final uri = Uri.tryParse(url);
                if (uri == null || !uri.hasScheme) {
                  showAppSnackBar(
                    context,
                    context.tr('Ссылка на файл повреждена.'),
                    backgroundColor: const Color(0xFFB91C1C),
                  );
                  return;
                }
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (context.mounted && !launched) {
                  showAppSnackBar(
                    context,
                    context.tr('Не удалось открыть файл.'),
                    backgroundColor: const Color(0xFFB91C1C),
                  );
                }
                return;
              }
              showAppSnackBar(
                context,
                context.tr('У этого файла нет ссылки для скачивания.'),
                backgroundColor: const Color(0xFFB91C1C),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TypeStyle _typeStyle(FileType type) {
    switch (type) {
      case FileType.pdf:
        return const _TypeStyle(
          bgColor: Color(0xFFFEE2E2),
          iconColor: Color(0xFFDC2626),
        );
      case FileType.excel:
        return const _TypeStyle(
          bgColor: Color(0xFFD1FAE5),
          iconColor: Color(0xFF059669),
        );
      case FileType.powerpoint:
        return const _TypeStyle(
          bgColor: Color(0xFFFFEDD5),
          iconColor: Color(0xFFEA580C),
        );
      case FileType.image:
        return const _TypeStyle(
          bgColor: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
        );
    }
  }

  IconData _typeIcon(FileType type) {
    switch (type) {
      case FileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileType.excel:
        return Icons.table_chart_rounded;
      case FileType.powerpoint:
        return Icons.slideshow_rounded;
      case FileType.image:
        return Icons.image_rounded;
    }
  }
}

class _TypeStyle {
  final Color bgColor;
  final Color iconColor;

  const _TypeStyle({
    required this.bgColor,
    required this.iconColor,
  });
}

class _EmptyFilesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, color: context.secondaryTextColor),
          const SizedBox(height: 8),
          Text(
            context.tr('Файлы пока не добавлены'),
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(
                'Когда учитель загрузит файл для класса, он появится здесь.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

List<_Folder> _foldersFromFiles(List<ManagedSchoolFile> files) {
  final grouped = <String, int>{};
  for (final file in files) {
    grouped[file.category] = (grouped[file.category] ?? 0) + 1;
  }
  return grouped.entries.map((entry) {
    final index = grouped.keys.toList().indexOf(entry.key);
    return _Folder(
      name: entry.key,
      filesCount: entry.value,
      colors: _folderColors(index),
    );
  }).toList();
}

List<Color> _folderColors(int index) {
  const colors = [
    [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    [Color(0xFFA855F7), Color(0xFF7C3AED)],
    [Color(0xFFF472B6), Color(0xFFEC4899)],
    [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  ];
  return colors[index % colors.length];
}

_RecentFile _recentFromManagedFile(ManagedSchoolFile file) {
  return _RecentFile(
    name: file.name,
    subject: file.category,
    date: _dateLabel(file.uploadedAt),
    size: file.sizeLabel,
    type: _fileType(file.name),
    downloadUrl: file.downloadUrl,
  );
}

FileType _fileType(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
    return FileType.excel;
  }
  if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
    return FileType.powerpoint;
  }
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp')) {
    return FileType.image;
  }
  return FileType.pdf;
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
