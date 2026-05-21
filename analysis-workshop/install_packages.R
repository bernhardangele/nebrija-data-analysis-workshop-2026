# Install required packages for LMM workshop
# Run this script before the workshop to ensure all dependencies are installed

# List of required packages
packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "lme4",         # Linear mixed effects models
  "lmerTest",     # P-values for lme4 models
  "ggdist",     # For raincloud plots
  "broom.mixed"   # Tidy model outputs
)

# Function to install packages if not already installed
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing package:", pkg, "\n")
    install.packages(pkg, dependencies = TRUE)
  } else {
    cat("Package already installed:", pkg, "\n")
  }
}

# Install packages
cat("Checking and installing required packages...\n\n")
sapply(packages, install_if_missing)

# Test loading packages
cat("\n\nTesting package loading...\n")
success <- TRUE
for (pkg in packages) {
  if (!library(pkg, character.only = TRUE, logical.return = TRUE, quietly = TRUE)) {
    cat("ERROR: Failed to load", pkg, "\n")
    success <- FALSE
  }
}

if (success) {
  cat("\n✓ All packages installed and loaded successfully!\n")
  cat("You are ready for the workshop.\n")
} else {
  cat("\n✗ Some packages failed to load. Please check the error messages above.\n")
}
