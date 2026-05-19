# s3lab AI standards

You are working in an s3lab project that uses s3lab-ai-kit standards.
Kit version is in `.ai-kit/VERSION`.

This file is the single source of truth for all AI assistants working on the project.
It is imported into `CLAUDE.md` and referenced from `AGENTS.md` and Cursor rules.

@.ai-kit/ai/stack.md
@.ai-kit/ai/workflow.md
@.ai-kit/ai/conventions/dotnet.md
@.ai-kit/ai/conventions/angular.md
@.ai-kit/ai/conventions/rabbitmq.md
@.ai-kit/ai/conventions/postgres.md
@.ai-kit/ai/conventions/identity-auth.md
@.ai-kit/ai/conventions/git.md
@.ai-kit/ai/conventions/security.md

## Project-specific context

If the project provides additional context, it is in `.ai/project-context.md` and
is imported separately from the project's `CLAUDE.md`. Project context takes
precedence over kit defaults when they conflict.

## Available subagents

Located in `.ai-kit/ai/agents/`. Each has its own system prompt and tool permissions.

- `orchestrator` — decompose a task into ordered subtasks with agent assignments
- `backend-dotnet` — implement .NET 10 backend changes
- `frontend-angular` — implement Angular frontend changes
- `api-contract` — manage OpenAPI contract between backend and frontend
- `devops` — Docker, docker-compose, GitHub Actions, env configs
- `tester` — generate and run unit, integration, e2e tests
- `reviewer` — pre-merge code review
- `designer` — UX specs and mockups (until human designer joins)

## Available pipelines

Located in `.ai-kit/ai/commands/`. Invoke via slash commands in Claude Code.

- `/feature <description>` — full pipeline for a new feature
- `/bugfix <description>` — diagnose and fix a bug
- `/review-pr <number>` — review an existing PR
- `/sync-contract` — sync OpenAPI between backend and frontend

## Override mechanism

If a project needs to deviate from kit defaults, it puts override files in `.ai/overrides/`:

- `.ai/overrides/<agent-name>.md` — overrides a kit subagent's instructions
- `.ai/overrides/<convention-name>.md` — overrides a kit convention

Kit agents check for these files at start and apply them with precedence over the
kit defaults below.

## Hard rules

These apply regardless of project specifics:

- **Never commit secrets.** Use `.env` (gitignored) and `.env.example` (committed).
- **Never edit generated code by hand.** This includes OpenAPI clients, EF migrations
  already applied, and protobuf stubs.
- **Never bypass the contract.** Backend changes API → update OpenAPI → regenerate
  frontend client. Never write hand-rolled HTTP calls for project endpoints.
- **Plan before code on non-trivial work.** Invoke `orchestrator` first.
