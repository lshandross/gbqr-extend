# Lines 2-84 from Lucie Contamin, Scenario Modeling Hub
library(dplyr)

# read file function
read_files <- function(path, sep = ",", nastrings = c("", "NA", "NaN")) {
    if (grepl(".csv$", basename(path))) {
        df <- read.csv(path, sep = sep, na.strings = nastrings)
    }
    if (grepl(".zip$", basename(path))) {
        file_name <- unzip(path, list = TRUE)[, "Name", TRUE]
        unzip(path)
        df <- read.csv(file_name[1], sep = sep, na.strings = nastrings)
        file.remove(file_name)
    }
    if (grepl(".gz$", basename(path))) {
        file_name <- gzfile(path)
        df <- read.csv(file_name, sep = sep, na.strings = nastrings)
    }
    if (grepl(".pqt$|.parquet$", basename(path))) {
        df <- arrow::read_parquet(path, as_data_frame = TRUE)
    }
    if (grepl(".rds$", basename(path))) {
        df <- readRDS(path)
    }
    if (any("location" %in% names(df))) {
        df$location <- as.character(df$location)
    }
    if (any("quantile" %in% names(df))) {
        df$quantile <- round(df$quantile, 3)
    }
    df
}

# List of GITHUB repo name to clone: just as a warning the COVID ones are quite
# big

repo_list <- list(
    #   "covid_research" = "midas-network/covid19-smh-research",
    #   "covid_op_ar" =  "midas-network/covid19-scenario-modeling-hub_archive",
    #   "covid_op" = "midas-network/covid19-scenario-modeling-hub",
    "flu_op_ar" = "midas-network/flu-scenario-modeling-hub_archive",
    "flu_op" = "midas-network/flu-scenario-modeling-hub"
    #   "rsv" = "midas-network/rsv-scenario-modeling-hub"
)

# Once cloned:
## Submissions + Ensembles local folder path (you might need to update it)
hub_dir <- c(
    #   "./covid19-scenario-modeling-hub_archive/data-processed/",
    #    "./covid19-scenario-modeling-hub/model-output/",
    #    "./covid19-smh-research/model-output/",
    "../flu-scenario-modeling-hub_archive/data-processed/",
    "../flu-scenario-modeling-hub/model-output/"
    #    "./rsv/rsv-scenario-modeling-hub/model-output/"
)

files_info <- lapply(hub_dir, function(hd) {
    sub_files <-
        grep(
            "metadata|(a|A)bstract|README|/MyTeam-MyModel|team.-model.|Licen(c|s)",
            dir(hd, full.names = TRUE, recursive = TRUE),
            value = TRUE,
            invert = TRUE,
            ignore.case = TRUE
        )
    files <- lapply(sub_files, function(sfile) {
        filename <- basename(sfile)
        df <- read_files(sfile)
        return(df)
    })
    files
})


# files_paths <- lapply(hub_dir, function(hd) {
#     grep(
#         "metadata|(a|A)bstract|README|/MyTeam-MyModel|team.-model.|Licen(c|s)",
#         dir(hd, full.names = TRUE, recursive = TRUE),
#         value = TRUE,
#         invert = TRUE,
#         ignore.case = TRUE
#     )
# }) |>
#     unlist(use.names = FALSE)

file_paths <-
    grep(
        "metadata|(a|A)bstract|README|/MyTeam-MyModel|team.-model.|Licen(c|s)",
        dir(hub_dir[1], full.names = TRUE, recursive = TRUE),
        value = TRUE,
        invert = TRUE,
        ignore.case = TRUE
    )
scenario_dates <- c(
    "2022-08-14",
    "2022-11-13",
    "2022-12-04",
    "2023-09-03",
    "2024-08-11" #,
    #    "2025-08-10"
)
purrr::iwalk(scenario_dates, function(.x, .y) {
    temp <- purrr::map(file_paths, function(fp) {
        if (stringr::str_detect(fp, .x)) {
            df <- read_files(fp) |>
                dplyr::mutate(
                    model_id = stringr::str_extract(
                        fp,
                        "(?<=processed/)[^.]+(?=/20)"
                    ),
                    .before = 1
                )
            if (.x %in% scenario_dates[1:3]) {
                ot <- colnames(df)[7]
                df <- df |>
                    tidyr::separate(
                        col = target,
                        into = c("horizon", "target"),
                        sep = " wk ahead ",
                        convert = FALSE
                    ) |>
                    dplyr::mutate(
                        origin_date = as.Date(model_projection_date),
                        output_type = ot,
                        output_type_id = as.character(.data[[ot]])
                    )
            } else if (.x %in% scenario_dates[4:5]) {
                df <- df |>
                    dplyr::mutate(
                        origin_date = as.Date(origin_date),
                        output_type_id = paste(
                            stringr::str_sub(scenario_id, 1, 1),
                            ifelse(
                                is.na(output_type_id) | output_type_id == "NA",
                                paste0(run_grouping, stochastic_run),
                                output_type_id
                            ),
                            sep = "-"
                        ),
                        .before = "origin_date"
                    )
            }
            df <- df |>
                dplyr::filter(
                    output_type == "sample",
                    target != "S0",
                    age_group == "0-130"
                ) |>
                dplyr::mutate(horizon = as.numeric(horizon)) |>
                dplyr::select(
                    "model_id",
                    "origin_date",
                    "scenario_id",
                    "target",
                    "horizon",
                    "location",
                    "age_group",
                    "output_type",
                    "output_type_id",
                    "value"
                )
        }
    }) |>
        purrr::list_rbind()
    arrow::write_parquet(
        temp,
        paste0("eda/flu_scenario-round", .y, "_gz.parquet"),
        compression = "gzip"
    )
})

file_paths <-
    grep(
        "metadata|(a|A)bstract|README|/MyTeam-MyModel|team.-model.|Licen(c|s)",
        dir(hub_dir[2], full.names = TRUE, recursive = TRUE),
        value = TRUE,
        invert = TRUE,
        ignore.case = TRUE
    )
round6 <- purrr::map(file_paths, function(fp) {
    df <- read_files(fp) |>
        dplyr::mutate(
            model_id = stringr::str_extract(
                fp,
                "(?<=output/)[^.]+(?=/20)"
            ),
            origin_date = as.Date(origin_date),
            #            id = output_type_id,
            output_type_id = paste(
                ifelse(
                    is.na(output_type_id) | output_type_id == "NA",
                    paste0(run_grouping, stochastic_run),
                    output_type_id
                ),
                sep = "-"
            ),
            .before = "origin_date"
        ) |>
        dplyr::filter(
            output_type == "sample",
            target != "S0",
            age_group == "0-130"
        ) |>
        dplyr::select(
            "model_id",
            "origin_date",
            "scenario_id",
            "target",
            "horizon",
            "location",
            "age_group",
            "output_type",
            "output_type_id",
            "id",
            "value"
        )
    #    if (length(colnames(df)) <= 9) {
    #        df <- dplyr::mutate(
    #            df,
    #            run_grouping = NA,
    #            stochastic_run = as.numeric(output_type_id)
    #        )
    #    }
    return(df)
}) |>
    purrr::list_rbind()

arrow::write_parquet(
    round6,
    "eda/flu_scenario-round6_gz.parquet",
    compression = "gzip"
)
