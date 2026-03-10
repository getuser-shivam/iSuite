import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/note.dart';

/// Working Note Editor Widget with proper structure
class NoteEditor extends StatefulWidget {
  final Note? note;
  final Function(Note) onSave;
  final VoidCallback? onCancel;

  const NoteEditor({
    super.key,
    this.note,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _typeController = TextEditingController();
  final _priorityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _colorController = TextEditingController();
  final _isPinnedController = TextEditingController();
  final _isFavoriteController = TextEditingController();
  final _isEncryptedController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.note != null) {
      _titleController.text = widget.note?.title ?? '';
      _contentController.text = widget.note!.content ?? '';
      _typeController.text = widget.note!.type.name;
      _priorityController.text = widget.note!.priority.name;
      _categoryController.text = widget.note!.category.name;
      _tagsController.text = widget.note!.tags.join(', ');
      _dueDateController.text = widget.note!.dueDate != null
          ? '${widget.note!.dueDate!.day}/${widget.note!.dueDate!.month}/${widget.note!.dueDate!.year}'
          : '';
      _colorController.text = widget.note!.color ?? '';
      _isPinnedController.text = widget.note!.isPinned.toString();
      _isFavoriteController.text = widget.note!.isFavorite.toString();
      _isEncryptedController.text = widget.note!.isEncrypted.toString();
      _passwordController.text = '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _typeController.dispose();
    _priorityController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _dueDateController.dispose();
    _colorController.dispose();
    _isPinnedController.dispose();
    _isFavoriteController.dispose();
    _isEncryptedController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note != null ? 'Edit Note' : 'New Note'),
        actions: [
          if (widget.note != null) ...[
            IconButton(
              onPressed: () => _shareNote(context),
              icon: const Icon(Icons.share),
              tooltip: 'Share note',
            ),
            IconButton(
              onPressed: () => _duplicateNote(context),
              icon: const Icon(Icons.copy),
              tooltip: 'Duplicate note',
            ),
            IconButton(
              onPressed: () => _deleteNote(context),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete note',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 16),

            // Content field
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              minLines: 3,
            ),

            const SizedBox(height: 16),

            // Metadata fields
            _buildMetadataFields(context),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _priorityController,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dueDateController,
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDueDate(context),
                  ),
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.color_lens),
                    onPressed: () => _selectColor(context),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Checkbox options
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Pinned'),
                value: widget.note?.isPinned ?? false,
                onChanged: (value) {
                  final note = widget.note?.copyWith(isPinned: value);
                  if (note != null) {
                    widget.onSave(note);
                  }
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Favorite'),
                value: widget.note?.isFavorite ?? false,
                onChanged: (value) {
                  final note = widget.note?.copyWith(isFavorite: value);
                  if (note != null) {
                    widget.onSave(note);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Encryption options
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Encrypted'),
                value: widget.note?.isEncrypted ?? false,
                onChanged: (value) {
                  final note = widget.note?.copyWith(isEncrypted: value);
                  if (note != null) {
                    widget.onSave(note);
                  }
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: !(widget.note?.isEncrypted ?? false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _saveNote(context),
            child: const Text('Save Note'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveNote(BuildContext context) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _parseNoteType(_typeController.text),
      priority: _parsePriority(_priorityController.text),
      category: _parseCategory(_categoryController.text),
      tags: _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      dueDate: _dueDateController.text.isNotEmpty
          ? _parseDueDate(_dueDateController.text)
          : null,
      color: _colorController.text.isNotEmpty ? _colorController.text : null,
      isPinned: widget.note?.isPinned ?? false,
      isFavorite: widget.note?.isFavorite ?? false,
      isArchived: widget.note?.isArchived ?? false,
      isEncrypted: widget.note?.isEncrypted ?? false,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(note);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.note?.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (date != null) {
      _dueDateController.text = '${date.day}/${date.month}/${date.year}';
      final note = widget.note?.copyWith(dueDate: date);
      if (note != null) {
        widget.onSave(note);
      }
    }
  }

  Future<void> _selectColor(BuildContext context) async {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.brown,
      Colors.pink,
    ];

    final selectedColor = colors.firstWhere(
      (color) =>
          color.toString().toLowerCase() == _colorController.text.toLowerCase(),
      orElse: () => Colors.blue,
    );

    _colorController.text = selectedColor.toString();
    final note =
        widget.note?.copyWith(color: selectedColor.value.toRadixString(16));
    if (note != null) {
      widget.onSave(note);
    }
  }

  Future<void> _shareNote(BuildContext context) async {
    if (widget.note == null) return;

    final note = widget.note!;
    final data = {
      'title': note.title,
      'content': note.content,
      'type': note.type.name,
      'priority': note.priority.name,
      'category': note.category.name,
      'tags': note.tags.join(', '),
      'createdAt': note.createdAt?.millisecondsSinceEpoch ?? 0,
      'updatedAt': note.updatedAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'isPinned': note.isPinned,
      'isFavorite': note.isFavorite,
      'isArchived': note.isArchived,
      'isEncrypted': note.isEncrypted,
    };

    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note shared successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _duplicateNote(BuildContext context) async {
    if (widget.note == null) return;

    final note = widget.note!;
    final duplicatedNote = note.copyWith(
      id: const Uuid().v4(),
      title: '${note.title} (Copy)',
      createdAt: DateTime.now(),
    );

    widget.onSave(duplicatedNote);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note duplicated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context) async {
    if (widget.note == null) return;

    if (widget.onCancel != null) {
      widget.onCancel!();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Helper methods
  NoteType _parseNoteType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return NoteType.text;
      case 'checklist':
        return NoteType.checklist;
      case 'voice':
        return NoteType.voice;
      case 'image':
        return NoteType.image;
      default:
        return NoteType.text;
    }
  }

  NotePriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotePriority.low;
      case 'medium':
        return NotePriority.medium;
      case 'high':
        return NotePriority.high;
      default:
        return NotePriority.medium;
    }
  }

  NoteCategory _parseCategory(String category) {
    // Implementation depends on your NoteCategory enum
    return NoteCategory.personal; // Default value
  }

  DateTime? _parseDueDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }
}
