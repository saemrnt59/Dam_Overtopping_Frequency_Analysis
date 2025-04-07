# Dam Overtopping Frequency Analysis

This repository contains an R script and supporting data for analyzing **dam water level** data to estimate **overtopping probabilities** using a **Generalized Extreme Value (GEV)** framework. The analysis helps identify potential risks of dam overtopping over rolling windows of time.

---

## Contents

1. **R Script**  
   - `Dam_Overtopping_Frequency_Analysis.R`  
     - Performs GEV fitting on 30-year rolling windows (and a final 50-year period) to calculate the probability of water levels exceeding each dam’s crest.  
     - Uses the `ismev` and `fExtremes` packages for extreme value fitting.

2. **Data**  
   - `Dam_info.csv`: Sample metadata for each dam, such as  
     - **Name**  
     - **Latitude/Longitude**  
     - **Dam crest elevation** (TOPDAM_FT)  
   - `Dam_data.csv`: Sample Time series of water levels for each dam.  
     - Each column = one dam  
     - Each row = a time step (e.g., an annual maximum water level)

3. **Output Example**  
   - `Frequency_Analysis_Result.csv`:  
     - Columns include the dam’s **Name**, **Hazard**, **Lat**, **Lon**, **Agency**, followed by:  
       - `KS_PValue_W1, KS_PValue_W2, ...` (p-values from the Kolmogorov-Smirnov test for each window)  
       - `OverRisk_W1, OverRisk_W2, ...` (overtopping probabilities—i.e., *1 – GEV CDF(crest height)*—for each window)

---
