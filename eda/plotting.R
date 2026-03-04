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

purrr::walk(1:6, function(i) {
    projections <- paste0("eda/flu_scenario-round", i, "_gz.parquet") |>
        arrow::read_parquet() |>
        dplyr::filter(target == "inc hosp") |>
        dplyr::left_join(locations[1:4])

    target_data <- read.csv(
        "https://raw.githubusercontent.com/midas-network/flu-scenario-modeling-hub/refs/heads/main/auxiliary-data/target-data_archive/time-series_2025-06-30.csv"
    )
    target_data <- target_data |>
        dplyr::left_join(locations[1:4]) |>
        dplyr::filter(!is.na(location_name))

    data_start <- lubridate::ymd(scenario_dates[i])
    data_end <- ifelse(
        i < 4,
        lubridate::ymd("2023-06-03"),
        data_start + 50 * 7L
    )
    target_data_plot <- target_data |>
        dplyr::filter(date >= data_start, date <= data_end)

    unique_locations <- unique(projections$location_name)

    pdf(paste0("eda/round", i, "-plot.pdf"), width = 11, height = 8.5)

    purrr::map(unique_locations, function(loc) {
        p <- projections |>
            dplyr::mutate(
                target_end_date = origin_date + 7 * horizon,
                output_type_id = paste(
                    stringr::str_sub(scenario_id, 1, 1),
                    ifelse(
                        is.na(output_type_id) | output_type_id == "NA",
                        paste0(run_grouping, stochastic_run),
                        output_type_id
                    ),
                    sep = "-"
                )
            ) |>
            dplyr::filter(
                # run_grouping < 50 | output_type_id < 50,
                location_name == loc,
                target == "inc hosp"
            )
        print(head(p))
        print(unique(p$location_name))
        #    })
        if (nrow(p) > 0) {
            ggplot(p) +
                # geom_point(
                #   data = target_data_plot,
                #   aes(x = date, y = observation),
                #   color = "darkgray"
                # ) +
                # geom_line(
                #   data = target_data_plot,
                #   aes(x = date, y = observation),
                #   color = "darkgray"
                # ) +
                geom_line(
                    aes(
                        x = target_end_date,
                        y = value,
                        group = output_type_id,
                        color = scenario_id
                    ),
                    alpha = 0.2
                ) +
                facet_wrap(
                    vars(model_id),
                    ncol = floor(1 + length(unique(p$model_id)) / 3),
                    scales = "free_y"
                ) +
                labs(
                    title = paste0(loc, " incident flu hospitalizations"),
                    x = "Date",
                    y = "incident hospitalizations"
                ) +
                scale_color_brewer(palette = "Set1") +
                theme_bw()
        } else {
            p
        }
    })

    dev.off()
})

#purrr::map(unique_locations, function(loc) {
#    p <- plot_step_ahead_model_output(
#        projections |>
#            dplyr::mutate(target_end_date = origin_date + 7 * horizon) |>
#            dplyr::filter(location_name == loc),
#        target_data |>
#            dplyr::filter(date >= data_start, date <= data_end),
#        intervals = NULL,
#        x_col_name = "target_end_date",
#        x_target_col_name = "date",
#        facet = "model_id",
#        facet_scales = "fixed",
#        facet_nrow = 4,
#        pal_color = "Set3",
#        title = paste0(loc, " incident flu hospitalizations"),
#        interactive = FALSE,
#        show_plot = FALSE
#    )
#    p + ggplot2::theme_bw()
#})

rounds123 <- purrr::map(1:3, function(i) {
    paste0("eda/flu_scenario-round", i, "_gz.parquet") |>
        arrow::read_parquet() |>
        dplyr::filter(target == "inc hosp") |>
        dplyr::left_join(locations[1:4])
}) |>
    purrr::list_rbind()

unique_locations <- unique(rounds123$location_name)

pdf(paste0("eda/rounds123-plot.pdf"), width = 11, height = 8.5)

purrr::map(unique_locations, function(loc) {
    p <- rounds123 |>
        dplyr::mutate(
            target_end_date = origin_date + 7 * horizon,
            output_type_id = paste(
                stringr::str_sub(scenario_id, 1, 1),
                ifelse(
                    is.na(output_type_id) | output_type_id == "NA",
                    paste0(run_grouping, stochastic_run),
                    output_type_id
                ),
                sep = "-"
            )
        ) |>
        dplyr::filter(
            location_name == loc,
            target == "inc hosp"
        )
    print(head(p))
    print(unique(p$location_name))
    #    })
    if (nrow(p) > 0) {
        ggplot(p) +
            # geom_point(
            #   data = target_data_plot,
            #   aes(x = date, y = observation),
            #   color = "darkgray"
            # ) +
            # geom_line(
            #   data = target_data_plot,
            #   aes(x = date, y = observation),
            #   color = "darkgray"
            # ) +
            geom_line(
                aes(
                    x = target_end_date,
                    y = value,
                    group = output_type_id,
                    color = scenario_id
                ),
                alpha = 0.2
            ) +
            facet_grid(
                cols = vars(model_id),
                rows = vars(origin_date),
                scales = "free"
            ) +
            labs(
                title = paste0(loc, " incident flu hospitalizations"),
                x = "Date",
                y = "incident hospitalizations"
            ) +
            scale_color_brewer(palette = "Set1") +
            theme_bw()
    } else {
        p
    }
})

dev.off()
