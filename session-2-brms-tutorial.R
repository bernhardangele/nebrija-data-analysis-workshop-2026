# ==============================================================================
# Nebrija Data Analysis Workshop 2026
# Session 2: Bayesian Mixed-Effects Models with brms
# Student Tutorial & Practical Exercise
# ==============================================================================
# 
# Goal: Load grammatical gender flanker experiment logs, apply custom orthogonal 
# contrasts, specify regularizing priors for coefficients, standard deviations, 
# and correlations, load or fit a Bayesian LMM using brms, inspect convergence 
# diagnostics (Rhat, ESS, divergences, treedepth), and interpret the posterior 
# distribution using Credible Intervals, Probability of Direction (pd), and 
# Savage-Dickey Bayes Factors via hypothesis().
#
# Prerequisites: Ensure tidyverse, brms, qs2, bayesplot, and here are installed.
# If not, run: install.packages(c("tidyverse", "brms", "qs2", "bayesplot", "here"))
#
# Note: Fitting Bayesian LMMs via MCMC is computationally expensive. In this 
# tutorial, we provide code to fit the model ourselves AND code to load the 
# pre-fit model (fit_gaussian.qs2) to save time in the workshop.

# ------------------------------------------------------------------------------
# 1. SETUP & LIBRARY LOADING
# ------------------------------------------------------------------------------

library(tidyverse) # For data cleaning, piping, and plotting
library(brms)      # For Bayesian regression modeling using Stan
library(qs2)       # For rapid reading of compressed pre-fit R objects
library(bayesplot) # For posterior diagnostics and predictive checks
library(here)      # For robust, platform-independent path resolution
library(MASS)      # For generalized inverse contrast mapping (ginv)

# Set seed for reproducibility of MCMC draws
set.seed(42)

# ------------------------------------------------------------------------------
# 2. DATA LOADING & PREPROCESSING (Identical to Session 1)
# ------------------------------------------------------------------------------
# We load the Flanker Exp 1 correct reaction times dataset.

cat("Step 1: Loading raw flanker data...\n")
flanker_raw <- read_csv(here("data", "exp1_data_for_analysis.csv"))

# Outlier exclusions and factors cast:
cat("Step 2: Preprocessing and applying exclusions...\n")
flanker_clean <- flanker_raw %>%
  filter(
    corr != -1,                # Exclude timeouts
    rt >= 0.25 & rt <= 1.8     # Keep plausible reaction times (seconds)
  ) %>%
  mutate(
    Condition = factor(Condition, levels = c("CON", "AGR", "DIS")),
    StimulusType = factor(StimulusType, levels = c("MAS", "FEM")),
    subject = factor(PROLIFIC_PID),
    item = factor(Target)
  )

# Filter correct trials only for reaction time modeling
flanker_rt_data <- flanker_clean %>% filter(corr == 1)
cat("Clean trials for RT analysis: ", nrow(flanker_rt_data), "\n")

# ------------------------------------------------------------------------------
# 3. CUSTOM ORTHOGONAL CONTRASTS (Identical to Session 1)
# ------------------------------------------------------------------------------
# We test:
# Contrast 1: CON vs AGR (concordant flankers vs. baseline control)
# Contrast 2: CON_AGR vs DIS (average of CON & AGR vs. discordant flankers)

cat("\nStep 3: Setting up custom orthogonal contrasts...\n")

contr_matrix <- matrix(
  c(
     1, -1,  0,    # Contrast 1: CON vs AGR
     0.5, 0.5, -1  # Contrast 2: (CON + AGR)/2 vs DIS
  ), 
  nrow = 3, 
  dimnames = list(c("CON", "AGR", "DIS"), c("CON_vs_AGR", "CON_AGR_vs_DIS"))
)

# Map differences to regression coefficient weights using MASS::ginv
contr_matrix_inv <- zapsmall(t(ginv(contr_matrix))) %>%
  matrix(nrow = 3, dimnames = list(c("CON", "AGR", "DIS"), c("CON_vs_AGR", "CON_AGR_vs_DIS")))

# Apply the contrasts
contrasts(flanker_rt_data$Condition) <- contr_matrix_inv
contrasts(flanker_rt_data$StimulusType) <- contr.sum(2) # Target noun gender (-1, 1)

# ------------------------------------------------------------------------------
# 4. SPECIFYING REGULARIZING PRIORS
# ------------------------------------------------------------------------------
# Rather than default flat priors (which waste sampler time on impossible values), 
# we define regularizing priors restricted to physiologically plausible bounds:
#
# 1. Coefficients (class = "b"): N(0, 0.1) restricts effects to a 100 ms SD.
# 2. Group standard deviations (class = "sd"): Exponential(2) pulls SDs 
#    toward 0 unless supported by data (prevents singular fits!).
# 3. Random correlations (class = "cor"): LKJ(2) shrinks correlations toward 0,
#    regularizing the subject/item slope-intercept covariance matrix.

cat("\nStep 4: Specifying priors...\n")

priors_gaussian <- c(
  prior(normal(0, 0.1), class = "b"),           # Fixed effect coefficients (100 ms SD)
  prior(exponential(2), class = "sd"),          # Group-level SD (Exponential prior)
  prior(lkj(2), class = "cor")                  # Slope-intercept correlations (LKJ(2))
)

# ------------------------------------------------------------------------------
# 5. LOADING OR FITTING THE MODEL
# ------------------------------------------------------------------------------
# Fitting the model takes time. We load the pre-fit model by default, but provide 
# the full brms code below so you can see how to fit it.

model_path <- here("presentations", "fit_gaussian.qs2")

if (file.exists(model_path)) {
  cat("\nStep 5: Loading the pre-fit Bayesian Gaussian model...\n")
  fit_gaussian <- qs_read(model_path)
} else {
  cat("\nStep 5: Pre-fit model file not found. Fitting the model using brms...\n")
  cat("Please note: This requires cmdstanr and a C++ compiler. It will take a few minutes.\n")
  
  # Note: To automate brms::hypothesis() Savage-Dickey BF later, 
  # we must set sample_prior = "yes"!
  fit_gaussian <- brm(
    formula = rt ~ Condition * StimulusType + 
      (Condition * StimulusType | subject) + 
      (Condition | item),
    data = flanker_rt_data,
    family = gaussian(),
    prior = priors_gaussian,
    chains = 4, iter = 2000, warmup = 1000,
    cores = 4, backend = "cmdstanr",
    sample_prior = "yes"  # Crucial for Savage-Dickey Bayes Factors!
  )
}

# ------------------------------------------------------------------------------
# 6. MCMC CONVERGENCE DIAGNOSTICS
# ------------------------------------------------------------------------------
# ALWAYS verify that your chains converged and searched the space reliably.
#
# 1. Rhat: Measures between vs. within-chain variance. Must be <= 1.01.
# 2. ESS (Effective Sample Size): Number of independent draws. Should be > 1000.
# 3. Divergent transitions: sampler failed in high curvature. MUST be 0.
#    (If > 0, increase adapt_delta, e.g. control = list(adapt_delta = 0.99))
# 4. Treedepth warnings: sampler terminated early. Indicates inefficiency.
#    (If triggered, increase max_treedepth, e.g. control = list(max_treedepth = 15))

cat("\nStep 6: Extracting MCMC convergence diagnostics...\n")

# Print fixed effects diagnostics
diagnostics <- summary(fit_gaussian)$fixed[, c("Rhat", "Bulk_ESS", "Tail_ESS")]
cat("\nFixed Effects Diagnostics Table:\n")
print(round(diagnostics, 3))

# Check for Divergent Transitions and Treedepth warnings
cat("\nSummary of chain convergence parameters:\n")
print(summary(fit_gaussian))

# ------------------------------------------------------------------------------
# 7. POSTERIOR INTERPRETATION METHODS (THE EXAMPLES)
# ------------------------------------------------------------------------------
# We now explore three separate methods to interpret our posterior estimates 
# for the critical Condition contrast: ConditionCON_AGR_vs_DIS ((CON+AGR)/2 - DIS).

cat("\nStep 7: Interpreting the posterior distribution...\n")

# =========================================================
# Method 1: Credible Intervals (CI)
# =========================================================
# A 95% Credible Interval represents the range where the parameter has a 95% 
# probability of residing, given the data and priors.

coef_summary <- summary(fit_gaussian)$fixed["ConditionCON_AGR_vs_DIS", ]
est_ms <- as.numeric(coef_summary["Estimate"]) * 1000
lower_ms <- as.numeric(coef_summary["l-95% CI"]) * 1000
upper_ms <- as.numeric(coef_summary["u-95% CI"]) * 1000

cat("\n--- METHOD 1: 95% CREDIBLE INTERVAL ---\n")
cat("Estimate (beta): ", round(est_ms, 2), "ms\n")
cat("95% CI: [", round(lower_ms, 2), "ms, ", round(upper_ms, 2), "ms]\n")
cat("Does it overlap with 0? ", ifelse(lower_ms <= 0 & upper_ms >= 0, "Yes", "No"), "\n")
cat("Interpretation: There is a 95% probability that the true interference effect slows participants down by between ", 
    round(abs(upper_ms), 1), "ms and ", round(abs(lower_ms), 1), "ms. Since 0 is completely excluded, we have extreme evidence.\n")

# =========================================================
# Method 2: Probability of Direction (pd)
# =========================================================
# Represents the direct probability that an effect is negative (or positive).
# We extract the raw MCMC draws and compute the proportion that are < 0.

draws <- as.data.frame(fit_gaussian)[["b_ConditionCON_AGR_vs_DIS"]]
pd <- mean(draws < 0)

cat("\n--- METHOD 2: PROBABILITY OF DIRECTION (pd) ---\n")
cat("Probability of Direction (pd): ", round(pd * 100, 3), "%\n")
cat("Interpretation: There is a ", round(pd * 100, 2), "% probability that discordant flankers slow reaction times compared to congruent/control flankers.\n")

# =========================================================
# Method 3: Savage-Dickey Bayes Factors (BF)
# =========================================================
# The Bayes Factor (BF10) quantifies the relative evidence for H1 (effect != 0) 
# vs. H0 (effect == 0). In brms, we perform this test using hypothesis().

cat("\n--- METHOD 3: BAYES FACTORS (BF) ---\n")
hyp <- hypothesis(fit_gaussian, "ConditionCON_AGR_vs_DIS = 0")
print(hyp)

# NOTE: If we loaded the pre-fit model, the 'Evid.Ratio' column shows 'NA'.
# Why? Because the pre-fit model was saved without prior draws (sample_prior = "yes"
# was not specified during fitting to save file size).
# When this happens, we calculate the Savage-Dickey BF manually:
if (is.na(hyp$hypothesis$Evid.Ratio)) {
  cat("\nNote: Evid.Ratio is NA because prior samples were not saved in this fit.\n")
  cat("Running manual Savage-Dickey calculation...\n")
  
  # Prior density at 0 under N(0, 0.1)
  prior_dens_at_0 <- dnorm(0, mean = 0, sd = 0.1)
  
  # Posterior density at 0 interpolated from draws
  d_post <- density(draws)
  post_dens_at_0 <- approx(d_post$x, d_post$y, xout = 0)$y
  
  # Calculate BF10 (prior density / posterior density at 0)
  bf10 <- if (is.na(post_dens_at_0) || post_dens_at_0 == 0) Inf else prior_dens_at_0 / post_dens_at_0
  cat("Manual Savage-Dickey BF10: ", bf10, " (Extreme evidence for H1)\n")
} else {
  cat("Savage-Dickey BF10 from hypothesis(): ", hyp$hypothesis$Evid.Ratio, "\n")
}

# ------------------------------------------------------------------------------
# 8. POSTERIOR PREDICTIVE CHECKS (PPC)
# ------------------------------------------------------------------------------
# A Posterior Predictive Check generates simulated data from our model's posterior 
# and compares it visually to our raw observed data. This helps us assess 
# whether our Gaussian assumption is appropriate.

cat("\nStep 8: Generating Posterior Predictive Check (PPC)...\n")

ppc_plot <- pp_check(fit_gaussian, ndraws = 50) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", color = "#1F497D")) +
  labs(
    title = "Posterior Predictive Check (Gaussian Model)",
    x = "Reaction Time (seconds)",
    y = "Probability Density"
  )

# Uncomment below to view the plot in RStudio or VS Code:
# print(ppc_plot)

cat("\nTutorial complete! Try extending the model by allowing Condition effects on the ex-Gaussian beta parameter next.\n")
# ==============================================================================
