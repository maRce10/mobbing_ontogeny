# Builds Supplementary materials 2-4 (markdown -> docx) from the reviewer re-analysis
suppressPackageStartupMessages(library(brms))
o <- "output/reanalysis"; m <- "data/processed/models"
d <- read.csv("data/raw/data_v2.csv", check.names = FALSE); names(d) <- trimws(names(d))
d$year <- substr(d$FECHA, 7, 10)
lab <- c(GLCR = "Sympatric (G. costaricanum)", GLBR = "Allopatric (G. brasilianum)", GLEU = "Allopatric+ (G. passerinum)", BADE = "Control (B. delattrii)")
L <- c("# Supplementary material 2", "",
  "Number of playback trials per stimulus, year and exemplar (recording of a different individual). All 2024 trials used exemplar 1.", "",
  "| Stimulus | 2024 (exemplar 1) | 2026 (exemplar 2) | 2026 (exemplar 3) | Total |", "|---|---|---|---|---|")
for (s in names(lab)) { n24 <- sum(d$ESTIMULO == s & d$year == "2024"); n26 <- sum(d$ESTIMULO == s & d$year == "2026")
  L <- c(L, sprintf("| %s | %d | %d | %d | %d |", lab[s], n24, n26/2, n26/2, n24 + n26)) }
L <- c(L, "", "Sites received one (21 sites), two (6 sites) or four (4 sites) trials, always on different days (49 trials at 31 sites).", "")
fx <- function(f) { s <- summary(readRDS(f)); r <- rbind(s$fixed, s$random$site); r <- round(r[, c(1, 3, 4, 5, 6, 7)], 3)
  c("| Parameter | Estimate | l-95% CrI | u-95% CrI | R-hat | Bulk ESS | Tail ESS |", "|---|---|---|---|---|---|---|",
    sprintf("| %s | %.3f | %.3f | %.3f | %.3f | %.0f | %.0f |", rownames(r), r[,1], r[,2], r[,3], r[,4], r[,5], r[,6])) }
ct <- function(f) { x <- read.csv(f); c("| Contrast | Estimate | 95% HPD lower | 95% HPD upper |", "|---|---|---|---|",
  sprintf("| %s | %.3f | %.3f | %.3f |", x$contrast, x$estimate, x$lower.HPD, x$upper.HPD)) }
L <- c(L, "# Supplementary material 3", "")
nm <- c(INDIVIDUOS = "number of responding birds", MORFOESPECIE = "number of responding species and morphospecies")
k <- 1
for (r in names(nm)) for (fam in c(pois = "Poisson", nb = "negative binomial")) {
  L <- c(L, sprintf("**Table S3.%d.** Parameter estimates of the %s model of the %s (stimulus and year as fixed effects, site as random intercept; reference levels: sympatric stimulus, 2024).", k, fam, nm[r]), "", fx(file.path(m, sprintf("%s_%s.rds", r, names(which(c(pois = "Poisson", nb = "negative binomial") == fam))))), ""); k <- k + 1 }
for (r in names(nm)) {
  for (p in list(c("pois_prior2", "Poisson model, normal(0, 2) priors"), c("pois", "Poisson model, normal(0, 6) priors (main text)"), c("pois_prior10", "Poisson model, normal(0, 10) priors"), c("nb", "negative binomial model, normal(0, 6) priors"))) {
    L <- c(L, sprintf("**Table S3.%d.** Pairwise contrasts (log scale) for the %s: %s.", k, nm[r], p[2]), "", ct(file.path(o, sprintf("contrasts_%s_%s.csv", r, p[1])))[], ""); k <- k + 1 } }
L <- c(L, "# Supplementary material 4", "",
  "![Trace plots of the Poisson model of the number of responding birds.](trace_INDIVIDUOS_pois.png){width=6in}", "",
  "![Trace plots of the Poisson model of the number of responding species.](trace_MORFOESPECIE_pois.png){width=6in}", "",
  "![Posterior predictive checks (observed vs. 500 simulated count distributions) for the number of responding birds.](ppc_INDIVIDUOS.png){width=6in}", "",
  "![Posterior predictive checks for the number of responding species.](ppc_MORFOESPECIE.png){width=6in}", "")
writeLines(L, file.path(o, "supplementary_2-4.md"))
