# Crowd Walrus Move

A Sui Move smart contract project for crowd-sourced walrus management and coordination.

## Overview

This project contains Move modules for managing crowd-sourced walrus projects with administrative controls. The smart contracts are built using the Sui Move framework and are optimized for development with the Zed editor.

## Project Structure

```
crowd_walrus_move/
├── sources/           # Move source files
│   ├── admin.move     # Administrative functionality
│   ├── project.move   # Project management
│   └── crowd_walrus_mvoe.move  # Main module
├── tests/             # Unit tests
├── build/             # Build artifacts (ignored by git)
├── .zed/              # Zed editor configuration
│   ├── settings.json  # Editor settings
│   ├── tasks.json     # Development tasks
│   └── README.md      # Zed setup documentation
├── Move.toml          # Package configuration
├── Move.lock          # Dependency lock file
└── README.md          # This file
```

## Prerequisites

1. **Sui CLI**: Install the Sui command-line interface
   ```bash
   curl -fLSs https://sui.io/install.sh | bash
   ```

2. **Move Analyzer**: Language server for Move development
   ```bash
   cargo install --git https://github.com/move-language/move move-analyzer --features "address32"
   ```

3. **Zed Editor** (recommended): Download from [zed.dev](https://zed.dev)

## Getting Started

### 1. Clone and Build

```bash
cd crowd_walrus_move
sui move build
```

### 2. Run Tests

```bash
sui move test
```

### 3. Development with Zed

Open the project in Zed for the best development experience:

- ✅ Sui Move standard library recognition
- ✅ Syntax highlighting and error detection
- ✅ Auto-completion for Sui types
- ✅ Code formatting on save
- ✅ Integrated build and test tasks (Zed native format)
- ✅ 12 predefined tasks for common workflows
- ✅ Task validation and format checking

See `.zed/README.md` for detailed Zed setup information.

## Modules

### `admin.move`
Defines administrative structures and functionality for managing crowd walrus projects.

```move
public struct Admin {
    id: ID,
    name: String,
}
```

### `project.move`
Core project management functionality for crowd-sourced walrus coordination.

```move
public struct Project {
    id: ID,
    name: String,
    description: String,
}
```

## Development Workflow

### Using Zed Tasks

1. **Build**: `Cmd+Shift+P` → "task: spawn" → "Build"
2. **Test**: `Cmd+Shift+P` → "task: spawn" → "Test"
3. **Clean Build**: `Cmd+Shift+P` → "task: spawn" → "Clean Build"
4. **Format Code**: `Cmd+Shift+P` → "task: spawn" → "Format Code"
5. **Deploy to Testnet**: `Cmd+Shift+P` → "task: spawn" → "Deploy to Testnet"

Or use `task: rerun` to repeat the last task.

### Command Line

```bash
# Build the project
sui move build

# Run tests
sui move test

# Clean build artifacts
sui move build --clean

# Check dependencies
sui move build --check-dependencies
```

## Configuration

### Move.toml

The project uses:
- **Edition**: 2024.beta
- **Framework**: Sui mainnet framework
- **Dependencies**: Sui framework from GitHub

### Dependencies

The project automatically includes:
- `Sui`: Core Sui framework
- `MoveStdlib`: Standard Move library
- Standard types like `ID`, `String`, etc.

## Deployment

### Testnet Deployment

```bash
sui client publish --gas-budget 100000000
```

### Environment Setup

Make sure you have a Sui client configured:

```bash
sui client envs
sui client active-env
```

## Testing

Unit tests are located in the `tests/` directory. Run them with:

```bash
sui move test
```

For verbose output:

```bash
sui move test --verbose
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Build and test: `sui move build && sui move test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## Code Style

- Use 4 spaces for indentation
- Maximum line length: 100 characters
- Follow Sui Move conventions: [Sui Move Conventions](https://docs.sui.io/concepts/sui-move-concepts/conventions)

## Development Tools

### Task Validation
Validate Zed tasks configuration:
```bash
./.zed/validate-tasks.sh
```

This ensures tasks.json uses proper Zed format (not VS Code format).

## License

[Add your license information here]

## Resources

- [Sui Documentation](https://docs.sui.io/)
- [Move Language Book](https://move-language.github.io/move/)
- [Sui Move Examples](https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples)
- [Zed Editor](https://zed.dev/)

## Support

For questions and support:
- [Sui Discord](https://discord.gg/sui)
- [Move Language Forum](https://github.com/move-language/move/discussions)
- [Issues](../../issues)