<h1 align="center">Hi, I'm Arvin</h1>
<h3 align="center">Senior Enterprise Data & Integration Engineer | Human-Gated AI Automation & Verification</h3>

<p align="center">
  <a href="https://linkedin.com/in/arvintorralba012">
    <img src="https://img.shields.io/badge/LinkedIn-Arvin%20Torralba-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
  </a>
</p>

---

### About Me

I am a senior enterprise data and integration engineer with 12 years of production experience across Oracle, SQL/PLSQL, enterprise system integrations, and AWS data operations (owned day-to-day AWS Glue monitoring and support).

Since 2025, I have focused on AI automation pipelines built around human review and independent verification using Python, n8n, PostgreSQL/Supabase, AI agents, and MCP. I focus on understanding the full flow, handling failures, and verifying the result.

---

### Selected Projects

#### Gunpla Scarcity Content Pipeline (Public)

- Built an n8n pipeline for low-stock listings: **Ingest -> Queue -> Batch -> Publish**, using Python/Playwright, PostgreSQL/Supabase, Docker Compose, and the Facebook Graph API.
- Added deduplication, content fingerprints, queue state tracking, and retry handling. The repository documents successful Facebook publishing.

[Source and sample output](https://github.com/am-torr/gunpla_project_01). Approval and archiving are in progress.

#### EOS / Ralph Loop (Private prototype)

- Built approval, checker identity, and promotion checks for an agent-assisted engineering workflow.
- Includes PowerShell/Pester tooling for queue state, recovery, and audit receipts.

Code walkthrough available.

#### Enterprise Data Migration, CDC & Lakehouse Lab (Public)

- Built a four-stage runnable ETL and migration lab: **Batch Star Schema (v1) -> Incremental CDC + Reconciliation (v2) -> S3/Athena/Glue Lab (v3) -> Airflow + Governance CI/CD (v4)**.
- Models an Oracle-style OLTP feed migrated into a PostgreSQL warehouse and S3 lakehouse with reconciliation checks and CI/CD.

[Source and runnable stages](https://github.com/am-torr/etl-aws-lab).

#### Resume / JD Diff (Public demo)

- Built a local React/TypeScript and Express app for DOCX/PDF comparison and resume-to-JD analysis.
- Runs without external AI APIs or document uploads to third-party services, backed by Vitest and Playwright E2E tests.

[Source and generated fixtures](https://github.com/am-torr/resume-jd-diff).

---

### Current Stack

**Enterprise Data & Integrations:** SQL/PLSQL, Oracle EBS R12, PostgreSQL, Supabase, REST/XML Integrations, AWS (S3, day-to-day Glue monitoring and support; Athena/Lambda lab).

**Automation:** Python, n8n, REST APIs, webhooks, FastAPI, Docker, Playwright.

**AI and tools (2025 to present):** Claude Agent SDK, MCP, Claude Code, Codex.

**Application and testing:** TypeScript/React, PowerShell/Pester, Vitest, GitHub Actions.
