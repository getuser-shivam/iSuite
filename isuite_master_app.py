#!/usr/bin/env python3
"""
iSuite Master App - Python GUI for Build and Run Management
Comprehensive tool for managing Flutter project builds, runs, and continuous improvement
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path
import queue
import logging
from typing import Dict, List, Optional, Tuple

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('isuite_master.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class BuildManager:
    """Manages Flutter build processes with comprehensive logging and error handling"""
    
    def __init__(self, project_path: str):
        self.project_path = Path(project_path)
        self.build_queue = queue.Queue()
        self.is_building = False
        self.build_history = []
        self.error_patterns = {
            'compilation_error': ['error:', 'Error:', 'ERROR:'],
            'dependency_error': ['failed:', 'Failed:', 'FAILED:'],
            'permission_error': ['permission denied', 'Permission denied', 'access denied'],
            'flutter_error': ['FlutterError', 'flutter:'],
            'import_error': ['import error', 'ImportError'],
        }
        
    def validate_flutter_project(self) -> Tuple[bool, str]:
        """Validate if the directory is a proper Flutter project"""
        try:
            pubspec_path = self.project_path / 'pubspec.yaml'
            if not pubspec_path.exists():
                return False, "pubspec.yaml not found - not a Flutter project"
            
            # Check for Flutter SDK
            result = subprocess.run(
                ['flutter', '--version'],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode != 0:
                return False, "Flutter SDK not found or not working"
                
            return True, "Flutter project validated successfully"
        except Exception as e:
            return False, f"Validation error: {str(e)}"
    
    def run_flutter_command(self, command: List[str], output_callback=None) -> Tuple[bool, str]:
        """Execute Flutter command with comprehensive logging"""
        try:
            logger.info(f"Executing Flutter command: {' '.join(command)}")
            
            process = subprocess.Popen(
                command,
                cwd=self.project_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            output_lines = []
            error_detected = False
            error_details = []
            
            for line in iter(process.stdout.readline, ''):
                if line:
                    output_lines.append(line.strip())
                    
                    # Detect errors in real-time
                    if any(pattern in line for patterns in self.error_patterns.values() for pattern in patterns):
                        error_detected = True
                        error_details.append(line.strip())
                    
                    # Send output to callback if provided
                    if output_callback:
                        output_callback(line.strip())
            
            process.wait()
            
            # Build result
            success = process.returncode == 0 and not error_detected
            output = '\n'.join(output_lines)
            
            if error_detected:
                output += f"\n\nERRORS DETECTED:\n{''.join(error_details)}"
            
            # Log to history
            self.build_history.append({
                'timestamp': datetime.now().isoformat(),
                'command': ' '.join(command),
                'success': success,
                'output': output,
                'errors': error_details if error_detected else []
            })
            
            logger.info(f"Command completed. Success: {success}")
            return success, output
            
        except subprocess.TimeoutExpired:
            error_msg = "Command timed out"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Command execution error: {str(e)}"
            logger.error(error_msg)
            return False, error_msg
    
    def get_dependencies(self) -> Tuple[bool, str]:
        """Get Flutter dependencies"""
        return self.run_flutter_command(['flutter', 'pub', 'get'])
    
    def clean_project(self) -> Tuple[bool, str]:
        """Clean Flutter project"""
        return self.run_flutter_command(['flutter', 'clean'])
    
    def build_apk(self, mode: str = 'release') -> Tuple[bool, str]:
        """Build APK"""
        command = ['flutter', 'build', 'apk', f'--{mode}']
        return self.run_flutter_command(command)
    
    def run_app(self, device: Optional[str] = None) -> Tuple[bool, str]:
        """Run Flutter app"""
        command = ['flutter', 'run']
        if device:
            command.extend(['-d', device])
        return self.run_flutter_command(command)
    
    def get_devices(self) -> List[str]:
        """Get available Flutter devices"""
        try:
            result = subprocess.run(
                ['flutter', 'devices'],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                # Parse device list
                devices = []
                for line in result.stdout.split('\n'):
                    if '•' in line and 'android' in line.lower():
                        device_id = line.split('•')[1].strip().split('•')[0].strip()
                        devices.append(device_id)
                return devices
        except Exception as e:
            logger.error(f"Error getting devices: {e}")
        return []
    
    def analyze_errors(self, output: str) -> Dict[str, List[str]]:
        """Analyze build output for error patterns"""
        analysis = {
            'compilation_errors': [],
            'dependency_errors': [],
            'permission_errors': [],
            'flutter_errors': [],
            'import_errors': [],
            'other_errors': []
        }
        
        lines = output.split('\n')
        for line in lines:
            for error_type, patterns in self.error_patterns.items():
                for pattern in patterns:
                    if pattern in line:
                        if error_type == 'compilation_error':
                            analysis['compilation_errors'].append(line.strip())
                        elif error_type == 'dependency_error':
                            analysis['dependency_errors'].append(line.strip())
                        elif error_type == 'permission_error':
                            analysis['permission_errors'].append(line.strip())
                        elif error_type == 'flutter_error':
                            analysis['flutter_errors'].append(line.strip())
                        elif error_type == 'import_error':
                            analysis['import_errors'].append(line.strip())
        
        # Categorize uncategorized errors
        for line in lines:
            if any(keyword in line.lower() for keyword in ['error', 'failed', 'exception']):
                if not any(line.strip() in errors for errors in analysis.values() if errors):
                    analysis['other_errors'].append(line.strip())
        
        return analysis


class ImprovementEngine:
    """Continuous improvement engine for build optimization"""
    
    def __init__(self):
        self.suggestions = []
        self.performance_metrics = {}
        self.common_fixes = {
            'dependency_conflict': 'flutter pub cache repair && flutter pub get',
            'gradle_issues': 'cd android && ./gradlew clean && cd .. && flutter clean',
            'flutter_doctor': 'flutter doctor -v',
            'upgrade_flutter': 'flutter upgrade',
            'clean_build': 'flutter clean && flutter pub get',
        }
    
    def analyze_build_history(self, build_history: List[Dict]) -> List[str]:
        """Analyze build history and provide improvement suggestions"""
        suggestions = []
        
        if not build_history:
            return ["No build history available. Run some builds first."]
        
        # Analyze failure patterns
        recent_builds = build_history[-10:]  # Last 10 builds
        failure_count = sum(1 for build in recent_builds if not build['success'])
        
        if failure_count > 5:
            suggestions.append("High failure rate detected. Consider running 'flutter doctor' to check environment.")
        
        # Check for common error patterns
        all_errors = []
        for build in recent_builds:
            all_errors.extend(build.get('errors', []))
        
        error_types = set()
        for error in all_errors:
            if 'dependency' in error.lower():
                error_types.add('dependency')
            elif 'gradle' in error.lower():
                error_types.add('gradle')
            elif 'permission' in error.lower():
                error_types.add('permission')
        
        if 'dependency' in error_types:
            suggestions.append("Dependency issues detected. Try: flutter pub cache repair")
        
        if 'gradle' in error_types:
            suggestions.append("Gradle issues detected. Try: cd android && ./gradlew clean")
        
        # Performance suggestions
        if len(recent_builds) >= 3:
            avg_build_time = self._calculate_avg_build_time(recent_builds)
            if avg_build_time > 300:  # 5 minutes
                suggestions.append("Build times are slow. Consider enabling build cache and using --no-sound-null-safety")
        
        return suggestions
    
    def _calculate_avg_build_time(self, builds: List[Dict]) -> float:
        """Calculate average build time from build history"""
        # Simplified calculation - in real implementation, would track actual build times
        return 180.0  # Placeholder
    
    def get_quick_fixes(self) -> Dict[str, str]:
        """Get quick fixes for common issues"""
        return self.common_fixes


class iSuiteMasterApp:
    """Main GUI application for iSuite build and run management"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("iSuite Master App - Build & Run Manager")
        self.root.geometry("1200x800")
        
        # Initialize components
        self.project_path = None
        self.build_manager = None
        self.improvement_engine = ImprovementEngine()
        
        # Setup UI
        self.setup_ui()
        self.setup_logging()
        
        # Load last project if available
        self.load_last_project()
    
    def setup_ui(self):
        """Setup the main UI components"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(3, weight=1)
        
        # Project selection
        self.setup_project_section(main_frame)
        
        # Control buttons
        self.setup_control_section(main_frame)
        
        # Device selection
        self.setup_device_section(main_frame)
        
        # Output and logging
        self.setup_output_section(main_frame)
        
        # Status bar
        self.setup_status_bar()
    
    def setup_project_section(self, parent):
        """Setup project selection section"""
        project_frame = ttk.LabelFrame(parent, text="Project", padding="10")
        project_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Project path
        ttk.Label(project_frame, text="Project Path:").grid(row=0, column=0, sticky=tk.W)
        self.project_path_var = tk.StringVar()
        project_entry = ttk.Entry(project_frame, textvariable=self.project_path_var, width=60)
        project_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(5, 5))
        
        browse_btn = ttk.Button(project_frame, text="Browse", command=self.browse_project)
        browse_btn.grid(row=0, column=2, padx=(5, 0))
        
        # Validate button
        validate_btn = ttk.Button(project_frame, text="Validate Project", command=self.validate_project)
        validate_btn.grid(row=0, column=3, padx=(5, 0))
        
        project_frame.columnconfigure(1, weight=1)
    
    def setup_control_section(self, parent):
        """Setup control buttons section"""
        control_frame = ttk.LabelFrame(parent, text="Build Controls", padding="10")
        control_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Row 1: Basic operations
        ttk.Button(control_frame, text="Get Dependencies", command=self.get_dependencies).grid(row=0, column=0, padx=(0, 5))
        ttk.Button(control_frame, text="Clean Project", command=self.clean_project).grid(row=0, column=1, padx=(0, 5))
        ttk.Button(control_frame, text="Analyze", command=self.analyze_project).grid(row=0, column=2, padx=(0, 5))
        
        # Row 2: Build operations
        ttk.Button(control_frame, text="Build APK (Debug)", command=lambda: self.build_apk('debug')).grid(row=1, column=0, padx=(0, 5), pady=(5, 0))
        ttk.Button(control_frame, text="Build APK (Release)", command=lambda: self.build_apk('release')).grid(row=1, column=1, padx=(0, 5), pady=(5, 0))
        ttk.Button(control_frame, text="Run App", command=self.run_app).grid(row=1, column=2, padx=(0, 5), pady=(5, 0))
        
        # Row 3: Advanced operations
        ttk.Button(control_frame, text="Flutter Doctor", command=self.flutter_doctor).grid(row=2, column=0, padx=(0, 5), pady=(5, 0))
        ttk.Button(control_frame, text="Upgrade Flutter", command=self.upgrade_flutter).grid(row=2, column=1, padx=(0, 5), pady=(5, 0))
        ttk.Button(control_frame, text="Get Suggestions", command=self.get_suggestions).grid(row=2, column=2, padx=(0, 5), pady=(5, 0))
    
    def setup_device_section(self, parent):
        """Setup device selection section"""
        device_frame = ttk.LabelFrame(parent, text="Device Selection", padding="10")
        device_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Label(device_frame, text="Target Device:").grid(row=0, column=0, sticky=tk.W)
        self.device_var = tk.StringVar()
        self.device_combo = ttk.Combobox(device_frame, textvariable=self.device_var, width=40)
        self.device_combo.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(5, 5))
        
        refresh_btn = ttk.Button(device_frame, text="Refresh Devices", command=self.refresh_devices)
        refresh_btn.grid(row=0, column=2, padx=(5, 0))
        
        device_frame.columnconfigure(1, weight=1)
    
    def setup_output_section(self, parent):
        """Setup output and logging section"""
        output_frame = ttk.LabelFrame(parent, text="Output & Logs", padding="10")
        output_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        
        # Create notebook for multiple tabs
        self.notebook = ttk.Notebook(output_frame)
        self.notebook.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Console output tab
        console_frame = ttk.Frame(self.notebook)
        self.notebook.add(console_frame, text="Console Output")
        
        self.console_output = scrolledtext.ScrolledText(console_frame, height=20, width=100)
        self.console_output.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Error analysis tab
        error_frame = ttk.Frame(self.notebook)
        self.notebook.add(error_frame, text="Error Analysis")
        
        self.error_output = scrolledtext.ScrolledText(error_frame, height=20, width=100)
        self.error_output.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Suggestions tab
        suggestions_frame = ttk.Frame(self.notebook)
        self.notebook.add(suggestions_frame, text="Suggestions")
        
        self.suggestions_output = scrolledtext.ScrolledText(suggestions_frame, height=20, width=100)
        self.suggestions_output.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        output_frame.columnconfigure(0, weight=1)
        output_frame.rowconfigure(0, weight=1)
        console_frame.columnconfigure(0, weight=1)
        console_frame.rowconfigure(0, weight=1)
        error_frame.columnconfigure(0, weight=1)
        error_frame.rowconfigure(0, weight=1)
        suggestions_frame.columnconfigure(0, weight=1)
        suggestions_frame.rowconfigure(0, weight=1)
    
    def setup_status_bar(self):
        """Setup status bar"""
        status_frame = ttk.Frame(self.root)
        status_frame.grid(row=1, column=0, sticky=(tk.W, tk.E))
        
        self.status_var = tk.StringVar(value="Ready")
        ttk.Label(status_frame, textvariable=self.status_var).pack(side=tk.LEFT)
        
        # Progress bar
        self.progress = ttk.Progressbar(status_frame, mode='indeterminate')
        self.progress.pack(side=tk.RIGHT, padx=(10, 0))
    
    def setup_logging(self):
        """Setup logging configuration"""
        # Create log directory if it doesn't exist
        log_dir = Path("logs")
        log_dir.mkdir(exist_ok=True)
        
        # Setup file handler for GUI logs
        gui_handler = logging.FileHandler('logs/isuite_gui.log')
        gui_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        
        # Add handler to root logger
        logging.getLogger().addHandler(gui_handler)
    
    def browse_project(self):
        """Browse for Flutter project directory"""
        directory = filedialog.askdirectory(title="Select Flutter Project Directory")
        if directory:
            self.project_path_var.set(directory)
            self.project_path = Path(directory)
            self.save_last_project()
            self.log_message(f"Selected project: {directory}")
    
    def validate_project(self):
        """Validate Flutter project"""
        if not self.project_path:
            self.show_error("Please select a project directory first")
            return
        
        self.set_status("Validating project...")
        self.start_progress()
        
        def validate():
            self.build_manager = BuildManager(self.project_path)
            success, message = self.build_manager.validate_flutter_project()
            
            self.root.after(0, lambda: self.validation_complete(success, message))
        
        threading.Thread(target=validate, daemon=True).start()
    
    def validation_complete(self, success: bool, message: str):
        """Handle validation completion"""
        self.stop_progress()
        self.set_status("Validation complete")
        
        if success:
            self.log_message(f"✓ Project validated: {message}")
            messagebox.showinfo("Validation Success", message)
            self.refresh_devices()
        else:
            self.log_message(f"✗ Validation failed: {message}")
            self.show_error(message)
    
    def get_dependencies(self):
        """Get Flutter dependencies"""
        self.run_command("Getting dependencies", lambda: self.build_manager.get_dependencies())
    
    def clean_project(self):
        """Clean Flutter project"""
        self.run_command("Cleaning project", lambda: self.build_manager.clean_project())
    
    def analyze_project(self):
        """Analyze project for issues"""
        self.run_command("Analyzing project", lambda: self.build_manager.run_flutter_command(['flutter', 'analyze']))
    
    def build_apk(self, mode: str):
        """Build APK"""
        command = f"Building APK ({mode})"
        self.run_command(command, lambda: self.build_manager.build_apk(mode))
    
    def run_app(self):
        """Run Flutter app"""
        device = self.device_var.get() if self.device_var.get() else None
        self.run_command("Running app", lambda: self.build_manager.run_app(device))
    
    def flutter_doctor(self):
        """Run Flutter doctor"""
        self.run_command("Running Flutter doctor", lambda: self.build_manager.run_flutter_command(['flutter', 'doctor', '-v']))
    
    def upgrade_flutter(self):
        """Upgrade Flutter SDK"""
        self.run_command("Upgrading Flutter", lambda: self.build_manager.run_flutter_command(['flutter', 'upgrade']))
    
    def get_suggestions(self):
        """Get improvement suggestions"""
        if not self.build_manager or not self.build_manager.build_history:
            self.show_info("No build history available. Run some builds first.")
            return
        
        suggestions = self.improvement_engine.analyze_build_history(self.build_manager.build_history)
        
        # Display suggestions
        self.suggestions_output.delete(1.0, tk.END)
        self.suggestions_output.insert(tk.END, "IMPROVEMENT SUGGESTIONS:\n\n")
        
        for i, suggestion in enumerate(suggestions, 1):
            self.suggestions_output.insert(tk.END, f"{i}. {suggestion}\n\n")
        
        # Show quick fixes
        quick_fixes = self.improvement_engine.get_quick_fixes()
        self.suggestions_output.insert(tk.END, "\nQUICK FIXES:\n\n")
        for issue, fix in quick_fixes.items():
            self.suggestions_output.insert(tk.END, f"• {issue}: {fix}\n")
        
        self.notebook.select(2)  # Switch to suggestions tab
        self.log_message("Generated improvement suggestions")
    
    def refresh_devices(self):
        """Refresh available devices"""
        if not self.build_manager:
            return
        
        self.set_status("Refreshing devices...")
        
        def refresh():
            devices = self.build_manager.get_devices()
            self.root.after(0, lambda: self.update_devices(devices))
        
        threading.Thread(target=refresh, daemon=True).start()
    
    def update_devices(self, devices: List[str]):
        """Update device list"""
        self.device_combo['values'] = devices
        if devices and not self.device_var.get():
            self.device_var.set(devices[0])
        
        self.set_status(f"Found {len(devices)} device(s)")
        self.log_message(f"Available devices: {', '.join(devices) if devices else 'None'}")
    
    def run_command(self, description: str, command_func):
        """Run a command in background thread"""
        if not self.build_manager:
            self.show_error("Please validate project first")
            return
        
        self.set_status(description)
        self.start_progress()
        self.clear_console()
        
        def run():
            success, output = command_func()
            self.root.after(0, lambda: self.command_complete(success, output, description))
        
        threading.Thread(target=run, daemon=True).start()
    
    def command_complete(self, success: bool, output: str, description: str):
        """Handle command completion"""
        self.stop_progress()
        self.set_status(f"{description} - {'Success' if success else 'Failed'}")
        
        # Display output
        self.console_output.delete(1.0, tk.END)
        self.console_output.insert(tk.END, output)
        
        # Analyze errors if failed
        if not success and self.build_manager:
            error_analysis = self.build_manager.analyze_errors(output)
            self.display_error_analysis(error_analysis)
        
        # Log result
        status = "✓" if success else "✗"
        self.log_message(f"{status} {description}")
        
        if not success:
            self.show_error(f"{description} failed. Check Error Analysis tab for details.")
    
    def display_error_analysis(self, analysis: Dict[str, List[str]]):
        """Display error analysis in error tab"""
        self.error_output.delete(1.0, tk.END)
        self.error_output.insert(tk.END, "ERROR ANALYSIS:\n\n")
        
        for error_type, errors in analysis.items():
            if errors:
                self.error_output.insert(tk.END, f"{error_type.upper().replace('_', ' ')}:\n")
                for error in errors:
                    self.error_output.insert(tk.END, f"  • {error}\n")
                self.error_output.insert(tk.END, "\n")
        
        if not any(analysis.values()):
            self.error_output.insert(tk.END, "No specific error patterns detected.")
        
        self.notebook.select(1)  # Switch to error analysis tab
    
    def clear_console(self):
        """Clear console output"""
        self.console_output.delete(1.0, tk.END)
        self.error_output.delete(1.0, tk.END)
    
    def log_message(self, message: str):
        """Log message to console"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.console_output.insert(tk.END, f"[{timestamp}] {message}\n")
        self.console_output.see(tk.END)
        self.root.update_idletasks()
    
    def set_status(self, message: str):
        """Set status bar message"""
        self.status_var.set(message)
        self.root.update_idletasks()
    
    def start_progress(self):
        """Start progress bar"""
        self.progress.start()
    
    def stop_progress(self):
        """Stop progress bar"""
        self.progress.stop()
    
    def show_error(self, message: str):
        """Show error message"""
        messagebox.showerror("Error", message)
        logger.error(message)
    
    def show_info(self, message: str):
        """Show info message"""
        messagebox.showinfo("Information", message)
        logger.info(message)
    
    def save_last_project(self):
        """Save last project path"""
        if self.project_path:
            try:
                with open('last_project.json', 'w') as f:
                    json.dump({'project_path': str(self.project_path)}, f)
            except Exception as e:
                logger.error(f"Failed to save last project: {e}")
    
    def load_last_project(self):
        """Load last project path"""
        try:
            if os.path.exists('last_project.json'):
                with open('last_project.json', 'r') as f:
                    data = json.load(f)
                    self.project_path_var.set(data['project_path'])
                    self.project_path = Path(data['project_path'])
                    self.log_message(f"Loaded last project: {data['project_path']}")
        except Exception as e:
            logger.error(f"Failed to load last project: {e}")


def main():
    """Main entry point"""
    try:
        root = tk.Tk()
        app = iSuiteMasterApp(root)
        
        # Handle window closing
        def on_closing():
            logger.info("Application closing")
            root.destroy()
            sys.exit(0)
        
        root.protocol("WM_DELETE_WINDOW", on_closing)
        
        logger.info("iSuite Master App started")
        root.mainloop()
        
    except Exception as e:
        logger.error(f"Application error: {e}")
        messagebox.showerror("Fatal Error", f"Application failed to start: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
