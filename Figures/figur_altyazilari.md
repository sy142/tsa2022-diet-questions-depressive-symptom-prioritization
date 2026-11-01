# Figure captions (draft, American English)

Kaynak veriler: `R_Data ve Python Data/figur_verileri/`; çizim: `Codes/figurler.py`. Altyazılar kısa tutuldu; ayrıntı tablo notlarında ve Methods'ta. Ek figür numaraları ana metindeki ilk atıf sırasına göre: S1 Methods (öncel), S2–S4 Results.

## Figure 1
**Figure 1.** Study population and decision problem. (**a**) Selection of the eligible population from the Türkiye Health Survey 2022; bar widths are proportional to unweighted counts, and the dark segment marks adults with PHQ-8 ≥ 10 (n = 581). GP, general practitioner. (**b**) Information layers used to rank eligible adults (M0, M1, M2), the weighted capacity threshold that determines who is invited for assessment, and the comparators evaluated at the same capacity: random selection, perfect ranking (upper bound) and PHQ-2 ranking, a symptom-based comparator sharing two items with the PHQ-8 and not an upper bound. No depressive-symptom questions enter M0–M2.

## Figure 2
**Figure 2.** Detection yield across assessment capacities. (**a**) Selected PHQ-8–positive adults per 1,000 eligible adults by capacity for random selection, M0, M1, M2 and PHQ-2 ranking (a symptom-based comparator sharing two items with the PHQ-8, not an upper bound); the dark dotted curve is perfect ranking at the population level, 1,000 × min(c, p), the population-level upper bound, which reaches its plateau of 45.7 at c = p; the light dotted curve, drawn where it differs, is perfect ranking within folds, the upper bound under the same within-fold capacity quota as the models; it lies below the population-level bound only between the smallest and the largest fold prevalence (2.4%–5.9%), by at most 3.6 per 1,000 (at c = p), and coincides with it at 10%, 20% and 30%. The diamond marks the capacity implied by the PHQ-2 ≥ 3 rule. Thin solid vertical lines mark the prespecified 10%, 20% and 30% scenarios. (**b**) Difference in detection yield between M1 and M0: violet band, pointwise 95% household cluster bootstrap interval (conditional on fixed model fits and fold assignments); gray band between dashed lines, prespecified practical-importance bound of ±1 per 1,000. Model rankings use outer-fold predictions from household-blocked cross-validation; all quantities are survey-weighted.

## Figure 3
**Figure 3.** Distribution of selection at 20% capacity. (**a**) Share of PHQ-8–positive adults in each subgroup who are selected under M0 and M1 (within-group sensitivity), with 95% household cluster bootstrap intervals. (**b**) M1 with unconstrained selection compared with an equal selection proportion across household income groups: total detection yield per 1,000 eligible adults with the difference, equal − unconstrained (top), and within-group sensitivity by income group (bottom). Survey-weighted estimates.

## Supplementary figures

**Figure S1.** Prior predictive check, computed on the analysis frame without the outcome. (**a**) Cumulative distribution of the prior-implied weighted share with PHQ-8 ≥ 10. (**b**) Prior-implied between-person standard deviation of the linear predictor. In both panels, M2 is shown with the originally specified prior SD of 1 per day for the three day-count coefficients, with prior SD 1/SD and with prior SD 1/(2 SD) per day (the version used); SD, weighted standard deviation of the day count.

**Figure S2.** Calibration of outer-fold predictions (first fold assignment): weighted observed share with PHQ-8 ≥ 10 against mean predicted probability by weighted decile of predicted probability, for M0, M1 and M2. The dashed line marks perfect calibration.

**Figure S3.** Distribution of the primary difference Δ(0.20). (**a**) Paired household cluster bootstrap replicates (sampling variability conditional on fixed model fits). (**b**) Model-based distribution over 1,000 outer-fold posterior draws with draw-specific rankings and selections (conditional on the fixed data and folds). The shaded band marks ±1 per 1,000. Shares of either distribution beyond the bound are not posterior probabilities for the population difference.

**Figure S4.** Sensitivity analyses of the primary difference in detection yield at 20% capacity (M1 − M0, per 1,000 eligible adults) with 95% household cluster bootstrap intervals. The shaded band marks ±1 per 1,000.
