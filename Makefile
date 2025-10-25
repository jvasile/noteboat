# Makefile for Noteboat - builds both CLI and GUI executables

FLUTTER := /home/james/flutter/bin/flutter
DART := /home/james/flutter/bin/dart

# Build mode: debug or release (default: release)
MODE ?= release

ifeq ($(MODE),debug)
    BUILD_DIR := build/linux/x64/debug/bundle
    FLUTTER_FLAGS := --debug
else
    BUILD_DIR := build/linux/x64/release/bundle
    FLUTTER_FLAGS := --release
endif

CLI_TARGET := $(BUILD_DIR)/noteboat
GUI_TARGET := $(BUILD_DIR)/noteboat-gui

# Source files for dependency tracking
DART_SOURCES := $(shell find lib bin -name '*.dart' 2>/dev/null)
OTHER_SOURCES := pubspec.yaml pubspec.lock linux/CMakeLists.txt

.PHONY: all clean test help debug release install uninstall windows windows-debug windows-release windows-installer windows-installer-debug windows-installer-release web web-debug web-release

# Default target
all: $(GUI_TARGET) $(CLI_TARGET)

# Convenience targets for debug and release
debug:
	$(MAKE) MODE=debug all

release:
	$(MAKE) MODE=release all

# Windows build configuration
ifeq ($(MODE),debug)
    WIN_BUILD_DIR := build/windows/x64/runner/Debug
    WIN_FLUTTER_FLAGS := --debug
else
    WIN_BUILD_DIR := build/windows/x64/runner/Release
    WIN_FLUTTER_FLAGS := --release
endif

WIN_GUI_TARGET := $(WIN_BUILD_DIR)/noteboat-gui.exe
WIN_CLI_TARGET := $(WIN_BUILD_DIR)/noteboat.exe

# Windows build targets
windows: $(WIN_GUI_TARGET) $(WIN_CLI_TARGET)

windows-debug:
	$(MAKE) MODE=debug windows

windows-release:
	$(MAKE) MODE=release windows

$(WIN_GUI_TARGET): $(DART_SOURCES) $(OTHER_SOURCES)
	@echo "Generating version info..."
	@./scripts/generate_version.sh $(MODE)
	@echo "Building Flutter GUI for Windows as noteboat-gui.exe ($(MODE) mode)..."
	$(FLUTTER) build windows $(WIN_FLUTTER_FLAGS)
	@if [ -f "$(WIN_BUILD_DIR)/noteboat.exe" ]; then \
		mv "$(WIN_BUILD_DIR)/noteboat.exe" "$(WIN_GUI_TARGET)"; \
	fi
	@echo "✓ Windows Flutter GUI built"

$(WIN_CLI_TARGET): $(WIN_GUI_TARGET) bin/noteboat.dart $(DART_SOURCES)
	@echo "Building pure Dart CLI for Windows as noteboat.exe ($(MODE) mode)..."
	$(DART) compile exe bin/noteboat.dart -o $(WIN_CLI_TARGET)
	@echo "✓ Windows pure Dart CLI built"

# Windows MSIX installer targets
windows-installer: $(WIN_CLI_TARGET)
	@echo "Creating Windows MSIX installer ($(MODE) mode)..."
	$(FLUTTER) pub get
	$(DART) run msix:create
	@echo "✓ Windows MSIX installer created"
	@echo "Output: build/windows/x64/runner/Release/noteboat.msix"

windows-installer-debug:
	$(MAKE) MODE=debug windows-installer

windows-installer-release:
	$(MAKE) MODE=release windows-installer

# Web build configuration
WEB_BUILD_DIR := build/web

# NOTE: Web builds use conditional imports to exclude nvim_editor (which requires dart:ffi).
# On web, only the basic editor is available. Nvim mode is automatically disabled.

# Web build targets
web: web-release

web-debug:
	@echo "Generating version info..."
	@./scripts/generate_version.sh debug
	@echo "Building Flutter web app (debug mode)..."
	@echo "Note: Neovim editor mode is not available on web (basic editor only)."
	$(FLUTTER) build web --debug
	@echo "✓ Web app built in debug mode"
	@echo "Output: $(WEB_BUILD_DIR)/"
	@echo ""
	@echo "To serve locally:"
	@echo "  cd $(WEB_BUILD_DIR) && python3 -m http.server 8000"
	@echo "  Then open: http://localhost:8000"

web-release:
	@echo "Generating version info..."
	@./scripts/generate_version.sh release
	@echo "Building Flutter web app (release mode)..."
	@echo "Note: Neovim editor mode is not available on web (basic editor only)."
	$(FLUTTER) build web --release
	@echo "✓ Web app built in release mode"
	@echo "Output: $(WEB_BUILD_DIR)/"
	@echo ""
	@echo "To serve locally:"
	@echo "  cd $(WEB_BUILD_DIR) && python3 -m http.server 8000"
	@echo "  Then open: http://localhost:8000"

# Build GUI - depends on source files
$(GUI_TARGET): $(DART_SOURCES) $(OTHER_SOURCES)
	@echo "Generating version info..."
	@./scripts/generate_version.sh $(MODE)
	@echo "Building Flutter GUI as noteboat-gui ($(MODE) mode)..."
	$(FLUTTER) build linux $(FLUTTER_FLAGS)
	@echo "✓ Flutter GUI built"

# Build CLI - depends on GUI for bundle directory structure and on source files
$(CLI_TARGET): $(GUI_TARGET) bin/noteboat.dart $(DART_SOURCES)
	@echo "Building pure Dart CLI as noteboat ($(MODE) mode)..."
	$(DART) compile exe bin/noteboat.dart -o $(CLI_TARGET)
	@echo "✓ Pure Dart CLI built"

# Run tests
test:
	@echo "Running tests..."
	$(FLUTTER) test

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	$(FLUTTER) clean
	@echo "✓ Build directory cleaned"

# Install to system
PREFIX ?= /usr/local
INSTALL_DIR := $(PREFIX)/bin
BUNDLE_INSTALL_DIR := /opt/noteboat

install:
	@echo "Installing noteboat..."
	@# Check if build artifacts exist
	@if [ ! -f "$(GUI_TARGET)" ] || [ ! -f "$(CLI_TARGET)" ]; then \
		echo "Error: Build artifacts not found."; \
		echo ""; \
		echo "Please build the project first as a regular user:"; \
		echo "  make"; \
		echo ""; \
		echo "Then run install with sudo:"; \
		echo "  sudo make install"; \
		echo ""; \
		exit 1; \
	fi
	@echo "  Copying bundle to $(BUNDLE_INSTALL_DIR)..."
	install -d $(BUNDLE_INSTALL_DIR)
	cp -r $(BUILD_DIR)/* $(BUNDLE_INSTALL_DIR)/
	@echo "  Creating symlinks in $(INSTALL_DIR)..."
	install -d $(INSTALL_DIR)
	ln -sf $(BUNDLE_INSTALL_DIR)/noteboat $(INSTALL_DIR)/noteboat
	ln -sf $(BUNDLE_INSTALL_DIR)/noteboat-gui $(INSTALL_DIR)/noteboat-gui
	@echo "✓ Installed noteboat to $(INSTALL_DIR)/noteboat"
	@echo "✓ Installed noteboat-gui to $(INSTALL_DIR)/noteboat-gui"
	@echo "✓ Bundle installed to $(BUNDLE_INSTALL_DIR)"

# Uninstall from system
uninstall:
	@echo "Uninstalling noteboat..."
	rm -f $(INSTALL_DIR)/noteboat
	rm -f $(INSTALL_DIR)/noteboat-gui
	rm -rf $(BUNDLE_INSTALL_DIR)
	@echo "✓ Uninstalled"

# Show help
help:
	@echo "Noteboat Build Targets:"
	@echo ""
	@echo "Linux builds:"
	@echo "  make              - Build both CLI and GUI for Linux in release mode (default)"
	@echo "  make all          - Build both CLI and GUI for Linux"
	@echo "  make release      - Build both for Linux in release mode"
	@echo "  make debug        - Build both for Linux in debug mode"
	@echo ""
	@echo "Windows builds:"
	@echo "  make windows                - Build both CLI and GUI for Windows in release mode"
	@echo "  make windows-release        - Build both for Windows in release mode"
	@echo "  make windows-debug          - Build both for Windows in debug mode"
	@echo "  make windows-installer      - Build and create MSIX installer (release mode)"
	@echo "  make windows-installer-debug   - Build and create MSIX installer (debug mode)"
	@echo ""
	@echo "Web builds:"
	@echo "  make web                    - Build web app in release mode (default)"
	@echo "  make web-release            - Build web app in release mode"
	@echo "  make web-debug              - Build web app in debug mode"
	@echo "  Note: Neovim editor not available on web (basic editor only)"
	@echo ""
	@echo "Other targets:"
	@echo "  make test         - Run test suite"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make install      - Install to system (Linux only, requires sudo)"
	@echo "  make uninstall    - Remove from system (Linux only, requires sudo)"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "Build modes:"
	@echo "  MODE=release      - Optimized release build (default)"
	@echo "  MODE=debug        - Debug build with symbols"
	@echo ""
	@echo "Installation (Linux only):"
	@echo "  make                        # Build first as regular user"
	@echo "  sudo make install           # Then install to /opt/noteboat and /usr/local/bin"
	@echo "  sudo make install PREFIX=/  # Install to /opt/noteboat and /bin"
	@echo ""
	@echo "Examples:"
	@echo "  make                              # Linux release build"
	@echo "  make debug                        # Linux debug build"
	@echo "  make windows                      # Windows release build"
	@echo "  make windows-installer            # Windows MSIX installer"
	@echo "  make web                          # Web release build"
	@echo ""
	@echo "Current mode: $(MODE)"
	@echo ""
	@echo "Linux output directory: $(BUILD_DIR)/"
	@echo "  noteboat      - CLI executable"
	@echo "  noteboat-gui  - GUI executable"
	@echo "  lib/          - Flutter engine libraries"
	@echo "  data/         - Flutter assets"
	@echo ""
	@echo "Windows output directory: $(WIN_BUILD_DIR)/"
	@echo "  noteboat.exe      - CLI executable"
	@echo "  noteboat-gui.exe  - GUI executable"
	@echo "  *.dll             - Flutter engine DLL files"
	@echo "  data/             - Flutter assets"
	@echo ""
	@echo "Web output directory: $(WEB_BUILD_DIR)/"
	@echo "  index.html        - Entry point"
	@echo "  main.dart.js      - Compiled Dart code"
	@echo "  flutter_service_worker.js - Service worker for PWA support"
	@echo "  assets/           - Flutter assets"
