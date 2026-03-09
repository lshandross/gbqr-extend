library(hubData)
library(hubVis)
library(fs)
library(readr)
library(lubridate)
library(ggplot2)

locations <- read.csv(
    "https://raw.githubusercontent.com/cdcepi/FluSight-forecast-hub/refs/heads/main/auxiliary-data/locations.csv"
)
scenario_dates <- c(
    "2022-08-14",
    "2022-11-13",
    "2022-12-04",
    "2023-09-03",
    "2024-08-11",
    "2025-08-10"
)

round5 <- paste0("eda/flu_scenario-round", i, "_gz.parquet") |>
    arrow::read_parquet() #|>
model_out <- round5 |>
    dplyr::filter(
        target == "inc hosp",
        age_group == "0-130",
#        as.numeric(output_type_id) == 11 |
        as.numeric(output_type_id) < 125,
        model_id %in% c("MOBS_NEU-GLEAM_FLU", "NIH-Flu_TS")
    ) |>
#    dplyr::group_by(model_id, scenario_id, location, output_type_id) |>
#    dplyr::slice_sample(n = 2) |>
#    dplyr::ungroup() |>
    dplyr::mutate(
        date = origin_date + 7 * horizon,
        output_type_id = paste(
            model_id,
            location,
            stringr::str_sub(scenario_id, 1, 1),
            ifelse(
                is.na(output_type_id) | output_type_id == "NA",
                paste0(run_grouping, stochastic_run),
                output_type_id
            ),
            sep = "-"
        ),
        source = "source_a"
    ) |>
#    dplyr::group_by(model_id, scenario_id, location) |>
#    dplyr::slice_sample(n = 10) |>
#    dplyr::ungroup() |>
    dplyr::rename(observation = value) |>
    dplyr::left_join(locations[1:4]) |>
    select(
        date,
        location,
        observation,
        location_name,
        population,
        source,
        output_type_id
    )

surveillance <- read.csv(
    "https://raw.githubusercontent.com/midas-network/flu-scenario-modeling-hub/refs/heads/main/auxiliary-data/target-data_archive/time-series_2025-06-30.csv"
) |>
    dplyr::left_join(locations[1:4]) |>
    dplyr::filter(
        target == "inc hosp",
        age_group == "0-130",
        !is.na(location_name)
    ) |>
    dplyr::mutate(
        date = as.Date(date),
        output_type_id = paste(location),
        source = "source_b"
    ) |>
    select(
        date,
        location,
        observation,
        location_name,
        population,
        source,
        output_type_id
    )

data_start <- lubridate::ymd(scenario_dates[i])
data_end <- ifelse(
    i < 4,
    lubridate::ymd("2023-06-03"),
    data_start + 50 * 7L
)
surveillance <- surveillance |>
    dplyr::filter(date >= data_start, date <= data_end)

pdf(
    paste0("eda/model-out-vs-surveillance_round", i, "-plot.pdf"),
    width = 11,
    height = 8.5
)

p <- rbind(model_out, surveillance) |>
    dplyr::mutate(
        epiweek = lubridate::epiweek(date),
        season_week = ifelse(epiweek > 30, epiweek - 30, epiweek - 30 + 52),
        observation = observation + 0.75^4,
        inc_trans = (observation + 0.01)^0.25,
        inc_trans_in_season = ifelse(
            (season_week < 10 | season_week > 45),
            NA,
            inc_trans
        )
    ) |>
    dplyr::filter(location != "US", season_week > 14)
p <- p |>
    dplyr::group_by(source, location) |>
    dplyr::summarize(
        inc_trans_scale_factor = quantile(
            inc_trans_in_season,
            0.95,
            na.rm = TRUE
        )
    ) |>
    dplyr::right_join(p) |>
    dplyr::ungroup() |>
    dplyr::mutate(
        inc_trans_cs = inc_trans / (inc_trans_scale_factor + 0.01),
        inc_trans_cs_in_season = ifelse(
            (season_week < 10 | season_week > 45),
            NA,
            inc_trans_cs
        )
    )
p <- p |>
    dplyr::group_by(source, location) |>
    dplyr::summarize(
        inc_trans_center_factor = mean(inc_trans_cs_in_season, na.rm = TRUE)
    ) |>
    dplyr::right_join(p) |>
    dplyr::ungroup() |>
    dplyr::mutate(inc_trans_cs = inc_trans_cs - inc_trans_center_factor) |>
    select(source, location, date, season_week, location_name, population, observation, inc_trans_cs, output_type_id)

ggplot(p) +
    geom_line(
        aes(
            x = season_week,
            y = inc_trans_cs,
            group = output_type_id,
            color = log(population)
        ),
        alpha = 0.2
    ) +
    facet_wrap(
        vars(source),
        ncol = 1,
        scales = "fixed"
    ) +
    labs(
        title = paste0("round", i, " incident flu hospitalizations"),
        x = "Date",
        y = "incident hospitalizations"
    ) +
    theme_bw()

dev.off()
