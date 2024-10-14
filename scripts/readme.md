# MoonBit Test Agent

This repository includes the scripts and dependencies required for the Moonbit Test Agent. These scripts are utilized for coverage analysis and the generation of test cases within the Moonbit project.

## Script Description

- **Gettest.py**: Invokes the agent to generate test cases.
- **Readcoverage.py**: Reads the coverage report generated during testing and identifies uncovered code areas based on the index.
- **requirements**: Lists the dependencies needed to run the scripts.
- **TestAgent.py**: Serves as the workflow for the test agent, coordinating the execution of coverage analysis and test case generation.
- **Writedown.py**: Writes the generated test cases.
- **coverage_and_test.yml**: Defines the complete workflow.

### Installation

To use MoonBit_Test_Agent, you need to have an API key for ZhiPuAI.

1. Install MoonBit
   ```
   curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
   ```
2.Install the required dependencies:
   ```
   pip install -r requirements.txt
   ```
3.Add API key in the Github Secret

## Usage

The Agent depends on the workflow.

Our workflow includes "Build", "Test", "Typo Check", and "License Header Check"

### 1. Build Job
- **Steps**:
  1. **Checkout Repository**: Clones the repository.
  2. **Install Moonbit CLI**: Installs the Moonbit command-line interface.
  3. **Moon Version**: Displays the installed Moonbit version.
  4. **Moon Check**: Runs static analysis to check for warnings.
  5. **Moon Info**: Displays project information and checks for uncommitted changes.
  6. **Run Moon Tests**: Executes tests with and without optimizations.
  7. **Moon Bundle**: Bundles the project.
  8. **Check Core Size**: Lists core dump files.
  9. **Format Diff**: Checks for formatting issues.
  10. **Set up Python**: Installs Python 3.9.
  11. **Install Dependencies**: Installs required Python packages.

### 2. Test Job
- **Steps**:
  1. **Checkout Repository**: Clones the repository.
  2. **Install Moonbit CLI**: Installs the Moonbit command-line interface.
  3. **Initial Moon Test**: Runs tests with coverage enabled.
  4. **Initial Coverage Report**: Generates and displays a summary of test coverage.
  5. **Loop Coverage Improvement**: Iteratively runs tests to improve coverage.
  6. **Final Coverage Report**: Generates and sends a detailed coverage report to Coveralls.

### 3. Typo Check Job
- **Steps**:
  1. **Download Typos**: Installs the Typos tool.
  2. **Checkout Repository**: Clones the repository.
  3. **Check Typos**: Scans the codebase for common typos.

### 4. License Header Check Job
- **Steps**:
  1. **Checkout Repository**: Clones the repository.
  2. **Download HawkEye**: Installs the HawkEye tool.
  3. **Check License Header**: Ensures all files have the correct license header.


