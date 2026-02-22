#!/usr/bin/env python3
"""
iSuite Master Application Controller
Python GUI application for building and running Flutter app with comprehensive logging
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import time
import os
import sys
import json
from datetime import datetime
from pathlib import Path
import queue
import webbrowser

class MasterAppController:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("iSuite Master Application Controller")
        self.root.geometry("1200x800")
        self.root.configure(bg='#2b2b2b')
        
        # Application state
        self.is_running = False
        self.is_building = False
        self.build_process = None
        self.run_process = None
        
        # Logging queue
        self.log_queue = queue.Queue()
        
        # Metrics
        self.start_time = datetime.now()
        self.build_count = 0
        self.error_count = 0
        self.warning_count = 0
        
        # Setup UI
        self.setup_ui()
        
        # Start log processing
        self.process_logs()
        
        # Load configuration
        self.load_configuration()
        
    def setup_ui(self):
        """Setup the main UI components"""
        
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(1, weight=1)
        
        # Header
        self.setup_header(main_frame)
        
        # Control Panel
        self.setup_control_panel(main_frame)
        
        # Log Console
        self.setup_log_console(main_frame)
        
        # Status Bar
        self.setup_status_bar(main_frame)
        
    def setup_header(self, parent):
        """Setup header section"""
        header_frame = ttk.Frame(parent, padding="5")
        header_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Title
        title_label = ttk.Label(
            header_frame, 
            text="🚀 iSuite Master Application Controller",
            font=('Arial', 16, 'bold')
        )
        title_label.grid(row=0, column=0, sticky=tk.W)
        
        # Subtitle
        subtitle_label = ttk.Label(
            header_frame,
            text="Cross-Platform Flutter App Development & Management",
            font=('Arial', 10)
        )
        subtitle_label.grid(row=1, column=0, sticky=tk.W)
        
        # Metrics display
        metrics_frame = ttk.Frame(header_frame)
        metrics_frame.grid(row=0, column=1, sticky=tk.E, padx=(20, 0))
        
        self.uptime_label = ttk.Label(metrics_frame, text="Uptime: 00:00:00")
        self.uptime_label.grid(row=0, column=0, padx=5)
        
        self.builds_label = ttk.Label(metrics_frame, text="Builds: 0")
        self.builds_label.grid(row=0, column=1, padx=5)
        
        self.errors_label = ttk.Label(metrics_frame, text="Errors: 0")
        self.errors_label.grid(row=0, column=2, padx=5)
        
    def setup_control_panel(self, parent):
        """Setup control panel"""
        control_frame = ttk.LabelFrame(parent, text="🎮 Control Panel", padding="10")
        control_frame.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        
        # Build Section
        build_frame = ttk.Frame(control_frame)
        build_frame.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=5)
        
        ttk.Label(build_frame, text="🔨 Build Operations:", font=('Arial', 12, 'bold')).grid(row=0, column=0, sticky=tk.W)
        
        # Build buttons
        self.build_button = ttk.Button(
            build_frame, 
            text="📦 Build App",
            command=self.build_app,
            width=15
        )
        self.build_button.grid(row=1, column=0, padx=5, pady=2)
        
        self.build_debug_button = ttk.Button(
            build_frame,
            text="🐛 Build Debug",
            command=self.build_debug,
            width=15
        )
        self.build_debug_button.grid(row=1, column=1, padx=5, pady=2)
        
        self.build_release_button = ttk.Button(
            build_frame,
            text="🚀 Build Release",
            command=self.build_release,
            width=15
        )
        self.build_release_button.grid(row=1, column=2, padx=5, pady=2)
        
        # Run Section
        run_frame = ttk.Frame(control_frame)
        run_frame.grid(row=2, column=0, sticky=(tk.W, tk.E), pady=5)
        
        ttk.Label(run_frame, text="▶️ Run Operations:", font=('Arial', 12, 'bold')).grid(row=0, column=0, sticky=tk.W)
        
        self.run_button = ttk.Button(
            run_frame,
            text="🏃 Run App",
            command=self.run_app,
            width=15
        )
        self.run_button.grid(row=1, column=0, padx=5, pady=2)
        
        self.run_debug_button = ttk.Button(
            run_frame,
            text="🔍 Run Debug",
            command=self.run_debug,
            width=15
        )
        self.run_debug_button.grid(row=1, column=1, padx=5, pady=2)
        
        self.run_profile_button = ttk.Button(
            run_frame,
            text="📊 Run Profile",
            command=self.run_profile,
            width=15
        )
        self.run_profile_button.grid(row=1, column=2, padx=5, pady=2)
        
        # Test Section
        test_frame = ttk.Frame(control_frame)
        test_frame.grid(row=3, column=0, sticky=(tk.W, tk.E), pady=5)
        
        ttk.Label(test_frame, text="🧪 Test Operations:", font=('Arial', 12, 'bold')).grid(row=0, column=0, sticky=tk.W)
        
        self.test_button = ttk.Button(
            test_frame,
            text="✅ Run Tests",
            command=self.run_tests,
            width=15
        )
        self.test_button.grid(row=1, column=0, padx=5, pady=2)
        
        self.test_coverage_button = ttk.Button(
            test_frame,
            text="📈 Test Coverage",
            command=self.run_test_coverage,
            width=15
        )
        self.test_coverage_button.grid(row=1, column=1, padx=5, pady=2)
        
        self.test_integration_button = ttk.Button(
            test_frame,
            text="🔗 Integration Tests",
            command=self.run_integration_tests,
            width=15
        )
        self.test_integration_button.grid(row=1, column=2, padx=5, pady=2)
        
        # Utility Section
        utility_frame = ttk.Frame(control_frame)
        utility_frame.grid(row=4, column=0, sticky=(tk.W, tk.E), pady=5)
        
        ttk.Label(utility_frame, text="🛠️ Utility Operations:", font=('Arial', 12, 'bold')).grid(row=0, column=0, sticky=tk.W)
        
        self.clean_button = ttk.Button(
            utility_frame,
            text="🧹 Clean",
            command=self.clean_project,
            width=15
        )
        self.clean_button.grid(row=1, column=0, padx=5, pady=2)
        
        self.analyze_button = ttk.Button(
            utility_frame,
            text="🔍 Analyze",
            command=self.analyze_code,
            width=15
        )
        self.analyze_button.grid(row=1, column=1, padx=5, pady=2)
        
        self.format_button = ttk.Button(
            utility_frame,
            text="🎨 Format",
            command=self.format_code,
            width=15
        )
        self.format_button.grid(row=1, column=2, padx=5, pady=2)
        
        # Control buttons
        control_buttons_frame = ttk.Frame(control_frame)
        control_buttons_frame.grid(row=5, column=0, sticky=(tk.W, tk.E), pady=10)
        
        self.stop_button = ttk.Button(
            control_buttons_frame,
            text="⏹️ Stop",
            command=self.stop_operations,
            state=tk.DISABLED,
            width=10
        )
        self.stop_button.grid(row=0, column=0, padx=5)
        
        self.restart_button = ttk.Button(
            control_buttons_frame,
            text="🔄 Restart",
            command=self.restart_operations,
            width=10
        )
        self.restart_button.grid(row=0, column=1, padx=5)
        
        self.clear_logs_button = ttk.Button(
            control_buttons_frame,
            text="🗑️ Clear Logs",
            command=self.clear_logs,
            width=10
        )
        self.clear_logs_button.grid(row=0, column=2, padx=5)
        
        self.save_logs_button = ttk.Button(
            control_buttons_frame,
            text="💾 Save Logs",
            command=self.save_logs,
            width=10
        )
        self.save_logs_button.grid(row=0, column=3, padx=5)
        
    def setup_log_console(self, parent):
        """Setup log console"""
        log_frame = ttk.LabelFrame(parent, text="📋 Console Output", padding="10")
        log_frame.grid(row=2, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        
        # Log output area
        self.log_text = scrolledtext.ScrolledText(
            log_frame,
            height=20,
            bg='#1e1e1e',
            fg='#00ff00',
            font=('Consolas', 10),
            wrap=tk.WORD
        )
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        
        # Log controls
        log_controls_frame = ttk.Frame(log_frame)
        log_controls_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(5, 0))
        
        # Log level filter
        ttk.Label(log_controls_frame, text="Filter:").grid(row=0, column=0, padx=5)
        
        self.log_filter = ttk.Combobox(
            log_controls_frame,
            values=["All", "Info", "Warning", "Error"],
            state="readonly",
            width=10
        )
        self.log_filter.set("All")
        self.log_filter.grid(row=0, column=1, padx=5)
        
        # Search
        ttk.Label(log_controls_frame, text="Search:").grid(row=0, column=2, padx=5)
        
        self.search_entry = ttk.Entry(log_controls_frame, width=20)
        self.search_entry.grid(row=0, column=3, padx=5)
        
        self.search_button = ttk.Button(
            log_controls_frame,
            text="🔍",
            command=self.search_logs,
            width=3
        )
        self.search_button.grid(row=0, column=4, padx=5)
        
        # Auto-scroll checkbox
        self.auto_scroll_var = tk.BooleanVar(value=True)
        self.auto_scroll_check = ttk.Checkbutton(
            log_controls_frame,
            text="Auto-scroll",
            variable=self.auto_scroll_var
        )
        self.auto_scroll_check.grid(row=0, column=5, padx=5)
        
    def setup_status_bar(self, parent):
        """Setup status bar"""
        status_frame = ttk.Frame(parent, padding="5")
        status_frame.grid(row=3, column=0, sticky=(tk.W, tk.E))
        
        # Status label
        self.status_label = ttk.Label(status_frame, text="Ready", font=('Arial', 10))
        self.status_label.grid(row=0, column=0, sticky=tk.W)
        
        # Progress bar
        self.progress_bar = ttk.Progressbar(
            status_frame,
            mode='indeterminate',
            length=200
        )
        self.progress_bar.grid(row=0, column=1, padx=10)
        
        # Project info
        project_info = ttk.Label(
            status_frame,
            text=f"Project: {os.path.basename(os.getcwd())}",
            font=('Arial', 9)
        )
        project_info.grid(row=0, column=2, padx=10)
        
        # Flutter info
        flutter_info = ttk.Label(
            status_frame,
            text="Flutter: Checking...",
            font=('Arial', 9)
        )
        flutter_info.grid(row=0, column=3, padx=10)
        
        # Check Flutter version
        self.check_flutter_version(flutter_info)
        
    def log_message(self, message, level="INFO"):
        """Add message to log queue"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        formatted_message = f"[{timestamp}] [{level}] {message}"
        self.log_queue.put(formatted_message)
        
        # Update metrics
        if level == "ERROR":
            self.error_count += 1
            self.update_metrics()
        elif level == "WARNING":
            self.warning_count += 1
            self.update_metrics()
            
    def process_logs(self):
        """Process log messages from queue"""
        try:
            while True:
                try:
                    message = self.log_queue.get_nowait()
                    self.log_text.insert(tk.END, message + "\n")
                    
                    # Auto-scroll if enabled
                    if self.auto_scroll_var.get():
                        self.log_text.see(tk.END)
                        
                    # Limit log size
                    if self.log_text.index('end-1c').split('.')[0] > '1000':
                        self.log_text.delete('1.0', '100.0')
                        
                except queue.Empty:
                    break
                    
        except Exception as e:
            print(f"Error processing logs: {e}")
            
        # Schedule next processing
        self.root.after(100, self.process_logs)
        
    def execute_command(self, command, description="Executing command"):
        """Execute a command in a separate thread"""
        def run_command():
            try:
                self.log_message(f"🚀 {description}", "INFO")
                self.log_message(f"Command: {command}", "INFO")
                
                # Update UI
                self.root.after(0, lambda: self.update_status(f"Running: {description}"))
                self.root.after(0, lambda: self.progress_bar.start())
                
                # Execute command
                process = subprocess.Popen(
                    command,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )
                
                # Read output line by line
                for line in process.stdout:
                    self.log_message(line.strip())
                    
                # Wait for completion
                process.wait()
                
                # Update UI
                self.root.after(0, lambda: self.progress_bar.stop())
                self.root.after(0, lambda: self.update_status("Ready"))
                
                if process.returncode == 0:
                    self.log_message(f"✅ {description} completed successfully", "INFO")
                    self.build_count += 1
                    self.update_metrics()
                else:
                    self.log_message(f"❌ {description} failed with exit code {process.returncode}", "ERROR")
                    
            except Exception as e:
                self.log_message(f"💥 Error executing {description}: {str(e)}", "ERROR")
                self.root.after(0, lambda: self.progress_bar.stop())
                self.root.after(0, lambda: self.update_status("Error"))
                
        # Run in separate thread
        thread = threading.Thread(target=run_command, daemon=True)
        thread.start()
        
    def build_app(self):
        """Build the Flutter app"""
        self.execute_command("flutter build", "Building Flutter app")
        
    def build_debug(self):
        """Build debug version"""
        self.execute_command("flutter build debug", "Building debug version")
        
    def build_release(self):
        """Build release version"""
        self.execute_command("flutter build release", "Building release version")
        
    def run_app(self):
        """Run the Flutter app"""
        self.execute_command("flutter run", "Running Flutter app")
        
    def run_debug(self):
        """Run debug version"""
        self.execute_command("flutter run --debug", "Running debug version")
        
    def run_profile(self):
        """Run with profiling"""
        self.execute_command("flutter run --profile", "Running with profiling")
        
    def run_tests(self):
        """Run tests"""
        self.execute_command("flutter test", "Running tests")
        
    def run_test_coverage(self):
        """Run tests with coverage"""
        self.execute_command("flutter test --coverage", "Running tests with coverage")
        
    def run_integration_tests(self):
        """Run integration tests"""
        self.execute_command("flutter test integration_test/", "Running integration tests")
        
    def clean_project(self):
        """Clean the project"""
        self.execute_command("flutter clean", "Cleaning project")
        
    def analyze_code(self):
        """Analyze code"""
        self.execute_command("flutter analyze", "Analyzing code")
        
    def format_code(self):
        """Format code"""
        self.execute_command("dart format .", "Formatting code")
        
    def stop_operations(self):
        """Stop all running operations"""
        if self.build_process:
            self.build_process.terminate()
            self.build_process = None
            self.log_message("🛑 Build process stopped", "INFO")
            
        if self.run_process:
            self.run_process.terminate()
            self.run_process = None
            self.log_message("🛑 Run process stopped", "INFO")
            
    def restart_operations(self):
        """Restart operations"""
        self.stop_operations()
        self.log_message("🔄 Restarting operations...", "INFO")
        time.sleep(1)
        self.run_app()
        
    def clear_logs(self):
        """Clear log console"""
        self.log_text.delete('1.0', tk.END)
        self.log_message("🗑️ Logs cleared", "INFO")
        
    def save_logs(self):
        """Save logs to file"""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"isuite_logs_{timestamp}.txt"
            
            with open(filename, 'w') as f:
                f.write(self.log_text.get('1.0', tk.END))
                
            self.log_message(f"💾 Logs saved to {filename}", "INFO")
            messagebox.showinfo("Success", f"Logs saved to {filename}")
            
        except Exception as e:
            self.log_message(f"💥 Error saving logs: {str(e)}", "ERROR")
            messagebox.showerror("Error", f"Failed to save logs: {str(e)}")
            
    def search_logs(self):
        """Search logs"""
        search_term = self.search_entry.get()
        if not search_term:
            return
            
        # Simple search implementation
        content = self.log_text.get('1.0', tk.END)
        lines = content.split('\n')
        
        matching_lines = []
        for i, line in enumerate(lines, 1):
            if search_term.lower() in line.lower():
                matching_lines.append(f"Line {i}: {line}")
                
        if matching_lines:
            # Show search results in a new window
            search_window = tk.Toplevel(self.root)
            search_window.title("Search Results")
            search_window.geometry("800x600")
            
            search_text = scrolledtext.ScrolledText(
                search_window,
                bg='#1e1e1e',
                fg='#00ff00',
                font=('Consolas', 10)
            )
            search_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
            
            search_text.insert('1.0', '\n'.join(matching_lines))
            
        else:
            messagebox.showinfo("Search Results", "No matches found")
            
    def update_status(self, status):
        """Update status bar"""
        self.status_label.config(text=status)
        
    def update_metrics(self):
        """Update metrics display"""
        uptime = datetime.now() - self.start_time
        hours, remainder = divmod(uptime.total_seconds(), 3600)
        minutes, seconds = divmod(remainder, 60)
        
        self.uptime_label.config(text=f"Uptime: {int(hours):02d}:{int(minutes):02d}:{int(seconds):02d}")
        self.builds_label.config(text=f"Builds: {self.build_count}")
        self.errors_label.config(text=f"Errors: {self.error_count}")
        
    def check_flutter_version(self, label):
        """Check Flutter version"""
        def check_version():
            try:
                result = subprocess.run(
                    ["flutter", "--version"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                if result.returncode == 0:
                    version = result.stdout.split('\n')[0]
                    self.root.after(0, lambda: label.config(text=f"Flutter: {version}"))
                else:
                    self.root.after(0, lambda: label.config(text="Flutter: Not found"))
            except Exception:
                self.root.after(0, lambda: label.config(text="Flutter: Error checking"))
                
        thread = threading.Thread(target=check_version, daemon=True)
        thread.start()
        
    def load_configuration(self):
        """Load configuration from file"""
        config_file = "master_app_config.json"
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    
                # Apply configuration
                if 'auto_scroll' in config:
                    self.auto_scroll_var.set(config['auto_scroll'])
                    
                self.log_message("⚙️ Configuration loaded", "INFO")
                
            except Exception as e:
                self.log_message(f"💥 Error loading configuration: {str(e)}", "ERROR")
                
    def save_configuration(self):
        """Save configuration to file"""
        config = {
            'auto_scroll': self.auto_scroll_var.get(),
            'last_run': datetime.now().isoformat(),
            'build_count': self.build_count,
            'error_count': self.error_count,
        }
        
        try:
            with open("master_app_config.json", 'w') as f:
                json.dump(config, f, indent=2)
                
        except Exception as e:
            self.log_message(f"💥 Error saving configuration: {str(e)}", "ERROR")
            
    def on_closing(self):
        """Handle window closing"""
        self.save_configuration()
        self.stop_operations()
        self.root.destroy()
        
    def run(self):
        """Run the application"""
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
        
        # Initial log message
        self.log_message("🚀 iSuite Master Application Controller started", "INFO")
        self.log_message("📱 Cross-Platform Flutter Development Environment", "INFO")
        self.log_message("🔧 Build, Run, Test, and Debug Operations Available", "INFO")
        self.log_message("📊 Real-time Logging and Performance Monitoring", "INFO")
        
        self.root.mainloop()

if __name__ == "__main__":
    app = MasterAppController()
    app.run()
