import 'package:flutter/material.dart';
import '../../domain/models/note.dart';

class NoteEditor extends StatefulWidget {
  final Note? note;
  final Function(Note) onSave;
  final VoidCallback? onCancel;

  const NoteEditor({
    super.key,
    this.note,
    this.onSave,
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
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrikethrough = false;
  bool _isCode = false;
  bool _isQuote = false;
  bool _isList = false;
  bool _isOrderedList = false;
  bool _isCheckboxList = false;
  bool _isCodeBlock = false;
  bool _isLink = false;
  bool _isImage = false;
  bool _isTable = false;
  bool _isHorizontalRule = false;
  bool _isCenterAlignment = false;
  bool _isJustifyAlignment = false;
  bool _isLeftAlignment = false;
  bool _isRightAlignment = false;
  bool _isFullWidth = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content ?? '';
      _typeController.text = widget.note!.type.name;
      _priorityController.text = widget.note!.priority.value.toString();
      _categoryController.text = widget.note!.category.name;
      _tagsController.text = widget.note!.tags.join(', ');
      _dueDateController.text = widget.note!.dueDate != null 
          ? '${widget.note!.dueDate!.day}/${widget.note!.dueDate!.month}/${widget.note!.dueDate!.year}'
          : '';
      _colorController.text = widget.note!.color ?? '';
      _isPinnedController.text = widget.note!.isPinned.toString();
      _isFavoriteController.text = widget.note!.isFavorite.toString();
      _isEncryptedController.text = widget.note!.isEncrypted.toString();
      _passwordController.text = widget.note!.password ?? '';
    }
    
    _focusNode.requestFocus();
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
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'bold',
                  child: ListTile(
                    leading: const Icon(Icons.format_bold),
                    title: const Text('Bold'),
                  ),
                ),
                PopupMenuItem(
                  value: 'italic',
                  child: ListTile(
                    leading: const Icon(Icons.format_italic),
                    title: const Text('Italic'),
                  ),
                ),
                PopupMenuItem(
                  value: 'underline',
                  child: ListTile(
                    leading: const Icon(Icons.format_underlined),
                    title: const Text('Underline'),
                  ),
                ),
                PopupMenuItem(
                  value: 'strikethrough',
                  child: ListTile(
                    leading: const Icon(Icons.format_strikethrough),
                    title: const Text('Strikethrough'),
                  ),
                ),
                PopupMenuItem(
                  value: 'code',
                  child: ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Code'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Title field
          TextField(
            controller: _titleController,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Formatting toolbar
          _buildFormattingToolbar(context),
          const SizedBox(height: 8),
          
          // Content field
          Expanded(
            child: TextField(
              controller: _contentController,
              focusNode: _focusNode,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Start typing your note...',
                border: InputBorder.none,
                filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              ),
              maxLines: null,
              expands: true,
            ),
          ),
          const SizedBox(height: 16),
          
          // Metadata fields
          _buildMetadataFields(context),
          const SizedBox(height: 16),
          
          // Content editor
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _contentController,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Note content',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFormatButton(
              context,
              Icons.format_bold,
              _isBold,
              () => _toggleFormat('bold'),
            ),
            _buildFormatButton(
              context,
              Icons.format_italic,
              _isItalic,
              () => _toggleFormat('italic'),
            ),
            _buildFormatButton(
              context,
              Icons.format_underlined,
              _isUnderline,
              () => _toggleFormat('underline'),
            ),
            _buildFormatButton(
              context,
              Icons.format_strikethrough,
              _isStrikethrough,
              () => _toggleFormat('strikethrough'),
            ),
            _buildFormatButton(
              context,
              Icons.code,
              _isCode,
              () => _toggleFormat('code'),
            ),
            _buildFormatButton(
              context,
              Icons.format_list_bulleted,
              _isList,
              () => _toggleFormat('list'),
            ),
            _buildFormatButton(
              context,
              Icons.format_list_numbered,
              _isOrderedList,
              () => _toggleFormat('orderedList'),
            ),
            _buildFormatButton(
              context,
              Icons.format_quote,
              _isQuote,
              () => _toggleFormat('quote'),
            ),
            _buildFormatButton(
              context,
              Icons.format_align_left,
              _isLeftAlignment,
              () => _toggleAlignment('left'),
            ),
            _buildFormatButton(
              context,
              Icons.format_align_center,
              _isCenterAlignment,
              () => _toggleAlignment('center'),
            ),
            _buildFormatButton(
              context,
              Icons.format_align_right,
              _isRightAlignment,
              () => _toggleAlignment('right'),
            ),
            _buildFormatButton(
              context,
              Icons.format_align_justify,
              _isJustifyAlignment,
              () => _toggleAlignment('justify'),
            ),
            _buildFormatButton(
              context,
              Icons.format_clear,
              () => _clearFormatting(),
            ),
          ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(
    BuildContext context,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Icon(
          icon: icon,
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }

  void _toggleFormat(String format) {
    switch (format) {
      case 'bold':
        _isBold = !_isBold;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'italic':
        _isBold = false;
        _isItalic = !_isItalic;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'underline':
        _isBold = false;
        _isItalic = false;
        _isUnderline = !_isUnderline;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'strikethrough':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = !_isStrikethrough;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'code':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = !_isCode;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'list':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = !_isList;
        _isOrderedList = !_isOrderedList;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'orderedList':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = !_isList;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'quote':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'alignLeft':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = !_isLeftAlignment;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'alignCenter':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = !_isCenterAlignment;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'alignRight':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'alignJustify':
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isStrikethrough = false;
        _isCode = false;
        _isList = false;
        _isOrderedList = false;
        _isQuote = false;
        _isLeftAlignment = false;
        _isCenterAlignment = !_isCenterAlignment;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'clear':
        _clearFormatting();
        break;
    }
  }

  void _clearFormatting() {
    _isBold = false;
    _isItalic = false;
    _isUnderline = false;
    _isStrikethrough = false;
    _isCode = false;
    _isList = false;
    _isOrderedList = false;
    _isQuote = false;
    _isLeftAlignment = false;
    _isCenterAlignment = false;
    _isRightAlignment = false;
    _isJustifyAlignment = false;
  }

  void _toggleAlignment(String alignment) {
    switch (alignment) {
      case 'alignLeft':
        _isLeftAlignment = !_isLeftAlignment;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = false;
        break;
      case 'alignCenter':
        _isLeftAlignment = false;
        _isCenterAlignment = !_isCenterAlignment;
        _isRightAlignment = false;
        _isJustifyAlignment = !_isJustifyAlignment;
        break;
      case 'alignRight':
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = !_isRightAlignment;
        _isJustifyAlignment = false;
        break;
      case 'alignJustify':
        _isLeftAlignment = false;
        _isCenterAlignment = false;
        _isRightAlignment = false;
        _isJustifyAlignment = !_isJustifyAlignment;
        break;
    }
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _priorityController,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _dueDateController,
                decoration: const InputDecoration(
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
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.color_lens),
                    onPressed: () => _selectColor(context),
                  ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 8),
        
        // Checkbox options
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Pinned'),
                value: widget.note?.isPinned ?? false,
                onChanged: (value) {
                  final note = widget.note?.copyWith(isPinned: value);
                  widget.onSave(note);
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Favorite'),
                value: widget.note?.isFavorite ?? false,
                onChanged: (value) {
                  final note = widget.note?.copyWith(isFavorite: value);
                  widget.onSave(note);
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Archived'),
                value: widget.note?.isArchived ?? false,
                onChanged: (value) {
                  final note = widget.note?.copyWith(isArchived: value);
                  widget.onSave(note);
                },
              ),
            ),
            const SizedBox(width: 8),
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
                  widget.onSave(note);
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  obscureText: !widget.note?.isEncrypted,
                  suffixIcon: IconButton(
                    icon: widget.note?.isEncrypted ?? false
                      ? Icons.visibility_off
                      : Icons.visibility,
                    onPressed: () {
                      final note = widget.note?.copyWith(isEncrypted: !widget.note!.isEncrypted);
                      widget.onSave(note);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _selectDueDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.note?.dueDate,
      firstDate: DateTime.now(),
    );
    
    if (date != null) {
      _dueDateController.text = '${date.day}/${date.month}/${date.year}';
      widget.onSave(note?.copyWith(dueDate: date));
    }
  }

  void _selectColor(BuildContext context) async {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.grey,
      Colors.brown,
      Colors.pink,
    ];
    
    final selectedColor = colors.firstWhere(
      (color) => color.toString().toLowerCase() == _colorController.text.toLowerCase(),
    );
    
    if (selectedColor != null) {
      _colorController.text = selectedColor.toString();
      widget.onSave(note?.copyWith(color: selectedColor));
    }
  }

  void _shareNote(BuildContext context) async {
    final note = widget.note!;
    final data = {
      'title': note.title,
      'content': note.content,
      'type': note.type.name,
      'priority': note.priority.value,
      'category': note.category.name,
      'tags': note.tags.join(', '),
      'createdAt': note.createdAt.millisecondsSinceEpoch,
      'updatedAt': note.updatedAt.millisecondsSinceEpoch,
      'isPinned': note.isPinned,
      'isFavorite': note.isFavorite,
      'isArchived': note.isArchived,
      'isEncrypted': note.isEncrypted,
    };
    
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Note shared successfully',
        backgroundColor: Colors.green,
      ),
    );
  }

  void _duplicateNote(BuildContext context) async {
    final note = widget.note!;
    final duplicatedNote = note.copyWith(
      id: AppUtils.generateRandomId(),
      title: '${note.title} (Copy)',
      createdAt: DateTime.now(),
    );
    
    await widget.onSave(duplicatedNote);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Note duplicated successfully',
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteNote(BuildContext context) async {
    await widget.onCancel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Note deleted',
        backgroundColor: Colors.red,
      ),
    );
  }
}
