set quiet

# Run all linters and formatters
check: lint format-check

# Run luacheck linter
lint:
  luacheck .

# Format code with stylua
format:
  stylua .

# Check formatting without making changes
format-check:
  stylua --check .
