# Zed Editor Setup for Sui Move Development

This directory contains configuration files to optimize Zed editor for Sui Move development in this project.

## Files Overview

### `settings.json`
Project-specific Zed settings that configure:
- Move language server (`move-analyzer`) with Sui dialect
- Code formatting and display preferences
- UI layout and panel configuration
- Syntax highlighting for `.move` files

### `tasks.json`
Predefined tasks for common Sui Move development workflows:
- **Build**: Compile the Move package
- **Test**: Run Move unit tests
- **Clean**: Clean build artifacts
- **Format**: Format Move code
- **Lint**: Run Move linter
- **Deploy (Testnet)**: Deploy to Sui testnet
- **Check Dependencies**: Verify package dependencies

## Prerequisites

1. **Sui CLI**: Ensure `sui` command is available in your PATH
   ```bash
   sui --version
   ```

2. **Move Analyzer**: Language server for Move (should be at `~/.local/bin/move-analyzer`)
   ```bash
   which move-analyzer
   ```

## Features Enabled

- ✅ Sui Move standard library recognition
- ✅ Syntax highlighting and error detection
- ✅ Auto-completion for Sui types (ID, String, etc.)
- ✅ Code formatting on save
- ✅ Integrated build and test tasks
- ✅ Problem detection and reporting

## Usage

### Running Tasks
Use Zed's command palette (`Cmd+Shift+P`) and search for "Tasks" to run any of the predefined tasks.

### Quick Actions
- `Cmd+S`: Save and auto-format
- `Cmd+Shift+P` → "Build": Compile the project
- `Cmd+Shift+P` → "Test": Run tests

## Troubleshooting

### Language Server Not Working
1. Verify `move-analyzer` is installed and in PATH
2. Restart Zed editor
3. Check Zed logs for language server errors

### Build Errors
1. Ensure `sui` CLI is properly installed
2. Check that `Move.toml` has correct dependencies
3. Run `sui move build` in terminal to see detailed errors

### Standard Library Not Recognized
This should be resolved with the current setup, but if issues persist:
1. Verify the Sui framework dependency in `Move.toml`
2. Run `sui move build` to update dependencies
3. Restart the language server

## Configuration Details

The setup uses:
- **Framework**: Sui mainnet framework
- **Edition**: 2024.beta
- **Tab Size**: 4 spaces
- **Line Length**: 100 characters
- **Language Server**: move-analyzer with Sui dialect

For global Zed settings, modify `~/.config/zed/settings.json` instead of the project-specific files in this directory.