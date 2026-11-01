# Changelog

## v1.0.0 — 2026-11-01

First public release of the analysis code and aggregated outputs.

- Prespecified analysis (analysis plan of 31 October 2026, `docs/analysis_plan_TR.md`, in Turkish), written before any model was fitted:
  - Bayesian logistic models M0, M1 and M2 (brms with CmdStan).
  - Household-blocked 10-fold cross-validation with five fold assignments (the first primary).
  - Capacity-constrained selection within folds at the weighted (1 − c) quantile with fractional inclusion of the boundary group.
  - Paired household cluster bootstrap (2,000 replicates).
  - Equal selection proportion across income groups, subgroup capture, sensitivity analyses A–G, discrimination and calibration.
- Decisions taken by rules stated before fitting: day-count prior scale chosen by the prior predictive check (Table S3, Figure S1); cross-validation draws increased from 1,500 to 6,000 per chain under the Monte Carlo error rule (`Results/log/_ilk_kosu_s1500/`).
- Descriptive additions made after the main results were seen:
  - Bootstrap medians in all summaries.
  - Capacity window H (fine grid 0.08–0.32, step 0.005).
  - Table S8 extended to 10% and 30% capacity for the five fold assignments.
  - The upper bound of detection yield under within-fold selection (`Results/denetim/kat_duzeyi_tavan.csv`; Figure 2a).
  - 1,000 posterior draws of each full-data model (`Results/model_cekilisleri/`) with a scoring function (`Codes/skorla.R`) that reproduces the model predictions.
- A clean run from the raw microdata with empty caches (1 November 2026; `Results/log/kosu_temiz.txt`) reproduced every number of the previous run exactly on the same software and hardware. The additions listed above were computed afterwards from the same cached model fits (the design matrix and model inputs are unchanged), and every earlier field of `Results/sayilar.json` stayed identical.
