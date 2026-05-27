# ==============================================================================
# Nebrija Data Analysis Workshop 2026
# Session 1: Frequentist Linear Mixed-Effects Models (LMMs) with lme4
# Student Tutorial & Practical Exercise
# ==============================================================================
# 
# Goal: Load grammatical gender flanker experiment logs, preprocess reaction 
# times, apply custom orthogonal contrast coding, and fit linear mixed-effects 
# models using lme4, resolving convergence issues step-by-step.
#
# Prerequisites: Ensure tidyverse, lme4, MASS, and here are installed.
# If not, run: install.packages(c("tidyverse", "lme4", "MASS", "here"))

# ------------------------------------------------------------------------------
# 1. SETUP & LIBRARY LOADING
# ------------------------------------------------------------------------------

library(tidyverse) # For data cleaning, pipes, and visual plotting
library(lme4)      # For linear mixed-effects modeling (lmer)
library(MASS)      # For generalized inverse matrix computation (ginv)
library(here)      # For robust, platform-independent file path resolution

# ------------------------------------------------------------------------------
# 2. DATA LOADING & EXCLUSIONS
# ------------------------------------------------------------------------------
# We load the Flanker Exp 1 correct reaction times dataset.
# The 'here' library resolves paths relative to the project root directory.

cat("Step 1: Loading raw flanker data...\n")
flanker_raw <- read_csv(here("data", "exp1_data_for_analysis.csv"))

# Inspect the raw dataset
glimpse(flanker_raw)

# EXCLUSIONS AND PREPROCESSING:
# 1. Timeout Exclusions: Exclude trials where participants timed out (corr == -1)
# 2. Physiological Plausibility: Retain manual RTs strictly between 250ms and 1800ms
# 3. Factor Casting: Cast Subject, Target Word, Condition, and Gender as factors
cat("\nStep 2: Preprocessing and applying outlier exclusions...\n")
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

# Summary of clean dataset
cat("Clean trials for analysis: ", nrow(flanker_rt_data), "\n")

# ------------------------------------------------------------------------------
# 3. CUSTOM ORTHOGONAL CONTRAST CODING
# ------------------------------------------------------------------------------
# Default treatment contrasts compare levels to a baseline (e.g. CON). To directly
# test our hypotheses, we define orthogonal custom contrasts:
#
# Contrast 1: CON vs AGR (concordant flankers vs. baseline control)
# Contrast 2: CON_AGR vs DIS (average of CON & AGR vs. discordant flankers)
#
# We use MASS::ginv() to calculate the generalized inverse. This maps our
# intuitive "differences format" hypotheses directly onto regression coefficients.

cat("\nStep 3: Setting up custom orthogonal contrasts...\n")

# Step A: Define contrast differences matrix
# Rows represent levels: CON, AGR, DIS
# Columns represent hypotheses
contr_matrix <- matrix(
  c(
     1, -1,  0,    # Contrast 1: CON vs AGR
     0.5, 0.5, -1  # Contrast 2: (CON + AGR)/2 vs DIS
  ), 
  nrow = 3, 
  dimnames = list(c("CON", "AGR", "DIS"), c("CON_vs_AGR", "CON_AGR_vs_DIS"))
)

# Step B: Apply generalized inverse to obtain regression coefficients format
contr_matrix_inv <- zapsmall(t(ginv(contr_matrix))) %>%
  matrix(nrow = 3, dimnames = list(c("CON", "AGR", "DIS"), c("CON_vs_AGR", "CON_AGR_vs_DIS")))

# View the mapped contrast weights
print(contr_matrix_inv)

# Step C: Assign contrasts to factors
contrasts(flanker_rt_data$Condition) <- contr_matrix_inv
contrasts(flanker_rt_data$StimulusType) <- contr.sum(2) # Sum coding for target noun gender (-1, 1)

# Verify factor contrasts look correct
cat("\nCondition Contrasts Mapped:\n")
print(contrasts(flanker_rt_data$Condition))

cat("\nStimulusType (Gender) Contrasts Mapped:\n")
print(contrasts(flanker_rt_data$StimulusType))

# ------------------------------------------------------------------------------
# 4. FITTING LINEAR MIXED-EFFECTS MODELS (LMMs)
# ------------------------------------------------------------------------------

# ---------------------------------------------------------
# MODEL 1: The Maximal Random Effects Structure
# ---------------------------------------------------------
# Barr et al. (2013) recommend fitting the maximal random effects structure 
# justified by the experimental design. This includes crossed random intercepts 
# for subjects and items, plus crossed random slopes for all within-unit factors.
#
# Note: StimulusType (noun gender) is a random slope for subjects (each subject 
# sees both MAS and FEM), but NOT for items (each target noun has only ONE gender!).

cat("\nStep 4: Attempting to fit Model 1 (Maximal LMM)...\n")
cat("Please note: This may take several minutes to run and will trigger convergence warnings!\n")

# UNCOMMENT THE CODE BELOW TO RUN THE MAXIMAL MODEL:
# m_max <- lmer(
#   rt ~ Condition * StimulusType + 
#     (1 + Condition * StimulusType | subject) + 
#     (1 + Condition | item),
#   data = flanker_rt_data
# )
# summary(m_max)

# Student Discussion Point: Why does the maximal model fail to converge?
# Answer: The model is overly complex; there are not enough data points per unit
# to reliably estimate all variances and correlation parameters (especially the 
# large correlation matrix for the 6-level random slope structure of subject!).

# ---------------------------------------------------------
# MODEL 2: The Zero-Correlation (Double Pipe) LMM
# ---------------------------------------------------------
# If a maximal model fails to converge, a common next step is to remove
# correlations between random intercepts and slopes using the double-pipe '||'.
# This dramatically reduces the number of parameters the optimizer must solve.

cat("\nStep 5: Attempting to fit Model 2 (Zero-Correlation LMM)...\n")

# UNCOMMENT THE CODE BELOW TO RUN THE ZERO-CORRELATION MODEL:
# m_zerocor <- lmer(
#   rt ~ Condition * StimulusType + 
#     (1 + Condition * StimulusType || subject) + 
#     (1 + Condition || item),
#   data = flanker_rt_data
# )
# summary(m_zerocor)

# Student Discussion Point: Did removing correlations fix the warning?
# Answer: For this foveal Flanker dataset, a model with this many random slope
# components still fails to converge. We must simplify the slopes.

# ---------------------------------------------------------
# MODEL 3: The Simplified, Converged LMM
# ---------------------------------------------------------
# We systematically remove random slopes with negligible variance (e.g. target 
# item random slopes) while retaining the critical Condition slopes for subjects
# that correspond directly to our main research questions.

cat("\nStep 6: Fitting Model 3 (Simplified LMM with converged parameters)...\n")

m_rt <- lmer(
  rt ~ Condition * StimulusType + 
    (1 + Condition || subject) + 
    (1 | item),
  data = flanker_rt_data
)

# ------------------------------------------------------------------------------
# 5. MODEL RESULTS & DIAGNOSTICS
# ------------------------------------------------------------------------------

# Display the full model output
cat("\n--- MODEL 3 SUMMARY SUMMARY ---\n")
print(summary(m_rt))

# Student Questions for Interpretation:
#
# 1. FIXED EFFECTS:
#    Look at the 'Fixed effects' section of the summary.
#    - Is there a significant effect of 'ConditionCON_vs_AGR'? 
#      What does a negative coefficient tell you about reaction times?
#    - Is there a significant effect of 'ConditionCON_AGR_vs_DIS'?
#      Does this support an interference account?
#    - Is there a significant interaction between Condition and StimulusType?
#
# 2. RANDOM EFFECTS:
#    Look at the 'Random effects' section of the summary.
#    - How much variance does the 'item' (word) random intercept explain 
#      compared to the 'subject' random intercept?
#    - Is there substantial individual variance in how subjects respond 
#      to the experimental conditions?

# ------------------------------------------------------------------------------
# 6. VISUALIZING RESIDUALS (Model Diagnostics)
# ------------------------------------------------------------------------------
# It is critical to inspect the model's residuals to check the normality and 
# homoscedasticity assumptions of linear mixed models.

cat("\nStep 7: Plotting residuals to check assumptions...\n")

# Residuals vs. Fitted plot
residuals_plot <- ggplot(data.frame(Fitted = fitted(m_rt), Residuals = residuals(m_rt)), aes(x = Fitted, y = Residuals)) +
  geom_point(alpha = 0.1, color = "#1F497D") +
  geom_hline(yintercept = 0, color = "#C2002F", linetype = "dashed", linewidth = 1) +
  theme_minimal() +
  labs(
    title = "Residuals vs. Fitted Values (Model 3)",
    x = "Fitted Values (Predicted RT)",
    y = "Residuals"
  )

# Uncomment below to view or save the plot if running in RStudio:
# print(residuals_plot)

cat("\nTutorial complete! You are now ready to compare these results to Session 2's Bayesian brms LMM.\n")
