# Experimental Design Brainstorming

Training phase: Retrospective 2025-2026
Testing phase: realtime/prospective 2026-2027?

Inclusion criteria for SMH trajectories
- Full season? 80%?
- 80% of locations?
- All horizons
- Sufficiently different trajectories

SMH trajectories
- Sampling method:
  - use all samples
  - random 20% from each model for each compound task
  - 20% most diverse across all models per compound task
  - 20% most diverse, stratified by model per compound task
  - just models that exhibit good diversity among their trajectories
- Noise injection
- Surveillance: Synthetic proportion
  - 100% surveillance
  - 70% surveillance, 30% synthetic
  - 50% surveillance, 50% synthetic
  - 30% surveillance, 70% synthetic
  - 100% synthetic
- Including subsets of possible seasons
- Projection labeling scheme:
  - single season from multiple sources
  - multiple seasons from single source
  - 10 season "stacks"

GBQR model (or data input) options:
- Include level feats (boolean)
- Bagging set up: num bags, bag frac samples
- Reporting adjustment (boolean)
- Sources [4 surveillance (nssp needs adjustment) + simulated trajectories]
- Fit locations separately (boolean)
- Power transform [only supports forth root or none, could add log]
