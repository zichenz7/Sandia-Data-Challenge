# Modeling and validation

[Project overview](README.md) · [Main R analysis](without%20R.R)

## Problem and data preparation

The challenge asks which combinations of build parameters are associated with the lowest potential scrap rate for additively manufactured parts. The supplied data include dimensional measurements, inspection nonconformity, powder type, build plate, layout, and row/column position.

The main script standardizes virgin and recycled inputs, harmonizes the alternate `Nonconfirmity` spelling, converts plate/layout identifiers, and derives a binary `is_bad` response. A part fails if any of eight dimensional checks fails or inspection marks it nonconforming. Missing required dimensional measurements fail the main script's tolerance check. If an `is_bad` column already exists, the script uses it rather than recomputing it, so input preparation matters.

Build plate R is explicitly excluded. The archived final model summary reports **n = 1,448** after the analysis preparation. That is the model's reported sample size, not a claim that all original plates entered the final fit. The surviving script does not document a substantive reason for excluding R; that choice remains a sensitivity-analysis question.

## Model specification

The fitted response is Bernoulli with a logit link:

```r
is_bad ~ layout_ta + powder_rec +
  te(row_num, col_num, bs = c("cr", "cr"), k = c(5, 5)) +
  s(PlateID, bs = "re")
```

The model is fitted with `mgcv::gam(..., family = binomial, method = "REML")`.

| Component | Reason for including it |
| --- | --- |
| `layout_ta` | Three observed design categories: `11x11_TA`, `6x6_noTA`, and `6x6_TA`; the first is the reference |
| `powder_rec` | Indicator for recycled rather than virgin powder |
| `te(row_num, col_num)` | Tensor-product cubic-regression smooth for a nonlinear spatial risk surface |
| `s(PlateID, bs = "re")` | Random intercept for plate-level clustering |

The combined layout/TA factor addresses the absence of an independent 11×11/no-TA design in the main encoding. It does not make every powder/configuration combination equally well supported. The same smooth is shared across groups: there are no explicit powder-by-layout or group-specific spatial interaction terms.

## Validation and recorded results

### Model progression

The team presentation records these diagnostics for three nested specifications:

| Specification | Deviance explained |
| --- | ---: |
| Layout/TA + powder | 1.2% |
| Above + plate random intercept | 8.7% |
| Above + two-dimensional position smooth | 12.5% |

The presentation's AIC plot also decreases across these steps. Exact AIC values are not transcribed because the archived figure provides plotted points rather than a numeric table.

The full-model summary reports adjusted R² of approximately 0.10 and deviance explained of 12.5%. For this binomial model, these are descriptive fit summaries; neither is classification accuracy.

### Calibration and residual checks

The main script groups fitted probabilities into ten bins and plots mean predicted risk against observed scrap frequency, with approximate binomial error bars. It also plots Pearson residuals against fitted probabilities with a smooth trend.

These predictions come from the **same observations used to fit the model and include fitted plate effects**. The calibration and residual figures are useful for diagnosing the fit, but they do not measure generalization to a new plate. The error bars do not explicitly adjust for within-plate dependence. No held-out split, cross-validation score, ROC-AUC, or Brier score is established by the archived analysis.

### Adjusted configuration estimates

The presentation reports the following fixed-effects-only probabilities:

| Layout / test artifacts | Virgin powder | Recycled powder |
| --- | ---: | ---: |
| 6×6, no TA | **5.2%** | 8.0% |
| 6×6, with TA | 8.0% | 12.2% |
| 11×11, with TA | 9.8% | 14.6% |

The code generates this comparison by **excluding the spatial smooth and plate random-effect terms** at prediction time. It sets those terms' contributions to zero; it does not average predictions over the empirical distribution of plates and locations. Accordingly, these are fixed-effects-only point estimates, not marginal production scrap rates or a demonstrated reduction in scrap.

The archived coefficient table is important context:

| Contrast | Log-odds estimate | Standard error | p-value |
| --- | ---: | ---: | ---: |
| 6×6/no TA versus 11×11/TA | −0.6764 | 0.7624 | 0.375 |
| 6×6/TA versus 11×11/TA | −0.2138 | 0.7303 | 0.770 |
| Recycled versus virgin | 0.4613 | 0.5536 | 0.405 |

None of these three adjusted coefficients reaches the conventional 0.05 threshold. The point estimates make virgin powder with a 6×6/no-TA layout a candidate for further testing, rather than establishing a statistically conclusive optimum. Spatial and plate effects are prominent in the fitted model; a thermal explanation would require additional evidence.

### Evidence provenance

The numbers above are transcribed from the original **Cluster Commanders** presentation: slide 13 (fit progression and diagnostics), slide 14 (model summary and coefficients), and slide 17 (rounded configuration estimates). They are historical reported results, checked against the current public script, not a new model rerun. The README graphic is a new rendering of the three printed deviance values; its [R source](render_showcase_figure.R) makes that provenance explicit.

The original deck uses some stronger language about interactions, thermal mechanisms, and averaging. This documentation follows the implemented model and prediction calls when explaining what those figures support.

## Running the archived analysis

**Data access restriction:** challenge staff instructed the team not to publish the competition datasets. Their absence from this repository is intentional. This showcase documents methods, code, and previously recorded aggregate results; it does not distribute the underlying records.

The setup below is for team members or others with separately authorized access to the restricted inputs. It is not a public data-download workflow.

The main script expects these data frames to be present in an R session:

```r
AllData_PreEDM_Virgin_RowColIDs_correcteddates
AllData_PreEDM_Recycled_RowColIDs_correcteddates
```

Required columns include `PlateID`, `Layout`, `RowID`, `ColID`, an inspection nonconformity column, and the dimensional columns listed in the script. The main script loads `dplyr`, `mgcv`, `lme4`, `ggplot2`, and `patchwork`; other exploratory scripts also use the tidyverse and `scales`.

If you already have authorized access to the competition inputs, prepare the named data frames and run the main script from a clean R session:

```r
source("without R.R")
```

This is an archived workflow, not a fully packaged reproduction environment. Dependencies are not locked, several files assume preloaded objects, and model output is not stored as a machine-readable artifact. The restricted input files are intentionally not distributed, so a fresh clone alone cannot reproduce the fit. Full public reproduction would require a separately permitted dataset; the original competition records must not be uploaded to fill this gap.

Two implementation details deserve attention before reusing the plots: the main heatmap helper's data-mask filter compares column names with identically named arguments, which can fail to detect absent combinations; and the fixed-effects plot's original title says “averaging out” although the prediction call excludes those terms. The documentation describes these boundaries without changing the historical analysis scripts.

## What would strengthen the evidence

- Evaluate on held-out build plates, fitting all preprocessing and model terms within each training fold.
- Report out-of-plate calibration and probabilistic error, with uncertainty that respects plate clustering.
- Check sensitivity to plate R's exclusion, missing-measurement handling, and sparse design combinations.
- Compare selected configurations in additional builds before making a production or causal claim.

These are proposed extensions, not completed experiments.
