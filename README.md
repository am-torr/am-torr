<h1 align="center">Hi, I'm Arvin</h1>
<h3 align="center">Senior Software & Data Engineer | Automation, Agentic Systems & Enterprise Data</h3>

<p align="center">
  <a href="https://linkedin.com/in/arvintorralba012">
    <img src="https://img.shields.io/badge/LinkedIn-Arvin%20Torralba-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
  </a>
</p>

---

### About Me

I build workflow automation and API integrations, with a background in enterprise data and production support.

My experience includes 10+ years with Oracle, SQL/PLSQL and enterprise integrations, followed by Python/AWS data engineering. My recent projects use n8n, PostgreSQL/Supabase, AI agents and MCP. I focus on understanding the full flow, handling failures and checking the result.

---

### Selected Projects

#### Gunpla Scarcity Content Pipeline (Public)

- Built an n8n pipeline for low-stock listings: **Ingest -> Queue -> Batch -> Publish**, using Python/Playwright, PostgreSQL/Supabase and the Facebook Graph API.
- Added deduplication, content fingerprints, queue state tracking and retry handling. The repository documents successful Facebook publishing.

[Source and sample output](https://github.com/am-torr/gunpla_project_01). Approval and archiving are in progress.

#### EOS / Ralph Loop (Private prototype)

- Built approval, checker identity and promotion checks for an agent-assisted engineering workflow.
- Includes PowerShell/Pester tooling for queue state, recovery and audit receipts.

Code walkthrough available.

#### Low-Stock Operations Agent (Private prototype)

- Implemented Claude Agent SDK calls for item classification and draft captions.
- Keeps draft preparation separate from the n8n publishing flow and includes human review controls.

Code walkthrough available.

#### DaVinci Resolve MCP Server (Private prototype)

- Implemented 18 MCP tools for project, timeline, clip, color and render operations.
- Includes unit tests with a fake backend and MCP protocol test code.

Code walkthrough available.

#### Resume / JD Diff (Public demo)

- Built a local React/TypeScript and Express app for DOCX/PDF comparison and resume-to-JD analysis.
- Runs without external AI APIs or document uploads to third-party services. The public JD matcher uses shared keywords.

[Source and generated fixtures](https://github.com/am-torr/resume-jd-diff).

---

### Current Stack

**Automation:** Python, n8n, REST APIs, webhooks, FastAPI, Docker.

**Data:** SQL/PLSQL, PostgreSQL, Supabase, AWS Glue/PySpark.

**AI and tools:** Claude Agent SDK, MCP, Claude Code, Codex.

**Application and testing:** TypeScript/React, PowerShell/Pester, GitHub Actions.
