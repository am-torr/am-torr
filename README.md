<h1 align="center">Hi, I'm Arvin</h1>
<h3 align="center">Senior Software & Data Engineer | Automation, Agentic Systems & Enterprise Data</h3>

<p align="center">
  <a href="https://linkedin.com/in/arvintorralba012">
    <img src="https://img.shields.io/badge/LinkedIn-Arvin%20Torralba-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
  </a>
</p>

---

### About Me

I'm a senior software and data engineer working at the intersection of **enterprise data, workflow automation, and agentic AI**.

My background is 10+ years across Oracle/SQL/PLSQL, enterprise integrations, and production support, followed by hands-on Python/AWS data-engineering work with Glue/PySpark pipelines. More recently, I've been building personal portfolio systems around **n8n, APIs, PostgreSQL/Supabase, Claude Code, Codex, Claude Agent SDK, MCP, and human-gated agent workflows**.

The common thread in my work is operational ownership: understand the whole flow, make failures observable, keep risky actions bounded, and verify the result instead of trusting a tool or agent simply because it reported success.

---

### Current Stack

**AI / Agentic** -- Claude Code | Codex | Claude Agent SDK | Anthropic API | MCP | Human-in-the-Loop | independent agent checking

**Pipelines / Automation** -- n8n | FastAPI | Playwright | Docker Compose | REST/webhooks | scheduled workflows

**Data** -- Python | PySpark | SQL | PL/SQL | PostgreSQL | Supabase | AWS Glue | S3 | Lambda

**Engineering / Ops** -- TypeScript/React | PowerShell + Pester | Git | GitHub Actions | CloudWatch | OpenSearch/Kibana

---

### Featured Projects

#### Gunpla Scarcity Content Pipeline | 2026 (Public)

Repository: [am-torr/gunpla_project_01](https://github.com/am-torr/gunpla_project_01)

- Built a self-hosted n8n pipeline for low-stock Gunpla items: **Ingest -> Queue -> Batch -> Publish**, with Python/Playwright scraping, PostgreSQL/Supabase state, Facebook Graph API publishing, and Docker Compose.
- The core path has successfully posted to Facebook. JavaScript Code nodes handle deduplication, transformations, formatting, payload construction, and API response/status handling.
- Reliability controls include content fingerprinting/idempotency, repost-cooldown rules, retry/fallback handling, and persisted staging/queue/batch states so a workflow success message is not the only evidence that a post completed.

#### EOS (Executive Operating System) & Ralph Loop | 2026 (Private)

- A human-gated agent orchestration system that moves build-ready PRDs through routing/validation, explicit approval, isolated scratch execution, independent checking, and promotion.
- The Executor cannot self-certify its own work: a separately identified Checker can fail the task, and failed output is not promoted.
- Includes deterministic PowerShell/Pester tooling for queue state, crash recovery, promotion/reconciliation, audit receipts, and reusable skills/lessons.

#### Low-Stock Operations Agent | 2026 (Private)

- Built around the **Claude Agent SDK** for the same low-stock domain as the n8n pipeline, but with a deliberately separate safety boundary.
- The agent prepares drafts for review, writes only to its own draft/price-history data, and reads the live publishing queue through a read-only database path rather than having unrestricted write access.
- Uses generate-and-check behavior plus an offline/dry-run path so agent behavior can be tested without directly publishing or writing into the live post queue.

#### DaVinci Resolve MCP Server | 2026 (Private)

- Built a FastMCP stdio server that exposes DaVinci Resolve's official Python scripting API as **18 Claude Code tools** across project, timeline, clip, color, and render operations.
- Uses structured JSON error envelopes instead of crashing when Resolve is unavailable.
- Covered by unit tests plus a real MCP stdio-handshake test with a stubbed Resolve environment.

#### Resume / JD Diff | 2026 (Public Portfolio Edition)

Repository: [am-torr/resume-jd-diff](https://github.com/am-torr/resume-jd-diff)

- Privacy-first local React/TypeScript + Express app for DOCX/PDF resume comparison and resume-vs-JD analysis.
- The public repository is a runnable portfolio edition with simplified comparison engines; the private canonical project contains the deeper section/risk and layered JD-matching logic.
- Includes generated fixtures, smoke tests, unit/E2E coverage, and no requirement to upload personal documents to a third-party service.

---

### Portfolio Evidence Model

I keep some recruiter-facing projects as **sanitized public portfolio editions** rather than publishing a private development repository wholesale. The goal is to preserve enough real code, tests, architecture, and failure-handling logic to make the work inspectable without exposing credentials-adjacent configuration, local-machine details, internal logs, or unrelated history.

For private projects, I can provide selected screenshots, code excerpts, architecture views, and a walkthrough of the implementation when relevant to a role.
