# Builds the single Supplementary material (markdown -> docx):
# Table S1 responsive taxa, Table S2 design, Tables S3-S6 parameter estimates,
# Tables S7-S14 contrasts (prior sensitivity, negative binomial), Figs. S1-S4 diagnostics
# Run from project root: Rscript scripts/supplementary_reanalysis.R
suppressPackageStartupMessages(library(brms))
o <- "output/reanalysis"; m <- "data/processed/models"
d <- read.csv("data/raw/data_v2.csv", check.names = FALSE); names(d) <- trimws(names(d))
d$year <- substr(d$FECHA, 7, 10)
lab <- c(GLCR = "Sympatric (*G. costaricanum*)", GLBR = "Allopatric (*G. brasilianum*)",
         GLEU = "Allopatric+ (*G. passerinum*)", BADE = "Control (*B. delattrii*)")
nm <- c(INDIVIDUOS = "number of responding birds", MORFOESPECIE = "number of responding species and morphospecies")

L <- c("# Supplementary material", "",
  "Mobbing responses of tropical passerines to sympatric and allopatric owl vocalizations.", "")

# Table S1: responsive taxa (from the field records; previously at the end of the manuscript)
s1 <- read.csv("data/raw/responsive_taxa.csv", check.names = FALSE)
L <- c(L, "**Table S1.** Bird taxa exhibiting mobbing responses to playback of owl calls and control at Las Cruces Biological Station, San Vito, Costa Rica. Responsive taxa are confirmed species or morphospecies grouped by family.", "",
  "| Stimulus species | Family | Scientific / common name | N° of individuals |", "|---|---|---|---|",
  sprintf("| %s | %s | %s | %s |", s1$stimulus, s1$family, s1$taxon, s1$n), "")

# Table S2: design
L <- c(L, "**Table S2.** Number of playback trials per stimulus, year and exemplar (recording of a different individual). All 2024 trials used exemplar 1.", "",
  "| Stimulus | 2024 (exemplar 1) | 2026 (exemplar 2) | 2026 (exemplar 3) | Total |", "|---|---|---|---|---|")
for (s in names(lab)) { n24 <- sum(d$ESTIMULO == s & d$year == "2024"); n26 <- sum(d$ESTIMULO == s & d$year == "2026")
  L <- c(L, sprintf("| %s | %d | %d | %d | %d |", lab[s], n24, n26/2, n26/2, n24 + n26)) }
team <- ifelse(d$EQUIPO == 3, 2, d$EQUIPO); sn <- table(table(paste0("T", team, "_P", d$PUNTO)))
L <- c(L, "", sprintf("Sites received one (%d sites), two (%d sites) or four (%d sites) trials, always on different days (%d trials at %d sites).",
  sn[["1"]], sn[["2"]], sn[["4"]], nrow(d), sum(sn)), "")

fx <- function(f) { s <- summary(readRDS(f)); r <- rbind(s$fixed, s$random$site); r <- round(r[, c(1, 3, 4, 5, 6, 7)], 3)
  rownames(r)[rownames(r) == "Intercept1"] <- "sd(Intercept)"
  c("| Parameter | Estimate | l-95% CrI | u-95% CrI | R-hat | Bulk ESS | Tail ESS |", "|---|---|---|---|---|---|---|",
    sprintf("| %s | %.3f | %.3f | %.3f | %.3f | %.0f | %.0f |", rownames(r), r[,1], r[,2], r[,3], r[,4], r[,5], r[,6])) }
ct <- function(f) { x <- read.csv(f); x$contrast <- gsub("\\((Allopatric\\+)\\)", "\\1", x$contrast); cr <- sign(x$lower.HPD) == sign(x$upper.HPD)
  lb <- ifelse(cr, paste0("**", x$contrast, "**"), x$contrast)
  c("| Contrast | Estimate | 95% HPD lower | 95% HPD upper |", "|---|---|---|---|",
    sprintf("| %s | %.3f | %.3f | %.3f |", lb, x$estimate, x$lower.HPD, x$upper.HPD)) }

# Tables S3-S6: parameter estimates
k <- 3
fams <- c(pois = "Poisson", nb = "negative binomial")
for (r in names(nm)) for (fm in names(fams)) {
  L <- c(L, sprintf("**Table S%d.** Parameter estimates of the %s model of the %s (stimulus and year as fixed effects, site as random intercept; reference levels: sympatric stimulus, 2024).", k, fams[[fm]], nm[r]), "",
         fx(file.path(m, sprintf("%s_%s.rds", r, fm))), ""); k <- k + 1 }

# Tables S7-S14: contrasts
for (r in names(nm)) for (p in list(c("pois_prior2", "Poisson model, normal(0, 2) priors"), c("pois", "Poisson model, normal(0, 6) priors (main text)"),
                                    c("pois_prior10", "Poisson model, normal(0, 10) priors"), c("nb", "negative binomial model, normal(0, 6) priors"))) {
  L <- c(L, sprintf("**Table S%d.** Pairwise contrasts (log scale) for the %s: %s. Contrasts whose 95%% HPD interval excludes zero are in bold.", k, nm[r], p[2]), "",
         ct(file.path(o, sprintf("contrasts_%s_%s.csv", r, p[1]))), ""); k <- k + 1 }

# Figures S1-S4
L <- c(L,
  "![**Figure S1.** Trace plots of the Poisson model of the number of responding birds.](trace_INDIVIDUOS_pois.png){width=6in}", "",
  "![**Figure S2.** Trace plots of the Poisson model of the number of responding species.](trace_MORFOESPECIE_pois.png){width=6in}", "",
  "![**Figure S3.** Posterior predictive checks (observed vs. 500 simulated count distributions) for the number of responding birds.](ppc_INDIVIDUOS.png){width=6in}", "",
  "![**Figure S4.** Posterior predictive checks for the number of responding species.](ppc_MORFOESPECIE.png){width=6in}", "")
writeLines(L, file.path(o, "supplementary_material.md"))
system("pandoc output/reanalysis/supplementary_material.md --resource-path=output/reanalysis -o manuscript/Supplementary_material.docx")
system("python3 scripts/fix_docx_tables.py manuscript/Supplementary_material.docx")
