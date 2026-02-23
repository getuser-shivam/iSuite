#!/usr/bin/env python3
"""
iSuite Master App - Professional Build & Run Manager
A comprehensive Python GUI application for building, running, and monitoring iSuite Flutter project
with advanced logging, error analysis, Flutter doctor integration, and continuous improvement.
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import queue
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path
import re
import logging
import platform
import shutil
from typing import Dict, List, Optional, Tuple, Callable
from dataclasses import dataclass, field
from enum import Enum
import psutil


class LogLevel(Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    SUCCESS = "SUCCESS"
    CRITICAL = "CRITICAL"


class FlutterCommand(Enum):
    DOCTOR = "doctor"
    ANALYZE = "analyze"
    BUILD = "build"
    RUN = "run"
    CLEAN = "clean"
    TEST = "test"
    PUB_GET = "pub get"
    PUB_UPGRADE = "pub upgrade"
    FORMAT = "format"
    LINT = "lint"
    ASSEMBLE = "assemble"
    INSTALL = "install"


@dataclass
class BuildResult:
    success: bool
    command: str
    output: str
    error_output: str = ""
    return_code: int = 0
    duration: float = 0.0
    errors_found: List[str] = field(default_factory=list)
    warnings_found: List[str] = field(default_factory=list)
    suggestions: List[str] = field(default_factory=list)


class FlutterAnalyzer:
    """Advanced Flutter output analyzer with error detection and suggestions"""
    
    def __init__(self):
        self.error_patterns = {
            'flutter_not_found': r'flutter\s*:\s*not\s*recognized|command\s+not\s+found',
            'dart_not_found': r'dart\s*:\s*not\s*recognized|command\s+not\s+found',
            'dependency_error': r'Error\s+on\s+line\s+\d+|dependency\s+resolution\s+failed',
            'import_error': r'Target\s+of\s+URI\s+doesn\'t\s+exist|import\s+error',
            'compilation_error': r'error.*\.dart:\d+:\d+|compilation\s+error',
            'syntax_error': r'syntax\s+error|unexpected\s+token',
            'type_error': r'type\s+error|cannot\s+convert',
            'null_safety_error': r'null\s+safety\s+error|non-nullable',
            'async_error': r'async\s+error|await\s+error',
            'widget_error': r'widget\s+error|renderflex\s+overflow',
            'permission_denied': r'Permission\s+denied|access\s+denied',
            'network_error': r'network|connection|timeout|unreachable',
            'memory_error': r'out\s+of\s+memory|memory|heap|stack\s+overflow',
            'disk_space': r'disk\s+space|no\s+space\s+left',
            'version_conflict': r'version\s+conflict|incompatible\s+version',
            'platform_error': r'platform\s+not\s+supported|unsupported\s+platform'
        }
        
        self.warning_patterns = {
            'deprecated': r'deprecated|obsolete|will\s+be\s+removed',
            'unused_import': r'unused\s+import|unused\s+element',
            'missing_return': r'missing\s+return|non-void\s+function',
            'dead_code': r'dead\s+code|unreachable\s+code',
            'performance': r'performance|slow|inefficient',
            'security': r'security|vulnerability|exposure'
        }
        
        self.suggestion_map = {
            'flutter_not_found': [
                "Install Flutter SDK from https://flutter.dev/docs/get-started/install",
                "Add Flutter to system PATH",
                "Verify Flutter installation with 'flutter --version'"
            ],
            'dart_not_found': [
                "Install Dart SDK from https://dart.dev/get-dart",
                "Add Dart to system PATH",
                "Verify Dart installation with 'dart --version'"
            ],
            'dependency_error': [
                "Run 'flutter pub get' to fetch dependencies",
                "Check pubspec.yaml for correct dependency versions",
                "Clear pub cache: 'flutter pub cache clean'"
            ],
            'import_error': [
                "Verify import paths and file existence",
                "Check for typos in import statements",
                "Ensure all required files are present"
            ],
            'compilation_error': [
                "Check syntax around reported line numbers",
                "Run 'flutter analyze' for detailed error information",
                "Verify all brackets and parentheses are balanced"
            ],
            'null_safety_error': [
                "Add null checks with '?' operator",
                "Use default values with '??' operator",
                "Initialize variables before use"
            ],
            'network_error': [
                "Check internet connection",
                "Verify firewall settings",
                "Try using different network or VPN"
            ],
            'memory_error': [
                "Close other applications to free memory",
                "Increase available RAM",
                "Restart the development environment"
            ]
        }
    
    def analyze_output(self, output: str, command: str) -> BuildResult:
        """Comprehensive analysis of Flutter command output"""
        result = BuildResult(
            success=True,
            command=command,
            output=output
        )
        
        # Check for errors
        for error_type, pattern in self.error_patterns.items():
            matches = re.findall(pattern, output, re.IGNORECASE)
            if matches:
                result.errors_found.extend(matches)
                if error_type in self.suggestion_map:
                    result.suggestions.extend(self.suggestion_map[error_type])
        
        # Check for warnings
        for warning_type, pattern in self.warning_patterns.items():
            matches = re.findall(pattern, output, re.IGNORECASE)
            if matches:
                result.warnings_found.extend(matches)
        
        # Determine success based on output and return code
        if any(keyword in output.lower() for keyword in ['failed', 'error:', 'exception']):
            result.success = False
        if 'finished' in output.lower() and 'error' not in output.lower():
            result.success = True
            
        return result


class ISuiteMasterGUI:
    """Professional GUI for iSuite Flutter project management"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("iSuite Master App - Professional Build Manager")
        self.root.geometry("1400x900")
        self.root.minsize(1200, 700)
        
        # Initialize components
        self.project_path = Path(__file__).parent
        self.analyzer = FlutterAnalyzer()
        self.current_process = None
        self.build_history = []
        self.log_queue = queue.Queue()
        
        # Setup UI
        self.setup_ui()
        self.setup_logging()
        self.load_project_info()
        
        # Start log processing
        self.process_log_queue()
        
    def setup_ui(self):
        """Create comprehensive UI layout"""
        # Configure styles
        style = ttk.Style()
        style.theme_use('clam')
        
        # Main container with padding
        main_frame = ttk.Frame(self.root, padding="15")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(2, weight=1)
        
        # Create sections
        self.create_header_section(main_frame)
        self.create_quick_actions_section(main_frame)
        self.create_flutter_tools_section(main_frame)
        self.create_log_viewer_section(main_frame)
        self.create_status_section(main_frame)
        
    def create_header_section(self, parent):
        """Create application header with project info"""
        header_frame = ttk.LabelFrame(parent, text="🚀 iSuite Project Manager", padding="10")
        header_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 15))
        
        # Project info
        info_frame = ttk.Frame(header_frame)
        info_frame.pack(fill=tk.X)
        
        self.project_label = ttk.Label(info_frame, text="Project: Loading...", 
                                      font=('Segoe UI', 11, 'bold'))
        self.project_label.pack(side=tk.LEFT)
        
        self.flutter_version_label = ttk.Label(info_frame, text="Flutter: Checking...", 
                                           font=('Segoe UI', 10))
        self.flutter_version_label.pack(side=tk.RIGHT)
        
    def create_quick_actions_section(self, parent):
        """Create quick action buttons"""
        quick_frame = ttk.LabelFrame(parent, text="⚡ Quick Actions", padding="10")
        quick_frame.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 10))
        
        # Action buttons in grid layout
        actions = [
            ("🔨 Build", self.build_project, "Build Flutter project"),
            ("▶️ Run", self.run_app, "Run Flutter application"),
            ("🧹 Clean", self.clean_project, "Clean build artifacts"),
            ("🔍 Analyze", self.analyze_code, "Analyze Dart code"),
            ("🩺 Doctor", self.flutter_doctor, "Check Flutter environment"),
            ("📦 Get Deps", self.get_dependencies, "Fetch dependencies"),
            ("🔄 Format", self.format_code, "Format Dart code"),
            ("🧪 Test", self.run_tests, "Run tests")
        ]
        
        for i, (text, command, tooltip) in enumerate(actions):
            btn = ttk.Button(quick_frame, text=text, command=command, width=15)
            btn.grid(row=i//4, column=i%4, padx=5, pady=5, sticky=(tk.W, tk.E))
            self.create_tooltip(btn, tooltip)
            
    def create_flutter_tools_section(self, parent):
        """Create comprehensive Flutter tools section"""
        tools_frame = ttk.LabelFrame(parent, text="🛠️ Flutter Tools & Commands", padding="10")
        tools_frame.grid(row=1, column=1, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 10))
        
        # Command selector
        cmd_frame = ttk.Frame(tools_frame)
        cmd_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(cmd_frame, text="Custom Command:", font=('Segoe UI', 10, 'bold')).pack(side=tk.LEFT)
        
        self.command_var = tk.StringVar(value="build")
        command_combo = ttk.Combobox(cmd_frame, textvariable=self.command_var, width=20, state="readonly")
        command_combo['values'] = [cmd.value for cmd in FlutterCommand]
        command_combo.pack(side=tk.LEFT, padx=(10, 0))
        
        # Target platform selector
        platform_frame = ttk.Frame(tools_frame)
        platform_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(platform_frame, text="Target Platform:", font=('Segoe UI', 10, 'bold')).pack(side=tk.LEFT)
        
        self.platform_var = tk.StringVar(value="web")
        platform_combo = ttk.Combobox(platform_frame, textvariable=self.platform_var, 
                                   values=["windows", "linux", "macos", "web", "android", "ios"], 
                                   width=15, state="readonly")
        platform_combo.pack(side=tk.LEFT, padx=(10, 0))
        
        # Execute custom command button
        self.execute_btn = ttk.Button(tools_frame, text="🚀 Execute Command", 
                                 command=self.execute_custom_command, width=20)
        self.execute_btn.pack(pady=10)
        
        # Advanced options
        advanced_frame = ttk.LabelFrame(tools_frame, text="🔧 Advanced Options", padding="5")
        advanced_frame.pack(fill=tk.X, pady=(10, 0))
        
        self.verbose_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(advanced_frame, text="Verbose Output", 
                     variable=self.verbose_var).pack(anchor=tk.W)
        
        self.release_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(advanced_frame, text="Release Build", 
                     variable=self.release_var).pack(anchor=tk.W)
        
    def create_log_viewer_section(self, parent):
        """Create comprehensive log viewer with tabs"""
        log_frame = ttk.LabelFrame(parent, text="📋 Console Output & Analysis", padding="10")
        log_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(10, 0))
        
        # Create notebook for organized viewing
        self.notebook = ttk.Notebook(log_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)
        
        # Console Output Tab
        console_frame = ttk.Frame(self.notebook)
        self.notebook.add(console_frame, text="🖥️ Console")
        
        # Console with toolbar
        console_toolbar = ttk.Frame(console_frame)
        console_toolbar.pack(fill=tk.X, pady=(0, 5))
        
        ttk.Button(console_toolbar, text="🗑️ Clear", 
                 command=self.clear_console).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(console_toolbar, text="📄 Save Log", 
                 command=self.save_log).pack(side=tk.LEFT, padx=5)
        ttk.Button(console_toolbar, text="🔍 Find", 
                 command=self.find_in_log).pack(side=tk.LEFT, padx=5)
        
        self.console_text = scrolledtext.ScrolledText(console_frame, height=20, width=100, 
                                               font=('Consolas', 10))
        self.console_text.pack(fill=tk.BOTH, expand=True)
        
        # Configure text tags for syntax highlighting
        self.configure_text_tags()
        
        # Error Analysis Tab
        analysis_frame = ttk.Frame(self.notebook)
        self.notebook.add(analysis_frame, text="🔍 Error Analysis")
        
        # Analysis toolbar
        analysis_toolbar = ttk.Frame(analysis_frame)
        analysis_toolbar.pack(fill=tk.X, pady=(0, 5))
        
        ttk.Button(analysis_toolbar, text="🔄 Refresh Analysis", 
                 command=self.refresh_analysis).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(analysis_toolbar, text="💾 Export Report", 
                 command=self.export_analysis).pack(side=tk.LEFT, padx=5)
        
        self.analysis_text = scrolledtext.ScrolledText(analysis_frame, height=20, width=100, 
                                                 font=('Consolas', 10))
        self.analysis_text.pack(fill=tk.BOTH, expand=True)
        
        # Build History Tab
        history_frame = ttk.Frame(self.notebook)
        self.notebook.add(history_frame, text="📚 Build History")
        
        # History toolbar
        history_toolbar = ttk.Frame(history_frame)
        history_toolbar.pack(fill=tk.X, pady=(0, 5))
        
        ttk.Button(history_toolbar, text="🗑️ Clear History", 
                 command=self.clear_history).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(history_toolbar, text="📄 Export History", 
                 command=self.export_history).pack(side=tk.LEFT, padx=5)
        
        # History treeview
        columns = ('Timestamp', 'Command', 'Status', 'Duration', 'Errors', 'Warnings')
        self.history_tree = ttk.Treeview(history_frame, columns=columns, show='headings', height=15)
        
        for col in columns:
            self.history_tree.heading(col, text=col)
            self.history_tree.column(col, width=140)
        
        # Scrollbar for history
        history_scroll = ttk.Scrollbar(history_frame, orient=tk.VERTICAL, command=self.history_tree.yview)
        self.history_tree.configure(yscrollcommand=history_scroll.set)
        
        self.history_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        history_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        
    def create_status_section(self, parent):
        """Create comprehensive status bar"""
        status_frame = ttk.Frame(parent)
        status_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(10, 0))
        
        # Status label
        self.status_label = ttk.Label(status_frame, text="✅ Ready", 
                                     font=('Segoe UI', 10), relief=tk.SUNKEN)
        self.status_label.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        # Progress bar
        self.progress = ttk.Progressbar(status_frame, mode='indeterminate', length=200)
        self.progress.pack(side=tk.RIGHT, padx=(10, 0))
        
        # Stop button (initially disabled)
        self.stop_button = ttk.Button(status_frame, text="⏹️ Stop", 
                                 command=self.stop_process, state=tk.DISABLED, width=10)
        self.stop_button.pack(side=tk.RIGHT, padx=(5, 0))
        
    def configure_text_tags(self):
        """Configure syntax highlighting tags"""
        self.console_text.tag_configure('INFO', foreground='#2E86AB', font=('Consolas', 10, 'bold'))
        self.console_text.tag_configure('ERROR', foreground='#E74C3C', font=('Consolas', 10, 'bold'))
        self.console_text.tag_configure('WARNING', foreground='#F39C12', font=('Consolas', 10, 'bold'))
        self.console_text.tag_configure('SUCCESS', foreground='#27AE60', font=('Consolas', 10, 'bold'))
        self.console_text.tag_configure('DEBUG', foreground='#95A5A6', font=('Consolas', 9))
        self.console_text.tag_configure('TIMESTAMP', foreground='#7F8C8D', font=('Consolas', 9))
        
    def setup_logging(self):
        """Setup logging system"""
        self.log_to_queue("🚀 iSuite Master App initialized", LogLevel.SUCCESS)
        self.log_to_queue("📁 Project path: {}".format(self.project_path), LogLevel.INFO)
        
    def log_to_queue(self, message: str, level: LogLevel = LogLevel.INFO):
        """Add message to logging queue"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        formatted_message = f"[{timestamp}] [{level.value}] {message}"
        self.log_queue.put(formatted_message)
        
    def process_log_queue(self):
        """Process log messages from queue"""
        try:
            while True:
                message = self.log_queue.get_nowait()
                self.console_text.insert(tk.END, message + '\n')
                self.console_text.see(tk.END)
                
                # Apply syntax highlighting
                if '[ERROR]' in message:
                    self.console_text.tag_add('ERROR', 'end-2l', 'end-1l')
                elif '[WARNING]' in message:
                    self.console_text.tag_add('WARNING', 'end-2l', 'end-1l')
                elif '[SUCCESS]' in message:
                    self.console_text.tag_add('SUCCESS', 'end-2l', 'end-1l')
                elif '[DEBUG]' in message:
                    self.console_text.tag_add('DEBUG', 'end-2l', 'end-1l')
                else:
                    self.console_text.tag_add('INFO', 'end-2l', 'end-1l')
                    
        except queue.Empty:
            pass
            
        # Schedule next check
        self.root.after(50, self.process_log_queue)
        
    def load_project_info(self):
        """Load and display project information"""
        try:
            pubspec_path = self.project_path / "pubspec.yaml"
            if pubspec_path.exists():
                with open(pubspec_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                # Parse project info
                name_match = re.search(r'name:\s*(.+)', content)
                version_match = re.search(r'version:\s*(.+)', content)
                
                if name_match and version_match:
                    project_name = name_match.group(1).strip()
                    version = version_match.group(1).strip()
                    self.project_label.config(text=f"📱 Project: {project_name} v{version}")
                else:
                    self.project_label.config(text="📱 Project: iSuite")
                    
            # Get Flutter version
            self.get_flutter_version()
            
        except Exception as e:
            self.project_label.config(text="❌ Error loading project info")
            self.log_to_queue(f"Error loading project info: {e}", LogLevel.ERROR)
            
    def get_flutter_version(self):
        """Get Flutter version information"""
        try:
            result = subprocess.run(['flutter', '--version'], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                version_info = result.stdout.strip()
                self.flutter_version_label.config(text=f"🐦 Flutter: {version_info}")
                self.log_to_queue(f"Flutter version: {version_info}", LogLevel.INFO)
            else:
                self.flutter_version_label.config(text="❌ Flutter: Not found")
                self.log_to_queue("Flutter not found in PATH", LogLevel.ERROR)
        except Exception as e:
            self.flutter_version_label.config(text="❌ Flutter: Error")
            self.log_to_queue(f"Error getting Flutter version: {e}", LogLevel.ERROR)
            
    # Flutter command implementations
    def build_project(self):
        """Build Flutter project"""
        command = ['build']
        if self.platform_var.get() != 'web':
            command.extend(['--{}'.format(self.platform_var.get())])
        if self.release_var.get():
            command.append('--release')
        if self.verbose_var.get():
            command.append('--verbose')
            
        self.run_flutter_command(command, "Build Project")
        
    def run_app(self):
        """Run Flutter application"""
        command = ['run']
        if self.platform_var.get() == 'web':
            command.extend(['-d', 'web-server', '--web-port=8080'])
        else:
            command.extend(['-d', self.platform_var.get()])
        if self.verbose_var.get():
            command.append('--verbose')
            
        self.run_flutter_command(command, "Run App")
        
    def clean_project(self):
        """Clean Flutter project"""
        self.run_flutter_command(['clean'], "Clean Project")
        
    def analyze_code(self):
        """Analyze Dart code"""
        self.run_flutter_command(['analyze', 'lib/'], "Analyze Code")
        
    def flutter_doctor(self):
        """Run Flutter doctor"""
        self.run_flutter_command(['doctor', '-v'], "Flutter Doctor")
        
    def get_dependencies(self):
        """Get Flutter dependencies"""
        self.run_flutter_command(['pub', 'get'], "Get Dependencies")
        
    def format_code(self):
        """Format Dart code"""
        self.run_flutter_command(['format', 'lib/'], "Format Code")
        
    def run_tests(self):
        """Run Flutter tests"""
        self.run_flutter_command(['test'], "Run Tests")
        
    def execute_custom_command(self):
        """Execute custom Flutter command"""
        command = self.command_var.get()
        if command:
            self.run_flutter_command([command], f"Execute {command}")
            
    def run_flutter_command(self, command_args: List[str], action_name: str):
        """Execute Flutter command with comprehensive error handling"""
        if self.current_process and self.current_process.poll() is None:
            messagebox.showwarning("Process Running", 
                                  "Another process is already running. Stop it first.")
            return
            
        self.update_ui_state(True)
        self.log_to_queue(f"🚀 Starting {action_name}: flutter {' '.join(command_args)}", LogLevel.INFO)
        
        # Run in separate thread
        thread = threading.Thread(target=self._execute_flutter_command, 
                                 args=(command_args, action_name))
        thread.daemon = True
        thread.start()
        
    def _execute_flutter_command(self, command_args: List[str], action_name: str):
        """Execute Flutter command and analyze output"""
        start_time = time.time()
        
        try:
            # Prepare command
            cmd = ['flutter'] + command_args
            
            # Start process
            self.current_process = subprocess.Popen(
                cmd,
                cwd=self.project_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
            
            # Read output line by line
            output_lines = []
            while True:
                output = self.current_process.stdout.readline()
                if output == '' and self.current_process.poll() is not None:
                    break
                if output:
                    output_lines.append(output.strip())
                    self.log_to_queue(output.strip())
                    
            # Get return code
            return_code = self.current_process.poll()
            
            # Analyze output
            full_output = '\n'.join(output_lines)
            analysis = self.analyzer.analyze_output(full_output, ' '.join(command_args))
            
            # Update analysis tab
            self.update_analysis_display(analysis)
            
            # Calculate duration
            duration = time.time() - start_time
            
            # Add to history
            self.add_to_history(action_name, analysis.success, duration, 
                           len(analysis.errors_found), len(analysis.warnings_found))
            
            # Log final result
            if analysis.success:
                self.log_to_queue(f"✅ {action_name} completed successfully in {duration:.2f}s", LogLevel.SUCCESS)
            else:
                self.log_to_queue(f"❌ {action_name} failed with return code {return_code}", LogLevel.ERROR)
                
            # Show suggestions if errors found
            if analysis.suggestions:
                self.log_to_queue("💡 Suggestions:", LogLevel.INFO)
                for suggestion in analysis.suggestions[:3]:  # Show top 3
                    self.log_to_queue(f"   • {suggestion}", LogLevel.INFO)
                    
        except FileNotFoundError:
            self.log_to_queue("❌ Flutter command not found. Please install Flutter SDK and add to PATH.", LogLevel.ERROR)
            self.add_to_history(action_name, False, 0, 1, 0)
        except subprocess.TimeoutExpired:
            self.log_to_queue(f"⏰ {action_name} timed out", LogLevel.ERROR)
            self.add_to_history(action_name, False, 0, 1, 0)
        except Exception as e:
            self.log_to_queue(f"❌ Error executing {action_name}: {e}", LogLevel.ERROR)
            self.add_to_history(action_name, False, 0, 1, 0)
        finally:
            self.current_process = None
            self.update_ui_state(False)
            
    def update_analysis_display(self, analysis: BuildResult):
        """Update the analysis tab with results"""
        self.analysis_text.delete(1.0, tk.END)
        
        self.analysis_text.insert(tk.END, "🔍 Flutter Command Analysis Report\n", 'heading')
        self.analysis_text.insert(tk.END, "=" * 50 + "\n\n", 'heading')
        
        # Command info
        self.analysis_text.insert(tk.END, f"Command: {analysis.command}\n", 'info')
        self.analysis_text.insert(tk.END, f"Success: {'✅ Yes' if analysis.success else '❌ No'}\n", 'success' if analysis.success else 'error')
        self.analysis_text.insert(tk.END, f"Duration: {analysis.duration:.2f}s\n\n", 'info')
        
        # Errors section
        if analysis.errors_found:
            self.analysis_text.insert(tk.END, f"🚨 Errors Found ({len(analysis.errors_found)}):\n", 'error')
            for i, error in enumerate(analysis.errors_found[:10], 1):
                self.analysis_text.insert(tk.END, f"  {i}. {error}\n", 'error')
        else:
            self.analysis_text.insert(tk.END, "✅ No errors detected!\n", 'success')
            
        # Warnings section
        if analysis.warnings_found:
            self.analysis_text.insert(tk.END, f"\n⚠️ Warnings Found ({len(analysis.warnings_found)}):\n", 'warning')
            for i, warning in enumerate(analysis.warnings_found[:10], 1):
                self.analysis_text.insert(tk.END, f"  {i}. {warning}\n", 'warning')
                
        # Suggestions section
        if analysis.suggestions:
            self.analysis_text.insert(tk.END, f"\n💡 Suggestions:\n", 'info')
            for i, suggestion in enumerate(analysis.suggestions, 1):
                self.analysis_text.insert(tk.END, f"  {i}. {suggestion}\n", 'info')
                
    def add_to_history(self, action: str, success: bool, duration: float, errors: int, warnings: int):
        """Add entry to build history"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        status = "✅ Success" if success else "❌ Failed"
        duration_str = f"{duration:.2f}s"
        
        self.history_tree.insert('', 'end', values=(timestamp, action, status, duration_str, errors, warnings))
        
    def update_ui_state(self, is_running: bool):
        """Update UI state based on process status"""
        if is_running:
            self.progress.start()
            self.status_label.config(text="🔄 Running...")
            self.stop_button.config(state=tk.NORMAL)
            self.execute_btn.config(state=tk.DISABLED)
        else:
            self.progress.stop()
            self.status_label.config(text="✅ Ready")
            self.stop_button.config(state=tk.DISABLED)
            self.execute_btn.config(state=tk.NORMAL)
            
    # UI utility methods
    def clear_console(self):
        """Clear console output"""
        self.console_text.delete(1.0, tk.END)
        self.log_to_queue("🗑️ Console cleared", LogLevel.INFO)
        
    def save_log(self):
        """Save console log to file"""
        filename = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        if filename:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(self.console_text.get(1.0, tk.END))
            self.log_to_queue(f"📄 Log saved to {filename}", LogLevel.SUCCESS)
            
    def find_in_log(self):
        """Find text in console log"""
        # Simple find dialog
        find_window = tk.Toplevel(self.root)
        find_window.title("Find in Console")
        find_window.geometry("300x100")
        
        ttk.Label(find_window, text="Find:").pack(pady=10)
        find_var = tk.StringVar()
        find_entry = ttk.Entry(find_window, textvariable=find_var, width=30)
        find_entry.pack(pady=5)
        
        def find_text():
            text = find_var.get()
            if text:
                # Simple search implementation
                content = self.console_text.get(1.0, tk.END)
                start = content.find(text)
                if start != -1:
                    end = start + len(text)
                    self.console_text.tag_remove('found')
                    self.console_text.tag_add('found', f'1.0+{start}c', f'1.0+{end}c')
                    self.console_text.tag_configure('found', background='yellow')
                    self.console_text.see(f'1.0+{start}c')
                else:
                    messagebox.showinfo("Find", "Text not found")
                    
        ttk.Button(find_window, text="Find", command=find_text).pack(pady=10)
        
    def refresh_analysis(self):
        """Refresh the analysis display"""
        self.log_to_queue("🔄 Analysis refreshed", LogLevel.INFO)
        
    def export_analysis(self):
        """Export analysis report"""
        filename = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        if filename:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(self.analysis_text.get(1.0, tk.END))
            self.log_to_queue(f"📄 Analysis exported to {filename}", LogLevel.SUCCESS)
            
    def clear_history(self):
        """Clear build history"""
        if messagebox.askyesno("Clear History", "Are you sure you want to clear all build history?"):
            for item in self.history_tree.get_children():
                self.history_tree.delete(item)
            self.log_to_queue("🗑️ Build history cleared", LogLevel.INFO)
            
    def export_history(self):
        """Export build history"""
        filename = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
        )
        if filename:
            with open(filename, 'w', encoding='utf-8') as f:
                # Write CSV header
                f.write("Timestamp,Command,Status,Duration,Errors,Warnings\n")
                # Write data
                for child in self.history_tree.get_children():
                    values = self.history_tree.item(child)['values']
                    f.write(f"{values[0]},{values[1]},{values[2]},{values[3]},{values[4]},{values[5]}\n")
            self.log_to_queue(f"📄 History exported to {filename}", LogLevel.SUCCESS)
            
    def stop_process(self):
        """Stop the current running process"""
        if self.current_process:
            try:
                self.current_process.terminate()
                self.current_process.wait(timeout=5)
                self.log_to_queue("⏹️ Process stopped successfully", LogLevel.SUCCESS)
            except subprocess.TimeoutExpired:
                self.current_process.kill()
                self.log_to_queue("⚠️ Process force killed", LogLevel.WARNING)
            except Exception as e:
                self.log_to_queue(f"❌ Error stopping process: {e}", LogLevel.ERROR)
            finally:
                self.update_ui_state(False)
                
    def create_tooltip(self, widget, text):
        """Create tooltip for widget"""
        def on_enter(event):
            tooltip = tk.Toplevel()
            tooltip.wm_overrideredirect(True)
            tooltip.wm_geometry(f"+{event.x_root+10}+{event.y_root+10}")
            label = tk.Label(tooltip, text=text, background="lightyellow", 
                           relief=tk.SOLID, borderwidth=1, font=('Segoe UI', 9))
            label.pack()
            widget.tooltip = tooltip
            
        def on_leave(event):
            if hasattr(widget, 'tooltip'):
                widget.tooltip.destroy()
                
        widget.bind("<Enter>", on_enter)
        widget.bind("<Leave>", on_leave)


def main():
    """Main entry point"""
    root = tk.Tk()
    
    # Set application icon and properties
    try:
        root.iconbitmap(default='icon.ico')
    except:
        pass  # Icon file not found, continue without it
        
    app = ISuiteMasterGUI(root)
    
    # Handle window closing
    def on_closing():
        if app.current_process:
            if messagebox.askokcancel("Quit", "A process is still running. Force quit?"):
                app.stop_process()
                root.after(1000, root.destroy)
        else:
            root.destroy()
            
    root.protocol("WM_DELETE_WINDOW", on_closing)
    
    # Start the GUI
    root.mainloop()


if __name__ == "__main__":
    main()
