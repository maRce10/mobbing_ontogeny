# Mobbing behavior in tropical passerine birds: an innate and learned behavior

[![Website](https://img.shields.io/badge/website-analysis%20reports-408AB4)](https://marce10.github.io/mobbing_ontogeny/)
[![DOI](https://zenodo.org/badge/743732923.svg)](https://doi.org/10.5281/zenodo.24247609)
[![Publish website](https://github.com/maRce10/mobbing_ontogeny/actions/workflows/publish.yml/badge.svg)](https://github.com/maRce10/mobbing_ontogeny/actions/workflows/publish.yml)

Code and data to reproduce the analyses and figures of:

> Sánchez N. V., Cataudela J. F., González M., Martínez-Penados A., Rodríguez-García E., Salas-Murillo D., Araya-Salas M. *Mobbing behavior in tropical passerine birds: an innate and learned behavior.* (under review)

We broadcast calls of three pygmy-owls that differ in their familiarity to the local bird community at Las Cruces Biological Station, Costa Rica (*Glaucidium costaricanum*, sympatric; *G. brasilianum*, allopatric with range overlap elsewhere; *G. passerinum*, strictly allopatric) and the song of a non-predatory warbler (*Basileuterus delattrii*, control), and counted the birds and species that responded in 49 playback trials at 31 sites (2024 and 2026).

## Website

The rendered analysis reports, with all code, results and figures, are available at **[marce10.github.io/mobbing_ontogeny](https://marce10.github.io/mobbing_ontogeny/)**:

- [Statistical analysis](https://marce10.github.io/mobbing_ontogeny/scripts/1_statistical_analysis.html): Bayesian mixed models, model checking, prior sensitivity and pairwise contrasts (Tables 1–2, Figs. 3–4, Supplementary material Tables S2–S14 and Figs. S1–S4)
- [Supplementary material](https://marce10.github.io/mobbing_ontogeny/scripts/2_supplementary_materials.html): the manuscript's Supplementary material (Tables S1–S14, Figs. S1–S4)

## Repository structure

```
_quarto.yml, index.qmd, styles.css        Quarto website configuration (cached code results in _freeze/)
_figure-download.html                     Adds a download button below each figure
.github/workflows/publish.yml             GitHub Actions workflow that builds the website and deploys it to GitHub Pages
scripts/
  1_statistical_analysis.qmd              Main analysis (models, diagnostics, contrasts, figures)
  2_supplementary_materials.qmd           Supplementary material (website page)
  reviewer_reanalysis.R                   Stand-alone script version of the main models
  supplementary_reanalysis.R              Builds manuscript/Supplementary_material.docx
data/
  raw/data_v2.csv                         One row per playback trial (date, team, time, point, stimulus, responding birds and species, notes)
  raw/responsive_taxa.csv                 Responsive taxa and number of individuals per stimulus (Table S1)
  processed/models/                       Cached brms models (not on GitHub; refitted by the analysis report)
output/
  figures/                                Figures used on the website (300 dpi)
  reanalysis/                             Contrast tables, trace plots and posterior predictive checks
```

## Rebuilding the website

Render locally with `quarto render` (code results are cached in `_freeze/`), then commit `_freeze/`. Pushing to `master` triggers the workflow, which renders the site from the cached results and deploys it to GitHub Pages.

## How to cite

> Sánchez N. V., Cataudela J. F., González M., Martínez-Penados A., Rodríguez-García E., Salas-Murillo D., Araya-Salas M. (2026). Code and data for "Mobbing behavior in tropical passerine birds: an innate and learned behavior". Zenodo. https://doi.org/10.5281/zenodo.24247609

## License

Code: GPL (>= 2) ([`LICENSE`](LICENSE)). Data: CC BY 4.0. See [`ATTRIBUTION.md`](ATTRIBUTION.md) for details, and [`CITATION.cff`](CITATION.cff) for how to cite.

## Contact

Marcelo Araya-Salas (marcelo.araya@ucr.ac.cr)
