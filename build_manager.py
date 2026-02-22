#!/usr/bin/env python3
"""
iSuite Enterprise Build Manager
Master GUI application for Flutter build management, testing, and deployment
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import json
import os
import sys
from datetime import datetime
from pathlib import Path
import queue

class BuildManager:
    def __init__(self, root):
        self.root = root
        self.root.title("iSuite Enterprise Build Manager")
        self.root.geometry("1200x800")
        
        # Configuration
        self.flutter_path = r"C:\flutter\bin\flutter.bat"
        self.project_path = Path(__file__).parent
        self.build_queue = queue.Queue()
        self.is_building = False
        
        # Build history
        self.build_history = []
        
        # Setup UI
        self.setup_ui()
        self.load_configuration()
        self.check_environment()
        
    def setup_ui(self):
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(2, weight=1)
        
        # Environment Section
        env_frame = ttk.LabelFrame(main_frame, text="Environment Status", padding="10")
        env_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        self.env_status = ttk.Label(env_frame, text="Checking environment...")
        self.env_status.grid(row=0, column=0, sticky=tk.W)
        
        self.flutter_version_label = ttk.Label(env_frame, text="")
        self.flutter_version_label.grid(row=0, column=1, sticky=tk.E)
        
        # Control Panel
        control_frame = ttk.LabelFrame(main_frame, text="Build Controls", padding="10")
        control_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Build buttons
        ttk.Button(control_frame, text="Flutter Doctor", command=self.run_flutter_doctor).grid(row=0, column=0, padx=5)
        ttk.Button(control_frame, text="Clean & Get", command=self.clean_and_get).grid(row=0, column=1, padx=5)
        ttk.Button(control_frame, text="Analyze", command=self.run_analyze).grid(row=0, column=2, padx=5)
        ttk.Button(control_frame, text="Format", command=self.run_format).grid(row=0, column=3, padx=5)
        ttk.Button(control_frame, text="Test", command=self.run_test).grid(row=0, column=4, padx=5)
        
        # Build buttons
        ttk.Button(control_frame, text="Build Windows", command=self.build_windows).grid(row=1, column=0, padx=5)
        ttk.Button(control_frame, text="Build APK", command=self.build_apk).grid(row=1, column=1, padx=5)
        ttk.Button(control_frame, text="Build Web", command=self.build_web).grid(row=1, column=2, padx=5)
        ttk.Button(control_frame, text="Run Windows", command=self.run_windows).grid(row=1, column=3, padx=5)
        ttk.Button(control_frame, text="Run Chrome", command=self.run_chrome).grid(row=1, column=4, padx=5)
        
        # Enterprise Build Script
        ttk.Button(control_frame, text="🚀 Enterprise Release", command=self.enterprise_release, 
                  style="Accent.TButton").grid(row=2, column=0, columnspan=5, pady=10, sticky=(tk.W, tk.E))
        
        # Output Console
        console_frame = ttk.LabelFrame(main_frame, text="Build Console", padding="10")
        console_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        self.console = scrolledtext.ScrolledText(console_frame, height=20, wrap=tk.WORD)
        self.console.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Progress bar
        self.progress = ttk.Progressbar(console_frame, mode='indeterminate')
        self.progress.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(10, 0))
        
        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(10, 0))
        
        # Configure console grid
        console_frame.columnconfigure(0, weight=1)
        console_frame.rowconfigure(0, weight=1)
        
    def log_message(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        formatted_message = f"[{timestamp}] [{level}] {message}\n"
        
        self.console.insert(tk.END, formatted_message)
        self.console.see(tk.END)
        self.root.update_idletasks()
        
        # Also log to file
        self.log_to_file(formatted_message)
        
    def log_to_file(self, message):
        log_file = self.project_path / "build_logs" / f"build_{datetime.now().strftime('%Y%m%d')}.log"
        log_file.parent.mkdir(exist_ok=True)
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(message)
    
    def run_command(self, command, description="Running command"):
        """Execute a Flutter command in a separate thread"""
        if self.is_building:
            messagebox.showwarning("Build in Progress", "Another build is already running!")
            return
            
        self.is_building = True
        self.progress.start()
        self.status_var.set(f"Running: {description}")
        
        def run_in_thread():
            try:
                self.log_message(f"🚀 Starting: {description}")
                self.log_message(f"Command: {command}")
                
                # Change to project directory
                os.chdir(self.project_path)
                
                # Run the command
                process = subprocess.Popen(
                    command,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    universal_newlines=True,
                    bufsize=1
                )
                
                # Stream output in real-time
                for line in process.stdout:
                    self.log_message(line.strip())
                
                # Wait for completion
                return_code = process.wait()
                
                if return_code == 0:
                    self.log_message(f"✅ SUCCESS: {description}")
                    self.build_history.append({
                        'timestamp': datetime.now().isoformat(),
                        'command': command,
                        'description': description,
                        'status': 'SUCCESS'
                    })
                else:
                    self.log_message(f"❌ FAILED: {description} (Return code: {return_code})", "ERROR")
                    self.build_history.append({
                        'timestamp': datetime.now().isoformat(),
                        'command': command,
                        'description': description,
                        'status': 'FAILED',
                        'return_code': return_code
                    })
                    
            except Exception as e:
                self.log_message(f"💥 EXCEPTION: {str(e)}", "ERROR")
                self.build_history.append({
                    'timestamp': datetime.now().isoformat(),
                    'command': command,
                    'description': description,
                    'status': 'EXCEPTION',
                    'error': str(e)
                })
                
            finally:
                self.is_building = False
                self.progress.stop()
                self.status_var.set("Ready")
                self.save_build_history()
        
        # Run in separate thread
        thread = threading.Thread(target=run_in_thread, daemon=True)
        thread.start()
    
    def check_environment(self):
        """Check Flutter environment"""
        def check_in_thread():
            try:
                self.log_message("🔍 Checking Flutter environment...")
                
                # Check Flutter version
                result = subprocess.run(
                    [self.flutter_path, "--version"],
                    capture_output=True,
                    text=True,
                    cwd=self.project_path
                )
                
                if result.returncode == 0:
                    version_info = result.stdout.strip()
                    self.flutter_version_label.config(text=version_info)
                    self.log_message(f"✅ Flutter detected: {version_info}")
                    
                    # Check connected devices
                    result = subprocess.run(
                        [self.flutter_path, "devices"],
                        capture_output=True,
                        text=True,
                        cwd=self.project_path
                    )
                    
                    if result.returncode == 0:
                        devices = result.stdout.strip()
                        self.log_message(f"📱 Connected devices:\n{devices}")
                    else:
                        self.log_message("⚠️ No connected devices found", "WARNING")
                        
                    self.env_status.config(text="✅ Environment Ready", foreground="green")
                    
                else:
                    self.env_status.config(text="❌ Flutter not found", foreground="red")
                    self.log_message("❌ Flutter not found or not in PATH", "ERROR")
                    
            except Exception as e:
                self.env_status.config(text="❌ Environment check failed", foreground="red")
                self.log_message(f"💥 Environment check failed: {str(e)}", "ERROR")
        
        thread = threading.Thread(target=check_in_thread, daemon=True)
        thread.start()
    
    def run_flutter_doctor(self):
        self.run_command(f"{self.flutter_path} doctor -v", "Flutter Doctor (Verbose)")
    
    def clean_and_get(self):
        self.run_command(f"{self.flutter_path} clean && {self.flutter_path} pub get", "Clean & Get Dependencies")
    
    def run_analyze(self):
        self.run_command(f"{self.flutter_path} analyze", "Static Code Analysis")
    
    def run_format(self):
        self.run_command(f'dart format .', "Code Formatting")
    
    def run_test(self):
        self.run_command(f"{self.flutter_path} test", "Run Tests")
    
    def build_windows(self):
        self.run_command(f"{self.flutter_path} build windows", "Build Windows Application")
    
    def build_apk(self):
        self.run_command(f"{self.flutter_path} build apk --split-per-abi", "Build Android APK")
    
    def build_web(self):
        self.run_command(f"{self.flutter_path} build web", "Build Web Application")
    
    def run_windows(self):
        self.run_command(f"{self.flutter_path} run -d windows", "Run on Windows")
    
    def run_chrome(self):
        self.run_command(f"{self.flutter_path} run -d chrome", "Run on Chrome")
    
    def enterprise_release(self):
        """Run the complete enterprise release script"""
        enterprise_script = f"""
echo "🚀 Starting Enterprise Release Process..."
echo "Step 1: Clean and get dependencies"
{self.flutter_path} clean
{self.flutter_path} pub get

echo "Step 2: Code formatting"
dart format .

echo "Step 3: Static analysis"
{self.flutter_path} analyze

echo "Step 4: Run tests"
{self.flutter_path} test

echo "Step 5: Build Windows release"
{self.flutter_path} build windows --release

echo "Step 6: Build Android release"
{self.flutter_path} build appbundle --release

echo "Step 7: Build Web release"
{self.flutter_path} build web --release

echo "✅ Enterprise Release Complete!"
"""
        
        self.run_command(enterprise_script, "🚀 Enterprise Release Process")
    
    def load_configuration(self):
        """Load build configuration"""
        config_file = self.project_path / "build_config.json"
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    self.flutter_path = config.get('flutter_path', self.flutter_path)
                    self.log_message(f"📋 Configuration loaded from {config_file}")
            except Exception as e:
                self.log_message(f"⚠️ Failed to load configuration: {str(e)}", "WARNING")
    
    def save_build_history(self):
        """Save build history to file"""
        history_file = self.project_path / "build_history.json"
        try:
            with open(history_file, 'w') as f:
                json.dump(self.build_history, f, indent=2)
        except Exception as e:
            self.log_message(f"⚠️ Failed to save build history: {str(e)}", "WARNING")
    
    def show_build_history(self):
        """Show build history dialog"""
        history_window = tk.Toplevel(self.root)
        history_window.title("Build History")
        history_window.geometry("800x600")
        
        # Create treeview for history
        columns = ('Timestamp', 'Command', 'Description', 'Status')
        tree = ttk.Treeview(history_window, columns=columns, show='headings')
        
        for col in columns:
            tree.heading(col, text=col)
            tree.column(col, width=150)
        
        # Add build history
        for build in self.build_history:
            tree.insert('', tk.END, values=(
                build['timestamp'],
                build['command'][:50] + '...' if len(build['command']) > 50 else build['command'],
                build['description'],
                build['status']
            ))
        
        tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Close button
        ttk.Button(history_window, text="Close", command=history_window.destroy).pack(pady=10)

def main():
    root = tk.Tk()
    app = BuildManager(root)
    
    # Add menu bar
    menubar = tk.Menu(root)
    root.config(menu=menubar)
    
    # File menu
    file_menu = tk.Menu(menubar, tearoff=0)
    menubar.add_cascade(label="File", menu=file_menu)
    file_menu.add_command(label="Show Build History", command=app.show_build_history)
    file_menu.add_separator()
    file_menu.add_command(label="Exit", command=root.quit)
    
    # Tools menu
    tools_menu = tk.Menu(menubar, tearoff=0)
    menubar.add_cascade(label="Tools", menu=tools_menu)
    tools_menu.add_command(label="Clear Console", command=lambda: app.console.delete(1.0, tk.END))
    tools_menu.add_command(label="Open Project Folder", command=lambda: os.startfile(app.project_path))
    tools_menu.add_command(label="Open Build Logs", command=lambda: os.startfile(app.project_path / "build_logs"))
    
    # Help menu
    help_menu = tk.Menu(menubar, tearoff=0)
    menubar.add_cascade(label="Help", menu=help_menu)
    help_menu.add_command(label="About", command=lambda: messagebox.showinfo("About", "iSuite Enterprise Build Manager\nVersion 1.0.0\n\nEnterprise-grade Flutter build management tool"))
    
    root.mainloop()

if __name__ == "__main__":
    main()
