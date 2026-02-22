#!/usr/bin/env python3
"""
iSuite Master App - Flutter Build & Run Manager
Enterprise-grade Flutter application management tool with comprehensive logging and error handling.

Features:
- Automated Flutter build and run processes
- Console logging with timestamps and levels
- Error detection and reporting
- Performance monitoring
- Cross-platform support (Windows, macOS, Linux)
- Configuration management
- Git integration
- Dependency management
- Clean build utilities
- Development workflow automation
"""

import os
import sys
import subprocess
import json
import datetime
import logging
import platform
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

# Configuration
@dataclass
class AppConfig:
    """Application configuration settings"""
    project_name: str = "iSuite"
    flutter_path: str = "C:\\flutter\\bin\\flutter.bat"
    project_path: str = os.path.dirname(os.path.abspath(__file__))
    build_path: str = os.path.join(project_path, "build")
    lib_path: str = os.path.join(project_path, "lib")
    test_path: str = os.path.join(project_path, "test")
    pubspec_path: str = os.path.join(project_path, "pubspec.yaml")
    
    # Build configurations
    debug_build: bool = False
    release_build: bool = False
    profile_build: bool = False
    target_platform: str = "windows"  # windows, macos, linux, web, android, ios
    
    # Logging configuration
    log_level: str = "INFO"  # DEBUG, INFO, WARNING, ERROR, CRITICAL
    log_to_file: bool = True
    log_to_console: bool = True
    log_file_path: str = os.path.join(project_path, "logs", "master_app.log")
    
    # Performance settings
    max_build_time: int = 300  # seconds
    max_run_time: int = 60   # seconds
    memory_limit_mb: int = 2048  # 2GB
    
    # Flutter configuration
    flutter_channel: str = "stable"
    flutter_version: str = "3.41.2"

class LogLevel(Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"

class BuildType(Enum):
    DEBUG = "debug"
    RELEASE = "release"
    PROFILE = "profile"

class Platform(Enum):
    WINDOWS = "windows"
    MACOS = "macos"
    LINUX = "linux"
    WEB = "web"
    ANDROID = "android"
    IOS = "ios"

class MasterApp:
    """Main application class for iSuite Flutter project management"""
    
    def __init__(self, config: Optional[AppConfig] = None):
        self.config = config or AppConfig()
        self.setup_logging()
        self.validate_environment()
        
    def setup_logging(self):
        """Setup logging configuration"""
        # Create logs directory
        log_dir = os.path.dirname(self.config.log_file_path)
        os.makedirs(log_dir, exist_ok=True)
        
        # Configure logging
        log_format = '%(asctime)s - %(levelname)s - %(message)s'
        logging.basicConfig(
            level=getattr(logging, self.config.log_level.upper()),
            format=log_format,
            handlers=[
                logging.FileHandler(self.config.log_file_path),
                logging.StreamHandler(sys.stdout)
            ]
        )
        
        self.logger = logging.getLogger(__name__)
        self.log("Master App initialized", LogLevel.INFO)
        
    def validate_environment(self):
        """Validate the development environment"""
        self.log("Validating environment...", LogLevel.INFO)
        
        # Check Flutter installation
        if not os.path.exists(self.config.flutter_path):
            self.log(f"Flutter not found at: {self.config.flutter_path}", LogLevel.ERROR)
            raise FileNotFoundError(f"Flutter SDK not found at {self.config.flutter_path}")
        
        # Check project structure
        required_paths = [
            self.config.pubspec_path,
            self.config.lib_path,
            self.config.build_path
        ]
        
        for path in required_paths:
            if not os.path.exists(path):
                self.log(f"Required path not found: {path}", LogLevel.ERROR)
                raise FileNotFoundError(f"Required path not found: {path}")
        
        self.log("Environment validation completed", LogLevel.INFO)
        
    def log(self, message: str, level: LogLevel = LogLevel.INFO):
        """Log a message with timestamp"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] - {level.value} - {message}"
        
        if self.config.log_to_file:
            with open(self.config.log_file_path, 'a', encoding='utf-8') as f:
                f.write(log_message + '\n')
        
        if self.config.log_to_console:
            print(log_message)
            
    def run_flutter_command(self, command: List[str], cwd: Optional[str] = None, timeout: int = 60) -> Tuple[bool, str]:
        """Run a Flutter command with error handling and logging"""
        try:
            self.log(f"Running Flutter command: {' '.join(command)}", LogLevel.INFO)
            
            # Set environment variables
            env = os.environ.copy()
            env['FLUTTER_ROOT'] = os.path.dirname(self.config.flutter_path)
            
            # Run the command
            process = subprocess.Popen(
                command,
                cwd=cwd or self.config.project_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=env
            )
            
            # Wait for completion with timeout
            try:
                stdout, stderr = process.communicate(timeout=timeout)
                return_code = process.returncode
                
                if return_code == 0:
                    self.log(f"Command completed successfully: {' '.join(command)}", LogLevel.INFO)
                    return True, stdout
                else:
                    error_msg = stderr.strip() if stderr else f"Command failed with return code {return_code}"
                    self.log(error_msg, LogLevel.ERROR)
                    return False, error_msg
                    
            except subprocess.TimeoutExpired:
                error_msg = f"Command timed out after {timeout} seconds: {' '.join(command)}"
                self.log(error_msg, LogLevel.ERROR)
                return False, error_msg
                
        except Exception as e:
            error_msg = f"Exception running command: {str(e)} - {' '.join(command)}"
            self.log(error_msg, LogLevel.ERROR)
            return False, error_msg
            
    def clean_project(self) -> bool:
        """Clean the project by removing build artifacts"""
        self.log("Cleaning project...", LogLevel.INFO)
        
        try:
            # Remove build directory
            if os.path.exists(self.config.build_path):
                shutil.rmtree(self.config.build_path)
                self.log("Removed build directory", LogLevel.INFO)
            
            # Clean Flutter cache
            cache_clean_result = self.run_flutter_command(["clean"], timeout=30)
            if not cache_clean_result[0]:
                self.log("Flutter cache cleaned", LogLevel.INFO)
            
            # Get dependencies
            deps_result = self.run_flutter_command(["pub", "get"], timeout=120)
            if not deps_result[0]:
                self.log("Dependencies updated", LogLevel.INFO)
                
            return True
            
        except Exception as e:
            self.log(f"Clean failed: {str(e)}", LogLevel.ERROR)
            return False
            
    def build_project(self, build_type: BuildType = BuildType.DEBUG) -> bool:
        """Build the Flutter project"""
        self.log(f"Building project in {build_type.value} mode...", LogLevel.INFO)
        
        try:
            # Prepare build command
            build_command = ["build", build_type.value]
            if self.config.target_platform != Platform.WINDOWS:
                build_command.append(self.config.target_platform)
            
            # Run build
            build_result = self.run_flutter_command(build_command, timeout=self.config.max_build_time)
            
            if build_result[0]:
                self.log(f"Build completed successfully in {build_type.value} mode", LogLevel.INFO)
                return True
            else:
                self.log(f"Build failed: {build_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Build failed with exception: {str(e)}", LogLevel.ERROR)
            return False
            
    def run_project(self, build_type: BuildType = BuildType.DEBUG) -> Tuple[bool, str]:
        """Run the Flutter project"""
        self.log(f"Running project in {build_type.value} mode...", LogLevel.INFO)
        
        try:
            # Prepare run command
            run_command = ["run"]
            if self.config.target_platform != Platform.WINDOWS:
                run_command.append("-d")
                run_command.append(self.config.target_platform)
            
            if build_type != BuildType.DEBUG:
                run_command.append("--release")
            
            # Run the application
            run_result = self.run_flutter_command(run_command, timeout=self.config.max_run_time)
            
            if run_result[0]:
                self.log(f"Application started successfully", LogLevel.INFO)
                return True, run_result[1]
            else:
                self.log(f"Run failed: {run_result[1]}", LogLevel.ERROR)
                return False, run_result[1]
                
        except Exception as e:
            self.log(f"Run failed with exception: {str(e)}", LogLevel.ERROR)
            return False, str(e)
            
    def run_tests(self) -> bool:
        """Run Flutter tests"""
        self.log("Running tests...", LogLevel.INFO)
        
        try:
            test_result = self.run_flutter_command(["test"], timeout=180)
            
            if test_result[0]:
                self.log("Tests completed successfully", LogLevel.INFO)
                return True
            else:
                self.log(f"Tests failed: {test_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Tests failed with exception: {str(e)}", LogLevel.ERROR)
            return False
            
    def analyze_code(self) -> bool:
        """Analyze Flutter code"""
        self.log("Analyzing code...", LogLevel.INFO)
        
        try:
            analyze_result = self.run_flutter_command(["analyze"], timeout=120)
            
            if analyze_result[0]:
                self.log("Code analysis completed", LogLevel.INFO)
                return True
            else:
                self.log(f"Code analysis failed: {analyze_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Code analysis failed with exception: {str(e)}", LogLevel.ERROR)
            return False
            
    def format_code(self) -> bool:
        """Format Flutter code"""
        self.log("Formatting code...", LogLevel.INFO)
        
        try:
            format_result = self.run_flutter_command(["format", "."], timeout=60)
            
            if format_result[0]:
                self.log("Code formatted successfully", LogLevel.INFO)
                return True
            else:
                self.log(f"Code formatting failed: {format_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Code formatting failed with exception: {str(e)}", LogLevel.ERROR)
            return False
            
    def upgrade_dependencies(self) -> bool:
        """Upgrade Flutter dependencies"""
        self.log("Upgrading dependencies...", LogLevel.INFO)
        
        try:
            upgrade_result = self.run_flutter_command(["pub", "upgrade"], timeout=300)
            
            if upgrade_result[0]:
                self.log("Dependencies upgraded successfully", LogLevel.INFO)
                return True
            else:
                self.log(f"Dependencies upgrade failed: {upgrade_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Dependencies upgrade failed with exception: {str(e)}", LogLevel.ERROR)
            return False
            
    def check_dependencies(self) -> bool:
        """Check for outdated dependencies"""
        self.log("Checking dependencies...", LogLevel.INFO)
        
        try:
            check_result = self.run_flutter_command(["pub", "outdated"], timeout=60)
            
            if check_result[0]:
                self.log("Dependencies check completed", LogLevel.INFO)
                return True
            else:
                self.log(f"Dependencies check failed: {check_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Dependencies check failed with exception: {str(e)}", LogLevel.ERROR)
            return False
            
    def get_project_info(self) -> Dict[str, str]:
        """Get project information"""
        try:
            info = {
                "project_name": self.config.project_name,
                "project_path": self.config.project_path,
                "flutter_path": self.config.flutter_path,
                "flutter_version": self.config.flutter_version,
                "target_platform": self.config.target_platform,
                "build_path": self.config.build_path,
                "lib_path": self.config.lib_path,
                "test_path": self.config.test_path,
                "pubspec_path": self.config.pubspec_path,
                "log_file": self.config.log_file_path,
                "python_version": platform.python_version(),
                "platform": platform.system(),
                "platform_release": platform.release(),
            }
            
            # Check if pubspec exists and get dependencies
            if os.path.exists(self.config.pubspec_path):
                with open(self.config.pubspec_path, 'r') as f:
                    pubspec_content = f.read()
                    info["dependencies"] = pubspec_content
                    info["flutter_dependencies"] = self._extract_flutter_dependencies(pubspec_content)
            
            return info
            
        except Exception as e:
            self.log(f"Failed to get project info: {str(e)}", LogLevel.ERROR)
            return {}
            
    def _extract_flutter_dependencies(self, pubspec_content: str) -> List[str]:
        """Extract Flutter dependencies from pubspec.yaml"""
        dependencies = []
        lines = pubspec_content.split('\n')
        in_deps = False
        
        for line in lines:
            line = line.strip()
            if line.startswith('dependencies:'):
                in_deps = True
            elif in_deps and line.startswith('-') and ':' in line:
                dep = line.split(':')[1].strip()
                dep = dep.split(' ')[0].strip()
                dependencies.append(dep)
            elif in_deps and not line.startswith('#') and line.strip():
                dep = line.split(':')[0].strip()
                dep = dep.split(' ')[0].strip()
                dependencies.append(dep)
                
        return dependencies
        
    def create_git_commit(self, message: str, files: List[str] = None) -> bool:
        """Create a git commit with proper error handling"""
        self.log(f"Creating git commit: {message}", LogLevel.INFO)
        
        try:
            # Add files if specified
            if files:
                add_result = self.run_command(["git", "add"] + files, timeout=30)
                if not add_result[0]:
                    self.log(f"Failed to add files: {add_result[1]}", LogLevel.ERROR)
                    return False
            
            # Commit changes
            commit_result = self.run_command(["git", "commit", "-m", message], timeout=30)
            
            if commit_result[0]:
                self.log("Git commit created successfully", LogLevel.INFO)
                return True
            else:
                self.log(f"Git commit failed: {commit_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Git commit failed: {str(e)}", LogLevel.ERROR)
            return False
            
    def push_to_git(self, remote: str = "origin") -> bool:
        """Push changes to git remote"""
        self.log(f"Pushing to {remote}...", LogLevel.INFO)
        
        try:
            push_result = self.run_command(["git", "push", remote], timeout=60)
            
            if push_result[0]:
                self.log("Git push completed successfully", LogLevel.INFO)
                return True
            else:
                self.log(f"Git push failed: {push_result[1]}", LogLevel.ERROR)
                return False
                
        except Exception as e:
            self.log(f"Git push failed: {str(e)}", LogLevel.ERROR)
            return False
            
    def show_menu(self) -> None:
        """Display the main menu"""
        print("\n" + "="*60)
        print(f"🚀 {self.config.project_name} Master App")
        print("="*60)
        print()
        
        menu_options = [
            "1. 🏗️ Build Project",
            "2. 🧪 Clean Project", 
            "3. 📱 Run Application",
            "4. 🧪 Run Tests",
            "5. 📊 Analyze Code",
            "6. 📝 Format Code",
            "7. 📦 Upgrade Dependencies",
            "8. 🔍 Check Dependencies",
            "9. 📋 Project Information",
            "10. 🗂️ Git Operations",
            "11. ⚙️ Settings",
            "12. 🚪 Exit"
        ]
        
        for option in menu_options:
            print(f"   {option}")
        
        print("="*60)
        
    def handle_menu_choice(self, choice: str) -> bool:
        """Handle user menu choice"""
        if choice == "1":
            return self.build_project(BuildType.DEBUG)
        elif choice == "2":
            return self.clean_project()
        elif choice == "3":
            return self.run_project(BuildType.DEBUG)
        elif choice == "4":
            return self.run_tests()
        elif choice == "5":
            return self.analyze_code()
        elif choice == "6":
            return self.format_code()
        elif choice == "7":
            return self.upgrade_dependencies()
        elif choice == "8":
            return self.check_dependencies()
        elif choice == "9":
            info = self.get_project_info()
            print("\n📋 Project Information:")
            print("-" * 40)
            for key, value in info.items():
                print(f"  {key}: {value}")
            print("-" * 40)
            input("\nPress Enter to continue...")
            return True
        elif choice == "10":
            self.show_git_menu()
        elif choice == "11":
            self.show_settings_menu()
        elif choice == "12":
            self.log("Exiting Master App", LogLevel.INFO)
            return False
        else:
            print("❌ Invalid choice. Please try again.")
            return True
            
    def show_git_menu(self) -> bool:
        """Display git operations menu"""
        print("\n🗂️ Git Operations:")
        print("-" * 40)
        git_options = [
            "1. 📝 Commit Changes",
            "2. 📤 Push to Remote",
            "3. 🔀 Pull from Remote",
            "4. 📊 Check Status",
            "5. 🔀 Back to Main Menu"
        ]
        
        for option in git_options:
            print(f"  {option}")
        
        print("-" * 40)
        
        choice = input("Select git operation (1-5): ").strip()
        
        if choice == "1":
            message = input("Enter commit message: ").strip()
            return self.create_git_commit(message)
        elif choice == "2":
            return self.push_to_git()
        elif choice == "3":
            pull_result = self.run_command(["git", "pull"], timeout=60)
            if pull_result[0]:
                self.log("Git pull completed successfully", LogLevel.INFO)
            else:
                self.log(f"Git pull failed: {pull_result[1]}", LogLevel.ERROR)
            return pull_result[0]
        elif choice == "4":
            status_result = self.run_command(["git", "status"], timeout=30)
            if status_result[0]:
                print("Git status:")
                print(status_result[1])
            else:
                self.log(f"Git status failed: {status_result[1]}", LogLevel.ERROR)
            return status_result[0]
        elif choice == "5":
            return True
        else:
            print("❌ Invalid choice. Please try again.")
            return True
            
    def show_settings_menu(self) -> bool:
        """Display settings menu"""
        print("\n⚙️ Settings:")
        print("-" * 40)
        
        print(f"  1. 🎯 Target Platform: {self.config.target_platform}")
        print(f"  2. 🏗️ Build Type: {self.config.debug_build}")
        print(f"  3. 📊 Log Level: {self.config.log_level}")
        print(f"  4. 📝 Log to File: {self.config.log_to_file}")
        print(f"  5. 📝 Log to Console: {self.config.log_to_console}")
        print(f"  6. ⏱️ Max Build Time: {self.config.max_build_time}s")
        print(f"  7. ⏱️ Max Run Time: {self.config.max_run_time}s")
        print(f"  8. 🧠 Memory Limit: {self.config.memory_limit_mb}MB")
        print("  9. 🔀 Back to Main Menu")
        
        choice = input("Select setting to modify (1-9): ").strip()
        
        if choice == "1":
            platforms = ["windows", "macos", "linux", "web", "android", "ios"]
            print("Available platforms:")
            for i, platform in enumerate(platforms, 1):
                print(f"  {i}. {platform}")
            
            new_platform = input(f"Enter platform ({'/'.join(platforms)}): ").strip()
            if new_platform in platforms:
                self.config.target_platform = new_platform
                self.log(f"Target platform changed to: {new_platform}", LogLevel.INFO)
            else:
                print("❌ Invalid platform.")
                
        elif choice == "2":
            build_types = ["debug", "release", "profile"]
            print("Available build types:")
            for i, build_type in enumerate(build_types, 1):
                print(f"  {i}. {build_type}")
            
            new_build_type = input(f"Enter build type ({'/'.join(build_types)}): ").strip()
            if new_build_type in build_types:
                self.config.debug_build = (new_build_type == "debug")
                self.log(f"Build type changed to: {new_build_type}", LogLevel.INFO)
            else:
                print("❌ Invalid build type.")
                
        elif choice == "3":
            log_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
            print("Available log levels:")
            for i, level in enumerate(log_levels, 1):
                print(f"  {i}. {level}")
            
            new_log_level = input(f"Enter log level ({'/'.join(log_levels)}): ").strip().upper()
            if new_log_level in log_levels:
                self.config.log_level = new_log_level
                self.log(f"Log level changed to: {new_log_level}", LogLevel.INFO)
            else:
                print("❌ Invalid log level.")
                
        elif choice == "4":
            self.config.log_to_file = not self.config.log_to_file
            status = "Enabled" if self.config.log_to_file else "Disabled"
            self.log(f"Log to file: {status}", LogLevel.INFO)
            
        elif choice == "5":
            self.config.log_to_console = not self.config.log_to_console
            status = "Enabled" if self.config.log_to_console else "Disabled"
            self.log(f"Log to console: {status}", LogLevel.INFO)
            
        elif choice == "6":
            try:
                new_time = int(input(f"Enter max build time (seconds) [current: {self.config.max_build_time}]: ").strip())
                if new_time > 0:
                    self.config.max_build_time = new_time
                    self.log(f"Max build time changed to: {new_time}s", LogLevel.INFO)
            except ValueError:
                print("❌ Invalid number.")
                
        elif choice == "7":
            try:
                new_time = int(input(f"Enter max run time (seconds) [current: {self.config.max_run_time}]: ").strip())
                if new_time > 0:
                    self.config.max_run_time = new_time
                    self.log(f"Max run time changed to: {new_time}s", LogLevel.INFO)
            except ValueError:
                print("❌ Invalid number.")
                
        elif choice == "8":
            try:
                new_limit = int(input(f"Enter memory limit (MB) [current: {self.config.memory_limit_mb}]: ").strip())
                if new_limit > 0:
                    self.config.memory_limit_mb = new_limit
                    self.log(f"Memory limit changed to: {new_limit}MB", LogLevel.INFO)
            except ValueError:
                print("❌ Invalid number.")
                
        elif choice == "9":
            return True
        else:
            print("❌ Invalid choice. Please try again.")
            return True
            
    def run(self) -> None:
        """Main application loop"""
        self.log("Starting Master App...", LogLevel.INFO)
        
        while True:
            try:
                self.show_menu()
                choice = input("\nEnter your choice (1-12): ").strip()
                
                if not self.handle_menu_choice(choice):
                    break
                    
            except KeyboardInterrupt:
                self.log("\nApplication interrupted by user", LogLevel.WARNING)
                break
            except Exception as e:
                self.log(f"Unexpected error: {str(e)}", LogLevel.ERROR)
                break

def main():
    """Main entry point"""
    try:
        app = MasterApp()
        app.run()
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except Exception as e:
        print(f"❌ Fatal error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
