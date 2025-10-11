# Development Guidelines

## Command-line Tools

- Always run gsed "gnu sed" instead of sed
- Use ripgrep (rg) instead of grep
- Use fd instead of find
- Use tree command where appropriate
- ALWAYS use the gh cli instead of web fetches for GitHub operations

## Tool Usage & Performance

- Use specialized agents: test-engineer for TDD/test reviews, code-reviewer after significant changes
- Make parallel tool calls when operations are independent
- Use dedicated file tools (Read, Edit, Write) instead of bash commands

## Task Management

- Use TodoWrite for tasks with 3+ steps
- Mark todos as completed immediately after finishing
- Only one todo in_progress at a time

## Git and Commit Guidelines

- Use the `/commit` command for detailed best practices
- DO not ever use --no-verify with git commit

## Debugging and Problem Solving

- When addressing failing tests, understand the problem to identify the proper fix instead of "just trying to make the test pass"

## Test-Driven Development

- Follow Red-Green-Refactor: Write failing test → Minimal code to pass → Refactor
- Write tests before implementation
- Verify tests fail before implementing (confirm Red phase)
- Run full test suite before considering work complete

## General Guidelines

- Follow existing codebase patterns and conventions
- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files over creating new ones
- NEVER proactively create documentation files unless explicitly requested
