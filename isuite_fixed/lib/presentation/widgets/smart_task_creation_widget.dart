import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/ui_helper.dart';
import '../providers/task_suggestion_provider.dart';

/// AI-powered task creation widget with smart suggestions
class SmartTaskCreationWidget extends StatefulWidget {
  const SmartTaskCreationWidget({super.key});

  @override
  State<SmartTaskCreationWidget> createState() =>
      _SmartTaskCreationWidgetState();
}

class _SmartTaskCreationWidgetState extends State<SmartTaskCreationWidget> {
  final _taskController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _taskController.text.isNotEmpty) {
      _generateSuggestions();
    } else {
      _hideSuggestions();
    }
  }

  Future<void> _generateSuggestions() async {
    final suggestionProvider =
        Provider.of<TaskSuggestionProvider>(context, listen: false);
    await suggestionProvider.generateSuggestions(_taskController.text);
    setState(() {
      _showSuggestions = true;
    });
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
  }

  void _selectSuggestion(String suggestion) {
    _taskController.text = suggestion;
    _focusNode.unfocus();
    _hideSuggestions();
  }

  void _createTask() {
    if (_taskController.text.trim().isEmpty) {
      UIHelper.showErrorSnackBar(
        // ignore: use_build_context_synchronously
        null,
        'Please enter a task description',
      );
      return;
    }

    // Create task logic here
    UIHelper.showSuccessSnackBar(
      // ignore: use_build_context_synchronously
      null,
      'Task created successfully',
    );

    _taskController.clear();
    _focusNode.unfocus();
    _hideSuggestions();
  }

  @override
  Widget build(BuildContext context) => Consumer<TaskSuggestionProvider>(
        builder: (context, suggestionProvider, child) => Card(
          margin: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Smart Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppConstants.defaultSpacing),
                TextField(
                  controller: _taskController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Enter task description...',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.inputRadius),
                    ),
                    contentPadding:
                        const EdgeInsets.all(AppConstants.defaultPadding),
                    suffixIcon: suggestionProvider.isLoading
                        ? const SizedBox(
                            width: AppConstants.loadingIndicatorSize,
                            height: AppConstants.loadingIndicatorSize,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.auto_awesome),
                            onPressed: _generateSuggestions,
                            tooltip: 'Generate AI suggestions',
                          ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultSpacing),
                if (_showSuggestions &&
                    suggestionProvider.suggestions.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey
                          .withValues(alpha: AppConstants.overlayOpacity),
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestionProvider.suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion =
                            suggestionProvider.suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.lightbulb_outline),
                          title: Text(suggestion),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: AppConstants.defaultSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _taskController.clear();
                        _hideSuggestions();
                      },
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: AppConstants.defaultSpacing),
                    ElevatedButton(
                      onPressed: _createTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.largePadding,
                          vertical: AppConstants.smallPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.buttonRadius),
                        ),
                      ),
                      child: const Text('Create Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
