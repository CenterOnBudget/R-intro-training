# Load packages ----------------------------------------------------------------


# These packages include additional functions we'll use today

library(tidyverse)
library(readxl)
library(writexl)


# Retrieve data ----------------------------------------------------------------


# Use `download.file` function to retrieve data

# This is especially useful when retrieving a lot of data files on a
# recurring basis. For this size project, it is not as important.

# We can check the arguments of `download.file` by running `?download.file`

download.file(
  url = "https://shef.sheeo.org/wp-content/uploads/2020/04/SHEEO_SHEF_FY19_Report_Data.xlsx",
  destfile = "data-raw/sheeo_shef_fy19_data.xlsx"
)

download.file(
  url = "https://www.bls.gov/cpi/research-series/allitems.xlsx",
  destfile = "data-raw/bls_cpi_u_rs.xlsx"
)


# Import data ------------------------------------------------------------------


# Use `read_excel` function to import SHEEO data from spreadsheet
# Store results of `read_excel` in an object named `sheeo_raw`

sheeo_raw <- read_excel(
  path = "data-raw/sheeo_shef_fy19_data.xlsx",
  sheet = 2,
  col_names = TRUE # This is a default argument
)

# Use `view` function to browse SHEEO data

# view(sheeo_raw)


# Use same approach to import BLS data
# Note that we can take advantage of positional and default arguments

bls_raw <- read_excel("data-raw/bls_cpi_u_rs.xlsx", skip = 5)


# Clean data -------------------------------------------------------------------


# Use `names` and `select` functions to clean SHEEO data

names(sheeo_raw)

sheeo_clean <- select(
  sheeo_raw,
  state = State,
  year = FY,
  support = `Total State Support`,
  fte = `Net FTE Enrollment`
)


# Use same approach to clean BLS data

bls_clean <- select(bls_raw, year = YEAR, cpi_u_rs = AVG)


# How do we get the value of the CPI-U-RS for 2019?
# To do this, we will explore some base R syntax

bls_clean$cpi_u_rs     # Select a column by name with `$`
bls_clean$cpi_u_rs[43] # Select element(s) by position with `[ ]`

bls_clean$year
bls_clean$year == 2019 # Apply logical test to year column

bls_clean$cpi_u_rs[bls_clean$year == 2019] # Select element(s) with logical vector

cpi_u_rs_2019 <- bls_clean$cpi_u_rs[bls_clean$year == 2019]


# Use `mutate` function to create inflation adjustment for 2019

bls_clean <- mutate(bls_clean, cpi_u_rs_2019_adj = cpi_u_rs_2019 / cpi_u_rs)


# Merge data -------------------------------------------------------------------


# Use `left_join` function to merge data

clean_data <- left_join(sheeo_clean, bls_clean, by = "year")

# A power of using R (and tidyverse functions) is the ability to merge on more
# than one ID (e.g., by year, state, and county). We don't need that power today,
# but it is worth keeping in mind!


# Verify data ------------------------------------------------------------------


# Use `count` function to check number of years of data per state

count(clean_data, state)
print(count(clean_data, state), n = Inf) # Consistent with SHEEO README


# Sneak-peek at more advanced tools:
# Use pipe, `filter`, `summarize`, and friends to check US totals

clean_data %>%
  filter(state == "U.S.") %>%
  select(1:3)

clean_data %>%
  filter(state != "U.S.") %>%
  # filter(!(state %in% c("U.S.", "District of Columbia"))) %>%
  group_by(year) %>%
  summarize(support = sum(support)) %>%
  arrange(-year)


# Analyze data -----------------------------------------------------------------


# Use `mutate` to calculate real state support per FTE

analysis_data <- mutate(
  clean_data,
  real_support = support * cpi_u_rs_2019_adj,
  real_support_fte = real_support / fte
)


# Use `pivot_wider` and pipes to create a table

real_support_fte_table <- analysis_data %>%
  arrange(year) %>%
  filter(year %in% c(2008:2019) & state != "District of Columbia") %>%
  select(state, year, real_support_fte) %>%
  pivot_wider(names_from = year, values_from = real_support_fte) %>%
  mutate(change = `2019` - `2008`)

print(real_support_fte_table, n = Inf)


# Export data ------------------------------------------------------------------


write_csv(analysis_data, "data/higher_ed_data.csv")
write_xlsx(real_support_fte_table, "results/real_support_fte_table.xlsx")


# End of script ----------------------------------------------------------------
