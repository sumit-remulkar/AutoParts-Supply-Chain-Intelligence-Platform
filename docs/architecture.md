# Architecture

```mermaid
flowchart TD
    U[User Browser] --> FE[Next.js Frontend]
    FE --> API[FastAPI API Layer]

    subgraph Business Services
      SS[Supplier Service]
      IS[Inventory Service]
      PS[Purchase Service]
      RS[Reporting Service]
    end

    subgraph AI / ML Layer
      FC[Forecasting Engine]
      RK[Risk Scoring Engine]
      OCR[RFQ Extraction Pipeline]
      CP[GenAI Copilot - tool calling]
    end

    API --> SS
    API --> IS
    API --> PS
    API --> RS

    SS --> RK
    PS --> OCR
    IS --> FC
    API --> CP
    CP -.tool calls.-> SS
    CP -.tool calls.-> IS
    CP -.tool calls.-> FC
    CP -.tool calls.-> RK

    SS --> DB[(PostgreSQL + pgvector)]
    IS --> DB
    PS --> DB
    RS --> DB
    FC --> DB
    RK --> DB
    OCR --> DB
    CP --> DB
```

## Notes on key decisions

- **pgvector instead of a separate vector DB** — the copilot's RAG layer reuses
  the same Postgres instance (`doc_embeddings` table) instead of adding Pinecone/Weaviate,
  keeping the infra story simple for a single deployed instance.
- **Copilot is tool-calling, not freeform generation** — every copilot answer is
  logged with which internal API(s) it called (`copilot_logs.tools_called`), so
  answers are traceable to actual data rather than hallucinated.
- **Risk scoring is an explainable weighted scorecard**, not a black-box classifier —
  `risk_scores.factors` stores the component breakdown so the UI can show *why*
  a supplier is flagged, not just a number.
