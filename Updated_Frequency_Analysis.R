################################################################################
# Title: Dam Overtopping Frequency Analysis
# Description:
#   This script performs a frequency analysis on dam water level data using
#   GEV (Generalized Extreme Value) fitting to estimate overtopping probabilities.
#   A rolling window approach is used (30 years), plus a full 50-year window.
#   Outputs include p-values (KS test) and overtopping risk for each window.
#
################################################################################

#-------------------------------------------------------------------------------
# 1. Load required libraries
#-------------------------------------------------------------------------------
library(dplyr)         # Data manipulation
library(tools)         # Tools for R
library(fExtremes)     # Extreme value theory (EVT)
library(ismev)         # Additional EVT (including gev.fit)

#-------------------------------------------------------------------------------
# 2. Set the working directory
#-------------------------------------------------------------------------------
setwd("C:/...")

#-------------------------------------------------------------------------------
# 3. Load Dam information and data
#    - Dam_info.csv: Metadata about each dam (Name, Hazard, Lat, Lon, Agency, etc.)
#    - Dam_data.csv: Water-level time series. Each column = a dam; each row = 
#      a time step (e.g., daily or annual maxima).
#-------------------------------------------------------------------------------
Dam_info <- read.csv("Dam_info.csv")
Dam_data <- read.csv("Dam_data.csv")

# Remove any unwanted first column (e.g., row indices) if necessary
Dam_data <- Dam_data[, -1]

#-------------------------------------------------------------------------------
# 4. Define Variables
#    - method: parameter estimation method (MLE)
#    - prob: a vector of probabilities; used to define exceedance probabilities
#    - step: how many rows to move forward in each rolling window
#    - P_value: storage for KS test results
#    - OverRisk: storage for overtopping probabilities
#    - Pwaterlevel: a 3D array (currently unused) that could store percentile data
#-------------------------------------------------------------------------------
method <- "mle"
prob <- numeric(100)  # Probability vector of length 100
step <- 1             # Rolling window step size

# Empty matrices for results
P_value  <- matrix(0, nrow(Dam_info), ((20 / step) + 2))
OverRisk <- matrix(0, nrow(Dam_info), ((20 / step) + 2))

# Optional array for additional analyses
Pwaterlevel <- array(0, c(nrow(Dam_info), ((20 / step) + 2), 100))

#-------------------------------------------------------------------------------
# 5. Create a probability vector (prob).
#    For example: prob[i] = 1 - 1/(10*i)
#-------------------------------------------------------------------------------
for (i in seq_len(100)) {
  prob[i] <- 1 - (1 / (10 * i))
}

#-------------------------------------------------------------------------------
# 6. Frequency Analysis Loop
#    For each dam (i) across each rolling window (j):
#      - Extract a 30-row subset from Dam_data
#      - Fit a GEV distribution (gev.fit)
#      - Perform a KS test to evaluate goodness-of-fit
#      - Calculate overtopping probability = 1 - F(top)
#-------------------------------------------------------------------------------
for (i in seq_len(ncol(Dam_data))) {
  
  # Temporary data frame to store GEV parameters for each window
  Parm_set <- data.frame(c(0, 0, 0))
  
  # Loop over each rolling window
  for (j in seq_len(((20 / step) + 2))) {
    
    # Identify the 30 rows for this rolling window
    target <- as.numeric(Dam_data[(1 + (j - 1) * step):(30 + (j - 1) * step), i])
    
    # If it's the last iteration, use the full 50 rows
    if (j == ((20 / step) + 2)) {
      target <- as.numeric(Dam_data[1:50, i])
    }
    
    # Top of dam (crest elevation) from Dam_info
    top <- Dam_info$TOPDAM_FT[i]
    
    # GEV fitting
    # The second argument in gev.fit (Dam_data) is unused by the function 
    # but retained here if needed for legacy reasons.
    parm <- try(gev.fit(target, Dam_data, show = FALSE), silent = TRUE)
    if (inherits(parm, "try-error")) next  # Skip if fitting fails
    
    # KS test p-value
    P_value[i, j] <- ks.test(
      target, "pgev",
      xi   = parm$vals[1, 3],  # shape
      mu   = parm$vals[1, 1],  # location
      beta = parm$vals[1, 2]   # scale
    )$p.value
    
    # Overtopping probability = 1 - F(top)
    OverRisk[i, j] <- 1 - pgev(
      top,
      xi   = parm$vals[1, 3],
      mu   = parm$vals[1, 1],
      beta = parm$vals[1, 2]
    )
    
    # Save the fitted parameters
    Parm_set <- data.frame(Parm_set, parm$vals[1, ])
  }
  
  # Remove the initial placeholder column
  Parm_set <- t(Parm_set[, -1])
  
  # (Optional) Write GEV parameters to CSV if needed
  # write.csv(Parm_set, paste0(i, "th_parameter_for_gev.csv"), row.names = FALSE)
}

#-------------------------------------------------------------------------------
# 7. Compute Return Period = 1 / Overtopping Probability
#    Replace infinite values with a large number (1e12).
#-------------------------------------------------------------------------------
Preturn <- round(1 / OverRisk, 3)
Preturn[is.infinite(Preturn)] <- 1e12

#-------------------------------------------------------------------------------
# 8. Convert P_value and OverRisk to data frames
#-------------------------------------------------------------------------------
P_value_df  <- as.data.frame(P_value)
OverRisk_df <- as.data.frame(OverRisk)

#-------------------------------------------------------------------------------
# 9. Combine Dam info and analysis results
#    Adjust Dam_info column indices [1,3,4,5,7] if needed.
#-------------------------------------------------------------------------------
All_result <- data.frame(
  Dam_info[, c(1, 3, 4, 5, 7)],
  P_value_df,
  OverRisk_df
)

# Assign descriptive column names
colnames(All_result) <- c(
  "Name", "Hazard", "Lat", "Lon", "Agency",
  paste0("KS_PValue_W", seq_len(ncol(P_value_df))),
  paste0("OverRisk_W", seq_len(ncol(OverRisk_df)))
)

#-------------------------------------------------------------------------------
# 10. Save the final results
#-------------------------------------------------------------------------------
write.csv(All_result, "Frequency_Analysis_Result.csv", row.names = FALSE)

#-------------------------------------------------------------------------------
# End of Script
#-------------------------------------------------------------------------------
