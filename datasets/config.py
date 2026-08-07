"""Shared constants for every generator script in this folder.

Everything is seeded so the generated dataset is reproducible — re-running
`make_all.py` from a clean checkout produces byte-identical CSVs. That
reproducibility is itself worth a line in the README: it means the demo
data isn't a one-off snapshot, it's regenerable.
"""

import random

import numpy as np

SEED = 42
random.seed(SEED)
np.random.seed(SEED)

NUM_SUPPLIERS = 40
NUM_PARTS = 120
NUM_PLANTS = 3
WAREHOUSES_PER_PLANT = 2
HISTORY_MONTHS = 18  # supplier_performance monthly history
DEMAND_HISTORY_DAYS = 730  # 2 years of daily demand history for forecasting

PART_CATEGORIES = [
    "Brakes",
    "Filters",
    "Sensors",
    "Electrical",
    "Engine Components",
    "Suspension",
    "Body Parts",
    "Batteries",
]

# Seasonality profile per category — used by the synthetic demand fallback,
# and also used to sanity-check a real dataset's remap (a "Batteries"
# category should show a winter peak; if it doesn't, the remap is probably
# wrong).
SEASONALITY_PROFILE = {
    "Brakes": {"annual_peak_day": 300, "annual_amplitude": 0.15},       # mild autumn peak
    "Filters": {"annual_peak_day": 150, "annual_amplitude": 0.10},      # mild mid-year
    "Sensors": {"annual_peak_day": 0, "annual_amplitude": 0.05},        # flat, low seasonality
    "Electrical": {"annual_peak_day": 0, "annual_amplitude": 0.05},
    "Engine Components": {"annual_peak_day": 200, "annual_amplitude": 0.12},
    "Suspension": {"annual_peak_day": 250, "annual_amplitude": 0.10},
    "Body Parts": {"annual_peak_day": 0, "annual_amplitude": 0.08},
    "Batteries": {"annual_peak_day": 350, "annual_amplitude": 0.35},    # strong winter peak
}

PLANT_CITIES = ["Pune", "Chennai", "Ahmedabad"]
SUPPLIER_LOCATIONS = [
    "Pune, IN", "Chennai, IN", "Coimbatore, IN", "Rajkot, IN",
    "Aurangabad, IN", "Nashik, IN", "Gurugram, IN", "Stuttgart, DE",
    "Nagoya, JP", "Shenzhen, CN",
]
