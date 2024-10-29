# MoonBit Test Agent

This repository includes the scripts and dependencies required for the Moonbit Test Agent. These scripts are utilized for coverage analysis and the generation of test cases within the Moonbit project.

## Script Description

- **Main.py**: The main workflow of our Test Agent. Compared to using a LangChain agent, directly executing LLMs within a fixed task workflow can save more time.
- **Gettest.py**: Invokes the agent to generate test cases.
- **Readcoverage.py**: Reads the coverage report generated after testing and identifies uncovered code areas based on the index.
- **TestAgent.py**: Serves as the workflow for the generate test cases, coordinating the execution of coverage analysis and test case generation.
- **Writedown.py**: Test the test code and writes the generated test cases.
- **coverage_and_test.yml**: Defines the complete workflow.
- **requirements**: Lists the dependencies needed to run the scripts.

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
3.Add API_KEY in the Github Secret

## Usage

The Test Agent will work in the Github Actioon.
Our workflow includes "Test", "Typo Check", and "License Header Check".

### 1. Test Job
- **Steps**:
  1. **Install Dependencies**: Installs required Python packages.
  2. **Install Moonbit CLI**: Installs the Moonbit command-line interface.
  3. **Initial Moon Test**: Runs tests with coverage enabled.
  4. **Initial Coverage Report**: Generates and displays a summary of test coverage.
  5. **Coverage Improvement**: Iteratively runs tests to improve coverage.
  6. **Get code changes**: Captures any code changes made in the pull request and stores them for later use..
  7. **Push Comments**: Uses a GitHub Action to create or update a comment on the pull request with the changes to the test code.

### 2. Typo Check Job
- **Steps**:
  1. **Download Typos**: Installs the Typos tool.
  2. **Checkout Repository**: Clones the repository.
  3. **Check Typos**: Scans the codebase for common typos.

### 3. License Header Check Job
- **Steps**:
  1. **Checkout Repository**: Clones the repository.
  2. **Download HawkEye**: Installs the HawkEye tool.
  3. **Check License Header**: Ensures all files have the correct license header.
  2. **Download HawkEye**: Installs the HawkEye tool.
  3. **Check License Header**: Ensures all files have the correct license header.


