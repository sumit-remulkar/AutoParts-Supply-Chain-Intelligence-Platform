# AutoParts Supply Chain Intelligence Platform (ASCIP)
### Revised Build Specification — Portfolio-Grade Edition

---

## 0. What Changed From the Original Doc, and Why

The original spec had good instincts but three problems that would hurt you with hiring managers rather than help:

- **Scope inflation.** 10 "modules," full RBAC, audit logging, enterprise architecture — for a solo project. Experienced engineers read this pattern as "generated wishlist," not "built system." Nobody expects a portfolio project to be enterprise software; claiming it is makes you look like you don't know the difference.
- **No data story.** Every feature assumed data existed. Where the data comes from — and how you handle it being messy — is usually the actual interesting engineering problem.
- **AI features described as outcomes, not mechanisms.** "Recommend the best supplier," "answer natural language questions" — with no model, no formula, no failure mode. That's a pitch deck, not a spec.

This version fixes those three things. It's smaller in surface area and larger in depth — which is what actually gets a reply on LinkedIn.

---

## 1. Positioning

**Don't call it an "enterprise platform."** Call it what it is: a portfolio-grade decision-support system for automotive procurement, built to demonstrate real data engineering, applied ML, and applied GenAI — not a production ERP replacement.

**One-line pitch (revised):**
> A supplier-risk and quotation-intelligence tool for automotive procurement — extracts RFQs from PDFs, scores supplier risk with an explainable model, forecasts part demand, and answers procurement questions grounded in live data via an LLM agent with tool access.

Notice this version doesn't use the word "AI-powered" or "intelligence platform" — those phrases are so overused in 2025-2026 portfolio projects that they now read as a negative signal. Let the mechanism speak for itself.

---

## 2. Problem Statement (kept, tightened)

Automotive procurement teams often run on spreadsheets and email. This creates three concrete, measurable pain points this project targets directly:

1. Comparing 5+ supplier quotations manually takes hours and misses inconsistencies.
2. Supplier risk is judged on gut feeling, not on delay/quality/price-volatility history.
3. Reorder decisions are reactive because nobody is forecasting demand per part.

Everything else in the original doc (finance controller dashboards, admin settings, full audit trail) is real-world ERP territory — good to *mention* as "out of scope, would extend to," bad to build shallowly.

---

## 3. Data Strategy (new — this section didn't exist before, and it's the first thing a technical interviewer will ask about)

You need two kinds of data, and being explicit about how you got them is itself a credibility signal:

**A. Time-series demand data (for forecasting):**
Use a real public logistics/retail time-series dataset (e.g. the DataCo Smart Supply Chain dataset on Kaggle, or the M5/Walmart forecasting dataset) and **remap** its categories/SKUs onto automotive part categories (brake pads, sensors, filters, etc.) with a documented mapping script. This gets you *real* seasonality and noise patterns instead of a fake sine wave, while still fitting your domain.

**B. Supplier, RFQ, and quotation data (for extraction and risk scoring):**
Generate this synthetically but *realistically*:
- Write a generator (Faker + custom rules) that produces supplier master data with correlated, plausible fields (a "high-risk" supplier should have correlated late-delivery + quality-reject history, not random noise).
- Generate 40–60 quotation PDFs using a few different real-world-style templates (different fonts, table layouts, some with missing fields, some scanned/rotated) — this is what makes your OCR pipeline demo *impressive*: it has to handle messiness, not a single clean template.
- Document this generation process in `/datasets/README.md`. Being upfront that data is synthetic-but-realistic is far more credible than pretending it's "real enterprise data."

---

## 4. Scope: MVP vs. Stretch

**Build MVP deep. Stretch modules are clearly labeled as "extends to" in your README — don't build them shallowly just to check a box.**

### MVP (build this well — ~10-12 weeks part-time)
1. Supplier & inventory data model + dashboard (CRUD, search, filters)
2. RFQ/Quotation extraction pipeline (PDF → structured data, with confidence scoring and a human-review-for-low-confidence-fields UI)
3. Explainable supplier risk scoring (weighted scorecard, not a black box)
4. Demand forecasting for a subset of parts, with backtested accuracy reported honestly
5. GenAI copilot **grounded via tool-calling** against your live API (not a raw LLM chatbot)
6. One clean, deployed, working dashboard

### Stretch (documented, not built)
- Full RBAC / multi-tenant admin
- Real-time MES/ERP integration
- Production-scale deployment
- Notification system

---

## 5. Core Features (revised)

### 5.1 Supplier & Inventory
- CRUD + search/filter suppliers and parts
- Stock levels, reorder point, safety stock, low-stock alerts
- Simple, honest labels: "fast/slow/dead-moving" based on a defined threshold you state in the README (e.g., <5% of avg monthly usage in 60 days = dead stock)

### 5.2 RFQ / Quotation Extraction — *your first real differentiator*
- Text-based PDFs: extract via PyMuPDF/pdfplumber with a rules layer (regex + positional heuristics) for structured fields
- Scanned/image PDFs: OCR fallback via Tesseract
- Messy/inconsistent layouts: LLM-assisted structured extraction (JSON-mode / function calling) as a fallback, **with a confidence score per field**
- Low-confidence fields flagged in a review UI rather than silently guessed — this single detail signals production-thinking to anyone technical who looks at it
- Output: normalized comparison table across suppliers for the same part

### 5.3 Supplier Risk Scoring — *your second differentiator*
Use an **explainable weighted scorecard**, the same style real procurement/credit-risk teams use (interpretable > black box, because a procurement manager needs to explain *why* a supplier is flagged):

```
risk_score =
    w1 * normalized(late_delivery_rate)
  + w2 * normalized(quality_reject_rate)
  + w3 * normalized(price_volatility)      # coefficient of variation of price over time
  + w4 * (1 - on_time_fulfillment_rate)
  + w5 * single_source_dependency_flag
```

Fit the weights with a simple logistic regression against a labeled "supplier had a failure event" target (label this in your synthetic data generator), then round to interpretable integer weights for the final scorecard — report the model's AUC/precision-recall honestly, including where it fails.

### 5.4 Demand Forecasting
- Baseline: seasonal-naive or Prophet/SARIMA
- Model: LightGBM with lag + rolling-window + calendar features
- **Backtest properly**: time-based train/test split, walk-forward validation — report MAPE/WAPE per part category, not a single cherry-picked number
- Be honest in the README about where forecasts are weak (e.g., low-volume parts, new parts with no history)

### 5.5 GenAI Copilot — *your third differentiator*
The single biggest mistake in most "AI copilot" portfolio projects: it's a raw LLM chatbot that hallucinates. Fix this by grounding it:
- Expose internal endpoints as callable tools: `get_supplier_risk(supplier_id)`, `get_inventory_status(part_id)`, `get_forecast(part_id, horizon)`, `compare_quotations(rfq_id)`
- LLM (Claude or GPT with function calling) decides which tool(s) to call, then answers using only the returned data
- Add a small RAG layer (pgvector, since you're already on Postgres — no need for a separate vector DB) over your own spec/policy docs for "why" questions
- Log every copilot answer with which tools it called — this becomes a nice "AI observability" talking point in interviews

---

## 6. Tech Stack (committed — no "X or Y")

| Layer | Choice |
|---|---|
| Frontend | Next.js + TypeScript + Tailwind + shadcn/ui + Recharts |
| Backend | FastAPI + Python 3.12 + SQLModel + Pydantic v2 |
| Database | PostgreSQL (Neon, serverless — free tier supports a live deployed demo) |
| Vector store | pgvector (same Postgres instance — simpler infra story) |
| ML | scikit-learn, LightGBM, Prophet/statsmodels |
| OCR/Extraction | PyMuPDF + pdfplumber + pytesseract + LLM-assisted fallback |
| LLM | Claude API (function calling / tool use) |
| Auth | JWT, simple RBAC (admin / procurement / read-only) |
| CI/CD | GitHub Actions (lint, test, deploy on merge) |
| Deployment | Frontend → Vercel, Backend → Render or Fly.io, DB → Neon |
| Testing | pytest + httpx (API), Playwright (key E2E flows) |

Picking a stack and defending it (even briefly, in the README) is itself a signal of engineering maturity.

---

## 7. Architecture (kept, same shape as original — it was fine)

```
User Browser
   |
Next.js Frontend
   |
FastAPI API Layer
   |
--------------------------------
| Supplier Service              |
| Inventory Service             |
| Purchase Service               |
| Reporting Service             |
--------------------------------
   |
--------------------------------
| Forecasting Engine (LightGBM) |
| Risk Scoring Engine           |
| RFQ Extraction Pipeline       |
| GenAI Copilot (tool-calling)  |
--------------------------------
   |
PostgreSQL + pgvector
```

---

## 8. Non-Functional Requirements (made measurable — vague NFRs like "should load quickly" don't demonstrate anything)

- API p95 latency < 300ms on CRUD endpoints against a ~5-10k row demo dataset
- RFQ extraction < 10s per document, confidence score always shown
- Forecast generation < 5s per part/plant combination
- Structured JSON logging + a `/health` endpoint (cheap, but shows you think about observability)
- Test coverage target: 70-80% on backend business logic
- Every AI output (risk score, forecast, copilot answer) is explainable — no unexplained black-box numbers in the UI

---

## 9. Realistic Roadmap (solo, ~15-20 hrs/week)

| Week | Focus |
|---|---|
| 1-2 | Data engineering: schema, real+synthetic datasets, seed DB, generator scripts |
| 3-4 | Backend core APIs (auth, suppliers, inventory, purchase) + tests |
| 5 | Frontend core dashboard wired to live APIs |
| 6-7 | RFQ extraction pipeline + confidence-scored review UI |
| 8 | Risk scoring model + explainability UI |
| 9 | Forecasting model + backtest + charts |
| 10 | GenAI copilot with tool-calling + basic answer evaluation |
| 11 | Polish, deploy live, write README/docs |
| 12 | Demo video, LinkedIn post, resume bullets |

Twelve weeks part-time is a claim you can actually defend in an interview. "Phase 1 through 6" with no time bound is not.

---

## 10. Success Criteria (measurable, not vibes)

- RFQ extraction: >90% field-level accuracy on your test set of generated PDFs
- Risk model: reports AUC/precision-recall honestly on held-out data
- Forecast: reports MAPE/WAPE per category, walk-forward validated
- Copilot: every answer traceable to a specific tool call / data source, zero unsupported claims in a 20-question eval set you write yourself
- A live, public, clickable demo — not just screenshots

(Cut from the original: "Look professional enough for portfolio and interviews" — that's a positioning goal, not an engineering success criterion. It belongs in section 11.)

---

## 11. Positioning & LinkedIn Plan (new — since this is your actual goal)

**README structure that gets read:**
1. One-paragraph problem + one GIF of the product in action, above the fold
2. Live demo link (this matters more than anything else in the README)
3. Architecture diagram
4. "Key technical decisions" section — 3-4 short write-ups like *"Why an explainable scorecard instead of a black-box classifier for risk scoring"* or *"Why the copilot uses tool-calling instead of freeform generation."* This is what makes engineers stop scrolling — it shows judgment, not just execution.
5. Honest limitations section (forecasts are weak for low-volume parts, etc.) — paradoxically, this builds more trust than pretending everything works perfectly.

**LinkedIn post approach:**
- Lead with the problem and a 30-60 second demo video/GIF, not a wall of buzzwords
- Pick ONE interesting engineering decision to highlight in the post itself (e.g., how you handled messy scanned RFQs) — specific detail invites comments from other engineers, and comments are what actually drives reach
- Include the live demo link and GitHub link directly
- Avoid "excited to share," "AI-powered," "game-changing" — these phrases are so common they now signal low effort

**Resume bullets (quantified):**
- "Built an explainable supplier-risk scoring model (logistic-regression-derived scorecard) achieving [X] AUC on backtested data; deployed via FastAPI + PostgreSQL"
- "Built a PDF/OCR extraction pipeline for supplier quotations achieving [X]% field-level accuracy across mixed text/scanned documents, with confidence-based human review fallback"
- "Built an LLM copilot grounded via tool-calling against live procurement APIs, eliminating hallucinated answers by construction"
- "Forecasted part-level demand using LightGBM with walk-forward backtesting, achieving [X]% MAPE across [N] part categories"

Fill in the `[X]` numbers with your real backtest results — real (even modest) numbers beat vague superlatives every time.
