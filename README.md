# nebrija-data-analysis-workshop-2026

Workshop materials for the seminar **"Data Analysis Course: Frequentist and Bayesian Statistics"** in the
**PhD Program in Education and Cognitive Processes (Universidad Nebrija, 2026)**.

## Course format

- **Instructor:** Dr. Bernhard Angele
- **Dates:** Wednesday 27 May 2026 (15:00–18:00) and Thursday 28 May 2026 (15:00–18:00)
- **Delivery mode:** Online (Collaborate Ultra)
- **Total workload:** 10 hours
  - 2h pre-readings
  - 6h synchronous teaching (2 sessions × 3h)
  - 2h autonomous final task

## Repository structure

- `presentations/session-1-lme4.qmd` – Session 1 (frequentist mixed-effects models with `lme4`)
- `presentations/session-2-brms.qmd` – Session 2 (Bayesian mixed-effects models with `brms`)
- `analysis-workshop/` – previous workshop materials consolidated into this 2026 course
- `power-workshop/` – previous workshop materials consolidated into this 2026 course
- `.devcontainer/devcontainer.json` – development container specification for local Docker / GitHub Codespaces

## Session learning goals

### Session 1 (3h): Frequentist mixed-effects models (`lme4`)

- Align model architecture with complex experimental designs in cognitive psychology and psycholinguistics
- Specify and justify crossed random effects (participants and items), including maximal structures
- Diagnose and solve convergence and singular-fit problems
- Apply contrast coding and produce publication-ready frequentist reporting

### Session 2 (3h): Bayesian mixed-effects models (`brms`)

- Transition from frequentist to Bayesian multilevel modeling
- Specify regularizing priors and interpret posterior distributions
- Fit models for non-normal outcomes (e.g., reaction times, ordinal judgments)
- Report Bayesian analyses for peer-reviewed publication contexts

## Evaluation

- Synchronous attendance and participation
- Final autonomous assignment (max 1 page):
  - Fit a mixed-effects model with `lme4` or `brms`
  - Use own doctoral data or instructor-provided public data
  - Write a results-style report justifying model structure

## Required pre-readings

1. Barr, D. J., Levy, R., Scheepers, C., & Tily, H. J. (2013). *Random effects structure for confirmatory hypothesis testing: Keep it maximal.* Journal of Memory and Language, 68(3), 255–278.
2. Matuschek, H., Kliegl, R., Vasishth, S., Baayen, H., & Bates, D. (2017). *Balancing Type I error and power in linear mixed models.* Journal of Memory and Language, 94, 305–315.

## Technical preparation (mandatory before Session 1)

### Option A: Local installation (R + RStudio)

1. Install latest R from CRAN: <https://cran.r-project.org>
2. Install latest RStudio Desktop: <https://posit.co/download/rstudio-desktop/>
3. Install C++ toolchain:
   - **Windows:** Install matching Rtools version for your R version
   - **macOS:** run `xcode-select --install`
4. Install required packages in R:

```r
install.packages(c("tidyverse", "lme4", "brms", "emmeans", "tidybayes"))
```

5. Run a quick `brms` compilation test:

```r
library(brms)
fit_test <- brm(count ~ zAge + zBase, data = epilepsy, family = poisson())
summary(fit_test)
```

### Option B: GitHub Codespaces (recommended)

This repository provides a devcontainer for cloud execution with RStudio Server.

1. Open this repository on GitHub
2. Select **Code → Codespaces → Create codespace on main**
3. Wait for container startup
4. Open forwarded port `8787` to access RStudio Server in browser

### Option C: Local Docker/devcontainer

You can run the same environment locally with Docker by using the repository devcontainer specification:

- File: `.devcontainer/devcontainer.json`
- Base image: `bangele1/analysis-in-a-box-rocker:latest`
- Exposed RStudio Server port: `8787`
- Includes `CMDSTAN` path and VS Code R/Quarto extensions

In VS Code, install the Dev Containers extension, then use:

- **Dev Containers: Reopen in Container**

## Render slides

From repository root:

```bash
quarto render
```

This renders both workshop sessions defined in `_quarto.yml`.

## Additional bibliography for deepening

- Winter, B. (2019). *Statistics for Linguists: An Introduction Using R.* Routledge.
- McElreath, R. (2020). *Statistical Rethinking: A Bayesian Course with Examples in R and Stan (2nd ed.).* CRC Press.
- Llaudet, E., & Imai, K. (2022). *Data Analysis for Social Science: A Friendly and Practical Introduction.* Princeton University Press.
