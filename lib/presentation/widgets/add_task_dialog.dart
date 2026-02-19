import 'package:flutter/material.dart';
import '../../domain/models/task.dart';
import '../../core/utils.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? task;
  final Function(Map<String, dynamic>) onSave;

  const AddTaskDialog({
    super.key,
    this.task,
    required this.onSave,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();
  final _tagsController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedCategory = TaskCategory.work;
  DateTime? _selectedDueDate;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedPriority = widget.task!.priority;
      _selectedCategory = widget.task!.category;
      _selectedDueDate = widget.task!.dueDate;
      _selectedTags = List.from(widget.task!.tags);
      if (widget.task!.dueDate != null) {
        _dueDateController.text = AppUtils.formatDate(widget.task!.dueDate!);
      }
      if (widget.task!.estimatedMinutes != null) {
        _estimatedMinutesController.text = widget.task!.estimatedMinutes.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _estimatedMinutesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task == null ? 'Add New Task' : 'Edit Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title *',
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => AppUtils.validateRequired(value, 'Title'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Priority and Category Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<TaskPriority>(
                                value: _selectedPriority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority',
                                  prefixIcon: Icon(Icons.flag),
                                  border: OutlineInputBorder(),
                                ),
                                items: TaskPriority.values.map((priority) {
                                  return DropdownMenuItem(
                                    value: priority,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: priority.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(priority.label),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedPriority = value!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<TaskCategory>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(Icons.category),
                                  border: OutlineInputBorder(),
                                ),
                                items: TaskCategory.values.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Icon(category.icon, size: 20, color: category.color),
                                        const SizedBox(width: 8),
                                        Text(category.label),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedCategory = value!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Due Date and Estimated Time Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dueDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Due Date',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_month),
                                ),
                                readOnly: true,
                                onTap: _selectDueDate,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _estimatedMinutesController,
                                decoration: const InputDecoration(
                                  labelText: 'Est. Minutes',
                                  prefixIcon: Icon(Icons.timer),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final minutes = int.tryParse(value);
                                    if (minutes == null || minutes! < 1) {
                                      return 'Please enter a valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        TextFormField(
                          controller: _tagsController,
                          decoration: InputDecoration(
                            labelText: 'Tags (comma separated)',
                            prefixIcon: const Icon(Icons.local_offer),
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addTagFromInput,
                            ),
                          ),
                          onChanged: (value) {
                            final tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                            setState(() => _selectedTags = tags);
                          },
                        ),
                        const SizedBox(height: 8),

                        // Selected Tags
                        if (_selectedTags.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _selectedTags.map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () => _removeTag(tag),
                              deleteIcon: const Icon(Icons.close, size: 16),
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveTask,
                    child: Text(widget.task == null ? 'Add Task' : 'Update Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = AppUtils.formatDate(picked!);
      });
    }
  }

  void _addTagFromInput() {
    final text = _tagsController.text.trim();
    if (text.isNotEmpty && !_selectedTags.contains(text)) {
      setState(() {
        _selectedTags.add(text);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'priority': _selectedPriority,
        'category': _selectedCategory,
        'dueDate': _selectedDueDate,
        'tags': _selectedTags,
        'estimatedMinutes': _estimatedMinutesController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_estimatedMinutesController.text.trim()),
      };

      widget.onSave(taskData);
    }
  }
}
