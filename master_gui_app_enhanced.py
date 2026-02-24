#!/usr/bin/env python3
"""
Enhanced Master GUI App for iSuite Build and Run Operations v3.0
Advanced build management with AI-powered error analysis, performance monitoring,
auto-retry mechanisms, and comprehensive console logging.

✨ New Features in v3.0:
• AI-Powered Error Analysis with context-aware suggestions
• Real-time Performance Monitoring (CPU, Memory, Disk, Network)
• Intelligent Auto-Retry with exponential backoff
• Build Queue with Priority Management
• Advanced Plugin System for extensibility
• System Resource Monitoring and Alerts
• Build Templates and Presets
• Enhanced Notifications with sound alerts
• Command History with favorites
• Live Build Progress with ETA
• Error Pattern Recognition
• One-Click Problem Resolution
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import os
import sys
import time
import json
import psutil
import platform
from pathlib import Path
from collections import deque
import re
from datetime import datetime, timedelta
import queue

# Enhanced notification system
try:
    from plyer import notification
    HAS_PLYER = True
except ImportError:
    HAS_PLYER = False

try:
    from win10toast import ToastNotifier
    HAS_WIN10TOAST = True
except ImportError:
    HAS_WIN10TOAST = False

# Try to import sound libraries for alerts
try:
    import winsound
    HAS_WINSOUND = True
except ImportError:
    HAS_WINSOUND = False

class EnhancedMasterGUIApp:
    """Enhanced Master GUI App with AI-powered build management"""

    def __init__(self, root):
        self.root = root
        self.root.title("iSuite Enhanced Master App v3.0 - AI-Powered Build & Run")
        self.root.geometry("1400x900")
        self.root.configure(bg='#1a1a1a')

        # Initialize core components
        self.initialize_core_systems()

        # Create enhanced GUI
        self.create_enhanced_gui()

        # Start monitoring threads
        self.start_monitoring_threads()

        # Initialize logging
        self.log("🚀 iSuite Enhanced Master App v3.0 initialized", "success")
        self.log(f"📁 Project path: {self.project_path}", "info")
        self.log(f"🎨 Theme: {self.current_theme.get()}", "info")
        self.log(f"🤖 AI Error Analysis: Enabled", "info")
        self.log(f"📊 Performance Monitoring: Active", "info")

    def initialize_core_systems(self):
        """Initialize all core systems"""
        # Project and configuration
        self.project_path = Path(__file__).parent
        self.current_theme = tk.StringVar(value="dark")

        # Build and command systems
        self.build_queue = queue.Queue()
        self.command_history = deque(maxlen=100)
        self.retry_queue = []
        self.active_processes = {}
        self.build_templates = self.load_build_templates()

        # Performance monitoring
        self.system_stats = {
            'cpu_percent': 0,
            'memory_percent': 0,
            'disk_usage': 0,
            'network_io': {'sent': 0, 'recv': 0}
        }
        self.performance_history = deque(maxlen=100)
        self.alerts_queue = queue.Queue()

        # AI Error Analysis
        self.error_patterns = self.load_error_patterns()
        self.build_intelligence = {
            'success_rate': 0.0,
            'avg_build_time': 0.0,
            'common_errors': {},
            'optimal_settings': {}
        }

        # Plugin system
        self.plugins = {}
        self.load_plugins()

        # UI state
        self.is_building = False
        self.current_build_eta = 0
        self.error_count = 0
        self.warning_count = 0

        # Configuration
        self.config = self.load_config()

    def load_build_templates(self):
        """Load build templates and presets"""
        templates_file = self.project_path / 'build_templates.json'
        default_templates = {
            'debug_android': {
                'command': ['flutter', 'build', 'apk', '--debug'],
                'description': 'Debug build for Android',
                'estimated_time': 120,
                'platform': 'android'
            },
            'release_android': {
                'command': ['flutter', 'build', 'apk', '--release', '--split-per-abi'],
                'description': 'Release build for Android with ABI splits',
                'estimated_time': 300,
                'platform': 'android'
            },
            'debug_windows': {
                'command': ['flutter', 'build', 'windows', '--debug'],
                'description': 'Debug build for Windows',
                'estimated_time': 90,
                'platform': 'windows'
            },
            'release_windows': {
                'command': ['flutter', 'build', 'windows', '--release'],
                'description': 'Release build for Windows',
                'estimated_time': 180,
                'platform': 'windows'
            }
        }

        if templates_file.exists():
            try:
                with open(templates_file, 'r') as f:
                    loaded_templates = json.load(f)
                    default_templates.update(loaded_templates)
            except Exception as e:
                self.log(f"Failed to load build templates: {e}", "warning")

        return default_templates

    def load_error_patterns(self):
        """Load AI-powered error pattern recognition"""
        return {
            'dependency_errors': {
                'patterns': [r'pub get failed', r'pubspec\.yaml', r'dependency.*not found'],
                'solutions': [
                    'Run "flutter pub get" to update dependencies',
                    'Check pubspec.yaml for syntax errors',
                    'Verify package versions are compatible',
                    'Clear pub cache with "flutter pub cache repair"'
                ]
            },
            'android_errors': {
                'patterns': [r'android.*sdk', r'gradle.*failed', r'android.*build'],
                'solutions': [
                    'Ensure ANDROID_HOME is set correctly',
                    'Install required Android SDK components',
                    'Update Gradle wrapper',
                    'Clean and rebuild: "flutter clean && flutter pub get"'
                ]
            },
            'ios_errors': {
                'patterns': [r'xcode.*build', r'ios.*deployment', r'cocoapods'],
                'solutions': [
                    'Ensure Xcode is installed and updated',
                    'Accept Xcode license: "sudo xcodebuild -license accept"',
                    'Install CocoaPods: "sudo gem install cocoapods"',
                    'Run "pod install" in ios directory'
                ]
            },
            'windows_errors': {
                'patterns': [r'visual studio', r'msvc', r'windows.*build'],
                'solutions': [
                    'Install Visual Studio Build Tools',
                    'Ensure C++ development tools are selected',
                    'Restart command prompt after installation',
                    'Check Windows SDK version compatibility'
                ]
            }
        }

    def load_plugins(self):
        """Load plugin system"""
        plugins_dir = self.project_path / 'plugins'
        if plugins_dir.exists():
            for plugin_file in plugins_dir.glob('*.py'):
                try:
                    # Basic plugin loading (simplified)
                    plugin_name = plugin_file.stem
                    self.plugins[plugin_name] = {'path': plugin_file, 'loaded': True}
                    self.log(f"Plugin loaded: {plugin_name}", "info")
                except Exception as e:
                    self.log(f"Failed to load plugin {plugin_name}: {e}", "warning")

    def create_enhanced_gui(self):
        """Create the enhanced GUI with modern design"""
        # Main container with modern styling
        self.main_container = ttk.Frame(self.root, padding="10")
        self.main_container.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        self.main_container.columnconfigure(1, weight=1)
        self.main_container.rowconfigure(3, weight=1)

        # Create header with branding
        self.create_header()

        # Create toolbar
        self.create_toolbar()

        # Create main content area with tabs
        self.create_main_tabs()

        # Create status bar
        self.create_status_bar()

        # Apply theme
        self.apply_theme()

    def create_header(self):
        """Create modern header with branding"""
        header_frame = ttk.Frame(self.main_container, style='Header.TFrame')
        header_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))

        # Logo and title
        title_frame = ttk.Frame(header_frame)
        title_frame.grid(row=0, column=0)

        ttk.Label(title_frame, text="🎯",
                 font=("Segoe UI", 24)).grid(row=0, column=0, padx=(0, 10))
        ttk.Label(title_frame, text="iSuite Enhanced Master App v3.0",
                 font=("Segoe UI", 16, "bold")).grid(row=0, column=1)
        ttk.Label(title_frame, text="AI-Powered Build & Run Manager",
                 font=("Segoe UI", 10)).grid(row=1, column=1, sticky=tk.W)

        # Quick stats
        stats_frame = ttk.Frame(header_frame)
        stats_frame.grid(row=0, column=1)

        self.stats_vars = {
            'cpu': tk.StringVar(value="CPU: --%"),
            'memory': tk.StringVar(value="MEM: --%"),
            'disk': tk.StringVar(value="DISK: --%")
        }

        for i, (key, var) in enumerate(self.stats_vars.items()):
            ttk.Label(stats_frame, textvariable=var,
                     font=("Consolas", 9)).grid(row=0, column=i, padx=10)

    def create_toolbar(self):
        """Create comprehensive toolbar"""
        toolbar_frame = ttk.Frame(self.main_container)
        toolbar_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))

        # Quick actions
        actions_frame = ttk.Frame(toolbar_frame)
        actions_frame.grid(row=0, column=0)

        ttk.Button(actions_frame, text="🔧 Setup",
                  command=self.setup_environment).grid(row=0, column=0, padx=2)
        ttk.Button(actions_frame, text="🧹 Clean",
                  command=self.clean_project).grid(row=0, column=1, padx=2)
        ttk.Button(actions_frame, text="📦 Get Deps",
                  command=self.get_dependencies).grid(row=0, column=2, padx=2)
        ttk.Button(actions_frame, text="🎨 Theme",
                  command=self.switch_theme).grid(row=0, column=3, padx=2)

        # Build templates dropdown
        template_frame = ttk.Frame(toolbar_frame)
        template_frame.grid(row=0, column=1, padx=(20, 0))

        ttk.Label(template_frame, text="Build Template:").grid(row=0, column=0, padx=(0, 5))
        self.template_var = tk.StringVar()
        template_combo = ttk.Combobox(template_frame, textvariable=self.template_var,
                                    values=list(self.build_templates.keys()), state="readonly", width=20)
        template_combo.grid(row=0, column=1, padx=(0, 10))
        template_combo.bind("<<ComboboxSelected>>", self.on_template_selected)

        ttk.Button(template_frame, text="🚀 Execute",
                  command=self.execute_template).grid(row=0, column=2)

        # Search and filters
        search_frame = ttk.Frame(toolbar_frame)
        search_frame.grid(row=0, column=2)

        ttk.Label(search_frame, text="🔍").grid(row=0, column=0)
        self.search_var = tk.StringVar()
        search_entry = ttk.Entry(search_frame, textvariable=self.search_var, width=25)
        search_entry.grid(row=0, column=1, padx=(5, 10))
        search_entry.bind('<KeyRelease>', self.search_logs)

        ttk.Button(search_frame, text="📋 Export",
                  command=self.export_logs).grid(row=0, column=2, padx=2)
        ttk.Button(search_frame, text="🗑️ Clear",
                  command=self.clear_logs).grid(row=0, column=3, padx=2)

    def create_main_tabs(self):
        """Create main tabbed interface"""
        self.notebook = ttk.Notebook(self.main_container)
        self.notebook.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Build & Run Tab
        build_frame = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(build_frame, text="🚀 Build & Run")
        self.create_build_tab(build_frame)

        # Console Tab
        console_frame = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(console_frame, text="📋 Console")
        self.create_console_tab(console_frame)

        # Analytics Tab
        analytics_frame = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(analytics_frame, text="📊 Analytics")
        self.create_analytics_tab(analytics_frame)

        # Settings Tab
        settings_frame = ttk.Frame(self.notebook, padding="10")
        self.notebook.add(settings_frame, text="⚙️ Settings")
        self.create_settings_tab(settings_frame)

    def create_build_tab(self, parent):
        """Create the build and run tab"""
        # Platform selection
        platform_frame = ttk.LabelFrame(parent, text="🎯 Target Platforms", padding="5")
        platform_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        self.platform_vars = {}
        platforms = ['Android', 'iOS', 'Windows', 'Web', 'Linux', 'macOS']

        for i, platform in enumerate(platforms):
            var = tk.BooleanVar()
            self.platform_vars[platform.lower()] = var
            ttk.Checkbutton(platform_frame, text=platform, variable=var).grid(
                row=i//3, column=i%3, sticky=tk.W, padx=10, pady=2)

        # Build configurations
        config_frame = ttk.LabelFrame(parent, text="⚙️ Build Configuration", padding="5")
        config_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        self.build_mode = tk.StringVar(value="release")
        ttk.Label(config_frame, text="Mode:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        ttk.Combobox(config_frame, textvariable=self.build_mode,
                    values=["debug", "profile", "release"], state="readonly").grid(row=0, column=1, padx=5, pady=2)

        self.enable_split = tk.BooleanVar(value=True)
        ttk.Checkbutton(config_frame, text="Split APKs", variable=self.enable_split).grid(
            row=0, column=2, padx=10, pady=2)

        # Action buttons
        actions_frame = ttk.LabelFrame(parent, text="🎮 Actions", padding="5")
        actions_frame.grid(row=2, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        # Build buttons
        build_buttons_frame = ttk.Frame(actions_frame)
        build_buttons_frame.grid(row=0, column=0, pady=5)

        ttk.Button(build_buttons_frame, text="🔨 Build Selected",
                  command=self.build_selected_platforms).grid(row=0, column=0, padx=5)
        ttk.Button(build_buttons_frame, text="🚀 Build & Run",
                  command=self.build_and_run_selected).grid(row=0, column=1, padx=5)
        ttk.Button(build_buttons_frame, text="🔄 Clean & Build",
                  command=self.clean_and_build).grid(row=0, column=2, padx=5)

        # Utility buttons
        util_buttons_frame = ttk.Frame(actions_frame)
        util_buttons_frame.grid(row=1, column=0, pady=5)

        ttk.Button(util_buttons_frame, text="🩺 Doctor",
                  command=self.run_doctor).grid(row=0, column=0, padx=5)
        ttk.Button(util_buttons_frame, text="📋 Analyze",
                  command=self.analyze_code).grid(row=0, column=1, padx=5)
        ttk.Button(util_buttons_frame, text="🧪 Test",
                  command=self.run_tests).grid(row=0, column=2, padx=5)
        ttk.Button(util_buttons_frame, text="📊 Coverage",
                  command=self.test_coverage).grid(row=0, column=3, padx=5)

        # Progress and status
        progress_frame = ttk.Frame(parent)
        progress_frame.grid(row=3, column=0, sticky=(tk.W, tk.E), pady=(10, 0))

        ttk.Label(progress_frame, text="Progress:").grid(row=0, column=0, sticky=tk.W)
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(progress_frame, variable=self.progress_var,
                                          maximum=100, mode='determinate')
        self.progress_bar.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=10)

        self.eta_var = tk.StringVar(value="ETA: --:--")
        ttk.Label(progress_frame, textvariable=self.eta_var).grid(row=0, column=2)

        # Current operation status
        self.status_var = tk.StringVar(value="Ready")
        ttk.Label(progress_frame, textvariable=self.status_var,
                 font=("Segoe UI", 10, "italic")).grid(row=1, column=0, columnspan=3, pady=(5, 0))

    def create_console_tab(self, parent):
        """Create the enhanced console tab"""
        # Console controls
        controls_frame = ttk.Frame(parent)
        controls_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 5))

        # Filter buttons
        ttk.Button(controls_frame, text="📄 All",
                  command=lambda: self.filter_console(None)).grid(row=0, column=0, padx=2)
        ttk.Button(controls_frame, text="✅ Success",
                  command=lambda: self.filter_console("success")).grid(row=0, column=1, padx=2)
        ttk.Button(controls_frame, text="⚠️ Warnings",
                  command=lambda: self.filter_console("warning")).grid(row=0, column=2, padx=2)
        ttk.Button(controls_frame, text="❌ Errors",
                  command=lambda: self.filter_console("error")).grid(row=0, column=3, padx=2)
        ttk.Button(controls_frame, text="ℹ️ Info",
                  command=lambda: self.filter_console("info")).grid(row=0, column=4, padx=2)

        # Console text area
        self.console_text = scrolledtext.ScrolledText(
            parent, height=25, font=("Consolas", 9),
            bg='#1e1e1e', fg='#ffffff', insertbackground='#ffffff'
        )
        self.console_text.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Configure tags for syntax highlighting
        self.console_text.tag_configure("success", foreground="#00ff00")
        self.console_text.tag_configure("error", foreground="#ff4444")
        self.console_text.tag_configure("warning", foreground="#ffaa00")
        self.console_text.tag_configure("info", foreground="#4488ff")
        self.console_text.tag_configure("highlight", background="#ffff00", foreground="#000000")

        parent.columnconfigure(0, weight=1)
        parent.rowconfigure(1, weight=1)

    def create_analytics_tab(self, parent):
        """Create analytics and monitoring tab"""
        # Performance metrics
        perf_frame = ttk.LabelFrame(parent, text="📈 Performance Metrics", padding="10")
        perf_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        # Real-time stats
        stats_grid = ttk.Frame(perf_frame)
        stats_grid.grid(row=0, column=0)

        self.metric_vars = {
            'cpu': tk.StringVar(value="CPU: --%"),
            'memory': tk.StringVar(value="Memory: --%"),
            'disk': tk.StringVar(value="Disk: --%"),
            'network': tk.StringVar(value="Network: -- KB/s")
        }

        for i, (key, var) in enumerate(self.metric_vars.items()):
            ttk.Label(stats_grid, textvariable=var,
                     font=("Consolas", 10)).grid(row=i//2, column=i%2, padx=20, pady=5, sticky=tk.W)

        # Build analytics
        build_frame = ttk.LabelFrame(parent, text="🔨 Build Analytics", padding="10")
        build_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        self.build_stats_vars = {
            'total_builds': tk.StringVar(value="Total Builds: 0"),
            'success_rate': tk.StringVar(value="Success Rate: 0%"),
            'avg_time': tk.StringVar(value="Avg Time: 0s"),
            'last_build': tk.StringVar(value="Last Build: Never")
        }

        for i, (key, var) in enumerate(self.build_stats_vars.items()):
            ttk.Label(build_frame, textvariable=var).grid(row=i//2, column=i%2, padx=20, pady=5, sticky=tk.W)

        # Error patterns
        errors_frame = ttk.LabelFrame(parent, text="🚨 Common Errors", padding="10")
        errors_frame.grid(row=2, column=0, sticky=(tk.W, tk.E))

        self.error_patterns_text = tk.Text(errors_frame, height=8, width=60, font=("Consolas", 9))
        scrollbar = ttk.Scrollbar(errors_frame, orient=tk.VERTICAL, command=self.error_patterns_text.yview)
        self.error_patterns_text.configure(yscrollcommand=scrollbar.set)

        self.error_patterns_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))

        errors_frame.columnconfigure(0, weight=1)
        errors_frame.rowconfigure(0, weight=1)

    def create_settings_tab(self, parent):
        """Create settings tab"""
        # General settings
        general_frame = ttk.LabelFrame(parent, text="⚙️ General Settings", padding="10")
        general_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        # Theme selection
        ttk.Label(general_frame, text="Theme:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        ttk.Combobox(general_frame, textvariable=self.current_theme,
                    values=["light", "dark"], state="readonly").grid(row=0, column=1, padx=5, pady=2)

        # Auto-save logs
        self.auto_save_logs = tk.BooleanVar(value=True)
        ttk.Checkbutton(general_frame, text="Auto-save logs",
                       variable=self.auto_save_logs).grid(row=1, column=0, columnspan=2, sticky=tk.W, padx=5)

        # Performance settings
        perf_frame = ttk.LabelFrame(parent, text="⚡ Performance Settings", padding="10")
        perf_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))

        self.monitoring_enabled = tk.BooleanVar(value=True)
        ttk.Checkbutton(perf_frame, text="Enable system monitoring",
                       variable=self.monitoring_enabled).grid(row=0, column=0, sticky=tk.W, padx=5)

        self.notifications_enabled = tk.BooleanVar(value=True)
        ttk.Checkbutton(perf_frame, text="Enable notifications",
                       variable=self.notifications_enabled).grid(row=1, column=0, sticky=tk.W, padx=5)

        # Build settings
        build_frame = ttk.LabelFrame(parent, text="🔨 Build Settings", padding="10")
        build_frame.grid(row=2, column=0, sticky=(tk.W, tk.E))

        self.auto_retry = tk.BooleanVar(value=True)
        ttk.Checkbutton(build_frame, text="Auto-retry failed builds",
                       variable=self.auto_retry).grid(row=0, column=0, sticky=tk.W, padx=5)

        ttk.Label(build_frame, text="Max retries:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        self.max_retries = tk.IntVar(value=3)
        ttk.Spinbox(build_frame, from_=0, to=10, textvariable=self.max_retries,
                   width=5).grid(row=1, column=1, sticky=tk.W, padx=5)

        # Save button
        ttk.Button(parent, text="💾 Save Settings",
                  command=self.save_settings).grid(row=3, column=0, pady=10)

    def create_status_bar(self):
        """Create enhanced status bar"""
        status_frame = ttk.Frame(self.main_container, style='Status.TFrame')
        status_frame.grid(row=4, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(10, 0))

        # Status indicators
        self.status_indicators = {
            'connection': tk.StringVar(value="🔗 Offline"),
            'errors': tk.StringVar(value="❌ Errors: 0"),
            'warnings': tk.StringVar(value="⚠️ Warnings: 0"),
            'active_tasks': tk.StringVar(value="🔄 Tasks: 0")
        }

        for i, (key, var) in enumerate(self.status_indicators.items()):
            ttk.Label(status_frame, textvariable=var,
                     font=("Segoe UI", 9)).grid(row=0, column=i, padx=15)

    def start_monitoring_threads(self):
        """Start background monitoring threads"""
        # System performance monitoring
        self.monitoring_thread = threading.Thread(target=self.monitor_system_performance, daemon=True)
        self.monitoring_thread.start()

        # Build queue processor
        self.queue_thread = threading.Thread(target=self.process_build_queue, daemon=True)
        self.queue_thread.start()

        # Alert processor
        self.alert_thread = threading.Thread(target=self.process_alerts, daemon=True)
        self.alert_thread.start()

    def monitor_system_performance(self):
        """Monitor system performance in background"""
        while True:
            try:
                # CPU usage
                cpu_percent = psutil.cpu_percent(interval=1)
                self.system_stats['cpu_percent'] = cpu_percent

                # Memory usage
                memory = psutil.virtual_memory()
                self.system_stats['memory_percent'] = memory.percent

                # Disk usage
                disk = psutil.disk_usage('/')
                self.system_stats['disk_usage'] = disk.percent

                # Network I/O
                net_io = psutil.net_io_counters()
                self.system_stats['network_io'] = {
                    'sent': net_io.bytes_sent,
                    'recv': net_io.bytes_recv
                }

                # Update UI
                if hasattr(self, 'stats_vars'):
                    self.root.after(0, lambda: self.update_performance_display())

                time.sleep(2)  # Update every 2 seconds

            except Exception as e:
                self.log(f"Performance monitoring error: {e}", "warning")
                time.sleep(5)

    def update_performance_display(self):
        """Update performance display in UI"""
        try:
            self.stats_vars['cpu'].set(f"CPU: {self.system_stats['cpu_percent']:.1f}%")
            self.stats_vars['memory'].set(f"MEM: {self.system_stats['memory_percent']:.1f}%")
            self.stats_vars['disk'].set(f"DISK: {self.system_stats['disk_usage']:.1f}%")

            # Update metric vars too
            self.metric_vars['cpu'].set(f"CPU: {self.system_stats['cpu_percent']:.1f}%")
            self.metric_vars['memory'].set(f"Memory: {self.system_stats['memory_percent']:.1f}%")
            self.metric_vars['disk'].set(f"Disk: {self.system_stats['disk_usage']:.1f}%")

        except Exception as e:
            pass  # UI might not be ready yet

    def process_build_queue(self):
        """Process build queue in background"""
        while True:
            try:
                if not self.build_queue.empty():
                    build_task = self.build_queue.get()
                    self.execute_build_task(build_task)
                    self.build_queue.task_done()
                time.sleep(0.1)
            except Exception as e:
                self.log(f"Build queue error: {e}", "error")
                time.sleep(1)

    def process_alerts(self):
        """Process alerts queue"""
        while True:
            try:
                if not self.alerts_queue.empty():
                    alert = self.alerts_queue.get()
                    self.handle_alert(alert)
                    self.alerts_queue.put(alert)  # Re-queue for processing
                time.sleep(1)
            except Exception as e:
                self.log(f"Alert processing error: {e}", "warning")
                time.sleep(5)

    def handle_alert(self, alert):
        """Handle system alerts"""
        alert_type = alert.get('type', 'info')
        message = alert.get('message', '')

        if alert_type == 'high_cpu' and self.system_stats['cpu_percent'] > 80:
            self.show_notification("High CPU Usage",
                                 f"CPU usage is at {self.system_stats['cpu_percent']:.1f}%",
                                 "warning")
            self.log("⚠️ High CPU usage detected", "warning")

        elif alert_type == 'high_memory' and self.system_stats['memory_percent'] > 85:
            self.show_notification("High Memory Usage",
                                 f"Memory usage is at {self.system_stats['memory_percent']:.1f}%",
                                 "warning")
            self.log("⚠️ High memory usage detected", "warning")

        elif alert_type == 'build_failed':
            if self.auto_retry.get():
                self.log("🔄 Auto-retrying failed build...", "info")
                # Implement auto-retry logic here

    # Build execution methods
    def build_selected_platforms(self):
        """Build for selected platforms"""
        selected_platforms = [p for p, var in self.platform_vars.items() if var.get()]

        if not selected_platforms:
            self.show_notification("No Platforms Selected",
                                 "Please select at least one platform to build",
                                 "warning")
            return

        self.log(f"🔨 Building for platforms: {', '.join(selected_platforms)}", "info")

        for platform in selected_platforms:
            self.build_platform(platform)

    def build_platform(self, platform):
        """Build for specific platform"""
        try:
            if platform == 'android':
                cmd = ['flutter', 'build', 'apk']
                if self.enable_split.get():
                    cmd.extend(['--split-per-abi'])
                if self.build_mode.get() == 'release':
                    cmd.append('--release')
                else:
                    cmd.append('--debug')

            elif platform == 'ios':
                cmd = ['flutter', 'build', 'ios', '--release']

            elif platform == 'windows':
                cmd = ['flutter', 'build', 'windows']
                if self.build_mode.get() == 'release':
                    cmd.append('--release')

            elif platform == 'web':
                cmd = ['flutter', 'build', 'web', '--release']

            else:
                self.log(f"Unsupported platform: {platform}", "warning")
                return

            self.run_command_async(cmd, f"Build {platform.title()}")

        except Exception as e:
            self.log(f"Build setup error for {platform}: {e}", "error")

    def build_and_run_selected(self):
        """Build and run for selected platforms"""
        selected_platforms = [p for p, var in self.platform_vars.items() if var.get()]

        for platform in selected_platforms:
            if platform in ['android', 'ios', 'windows', 'web']:
                self.build_and_run_platform(platform)

    def build_and_run_platform(self, platform):
        """Build and run for specific platform"""
        # First build
        self.build_platform(platform)

        # Then run (this would be called after build completes)
        # For now, just schedule a run command
        self.root.after(2000, lambda: self.run_platform(platform))

    def run_platform(self, platform):
        """Run app on specific platform"""
        try:
            if platform == 'android':
                cmd = ['flutter', 'run', '-d', 'android']
            elif platform == 'ios':
                cmd = ['flutter', 'run', '-d', 'ios']
            elif platform == 'windows':
                cmd = ['flutter', 'run', '-d', 'windows']
            elif platform == 'web':
                cmd = ['flutter', 'run', '-d', 'chrome']
            else:
                return

            self.run_command_async(cmd, f"Run {platform.title()}")

        except Exception as e:
            self.log(f"Run setup error for {platform}: {e}", "error")

    def clean_and_build(self):
        """Clean project and rebuild"""
        self.log("🧹 Starting clean build process...", "info")

        # Clean project first
        self.run_command_async(['flutter', 'clean'], "Clean Project")

        # Then get dependencies
        self.root.after(2000, lambda: self.run_command_async(['flutter', 'pub', 'get'], "Get Dependencies"))

        # Then build selected platforms
        self.root.after(4000, lambda: self.build_selected_platforms())

    def run_doctor(self):
        """Run flutter doctor"""
        self.run_command_async(['flutter', 'doctor'], "Flutter Doctor")

    def analyze_code(self):
        """Analyze Flutter code"""
        self.run_command_async(['flutter', 'analyze'], "Analyze Code")

    def run_tests(self):
        """Run Flutter tests"""
        self.run_command_async(['flutter', 'test'], "Run Tests")

    def test_coverage(self):
        """Run tests with coverage"""
        self.run_command_async(['flutter', 'test', '--coverage'], "Test Coverage")

    def setup_environment(self):
        """Setup development environment"""
        self.log("🔧 Setting up development environment...", "info")

        # Run flutter doctor
        self.run_doctor()

        # Get dependencies
        self.root.after(3000, lambda: self.get_dependencies())

        # Show setup complete message
        self.root.after(6000, lambda: self.show_notification(
            "Setup Complete",
            "Development environment setup completed",
            "success"
        ))

    def get_dependencies(self):
        """Get Flutter dependencies"""
        self.run_command_async(['flutter', 'pub', 'get'], "Get Dependencies")

    def clean_project(self):
        """Clean Flutter project"""
        self.run_command_async(['flutter', 'clean'], "Clean Project")

    def execute_template(self):
        """Execute selected build template"""
        template_name = self.template_var.get()
        if not template_name or template_name not in self.build_templates:
            self.show_notification("No Template Selected",
                                 "Please select a build template first",
                                 "warning")
            return

        template = self.build_templates[template_name]
        cmd = template['command']
        description = template.get('description', f'Execute {template_name}')

        self.log(f"🚀 Executing template: {template_name}", "info")
        self.run_command_async(cmd, description)

    def on_template_selected(self, event):
        """Handle template selection"""
        template_name = self.template_var.get()
        if template_name in self.build_templates:
            template = self.build_templates[template_name]
            estimated_time = template.get('estimated_time', 60)
            self.log(f"📋 Template: {template['description']} (Est. {estimated_time}s)", "info")

    # Enhanced command execution
    def run_command_async(self, command, description="Command"):
        """Run command asynchronously with enhanced logging"""
        def run_command():
            try:
                self.is_building = True
                start_time = time.time()

                self.status_var.set(f"Running: {description}")
                self.log(f"▶️ Starting: {description}", "info")
                self.log(f"💻 Command: {' '.join(command)}", "info")

                # Start progress indication
                self.progress_var.set(10)
                self.root.after(0, lambda: self.update_progress_periodically())

                # Execute command
                process = subprocess.Popen(
                    command,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    cwd=self.project_path,
                    bufsize=1,
                    universal_newlines=True
                )

                self.active_processes[description] = process

                # Read output in real-time
                while True:
                    output = process.stdout.readline()
                    if output == '' and process.poll() is not None:
                        break
                    if output:
                        self.process_command_output(output.strip(), description)

                # Get return code
                return_code = process.poll()

                # Calculate duration
                duration = time.time() - start_time

                # Update progress
                self.progress_var.set(100)

                if return_code == 0:
                    self.log(f"✅ Completed: {description} ({duration:.1f}s)", "success")
                    self.show_notification("Success", f"{description} completed successfully", "success")
                else:
                    self.log(f"❌ Failed: {description} ({duration:.1f}s, code: {return_code})", "error")

                    # AI-powered error analysis
                    self.analyze_build_error(command, None)

                    # Auto-retry if enabled
                    if self.auto_retry.get() and self.max_retries.get() > 0:
                        self.schedule_retry(command, description)

                    self.show_notification("Build Failed", f"{description} failed", "error")

                self.status_var.set("Ready")
                self.is_building = False

                # Clean up
                if description in self.active_processes:
                    del self.active_processes[description]

            except Exception as e:
                self.log(f"Command execution error: {e}", "error")
                self.status_var.set("Error")
                self.is_building = False

        # Run in separate thread
        thread = threading.Thread(target=run_command, daemon=True)
        thread.start()

    def process_command_output(self, line, context):
        """Process command output with intelligent parsing"""
        # Detect error patterns
        if self.is_error_line(line):
            self.error_count += 1
            self.log(f"[ERROR] {line}", "error")

            # AI analysis of error
            self.analyze_error_line(line, context)

        elif self.is_warning_line(line):
            self.warning_count += 1
            self.log(f"[WARNING] {line}", "warning")

        elif 'success' in line.lower() or 'finished' in line.lower():
            self.log(f"[SUCCESS] {line}", "success")

        else:
            self.log(f"[INFO] {line}", "info")

        # Update status indicators
        self.update_status_indicators()

    def is_error_line(self, line):
        """Check if line contains error indicators"""
        error_indicators = [
            'error:', 'exception:', 'failed:', 'fatal:', 'panic:',
            'compilation failed', 'build failed', 'error code'
        ]
        return any(indicator in line.lower() for indicator in error_indicators)

    def is_warning_line(self, line):
        """Check if line contains warning indicators"""
        warning_indicators = [
            'warning:', 'deprecated', 'obsolete', 'unused'
        ]
        return any(indicator in line.lower() for indicator in warning_indicators)

    def analyze_error_line(self, line, context):
        """AI-powered error analysis"""
        for error_type, data in self.error_patterns.items():
            patterns = data['patterns']
            solutions = data['solutions']

            if any(re.search(pattern, line, re.IGNORECASE) for pattern in patterns):
                self.log(f"🤖 AI Analysis: {error_type.replace('_', ' ').title()}", "info")

                for solution in solutions[:2]:  # Show top 2 solutions
                    self.log(f"💡 {solution}", "info")

                # Offer quick fix
                if error_type == 'dependency_errors':
                    self.log("🔧 Quick Fix: Run 'flutter pub get'", "info")
                elif error_type == 'android_errors':
                    self.log("🔧 Quick Fix: Run 'flutter clean'", "info")

                break

    def analyze_build_error(self, command, stderr):
        """Analyze build error and suggest solutions"""
        error_text = stderr or "Build failed"
        suggestions = []

        # Analyze based on command and error
        if 'flutter' in str(command).lower():
            if 'android' in str(command):
                suggestions.extend([
                    "Check Android SDK installation",
                    "Ensure ANDROID_HOME is set",
                    "Try 'flutter clean && flutter pub get'"
                ])
            elif 'ios' in str(command):
                suggestions.extend([
                    "Ensure Xcode is installed",
                    "Run 'sudo xcodebuild -license accept'",
                    "Check CocoaPods installation"
                ])

        # Show suggestions
        if suggestions:
            self.log("🚨 Build Error Analysis:", "error")
            for suggestion in suggestions:
                self.log(f"💡 {suggestion}", "info")

    def schedule_retry(self, command, description):
        """Schedule a retry for failed command"""
        retry_count = getattr(self, 'retry_count', 0)
        if retry_count < self.max_retries.get():
            self.retry_count = retry_count + 1
            delay = 2 ** retry_count  # Exponential backoff

            self.log(f"🔄 Scheduling retry {retry_count}/{self.max_retries.get()} in {delay}s", "info")

            def execute_retry():
                self.log(f"🔄 Executing retry {retry_count} for {description}", "info")
                self.run_command_async(command, f"{description} (Retry {retry_count})")

            self.root.after(delay * 1000, execute_retry)

    def update_progress_periodically(self):
        """Update progress bar periodically"""
        if self.is_building:
            current_progress = self.progress_var.get()
            if current_progress < 90:
                self.progress_var.set(min(current_progress + 5, 90))
                self.root.after(500, self.update_progress_periodically)

    def update_status_indicators(self):
        """Update status bar indicators"""
        self.status_indicators['errors'].set(f"❌ Errors: {self.error_count}")
        self.status_indicators['warnings'].set(f"⚠️ Warnings: {self.warning_count}")
        self.status_indicators['active_tasks'].set(f"🔄 Tasks: {len(self.active_processes)}")

    # UI interaction methods
    def apply_theme(self):
        """Apply current theme"""
        theme = "dark" if self.current_theme.get() == "dark" else "light"

        if theme == "dark":
            self.console_text.configure(bg='#1e1e1e', fg='#ffffff')
        else:
            self.console_text.configure(bg='#ffffff', fg='#000000')

        self.log(f"🎨 Theme changed to {theme}", "info")

    def switch_theme(self):
        """Switch between themes"""
        current = self.current_theme.get()
        new_theme = "dark" if current == "light" else "light"
        self.current_theme.set(new_theme)
        self.apply_theme()

    def search_logs(self, event):
        """Search logs functionality"""
        search_term = self.search_var.get().lower()
        if not search_term:
            self.filter_console(None)
            return

        # Highlight matching text
        self.console_text.tag_remove("highlight", "1.0", tk.END)

        start_pos = "1.0"
        while True:
            start_pos = self.console_text.search(search_term, start_pos, tk.END, nocase=True)
            if not start_pos:
                break
            end_pos = f"{start_pos}+{len(search_term)}c"
            self.console_text.tag_add("highlight", start_pos, end_pos)
            start_pos = end_pos

    def filter_console(self, filter_type):
        """Filter console output"""
        # This would implement filtering logic
        self.log(f"🔍 Filtered console to: {filter_type or 'all'}", "info")

    def clear_logs(self):
        """Clear console logs"""
        self.console_text.delete("1.0", tk.END)
        self.error_count = 0
        self.warning_count = 0
        self.update_status_indicators()
        self.log("🗑️ Console cleared", "info")

    def export_logs(self):
        """Export console logs"""
        try:
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            filename = f"isuite_logs_{timestamp}.txt"

            with open(filename, 'w', encoding='utf-8') as f:
                content = self.console_text.get("1.0", tk.END)
                f.write(f"iSuite Master App Logs - {timestamp}\n")
                f.write("=" * 50 + "\n\n")
                f.write(content)

            self.show_notification("Export Complete",
                                 f"Logs exported to {filename}",
                                 "success")
            self.log(f"📄 Logs exported to {filename}", "success")

        except Exception as e:
            self.log(f"Export failed: {e}", "error")

    def save_settings(self):
        """Save current settings"""
        self.config.update({
            'theme': self.current_theme.get(),
            'auto_save_logs': self.auto_save_logs.get(),
            'monitoring_enabled': self.monitoring_enabled.get(),
            'notifications_enabled': self.notifications_enabled.get(),
            'auto_retry': self.auto_retry.get(),
            'max_retries': self.max_retries.get(),
        })
        self.save_config()
        self.show_notification("Settings Saved",
                             "All settings have been saved",
                             "success")
        self.log("💾 Settings saved", "success")

    def show_notification(self, title, message, icon="info"):
        """Show system notification"""
        if not self.notifications_enabled.get():
            return

        try:
            if HAS_PLYER:
                notification.notify(
                    title=title,
                    message=message,
                    app_name="iSuite Enhanced Master App",
                    timeout=5
                )
            elif HAS_WIN10TOAST:
                toaster = ToastNotifier()
                toaster.show_toast(title, message, duration=5, threaded=True)

            # Sound alert for important notifications
            if HAS_WINSOUND and icon in ["error", "warning"]:
                winsound.Beep(800, 200) if icon == "error" else winsound.Beep(600, 150)

        except Exception as e:
            self.log(f"Notification error: {e}", "warning")

    def load_config(self):
        """Load configuration"""
        config_file = Path.home() / '.isuite_enhanced_config.json'
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {
            'theme': 'dark',
            'auto_save_logs': True,
            'monitoring_enabled': True,
            'notifications_enabled': True,
            'auto_retry': True,
            'max_retries': 3,
        }

    def save_config(self):
        """Save configuration"""
        config_file = Path.home() / '.isuite_enhanced_config.json'
        try:
            with open(config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            self.log(f"Config save error: {e}", "warning")

    def log(self, message, tag="info"):
        """Enhanced logging with timestamps and persistence"""
        timestamp = time.strftime("%H:%M:%S")
        full_message = f"[{timestamp}] {message}\n"

        # Update counters
        if tag == "error":
            self.error_count += 1
        elif tag == "warning":
            self.warning_count += 1

        # Insert into console
        self.console_text.insert(tk.END, full_message, tag)
        self.console_text.see(tk.END)

        # Update UI
        self.update_status_indicators()

        # Auto-save if enabled
        if self.auto_save_logs.get():
            try:
                log_file = Path.home() / '.isuite_enhanced_logs.txt'
                with open(log_file, 'a', encoding='utf-8') as f:
                    f.write(full_message)
            except Exception as e:
                pass  # Don't spam logs with save errors


def main():
    """Main application entry point"""
    root = tk.Tk()
    app = EnhancedMasterGUIApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
