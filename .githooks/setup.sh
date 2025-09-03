#!/bin/bash

# Setup script for MoonBit pre-commit hooks
# Run this script to configure Git hooks for this repository

echo "🔧 Setting up MoonBit pre-commit hooks..."

# Configure Git to use the custom hooks directory
git config core.hooksPath .githooks

# Make all hooks executable
chmod +x .githooks/*

echo "✅ Git hooks configured successfully!"
echo ""
echo "📝 The following hooks are now active:"
echo "   - pre-commit: Runs 'moon check' before each commit"
echo ""
echo "💡 To disable hooks temporarily, use: git commit --no-verify"
echo "   (Not recommended for production commits)"
echo ""
