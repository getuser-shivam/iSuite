import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/note.dart';

class NoteEditor extends StatefulWidget {

  const NoteEditor({
    super.key,
    this.note,
    this.onSave,
    this.onCancel,
  });
  final Note? note;
  final Function(Note) onSave;
  final VoidCallback? onCancel;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _colorController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content ?? '';
      _categoryController.text = widget.note!.category.name;
      _tagsController.text = widget.note!.tags.join(', ');
      _colorController.text = widget.note!.color;
      _dueDateController.text = widget.note!.dueDate != null 
          ? '${widget.note!.dueDate!.day}/${widget.note!.dueDate!.month}/${widget.note!.dueDate!.year}'
          : '';
      _passwordController.text = widget.note!.password ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _colorController.dispose();
    _dueDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: widget.onCancel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDueDate(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _shareNote(context),
                      child: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _duplicateNote(context),
                      child: const Text('Duplicate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _deleteNote(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveNote() {
    final note = Note(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      category: NoteCategory.values.firstWhere(
        (cat) => cat.name == _categoryController.text,
        orElse: () => NoteCategory.other,
      ),
      tags: _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
      color: _colorController.text.isEmpty ? '' : _colorController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    widget.onSave(note);
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.note?.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (date != null) {
      _dueDateController.text = '${date.day}/${date.month}/${date.year}';
      if (widget.note != null) {
        final note = widget.note!.copyWith(dueDate: date);
        widget.onSave(note);
      }
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
      'createdAt': note.createdAt.millisecondsSinceEpoch,
      'updatedAt': note.updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'isPinned': note.isPinned,
      'isFavorite': note.isFavorite,
      'isArchived': note.isArchived,
      'isEncrypted': note.isEncrypted,
    };
    
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
    
    widget.onCancel?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
