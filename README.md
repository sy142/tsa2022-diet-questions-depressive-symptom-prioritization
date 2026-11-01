# Two diet questions and capacity-constrained prioritization of adults for depressive-symptom assessment (Türkiye Health Survey 2022)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23862929.svg)](https://doi.org/10.5281/zenodo.23862929)

This repository contains the analysis code and aggregated outputs of a study of whether two questions on fruit and vegetable/salad consumption frequency improve the prioritization of adults for depressive-symptom assessment when only part of a primary care population can be invited. It uses the microdata of the 2022 Türkiye Health Survey of the Turkish Statistical Institute (TurkStat). The eligible population comprises adults aged 18 years or older who saw a general practitioner or family physician in the past 12 months and reported no psychologist, psychotherapist or psychiatrist visit (12,842 adults in 7,725 households in the analysis frame; 581 with PHQ-8 ≥ 10). Three Bayesian logistic models rank adults by their predicted probability of PHQ-8 ≥ 10 without any depressive-symptom item: M0 (routine characteristics), M1 (M0 plus the two diet questions) and M2 (M1 plus physical activity, physical demand of daily activities and social support). Predictions come from household-blocked 10-fold cross-validation with five fold assignments. At an assessment capacity c, the weighted share c of adults with the highest predicted probabilities is selected within each fold, with fractional inclusion of the boundary group. The primary measure is detection yield, the number of selected PHQ-8–positive adults per 1,000 eligible adults; the primary estimand is the difference between M1 and M0 at 20% capacity, judged against a prespecified practical-importance bound of ±1 per 1,000. Uncertainty is estimated with a paired household cluster bootstrap. Comparators are random selection, perfect ranking (the upper bound) and ranking by the PHQ-2 score, a symptom-based comparator that shares two items with the PHQ-8. The distribution of selection across age, sex, education and income groups, an equal selection proportion across income groups, sensitivity analyses, discrimination and calibration are included. PHQ-8 ≥ 10 is a screening threshold, not a clinical diagnosis. A manuscript based on this repository has been prepared for submission.

## Data

The Türkiye Health Survey 2022 microdata were obtained from TurkStat under its microdata user agreement. Under the confidentiality provisions of Statistical Law No. 5429 they cannot be redistributed. This repository contains no microdata and no person-level intermediate files: the data files, analysis frame, cross-validation predictions, model objects, cross-validation posterior draws and caches that the code writes to `R_Data ve Python Data/` are not included. Researchers can obtain the microdata by applying through TurkStat's official microdata procedures.

The code expects, in `R_Data ve Python Data/kaynak/` (or in the folder given by the environment variable `TSA_KAYNAK`), the semicolon-delimited microdata file `TSA_2022_MIKROVERI_REV.csv` (29,761 records, 295 columns) and the coding dictionary `TSA2022_kodlama_sozlugu.R`, which defines the value codes and labels (`kmap`) and question texts (`vlab`) of the variables. The file is read once and stored as `R_Data ve Python Data/tsa2022.parquet`. Eighteen numbers prespecified in the analysis plan (sample sizes, prevalences, the PHQ-2 workload) are reproduced from the data before any model is fitted; the run stops if one does not match (`Results/dogrulama_kontrolleri.csv`).

## Repository structure

- `Codes/`
  - `analiz.R`: single entry point. Reads and validates the data, builds the variables, runs the prior predictive check, fits the full-data and cross-validation models, performs the capacity analyses and the bootstrap, and writes all tables, machine-readable results and figure data.
  - `tasarim.R`: the design matrix (`tasarim_kur`), shared by `analiz.R` and `skorla.R`.
  - `skorla.R`: scoring function for new data with the full-data models (see Scoring below).
  - `figurler.py`, `figur_stili.py`: all figures, drawn from the figure data; `fonts/`: the Lato typeface used in the figures (SIL Open Font License, `fonts/OFL.txt`); `etiketler.json`: labels shared by the R tables and the figures.
  - `xlsx_simge.py`: real subscripts and superscripts in `Results/tablolar_tumu.xlsx`; `python_ortam.py`: records the Python environment; `sayilar_karsilastir.py`: compares two `sayilar.json` files field by field; `renv_kilidi.R`: writes `renv.lock`.
  - `README_kodlar.md`: run guide in Turkish (order, durations, caches, seeds).
- `Results/`
  - `Table1`, `Table2` (`.docx`, `.csv`) and `tablolar_tumu.xlsx` (all tables in one workbook).
  - `sayilar.json`: every number reported in the manuscript, in machine-readable form.
  - Results files: `altgrup_kapsami.csv` (subgroups), `esitlik_senaryosu.csv` (equal selection proportion), `table1_veri.csv`, `degisken_tanimlari.csv`.
  - Protocol and checks: `model_protokolu.csv` (model-fitting protocol, criteria and decisions), `model_ozetleri.txt` (summaries of the full-data models), `dogrulama_kontrolleri.csv` (validation of the prespecified numbers).
  - Environment: `sessionInfo.txt`, `python_ortam.txt`, `paket_atiflari.txt` (package citations).
  - `Supplementary/`: Supplementary Tables S1–S11 (`.docx`, `.csv`) and their source files (`duyarlilik.csv`, `performans.csv`, `kalibrasyon.csv`, `katsayilar.csv`, `bootstrap_tekrar_oranlari.csv`, `model_temelli_delta.csv`, `grup470.csv`).
  - `model_cekilisleri/`: 1,000 posterior draws of each full-data model (`M0.csv`, `M1.csv`, `M2.csv`) and the term dictionary `terimler.csv`. These are draws of the model parameters (intercept and coefficients); no row corresponds to a person.
  - `denetim/`: aggregated audit files (weights, missing data, income bands, fold summaries, convergence diagnostics, unit tests of the selection function, Monte Carlo error, fine capacity grid, the upper bound under within-fold selection, validation of the scoring function, embedded fonts of the figures).
  - `log/`: run logs and durations, including the clean run from the raw file (`kosu_temiz.txt`) and the numbers of the first run with 1,500 draws per chain (`_ilk_kosu_s1500/`).
- `Figures/`: Figures 1–3 and `Supplementary/` Figures S1–S4 (PNG at 600 dpi, PDF with embedded fonts, LZW-compressed TIFF); `figur_altyazilari.md` (caption drafts); `figur_verileri/` (the aggregated data from which every figure is drawn).
- `docs/`: `analysis_plan_TR.md` (analysis plan of 31 October 2026, written before any model was fitted; in Turkish; archive version with the journal, folder and path names removed) and `CHANGELOG.md`. The analysis report and working notes requested in the plan are not part of the archive; the TRIPOD+AI checklist accompanies the manuscript.
- Not included: everything under `R_Data ve Python Data/` (see Data) and `Results/denetim/gun_sayisi_olay.csv`, an audit file of counts by single day count that the code writes and that contains cells of fewer than 20 people.
- `renv.lock`: versions of the R packages; `LICENSE`, `CITATION.cff`, `.zenodo.json`.

Tables and figures of the manuscript:

| Item | Content | Files |
|---|---|---|
| Table 1 | Characteristics of the analysis frame by PHQ-8 positivity | `Results/Table1.*` |
| Table 2 | Detection yield, sensitivity and positive predictive value at 10%, 20% and 30% capacity, by strategy | `Results/Table2.*` |
| Table S1 | Variable definitions and coding | `Results/Supplementary/TableS1_degisken_tanimlari.*` |
| Table S2 | Missing values and records excluded from the analysis frame | `Results/Supplementary/TableS2_eksik_veri.*` |
| Table S3 | Model specification, prior predictive check and convergence diagnostics | `Results/Supplementary/TableS3_model_tanilari.*` |
| Table S4 | Posterior summaries of the full-data models (intercept and odds ratios) | `Results/Supplementary/TableS4_katsayilar.*` |
| Table S5 | Software and packages | `Results/Supplementary/TableS5_yazilim.*` |
| Table S6 | Discrimination and calibration of the outer-fold predictions | `Results/Supplementary/TableS6_performans.*` |
| Table S7 | Bootstrap replicate proportions and the model-based distribution of the primary difference | `Results/Supplementary/TableS7_bootstrap_oranlari.*` |
| Table S8 | Sensitivity analyses at 10%, 20% and 30% capacity | `Results/Supplementary/TableS8_duyarlilik.*` |
| Table S9 | Distribution of selection and within-group capture by subgroup at 20% capacity | `Results/Supplementary/TableS9_altgrup.*` |
| Table S10 | Equal selection proportion across income groups at 20% capacity | `Results/Supplementary/TableS10_esitlik.*` |
| Table S11 | Adults with PHQ-8 ≥ 10, both foods less than daily and no mental health specialist contact | `Results/Supplementary/TableS11_grup470.*` |
| Figure 1 | Study population and decision problem | `Figures/Figure1.*` |
| Figure 2 | Detection yield across assessment capacities; difference between M1 and M0 | `Figures/Figure2.*` |
| Figure 3 | Distribution of selection at 20% capacity; equal selection proportion across income groups | `Figures/Figure3.*` |
| Figure S1 | Prior predictive check | `Figures/Supplementary/FigureS1_oncel_ongoru.*` |
| Figure S2 | Calibration of the outer-fold predictions | `Figures/Supplementary/FigureS2_kalibrasyon.*` |
| Figure S3 | Bootstrap and model-based distributions of the primary difference | `Figures/Supplementary/FigureS3_delta_dagilimlari.*` |
| Figure S4 | Sensitivity analyses of the primary difference | `Figures/Supplementary/FigureS4_duyarlilik.*` |

Following TurkStat's guidance on the reliability of estimates, no estimate is reported for cells with fewer than 20 unweighted observations, and cells with 20–50 are flagged. Analyses added after the main results were seen are listed in `docs/CHANGELOG.md` and described in the table notes.

## How to run

All commands are run from the repository root. The data analysis needs the microdata (see Data); the figures can be redrawn from the files in this repository.

```
Rscript Codes/analiz.R
python3 Codes/figurler.py
```

- `analiz.R` writes the parquet file, the analysis frame, cross-validation predictions and caches to `R_Data ve Python Data/` and all outputs to `Results/` and `R_Data ve Python Data/figur_verileri/`. It calls Python for `xlsx_simge.py` and `python_ortam.py` (`~/veri-ortami/bin/python3` if present, otherwise `python3`; or the interpreter given by `PY_YORUMLAYICI`).
- `figurler.py` reads the figure data from `R_Data ve Python Data/figur_verileri/` if that folder exists, otherwise from `Figures/figur_verileri/`. A single figure: `python3 Codes/figurler.py 2` or `python3 Codes/figurler.py S3`. The script stops if a font other than the bundled Lato would be embedded, if any text is smaller than 7 pt at print size or if text extends beyond the figure.
- Caches (`R_Data ve Python Data/onbellek/`): every fitted model and every long computation is stored under a name that carries a hash of its inputs (data, folds, priors, model lists, function code) and is recomputed only when these change. Deleting the folder gives a clean run.
- Durations on an 18-core Apple silicon Mac with 64 GB of memory: a clean run from the raw file with empty caches took 42 min (39 min for the 230 cross-validation fits; four concurrent fits × four chains); a run from valid caches takes about 20 s; the figures take about 5 s.

## Scoring with the full-data models

Table S4 summarizes the full-data models descriptively. Because predictions are posterior mean probabilities, which differ from the probability at the posterior mean or median coefficients, exact predictions require the posterior draws and the scoring function:

```r
source("Codes/skorla.R")
skorla(ornek_kisiler, model = "M1")   # synthetic example defined at the top of skorla.R
```

`skorla(yeni_veri, model, dogrusal = FALSE)` returns, for each person, the posterior mean probability over the 1,000 draws (`p_ortalama`) and, if requested, the mean linear predictor. The input uses the raw codes of Table S1 (not labels); the required columns and their codes are listed in `Codes/README_kodlar.md`, `Codes/tasarim.R` and `Results/model_cekilisleri/terimler.csv`. On the analysis frame, the function reproduces the brms predictions on the same 1,000 draws to within 2 × 10⁻¹⁶ (`Results/denetim/skorla_dogrulama.csv`). The models were fitted to this population without survey weights and are not validated for other populations; the capacity analyses use the outer-fold predictions of the cross-validation, not these models.

## Environment

- R 4.6.1 (Apple Accelerate BLAS); brms 2.23.0, cmdstanr 0.9.0, CmdStan 2.40.0, posterior 1.7.0, WeightedROC 2026.8.27; data.table, readr, arrow, future, furrr, flextable, officer and openxlsx for data handling, parallel computation and tables. `renv.lock` records all R package versions (CRAN and, for cmdstanr, `https://stan-dev.r-universe.dev`); CmdStan is installed with `cmdstanr::install_cmdstan(version = "2.40.0")`. On this machine the CmdStan precompiled headers were incompatible with the current compiler, so models are compiled with `PRECOMPILED_HEADERS=false`; this affects only compilation time.
- Python 3.13 with matplotlib, numpy, pandas, pillow, fonttools and openpyxl.
- Exact versions: `Results/sessionInfo.txt`, `Results/python_ortam.txt`; packages, their roles and citations: `Results/paket_atiflari.txt` and Table S5.

## Reproducibility

- Seeds are fixed (R 20261101; fold assignments 20261111–20261115; prior predictive check 20261102; full-data models 20261111–20261113; cross-validation fits by fold and model; household bootstrap 20261131; Monte Carlo error check 20261141); the full list is in `Codes/README_kodlar.md`.
- A clean run from the raw file with empty caches (1 November 2026) reproduced every number of the previous run exactly on the same software and hardware. The later additions (see `docs/CHANGELOG.md`) were computed from the same cached model fits; all earlier fields of `Results/sayilar.json` stayed identical.
- On other hardware or compilers the Stan draws differ; results should agree within Monte Carlo error (standard deviation of the primary difference due to Monte Carlo error 0.04 per 1,000; `Results/denetim/mcse_delta_denetimi.csv`).

## Citation

Citation details will be added when the manuscript is published.

Authors:
- Salim Yılmaz, Acıbadem Mehmet Ali Aydınlar University (ORCID [0000-0003-2405-5084](https://orcid.org/0000-0003-2405-5084))
- Ahmet Murat Günal, Haliç University (ORCID [0000-0001-9109-1080](https://orcid.org/0000-0001-9109-1080))

## License

The code is released under the MIT License (`LICENSE`). The aggregated outputs (tables, figures, posterior draws and results files) may be reused with attribution. The Lato font files in `Codes/fonts/` are distributed under the SIL Open Font License 1.1 (`Codes/fonts/OFL.txt`).
