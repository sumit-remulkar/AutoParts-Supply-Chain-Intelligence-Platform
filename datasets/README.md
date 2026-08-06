# Datasets

This folder will hold:

1. **Real time-series data** — a public logistics/retail dataset (e.g. the
   DataCo Smart Supply Chain dataset, or the M5 forecasting dataset),
   remapped onto automotive part categories via a documented script, used
   to train/backtest the demand forecasting model with realistic
   seasonality and noise instead of synthetic sine waves.

2. **Synthetic supplier, RFQ, and quotation data** — generated (not
   scraped, not fabricated as "real"), using correlated rules so that,
   e.g., a "high-risk" supplier has correlated late-delivery + quality-reject
   history rather than random noise. RFQ PDFs are generated across a few
   different templates (clean text, messy layout, scanned/rotated) so the
   extraction pipeline has to handle real-world messiness.

Generator scripts land here in the data-engineering step of the build
(Weeks 1-2 of the roadmap — see `docs/ASCIP_Pro_Build_Spec.md`). Generated
output itself is git-ignored (`datasets/generated/`) to keep the repo small;
only the generator code is committed.

## Status
🚧 Not yet built.
