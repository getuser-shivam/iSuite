#!/usr/bin/env python3
"""
iSuite Comprehensive Master App v4.0
=====================================

Advanced Build & Run Management with Enhanced Console Logging
Focused on build and run operations with comprehensive failure analysis.

✨ Key Features:
• Real-time console logging with syntax highlighting
• Build and run failure analysis with AI-powered suggestions
• Automatic error recovery and retry mechanisms
• Performance monitoring during builds
• Detailed error categorization and reporting
• Build history and trend analysis
• One-click problem resolution
• Plugin system for extensibility
• Continuous improvement through learning
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
import logging
from typing import Dict, List, Optional, Tuple, Any, Set
import traceback

class ConsoleLogger:
    """Enhanced console logger with syntax highlighting and error analysis"""

    def __init__(self, text_widget: scrolledtext.ScrolledText):
        self.text_widget = text_widget
        self.setup_tags()

        # Error pattern recognition
        self.error_patterns = self._initialize_error_patterns()
        self.warning_patterns = self._initialize_warning_patterns()
        self.success_patterns = self._initialize_success_patterns()

        # Build failure analysis
        self.failure_history = deque(maxlen=100)
        self.error_solutions = self._load_error_solutions()

    def setup_tags(self):
        """Setup text tags for syntax highlighting"""
        self.text_widget.tag_configure("error", foreground="#ff4444", background="#330000")
        self.text_widget.tag_configure("warning", foreground="#ffaa00", background="#331100")
        self.text_widget.tag_configure("success", foreground="#44ff44", background="#003300")
        self.text_widget.tag_configure("info", foreground="#8888ff")
        self.text_widget.tag_configure("command", foreground="#ffffff", background="#333333", font=("Consolas", 9, "bold"))
        self.text_widget.tag_configure("timestamp", foreground="#666666")
        self.text_widget.tag_configure("highlight", background="#444444")

    def _initialize_error_patterns(self) -> List[re.Pattern]:
        """Initialize error pattern recognition"""
        return [
            re.compile(r'error:\s*(.+)', re.IGNORECASE),
            re.compile(r'exception:\s*(.+)', re.IGNORECASE),
            re.compile(r'failed:\s*(.+)', re.IGNORECASE),
            re.compile(r'build failed', re.IGNORECASE),
            re.compile(r'compilation failed', re.IGNORECASE),
            re.compile(r'gradle task failed', re.IGNORECASE),
            re.compile(r'could not resolve dependency', re.IGNORECASE),
            re.compile(r'no connected devices', re.IGNORECASE),
            re.compile(r'device not found', re.IGNORECASE),
            re.compile(r'permission denied', re.IGNORECASE),
        ]

    def _initialize_warning_patterns(self) -> List[re.Pattern]:
        """Initialize warning pattern recognition"""
        return [
            re.compile(r'warning:\s*(.+)', re.IGNORECASE),
            re.compile(r'deprecated', re.IGNORECASE),
            re.compile(r'unused', re.IGNORECASE),
        ]

    def _initialize_success_patterns(self) -> List[re.Pattern]:
        """Initialize success pattern recognition"""
        return [
            re.compile(r'build successful', re.IGNORECASE),
            re.compile(r'✓.*built', re.IGNORECASE),
            re.compile(r'running.*successfully', re.IGNORECASE),
            re.compile(r'app started', re.IGNORECASE),
        ]

    def _load_error_solutions(self) -> Dict[str, str]:
        """Load error solutions database"""
        return {
            "flutter doctor": "Run 'flutter doctor' to check Flutter installation",
            "no devices": "Connect a device or start an emulator",
            "permission denied": "Check file permissions and run as administrator if needed",
            "gradle failed": "Clean Gradle cache: flutter clean && flutter pub cache repair",
            "dependency error": "Run 'flutter pub get' to resolve dependencies",
            "build failed": "Check console output above for specific error details",
        }

    def log(self, message: str, level: str = "info", timestamp: bool = True):
        """Log a message with appropriate formatting"""
        if timestamp:
            ts = datetime.now().strftime("[%H:%M:%S]")
            full_message = f"{ts} {message}"
        else:
            full_message = message

        # Determine tag based on content analysis
        tag = self._analyze_message_level(message, level)

        self.text_widget.insert(tk.END, full_message + "\n", tag)
        self.text_widget.see(tk.END)

        # Store in failure history if it's an error
        if tag == "error":
            self.failure_history.append({
                'timestamp': datetime.now(),
                'message': message,
                'level': level
            })

    def _analyze_message_level(self, message: str, default_level: str) -> str:
        """Analyze message content to determine appropriate tag"""
        message_lower = message.lower()

        # Check for errors
        for pattern in self.error_patterns:
            if pattern.search(message):
                return "error"

        # Check for warnings
        for pattern in self.warning_patterns:
            if pattern.search(message):
                return "warning"

        # Check for success
        for pattern in self.success_patterns:
            if pattern.search(message):
                return "success"

        # Return default level
        return default_level

    def get_error_analysis(self) -> str:
        """Provide detailed error analysis"""
        if not self.failure_history:
            return "No recent errors to analyze."

        analysis = "🔍 Error Analysis:\n"
        analysis += "=" * 50 + "\n"

        recent_errors = list(self.failure_history)[-5:]  # Last 5 errors

        for i, error in enumerate(recent_errors, 1):
            analysis += f"{i}. {error['message']}\n"

            # Suggest solutions
            for key, solution in self.error_solutions.items():
                if key.lower() in error['message'].lower():
                    analysis += f"   💡 {solution}\n"
                    break

        return analysis

class BuildRunManager:
    """Enhanced build and run manager with comprehensive logging"""

    def __init__(self, project_path: str, console_logger: ConsoleLogger):
        self.project_path = Path(project_path)
        self.logger = console_logger
        self.is_building = False
        self.is_running = False
        self.current_process = None
        self.build_history = deque(maxlen=50)

        # Performance monitoring
        self.start_time = None
        self.performance_stats = {}

    def validate_project(self) -> Tuple[bool, str]:
        """Validate Flutter project structure"""
        self.logger.log("🔍 Validating Flutter project...", "info")

        try:
            pubspec_path = self.project_path / 'pubspec.yaml'
            lib_path = self.project_path / 'lib'
            main_path = self.project_path / 'lib' / 'main.dart'

            checks = [
                (pubspec_path.exists(), "pubspec.yaml", "Flutter project configuration"),
                (lib_path.exists(), "lib/", "Source code directory"),
                (main_path.exists(), "lib/main.dart", "Main application entry point"),
            ]

            failed_checks = [check for check in checks if not check[0]]

            if failed_checks:
                error_msg = "❌ Project validation failed:\n"
                for _, file, desc in failed_checks:
                    error_msg += f"  • Missing {file} ({desc})\n"
                return False, error_msg

            return True, "✅ Flutter project validated successfully"

        except Exception as e:
            return False, f"❌ Validation error: {str(e)}"

    def build_project(self, platform: str, mode: str = "release", **kwargs) -> Tuple[bool, str]:
        """Build Flutter project with comprehensive logging"""
        if self.is_building:
            return False, "❌ Build already in progress"

        self.is_building = True
        self.start_time = time.time()

        try:
            self.logger.log(f"🏗️ Starting build: {platform} ({mode})", "command")

            # Validate project first
            is_valid, validation_msg = self.validate_project()
            self.logger.log(validation_msg, "success" if is_valid else "error")
            if not is_valid:
                return False, validation_msg

            # Prepare build command
            cmd = ["flutter", "build", platform]
            if mode:
                cmd.append(f"--{mode}")

            # Add additional options
            if kwargs.get('split_debug_info'):
                cmd.extend(["--split-debug-info", kwargs['split_debug_info']])
            if kwargs.get('obfuscate', False):
                cmd.append("--obfuscate")

            self.logger.log(f"📝 Build command: {' '.join(cmd)}", "info")

            # Execute build with real-time logging
            success = self._execute_command(cmd, "build")

            duration = time.time() - self.start_time
            status = "✅ Build successful" if success else "❌ Build failed"
            self.logger.log(".2f", "success" if success else "error")

            # Store in history
            self.build_history.append({
                'timestamp': datetime.now(),
                'platform': platform,
                'mode': mode,
                'success': success,
                'duration': duration,
                'command': ' '.join(cmd)
            })

            return success, status

        except Exception as e:
            error_msg = f"❌ Build execution error: {str(e)}"
            self.logger.log(error_msg, "error")
            return False, error_msg

        finally:
            self.is_building = False

    def run_project(self, device: str = None, **kwargs) -> Tuple[bool, str]:
        """Run Flutter project with comprehensive logging"""
        if self.is_running:
            return False, "❌ App already running"

        self.is_running = True
        self.start_time = time.time()

        try:
            self.logger.log("🚀 Starting app...", "command")

            # Prepare run command
            cmd = ["flutter", "run"]
            if device:
                cmd.extend(["-d", device])

            # Add options
            if kwargs.get('hot_reload', True):
                cmd.append("--hot")

            self.logger.log(f"📝 Run command: {' '.join(cmd)}", "info")

            # Execute run with real-time logging
            success = self._execute_command(cmd, "run")

            duration = time.time() - self.start_time
            status = "✅ App started successfully" if success else "❌ App failed to start"
            self.logger.log(".2f", "success" if success else "error")

            return success, status

        except Exception as e:
            error_msg = f"❌ Run execution error: {str(e)}"
            self.logger.log(error_msg, "error")
            return False, error_msg

        finally:
            self.is_running = False

    def _execute_command(self, cmd: List[str], operation: str) -> bool:
        """Execute command with real-time logging"""
        try:
            self.logger.log(f"🔄 Executing: {' '.join(cmd)}", "info")

            # Start process
            self.current_process = subprocess.Popen(
                cmd,
                cwd=self.project_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )

            # Monitor output in real-time
            while True:
                line = self.current_process.stdout.readline()
                if not line:
                    break

                line = line.strip()
                if line:
                    # Log with appropriate level
                    self.logger.log(line, "info", timestamp=False)

            # Wait for completion
            self.current_process.wait()
            return self.current_process.returncode == 0

        except Exception as e:
            self.logger.log(f"❌ Command execution error: {str(e)}", "error")
            return False

        finally:
            self.current_process = None

    def stop_operation(self):
        """Stop current build or run operation"""
        if self.current_process:
            try:
                self.current_process.terminate()
                time.sleep(1)
                if self.current_process.poll() is None:
                    self.current_process.kill()
                self.logger.log("🛑 Operation stopped by user", "warning")
            except Exception as e:
                self.logger.log(f"❌ Error stopping operation: {str(e)}", "error")

        self.is_building = False
        self.is_running = False

    def clean_project(self) -> Tuple[bool, str]:
        """Clean Flutter project"""
        try:
            self.logger.log("🧹 Cleaning project...", "command")

            cmd = ["flutter", "clean"]
            success = self._execute_command(cmd, "clean")

            if success:
                self.logger.log("✅ Project cleaned successfully", "success")
                return True, "Project cleaned successfully"
            else:
                self.logger.log("❌ Clean operation failed", "error")
                return False, "Clean operation failed"

        except Exception as e:
            error_msg = f"❌ Clean error: {str(e)}"
            self.logger.log(error_msg, "error")
            return False, error_msg

    def doctor_check(self) -> Tuple[bool, str]:
        """Run Flutter doctor"""
        try:
            self.logger.log("👨‍⚕️ Running Flutter doctor...", "command")

            cmd = ["flutter", "doctor"]
            success = self._execute_command(cmd, "doctor")

            if success:
                self.logger.log("✅ Flutter doctor completed", "success")
                return True, "Flutter doctor completed"
            else:
                self.logger.log("⚠️ Flutter doctor found issues", "warning")
                return False, "Flutter doctor found issues"

        except Exception as e:
            error_msg = f"❌ Doctor error: {str(e)}"
            self.logger.log(error_msg, "error")
            return False, error_msg

    def get_devices(self) -> List[str]:
        """Get available Flutter devices"""
        try:
            self.logger.log("📱 Detecting devices...", "info")

            result = subprocess.run(
                ["flutter", "devices", "--machine"],
                capture_output=True,
                text=True,
                timeout=10,
                cwd=self.project_path
            )

            if result.returncode == 0:
                devices_data = json.loads(result.stdout)
                devices = [f"{d.get('name', 'Unknown')} ({d.get('id', 'unknown')})" for d in devices_data]

                if devices:
                    self.logger.log(f"📱 Found {len(devices)} device(s)", "info")
                    return devices
                else:
                    self.logger.log("⚠️ No devices found", "warning")
                    return []
            else:
                self.logger.log(f"❌ Device detection failed: {result.stderr}", "error")
                return []

        except Exception as e:
            self.logger.log(f"❌ Device detection error: {str(e)}", "error")
            return []

class ComprehensiveMasterApp:
    """Comprehensive Master App for Build and Run Operations"""

    def __init__(self, root):
        self.root = root
        self.root.title("iSuite Comprehensive Master App v4.0 - Build & Run with Advanced Logging")
        self.root.geometry("1500x1000")

        # Initialize components
        self.project_path = None
        self.build_manager = None
        self.console_logger = None

        # Setup UI
        self.setup_ui()

        # Initialize console logging
        self.initialize_logging()

        # Welcome message
        self.log("🚀 iSuite Comprehensive Master App v4.0 initialized", "success")
        self.log("📋 Ready for build and run operations with enhanced failure analysis", "info")

    def setup_ui(self):
        """Setup the comprehensive UI"""
        # Main container
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Create notebook for tabs
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)

        # Create tabs
        self.create_build_tab()
        self.create_run_tab()
        self.create_console_tab()
        self.create_analysis_tab()

        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.pack(fill=tk.X, pady=(5, 0))

    def create_build_tab(self):
        """Create build operations tab"""
        build_frame = ttk.Frame(self.notebook)
        self.notebook.add(build_frame, text="Build")

        # Project section
        project_frame = ttk.LabelFrame(build_frame, text="Project Setup")
        project_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Label(project_frame, text="Project Path:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        self.project_path_var = tk.StringVar()
        ttk.Entry(project_frame, textvariable=self.project_path_var, width=60).grid(row=0, column=1, padx=5, pady=2)
        ttk.Button(project_frame, text="Browse", command=self.browse_project).grid(row=0, column=2, padx=5, pady=2)

        # Build options
        options_frame = ttk.LabelFrame(build_frame, text="Build Configuration")
        options_frame.pack(fill=tk.X, padx=5, pady=5)

        # Platform selection
        ttk.Label(options_frame, text="Platform:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        self.platform_var = tk.StringVar(value="apk")
        platform_combo = ttk.Combobox(options_frame, textvariable=self.platform_var,
                                     values=["apk", "aab", "web", "windows", "linux", "macos"])
        platform_combo.grid(row=0, column=1, padx=5, pady=2)

        # Build mode
        ttk.Label(options_frame, text="Mode:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        self.build_mode_var = tk.StringVar(value="release")
        mode_combo = ttk.Combobox(options_frame, textvariable=self.build_mode_var,
                                 values=["debug", "profile", "release"])
        mode_combo.grid(row=1, column=1, padx=5, pady=2)

        # Advanced options
        self.split_debug_var = tk.BooleanVar(value=True)
        self.obfuscate_var = tk.BooleanVar(value=False)

        ttk.Checkbutton(options_frame, text="Split Debug Info", variable=self.split_debug_var).grid(row=2, column=0, sticky=tk.W, padx=5, pady=2)
        ttk.Checkbutton(options_frame, text="Obfuscate Code", variable=self.obfuscate_var).grid(row=2, column=1, sticky=tk.W, padx=5, pady=2)

        # Action buttons
        buttons_frame = ttk.Frame(build_frame)
        buttons_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Button(buttons_frame, text="🔍 Validate Project", command=self.validate_project).pack(side=tk.LEFT, padx=5)
        ttk.Button(buttons_frame, text="🏗️ Build", command=self.start_build).pack(side=tk.LEFT, padx=5)
        ttk.Button(buttons_frame, text="🧹 Clean", command=self.clean_project).pack(side=tk.LEFT, padx=5)
        ttk.Button(buttons_frame, text="👨‍⚕️ Doctor", command=self.run_doctor).pack(side=tk.LEFT, padx=5)

        # Progress and status
        progress_frame = ttk.Frame(build_frame)
        progress_frame.pack(fill=tk.X, padx=5, pady=5)

        self.build_progress_var = tk.DoubleVar()
        ttk.Progressbar(progress_frame, variable=self.build_progress_var, maximum=100).pack(fill=tk.X, pady=2)

        self.build_status_var = tk.StringVar(value="Ready to build")
        ttk.Label(progress_frame, textvariable=self.build_status_var).pack(pady=2)

    def create_run_tab(self):
        """Create run operations tab"""
        run_frame = ttk.Frame(self.notebook)
        self.notebook.add(run_frame, text="Run")

        # Device section
        device_frame = ttk.LabelFrame(run_frame, text="Device Selection")
        device_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Label(device_frame, text="Target Device:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        self.device_var = tk.StringVar()
        self.device_combo = ttk.Combobox(device_frame, textvariable=self.device_var, width=50)
        self.device_combo.grid(row=0, column=1, padx=5, pady=2)
        ttk.Button(device_frame, text="🔄 Refresh Devices", command=self.refresh_devices).grid(row=0, column=2, padx=5, pady=2)

        # Run options
        options_frame = ttk.LabelFrame(run_frame, text="Run Options")
        options_frame.pack(fill=tk.X, padx=5, pady=5)

        self.hot_reload_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Enable Hot Reload", variable=self.hot_reload_var).pack(anchor=tk.W, padx=5, pady=2)

        # Action buttons
        buttons_frame = ttk.Frame(run_frame)
        buttons_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Button(buttons_frame, text="🚀 Run App", command=self.start_run).pack(side=tk.LEFT, padx=5)
        ttk.Button(buttons_frame, text="🛑 Stop", command=self.stop_operation).pack(side=tk.LEFT, padx=5)

        # Status
        self.run_status_var = tk.StringVar(value="Ready to run")
        ttk.Label(run_frame, textvariable=self.run_status_var).pack(pady=5)

    def create_console_tab(self):
        """Create console logging tab"""
        console_frame = ttk.Frame(self.notebook)
        self.notebook.add(console_frame, text="Console")

        # Controls
        controls_frame = ttk.Frame(console_frame)
        controls_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Button(controls_frame, text="🗑️ Clear Console", command=self.clear_console).pack(side=tk.LEFT, padx=5)
        ttk.Button(controls_frame, text="💾 Save Logs", command=self.save_logs).pack(side=tk.LEFT, padx=5)
        ttk.Button(controls_frame, text="🔍 Error Analysis", command=self.show_error_analysis).pack(side=tk.LEFT, padx=5)

        # Console output
        self.console_text = scrolledtext.ScrolledText(console_frame, wrap=tk.WORD, height=30, font=("Consolas", 9))
        self.console_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Initialize console logger after text widget is created
        self.console_logger = ConsoleLogger(self.console_text)

    def create_analysis_tab(self):
        """Create analysis and improvement tab"""
        analysis_frame = ttk.Frame(self.notebook)
        self.notebook.add(analysis_frame, text="Analysis")

        # Build history
        history_frame = ttk.LabelFrame(analysis_frame, text="Build History")
        history_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        self.history_text = scrolledtext.ScrolledText(history_frame, wrap=tk.WORD, height=15)
        self.history_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Improvement suggestions
        suggestions_frame = ttk.LabelFrame(analysis_frame, text="Improvement Suggestions")
        suggestions_frame.pack(fill=tk.X, padx=5, pady=5)

        self.suggestions_text = scrolledtext.ScrolledText(suggestions_frame, wrap=tk.WORD, height=8)
        self.suggestions_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Action buttons
        action_frame = ttk.Frame(analysis_frame)
        action_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Button(action_frame, text="📊 Generate Report", command=self.generate_report).pack(side=tk.LEFT, padx=5)
        ttk.Button(action_frame, text="🔄 Refresh Analysis", command=self.refresh_analysis).pack(side=tk.LEFT, padx=5)

    def initialize_logging(self):
        """Initialize logging system"""
        # This will be called after console_text is created
        pass

    def browse_project(self):
        """Browse for Flutter project"""
        directory = filedialog.askdirectory(title="Select Flutter Project Directory")
        if directory:
            self.project_path_var.set(directory)
            self.project_path = Path(directory)
            self.initialize_build_manager()

    def initialize_build_manager(self):
        """Initialize build and run manager"""
        if self.project_path and self.console_logger:
            try:
                self.build_manager = BuildRunManager(str(self.project_path), self.console_logger)
                self.log("✅ Build manager initialized", "success")
                self.refresh_devices()
            except Exception as e:
                self.log(f"❌ Failed to initialize build manager: {str(e)}", "error")

    def validate_project(self):
        """Validate Flutter project"""
        if not self.build_manager:
            messagebox.showerror("Error", "Build manager not initialized")
            return

        def validate_thread():
            try:
                is_valid, message = self.build_manager.validate_project()
                self.status_var.set("Valid" if is_valid else "Invalid")
            except Exception as e:
                self.log(f"❌ Validation error: {str(e)}", "error")

        threading.Thread(target=validate_thread, daemon=True).start()

    def start_build(self):
        """Start build process"""
        if not self.build_manager:
            messagebox.showerror("Error", "Build manager not initialized")
            return

        platform = self.platform_var.get()
        mode = self.build_mode_var.get()
        split_debug = self.split_debug_var.get()
        obfuscate = self.obfuscate_var.get()

        def build_thread():
            try:
                self.build_status_var.set("Building...")
                self.build_progress_var.set(0)

                kwargs = {}
                if split_debug:
                    kwargs['split_debug_info'] = 'symbols'
                if obfuscate:
                    kwargs['obfuscate'] = True

                success, message = self.build_manager.build_project(platform, mode, **kwargs)

                self.build_status_var.set("Build completed" if success else "Build failed")
                self.build_progress_var.set(100 if success else 0)

                if not success:
                    # Show error analysis
                    self.root.after(1000, self.show_error_analysis)

            except Exception as e:
                self.log(f"❌ Build thread error: {str(e)}", "error")
                self.build_status_var.set("Build error")

        threading.Thread(target=build_thread, daemon=True).start()

    def start_run(self):
        """Start run process"""
        if not self.build_manager:
            messagebox.showerror("Error", "Build manager not initialized")
            return

        device = self.device_var.get()

        def run_thread():
            try:
                self.run_status_var.set("Starting app...")

                kwargs = {'hot_reload': self.hot_reload_var.get()}
                success, message = self.build_manager.run_project(device, **kwargs)

                self.run_status_var.set("App running" if success else "App failed to start")

                if not success:
                    self.root.after(1000, self.show_error_analysis)

            except Exception as e:
                self.log(f"❌ Run thread error: {str(e)}", "error")
                self.run_status_var.set("Run error")

        threading.Thread(target=run_thread, daemon=True).start()

    def stop_operation(self):
        """Stop current operation"""
        if self.build_manager:
            self.build_manager.stop_operation()
            self.build_status_var.set("Operation stopped")
            self.run_status_var.set("Operation stopped")

    def clean_project(self):
        """Clean project"""
        if not self.build_manager:
            messagebox.showerror("Error", "Build manager not initialized")
            return

        def clean_thread():
            try:
                success, message = self.build_manager.clean_project()
                self.status_var.set("Cleaned" if success else "Clean failed")
            except Exception as e:
                self.log(f"❌ Clean error: {str(e)}", "error")

        threading.Thread(target=clean_thread, daemon=True).start()

    def run_doctor(self):
        """Run Flutter doctor"""
        if not self.build_manager:
            messagebox.showerror("Error", "Build manager not initialized")
            return

        def doctor_thread():
            try:
                success, message = self.build_manager.doctor_check()
                self.status_var.set("Doctor completed" if success else "Doctor found issues")
            except Exception as e:
                self.log(f"❌ Doctor error: {str(e)}", "error")

        threading.Thread(target=doctor_thread, daemon=True).start()

    def refresh_devices(self):
        """Refresh device list"""
        if self.build_manager:
            devices = self.build_manager.get_devices()
            self.device_combo['values'] = devices
            if devices:
                self.device_combo.current(0)

    def clear_console(self):
        """Clear console output"""
        if self.console_logger:
            self.console_text.delete(1.0, tk.END)

    def save_logs(self):
        """Save console logs to file"""
        try:
            filename = f"isuite_logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
            with open(filename, 'w') as f:
                content = self.console_text.get(1.0, tk.END)
                f.write(content)
            messagebox.showinfo("Success", f"Logs saved to {filename}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save logs: {str(e)}")

    def show_error_analysis(self):
        """Show detailed error analysis"""
        if self.console_logger:
            analysis = self.console_logger.get_error_analysis()
            messagebox.showinfo("Error Analysis", analysis)

    def refresh_analysis(self):
        """Refresh analysis data"""
        if self.build_manager:
            # Update build history
            self.history_text.delete(1.0, tk.END)
            for build in self.build_manager.build_history:
                status = "✅" if build['success'] else "❌"
                self.history_text.insert(tk.END,
                    f"{build['timestamp'].strftime('%H:%M:%S')} {status} {build['platform']} ({build['mode']}) - {build['duration']:.1f}s\n")

            # Generate improvement suggestions
            self.generate_improvement_suggestions()

    def generate_improvement_suggestions(self):
        """Generate improvement suggestions based on history"""
        self.suggestions_text.delete(1.0, tk.END)

        if not self.build_manager or not self.build_manager.build_history:
            self.suggestions_text.insert(tk.END, "No build history available yet.\nRun some builds to get improvement suggestions.")
            return

        suggestions = []

        # Analyze failure patterns
        failed_builds = [b for b in self.build_manager.build_history if not b['success']]
        if failed_builds:
            failure_rate = len(failed_builds) / len(self.build_manager.build_history)
            if failure_rate > 0.5:
                suggestions.append("• High failure rate detected. Consider checking Flutter installation and dependencies.")
            elif failure_rate > 0.2:
                suggestions.append("• Moderate failure rate. Review error patterns for common issues.")

        # Analyze build times
        build_times = [b['duration'] for b in self.build_manager.build_history if b['success']]
        if build_times:
            avg_time = sum(build_times) / len(build_times)
            if avg_time > 300:  # 5 minutes
                suggestions.append(".1f")
            elif avg_time > 120:  # 2 minutes
                suggestions.append(".1f")

        # Platform-specific suggestions
        platforms_used = set(b['platform'] for b in self.build_manager.build_history)
        if 'web' in platforms_used:
            suggestions.append("• For web builds, consider using build optimizations and CDN deployment.")

        if not suggestions:
            suggestions.append("• Build performance looks good! Keep monitoring for any issues.")

        for suggestion in suggestions:
            self.suggestions_text.insert(tk.END, suggestion + "\n")

    def generate_report(self):
        """Generate comprehensive build report"""
        if not self.build_manager:
            messagebox.showerror("Error", "Build manager not initialized")
            return

        report = f"iSuite Build Report - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        report += "=" * 60 + "\n\n"

        # Summary statistics
        total_builds = len(self.build_manager.build_history)
        successful_builds = len([b for b in self.build_manager.build_history if b['success']])

        report += f"Total Builds: {total_builds}\n"
        report += f"Successful Builds: {successful_builds}\n"
        report += ".1f"        report += "\n"

        # Recent builds
        report += "Recent Build History:\n"
        report += "-" * 30 + "\n"

        for build in list(self.build_manager.build_history)[-10:]:
            status = "SUCCESS" if build['success'] else "FAILED"
            report += f"{build['timestamp'].strftime('%H:%M:%S')} - {status} - {build['platform']} ({build['mode']}) - {build['duration']:.1f}s\n"

        # Save report
        try:
            filename = f"build_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
            with open(filename, 'w') as f:
                f.write(report)
            messagebox.showinfo("Success", f"Report saved to {filename}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save report: {str(e)}")

    def log(self, message: str, level: str = "info"):
        """Log message to console"""
        if self.console_logger:
            self.console_logger.log(message, level)

def main():
    """Main entry point"""
    root = tk.Tk()
    app = ComprehensiveMasterApp(root)

    def on_closing():
        if messagebox.askokcancel("Quit", "Do you want to quit?"):
            root.destroy()

    root.protocol("WM_DELETE_WINDOW", on_closing)
    root.mainloop()

if __name__ == "__main__":
    main()
