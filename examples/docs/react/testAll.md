# testAll — comprehensive test runner with failure tracking

Executes the complete Jest test suite and automatically captures failing test files for easy re-running and debugging. Ideal for CI/CD workflows and comprehensive test analysis.

## Synopsis

```bash
drun react/testAll
```

## Description

Runs the full Jest test suite using `yarn test --watchAll=false`, captures all output for analysis, and extracts failing test file paths into a convenient format. The script provides two key outputs:

- **Complete test log**: Full test output saved to `test_output.out`
- **Failure summary**: Failing test files saved to `files_with_error.out`

## Features

- **Non-interactive execution**: Runs all tests without watch mode
- **Complete output capture**: Saves full test results for later analysis
- **Failure extraction**: Isolates failing test files for targeted re-runs
- **Deduplication**: Removes duplicate file paths from failure list
- **Ready-to-run format**: Failure list formatted for immediate re-execution

## Output Files

### test_output.out
Contains the complete Jest test execution output, including:
- Test suite summaries
- Individual test results
- Coverage information (if enabled)
- Error messages and stack traces
- Performance metrics

### files_with_error.out
Contains a clean list of failing test files with `FAIL` replaced by `clear; yarn test` for easy copy-paste execution:

```bash
clear; yarn test src/components/Button.test.js
clear; yarn test src/utils/helpers.test.js
clear; yarn test src/services/api.test.js
```

## Usage Examples

### Basic Test Run
```bash
# Run all tests and capture failures
drun react/testAll

# Check results
cat test_output.out     # Full test log
cat files_with_error.out   # Failed tests only
```

### Re-running Failed Tests
```bash
# Run testAll first
drun react/testAll

# Re-run only the failed tests
bash files_with_error.out

# Or run them individually
clear; yarn test src/components/Button.test.js
```

### CI/CD Integration
```bash
# In CI pipeline
drun react/testAll

# Check if any tests failed
if [[ -s files_with_error.out ]]; then
  echo "Tests failed. See files_with_error.out for details"
  exit 1
fi
```

### Development Workflow
```bash
# After making changes, run full test suite
drun react/testAll

# If failures exist, work on them iteratively
while [[ -s files_with_error.out ]]; do
  # Fix failing tests
  # Re-run specific tests
  clear; yarn test $(head -1 files_with_error.out | awk '{print $NF}')
  # Re-run full suite
  drun react/testAll
done
```

## Prerequisites

- **Node.js project** with Jest configured
- **yarn** package manager
- **Jest test files** following standard naming conventions
- **package.json** with `test` script defined

## Performance Considerations

- **Full suite execution**: Runs all tests, which may take significant time
- **Output capture**: Stores complete logs, may use disk space for large test suites
- **Memory usage**: Non-watch mode is more memory efficient than interactive mode

## Integration

### Package.json Scripts
```json
{
  "scripts": {
    "test": "jest",
    "test:all": "drun react/testAll",
    "test:failed": "bash files_with_error.out"
  }
}
```

### Git Hooks
```bash
# Pre-commit hook
#!/bin/bash
drun react/testAll
if [[ -s files_with_error.out ]]; then
  echo "Cannot commit: tests are failing"
  exit 1
fi
```

## Related Commands

- **yarn test** - Interactive Jest test runner
- **yarn test --watch** - Watch mode for development
- **jest --coverage** - Test coverage analysis
- **drun react/rnewc** - Create new components with tests

## See Also

- [Jest Documentation](https://jestjs.io/) - Jest testing framework
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/) - Component testing utilities
