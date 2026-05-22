---
name: dotnet-testing
description: Unit/integration tests must use xUnit and Moq in this solution.
globs: src/**/*.cs
always_apply: false
---

# Tests (Tiss.Chatbot)

- Проект тестов: `src/Tiss.Chatbot.Test` — пакеты **xunit**, **xunit.runner.visualstudio**, **Moq**.
- Не добавлять **NUnit** и не смешивать фреймворки в одном проекте.
- Предпочитать `[Theory]` + `[InlineData]` / `[MemberData]` для наборов входов; имена тестов отражают сценарий.
- Доступ к БД в **модульных** тестах — через моки (`Mock<>`, in-memory только если явно принято командой); интеграция с реальной БД — отдельный тип тестов и явное согласование.
- Подробный playbook: `.ai/skills/dotnet/dotnet_unit_tests_xunit_moq.md`.
