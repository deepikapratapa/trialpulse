# TrialPulse — Clinical Trial Operations & Risk Analytics

**TrialPulse** is an analytics-first decision-support product for **clinical trial operations and portfolio leadership**, built using public **ClinicalTrials.gov** data.

The project focuses on **Phase II–III interventional trials** and answers practical operational questions around:
- trial timelines,
- enrollment risk,
- discontinuation patterns,
- sponsor and indication differences,
- and geographic execution complexity.

This is not a modeling-heavy project. The emphasis is on **interpretable analytics**, reproducibility, and **executive-ready insights**.

---

## Why this project?

Clinical trial teams make high-stakes decisions under uncertainty:
- How long should we expect trials to run?
- Which enrollment profiles are higher risk?
- Where do trials most commonly fail?
- How does sponsor type, indication, or geography affect outcomes?

TrialPulse translates messy public registry data into **clear operational signals** that can support:
- feasibility assessments,
- portfolio reviews,
- and early risk identification.

---

## Data Source

- **ClinicalTrials.gov API (v2)**
- ~25,000 Phase II–III interventional trials
- Public metadata only (no patient-level data)

Key fields include:
- trial status and outcomes,
- start / completion dates,
- enrollment size and type,
- sponsor classification,
- condition area,
- intervention characteristics,
- geographic footprint,
- and reported termination / withdrawal reasons (where available).

---

## Project Structure
```
trialpulse/
├── app/                     # Streamlit dashboard
│   └── app.py
├── notebooks/               # End-to-end analytics pipeline
│   ├── 01_data_ingest.ipynb
│   ├── 02_flatten_qc.ipynb
│   ├── 03_feature_engineering.ipynb
│   └── 04_analysis_visuals.ipynb
├── src/                     # Shared utilities (lightweight)
│   └── init.py
├── data/
│   ├── raw/                 # Raw ClinicalTrials.gov downloads (NDJSON)
│   ├── interim/             # Schema checks & QA artifacts
│   └── processed/           # Analysis-ready datasets
├── reports/
│   ├── figures/             # Executive-ready figures (HTML + PNG)
│   └── tables/              # KPI and summary tables (CSV)
├── README.md
├── requirements.txt
└── .gitignore
```
---

## Key Questions Answered

1. **Timeline**  
   How long do Phase II vs Phase III trials take, and how does duration vary by sponsor type and condition area?

2. **Enrollment Risk**  
   Which enrollment size profiles are associated with higher termination or withdrawal rates?

3. **Outcomes**  
   How do completion, termination, and withdrawal rates differ across phases and sponsor classes?

4. **Discontinuation Drivers**  
   What themes dominate reported termination and withdrawal reasons?

5. **Geography & Complexity**  
   How does geographic footprint (number of countries) relate to cycle time and operational burden?

6. **Trends Over Time**  
   How have trial volumes and discontinuation rates evolved over time?

---

## Outputs

- **9 executive-quality visualizations**, saved to `reports/figures/`
- **KPI and summary tables**, saved to `reports/tables/`
- A polished **Streamlit dashboard** with:
  - interactive filters,
  - KPI cards,
  - embedded figures,
  - and downloadable outputs.

---

## Selected Visual Insights

### Trial Duration by Phase
![Trial Duration by Phase](reports/figures/fig01_duration_by_phase.png)

*Phase III trials exhibit longer and more variable cycle times than Phase II, reflecting higher operational cost and execution complexity.*

---

### Outcome Mix by Phase
![Outcome Mix by Phase](reports/figures/fig04_outcome_mix_by_phase.png)

*Phase-specific completion and discontinuation rates highlight differing operational risk profiles across the development lifecycle.*

---

### Top Discontinuation Themes
![Top Discontinuation Themes](reports/figures/fig06_top_discontinuation_themes.png)

*Reported termination and withdrawal reasons cluster into a small number of operationally actionable themes, most commonly enrollment, funding/business, and safety.*

---

### Trial Volume and Discontinuation Trends
![Trial Volume and Discontinuation Trends](reports/figures/fig09_trials_over_time.png)

*Trial volume has increased substantially over time; recent-year discontinuation rates should be interpreted cautiously due to right-censoring.*

---

## Dashboard

Run locally:

```bash
conda activate trialpulse
streamlit run app/app.py
```
The dashboard is intentionally lightweight and reads from pre-computed analytics outputs to ensure fast, reproducible execution.

## Key Insights (Examples)

- **Phase III trials** typically exhibit longer cycle times and greater variability than Phase II, reflecting higher operational and regulatory complexity.
- **Smaller enrollment targets** are associated with higher discontinuation risk, particularly in certain phases, indicating feasibility and recruitment challenges.
- **Reported discontinuation reasons** cluster into a small number of operationally meaningful themes, most commonly enrollment, funding/business, and safety-related issues.
- **Multi-country trials** carry a measurable operational complexity premium, with longer median durations compared to single-country studies.
- **Recent-year trends** should be interpreted cautiously due to right-censoring, as many trials remain ongoing.

---

## Limitations & Data Quality Notes

- Enrollment and termination reasons are **not uniformly reported** across all trials.
- Public registry data may contain **reporting delays, missing fields, or inconsistencies**.
- Recent trials may be **right-censored** (still ongoing), affecting duration and discontinuation estimates.
- Findings are **directional and descriptive**, intended to support operational insight rather than causal inference.

---

## Intended Audience

This project is designed for:

- Clinical Data Analyst roles  
- Healthcare / Life Sciences Analytics  
- Clinical Operations & Trial Feasibility teams  
- Research Analytics and Health Informatics roles  

---

## Author

**Deepika Sarala Pratapa**  
Final-semester **M.S. Applied Data Science** student focused on **clinical analytics and healthcare data roles**, with an emphasis on **reproducible, decision-oriented analytics**.

- Email: [deepikapratapa27@gmail.com](mailto:deepikapratapa27@gmail.com)  
- LinkedIn: https://www.linkedin.com/in/deepika-sarala-pratapa/  
- GitHub: https://github.com/deepikapratapa










