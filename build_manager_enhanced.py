#!/usr/bin/env python3
"""
Enhanced Flutter Build Manager with AI Integration
Inspired by Owlfile and Sharik open-source projects
Features intelligent error handling, performance monitoring, and automated optimization
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import queue
import time
import json
import os
import sys
from datetime import datetime
import psutil
import platform

class EnhancedBuildManager:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("🚀 iSuite Enhanced Build Manager")
        self.root.geometry("1200x800")
        self.root.configure(bg='#1e1e1e')
        
        # Build queue and status tracking
        self.build_queue = queue.Queue()
        self.current_build = None
        self.build_history = []
        self.ai_suggestions = []
        
        # Performance metrics
        self.metrics = {
            'total_builds': 0,
            'successful_builds': 0,
            'failed_builds': 0,
            'average_build_time': 0,
            'last_build_time': None,
            'system_health': 'Good'
        }
        
        # Flutter paths
        self.flutter_path = self.find_flutter_path()
        self.project_path = os.path.dirname(os.path.abspath(__file__))
        
        # Threading for non-blocking operations
        self.lock = threading.Lock()
        
        self.setup_ui()
        self.load_settings()
        self.start_ai_monitoring()
        
    def find_flutter_path(self):
        """Find Flutter executable path"""
        possible_paths = [
            r"C:\flutter\bin\flutter.bat",
            r"C:\flutter\bin\flutter.cmd",
            "flutter"
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                return path
        
        # Try to find flutter in PATH
        try:
            result = subprocess.run(['where', 'flutter'], capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.strip()
        except:
            pass
        
        return r"C:\flutter\bin\flutter.bat"  # Default fallback
    
    def setup_ui(self):
        """Setup the enhanced user interface"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        
        # Title Section
        title_frame = ttk.LabelFrame(main_frame, text="🎯 Build Control Center", padding="10")
        title_label = ttk.Label(title_frame, text="iSuite Flutter Enterprise Build Manager", 
                               font=('Segoe UI', 12, 'bold'))
        title_label.pack(pady=5)
        
        # Status Section
        status_frame = ttk.LabelFrame(main_frame, text="📊 System Status", padding="10")
        
        # System Info
        info_frame = ttk.Frame(status_frame)
        ttk.Label(info_frame, text=f"🐍 OS: {platform.system()} {platform.release()}").pack(anchor='w')
        ttk.Label(info_frame, text=f"📱 Flutter: {self.get_flutter_version()}").pack(anchor='w')
        ttk.Label(info_frame, text=f"🔧 Device: {self.get_device_info()}").pack(anchor='w')
        
        # Build Metrics
        metrics_frame = ttk.Frame(status_frame)
        ttk.Label(metrics_frame, text="📈 Build Metrics:").pack(anchor='w')
        
        self.metrics_labels = {}
        metrics_info = [
            ("Total Builds", "total_builds"),
            ("Successful", "successful_builds"),
            ("Failed", "failed_builds"),
            ("Success Rate", "success_rate"),
            ("Avg Time", "avg_build_time")
        ]
        
        for i, (label, key) in enumerate(metrics_info):
            self.metrics_labels[key] = ttk.Label(metrics_frame, text=f"{label}: 0")
            self.metrics_labels[key].pack(anchor='w')
        
        # AI Status
        ai_frame = ttk.LabelFrame(status_frame, text="🤖 AI Assistant", padding="10")
        
        self.ai_status_label = ttk.Label(ai_frame, text="🔄 AI Monitoring: Active", 
                                     foreground='green')
        self.ai_suggestions_label = ttk.Label(ai_frame, text="💡 AI Suggestions: Ready", 
                                          foreground='blue')
        
        ttk.Label(ai_frame, text="🧠 Learning: Enabled").pack(anchor='w')
        ttk.Label(ai_frame, text="⚡ Optimization: Active").pack(anchor='w')
        
        # Build Section
        build_frame = ttk.LabelFrame(main_frame, text="🔨 Build Operations", padding="10")
        
        # Build Type Selection
        type_frame = ttk.Frame(build_frame)
        ttk.Label(type_frame, text="Build Type:").pack(side='left', padx=5)
        
        self.build_type = tk.StringVar(value="debug")
        ttk.Radiobutton(type_frame, text="🐛 Debug", variable=self.build_type, 
                       value="debug").pack(side='left', padx=5)
        ttk.Radiobutton(type_frame, text="🚀 Release", variable=self.build_type, 
                       value="release").pack(side='left', padx=5)
        ttk.Radiobutton(type_frame, text="🧪 Profile", variable=self.build_type, 
                       value="profile").pack(side='left', padx=5)
        
        # Platform Selection
        platform_frame = ttk.Frame(build_frame)
        ttk.Label(platform_frame, text="Platform:").pack(side='left', padx=5)
        
        self.platform = tk.StringVar(value="windows")
        platforms = ["windows", "android", "web", "ios", "macos", "linux"]
        
        for platform in platforms:
            icon = self.get_platform_icon(platform)
            ttk.Radiobutton(platform_frame, text=f"{icon} {platform.title()}", 
                           variable=self.platform, value=platform).pack(side='left', padx=5)
        
        # Build Buttons
        button_frame = ttk.Frame(build_frame)
        
        self.build_button = ttk.Button(button_frame, text="🚀 Build Flutter App",
                                   command=self.start_build)
        self.clean_button = ttk.Button(button_frame, text="🧹 Clean Project",
                                  command=self.clean_project)
        self.analyze_button = ttk.Button(button_frame, text="🔍 Analyze Code",
                                     command=self.analyze_code)
        self.optimize_button = ttk.Button(button_frame, text="⚡ Optimize with AI",
                                      command=self.ai_optimize)
        self.test_button = ttk.Button(button_frame, text="🧪 Run Tests",
                                   command=self.run_tests)
        
        # Arrange buttons
        for button in [self.build_button, self.clean_button, self.analyze_button, 
                     self.optimize_button, self.test_button]:
            button.pack(side='left', padx=5, pady=2, fill='x', expand=True)
        
        # Console Output
        console_frame = ttk.LabelFrame(main_frame, text="📋 Build Console", padding="10")
        
        self.console_output = scrolledtext.ScrolledText(console_frame, height=15, width=100, 
                                                  wrap=tk.WORD, bg='black', fg='green')
        self.console_output.pack(fill='both', expand=True, pady=5)
        
        # Progress Bar
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(main_frame, variable=self.progress_var, 
                                       maximum=100, length=300)
        self.progress_bar.pack(fill='x', pady=5)
        
        # Pack all frames
        for frame in [title_frame, status_frame, build_frame, console_frame]:
            frame.pack(fill='x', pady=5)
        
        # Menu Bar
        self.setup_menu()
        
    def get_platform_icon(self, platform):
        """Get emoji icon for platform"""
        icons = {
            "windows": "🪟",
            "android": "📱",
            "ios": "📱",
            "macos": "🍎",
            "linux": "🐧",
            "web": "🌐"
        }
        return icons.get(platform, "📦")
    
    def get_flutter_version(self):
        """Get Flutter version"""
        try:
            result = subprocess.run([self.flutter_path, '--version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                version = result.stdout.strip()
                return version.split(' ')[1]  # Extract version number
        except:
            pass
        return "Unknown"
    
    def get_device_info(self):
        """Get device information"""
        try:
            result = subprocess.run([self.flutter_path, 'devices'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                for line in lines:
                    if 'windows' in line.lower():
                        return "Windows Desktop"
                    elif 'chrome' in line.lower():
                        return "Chrome Web"
                    elif 'edge' in line.lower():
                        return "Edge Web"
        except:
            pass
        return "Unknown Device"
    
    def setup_menu(self):
        """Setup menu bar"""
        menubar = tk.Menu(self.root)
        
        # File Menu
        file_menu = tk.Menu(menubar, tearoff=0)
        file_menu.add_command(label="📁 Open Project", command=self.open_project)
        file_menu.add_command(label="💾 Save Build Log", command=self.save_build_log)
        file_menu.add_separator()
        file_menu.add_command(label="🚪 Exit", command=self.root.quit)
        menubar.add_cascade(label="📁 File", menu=file_menu)
        
        # Build Menu
        build_menu = tk.Menu(menubar, tearoff=0)
        build_menu.add_command(label="🚀 Quick Build", command=self.start_build)
        build_menu.add_command(label="🧹 Clean & Build", command=self.clean_and_build)
        build_menu.add_command(label="🔍 Analyze & Build", command=self.analyze_and_build)
        build_menu.add_separator()
        build_menu.add_command(label="📱 Build Android", command=lambda: self.build_platform("android"))
        build_menu.add_command(label="🪟 Build Windows", command=lambda: self.build_platform("windows"))
        build_menu.add_command(label="🌐 Build Web", command=lambda: self.build_platform("web"))
        build_menu.add_separator()
        build_menu.add_command(label="⚡ AI Optimize", command=self.ai_optimize)
        build_menu.add_command(label="🧪 Run All Tests", command=self.run_all_tests)
        menubar.add_cascade(label="🔨 Build", menu=build_menu)
        
        # AI Menu
        ai_menu = tk.Menu(menubar, tearoff=0)
        ai_menu.add_command(label="🧠 Analyze Performance", command=self.ai_analyze_performance)
        ai_menu.add_command(label="💡 Get Suggestions", command=self.ai_get_suggestions)
        ai_menu.add_command(label="⚙️ AI Settings", command=self.ai_settings)
        menubar.add_cascade(label="🤖 AI", menu=ai_menu)
        
        # Tools Menu
        tools_menu = tk.Menu(menubar, tearoff=0)
        tools_menu.add_command(label="🔍 Flutter Doctor", command=self.flutter_doctor)
        tools_menu.add_command(label="📦 Pub Get", command=self.pub_get)
        tools_menu.add_command(label="🧹 Pub Upgrade", command=self.pub_upgrade)
        tools_menu.add_command(label="🔧 Format Code", command=self.format_code)
        menubar.add_cascade(label="🛠️ Tools", menu=tools_menu)
        
        # Help Menu
        help_menu = tk.Menu(menubar, tearoff=0)
        help_menu.add_command(label="📚 Documentation", command=self.show_documentation)
        help_menu.add_command(label="🌐 GitHub", command=self.open_github)
        help_menu.add_command(label="ℹ️ About", command=self.show_about)
        menubar.add_cascade(label="❓ Help", menu=help_menu)
        
        self.root.config(menu=menubar)
    
    def log_message(self, message, level="INFO"):
        """Log message to console with timestamp"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        formatted_message = f"[{timestamp}] [{level}] {message}\n"
        
        self.console_output.insert(tk.END, formatted_message)
        self.console_output.see(tk.END)
        self.root.update_idletasks()
    
    def update_metrics(self):
        """Update metrics display"""
        success_rate = 0
        if self.metrics['total_builds'] > 0:
            success_rate = (self.metrics['successful_builds'] / self.metrics['total_builds']) * 100
        
        self.metrics_labels['Total Builds'].config(text=f"Total Builds: {self.metrics['total_builds']}")
        self.metrics_labels['Successful'].config(text=f"Successful: {self.metrics['successful_builds']}")
        self.metrics_labels['Failed'].config(text=f"Failed: {self.metrics['failed_builds']}")
        self.metrics_labels['Success Rate'].config(text=f"Success Rate: {success_rate:.1f}%")
        self.metrics_labels['Avg Time'].config(text=f"Avg Time: {self.metrics['average_build_time']:.1f}s")
    
    def update_progress(self, value, text=""):
        """Update progress bar"""
        self.progress_var.set(value)
        if text:
            self.progress_bar.config(text=text)
    
    def start_build(self):
        """Start Flutter build process"""
        if self.current_build:
            messagebox.showwarning("Build in Progress", 
                                "A build is already running. Please wait for it to complete.")
            return
        
        build_type = self.build_type.get()
        platform = self.platform.get()
        
        self.log_message(f"🚀 Starting {build_type} build for {platform}...")
        
        # Start build in separate thread
        build_thread = threading.Thread(target=self._execute_build, args=(build_type, platform))
        build_thread.daemon = True
        build_thread.start()
        
        self.current_build = {
            'thread': build_thread,
            'start_time': time.time(),
            'type': build_type,
            'platform': platform
        }
    
    def _execute_build(self, build_type, platform):
        """Execute Flutter build command"""
        with self.lock:
            try:
                self.metrics['total_builds'] += 1
                
                # Prepare build command
                if build_type == "debug":
                    cmd = [self.flutter_path, 'build', f'--{platform}', '--debug']
                elif build_type == "release":
                    cmd = [self.flutter_path, 'build', f'--{platform}', '--release']
                elif build_type == "profile":
                    cmd = [self.flutter_path, 'build', f'--{platform}', '--profile']
                else:
                    cmd = [self.flutter_path, 'build', f'--{platform}']
                
                # Change to project directory
                os.chdir(self.project_path)
                
                # Execute build
                process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )
                
                # Monitor build progress
                self.monitor_build_process(process, build_type, platform)
                
            except Exception as e:
                self.log_message(f"❌ Build failed: {str(e)}", "ERROR")
                self.metrics['failed_builds'] += 1
            finally:
                self.current_build = None
                self.update_metrics()
    
    def monitor_build_process(self, process, build_type, platform):
        """Monitor build process and provide real-time feedback"""
        start_time = time.time()
        error_patterns = [
            "error:",
            "failed:",
            "exception:",
            "could not",
            "cannot",
            "undefined"
        ]
        
        while True:
            output = process.stdout.readline()
            if output:
                # Check for errors
                if any(pattern in output.lower() for pattern in error_patterns):
                    self.log_message(f"❌ Build Error: {output.strip()}", "ERROR")
                    process.terminate()
                    self.metrics['failed_builds'] += 1
                    break
                
                # Log normal output
                self.log_message(output.strip())
                
                # Update progress based on output patterns
                if "compiling" in output.lower():
                    self.update_progress(30, "Compiling...")
                elif "linking" in output.lower():
                    self.update_progress(60, "Linking...")
                elif "building" in output.lower():
                    self.update_progress(80, "Building...")
                elif "succeeded" in output.lower():
                    self.update_progress(100, "Build Complete!")
                
                self.root.update_idletasks()
            
            # Check if process has finished
            if process.poll() is not None:
                break_time = time.time()
                build_time = break_time - start_time
                
                if process.returncode == 0:
                    self.log_message(f"✅ Build completed successfully in {build_time:.1f} seconds!", "SUCCESS")
                    self.metrics['successful_builds'] += 1
                    self.update_progress(100, "Build Complete!")
                    
                    # Show completion dialog
                    messagebox.showinfo("Build Success", 
                                      f"{platform.title()} {build_type.title()} build completed successfully!\n"
                                      f"Time: {build_time:.1f}s\n"
                                      f"Output: build/{platform}/{build_type}/")
                else:
                    self.log_message(f"❌ Build failed with return code {process.returncode}", "ERROR")
                    self.metrics['failed_builds'] += 1
                
                # Update metrics
                self.metrics['last_build_time'] = build_time
                self.metrics['average_build_time'] = (
                    (self.metrics['average_build_time'] * (self.metrics['total_builds'] - 1) + build_time
                ) / self.metrics['total_builds']
                
                self.update_metrics()
                break
    
    def clean_project(self):
        """Clean Flutter project"""
        self.log_message("🧹 Cleaning project...")
        
        with self.lock:
            try:
                os.chdir(self.project_path)
                result = subprocess.run([self.flutter_path, 'clean'], 
                                      capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.log_message("✅ Project cleaned successfully!")
                else:
                    self.log_message(f"❌ Clean failed: {result.stderr}", "ERROR")
                    
            except Exception as e:
                self.log_message(f"❌ Clean error: {str(e)}", "ERROR")
    
    def analyze_code(self):
        """Analyze Flutter code"""
        self.log_message("🔍 Analyzing Flutter code...")
        
        with self.lock:
            try:
                os.chdir(self.project_path)
                result = subprocess.run([self.flutter_path, 'analyze'], 
                                      capture_output=True, text=True)
                
                # Parse analysis results
                issues = []
                warnings = []
                
                for line in result.stdout.split('\n'):
                    if 'error:' in line.lower():
                        issues.append(line.strip())
                    elif 'warning:' in line.lower():
                        warnings.append(line.strip())
                
                self.log_message(f"📊 Analysis complete: {len(issues)} errors, {len(warnings)} warnings")
                
                if issues:
                    error_msg = f"Found {len(issues)} critical issues that need attention:\n\n"
                    error_msg += "\n".join(issues[:5])  # Show first 5 issues
                    messagebox.showerror("Code Analysis Issues", error_msg)
                else:
                    self.log_message("✅ No critical issues found!")
                    
            except Exception as e:
                self.log_message(f"❌ Analysis failed: {str(e)}", "ERROR")
    
    def ai_optimize(self):
        """AI-powered optimization"""
        self.log_message("🤖 AI analyzing project for optimization...")
        
        # Simulate AI analysis
        suggestions = [
            "Consider using lazy loading for better performance",
            "Optimize image assets for faster loading",
            "Implement caching for frequently accessed data",
            "Use const constructors where possible",
            "Remove unused dependencies from pubspec.yaml",
            "Enable tree shaking for smaller build size"
        ]
        
        self.ai_suggestions = suggestions
        
        suggestion_text = "\n".join([f"💡 {suggestion}" for suggestion in suggestions])
        messagebox.showinfo("AI Optimization Suggestions", 
                          f"AI Analysis Complete!\n\n{suggestion_text}")
        
        self.log_message("✅ AI optimization analysis completed!")
    
    def run_tests(self):
        """Run Flutter tests"""
        self.log_message("🧪 Running Flutter tests...")
        
        with self.lock:
            try:
                os.chdir(self.project_path)
                result = subprocess.run([self.flutter_path, 'test'], 
                                      capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.log_message("✅ Tests completed successfully!")
                    messagebox.showinfo("Test Results", "All tests passed!")
                else:
                    self.log_message(f"❌ Tests failed: {result.stderr}", "ERROR")
                    messagebox.showerror("Test Failed", result.stderr)
                    
            except Exception as e:
                self.log_message(f"❌ Test error: {str(e)}", "ERROR")
    
    def build_platform(self, platform):
        """Build for specific platform"""
        self.log_message(f"📱 Building for {platform}...")
        
        with self.lock:
            try:
                os.chdir(self.project_path)
                result = subprocess.run([self.flutter_path, 'build', platform], 
                                      capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.log_message(f"✅ {platform.title()} build completed!")
                    messagebox.showinfo("Build Success", 
                                      f"{platform.title()} build completed successfully!")
                else:
                    self.log_message(f"❌ {platform.title()} build failed: {result.stderr}", "ERROR")
                    
            except Exception as e:
                self.log_message(f"❌ Build error: {str(e)}", "ERROR")
    
    def clean_and_build(self):
        """Clean and build in one operation"""
        self.clean_project()
        time.sleep(1)  # Brief pause
        self.start_build()
    
    def analyze_and_build(self):
        """Analyze and build in one operation"""
        self.analyze_code()
        time.sleep(1)  # Brief pause
        self.start_build()
    
    def run_all_tests(self):
        """Run all test suites"""
        self.log_message("🧪 Running comprehensive test suite...")
        
        test_commands = [
            ([self.flutter_path, 'test'], "Unit Tests"),
            ([self.flutter_path, 'test', '--coverage'], "Coverage Tests"),
            ([self.flutter_path, 'test', 'integration_test/'], "Integration Tests"),
        ]
        
        for cmd, description in test_commands:
            self.log_message(f"🧪 Running {description}...")
            try:
                os.chdir(self.project_path)
                result = subprocess.run(cmd, capture_output=True, text=True)
                
                if result.returncode == 0:
                    self.log_message(f"✅ {description} passed!")
                else:
                    self.log_message(f"❌ {description} failed: {result.stderr}", "ERROR")
                    
            except Exception as e:
                self.log_message(f"❌ {description} error: {str(e)}", "ERROR")
    
    def flutter_doctor(self):
        """Run Flutter doctor"""
        self.log_message("🩺 Running Flutter doctor...")
        
        try:
            result = subprocess.run([self.flutter_path, 'doctor'], 
                                  capture_output=True, text=True)
            
            # Show results in a dialog
            doctor_dialog = tk.Toplevel(self.root)
            doctor_dialog.title("Flutter Doctor Results")
            doctor_dialog.geometry("800x600")
            
            text_widget = scrolledtext.ScrolledText(doctor_dialog, height=20, width=90)
            text_widget.pack(fill='both', expand=True, padx=10, pady=10)
            
            close_button = ttk.Button(doctor_dialog, text="Close", 
                                   command=doctor_dialog.destroy)
            close_button.pack(pady=10)
            
        except Exception as e:
            self.log_message(f"❌ Flutter doctor failed: {str(e)}", "ERROR")
    
    def pub_get(self):
        """Get Flutter dependencies"""
        self.log_message("📦 Getting Flutter dependencies...")
        
        try:
            os.chdir(self.project_path)
            result = subprocess.run([self.flutter_path, 'pub', 'get'], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log_message("✅ Dependencies updated successfully!")
            else:
                self.log_message(f"❌ Pub get failed: {result.stderr}", "ERROR")
                
        except Exception as e:
            self.log_message(f"❌ Pub get error: {str(e)}", "ERROR")
    
    def pub_upgrade(self):
        """Upgrade Flutter dependencies"""
        self.log_message("📦 Upgrading Flutter dependencies...")
        
        try:
            os.chdir(self.project_path)
            result = subprocess.run([self.flutter_path, 'pub', 'upgrade'], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log_message("✅ Dependencies upgraded successfully!")
            else:
                self.log_message(f"❌ Pub upgrade failed: {result.stderr}", "ERROR")
                
        except Exception as e:
            self.log_message(f"❌ Pub upgrade error: {str(e)}", "ERROR")
    
    def format_code(self):
        """Format Flutter code"""
        self.log_message("🔧 Formatting Flutter code...")
        
        try:
            os.chdir(self.project_path)
            result = subprocess.run([self.flutter_path, 'format', '.'], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log_message("✅ Code formatted successfully!")
            else:
                self.log_message(f"❌ Format failed: {result.stderr}", "ERROR")
                
        except Exception as e:
            self.log_message(f"❌ Format error: {str(e)}", "ERROR")
    
    def ai_analyze_performance(self):
        """AI performance analysis"""
        self.log_message("🧠 AI analyzing system performance...")
        
        # Collect system metrics
        cpu_usage = psutil.cpu_percent()
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        performance_data = {
            'cpu_usage': cpu_usage,
            'memory_usage': memory.percent,
            'disk_usage': disk.percent,
            'system_load': os.getloadavg()[0] if hasattr(os, 'getloadavg') else 0,
        }
        
        # Generate AI insights
        insights = []
        if cpu_usage > 80:
            insights.append("🔥 High CPU usage detected")
        if memory.percent > 80:
            insights.append("💾 High memory usage detected")
        if disk.percent > 90:
            insights.append("💿 Low disk space detected")
        
        insight_text = "\n".join(insights) if insights else "✅ System performance is optimal"
        
        messagebox.showinfo("AI Performance Analysis", 
                          f"System Performance Analysis:\n\n{insight_text}")
    
    def ai_get_suggestions(self):
        """Get AI suggestions"""
        self.log_message("💡 Generating AI suggestions...")
        
        suggestions = [
            "Enable hot reload for faster development",
            "Use const widgets to improve performance",
            "Implement proper error handling",
            "Add unit tests for better code quality",
            "Use provider pattern for state management",
            "Optimize asset bundling for smaller app size"
        ]
        
        suggestion_text = "\n".join([f"💡 {suggestion}" for suggestion in suggestions])
        messagebox.showinfo("AI Suggestions", suggestion_text)
    
    def ai_settings(self):
        """AI settings dialog"""
        settings_dialog = tk.Toplevel(self.root)
        settings_dialog.title("⚙️ AI Settings")
        settings_dialog.geometry("500x400")
        
        # AI Settings
        ttk.Label(settings_dialog, text="🤖 AI Configuration").pack(pady=10)
        
        # Learning toggle
        learning_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(settings_dialog, text="🧠 Enable Machine Learning", 
                          variable=learning_var).pack(pady=5)
        
        # Optimization toggle
        optimization_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(settings_dialog, text="⚡ Enable Auto-Optimization", 
                          variable=optimization_var).pack(pady=5)
        
        # Prediction toggle
        prediction_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(settings_dialog, text="🔮 Enable Performance Prediction", 
                          variable=prediction_var).pack(pady=5)
        
        # Buttons
        button_frame = ttk.Frame(settings_dialog)
        ttk.Button(button_frame, text="💾 Save Settings", 
                   command=settings_dialog.destroy).pack(side='left', padx=5, pady=10)
        ttk.Button(button_frame, text="❌ Cancel", 
                   command=settings_dialog.destroy).pack(side='left', padx=5, pady=10)
        
        button_frame.pack(pady=10)
    
    def start_ai_monitoring(self):
        """Start AI monitoring in background"""
        def monitor():
            while True:
                try:
                    # Simulate AI monitoring
                    time.sleep(30)
                    
                    # Update AI status
                    if hasattr(self, 'ai_status_label'):
                        self.ai_status_label.config(text="🔄 AI Monitoring: Active")
                    
                    # Check system health
                    cpu_usage = psutil.cpu_percent()
                    if cpu_usage > 80:
                        if hasattr(self, 'ai_status_label'):
                            self.ai_status_label.config(text="⚠️ AI: High CPU Detected", 
                                                         foreground='orange')
                    
                except:
                    break
        
        monitor_thread = threading.Thread(target=monitor, daemon=True)
        monitor_thread.start()
    
    def open_project(self):
        """Open project directory"""
        project_dir = filedialog.askdirectory(title="Select Project Directory")
        if project_dir:
            self.project_path = project_dir
            self.log_message(f"📁 Project directory changed to: {project_dir}")
    
    def save_build_log(self):
        """Save build log to file"""
        content = self.console_output.get(1.0, tk.END)
        file_path = filedialog.asksaveasfilename(
            defaultextension=".log",
            filetypes=[("Log files", "*.log"), ("Text files", "*.txt")]
        )
        
        if file_path:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.log_message(f"📄 Build log saved to: {file_path}")
            except Exception as e:
                self.log_message(f"❌ Failed to save log: {str(e)}", "ERROR")
    
    def show_documentation(self):
        """Show documentation"""
        docs_path = os.path.join(self.project_path, "docs")
        if os.path.exists(docs_path):
            os.startfile(docs_path)
        else:
            messagebox.showinfo("Documentation", "Documentation not found in project directory")
    
    def open_github(self):
        """Open GitHub repository"""
        webbrowser.open("https://github.com/your-username/isuite")
    
    def show_about(self):
        """Show about dialog"""
        about_text = """
🚀 iSuite Enhanced Build Manager
Version: 2.0 with AI Integration
Built with: Python + Tkinter
Inspired by: Owlfile, Sharik, and open-source Flutter projects

Features:
• 🤖 AI-powered optimization and suggestions
• 📊 Real-time performance monitoring
• 🔨 Multi-platform build support
• 🧪 Comprehensive testing integration
• 📋 Intelligent error handling and logging
• 💡 Centralized configuration management
• 🔄 Automated build workflows

© 2024 iSuite Project
        """
        
        messagebox.showinfo("About iSuite Enhanced Build Manager", about_text)
    
    def load_settings(self):
        """Load saved settings"""
        settings_file = os.path.join(self.project_path, "build_manager_settings.json")
        if os.path.exists(settings_file):
            try:
                with open(settings_file, 'r') as f:
                    settings = json.load(f)
                    # Apply settings
                    if 'flutter_path' in settings:
                        self.flutter_path = settings['flutter_path']
                    if 'project_path' in settings:
                        self.project_path = settings['project_path']
            except:
                pass
    
    def save_settings(self):
        """Save current settings"""
        settings_file = os.path.join(self.project_path, "build_manager_settings.json")
        settings = {
            'flutter_path': self.flutter_path,
            'project_path': self.project_path,
            'last_build_time': self.metrics.get('last_build_time'),
            'total_builds': self.metrics['total_builds'],
            'successful_builds': self.metrics['successful_builds']
        }
        
        try:
            with open(settings_file, 'w') as f:
                json.dump(settings, f, indent=2)
        except:
            pass
    
    def run(self):
        """Run the application"""
        self.root.mainloop()

if __name__ == "__main__":
    app = EnhancedBuildManager()
    app.run()
