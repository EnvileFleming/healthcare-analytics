# Visual Findings and Recommendations

This document is the evidence log for the Power BI report. Final numerical conclusions must be based on a successful refresh from the PostgreSQL analytical views.

> The dashboard image in the README is a design preview with illustrative values. Do not use those values as analytical evidence.

## Completion criteria

Before marking the final project-status item complete:

- [ ] Refresh the PBIX successfully from PostgreSQL.
- [ ] Record the analysis date, reporting period, and latest available data date.
- [ ] Document at least four findings with exact values, dates, countries, or percentages.
- [ ] Connect each recommendation to a documented finding.
- [ ] Review the data-quality page and disclose material source revisions or invalid records.
- [ ] Replace every placeholder below with verified dashboard results.

## Analysis context

| Item | Verified value |
|---|---|
| Analysis date | To be completed |
| Reporting period | To be completed |
| Latest available data date | To be completed |
| Countries included | To be completed |
| Valid-record rate | To be completed |

## Finding 1: Global case trend

**Evidence:** Record the peak daily-case value, peak date, latest 7-day average, and direction of the recent trend.

**Interpretation:** Explain whether the rolling average indicates a sustained increase, decline, or stable pattern.

**Recommendation:** Use the 7-day rolling average for monitoring because it reduces volatility caused by reporting schedules.

## Finding 2: Global death trend

**Evidence:** Record the peak daily-death value and date, latest 7-day average, and comparison with the case trend.

**Interpretation:** Explain whether deaths followed the same timing and direction as cases.

**Recommendation:** Monitor cases and deaths together and avoid interpreting a single daily observation as a sustained change.

## Finding 3: Country concentration

**Evidence:** Record the leading countries by cumulative cases and their shares of the global total.

**Interpretation:** Explain whether the burden is concentrated among a small number of countries.

**Recommendation:** Prioritize detailed monitoring for high-burden countries while retaining country-level filters for broader comparison.

## Finding 4: Mortality-rate variation

**Evidence:** Compare mortality rates only among countries with a meaningful minimum number of cases. Record the threshold used.

**Interpretation:** Identify notable differences without making causal or clinical claims.

**Recommendation:** Investigate differences alongside reporting practices, population structure, testing coverage, and data completeness.

## Finding 5: Data quality

**Evidence:** Record counts and percentages by data-quality status, including negative daily changes caused by historical source revisions.

**Interpretation:** Explain how revisions affect daily metrics without changing the meaning of cumulative source totals.

**Recommendation:** Preserve revision flags, disclose them in reporting, and exclude invalid records from mortality calculations where appropriate.

## Limitations

- The analysis is descriptive and does not establish causation.
- Country comparisons may be affected by differences in testing, reporting practices, and update schedules.
- Historical revisions can produce negative derived daily values.
- Cumulative totals should not be summed across countries and aggregate entities.
- Executive global totals should use the dedicated World record from the analytical view.
