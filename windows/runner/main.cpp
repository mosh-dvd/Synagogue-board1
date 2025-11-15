#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// הוספת ספרייה לכתיבה לקבצים
#include <fstream> 
#include <string>
#include <chrono>
#include <ctime>

// פונקציה לכתיבת לוג שגיאות
void LogCrash(const std::string& error_message) {
    char app_path[MAX_PATH];
    GetModuleFileNameA(NULL, app_path, MAX_PATH);
    std::string path_str(app_path);
    size_t last_slash = path_str.find_last_of("\\/");
    std::string log_path = (last_slash != std::string::npos) ? path_str.substr(0, last_slash) : "";
    log_path += "\\native_crash_log.txt";

    std::ofstream log_file(log_path, std::ios_base::app);
    if (log_file.is_open()) {
        auto now = std::chrono::system_clock::now();
        std::time_t now_time = std::chrono::system_clock::to_time_t(now);
        char time_str[26];
        ctime_s(time_str, sizeof(time_str), &now_time);
        log_file << "--- Crash Report ---" << std::endl;
        log_file << "Timestamp: " << time_str; // ctime_s adds a newline
        log_file << "Error: " << error_message << std::endl;
        log_file << "--------------------" << std::endl << std::endl;
        log_file.close();
    }
}


int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  
  // עטיפת כל הקוד ב-try...catch
  try {
    // Attach to console when present (e.g., 'flutter run') or create a
    // new console when running with a debugger.
    if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
      CreateAndAttachConsole();
    }

    // Initialize COM, so that it is available for use in the library and/or
    // plugins.
    ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    flutter::DartProject project(L"data");

    std::vector<std::string> command_line_arguments =
        GetCommandLineArguments();

    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    if (!window.Create(L"synagogue_display", origin, size)) {
      return EXIT_FAILURE;
    }
    window.SetQuitOnClose(true);

    ::MSG msg;
    while (::GetMessage(&msg, nullptr, 0, 0)) {
      ::TranslateMessage(&msg);
      ::DispatchMessage(&msg);
    }

    ::CoUninitialize();
    return EXIT_SUCCESS;
  } catch (const std::exception& e) {
      LogCrash("Standard Exception: " + std::string(e.what()));
      return EXIT_FAILURE;
  } catch (...) {
      LogCrash("Unknown exception caught in wWinMain.");
      return EXIT_FAILURE;
  }
}