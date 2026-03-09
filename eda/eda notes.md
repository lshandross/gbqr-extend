Storage could be on GitHub or AWS S3 bucket. Mostly depends on file size. Could be stored as a Miniature Hub, or as individual parquet files for each round.

Either works

```r
# 2012400 rows, 11 columns model output
arrow::write_parquet(round6[[3]], "eda/snappy-0.parquet") # 2.340MB; snappy doesn't support compression level
arrow::write_parquet(round6[[3]], "eda/gzip-0.parquet", compression="gzip") #1.794MB
arrow::write_parquet(round6[[3]], "eda/gzip-9.parquet", compression="gzip", compression_level=9) # 1.794MB
```

Probably just want samples for weekly hospitalizations and ed visit percents for ages 0-130

- Round 1 (2022-08-14 to 2023-06-03)
  - Columns (11): model projection date, scenario name, scenario id, target, target end date, location, age group, type, quantile, sample, value
  - 4 scenarios, 6 targets (2 deaths are US only, cumulative + peak are not for samples), 3 output types (quantile, point, optional sample), 5 main age groups (or aggregation of any); up to 100 trajectories
- Round 2 (2022-11-13 to 2023-06-03) is similar to 1, but has different scenarios; up to 100 trajectories
- Round 3 (2022-12-04 to 2023-06-03) is "a direct update of Round 2 with 3 extra weeks of data"; up to 100 trajectories
- Round 4 (2023-09-03 to 2024-06-01)
- Columns (9): Origin date, scenario id, target, horizon, location, age group, output type, output type id, value
- 6 scenarios, 2 main targets (weekly incident hospitalizations and deaths for samples) + 6 more for quantile and cdf, 3 output types, 1 main age group (0-130) + 5 optional; up to 100 trajectories
- Round 5 (2024-08-11 to 2025-06-07) is similar to 4 but has the extra columns of 6; 100 to 300 trajectories
- Round 6 (2025-08-10 to 2026-06-06)
  - Columns (11): Origin date, scenario id, target, horizon, location, age group, output type, output type id, value, run grouping, stochastic run
  - 3 scenarios, 2 main targets (weekly incident hospitalizations, initial proportion of susceptible individuals at simulation start for samples) + 7 more, 3 output types, 1 main age group (0-130) + 5 optional; at least 300 trajectories
  - Compound task id set (per target): Origin date, location

Investigate how much of the season is covered by projections, how many models (total, per each round), similarity of projections within and across rounds, what targets are available for each round
- Rounds 1, 4-6 are full seasons (August/September - June)
- Models vary by round, not all submit all locations
- Only hospitalization target available as samples is incident hospitalizations (weekly)


All data is transformed to have the same 9 columns: Origin date, scenario id, target, horizon, location, age group, output type, output type id, value

Plot round 5 data against 2024-2025 season data (could consider more rounds) by writing new function based on ID data loader functions for each source, then perform transforms in load_data()