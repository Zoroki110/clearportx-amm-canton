# Contributing to ClearportX AMM

Thank you for your interest in contributing to ClearportX! This document provides guidelines for contributions.

## Code of Conduct

Be respectful, professional, and inclusive in all interactions.

## How to Contribute

### Reporting Bugs
1. Check existing issues first
2. Use bug report template
3. Include reproduction steps
4. Provide environment details

### Suggesting Features
1. Check existing feature requests
2. Describe use case clearly
3. Explain expected behavior
4. Consider implementation impact

### Pull Requests

#### Before Submitting
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write/update tests
5. Update documentation
6. Run tests (`make test`)
7. Commit with clear messages

#### PR Guidelines
- One feature/fix per PR
- Keep changes focused
- Update CHANGELOG.md
- Add tests for new code
- Ensure CI passes
- Request review from maintainers

#### Commit Messages
```
feat: Add multi-hop routing support
fix: Resolve slippage calculation bug
docs: Update API documentation
test: Add integration tests for swaps
chore: Update dependencies
```

### Development Setup

1. **Clone Repository:**
   ```bash
   git clone https://github.com/clearportx/clearportx-amm-canton
   cd clearportx-amm-canton
   ```

2. **Install Dependencies:**
   ```bash
   make setup
   ```

3. **Run Tests:**
   ```bash
   make test
   ```

4. **Start Development Environment:**
   ```bash
   make start
   ```

### Code Style

#### DAML
- Follow DAML style guide
- Use meaningful contract names
- Add comments for complex logic
- Include assertions with error messages

#### Backend (Kotlin/Java)
- Follow Kotlin coding conventions
- Use Spring Boot best practices
- Write clear method names
- Add JavaDoc for public APIs

#### Frontend (React/TypeScript)
- Use TypeScript strict mode
- Follow React best practices
- Use functional components
- Add JSDoc comments

#### Testing
- Write unit tests for all functions
- Add integration tests for workflows
- Maintain >80% code coverage
- Use descriptive test names

### Documentation

- Update README.md for major changes
- Add API documentation for new endpoints
- Update architecture docs if design changes
- Include examples in docs/

### Review Process

1. Automated checks run (CI/CD)
2. Code review by maintainer
3. Address feedback
4. Merge when approved

## Project Structure

```
clearportx-amm-canton/
├── daml/              # Smart contracts
├── backend/           # API server
├── frontend/          # Web UI
├── infrastructure/    # Deployment
├── docs/              # Documentation
└── test/              # Test suites
```

## Questions?

- GitHub Discussions: Ask questions
- Discord: Join our community
- Email: dev@clearportx.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
