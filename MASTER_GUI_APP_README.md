# iSuite Master GUI App

A comprehensive Python GUI application for building and running the iSuite Flutter project with advanced console logging, error analysis, and build management features.

## 🚀 Features

### **Core Functionality**
- **Cross-Platform Build Support**: Build and run Flutter apps for Windows, Android, iOS, and Web
- **Real-time Console Logging**: Live output with color-coded messages (success, error, warning, info)
- **Advanced Error Analysis**: Automatic error categorization and troubleshooting suggestions
- **Build History & Statistics**: Track build performance, success rates, and timing
- **Progress Monitoring**: Visual progress bars for build operations

### **User Experience**
- **Keyboard Shortcuts**: Fast access to common actions (F5-F10, Ctrl+L/S, F1 for help)
- **Theme Support**: Light and dark themes for comfortable usage
- **Auto-Save**: Automatic saving of logs and build history every 30 seconds
- **Menu-Driven Interface**: Organized menus for all functionality
- **Status Indicators**: Real-time status updates and error/warning counters

### **Developer Tools**
- **Flutter Integration**: Direct integration with Flutter CLI commands
- **Dependency Management**: Get, upgrade, and manage Flutter packages
- **Code Quality**: Analyze, format, and test Flutter code
- **Project Management**: Select different project directories

## 📋 Requirements

- **Python 3.7+** (uses only standard library)
- **Flutter SDK** installed and in PATH
- **Platform-specific SDKs** (Android SDK, Xcode for iOS, etc.)

## 🚀 Quick Start

### **Option 1: Launcher Script (Recommended)**
```bash
# Double-click or run the batch file
run_master_gui_app.bat
```

### **Option 2: Direct Python Execution**
```bash
python master_gui_app.py
```

## 🎮 Keyboard Shortcuts

### **Build & Run**
- **F5**: Build Windows
- **F6**: Run Windows
- **F8**: Build APK
- **F9**: Run Android

### **Tools**
- **F7**: Switch Theme (Light/Dark)
- **F10**: Flutter Doctor

### **Logs**
- **Ctrl+L**: Clear Logs
- **Ctrl+S**: Save Logs

### **Help**
- **F1**: Show Keyboard Shortcuts Help

## 📁 Menu Structure

### **File Menu**
- **Settings**: Configure Flutter SDK path
- **Select Project**: Choose different Flutter project directory
- **Exit**: Close application

### **Build Menu**
- Build Windows/APK/iOS/Web
- All platform-specific build commands

### **Run Menu**
- Run Windows/Android/iOS/Web
- Platform-specific run commands

### **Tools Menu**
- **Flutter Doctor**: Check Flutter installation
- **Clean Project**: Remove build artifacts
- **Get/Upgrade Dependencies**: Manage packages
- **Analyze/Format Code**: Code quality tools
- **Run Tests**: Execute Flutter tests

### **View Menu**
- **Switch Theme**: Toggle light/dark mode
- **Auto-Save Enabled**: Toggle automatic saving (default: ON)
- **Build Statistics**: View build performance metrics
- **Build History**: Detailed build attempt history
- **Error Summary**: Categorized error analysis

### **Help Menu**
- **About**: Application information

## 🔧 Configuration

### **Settings File**
Configuration is automatically saved to:
```
~/.isuite_master_config.json
```

### **Auto-Save Directory**
Logs and build history are auto-saved to:
```
~/.isuite_auto_save/
```

### **Build History**
Persistent build statistics and history:
```
~/.isuite_master_build_history.json
```

## 📊 Build Analytics

### **Real-time Statistics**
- Total builds attempted
- Success/failure rates
- Average build times
- Last build timestamp

### **Build History**
- Detailed log of all build attempts
- Command executed
- Duration and success status
- Error messages (if failed)
- Platform information

## 🐛 Error Analysis

### **Automatic Error Categorization**
- **CRITICAL**: Fatal errors and crashes
- **BUILD**: Compilation and build failures
- **DEP**: Dependency and package issues
- **NET**: Network and connection problems
- **PERM**: Permission and access issues
- **ANDROID/IOS/WINDOWS**: Platform-specific errors
- **FLUTTER**: Flutter framework issues

### **Smart Troubleshooting**
- Context-aware error analysis
- Platform-specific suggestions
- Common fix recommendations
- Dependency resolution hints

## 🎨 Themes

### **Light Theme**
- Clean, bright interface
- High contrast for readability
- Standard color scheme

### **Dark Theme**
- Easy on the eyes for long sessions
- Modern dark UI elements
- Maintained readability

## 🔄 Auto-Save System

### **Automatic Saving**
- **Interval**: Every 30 seconds
- **Data Saved**: Console logs, build history, configuration
- **Retention**: Last 10 auto-saved log files kept
- **Emergency Save**: Triggered on application close/crash

### **Manual Controls**
- Toggle auto-save on/off via View menu
- Manual log saving with Ctrl+S
- Export error logs for sharing

## 🚀 Advanced Features

### **Command Queue**
- Sequential execution of build commands
- Prevents command conflicts
- Queue status monitoring

### **System Notifications**
- Build completion alerts
- Error notifications
- Progress updates (if supported by OS)

### **Progress Tracking**
- Visual progress bars
- Build percentage completion
- Time estimation

## 🛠️ Troubleshooting

### **Common Issues**

**Flutter SDK Not Found**
```
Error: 'flutter' command not found
```
**Solution**: Set Flutter path in Settings or add to system PATH

**Build Failures**
- Check console output for specific errors
- Use "Error Summary" to categorize issues
- Follow automatic troubleshooting suggestions

**Permission Errors**
- Ensure write access to project directory
- Check Flutter SDK permissions
- Verify platform SDK installations

**Network Issues**
- Check internet connection
- Verify proxy settings if applicable
- Use offline mode if available

### **Debug Information**
- Use **F10** (Flutter Doctor) to check environment
- View detailed error logs in auto-save directory
- Check build history for patterns

## 📈 Performance Tips

### **Build Optimization**
- Use appropriate build modes (debug/profile/release)
- Clean project regularly to remove artifacts
- Keep dependencies updated

### **UI Responsiveness**
- Auto-save runs in background threads
- Command execution is asynchronous
- Progress bars provide visual feedback

### **Storage Management**
- Auto-save maintains only recent files
- Build history limited to last 100 entries
- Emergency saves prevent data loss

## 🔧 Customization

### **Adding New Commands**
Modify `master_gui_app.py` to add custom build/run commands:
```python
def custom_build_command(self):
    cmd = ["flutter", "build", "custom", "--options"]
    self.run_command_async(cmd, "Custom Build")
```

### **Extending Error Analysis**
Add custom error patterns in `analyze_error_line()`:
```python
if "custom_error" in line_lower:
    self.log("💡 Custom error detected - try this fix", "info")
```

## 📝 Version History

- **v2.0**: Complete rewrite with advanced features
  - Auto-save system
  - Keyboard shortcuts
  - Enhanced error analysis
  - Build statistics
  - Theme support

## 🤝 Contributing

To extend the application:
1. Fork and clone the repository
2. Add features following the existing patterns
3. Test thoroughly across platforms
4. Submit pull request with documentation

## 📄 License

This application is part of the iSuite project and follows the same licensing terms.

---

**Built with ❤️ for Flutter developers**
