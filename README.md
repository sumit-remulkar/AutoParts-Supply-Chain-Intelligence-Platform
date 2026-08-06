# AutoParts Supply Chain Intelligence Platform (ASCIP)

A supplier-risk and quotation-intelligence tool for automotive procurement.
Extracts RFQs from PDFs, scores supplier risk with an explainable model,
forecasts part demand, and answers procurement questions through an LLM
agent grounded in live data via tool-calling.

**Live demo:** _coming soon_
**Demo video:** _coming soon_

---

## Why this project exists

Automotive procurement teams often run on spreadsheets and email. Comparing
five supplier quotations by hand takes hours. Supplier risk gets judged on
gut feeling instead of delay/quality/price history. Reorder decisions are
reactive because nobody is forecasting demand per part.

ASCIP is a portfolio-grade system built to demonstrate real data
engineering, applied ML, and applied GenAI against those three problems —
not a claim to be production ERP software.

Full build spec: [`docs/ASCIP_Pro_Build_Spec.md`](docs/ASCIP_Pro_Build_Spec.md)

---

## Architecture

```
User Browser
   |
Next.js Frontend (frontend/)
   |
FastAPI API Layer (backend/)
   |
-------------------------------------
| Supplier Service                  |
| Inventory Service                 |
| Purchase Service                  |
| Reporting Service                 |
-------------------------------------
   |
-------------------------------------
| Forecasting Engine   (ai/)        |
| Risk Scoring Engine  (ai/)        |
| RFQ Extraction Pipeline (ai/)     |
| GenAI Copilot (tool-calling)(agents/) |
-------------------------------------
   |
PostgreSQL + pgvector (database/)
```

See [`docs/architecture.md`](docs/architecture.md) for the diagram source.

---

## Tech stack

| Layer | Choice |
|---|---|
| Frontend | Next.js 14 (App Router) + TypeScript + Tailwind CSS |
| Backend | FastAPI + Python 3.12 + SQLModel |
| Database | PostgreSQL + pgvector |
| ML | scikit-learn, LightGBM, Prophet/statsmodels |
| OCR/Extraction | PyMuPDF, pdfplumber, pytesseract |
| LLM | Claude API (tool use / function calling) |
| CI/CD | GitHub Actions |
| Deployment | Vercel (frontend), Render/Fly.io (backend), Neon (Postgres) |

---

## Project structure

```
ASCIP/
├── backend/          FastAPI application
├── frontend/         Next.js application
├── agents/           GenAI copilot: tool-calling agent logic
├── ai/               Forecasting, risk scoring, RFQ extraction pipelines
├── database/         SQL schema, migrations
├── datasets/         Data generation scripts + docs (real + synthetic)
├── docs/             Architecture notes, build spec
├── docker/           Extra Dockerfiles/configs beyond docker-compose
└── docker-compose.yml
```

---

## Running locally

Requirements: Docker + Docker Compose.

```bash
cp .env.example .env
docker compose up --build
```

- Backend: http://localhost:8000 (docs at `/docs`)
- Frontend: http://localhost:3000
- Postgres: localhost:5432

### Running backend without Docker

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Running frontend without Docker

```bash
cd frontend
npm install
npm run dev
```

---

## Status

🚧 Actively being built, step by step. Current stage: **repo scaffold + health-check API**.
See the roadmap in the build spec for what's next.

## Key technical decisions

_(Filled in as each piece is built — this is where the interesting engineering
write-ups go: why an explainable scorecard over a black-box classifier, why
pgvector instead of a separate vector DB, how messy scanned RFQs are handled, etc.)_

## License

MIT — see [LICENSE](LICENSE).
