  /// Apply enhanced UI configuration with central parameterization
  Future<void> _applyEnhancedUIConfiguration() async {
    try {
      // Apply UI theme configuration
      await _config.setParameter('ui.theme.brightness', getParameter('ui.theme.brightness', defaultValue: 'system'));
      await _config.setParameter('ui.theme.text_scale_factor', getParameter('ui.theme.text_scale_factor', defaultValue: 1.0));

      // Apply UI colors - all parameterized
      await _config.setParameter('ui.primary_color', getParameter('ui.primary_color', defaultValue: 0xFF2196F3));
      await _config.setParameter('ui.secondary_color', getParameter('ui.secondary_color', defaultValue: 0xFF03DAC6));
      await _config.setParameter('ui.accent_color', getParameter('ui.accent_color', defaultValue: 0xFFFF4081));
      await _config.setParameter('ui.error_color', getParameter('ui.error_color', defaultValue: 0xFFB00020));
      await _config.setParameter('ui.warning_color', getParameter('ui.warning_color', defaultValue: 0xFFFF9800));
      await _config.setParameter('ui.success_color', getParameter('ui.success_color', defaultValue: 0xFF4CAF50));
      await _config.setParameter('ui.info_color', getParameter('ui.info_color', defaultValue: 0xFF2196F3));

      // Apply surface colors - all parameterized
      await _config.setParameter('ui.surface_color', getParameter('ui.surface_color', defaultValue: 0xFFFFFFFF));
      await _config.setParameter('ui.background_color', getParameter('ui.background_color', defaultValue: 0xFFFAFAFA));
      await _config.setParameter('ui.card_color', getParameter('ui.card_color', defaultValue: 0xFFFFFFFF));
      await _config.setParameter('ui.dialog_color', getParameter('ui.dialog_color', defaultValue: 0xFFFFFFFF));

      // Apply text colors - all parameterized
      await _config.setParameter('ui.on_primary', getParameter('ui.on_primary', defaultValue: 0xFFFFFFFF));
      await _config.setParameter('ui.on_secondary', getParameter('ui.on_secondary', defaultValue: 0xFF000000));
      await _config.setParameter('ui.on_surface', getParameter('ui.on_surface', defaultValue: 0xFF000000));
      await _config.setParameter('ui.on_background', getParameter('ui.on_background', defaultValue: 0xFF000000));
      await _config.setParameter('ui.on_error', getParameter('ui.on_error', defaultValue: 0xFFFFFFFF));

      // Apply font sizes - all parameterized
      await _config.setParameter('ui.font_size_xs', getParameter('ui.font_size_xs', defaultValue: 12.0));
      await _config.setParameter('ui.font_size_sm', getParameter('ui.font_size_sm', defaultValue: 14.0));
      await _config.setParameter('ui.font_size_md', getParameter('ui.font_size_md', defaultValue: 16.0));
      await _config.setParameter('ui.font_size_lg', getParameter('ui.font_size_lg', defaultValue: 18.0));
      await _config.setParameter('ui.font_size_xl', getParameter('ui.font_size_xl', defaultValue: 20.0));
      await _config.setParameter('ui.font_size_2xl', getParameter('ui.font_size_2xl', defaultValue: 24.0));
      await _config.setParameter('ui.font_size_3xl', getParameter('ui.font_size_3xl', defaultValue: 30.0));

      // Apply spacing - all parameterized
      await _config.setParameter('ui.spacing_xs', getParameter('ui.spacing_xs', defaultValue: 4.0));
      await _config.setParameter('ui.spacing_sm', getParameter('ui.spacing_sm', defaultValue: 8.0));
      await _config.setParameter('ui.spacing_md', getParameter('ui.spacing_md', defaultValue: 16.0));
      await _config.setParameter('ui.spacing_lg', getParameter('ui.spacing_lg', defaultValue: 24.0));
      await _config.setParameter('ui.spacing_xl', getParameter('ui.spacing_xl', defaultValue: 32.0));
      await _config.setParameter('ui.spacing_2xl', getParameter('ui.spacing_2xl', defaultValue: 48.0));

      // Apply border radius - all parameterized
      await _config.setParameter('ui.border_radius_sm', getParameter('ui.border_radius_sm', defaultValue: 4.0));
      await _config.setParameter('ui.border_radius_md', getParameter('ui.border_radius_md', defaultValue: 8.0));
      await _config.setParameter('ui.border_radius_lg', getParameter('ui.border_radius_lg', defaultValue: 12.0));
      await _config.setParameter('ui.border_radius_xl', getParameter('ui.border_radius_xl', defaultValue: 16.0));
      await _config.setParameter('ui.border_radius_full', getParameter('ui.border_radius_full', defaultValue: 999.0));

      // Apply shadows - all parameterized
      await _config.setParameter('ui.shadow_sm', getParameter('ui.shadow_sm', defaultValue: 2.0));
      await _config.setParameter('ui.shadow_md', getParameter('ui.shadow_md', defaultValue: 4.0));
      await _config.setParameter('ui.shadow_lg', getParameter('ui.shadow_lg', defaultValue: 8.0));
      await _config.setParameter('ui.shadow_xl', getParameter('ui.shadow_xl', defaultValue: 16.0));

      // Apply animations - all parameterized
      await _config.setParameter('ui.animation_fast', getParameter('ui.animation_fast', defaultValue: 150));
      await _config.setParameter('ui.animation_normal', getParameter('ui.animation_normal', defaultValue: 300));
      await _config.setParameter('ui.animation_slow', getParameter('ui.animation_slow', defaultValue: 500));

      // Apply component dimensions - all parameterized
      await _config.setParameter('ui.button_height', getParameter('ui.button_height', defaultValue: 48.0));
      await _config.setParameter('ui.input_height', getParameter('ui.input_height', defaultValue: 48.0));
      await _config.setParameter('ui.card_padding', getParameter('ui.card_padding', defaultValue: 16.0));
      await _config.setParameter('ui.screen_padding', getParameter('ui.screen_padding', defaultValue: 16.0));

      // Apply icon sizes - all parameterized
      await _config.setParameter('ui.icon_size_sm', getParameter('ui.icon_size_sm', defaultValue: 16.0));
      await _config.setParameter('ui.icon_size_md', getParameter('ui.icon_size_md', defaultValue: 24.0));
      await _config.setParameter('ui.icon_size_lg', getParameter('ui.icon_size_lg', defaultValue: 32.0));
      await _config.setParameter('ui.icon_size_xl', getParameter('ui.icon_size_xl', defaultValue: 48.0));

      // Apply UI text strings - all parameterized
      await _config.setParameter('ui.text.loading.title', getParameter('ui.text.loading.title', defaultValue: 'iSuite'));
      await _config.setParameter('ui.text.loading.subtitle', getParameter('ui.text.loading.subtitle', defaultValue: 'Enterprise File Manager'));
      await _config.setParameter('ui.text.loading.status', getParameter('ui.text.loading.status', defaultValue: 'Initializing...'));
      await _config.setParameter('ui.text.error.title', getParameter('ui.text.error.title', defaultValue: 'Initialization Failed'));
      await _config.setParameter('ui.text.error.subtitle', getParameter('ui.text.error.subtitle', defaultValue: 'iSuite could not start properly'));
      await _config.setParameter('ui.text.error.retry', getParameter('ui.text.error.retry', defaultValue: 'Retry'));
      await _config.setParameter('ui.text.app.semantics_label', getParameter('ui.text.app.semantics_label', defaultValue: 'iSuite Application'));

      // Apply UI icons - all parameterized
      await _config.setParameter('ui.icon.loading', getParameter('ui.icon.loading', defaultValue: 'folder_shared'));
      await _config.setParameter('ui.icon.error', getParameter('ui.icon.error', defaultValue: 'error_outline'));

      // Apply UI routes - all parameterized
      await _config.setParameter('ui.route.home', getParameter('ui.route.home', defaultValue: '/'));
      await _config.setParameter('ui.route.files', getParameter('ui.route.files', defaultValue: '/files'));
      await _config.setParameter('ui.route.network', getParameter('ui.route.network', defaultValue: '/network'));
      await _config.setParameter('ui.route.settings', getParameter('ui.route.settings', defaultValue: '/settings'));

      // Apply UI layout parameters - all parameterized
      await _config.setParameter('ui.layout.loading.icon_size', getParameter('ui.layout.loading.icon_size', defaultValue: 'xl'));
      await _config.setParameter('ui.layout.loading.title_font', getParameter('ui.layout.loading.title_font', defaultValue: '2xl'));
      await _config.setParameter('ui.layout.loading.subtitle_font', getParameter('ui.layout.loading.subtitle_font', defaultValue: 'lg'));
      await _config.setParameter('ui.layout.loading.text_font', getParameter('ui.layout.loading.text_font', defaultValue: 'sm'));
      await _config.setParameter('ui.layout.loading.spacing_md', getParameter('ui.layout.loading.spacing_md', defaultValue: 'md'));
      await _config.setParameter('ui.layout.loading.spacing_xl', getParameter('ui.layout.loading.spacing_xl', defaultValue: 'xl'));

      await _config.setParameter('ui.layout.error.icon_size', getParameter('ui.layout.error.icon_size', defaultValue: 'xl'));
      await _config.setParameter('ui.layout.error.title_font', getParameter('ui.layout.error.title_font', defaultValue: '2xl'));
      await _config.setParameter('ui.layout.error.subtitle_font', getParameter('ui.layout.error.subtitle_font', defaultValue: 'lg'));
      await _config.setParameter('ui.layout.error.text_font', getParameter('ui.layout.error.text_font', defaultValue: 'sm'));
      await _config.setParameter('ui.layout.error.spacing_md', getParameter('ui.layout.error.spacing_md', defaultValue: 'md'));
      await _config.setParameter('ui.layout.error.spacing_xl', getParameter('ui.layout.error.spacing_xl', defaultValue: 'xl'));
      await _config.setParameter('ui.layout.error.border_radius', getParameter('ui.layout.error.border_radius', defaultValue: 'md'));

      // Apply UI accessibility - all parameterized
      await _config.setParameter('ui.accessibility.enabled', getParameter('ui.accessibility.enabled', defaultValue: false));
      await _config.setParameter('ui.accessibility.screen_reader_delay', getParameter('ui.accessibility.screen_reader_delay', defaultValue: 1000));

      _logger.info('✅ Enhanced UI configuration applied with complete central parameterization', 'EnhancedISuiteApp');
    } catch (e) {
      _logger.error('❌ Failed to apply enhanced UI configuration', 'EnhancedISuiteApp', error: e);
    }
  }
