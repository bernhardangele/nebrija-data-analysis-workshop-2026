# generate_plots.R
# R script to generate professional ex-Gaussian PDF plots for Session 2 slides

library(ggplot2)
library(dplyr)
library(tidyr)
library(here)

# Numerically stable ex-Gaussian PDF function in R
dexgauss <- function(x, mu, sigma, beta) {
  # Recover the Gaussian mean xi
  xi <- mu - beta
  
  # Compute terms in log-space to prevent overflow/underflow
  term1 <- -log(beta)
  term2 <- (xi - x) / beta
  term3 <- (sigma^2) / (2 * beta^2)
  z <- (x - xi) / sigma - sigma / beta
  term4 <- pnorm(z, log.p = TRUE)
  
  log_pdf <- term1 + term2 + term3 + term4
  exp(log_pdf)
}

# Define x-range for response times (seconds)
x_seq <- seq(0.2, 1.5, by = 0.002)

# ==========================================
# Scenario 1: Only 'mu' varies (beta constant)
# ==========================================
# We vary mu: 0.5s, 0.6s, 0.7s
# Constant parameters: sigma = 0.05s, beta = 0.1s
df_mu <- bind_rows(
  tibble(x = x_seq, mu = 0.5, sigma = 0.05, beta = 0.1, label = "mu = 0.5s (xi = 0.4s, beta = 0.1s)"),
  tibble(x = x_seq, mu = 0.6, sigma = 0.05, beta = 0.1, label = "mu = 0.6s (xi = 0.5s, beta = 0.1s)"),
  tibble(x = x_seq, mu = 0.7, sigma = 0.05, beta = 0.1, label = "mu = 0.7s (xi = 0.6s, beta = 0.1s)")
) %>%
  mutate(y = dexgauss(x, mu, sigma, beta))

p1 <- ggplot(df_mu, aes(x = x, y = y, color = label)) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = c("#C2002F", "#1F497D", "#E69F00")) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(face = "bold")
  ) +
  labs(
    title = "Ex-Gaussian Shift: Only mu Varies (beta Constant)",
    subtitle = "The entire distribution shifts laterally; shape and tail skew remain identical.",
    x = "Reaction Time (seconds)",
    y = "Probability Density"
  )

ggsave(here("presentations/images/exg_mu_varying.png"), p1, width = 8, height = 4.5, dpi = 300)

# ==========================================
# Scenario 2: Both mu & beta vary (xi constant)
# ==========================================
# Condition 1: mu = 0.6s, beta = 0.1s (xi = 0.5s)
# Condition 2: mu = 0.7s, beta = 0.2s (xi = 0.5s)
df_joint <- bind_rows(
  tibble(x = x_seq, mu = 0.6, sigma = 0.05, beta = 0.1, label = "Baseline (mu = 0.6s, beta = 0.1s, xi = 0.5s)"),
  tibble(x = x_seq, mu = 0.7, sigma = 0.05, beta = 0.2, label = "Fat Tail (mu = 0.7s, beta = 0.2s, xi = 0.5s)")
) %>%
  mutate(y = dexgauss(x, mu, sigma, beta))

p2 <- ggplot(df_joint, aes(x = x, y = y, color = label)) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = c("#1F497D", "#C2002F")) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(face = "bold")
  ) +
  labs(
    title = "The brms Interpretation Catch: Constant xi, Varying beta",
    subtitle = "Peak onset (xi) is identical, but overall mean (mu) increases due to the fat tail.",
    x = "Reaction Time (seconds)",
    y = "Probability Density"
  )

ggsave(here("presentations/images/exg_mu_beta_varying.png"), p2, width = 8, height = 4.5, dpi = 300)

# ==========================================
# Scenario 3: Systematic Grid Plot of xi and beta
# ==========================================
# Varying xi (Gaussian mean): 0.4s, 0.5s, 0.6s
# Varying beta (exponential tail): 0.05s, 0.15s, 0.25s
# Constant sigma = 0.05s
library(purrr)

grid_combinations <- expand.grid(
  xi = c(0.4, 0.5, 0.6),
  beta = c(0.05, 0.15, 0.25)
)

df_grid <- pmap_dfr(grid_combinations, function(xi, beta) {
  # In brms, mu = xi + beta
  mu <- xi + beta
  tibble(
    x = x_seq,
    xi = xi,
    beta = beta,
    mu = mu,
    y = dexgauss(x, mu, 0.05, beta)
  )
}) %>%
  mutate(
    xi_label = factor(paste0("xi = ", xi, "")),
    beta_label = factor(paste0("beta = ", beta, ""))
  )

p3 <- ggplot(df_grid, aes(x = x, y = y)) +
  geom_line(color = "#1F497D", linewidth = 1.2) +
  facet_grid(xi_label ~ beta_label) +
  theme_minimal(base_size = 12) +
  theme(
    strip.text = element_text(face = "bold", size = 11),
    plot.title = element_text(face = "bold", size = 16),
    axis.title = element_text(face = "bold"),
    panel.border = element_rect(color = "#ccc", fill = NA, linewidth = 0.5)
  ) +
  labs(
    title = "Systematic Effects of xi (Gaussian Mean) and beta (Tail Scale)",
    subtitle = "Rows show shifts in baseline latency (xi). Columns show changes in tail skew (beta).",
    x = "Reaction Time (seconds)",
    y = "Probability Density"
  )

ggsave(here("presentations/images/exg_grid.png"), p3, width = 9, height = 6.5, dpi = 300)

cat("Successfully generated ex-Gaussian density plots!\n")
