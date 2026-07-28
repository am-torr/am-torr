<h1 align="center">Hi, I'm Arvin</h1>
<h3 align="center">AI Data Engineer | GenAI Pipelines | Workflow Automation | 10+ yrs Enterprise Data</h3>

<p align="center">
  <a href="https://linkedin.com/in/arvintorralba012">
    <img src="https://img.shields.io/badge/LinkedIn-Arvin%20Torralba-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
  </a>
</p>

---

### About Me

I'm an AI Data Engineer working at the intersection of **data engineering, workflow automation, and modern GenAI**. I build AI-powered data pipelines that connect legacy and enterprise systems (Oracle ERP, AWS data stacks) with LLMs and retrieval systems.

Over the last year, I've shipped production-grade **RAG systems**, **multi-agent LLM pipelines**, and **real-time scraping workflows** - often taking projects from prototype to production in under 60 hours. Before that, I spent a decade in enterprise data work across IBM, Accenture, and Cognizant, building and operating ETL jobs, AWS Glue/Lambda pipelines, and large-scale SQL workloads.

My niche is the gap most teams struggle with: **robust data plumbing + the AI layer on top** (LLM orchestration, retrieval, enrichment, monitoring). I'm currently focused on AI/data engineering roles where I can design end-to-end pipelines, wire LLMs into real business data, and automate the glue between tools and platforms.

---

### Current Stack
Python | SQL | Oracle ERP | AWS Glue/Lambda | Docker | FastAPI
Supabase | PostgreSQL/pgvector | n8n | HuggingFace | RAG | LLM Orchestration


---

### Featured Projects

#### EOS (Executive Operating System) & Ralph Loop | 2026 (Private Repository)

Repository: [am-torr/skills](https://github.com/am-torr/skills)

- Built a human-gated autonomous build pipeline that carries a written spec from queue to verified, promoted code: each task is routed for required context, approved by a human, executed by a context-shielded agent, then graded by a separate agent that can fail the build.
- Completed 61 specs end to end and authored ~60 reusable skills, on deterministic PowerShell tooling (sequence manifest, crash-recovery markers, promotion-reconciliation gates) covered by Pester suites.
- Compounds each build into reusable assets -- routing rules, lint rules, skills -- so a failure mode is diagnosed once and never re-debugged.

#### Production n8n Service | 2025-Present (Private Repository)

Repository: [am-torr/gunpla_project_01](https://github.com/am-torr/gunpla_project_01)

- Operates a self-hosted 19-service Docker Compose stack in production: Python/Playwright scrapers, a scheduler, n8n workflow orchestration, self-hosted Supabase (PostgreSQL + PostgREST + Kong), nginx, and a URL shortener.
- Runs an end-to-end scrape -> queue -> batch -> publish pipeline turning scraped retail inventory into scheduled social posts, with idempotent dedup and repost-cooldown rules enforced in the database.
- Migrated the data layer off hosted Supabase onto self-hosted PostgreSQL + PostgREST + Kong, keeping the cloud project as a rollback path.

#### Autonomous Operations Agent | 2026 (Private Repository)

Repository: [am-torr/gunpla_project_01](https://github.com/am-torr/gunpla_project_01) -- subsystem: `scripts/lowstock_agent`

- Built a Claude Agent SDK pipeline that detects low-stock inventory and drafts publish-ready copy for human review; it runs alongside the production n8n flow and never auto-publishes.
- Enforces a hard database write boundary -- the agent writes only to its own drafts and price-history tables and reads the live publishing queue read-only through a stored procedure -- so an agent fault cannot corrupt production data.
- Self-corrects with a generate-and-check loop that rewrites captions until an automated checker passes, using a two-tier model split (cheap classifier, stronger writer) and an offline dry-run mode for testing without live scrapes or writes.

#### Resume-Diff Web App | 2026 (Private Repository)

Repository: [am-torr/i-want-a-text-diff-viewer](https://github.com/am-torr/i-want-a-text-diff-viewer)

- Privacy-first local web app (React + TypeScript + Express) comparing two resume versions across all four DOCX/PDF pairings -- no upload, no third-party API call, no login.
- Extracts and normalizes text from both binary formats, groups changes by resume section using heading-synonym mapping, flags resume-specific risks, and exports a self-contained local HTML report.
- Covered by unit tests, a four-pairing smoke test, and Playwright end-to-end tests; the document-processing patterns it produced were captured as reusable skills.

---

### Activity

![Arvin's GitHub Stats](https://github-readme-stats.vercel.app/api?username=am-torr&show_icons=true&theme=default&hide_border=true&count_private=true)

---
