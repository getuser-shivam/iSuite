import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/note.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/note_editor.dart';
import '../widgets/note_filter_chip.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search notes',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Statistics'),
                ),
              ),
              PopupMenuItem(
                value: 'delete_all',
                child: ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Delete All'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Search bar and filters
              _buildSearchAndFilters(context),
              
              // Notes list
              Expanded(
                child: noteProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : noteProvider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading notes',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  noteProvider.error!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => noteProvider.refresh(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : noteProvider.filteredNotes.isEmpty
                            ? _buildEmptyState(context)
                            : _buildNotesList(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => noteProvider.setSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Search notes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: noteProvider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => noteProvider.setSearchQuery(''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                NoteFilterChip(
                  label: 'All',
                  isSelected: noteProvider.selectedStatus == NoteStatus.draft &&
                             noteProvider.selectedType == NoteType.text &&
                             noteProvider.selectedPriority == NotePriority.medium &&
                             noteProvider.selectedCategory == NoteCategory.personal,
                  onTap: () => noteProvider.clearFilters(),
                ),
                const SizedBox(width: 8),
                NoteFilterChip(
                  label: 'Draft',
                  isSelected: noteProvider.selectedStatus == NoteStatus.draft,
                  onTap: () => noteProvider.setStatusFilter(NoteStatus.draft),
                ),
                const SizedBox(width: 8),
                NoteFilterChip(
                  label: 'Published',
                  isSelected: noteProvider.selectedStatus == NoteStatus.published,
                  onTap: () => noteProvider.setStatusFilter(NoteStatus.published),
                ),
                const SizedBox(width: 8),
                NoteFilterChip(
                  label: 'Favorites',
                  isSelected: noteProvider.showFavorites,
                  onTap: () => noteProvider.toggleFavorites(),
                ),
                const SizedBox(width: 8),
                NoteFilterChip(
                  label: 'Pinned',
                  isSelected: noteProvider.showPinned,
                  onTap: () => noteProvider.togglePinned(),
                ),
                const SizedBox(width: 8),
                NoteFilterChip(
                  label: 'Archived',
                  isSelected: noteProvider.showArchived,
                  onTap: () => noteProvider.toggleArchived(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<NoteType>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter by type',
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: NoteType.text,
                      child: ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: const Text('Text'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteType.checklist,
                      child: ListTile(
                        leading: const Icon(Icons.checklist),
                        title: const Text('Checklist'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteType.markdown,
                      child: ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Markdown'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteType.code,
                      child: ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Code'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteType.drawing,
                      child: ListTile(
                        leading: const Icon(Icons.brush),
                        title: const Text('Drawing'),
                      ),
                    ),
                  ],
                  onSelected: (type) => noteProvider.setTypeFilter(type),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<NotePriority>(
                  icon: const Icon(Icons.flag),
                  tooltip: 'Filter by priority',
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: NotePriority.low,
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: const Text('Low'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NotePriority.medium,
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: const Text('Medium'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NotePriority.high,
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: const Text('High'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NotePriority.urgent,
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: const Text('Urgent'),
                      ),
                    ),
                  ],
                  onSelected: (priority) => noteProvider.setPriorityFilter(priority),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<NoteCategory>(
                  icon: const Icon(Icons.category),
                  tooltip: 'Filter by category',
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: NoteCategory.personal,
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Personal'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.work,
                      child: ListTile(
                        leading: const Icon(Icons.work),
                        title: const Text('Work'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.study,
                      child: ListTile(
                        leading: const Icon(Icons.school),
                        title: const Text('Study'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.ideas,
                      child: ListTile(
                        leading: const(Icons.lightbulb),
                        title: const Text('Ideas'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.meeting,
                      child: ListTile(
                        leading: const Icon(Icons.groups),
                        title: const Text('Meeting'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.project,
                      child: ListTile(
                        leading: const Icon(Icons.folder),
                        title: const Text('Project'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.shopping,
                      child: ListTile(
                        leading: const Icon(Icons.shopping_cart),
                        title: const Text('Shopping'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.health,
                      child: ListTile(
                        leading: const Icon(Icons.favorite),
                        title: const Text('Health'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.finance,
                      child: ListTile(
                        leading: const Icon(Icons.account_balance),
                        title: const Text('Finance'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.travel,
                      child: ListTile(
                        leading: const Icon(Icons.flight),
                        title: const Text('Travel'),
                      ),
                    ),
                    PopupMenuItem(
                      value: NoteCategory.other,
                      child: ListTile(
                        leading: const Icon(Icons.more_horiz),
                        title: const Text('Other'),
                      ),
                    ),
                  ],
                  onSelected: (category) => noteProvider.setCategoryFilter(category),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first note to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    
    return noteProvider.isGridView
        ? _buildGridView(context)
        : _buildListView(context);
  }

  Widget _buildGridView(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: noteProvider.filteredNotes.length,
      itemBuilder: (context, index) {
        final note = noteProvider.filteredNotes[index];
        return NoteCard(
          note: note,
          onTap: () => _showNoteDetails(context, note),
          onEdit: () => _editNote(context, note),
          onDelete: () => _deleteNote(context, note),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: noteProvider.filteredNotes.length,
      itemBuilder: (context, index) {
        final note = noteProvider.filteredNotes[index];
        return NoteCard(
          note: note,
          onTap: () => _showNoteDetails(context, note),
          onEdit: () => _editNote(context, note),
          onDelete: () => _deleteNote(context, note),
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => NoteEditor(
        onSave: (noteData) async {
          final noteProvider = Provider.of<NoteProvider>(context, listen: false);
          await noteProvider.createNote(
            title: noteData['title'],
            content: noteData['content'],
            type: noteData['type'],
            priority: noteData['priority'],
            category: noteData['category'],
            tags: noteData['tags'],
            dueDate: noteData['dueDate'],
            isPinned: noteData['isPinned'],
            isFavorite: noteData['isFavorite'],
            color: noteData['color'],
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: 'Note created successfully',
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _editNote(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => NoteEditor(
        note: note,
        onSave: (noteData) async {
          final noteProvider = Provider.of<NoteProvider>(context, listen: false);
          final updatedNote = note.copyWith(
            title: noteData['title'],
            content: noteData['content'],
            type: noteData['type'],
            priority: noteData['priority'],
            category: noteData['category'],
            tags: noteData['tags'],
            dueDate: noteData['dueDate'],
            isPinned: noteData['isPinned'],
            isFavorite: noteData['isFavorite'],
            color: noteData['color'],
          );
          
          await noteProvider.updateNote(updatedNote);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: 'Note updated successfully',
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteNote(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final noteProvider = Provider.of<NoteProvider>(context, listen: false);
              await noteProvider.deleteNote(note.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: 'Note deleted successfully',
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteDetails(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    note.title,
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
              const SizedBox(height: 16),
              
              // Note content
              if (note.content != null && note.content!.isNotEmpty) ...[
                Text(
                  'Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.content!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              
              // Metadata
              _buildDetailRow('Type', note.typeLabel),
              _buildDetailRow('Status', note.statusLabel),
              _buildDetailRow('Priority', note.priorityLabel),
              _buildDetailRow('Category', note.categoryLabel),
              _buildDetailRow('Created', note.formattedDate),
              if (note.dueDate != null) ...[
                _buildDetailRow('Due Date', note.formattedDate),
              ],
              if (note.tags.isNotEmpty) ...[
                _buildDetailRow('Tags', note.tags.join(', ')),
              ],
              if (note.attachments.isNotEmpty) ...[
                _buildDetailRow('Attachments', '${note.attachments.length} files'),
              ],
              if (note.wordCount != null) ...[
                _buildDetailRow('Word Count', '${note.wordCount} words'),
              ],
              if (note.readingTime != null) ...[
                _buildDetailRow('Reading Time', '${note.readingTime} min'),
              ],
              
              const SizedBox(height: 20),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editNote(context, note);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: note.priorityColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context);
    final TextEditingController controller = TextEditingController(text: noteProvider.searchQuery);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Notes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            noteProvider.setSearchQuery(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              noteProvider.setSearchQuery(controller.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final noteProvider = Provider.of<NoteProvider>(context);
    
    switch (action) {
      case 'statistics':
        _showStatisticsDialog(context);
        break;
      case 'delete_all':
        _showDeleteAllConfirmation(context);
        break;
    }
  }

  void _showStatisticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note Statistics'),
        content: FutureBuilder<Map<String, int>>(
          future: noteProvider.getStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final stats = snapshot.data ?? {};
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatItem('Total Notes', stats['total'] ?? 0),
                _buildStatItem('Draft Notes', stats['draft'] ?? 0),
                _buildStatItem('Published Notes', stats['published'] ?? 0),
                _buildStatItem('Archived Notes', stats['archived'] ?? 0),
                _buildStatItem('Favorite Notes', stats['favorite'] ?? 0),
                _buildStatItem('Pinned Notes', stats['pinned'] ?? 0),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notes'),
        content: const Text('Are you sure you want to delete all notes? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final noteProvider = Provider.of<NoteProvider>(context, listen: false);
              await noteProvider.deleteAllNotes();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: 'All notes deleted successfully',
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete All'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
