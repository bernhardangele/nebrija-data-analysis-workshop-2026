# fit_gaussian_brms.R
# Script to fit three Bayesian models on the full flanker dataset using brms
# Models:
#   1. Gaussian LMM
#   2. ex-Gaussian LMM (fixed/random effects only on mu, global beta)
#   3. ex-Gaussian LMM (fixed/random effects on both mu and beta)
#
# Path resolution: Uses the 'here' library relative to the project root.

library(tidyverse)
library(brms)
library(qs2)
library(here)
library(ggplot2)
library(bayesplot)

# Configure CmdStan path explicitly
cmdstanr::set_cmdstan_path("/opt/cmdstan/cmdstan-2.38.0")

# Set up bayesplot color scheme to match school branding
color_scheme_set("red")

# Load Flanker Exp 1 data using the here package
flanker_raw <- read_csv(here("data", "exp1_data_for_analysis.csv"))

# Preprocessing
flanker_clean <- flanker_raw %>%
  filter(
    corr != -1,
    rt >= 0.25 & rt <= 1.8
  ) %>%
  mutate(
    Condition = factor(Condition, levels = c("CON", "AGR", "DIS")),
    StimulusType = factor(StimulusType, levels = c("MAS", "FEM")),
    subject = factor(PROLIFIC_PID),
    item = factor(Target)
  )

# Filter correct trials for RT modeling (using ALL subjects)
flanker_rt_data <- flanker_clean %>% filter(corr == 1)

# Set up contrasts to match Session 1 LMM design
# Sum coding for gender (-1, 1)
contrasts(flanker_rt_data$StimulusType) <- contr.sum(2)

# Custom hypothesis contrast matrix as defined in Session 1
library(MASS)
contr_matrix <- matrix(c(
   1, -1,  0,    # Contrast 1: CON vs AGR
   0.5, 0.5, -1  # Contrast 2: (CON + AGR) vs DIS
), nrow = 3, dimnames = list(c("CON", "AGR", "DIS"), c("CON_vs_AGR", "CON_AGR_vs_DIS")))

# Apply the generalized inverse to map contrasts onto regression coefficients
contr_matrix_inv <- zapsmall(t(ginv(contr_matrix))) %>%
  matrix(nrow = 3, dimnames = list(c("CON", "AGR", "DIS"), c("CON_vs_AGR", "CON_AGR_vs_DIS")))

contrasts(flanker_rt_data$Condition) <- contr_matrix_inv

cat("Data prepared successfully. Total rows for modeling: ", nrow(flanker_rt_data), "\n")


# ==============================================================================
# MODEL 1: GAUSSIAN LMM
# ==============================================================================
cat("\n--- Fitting Model 1: Gaussian brms LMM on full dataset ---\n")

fit_gaussian <- brm(
  formula = rt ~ Condition * StimulusType + (Condition * StimulusType | subject) + (Condition | item),
  data = flanker_rt_data,
  family = gaussian(),
  prior = c(
    #prior(normal(0.6, 0.2), class = "Intercept"),
    prior(normal(0, 0.1), class = "b"),
    prior(exponential(2), class = "sd"),
    prior(lkj(2), class = "cor")
  ),
  chains = 4, iter = 2000, warmup = 1000,
  cores = 4, backend = "cmdstanr"
)

# Save Model 1
cat("Saving fit_gaussian.qs2...\n")
qs_save(fit_gaussian, here("presentations", "fit_gaussian.qs2"))

# PPC Model 1
cat("Exporting Gaussian PPC Plot...\n")
ppc_gauss <- pp_check(fit_gaussian, ndraws = 50) +
  theme_minimal(base_family = "sans") +
  labs(
    title = "Posterior Predictive Check (Gaussian brms LMM)",
    subtitle = "Observed y (thick dark line) vs. 50 simulated datasets y_rep (thin red lines)",
    x = "Reaction Time (s)",
    y = "Density"
  ) +
  theme(plot.title = element_text(face = "bold", color = "#1F497D"), legend.position = "bottom")

ggsave(here("presentations", "images", "gaussian_ppc.png"), plot = ppc_gauss, width = 8, height = 5, dpi = 300)


# ==============================================================================
# MODEL 2: EX-GAUSSIAN (mu-only)
# ==============================================================================
# This model places fixed and random effects ONLY on the Gaussian mean parameter (mu).
# The exponential parameter (beta) is estimated as a single global population parameter.
cat("\n--- Fitting Model 2: ex-Gaussian LMM (mu-only) on full dataset ---\n")

fit_exgaussian_mu <- brm(
  formula = rt ~ Condition * StimulusType + (Condition * StimulusType | subject) + (Condition | item),
  data = flanker_rt_data,
  family = exgaussian(),
  prior = c(
    #prior(normal(0.6, 0.2), class = "Intercept"),
    prior(normal(0, 0.1), class = "b"),
    prior(exponential(2), class = "sd"),
    prior(lkj(2), class = "cor"),
    
    # Prior for global exponential parameter beta (raw scale class)
    prior(exponential(10), class = "beta")
  ),
  chains = 4, iter = 2000, warmup = 1000,
  control = list(adapt_delta = 0.95),
  cores = 4, backend = "cmdstanr"
)

# Save Model 2
cat("Saving fit_exgaussian_mu.qs2...\n")
qs_save(fit_exgaussian_mu, here("presentations", "fit_exgaussian_mu.qs2"))

# PPC Model 2
cat("Exporting ex-Gaussian (mu-only) PPC Plot...\n")
ppc_exg_mu <- pp_check(fit_exgaussian_mu, ndraws = 50) +
  theme_minimal(base_family = "sans") +
  labs(
    title = "Posterior Predictive Check (ex-Gaussian LMM - mu only)",
    subtitle = "Observed y (thick dark line) vs. 50 simulated datasets y_rep (thin red lines)",
    x = "Reaction Time (s)",
    y = "Density"
  ) +
  theme(plot.title = element_text(face = "bold", color = "#1F497D"), legend.position = "bottom")

ggsave(here("presentations", "images", "exgaussian_mu_ppc.png"), plot = ppc_exg_mu, width = 8, height = 5, dpi = 300)


# ==============================================================================
# MODEL 3: EX-GAUSSIAN (mu and beta)
# ==============================================================================
# This model places fixed and random effects on BOTH mu and the exponential parameter beta.
cat("\n--- Fitting Model 3: ex-Gaussian LMM (mu and beta) on full dataset ---\n")

formula_mu_beta <- bf(
  rt ~ Condition * StimulusType + (Condition * StimulusType | subject) + (Condition | item),
  beta ~ Condition * StimulusType + (Condition * StimulusType | subject) + (Condition | item)
)

fit_exgaussian_mu_beta <- brm(
  formula = formula_mu_beta,
  data = flanker_rt_data,
  family = exgaussian(),
  init = 0,
  prior = c(
    # mu priors
    #prior(normal(0.6, 0.2), class = "Intercept"),
    prior(normal(0, 0.1), class = "b"),
    prior(exponential(2), class = "sd"),
    prior(lkj(2), class = "cor"),
    
    # beta priors
    #prior(normal(-1.5, 0.5), class = "Intercept", dpar = "beta"),
    prior(normal(0, 0.3), class = "b", dpar = "beta"),
    prior(exponential(2), class = "sd", dpar = "beta")
  ),
  chains = 4, iter = 2000, warmup = 1000,
  control = list(adapt_delta = 0.8),
  cores = 4, backend = "cmdstanr",
  threads = threading(2)
)

# Save Model 3
cat("Saving fit_exgaussian_mu_beta.qs2...\n")
qs_save(fit_exgaussian_mu_beta, here("presentations", "fit_exgaussian_mu_beta.qs2"))

# PPC Model 3
cat("Exporting ex-Gaussian (mu & beta) PPC Plot...\n")
ppc_exg_mu_beta <- pp_check(fit_exgaussian_mu_beta, ndraws = 50) +
  theme_minimal(base_family = "sans") +
  labs(
    title = "Posterior Predictive Check (ex-Gaussian LMM - mu & beta)",
    subtitle = "Observed y (thick dark line) vs. 50 simulated datasets y_rep (thin red lines)",
    x = "Reaction Time (s)",
    y = "Density"
  ) +
  theme(plot.title = element_text(face = "bold", color = "#1F497D"), legend.position = "bottom")

ggsave(here("presentations", "images", "exgaussian_mu_beta_ppc.png"), plot = ppc_exg_mu_beta, width = 8, height = 5, dpi = 300)


cat("\nAll three Bayesian models successfully fit, saved, and checked on the full dataset!\n")
