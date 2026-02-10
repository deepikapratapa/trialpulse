# app/app.py

import streamlit as st
import pandas as pd
from pathlib import Path

# -----------------------------
# Paths
# -----------------------------
ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data" / "processed"
FIG_DIR = ROOT / "reports" / "figures"
TABLE_DIR = ROOT / "reports" / "tables"

DATA_PATH = DATA_DIR / "trialpulse_analysis.parquet"

# -----------------------------
# Page config
# -----------------------------
st.set_page_config(
    page_title="TrialPulse — Clinical Trial Analytics",
    layout="wide",
    initial_sidebar_state="expanded",
)

# -----------------------------
# Title + intro
# -----------------------------
st.title("TrialPulse")
st.subheader("Clinical Trial Operations & Risk Analytics (Phase II–III)")

st.markdown(
    """
TrialPulse provides analytics-driven insight into **clinical trial timelines, enrollment risk, and discontinuation patterns**
using public **ClinicalTrials.gov** data.

These KPIs summarize **portfolio-level operational risk** and **cycle-time expectations** for Phase II–III development programs.
"""
)

# -----------------------------
# Load data
# -----------------------------
@st.cache_data
def load_data() -> pd.DataFrame:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Processed dataset not found at: {DATA_PATH}")
    return pd.read_parquet(DATA_PATH)

df = load_data()

# -----------------------------
# Sidebar filters
# -----------------------------
st.sidebar.header("Filters")

phase_options = sorted(df["phase"].dropna().unique())
sponsor_options = sorted(df["sponsor_type"].dropna().unique())
condition_options = sorted(df["condition_area"].dropna().unique())
status_options = sorted(df["status_group"].dropna().unique())

phase_sel = st.sidebar.multiselect(
    "Phase",
    options=phase_options,
    default=[p for p in ["Phase 2", "Phase 3", "Phase 2/3"] if p in phase_options] or phase_options
)

condition_sel = st.sidebar.multiselect(
    "Condition area",
    options=condition_options,
    default=condition_options
)

sponsor_sel = st.sidebar.multiselect(
    "Sponsor type",
    options=sponsor_options,
    default=sponsor_options
)

status_sel = st.sidebar.multiselect(
    "Status group",
    options=status_options,
    default=status_options
)

# Start year filter (handle missing years safely)
year_min = int(df["start_year"].dropna().min()) if df["start_year"].notna().any() else 2000
year_max = int(df["start_year"].dropna().max()) if df["start_year"].notna().any() else 2026

year_range = st.sidebar.slider(
    "Start year (directional for recent years)",
    min_value=year_min,
    max_value=year_max,
    value=(year_min, year_max),
)

# -----------------------------
# Apply filters
# -----------------------------
df_f = df.copy()

if phase_sel:
    df_f = df_f[df_f["phase"].isin(phase_sel)]
if condition_sel:
    df_f = df_f[df_f["condition_area"].isin(condition_sel)]
if sponsor_sel:
    df_f = df_f[df_f["sponsor_type"].isin(sponsor_sel)]
if status_sel:
    df_f = df_f[df_f["status_group"].isin(status_sel)]

# Year filter applies only where start_year exists
df_f = df_f[
    (df_f["start_year"].isna()) |
    ((df_f["start_year"] >= year_range[0]) & (df_f["start_year"] <= year_range[1]))
]

# -----------------------------
# KPI row
# -----------------------------
st.markdown("### Portfolio KPIs")

c1, c2, c3, c4, c5 = st.columns(5)

with c1:
    st.metric("Trials", f"{len(df_f):,}")

with c2:
    med_dur = df_f["duration_start_to_completion_days"].median(skipna=True)
    st.metric("Median duration (days)", f"{int(med_dur):,}" if pd.notna(med_dur) else "—")

with c3:
    disc_rate = (df_f["status_group"].isin(["Terminated", "Withdrawn"])).mean() if len(df_f) else 0.0
    st.metric("Discontinuation rate", f"{disc_rate:.1%}")

with c4:
    med_enroll = df_f["enrollment_count"].median(skipna=True)
    st.metric("Median enrollment", f"{int(med_enroll):,}" if pd.notna(med_enroll) else "—")

with c5:
    pct_completed = df_f["status_group"].eq("Completed").mean() if len(df_f) else 0.0
    st.metric("Completed %", f"{pct_completed:.1%}")

# -----------------------------
# Key Visual Insights (embed saved Plotly HTML)
# -----------------------------
st.markdown("---")
st.markdown("### Key Visual Insights")

# Match these filenames to what Notebook 04 saved in reports/figures/
FIG_TITLES = [
    ("fig01_duration_by_phase.html", "Trial Duration by Phase"),
    ("fig02_duration_by_sponsor_phase.html", "Trial Duration by Sponsor Type and Phase"),
    ("fig04_outcome_mix_by_phase.html", "Outcome Mix by Phase (Completed vs Discontinued)"),
    ("fig05_discontinuation_by_enrollment_bucket.html", "Discontinuation Rate by Enrollment Bucket"),
    ("fig06_top_discontinuation_themes.html", "Top Reported Discontinuation Themes"),
    ("fig07_top_countries.html", "Top Countries by Trial Count"),
    ("fig08_duration_by_country_count.html", "Duration vs Number of Countries (Operational Complexity Proxy)"),
    ("fig09a_volume_by_year.html", "Trial Volume by Start Year"),
    ("fig09b_discontinuation_rate_by_year.html", "Discontinuation Rate by Start Year (Known Outcomes Only)"),
]

for fname, title in FIG_TITLES:
    fig_path = FIG_DIR / fname
    if fig_path.exists():
        st.markdown(f"#### {title}")
        with open(fig_path, "r", encoding="utf-8") as f:
            st.components.v1.html(f.read(), height=540, scrolling=True)
    else:
        st.info(f"Figure not found: {fname} (expected at {fig_path})")

# -----------------------------
# Reporting Tables + Downloads
# -----------------------------
st.markdown("---")
st.markdown("### Reporting Tables & Downloads")

# Show available tables
csv_tables = sorted(TABLE_DIR.glob("*.csv"))

if not csv_tables:
    st.warning(f"No CSV tables found in {TABLE_DIR}.")
else:
    for table_path in csv_tables:
        st.markdown(f"**{table_path.name}**")
        df_tbl = pd.read_csv(table_path)
        st.dataframe(df_tbl.head(50), use_container_width=True)

        st.download_button(
            label=f"Download {table_path.name}",
            data=df_tbl.to_csv(index=False),
            file_name=table_path.name,
            mime="text/csv"
        )

# Download filtered dataset
st.markdown("#### Download filtered dataset")
st.download_button(
    label="Download filtered dataset (CSV)",
    data=df_f.to_csv(index=False),
    file_name="trialpulse_filtered.csv",
    mime="text/csv"
)

# -----------------------------
# Limitations / footnotes
# -----------------------------
st.markdown("---")
st.caption(
    "Limitations: Enrollment and discontinuation reasons are not uniformly reported in public registries. "
    "Recent trials may be right-censored (ongoing), so duration and discontinuation trends should be interpreted directionally."
)