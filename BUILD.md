# Building Noteboat

This document describes how to build Noteboat from source on different platforms.

## Prerequisites

### All Platforms

- **Flutter SDK** - Download from [flutter.dev](https://flutter.dev)
- **Git** - For cloning the repository

### Linux

- Standard development tools (`build-essential` on Debian/Ubuntu)
- GTK 3.0 development libraries:
  ```bash
  sudo apt-get install libgtk-3-dev
  ```

### Windows

- **Visual Studio 2022** (Community Edition is free)
  - Install with "Desktop development with C++" workload
- **Git for Windows** - Includes Git Bash with `make` support

## Building

### Using Make (Recommended)

The project includes a Makefile that handles building both the CLI and GUI executables.

#### Linux Builds

```bash
# Release build (default)
make

# Debug build
make debug

# Run tests
make test

# Clean build artifacts
make clean

# Install to system (requires sudo)
sudo make install

# Show all available targets
make help
```

Output will be in `build/linux/x64/release/bundle/`:
- `noteboat` - CLI executable
- `noteboat-gui` - GUI executable
- `lib/` - Flutter engine libraries
- `data/` - Flutter assets

#### Windows Builds

```bash
# Release build (default)
make windows

# Debug build
make windows-debug

# Create MSIX installer (recommended for distribution)
make windows-installer

# Debug MSIX installer
make windows-installer-debug

# Clean build artifacts
make clean

# Show all available targets
make help
```

**Regular build output** will be in `build/windows/x64/runner/Release/`:
- `noteboat.exe` - CLI executable
- `noteboat-gui.exe` - GUI executable
- `*.dll` - Flutter engine DLL files
- `data/` - Flutter assets

**MSIX installer output** will be in `build/windows/x64/runner/Release/`:
- `noteboat.msix` - Windows installer package

**Note:** On Windows, run these commands from Git Bash (included with Git for Windows).

## Distribution

### Linux

After building, the entire bundle directory must be distributed together:
```bash
cp -r build/linux/x64/release/bundle noteboat-linux
zip -r noteboat-linux.zip noteboat-linux/
```

Or install system-wide:
```bash
sudo make install
```

### Windows

#### Option 1: MSIX Installer (Recommended)

After building with `make windows-installer`, distribute the MSIX file:

```bash
# The installer is ready to distribute
ls build/windows/x64/runner/Release/noteboat.msix
```

Users can double-click `noteboat.msix` to install. The app will be installed to their Windows apps and appear in the Start Menu.

**Requirements:**
- Windows 10 version 1809 or later
- For production distribution, you should sign the MSIX with a trusted certificate (see Configuration section below)

#### Option 2: Portable Bundle

After building with `make windows`, distribute the entire Release directory:

```bash
# From Git Bash
cp -r build/windows/x64/runner/Release noteboat-windows
zip -r noteboat-windows.zip noteboat-windows/

# Or from PowerShell/CMD
xcopy /E /I build\windows\x64\runner\Release noteboat-windows
```

Users can then run `noteboat.exe` or `noteboat-gui.exe` from the extracted directory. This option works on any Windows version but requires manual setup.

## Development

### Quick Testing

```bash
# Run tests
make test

# Run GUI in development mode
flutter run -d linux    # or -d windows
```

### Build Modes

- **Release mode** (default): Optimized, smaller binaries
- **Debug mode**: Includes debugging symbols, larger binaries

```bash
# Explicit mode specification
make MODE=release
make MODE=debug windows
```

## Configuration

### MSIX Installer Signing (Windows)

The default MSIX configuration in `pubspec.yaml` uses a self-signed certificate for development/testing. For production distribution, you should sign with a trusted certificate:

1. **Obtain a code signing certificate** from a trusted Certificate Authority
2. **Update `pubspec.yaml`** with your certificate details:

```yaml
msix_config:
  display_name: Noteboat
  publisher_display_name: Your Company Name
  identity_name: com.yourcompany.noteboat
  publisher: CN=Your Company Name
  certificate_path: path/to/your/certificate.pfx
  certificate_password: your_certificate_password
```

3. **Update other fields** as needed:
   - `display_name`: The name shown to users
   - `publisher_display_name`: Your organization name
   - `identity_name`: Unique identifier (reverse domain notation)

For development and testing, the default self-signed certificate will work, but Windows will show a security warning during installation.

## Troubleshooting

### Flutter not found

If `make` reports that Flutter is not found, the Makefile expects Flutter at `/home/james/flutter/bin/flutter`. Update the `FLUTTER` and `DART` variables at the top of the Makefile to match your Flutter installation:

```makefile
FLUTTER := /path/to/your/flutter/bin/flutter
DART := /path/to/your/flutter/bin/dart
```

Or on Windows in Git Bash:
```makefile
FLUTTER := /c/Users/YourName/flutter/bin/flutter
DART := /c/Users/YourName/flutter/bin/dart
```

### Windows build fails

Ensure Visual Studio 2022 is installed with the "Desktop development with C++" workload. You may need to run:

```bash
flutter doctor
```

to verify your Windows development environment is properly configured.

### Linux build fails

Ensure GTK development libraries are installed:

```bash
sudo apt-get install libgtk-3-dev pkg-config
```

### MSIX creation fails

If `make windows-installer` fails, ensure:

1. **Dependencies are installed:**
   ```bash
   flutter pub get
   ```

2. **Windows build completed successfully** - The MSIX installer requires a successful Windows build first

3. **Check for specific errors** in the output - the msix package will provide detailed error messages

## Cross-Compilation

You can build Windows executables from Linux (WSL2 or native Linux) using `make windows` and `make windows-installer`, and the binaries/installer can be copied to Windows to run. However, you must have Flutter's Windows build tools configured even on Linux.
