import tkinter as tk
from tkinter import scrolledtext, messagebox, filedialog
import subprocess
import threading
import os

class BuildMasterApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Flutter Build Master")
        self.project_path = r"c:\Users\xxixw\Desktop\Projects\iSuite"
        self.flutter_path = ""  # Leave empty to use PATH

        # Create widgets
        self.log_text = scrolledtext.ScrolledText(root, width=80, height=20)
        self.log_text.pack(pady=10)

        button_frame = tk.Frame(root)
        button_frame.pack()

        tk.Button(button_frame, text="Build APK", command=self.build_apk).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Build iOS", command=self.build_ios).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Build Windows", command=self.build_windows).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Build Web", command=self.build_web).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Run Debug", command=self.run_debug).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Run Release", command=self.run_release).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Analyze", command=self.analyze).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Settings", command=self.open_settings).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Save Logs", command=self.save_logs).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="Clear Logs", command=self.clear_logs).pack(side=tk.LEFT, padx=5)

    def run_command(self, flutter_command):
        def worker():
            try:
                if self.flutter_path:
                    command = os.path.join(self.flutter_path, 'flutter') + ' ' + flutter_command
                else:
                    command = 'flutter ' + flutter_command
                process = subprocess.Popen(command, cwd=self.project_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, text=True)
                while True:
                    output = process.stdout.readline()
                    if output == '' and process.poll() is not None:
                        break
                    if output:
                        self.log_text.insert(tk.END, output)
                        self.log_text.see(tk.END)
                stderr = process.stderr.read()
                if stderr:
                    self.log_text.insert(tk.END, "ERROR: " + stderr, "error")
                    self.log_text.see(tk.END)
                rc = process.poll()
                if rc == 0:
                    self.log_text.insert(tk.END, "Command completed successfully.\n")
                else:
                    self.log_text.insert(tk.END, f"Command failed with exit code {rc}.\n", "error")
            except Exception as e:
                self.log_text.insert(tk.END, f"Exception: {e}\n", "error")
        thread = threading.Thread(target=worker)
        thread.start()

    def build_apk(self):
        self.run_command("build apk --release")

    def build_ios(self):
        self.run_command("build ios --release")

    def run_debug(self):
        self.run_command("run")

    def run_release(self):
        self.run_command("run --release")

    def build_windows(self):
        self.run_command("flutter build windows --release")

    def build_web(self):
        self.run_command("flutter build web --release")

    def analyze(self):
        self.run_command("flutter analyze")

    def open_settings(self):
        settings_window = tk.Toplevel(self.root)
        settings_window.title("Settings")

        tk.Label(settings_window, text="Project Path:").grid(row=0, column=0, padx=5, pady=5)
        project_entry = tk.Entry(settings_window, width=50)
        project_entry.insert(0, self.project_path)
        project_entry.grid(row=0, column=1, padx=5, pady=5)

        tk.Label(settings_window, text="Flutter Path:").grid(row=1, column=0, padx=5, pady=5)
        flutter_entry = tk.Entry(settings_window, width=50)
        flutter_entry.insert(0, self.flutter_path)
        flutter_entry.grid(row=1, column=1, padx=5, pady=5)

        def save_settings():
            self.project_path = project_entry.get()
            self.flutter_path = flutter_entry.get()
            settings_window.destroy()

        tk.Button(settings_window, text="Save", command=save_settings).grid(row=2, column=0, padx=5, pady=5)
        tk.Button(settings_window, text="Cancel", command=settings_window.destroy).grid(row=2, column=1, padx=5, pady=5)

    def save_logs(self):
        file_path = filedialog.asksaveasfilename(defaultextension=".txt", filetypes=[("Text files", "*.txt"), ("All files", "*.*")])
        if file_path:
            with open(file_path, 'w') as f:
                f.write(self.log_text.get(1.0, tk.END))

    def clear_logs(self):
        self.log_text.delete(1.0, tk.END)

if __name__ == "__main__":
    root = tk.Tk()
    app = BuildMasterApp(root)
    app.log_text.tag_config("error", foreground="red")
    root.mainloop()
