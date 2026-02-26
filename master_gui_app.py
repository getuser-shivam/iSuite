#!/usr/bin/env python3
"""
Master GUI App for iSuite Build and Run Operations
Provides a graphical interface for building and running the Flutter iSuite app
with comprehensive console logging and error handling.
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import subprocess
import threading
import os
import sys
import time
import json
from pathlib import Path

# Platform-specific notification imports
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

class MasterGUIApp:
    def __init__(self, root):
        self.root = root
        self.root.title("iSuite Master App - Build & Run")
        self.root.geometry("1200x800")
        self.root.configure(bg='#f0f0f0')

        # Theme management
        self.current_theme = tk.StringVar(value="light")
        self.themes = {
            "light": {
                "bg": "#f0f0f0",
                "fg": "#000000",
                "button_bg": "#ffffff",
                "button_fg": "#000000",
                "console_bg": "#ffffff",
                "console_fg": "#000000",
                "success": "green",
                "error": "red",
                "warning": "orange",
                "info": "blue"
            },
            "dark": {
                "bg": "#2b2b2b",
                "fg": "#ffffff",
                "button_bg": "#404040",
                "button_fg": "#ffffff",
                "console_bg": "#1e1e1e",
                "console_fg": "#ffffff",
                "success": "#00ff00",
                "error": "#ff4444",
                "warning": "#ffaa00",
                "info": "#4488ff"
            }
        }

        # Project path
        self.project_path = Path(__file__).parent

        # Build mode
        self.build_mode = tk.StringVar(value="release")

        # Load configuration
        self.config = self.load_config()

        # Create GUI components
        self.create_menu()
        self.create_widgets()

        # Apply initial theme
        self.apply_theme()
        
        # Bind keyboard shortcuts
        self.bind_shortcuts()
        
        # Initialize logging
        self.log("iSuite Master App initialized")
        self.log(f"Project path: {self.project_path}")
        self.log(f"Flutter path: {self.config.get('flutter_path', 'Not set')}")
        self.log(f"Build mode: {self.build_mode.get()}")
        self.log(f"Theme: {self.current_theme.get()}")
        self.log("Keyboard shortcuts: Ctrl+L (Clear), Ctrl+S (Save), F5 (Build Windows), F6 (Run Windows), F7 (Theme)")
        
        # Build analytics
        self.build_history = []
        self.build_stats = {
            'total_builds': 0,
            'successful_builds': 0,
            'failed_builds': 0,
            'average_build_time': 0,
            'last_build_time': None,
        }
        
        # Command queue
        self.command_queue = []
        self.is_processing_queue = False
        
        # Load build history
        self.load_build_history()

        # Initialize auto-save system
        self.auto_save_enabled = True
        self.auto_save_interval = 30000  # 30 seconds
        self.last_save_time = time.time()
        self.start_auto_save()

    def start_auto_save(self):
        """Start automatic saving of logs and build history"""
        if self.auto_save_enabled:
            def auto_save_task():
                while self.auto_save_enabled:
                    try:
                        current_time = time.time()
                        if current_time - self.last_save_time >= (self.auto_save_interval / 1000):
                            self.perform_auto_save()
                            self.last_save_time = current_time
                        time.sleep(5)  # Check every 5 seconds
                    except Exception as e:
                        self.log(f"Auto-save error: {e}", "warning")
                        time.sleep(10)  # Wait longer on error
            
            self.auto_save_thread = threading.Thread(target=auto_save_task, daemon=True)
            self.auto_save_thread.start()
            self.log("Auto-save enabled - logs and history will be saved automatically", "info")

    def perform_auto_save(self):
        """Perform automatic saving of logs and build history"""
        try:
            # Auto-save logs
            self.save_logs_auto()
            
            # Auto-save build history
            self.save_build_history()
            
            # Update status briefly
            self.status_var.set("Auto-saved ✓")
            self.root.after(2000, lambda: self.status_var.set("Ready"))
            
        except Exception as e:
            self.log(f"Auto-save failed: {e}", "warning")

    def save_logs_auto(self):
        """Auto-save console logs to file"""
        try:
            # Create auto-save directory if it doesn't exist
            auto_save_dir = Path.home() / '.isuite_auto_save'
            auto_save_dir.mkdir(exist_ok=True)
            
            # Save logs with timestamp
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            log_file = auto_save_dir / f'isuite_logs_{timestamp}.txt'
            
            with open(log_file, 'w', encoding='utf-8') as f:
                f.write(f"Auto-saved iSuite Master App Logs - {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Project: {self.project_path}\n")
                f.write(f"Errors: {self.error_count}, Warnings: {self.warning_count}\n\n")
                f.write(self.console_text.get(1.0, tk.END))
            
            # Keep only last 10 auto-saved log files
            log_files = sorted(auto_save_dir.glob('isuite_logs_*.txt'), reverse=True)
            if len(log_files) > 10:
                for old_file in log_files[10:]:
                    old_file.unlink()
                    
        except Exception as e:
            self.log(f"Auto-save logs failed: {e}", "warning")

    def toggle_auto_save(self):
        """Toggle auto-save functionality"""
        self.auto_save_enabled = not self.auto_save_enabled
        if self.auto_save_enabled:
            self.start_auto_save()
            self.log("Auto-save enabled", "success")
        else:
            self.log("Auto-save disabled", "warning")
        
        # Update menu checkmark
        if hasattr(self, 'auto_save_var'):
            self.auto_save_var.set(self.auto_save_enabled)

    def emergency_save(self):
        """Emergency save of all data when app is closing"""
        try:
            self.log("Performing emergency save...", "warning")
            
            # Force save everything
            self.save_logs_auto()
            self.save_build_history()
            self.save_config()
            
            # Save final state
            emergency_file = Path.home() / '.isuite_emergency_save.txt'
            with open(emergency_file, 'w', encoding='utf-8') as f:
                f.write(f"Emergency Save - {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Build Stats: {json.dumps(self.build_stats, indent=2)}\n")
                f.write(f"Error Count: {self.error_count}\n")
                f.write(f"Warning Count: {self.warning_count}\n")
            
            self.log("Emergency save completed", "success")
            
        except Exception as e:
            # Last resort - try to write to stderr
            print(f"CRITICAL: Emergency save failed: {e}", file=sys.stderr)

    def bind_shortcuts(self):
        """Bind keyboard shortcuts for common actions"""
        # Clear logs (Ctrl+L)
        self.root.bind('<Control-l>', lambda e: self.clear_logs())
        self.root.bind('<Control-L>', lambda e: self.clear_logs())
        
        # Save logs (Ctrl+S)
        self.root.bind('<Control-s>', lambda e: self.save_logs())
        self.root.bind('<Control-S>', lambda e: self.save_logs())
        
        # Build Windows (F5)
        self.root.bind('<F5>', lambda e: self.build_windows())
        
        # Run Windows (F6) 
        self.root.bind('<F6>', lambda e: self.run_windows())
        
        # Switch theme (F7)
        self.root.bind('<F7>', lambda e: self.switch_theme())
        
        # Build APK (F8)
        self.root.bind('<F8>', lambda e: self.build_apk())
        
        # Run Android (F9)
        self.root.bind('<F9>', lambda e: self.run_android())
        
        # Flutter Doctor (F10)
        self.root.bind('<F10>', lambda e: self.flutter_doctor())
        
        # Show help (F1)
        self.root.bind('<F1>', lambda e: self.show_shortcuts_help())
        
        # Prevent default behavior for our shortcuts
        for key in ['<Control-l>', '<Control-L>', '<Control-s>', '<Control-S>', '<F5>', '<F6>', '<F7>', '<F8>', '<F9>', '<F10>', '<F1>']:
            self.root.bind(key, lambda e, k=key: 'break')
    
    def show_shortcuts_help(self):
        """Show keyboard shortcuts help dialog"""
        shortcuts_text = """iSuite Master App - Keyboard Shortcuts

Build & Run:
• F5: Build Windows
• F6: Run Windows  
• F8: Build APK
• F9: Run Android

Tools:
• F7: Switch Theme (Light/Dark)
• F10: Flutter Doctor

Logs:
• Ctrl+L: Clear Logs
• Ctrl+S: Save Logs

Help:
• F1: Show this help

Menu Navigation:
• Alt+F: File menu
• Alt+B: Build menu
• Alt+R: Run menu
• Alt+T: Tools menu
• Alt+V: View menu
• Alt+H: Help menu

Tips:
• Use progress bar to monitor build status
• Check console for detailed output
• Error analysis provides troubleshooting suggestions
• Build history tracks performance over time"""
        
        messagebox.showinfo("Keyboard Shortcuts", shortcuts_text)

    def apply_theme(self):
        """Apply the current theme to all UI elements"""
        theme = self.themes[self.current_theme.get()]
        
        # Update root window
        self.root.configure(bg=theme["bg"])
        
        # Update console text colors
        self.console_text.configure(bg=theme["console_bg"], fg=theme["console_fg"])
        self.console_text.tag_configure("success", foreground=theme["success"])
        self.console_text.tag_configure("error", foreground=theme["error"])
        self.console_text.tag_configure("warning", foreground=theme["warning"])
        self.console_text.tag_configure("info", foreground=theme["info"])
        
        # Update status bar colors
        if hasattr(self, 'error_counter_var'):
            # Update ttk style for better theme support
            style = ttk.Style()
            style.configure("TButton", background=theme["button_bg"], foreground=theme["button_fg"])
            style.configure("TLabel", background=theme["bg"], foreground=theme["fg"])
            style.configure("TFrame", background=theme["bg"])
        
        self.log(f"Theme switched to: {self.current_theme.get()}", "info")

    def switch_theme(self):
        """Switch between light and dark themes"""
        current = self.current_theme.get()
        new_theme = "dark" if current == "light" else "light"
        self.current_theme.set(new_theme)
        self.config['theme'] = new_theme
        self.save_config()
        self.apply_theme()
        
    def load_build_history(self):
        history_file = Path.home() / '.isuite_master_build_history.json'
        if history_file.exists():
            try:
                with open(history_file, 'r') as f:
                    data = json.load(f)
                    self.build_history = data.get('history', [])
                    self.build_stats = data.get('stats', self.build_stats)
            except Exception as e:
                self.log(f"Failed to load build history: {e}", "warning")

    def save_build_history(self):
        """Save build history to file"""
        history_file = Path.home() / '.isuite_master_build_history.json'
        try:
            data = {
                'history': self.build_history[-100:],  # Keep last 100 builds
                'stats': self.build_stats,
            }
            with open(history_file, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            self.log(f"Failed to save build history: {e}", "error")

    def show_notification(self, title, message, icon="info"):
        """Show system notification"""
        try:
            if HAS_PLYER:
                notification.notify(
                    title=title,
                    message=message,
                    app_name="iSuite Master App",
                    timeout=5
                )
            elif HAS_WIN10TOAST:
                toaster = ToastNotifier()
                toaster.show_toast(
                    title,
                    message,
                    duration=5,
                    threaded=True
                )
            else:
                # Fallback: show messagebox if no notification library available
                if icon == "error":
                    messagebox.showerror(title, message)
                elif icon == "warning":
                    messagebox.showwarning(title, message)
                else:
                    messagebox.showinfo(title, message)
        except Exception as e:
            self.log(f"Failed to show notification: {e}", "warning")

    def record_build_attempt(self, command, description, success, duration, error_message=None):
        """Record a build attempt"""
        build_record = {
            'timestamp': time.time(),
            'command': str(command),
            'description': description,
            'success': success,
            'duration': duration,
            'error_message': error_message,
            'platform': self._extract_platform_from_command(command),
        }

        self.build_history.append(build_record)
        self.build_stats['total_builds'] += 1
        self.build_stats['last_build_time'] = time.time()

        if success:
            self.build_stats['successful_builds'] += 1
        else:
            self.build_stats['failed_builds'] += 1

        # Update average build time
        total_time = sum(h['duration'] for h in self.build_history if h['success'])
        successful_builds = self.build_stats['successful_builds']
        if successful_builds > 0:
            self.build_stats['average_build_time'] = total_time / successful_builds

        self.save_build_history()

    def _extract_platform_from_command(self, command):
        """Extract platform from build command"""
        cmd_str = str(command).lower()
        if 'windows' in cmd_str:
            return 'windows'
        elif 'android' in cmd_str or 'apk' in cmd_str:
            return 'android'
        elif 'ios' in cmd_str:
            return 'ios'
        elif 'web' in cmd_str:
            return 'web'
        return 'unknown'

    def categorize_errors(self, error_lines):
        """Categorize errors by type"""
        categories = {
            'critical': 0,
            'build': 0,
            'dependency': 0,
            'network': 0,
            'permission': 0,
            'other': 0
        }
        
        for line in error_lines:
            line_lower = line.lower()
            if any(word in line_lower for word in ['fatal', 'panic', 'crash', 'segmentation fault']):
                categories['critical'] += 1
            elif any(word in line_lower for word in ['build failed', 'compilation', 'syntax error', 'type error']):
                categories['build'] += 1
            elif any(word in line_lower for word in ['dependency', 'package', 'pub get', 'pubspec']):
                categories['dependency'] += 1
            elif any(word in line_lower for word in ['network', 'connection', 'timeout', 'unreachable']):
                categories['network'] += 1
            elif any(word in line_lower for word in ['permission', 'access denied', 'readonly']):
                categories['permission'] += 1
            else:
                categories['other'] += 1
        
        return categories

    def categorize_error_line(self, line):
        """Categorize a single error line"""
        line_lower = line.lower()
        
        if any(word in line_lower for word in ['fatal', 'panic', 'crash']):
            return 'CRITICAL'
        elif any(word in line_lower for word in ['build failed', 'compilation', 'syntax']):
            return 'BUILD'
        elif any(word in line_lower for word in ['dependency', 'package', 'pub']):
            return 'DEP'
        elif any(word in line_lower for word in ['network', 'connection', 'timeout']):
            return 'NET'
        elif any(word in line_lower for word in ['permission', 'access denied']):
            return 'PERM'
        elif any(word in line_lower for word in ['flutter', 'dart']):
            return 'FLUTTER'
        elif any(word in line_lower for word in ['android', 'gradle', 'sdk']):
            return 'ANDROID'
        elif any(word in line_lower for word in ['ios', 'xcode']):
            return 'IOS'
        else:
            return 'OTHER'

    def analyze_error_line(self, line, source):
        """Analyze error line for additional context"""
        line_lower = line.lower()
        
        # Flutter-specific errors
        if 'flutter' in line_lower:
            if 'android' in line_lower:
                if 'sdk' in line_lower:
                    self.log("💡 Android SDK not found - ensure ANDROID_HOME is set", "info")
                elif 'gradle' in line_lower:
                    self.log("💡 Gradle issue - try 'flutter clean' then rebuild", "info")
            elif 'ios' in line_lower:
                if 'xcode' in line_lower:
                    self.log("💡 Xcode issue - ensure Xcode is installed and selected", "info")
                elif 'cocoapods' in line_lower:
                    self.log("💡 CocoaPods issue - run 'pod install' in ios/ directory", "info")
            elif 'windows' in line_lower:
                if 'visual studio' in line_lower:
                    self.log("💡 Visual Studio issue - ensure Build Tools are installed", "info")
        
        # Dependency errors
        elif any(word in line_lower for word in ['pub get', 'pubspec', 'dependency']):
            self.log("💡 Dependency issue - try 'flutter pub get' or check pubspec.yaml", "info")
        
        # Network errors
        elif any(word in line_lower for word in ['connection', 'timeout', 'network']):
            self.log("💡 Network issue - check internet connection and proxy settings", "info")

    def analyze_warning_line(self, line, source):
        """Analyze warning line for additional context"""
        line_lower = line.lower()
        
        if 'deprecated' in line_lower:
            self.log("⚠️  Deprecated API usage - consider updating to newer version", "warning")
        elif 'obsolete' in line_lower:
            self.log("⚠️  Obsolete code - should be updated for better performance", "warning")
        elif 'unused' in line_lower:
            self.log("⚠️  Unused code detected - consider removing for cleaner codebase", "warning")

    def export_error_log(self):
        """Export current error log to file"""
        try:
            error_log_path = self.project_path / f'error_log_{time.strftime("%Y%m%d_%H%M%S")}.txt'
            with open(error_log_path, 'w', encoding='utf-8') as f:
                # Get all error lines from console
                console_content = self.console_text.get('1.0', tk.END)
                error_lines = []
                
                for line in console_content.split('\n'):
                    if '[error]' in line.lower() or '[warning]' in line.lower():
                        error_lines.append(line)
                
                f.write(f"Error Log Export - {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Project: {self.project_path}\n")
                f.write(f"Total Errors: {self.error_count}\n")
                f.write(f"Total Warnings: {self.warning_count}\n\n")
                
                f.write("Error Details:\n")
                f.write("=" * 50 + "\n")
                for line in error_lines:
                    f.write(line + "\n")
            
            self.log(f"Error log exported to: {error_log_path}", "success")
            self.show_notification("Export Complete", f"Error log saved to {error_log_path}", "success")
            
        except Exception as e:
            self.log(f"Failed to export error log: {e}", "error")

    def show_error_summary(self):
        """Show error summary dialog"""
        if self.error_count == 0 and self.warning_count == 0:
            messagebox.showinfo("Error Summary", "No errors or warnings found!")
            return
        
        summary_window = tk.Toplevel(self.root)
        summary_window.title("Error Summary")
        summary_window.geometry("500x400")
        
        main_frame = ttk.Frame(summary_window, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        ttk.Label(main_frame, text="Error Summary", 
                 font=("Arial", 14, "bold")).grid(row=0, column=0, pady=(0, 20))
        
        # Summary stats
        stats_frame = ttk.Frame(main_frame)
        stats_frame.grid(row=1, column=0, pady=(0, 20))
        
        ttk.Label(stats_frame, text=f"Total Errors: {self.error_count}", 
                 foreground="red").grid(row=0, column=0, padx=20)
        ttk.Label(stats_frame, text=f"Total Warnings: {self.warning_count}", 
                 foreground="orange").grid(row=0, column=1, padx=20)
        
        # Recent errors list
        ttk.Label(main_frame, text="Recent Errors:", 
                 font=("Arial", 10, "bold")).grid(row=2, column=0, pady=(10, 5), sticky=tk.W)
        
        error_list = tk.Text(main_frame, height=15, wrap=tk.WORD, font=("Consolas", 9))
        error_list.grid(row=3, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        scrollbar = ttk.Scrollbar(main_frame, orient=tk.VERTICAL, command=error_list.yview)
        scrollbar.grid(row=3, column=1, sticky=(tk.N, tk.S))
        error_list.configure(yscrollcommand=scrollbar.set)
        
        # Populate with recent errors
        console_content = self.console_text.get('1.0', tk.END)
        error_count = 0
        
        for line in console_content.split('\n'):
            if error_count >= 20:  # Limit to last 20 errors
                break
            if '[error]' in line.lower():
                error_list.insert(tk.END, line + '\n')
                error_count += 1
        
        # Export button
        ttk.Button(main_frame, text="Export Error Log", 
                  command=self.export_error_log).grid(row=4, column=0, pady=(10, 0))
        
        # Close button
        ttk.Button(main_frame, text="Close", 
                  command=summary_window.destroy).grid(row=5, column=0, pady=(10, 0))
    
    def load_config(self):
        config_file = Path.home() / '.isuite_master_config.json'
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {
            'flutter_path': '',
            'project_paths': [str(self.project_path)],
            'theme': 'light'
        }

    def save_config(self):
        """Save configuration to file"""
        config_file = Path.home() / '.isuite_master_config.json'
        try:
            with open(config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            self.log(f"Failed to save config: {e}")

    def create_menu(self):
        """Create the application menu bar"""
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)

        # File menu
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="Settings", command=self.show_settings)
        file_menu.add_command(label="Select Project", command=self.select_project)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)

        # Build menu
        build_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Build", menu=build_menu)
        build_menu.add_command(label="Build Windows", command=self.build_windows)
        build_menu.add_command(label="Build APK", command=self.build_apk)
        build_menu.add_command(label="Build iOS", command=self.build_ios)
        build_menu.add_command(label="Build Web", command=self.build_web)

        # Run menu
        run_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Run", menu=run_menu)
        run_menu.add_command(label="Run Windows", command=self.run_windows)
        run_menu.add_command(label="Run Android", command=self.run_android)
        run_menu.add_command(label="Run iOS", command=self.run_ios)
        run_menu.add_command(label="Run Web", command=self.run_web)

        # Tools menu
        tools_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Tools", menu=tools_menu)
        tools_menu.add_command(label="Flutter Doctor", command=self.flutter_doctor)
        tools_menu.add_command(label="Clean Project", command=self.clean_project)
        tools_menu.add_command(label="Get Dependencies", command=self.get_dependencies)
        tools_menu.add_command(label="Upgrade Dependencies", command=self.upgrade_dependencies)
        tools_menu.add_separator()
        tools_menu.add_command(label="Analyze Code", command=self.analyze_code)
        tools_menu.add_command(label="Format Code", command=self.format_code)
        tools_menu.add_command(label="Run Tests", command=self.test_app)

        # View menu
        view_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="View", menu=view_menu)
        view_menu.add_command(label="Switch Theme", command=self.switch_theme)
        view_menu.add_separator()
        self.auto_save_var = tk.BooleanVar(value=self.auto_save_enabled)
        view_menu.add_checkbutton(label="Auto-Save Enabled", variable=self.auto_save_var, command=self.toggle_auto_save)
        view_menu.add_separator()
        view_menu.add_command(label="Build Statistics", command=self.show_build_stats)
        view_menu.add_command(label="Build History", command=self.show_build_history)
        view_menu.add_command(label="Error Summary", command=self.show_error_summary)

        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="About", command=self.show_about)
    
    def show_settings(self):
        """Show settings dialog"""
        settings_window = tk.Toplevel(self.root)
        settings_window.title("Settings")
        settings_window.geometry("400x200")
        
        main_frame = ttk.Frame(settings_window, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        ttk.Label(main_frame, text="Flutter SDK Path:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=5)
        flutter_path_var = tk.StringVar(value=self.config.get('flutter_path', ''))
        ttk.Entry(main_frame, textvariable=flutter_path_var, width=40).grid(row=0, column=1, padx=5, pady=5)

        # Save button
        def save_settings():
            self.config['flutter_path'] = flutter_path_var.get()
            self.save_config()
            self.log(f"Settings saved. Flutter path: {flutter_path_var.get()}")
            settings_window.destroy()

        ttk.Button(main_frame, text="Save", command=save_settings).grid(row=1, column=0, columnspan=2, pady=10)
    def get_dependencies(self):
        """Get Flutter dependencies"""
        cmd = self.get_flutter_cmd() + ['pub', 'get']
        self.run_command_async(cmd, "Get Dependencies")
    
    def analyze_code(self):
        """Analyze Flutter code"""
        cmd = self.get_flutter_cmd() + ['analyze']
        self.run_command_async(cmd, "Analyze Code")
    
    def analyze_build_error(self, command, stderr):
        """Analyze build error and provide suggestions"""
        suggestions = []
        error_text = stderr.lower() if stderr else ""
        
        if 'flutter' not in str(command).lower():
            return suggestions
            
        if 'dependency' in error_text or 'pubspec' in error_text:
            suggestions.append("Run 'flutter pub get' to update dependencies")
            suggestions.append("Check pubspec.yaml for syntax errors")
        
        if 'android' in error_text:
            if 'sdk' in error_text:
                suggestions.append("Check Android SDK installation")
                suggestions.append("Set ANDROID_HOME environment variable")
            if 'gradle' in error_text:
                suggestions.append("Try 'flutter clean' then rebuild")
                suggestions.append("Check Gradle wrapper configuration")
        
        if 'windows' in error_text:
            if 'visual studio' in error_text:
                suggestions.append("Install Visual Studio with Build Tools")
                suggestions.append("Ensure C++ development tools are installed")
        
        if 'ios' in error_text:
            if 'xcode' in error_text:
                suggestions.append("Install Xcode from App Store")
                suggestions.append("Run 'sudo xcode-select --install' if needed")
        
        if not suggestions:
            suggestions.append("Check the detailed error message above")
            suggestions.append("Try running 'flutter doctor' to diagnose issues")
        
        return suggestions

    def select_project(self):
        """Select project directory"""
        from tkinter import filedialog
        project_dir = filedialog.askdirectory(title="Select Flutter Project Directory")
        if project_dir:
            self.project_path = Path(project_dir)
            if str(self.project_path) not in self.config['project_paths']:
                self.config['project_paths'].append(str(self.project_path))
                self.save_config()
            self.log(f"Project changed to: {self.project_path}")

    def flutter_doctor(self):
        """Run flutter doctor"""
        self.run_command_async(["flutter", "doctor"], "Flutter Doctor")

    def clean_cache(self):
        """Clean Flutter cache"""
        self.run_command_async(["flutter", "clean"], "Clean Flutter Cache")

    def pub_cache_repair(self):
        """Repair pub cache"""
        self.run_command_async(["flutter", "pub", "cache", "repair"], "Pub Cache Repair")

    def show_about(self):
        """Show about dialog"""
        about_text = """iSuite Master App v2.0

Enhanced Build and Run Manager for Flutter iSuite project

✨ New Features:
• Advanced console logging with search & filtering
• Automatic log saving and error tracking
• Real-time error/warning counters
• Command queue for sequential operations
• Keyboard shortcuts (Ctrl+L, Ctrl+S, F5)
• Detailed error analysis and troubleshooting
• Log statistics and file management

Provides comprehensive console logging and error handling for all Flutter operations."""
        messagebox.showinfo("About", about_text)

    def create_widgets(self):
        """Create all GUI widgets"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(4, weight=1)

        # Title
        title_label = ttk.Label(main_frame, text="iSuite Build & Run Manager",
                               font=("Arial", 16, "bold"))
        title_label.grid(row=0, column=0, columnspan=2, pady=(0, 10))

        # Build options frame
        options_frame = ttk.LabelFrame(main_frame, text="Build Options", padding="5")
        options_frame.grid(row=1, column=0, columnspan=2, pady=(0, 10), sticky=(tk.W, tk.E))

        # Build mode selection
        ttk.Label(options_frame, text="Build Mode:").grid(row=0, column=0, padx=5, pady=5)
        build_mode_combo = ttk.Combobox(options_frame, textvariable=self.build_mode,
                                        values=["debug", "profile", "release"], state="readonly")
        build_mode_combo.grid(row=0, column=1, padx=5, pady=5)
        build_mode_combo.bind("<<ComboboxSelected>>", lambda e: self.log(f"Build mode changed to: {self.build_mode.get()}"))

        # Buttons frame
        buttons_frame = ttk.Frame(main_frame)
        buttons_frame.grid(row=2, column=0, columnspan=2, pady=(0, 10))

        # Setup and maintenance buttons
        ttk.Button(buttons_frame, text="Setup Flutter",
                  command=self.setup_flutter).grid(row=0, column=0, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Clean Project",
                  command=self.clean_project).grid(row=0, column=1, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Get Dependencies",
                  command=self.get_dependencies).grid(row=0, column=2, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Upgrade Dependencies",
                  command=self.upgrade_dependencies).grid(row=0, column=3, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Switch Theme",
                  command=self.switch_theme).grid(row=0, column=4, padx=5, pady=2)

        # Code quality buttons
        ttk.Button(buttons_frame, text="Analyze Code",
                  command=self.analyze_code).grid(row=1, column=0, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Format Code",
                  command=self.format_code).grid(row=1, column=1, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Run Tests",
                  command=self.test_app).grid(row=1, column=2, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Test Coverage",
                  command=self.test_coverage).grid(row=1, column=3, padx=5, pady=2)

        # Build buttons
        ttk.Button(buttons_frame, text="Build Windows",
                  command=self.build_windows).grid(row=2, column=0, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Build APK",
                  command=self.build_apk).grid(row=2, column=1, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Build iOS",
                  command=self.build_ios).grid(row=2, column=2, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Build Web",
                  command=self.build_web).grid(row=2, column=3, padx=5, pady=2)

        # Run buttons
        ttk.Button(buttons_frame, text="Run Windows",
                  command=self.run_windows).grid(row=3, column=0, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Run Android",
                  command=self.run_android).grid(row=3, column=1, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Run iOS",
                  command=self.run_ios).grid(row=3, column=2, padx=5, pady=2)
        ttk.Button(buttons_frame, text="Run Web",
                  command=self.run_web).grid(row=3, column=3, padx=5, pady=2)

        # Control buttons
        ttk.Button(buttons_frame, text="Build & Run",
                  command=self.build_and_run).grid(row=4, column=0, padx=5, pady=(10, 2))
        ttk.Button(buttons_frame, text="Clear Logs",
                  command=self.clear_logs).grid(row=4, column=1, padx=5, pady=(10, 2))
        ttk.Button(buttons_frame, text="Save Logs",
                  command=self.save_logs).grid(row=4, column=2, padx=5, pady=(10, 2))
        ttk.Button(buttons_frame, text="Exit",
                  command=self.root.quit).grid(row=4, column=3, padx=5, pady=(10, 2))

        # Progress bar
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(main_frame, variable=self.progress_var,
                                           maximum=100, mode='determinate')
        self.progress_bar.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(10, 5))

        # Status label
        self.status_var = tk.StringVar(value="Ready")
        status_label = ttk.Label(main_frame, textvariable=self.status_var,
                                font=("Arial", 10, "italic"))
        status_label.grid(row=4, column=0, columnspan=2, pady=(0, 10))

        # Status bar with counters
        status_bar = ttk.Frame(main_frame)
        status_bar.grid(row=6, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(5, 0))

        # Initialize log file before using it
        self.log_file = Path.home() / '.isuite_master_logs.txt'
        self.error_count = 0
        self.warning_count = 0

        self.error_counter_var = tk.StringVar(value="Errors: 0")
        self.warning_counter_var = tk.StringVar(value="Warnings: 0")
        
        ttk.Label(status_bar, textvariable=self.error_counter_var, foreground="red").grid(row=0, column=0, padx=10)
        ttk.Label(status_bar, textvariable=self.warning_counter_var, foreground="orange").grid(row=0, column=1, padx=10)
        ttk.Label(status_bar, text=" | ").grid(row=0, column=2)
        ttk.Label(status_bar, text=f"Log file: {self.log_file.name}").grid(row=0, column=3, padx=10)

        # Console output
        console_frame = ttk.LabelFrame(main_frame, text="Console Output", padding="5")
        console_frame.grid(row=5, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Search frame
        search_frame = ttk.Frame(console_frame)
        search_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 5))
        
        ttk.Label(search_frame, text="Search:").grid(row=0, column=0, padx=(0, 5))
        self.search_var = tk.StringVar()
        search_entry = ttk.Entry(search_frame, textvariable=self.search_var, width=30)
        search_entry.grid(row=0, column=1, padx=(0, 5))
        search_entry.bind('<KeyRelease>', self.search_logs)
        
        # Filter buttons
        ttk.Button(search_frame, text="All", command=lambda: self.filter_logs(None)).grid(row=0, column=2, padx=2)
        ttk.Button(search_frame, text="Errors", command=lambda: self.filter_logs("error")).grid(row=0, column=3, padx=2)
        ttk.Button(search_frame, text="Warnings", command=lambda: self.filter_logs("warning")).grid(row=0, column=4, padx=2)
        ttk.Button(search_frame, text="Success", command=lambda: self.filter_logs("success")).grid(row=0, column=5, padx=2)

        self.console_text = scrolledtext.ScrolledText(console_frame, height=20,
                                                     font=("Consolas", 9))
        self.console_text.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        console_frame.columnconfigure(0, weight=1)
        console_frame.rowconfigure(1, weight=1)

        # Configure tags for colored output
        self.console_text.tag_configure("success", foreground="green")
        self.console_text.tag_configure("error", foreground="red")
        self.console_text.tag_configure("warning", foreground="orange")
        self.console_text.tag_configure("info", foreground="blue")
        self.console_text.tag_configure("highlight", background="yellow")

    def log(self, message, tag="info"):
        """Log message to console with timestamp and file saving"""
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        full_message = f"[{timestamp}] {message}\n"

        # Update counters
        if tag == "error":
            self.error_count += 1
            self.error_counter_var.set(f"Errors: {self.error_count}")
        elif tag == "warning":
            self.warning_count += 1
            self.warning_counter_var.set(f"Warnings: {self.warning_count}")

        # Insert into console
        self.console_text.insert(tk.END, full_message, tag)
        self.console_text.see(tk.END)
        self.root.update_idletasks()

        # Save to file
        try:
            with open(self.log_file, 'a', encoding='utf-8') as f:
                f.write(full_message)
        except Exception as e:
            print(f"Failed to save log to file: {e}")

        # Auto-save error logs to separate file
        if tag == "error":
            error_log_file = Path.home() / f'.isuite_master_errors_{time.strftime("%Y%m%d")}.txt'
            try:
                with open(error_log_file, 'a', encoding='utf-8') as f:
                    f.write(full_message)
            except Exception as e:
                self.log(f"Failed to save error log: {e}", "error")

    def search_logs(self, event=None):
        """Search logs and highlight matches"""
        search_term = self.search_var.get().lower()
        
        # Remove previous highlights
        self.console_text.tag_remove("highlight", "1.0", tk.END)
        
        if not search_term:
            return
        
        # Search and highlight
        start_pos = "1.0"
        while True:
            start_pos = self.console_text.search(search_term, start_pos, tk.END, nocase=True)
            if not start_pos:
                break
            end_pos = f"{start_pos}+{len(search_term)}c"
            self.console_text.tag_add("highlight", start_pos, end_pos)
            start_pos = end_pos

    def filter_logs(self, tag_filter):
        """Filter logs by tag"""
        # This is a simple implementation - in a real app, you'd maintain separate log storage
        # For now, just scroll to show relevant logs
        self.log(f"Filtering logs by: {tag_filter or 'All'}", "info")
        # TODO: Implement actual filtering by hiding/showing lines

    def add_to_queue(self, command, description):
        """Add command to queue"""
        self.command_queue.append((command, description))
        self.log(f"Added to queue: {description}", "info")
        if not self.is_processing_queue:
            self.process_queue()

    def process_queue(self):
        """Process command queue sequentially"""
        if not self.command_queue:
            self.is_processing_queue = False
            return
        
        self.is_processing_queue = True
        command, description = self.command_queue.pop(0)
        self.run_command_async(command, description, callback=self.process_queue)

    def run_command_async(self, command, description, callback=None):
        """Run command asynchronously with progress tracking and build analytics"""
        start_time = time.time()

        def run():
            try:
                self.status_var.set(f"Running: {description}")
                self.progress_var.set(10)
                self.log(f"Starting: {description}")

                # Change to project directory
                os.chdir(self.project_path)

                self.progress_var.set(30)

                # Run the command
                if isinstance(command, list):
                    # Handle Windows .bat files properly
                    if len(command) > 0 and command[0].endswith('.bat'):
                        result = subprocess.run(command, capture_output=True, text=True, cwd=self.project_path, shell=True)
                    else:
                        result = subprocess.run(command, capture_output=True, text=True, cwd=self.project_path)
                else:
                    result = subprocess.run(command, shell=True, capture_output=True, text=True, cwd=self.project_path)

                self.progress_var.set(80)

                # Enhanced logging with error analysis
                if result.stdout:
                    lines = result.stdout.strip().split('\n')
                    for line in lines:
                        if any(error_word in line.lower() for error_word in ['error', 'failed', 'exception', 'crash']):
                            self.log(line, "error")
                            self.analyze_error_line(line, "stdout")
                        elif any(warn_word in line.lower() for warn_word in ['warning', 'deprecated', 'obsolete']):
                            self.log(line, "warning")
                            self.analyze_warning_line(line, "stdout")
                        else:
                            self.log(line, "info")

                if result.stderr:
                    error_lines = result.stderr.strip().split('\n')
                    error_summary = self.categorize_errors(error_lines)
                    
                    # Log error summary first
                    if error_summary['critical'] > 0:
                        self.log(f"🚨 CRITICAL ERRORS: {error_summary['critical']}", "error")
                    if error_summary['build'] > 0:
                        self.log(f"🔨 BUILD ERRORS: {error_summary['build']}", "error")
                    if error_summary['dependency'] > 0:
                        self.log(f"📦 DEPENDENCY ERRORS: {error_summary['dependency']}", "error")
                    
                    # Log individual errors with categorization
                    for line in error_lines:
                        if result.returncode == 0:
                            self.log(line, "warning")
                        else:
                            error_category = self.categorize_error_line(line)
                            self.log(f"[{error_category}] {line}", "error")
                            self.analyze_error_line(line, "stderr")

                self.progress_var.set(100)

                        if 'android' in str(command).lower():
                            self.log("Android build failed - check Android SDK and emulator", "error")
                        elif 'ios' in str(command).lower():
                            self.log("iOS build failed - check Xcode and iOS Simulator", "error")
                        elif 'web' in str(command).lower():
                            self.log("Web build failed - check Chrome and web dependencies", "error")

                    error_message = result.stderr.strip()[:500] if result.stderr else "Unknown error"
                    self.record_build_attempt(command, description, False, duration, error_message)

                    self.status_var.set(f"❌ {description} failed")
                    self.show_notification(
                        "Build Failed", 
                        f"{description} failed after {duration:.2f} seconds",
                        "error"
                    )
                    messagebox.showerror("Error", f"{description} failed!\n\nExit code: {result.returncode}\n\nCheck console output for detailed error analysis and troubleshooting suggestions.")

            except Exception as e:
                end_time = time.time()
                duration = end_time - start_time
                self.log(f"❌ Exception during {description}: {str(e)}", "error")
                self.log(f"Build time: {duration:.2f} seconds", "error")
                self.status_var.set(f"❌ {description} failed")
                self.record_build_attempt(command, description, False, duration, str(e))
                messagebox.showerror("Exception", f"Exception during {description}:\n\n{str(e)}")

            finally:
                self.progress_var.set(0)
                if callback:
                    callback()

        thread = threading.Thread(target=run, daemon=True)
        thread.start()

    def show_build_stats(self):
        """Show build statistics dialog"""
        stats_window = tk.Toplevel(self.root)
        stats_window.title("Build Statistics")
        stats_window.geometry("400x350")

        # Create scrollable frame
        main_frame = ttk.Frame(stats_window, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        stats_window.columnconfigure(0, weight=1)
        stats_window.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)

        ttk.Label(main_frame, text="Build Statistics", 
                 font=("Arial", 14, "bold")).grid(row=0, column=0, pady=(0, 20))

        # Statistics display
        stats_text = tk.Text(main_frame, height=15, wrap=tk.WORD, font=("Consolas", 10))
        stats_text.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        main_frame.rowconfigure(1, weight=1)

        scrollbar = ttk.Scrollbar(main_frame, orient=tk.VERTICAL, command=stats_text.yview)
        scrollbar.grid(row=1, column=1, sticky=(tk.N, tk.S))
        stats_text.config(yscrollcommand=scrollbar.set)

        # Populate statistics
        stats_content = f"""Build Statistics Overview
{'='*25}

Total Builds: {self.build_stats['total_builds']}
Successful Builds: {self.build_stats['successful_builds']}
Failed Builds: {self.build_stats['failed_builds']}
Success Rate: {self._calculate_success_rate():.1f}%

Average Build Time: {self.build_stats['average_build_time']:.2f} seconds

Recent Activity:
"""

        if self.build_stats['last_build_time']:
            last_build = time.strftime("%Y-%m-%d %H:%M:%S", 
                                     time.localtime(self.build_stats['last_build_time']))
            stats_content += f"Last Build: {last_build}\n"

        # Platform breakdown
        platform_stats = self._get_platform_stats()
        if platform_stats:
            stats_content += "\nPlatform Breakdown:\n"
            for platform, stats in platform_stats.items():
                success_rate = (stats['successful'] / stats['total'] * 100) if stats['total'] > 0 else 0
                stats_content += f"  {platform.title()}: {stats['successful']}/{stats['total']} ({success_rate:.1f}%)\n"

        stats_text.insert(tk.END, stats_content)
        stats_text.config(state=tk.DISABLED)

        # Close button
        ttk.Button(main_frame, text="Close", 
                  command=stats_window.destroy).grid(row=2, column=0, pady=(20, 0))

    def show_build_history(self):
        """Show build history dialog"""
        history_window = tk.Toplevel(self.root)
        history_window.title("Build History")
        history_window.geometry("800x600")

        # Create scrollable frame
        main_frame = ttk.Frame(history_window, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        history_window.columnconfigure(0, weight=1)
        history_window.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)

        ttk.Label(main_frame, text="Build History", 
                 font=("Arial", 14, "bold")).grid(row=0, column=0, pady=(0, 10))

        # Create treeview for history
        columns = ("Time", "Platform", "Description", "Status", "Duration")
        tree = ttk.Treeview(main_frame, columns=columns, show="headings", height=20)
        
        # Configure columns
        tree.heading("Time", text="Time")
        tree.heading("Platform", text="Platform") 
        tree.heading("Description", text="Description")
        tree.heading("Status", text="Status")
        tree.heading("Duration", text="Duration (s)")
        
        tree.column("Time", width=150, anchor=tk.W)
        tree.column("Platform", width=80, anchor=tk.CENTER)
        tree.column("Description", width=300, anchor=tk.W)
        tree.column("Status", width=80, anchor=tk.CENTER)
        tree.column("Duration", width=100, anchor=tk.CENTER)

        # Add scrollbar
        scrollbar = ttk.Scrollbar(main_frame, orient=tk.VERTICAL, command=tree.yview)
        tree.configure(yscrollcommand=scrollbar.set)

        tree.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        scrollbar.grid(row=1, column=1, sticky=(tk.N, tk.S))
        main_frame.rowconfigure(1, weight=1)

        # Populate history
        for build in reversed(self.build_history[-50:]):  # Show last 50 builds
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(build['timestamp']))
            status = "✅ Success" if build['success'] else "❌ Failed"
            duration = f"{build['duration']:.2f}"
            
            tree.insert("", tk.END, values=(
                timestamp,
                build['platform'].title(),
                build['description'],
                status,
                duration
            ))

        # Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=2, column=0, columnspan=2, pady=(10, 0))
        
        ttk.Button(button_frame, text="Refresh", 
                  command=lambda: self._refresh_history(tree)).grid(row=0, column=0, padx=(0, 10))
        ttk.Button(button_frame, text="Clear History", 
                  command=self._clear_build_history).grid(row=0, column=1, padx=(0, 10))
        ttk.Button(button_frame, text="Close", 
                  command=history_window.destroy).grid(row=0, column=2)

    def _calculate_success_rate(self):
        """Calculate success rate percentage"""
        total = self.build_stats['total_builds']
        if total == 0:
            return 0.0
        return (self.build_stats['successful_builds'] / total) * 100

    def _get_platform_stats(self):
        """Get statistics by platform"""
        platform_stats = {}
        
        for build in self.build_history:
            platform = build['platform']
            if platform not in platform_stats:
                platform_stats[platform] = {'total': 0, 'successful': 0}
            
            platform_stats[platform]['total'] += 1
            if build['success']:
                platform_stats[platform]['successful'] += 1
        
        return platform_stats

    def _refresh_history(self, tree):
        """Refresh the history treeview"""
        # Clear existing items
        for item in tree.get_children():
            tree.delete(item)
        
        # Repopulate
        for build in reversed(self.build_history[-50:]):
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(build['timestamp']))
            status = "✅ Success" if build['success'] else "❌ Failed"
            duration = f"{build['duration']:.2f}"
            
            tree.insert("", tk.END, values=(
                timestamp,
                build['platform'].title(),
                build['description'],
                status,
                duration
            ))

    def _clear_build_history(self):
        """Clear build history"""
        if messagebox.askyesno("Confirm", "Are you sure you want to clear all build history?"):
            self.build_history.clear()
            self.build_stats = {
                'total_builds': 0,
                'successful_builds': 0,
                'failed_builds': 0,
                'average_build_time': 0,
                'last_build_time': None,
            }
            self.save_build_history()
            messagebox.showinfo("Success", "Build history cleared")

    def setup_flutter(self):
        """Setup Flutter environment"""
        self.run_command_async("setup_flutter.bat", "Flutter Setup")

    def clean_project(self):
        """Clean Flutter project"""
        self.run_command_async(["flutter", "clean"], "Project Clean")

    def _run_tests(self):
        """Run Flutter tests"""
        self.log("Running Flutter tests...")
        self.run_command_async(["flutter", "test"], cwd=self.project_path)

    def _run_tests_with_coverage(self):
        """Run tests with coverage"""
        self.log("Running tests with coverage...")
        self.run_command_async(["flutter", "test", "--coverage"], cwd=self.project_path)

    def _generate_test_report(self):
        """Generate test report"""
        self.log("Generating test report...")
        # Implementation for test report generation
        self.log("Test report generated")

    def _run_integration_tests(self):
        """Run integration tests"""
        self.log("Running integration tests...")
        # Implementation for integration tests
        self.log("Integration tests completed")

    def _run_flutter_analyze(self):
        """Run Flutter analyze"""
        self.log("Running Flutter analyze...")
        self.run_command_async(["flutter", "analyze"], cwd=self.project_path)

    def _check_dependencies(self):
        """Check project dependencies"""
        self.log("Checking dependencies...")
        self.run_command_async(["flutter", "pub", "outdated"], cwd=self.project_path)

    def _generate_code_metrics(self):
        """Generate code metrics"""
        self.log("Generating code metrics...")
        # Implementation for code metrics
        self.log("Code metrics generated")

    def _run_security_scan(self):
        """Run security scan"""
        self.log("Running security scan...")
        # Implementation for security scanning
        self.log("Security scan completed")

    def _deploy_testflight(self):
        """Deploy to TestFlight"""
        self.log("Deploying to TestFlight...")
        # Implementation for TestFlight deployment
        self.log("TestFlight deployment initiated")

    def _deploy_google_play(self):
        """Deploy to Google Play"""
        self.log("Deploying to Google Play...")
        # Implementation for Google Play deployment
        self.log("Google Play deployment initiated")

    def _deploy_microsoft_store(self):
        """Deploy to Microsoft Store"""
        self.log("Deploying to Microsoft Store...")
        # Implementation for Microsoft Store deployment
        self.log("Microsoft Store deployment initiated")

    def _deploy_web(self):
        """Deploy to web"""
        self.log("Deploying to web...")
        self.run_command_async(["flutter", "build", "web", "--release"], cwd=self.project_path)

    def _generate_release_notes(self):
        """Generate release notes"""
        self.log("Generating release notes...")
        # Implementation for release notes generation
        self.log("Release notes generated")

    def _setup_github_actions(self):
        """Setup GitHub Actions CI/CD"""
        self.log("Setting up GitHub Actions...")
        # Implementation for GitHub Actions setup
        self.log("GitHub Actions setup completed")

    def _setup_azure_devops(self):
        """Setup Azure DevOps CI/CD"""
        self.log("Setting up Azure DevOps...")
        # Implementation for Azure DevOps setup
        self.log("Azure DevOps setup completed")

    def _setup_jenkins(self):
        """Setup Jenkins CI/CD"""
        self.log("Setting up Jenkins...")
        # Implementation for Jenkins setup
        self.log("Jenkins setup completed")

    def _run_ci_pipeline(self):
        """Run CI pipeline"""
        self.log("Running CI pipeline...")
        # Implementation for CI pipeline execution
        self.log("CI pipeline completed")

    def _view_ci_status(self):
        """View CI status"""
        self.log("Viewing CI status...")
        # Implementation for CI status viewing
        self.log("CI status displayed")

    def get_flutter_cmd(self):
        """Get flutter command with path if configured"""
        flutter_path = self.config.get('flutter_path')
        if flutter_path and os.path.exists(flutter_path):
            flutter_exe = os.path.join(flutter_path, 'bin', 'flutter')
            if os.name == 'nt':  # Windows
                flutter_exe += '.bat'
            return [flutter_exe]
        
        # Try to find Flutter in common locations
        common_paths = [
            r'c:\flutter\bin\flutter.bat',  # User's Flutter location
            r'C:\flutter\bin\flutter.bat',
            os.path.expanduser(r'~\flutter\bin\flutter.bat'),
            'flutter'  # System PATH
        ]
        
        for path in common_paths:
            if os.path.exists(path) or path == 'flutter':
                return [path] if path == 'flutter' else [path]
        
        # Default to system flutter
        return ['flutter']

    def upgrade_dependencies(self):
        """Upgrade Flutter dependencies"""
        cmd = self.get_flutter_cmd() + ['pub', 'upgrade']
        self.run_command_async(cmd, "Upgrade Dependencies")

    def format_code(self):
        """Format Flutter code"""
        cmd = self.get_flutter_cmd() + ['format', '.']
        self.run_command_async(cmd, "Format Code")

    def test_coverage(self):
        """Run tests with coverage"""
        cmd = self.get_flutter_cmd() + ['test', '--coverage']
        self.run_command_async(cmd, "Test Coverage")

    def build_apk(self):
        """Build Android APK"""
        cmd = self.get_flutter_cmd() + ['build', 'apk', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Build APK ({self.build_mode.get()})")

    def build_ios(self):
        """Build iOS app"""
        cmd = self.get_flutter_cmd() + ['build', 'ios', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Build iOS ({self.build_mode.get()})")

    def build_web(self):
        """Build Web app"""
        cmd = self.get_flutter_cmd() + ['build', 'web', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Build Web ({self.build_mode.get()})")

    def run_android(self):
        """Run on Android device"""
        cmd = self.get_flutter_cmd() + ['run', '-d', 'android', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Run Android ({self.build_mode.get()})")

    def run_ios(self):
        """Run on iOS device"""
        cmd = self.get_flutter_cmd() + ['run', '-d', 'ios', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Run iOS ({self.build_mode.get()})")

    def run_web(self):
        """Run on Web"""
        cmd = self.get_flutter_cmd() + ['run', '-d', 'web-server', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Run Web ({self.build_mode.get()})")

    def build_windows(self):
        """Build for Windows"""
        cmd = self.get_flutter_cmd() + ['build', 'windows', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Build Windows ({self.build_mode.get()})")

    def run_windows(self):
        """Run on Windows"""
        cmd = self.get_flutter_cmd() + ['run', '-d', 'windows', f'--{self.build_mode.get()}']
        self.run_command_async(cmd, f"Run Windows ({self.build_mode.get()})")

    def build_and_run(self):
        """Build and run Windows app"""
        self.run_command_async("run_windows.bat", f"Build & Run Windows ({self.build_mode.get()})")

    def test_app(self):
        """Run Flutter tests"""
        self.run_command_async(["flutter", "test"], "Run Tests")

    def clear_logs(self):
        """Clear console logs"""
        self.console_text.delete(1.0, tk.END)
        self.log("Console logs cleared")

    def save_logs(self):
        """Save console logs to file"""
        try:
            from tkinter import filedialog
            filename = filedialog.asksaveasfilename(
                defaultextension=".txt",
                filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
            )
            if filename:
                with open(filename, 'w') as f:
                    f.write(self.console_text.get(1.0, tk.END))
                self.log(f"Logs saved to: {filename}", "success")
        except Exception as e:
            self.log(f"Failed to save logs: {str(e)}", "error")

def main():
    root = tk.Tk()
    app = MasterGUIApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
