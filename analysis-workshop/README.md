# Analysis Workshop: Linear Mixed Models with R

This repository contains materials for an introductory workshop on Linear Mixed Models (LMMs) using R.

## Contents

- `lmm_presentation.qmd` - Quarto presentation introducing LMMs with eye-tracking data
- `download_data.R` - Function to download datasets from Google Drive
- `data/` - Eye-tracking datasets for the workshop (automatically downloaded)
  - `Hindi_new.csv` - Hindi reading time data with factorial design (word type × frequency)
  - `RASTROS_sample.csv` - Portuguese reading data with continuous word frequency predictor

## Requirements

To run this presentation, you'll need:

- R (>= 4.0.0)
- Quarto
- Required R packages:
  - tidyverse
  - lme4
  - lmerTest
  - ggdist
  - broom.mixed
 
The easiest way to run this workshop is by using GitHub Codespaces. Alternatively, you can install the software and the packages on your own computer (see below).

## Option 1: Running in GitHub Codespaces

The repository includes a devcontainer image that provides RStudio Server. You can run the workshop entirely in GitHub Codespaces and use a full RStudio session in your browser. Please note that you need to be logged into GitHub for this to work.

### Start a Codespace

1. Open the repository page: https://github.com/bernhardangele/analysis-workshop-lacem-2025 (if you are reading this, you may be already on it).
2. Click the green `Code` button.
3. Select the `Codespaces` tab.
4. Click `Create codespace on main`.
5. Wait for the container to build and initialize (first start may take a few minutes).

### Open RStudio in your Codespace

Once the Codespace is running:

- Look for the `Ports` panel (bottom or left sidebar in the web VS Code editor). A port labeled `RStudio` (usually 8787) should appear when the container finishes starting.
- Click the `Open in Browser` 🌐 icon for the `RStudio` port to launch RStudio Server.

If you don’t see the port immediately:

- Open the Command Palette (Ctrl/Cmd + Shift + P) and run `Ports: Focus on Ports View`.
- Alternatively, wait a few minutes for the service to start; the port will be auto-forwarded once RStudio is ready.
- You will see the number of active ports next to the "Ports" tab once RStudio is ready.

Notes:

- RStudio will open directly in your browser. The login and password are both "rstudio". This is safe since this codespace can only be accessed from your GitHub account.
- Use the `Files` pane in RStudio to navigate the repo. Go to `projects`, `analysis-workshop-lacem-2025` and open the `analysis-workshop-lacem.Rproj` to load the project. Then open the `lmm-presentation.qmd` file. You can click `Render` to build the presentation.
- You can still use the VS Code terminal and editor alongside RStudio (but it should not be necessary).
- Every GitHub account has a limited number of minutes of codespace usage every month (120 for free accounts and 180 for Github Education accounts). If you run out of minutes, the codespace will terminate. However, it is unlikely that you will reach this limit during the workshop. You can check your usage in your GitHub account settings under "Billing".
- Note that, in order to minimize your usage, the Codespace will stop automatically if it is idle for more than 30 minutes. In this case, RStudio will stop working. You can restart the codespace from the `Code` button or from https://github.com/codespaces


## Option 2: Installation

- This is more flexible, but requires you to have R and RStudio installed on your computer. Download the data from the repository to a new folder on your computer. You can do this by running `git clone git@github.com:bernhardangele/analysis-workshop-lacem-2025.git` in the command line/terminal if you have git installed, or use the `Code` button on the repository page, click `Local`, and download the code as a ZIP file which you can then extract in a folder of your choice.
- Open RStudio. Use the `Files` pane in RStudio to navigate to the folder where you have downloaded the files. Open the `analysis-workshop-lacem.Rproj` to load the project. Then open the `lmm-presentation.qmd` file. You can click `Render` to build the presentation.

### Downloading Data Files

The presentation automatically downloads required data files from Google Drive when you run it. The data files are:
- `Hindi_new.csv` - Downloaded from Google Drive
- `RASTROS_sample.csv` - Downloaded from Google Drive

The download function checks if files already exist and only downloads them if they're not present. To manually download the data files, you can run:

```r
source("download_data.R")
download_workshop_data()
```

To force re-download even if files exist:

```r
download_workshop_data(force_download = TRUE)
```

### Install R packages

```r
install.packages(c("tidyverse", "lme4", "lmerTest", "ggdist", "broom.mixed"))
```

### Install Quarto

Download and install Quarto from [https://quarto.org/docs/get-started/](https://quarto.org/docs/get-started/)

## Rendering the Presentation

To render the presentation to HTML (RevealJS):

```bash
quarto render lmm_presentation.qmd
```

To preview the presentation:

```bash
quarto preview lmm_presentation.qmd
```

## Workshop Overview

The presentation covers:

1. **Data Reading and Exploration**
   - Loading eye-tracking data with tidyverse's `read_csv()`
   - Descriptive statistics
   - Raincloud plots using ggplot2 and ggdist

2. **Hindi Data - Factorial Design**
   - Setting up two-factor design (word type × frequency)
   - Sum contrasts coding
   - Fitting LMMs with interactions
   - Interpreting factorial effects

3. **RASTROS Data - Continuous Predictors**
   - Fitting LMMs with continuous predictors (word frequency)
   - Interpreting slopes
   - Visualizing relationships

4. **Advanced Considerations**
   - Random slopes vs. random intercepts
   - Power considerations (Brysbaert & Stevens, 2018)
   - Multiple comparisons issues
     
## Data Description

### Hindi Data (Hindi_new.csv)

Eye-tracking data from Hindi reading with factorial design:

- **RECORDING_SESSION_LABEL**: Participant ID
- **cond_name**: Condition code (RL, RH, TL, TH)
  - RL = Romance Low Frequency
  - RH = Romance High Frequency
  - TL = Traditional Low Frequency
  - TH = Traditional High Frequency
- **IA_FIRST_FIXATION_DURATION**: First fixation duration (ms)
- **IA_DWELL_TIME**: Total dwell time (ms)
- Other eye-tracking measures

### RASTROS Data (RASTROS_sample.csv)

Portuguese reading data with word-level predictors:

- **RECORDING_SESSION_LABEL**: Participant ID
- **IA_FIRST_FIXATION_DURATION**: First fixation duration (ms)
- **Freq_Brasileiro_log**: Log word frequency in Brazilian Portuguese
- **Word_Length**: Number of characters
- **Content_or_Function**: Word class
- Other eye-tracking and linguistic measures

## License

This material is provided for educational purposes.
