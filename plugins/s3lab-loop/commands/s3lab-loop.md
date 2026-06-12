---
description: Run the s3lab-loop orchestrator on a goal — research, draft, critique, refine, return final.
argument-hint: "<goal text>"
allowed-tools: Agent
---

Spawn the `loop-orchestrator` subagent. Use the text below as the orchestrator's prompt verbatim:

$ARGUMENTS

When the orchestrator returns its result, output that result verbatim. Do not summarize. Do not edit. Do not add commentary. Do nothing else after the orchestrator returns.
