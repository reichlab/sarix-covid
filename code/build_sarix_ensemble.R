library(dplyr)
library(tidyr)
library(hubEnsembles)
source("code/build_quantile_ensemble.R")


args <- commandArgs(trailingOnly = TRUE)

# The forecast_date is the date of forecast creation.
forecast_date <- args[1]

# Set locations and quantiles
required_quantiles <-
  c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)
required_locations <-
  readr::read_csv(file = "./data/locations.csv") %>%
  dplyr::select("location", "abbreviation")

# load them back in to a single data.frame having columns required by
# build_quantile_ensemble and plot_forecasts
hosps_path <- "weekly-submission/sarix-forecasts/hosps"
models <- list.dirs(
  hosps_path,
  full.names = FALSE,
  recursive = FALSE)

forecast_exists <- purrr::map_lgl(
    models,
    function(model) {
        file.exists(file.path(hosps_path, model, paste0(forecast_date, "-", model, ".csv")))
    })
models <- models[forecast_exists]

all_components <- covidHubUtils::load_forecasts_repo(
  file_path = paste0('weekly-submission/sarix-forecasts/hosps/'),
  models = models,
  forecast_dates = forecast_date,
  locations = NULL,
  types = NULL,
  targets = NULL,
  hub = "US",
  verbose = TRUE
)
all_components <- all_components %>%
    dplyr::filter(grepl("SARIX", model))


# build ensemble via median
sarix_ensemble <- build_quantile_ensemble(
  all_components,
  forecast_date = forecast_date,
  model_name = "sarix"
)

# save ensemble in hub format
target_dir <- 'weekly-submission/sarix-forecasts/UMass-sarix/'
if (!dir.exists(target_dir)) {
    dir.create(target_dir, recursive = TRUE)
}
write.csv(sarix_ensemble %>% dplyr::transmute(
  forecast_date = forecast_date,
  target = paste(horizon, temporal_resolution, "ahead", target_variable),
  target_end_date = target_end_date,
  location = location,
  type = type,
  quantile = quantile,
  value = value),
  file = paste0(target_dir, forecast_date, '-UMass-sarix.csv'),
  row.names = FALSE)

unlink(hosps_path, recursive = TRUE)
