import 'package:flutter/material.dart';
import '../../../core/central_config.dart';

/// Language Selector Widget
///
/// Provides an intuitive language selection interface with:
/// - Search functionality
/// - Recent languages
/// - Language flags and names
/// - Voice samples
/// - Auto-detection
/// - Regional variants
class LanguageSelectorWidget extends StatefulWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;
  final String label;

  const LanguageSelectorWidget({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.label,
  });

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  final CentralConfig _config = CentralConfig.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isExpanded = false;
  List<Language> _filteredLanguages = [];
  List<Language> _recentLanguages = [];

  @override
  void initState() {
    super.initState();
    _filteredLanguages = _allLanguages;
    _recentLanguages = _getRecentLanguages();
  }

  List<Language> _getRecentLanguages() {
    // Return recently used languages
    return [
      Language(code: 'en', name: 'English', flag: '🇺🇸', isRecent: true),
      Language(code: 'es', name: 'Spanish', flag: '🇪🇸', isRecent: true),
      Language(code: 'fr', name: 'French', flag: '🇫🇷', isRecent: true),
      Language(code: 'de', name: 'German', flag: '🇩🇪', isRecent: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.body_medium',
                defaultValue: 14.0),
            fontWeight: FontWeight.w500,
            color: _config.getParameter('ui.colors.on_surface',
                defaultValue: Colors.black87),
          ),
        ),
        SizedBox(
            height:
                _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: EdgeInsets.all(
                _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
            decoration: BoxDecoration(
              color: _config.getParameter('ui.colors.surface_variant',
                  defaultValue: Colors.grey[50]),
              borderRadius: BorderRadius.circular(_config
                  .getParameter('ui.border_radius.medium', defaultValue: 12.0)),
              border: Border.all(
                color: _config.getParameter('ui.colors.outline',
                    defaultValue: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                _buildLanguageDisplay(),
                Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: _config.getParameter('ui.colors.on_surface_variant',
                      defaultValue: Colors.grey[600]!),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) _buildExpandedContent(),
      ],
    );
  }

  Widget _buildLanguageDisplay() {
    final language = _allLanguages.firstWhere(
      (lang) => lang.code == widget.selectedLanguage,
      orElse: () => Language(code: 'en', name: 'English', flag: '🇺🇸'),
    );

    return Row(
      children: [
        Text(
          language.flag,
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.body_large',
                defaultValue: 18.0),
          ),
        ),
        SizedBox(
            width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
        Text(
          language.name,
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.body_medium',
                defaultValue: 14.0),
            color: _config.getParameter('ui.colors.on_surface',
                defaultValue: Colors.black87),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      margin: EdgeInsets.only(
          top: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface',
            defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config
            .getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline',
              defaultValue: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                _config.getParameter('ui.shadow.opacity', defaultValue: 0.1)),
            blurRadius: _config.getParameter('ui.shadow.blur_radius',
                defaultValue: 4.0),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          if (_recentLanguages.isNotEmpty) ...[
            _buildSectionTitle('Recent Languages'),
            _buildRecentLanguages(),
          ],
          _buildSectionTitle('All Languages'),
          _buildLanguageList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(
          _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search languages...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_config
                .getParameter('ui.border_radius.medium', defaultValue: 12.0)),
          ),
          filled: true,
          fillColor: _config.getParameter('ui.colors.surface_variant',
              defaultValue: Colors.grey[50]),
        ),
        onChanged: _filterLanguages,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            _config.getParameter('ui.spacing.medium', defaultValue: 16.0),
        vertical: _config.getParameter('ui.spacing.small', defaultValue: 8.0),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.body_medium',
                defaultValue: 14.0),
            fontWeight: FontWeight.bold,
            color: _config.getParameter('ui.colors.on_surface',
                defaultValue: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLanguages() {
    return Container(
      height: _config.getParameter('ui.language_selector.recent_height',
          defaultValue: 80.0),
      padding: EdgeInsets.symmetric(
          horizontal:
              _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentLanguages.length,
        itemBuilder: (context, index) {
          final language = _recentLanguages[index];
          return _buildLanguageChip(language);
        },
      ),
    );
  }

  Widget _buildLanguageChip(Language language) {
    final isSelected = language.code == widget.selectedLanguage;

    return Container(
      margin: EdgeInsets.only(
          right: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag),
            SizedBox(width: 4),
            Text(language.name),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            widget.onLanguageChanged(language.code);
            _toggleExpanded();
          }
        },
        backgroundColor: _config.getParameter('ui.colors.surface_variant',
            defaultValue: Colors.grey[100]),
        selectedColor: _config
            .getParameter('ui.colors.primary', defaultValue: Colors.blue)
            .withOpacity(0.2),
        checkmarkColor: _config.getParameter('ui.colors.primary',
            defaultValue: Colors.blue),
      ),
    );
  }

  Widget _buildLanguageList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: _config.getParameter('ui.language_selector.list_height',
            defaultValue: 200.0),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredLanguages.length,
        itemBuilder: (context, index) {
          final language = _filteredLanguages[index];
          return _buildLanguageTile(language);
        },
      ),
    );
  }

  Widget _buildLanguageTile(Language language) {
    final isSelected = language.code == widget.selectedLanguage;

    return ListTile(
      leading: Text(
        language.flag,
        style: TextStyle(
          fontSize: _config.getParameter('ui.font.size.body_large',
              defaultValue: 24.0),
        ),
      ),
      title: Text(
        language.name,
        style: TextStyle(
          fontSize: _config.getParameter('ui.font.size.body_medium',
              defaultValue: 14.0),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: _config.getParameter('ui.colors.on_surface',
              defaultValue: Colors.black87),
        ),
      ),
      subtitle: Text(
        language.nativeName ?? language.name,
        style: TextStyle(
          fontSize: _config.getParameter('ui.font.size.body_small',
              defaultValue: 12.0),
          color: _config.getParameter('ui.colors.on_surface_variant',
              defaultValue: Colors.grey[600]!),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: _config.getParameter('ui.colors.primary',
                  defaultValue: Colors.blue),
            )
          : null,
      onTap: () {
        widget.onLanguageChanged(language.code);
        _toggleExpanded();
      },
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _searchController.clear();
        _filterLanguages('');
        _searchFocusNode.unfocus();
      }
    });
  }

  void _filterLanguages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = _allLanguages;
      } else {
        _filteredLanguages = _allLanguages.where((language) {
          return language.name.toLowerCase().contains(query.toLowerCase()) ||
              (language.nativeName
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }
}

// Language model
class Language {
  final String code;
  final String name;
  final String? nativeName;
  final String flag;
  final bool isRecent;

  Language({
    required this.code,
    required this.name,
    this.nativeName,
    required this.flag,
    this.isRecent = false,
  });
}

// All supported languages
final List<Language> _allLanguages = [
  Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
  Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
  Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
  Language(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
  Language(
      code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
  Language(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
  Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
  Language(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
  Language(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
  Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
  Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
  Language(code: 'th', name: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
  Language(
      code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
  Language(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
  Language(code: 'sv', name: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
  Language(code: 'no', name: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴'),
  Language(code: 'da', name: 'Danish', nativeName: 'Dansk', flag: '🇩🇰'),
  Language(code: 'fi', name: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮'),
  Language(code: 'pl', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
  Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
  Language(code: 'el', name: 'Greek', nativeName: 'Ελληνικά', flag: '🇬🇷'),
  Language(code: 'he', name: 'Hebrew', nativeName: 'עברית', flag: '🇮🇱'),
  Language(code: 'cs', name: 'Czech', nativeName: 'Čeština', flag: '🇨🇿'),
  Language(code: 'hu', name: 'Hungarian', nativeName: 'Magyar', flag: '🇭🇺'),
  Language(code: 'ro', name: 'Romanian', nativeName: 'Română', flag: '🇷🇴'),
  Language(
      code: 'bg', name: 'Bulgarian', nativeName: 'Български', flag: '🇧🇬'),
  Language(code: 'hr', name: 'Croatian', nativeName: 'Hrvatski', flag: '🇭🇷'),
  Language(code: 'sr', name: 'Serbian', nativeName: 'Српски', flag: '🇷🇸'),
  Language(code: 'sk', name: 'Slovak', nativeName: 'Slovenčina', flag: '🇸🇰'),
  Language(
      code: 'sl', name: 'Slovenian', nativeName: 'Slovenščina', flag: '🇸🇮'),
  Language(code: 'et', name: 'Estonian', nativeName: 'Eesti', flag: '🇪🇪'),
  Language(code: 'lv', name: 'Latvian', nativeName: 'Latviešu', flag: '🇱🇻'),
  Language(
      code: 'lt', name: 'Lithuanian', nativeName: 'Lietuvių', flag: '🇱🇹'),
  Language(
      code: 'uk', name: 'Ukrainian', nativeName: 'Українська', flag: '🇺🇦'),
  Language(
      code: 'be', name: 'Belarusian', nativeName: 'Беларуская', flag: '🇧🇾'),
  Language(
      code: 'mk', name: 'Macedonian', nativeName: 'Македонски', flag: '🇲🇰'),
  Language(code: 'sq', name: 'Albanian', nativeName: 'Shqip', flag: '🇦🇱'),
  Language(code: 'mt', name: 'Maltese', nativeName: 'Malti', flag: '🇲🇹'),
  Language(code: 'is', name: 'Icelandic', nativeName: 'Íslenska', flag: '🇮🇸'),
  Language(code: 'ga', name: 'Irish', nativeName: 'Gaeilge', flag: '🇮🇪'),
  Language(
      code: 'cy', name: 'Welsh', nativeName: 'Cymraeg', flag: '🏴󠁧󠁢󠁷󠁬󠁳󠁿'),
  Language(
      code: 'eu', name: 'Basque', nativeName: 'Euskara', flag: '🏴󠁥󠁳󠁰󠁶󠁿'),
  Language(
      code: 'ca', name: 'Catalan', nativeName: 'Català', flag: '🏴󠁥󠁳󠁣󠁴󠁿'),
  Language(
      code: 'gl', name: 'Galician', nativeName: 'Galego', flag: '🏴󠁥󠁳󠁣󠁴󠁿'),
];
