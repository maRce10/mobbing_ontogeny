# Re-analysis in response to reviewers (Nov 2026)
# - year as fixed effect, sampling site as random intercept
# - Poisson vs negative binomial (LOO + posterior predictive checks)
# - prior sensitivity (refits under alternative priors on b)
# - pairwise contrasts as response ratios (emmeans, 95% HPD)
# Run from project root: Rscript scripts/reviewer_reanalysis.R

suppressPackageStartupMessages({
  library(brms); library(emmeans); library(loo); library(ggplot2); library(bayesplot)
})

dir.create("output/reanalysis", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed/models", showWarnings = FALSE, recursive = TRUE)

d <- read.csv("data/raw/data_v2.csv", na.strings = "NA", check.names = FALSE)
names(d) <- trimws(names(d))
d$year <- factor(substr(d$FECHA, 7, 10))
d$stimulus <- factor(d$ESTIMULO, levels = c("GLCR", "GLBR", "GLEU", "BADE"),
                     labels = c("Sympatric", "Allopatric", "Allopatric+", "Control"))
# Sampling site: point number within team transect. Team 3 (18 Jan 2024) revisited
# team-2 point 19; 2026 points 1-4 revisited team-1 points 1-4.
# ASSUMPTION: confirm with field notes.
team <- ifelse(d$EQUIPO == 3, 2, d$EQUIPO)
d$site <- factor(paste0("T", team, "_P", d$PUNTO))

cat("Occasions:", nrow(d), "| sites:", nlevels(d$site), "\n")
print(table(d$year)); print(table(d$stimulus))
print(table(table(d$site)))
cat("Proportion zeros (individuals):", mean(d$INDIVIDUOS == 0), "\n")
cat("Mean/var individuals:", mean(d$INDIVIDUOS), var(d$INDIVIDUOS), "\n")

iter <- 10000; warmup <- 5000; chains <- 4
pri <- c(prior(normal(0, 6), class = "b"))
ctrl <- list(adapt_delta = 0.99, max_treedepth = 15)

fit <- function(resp, fam, prior = pri, name) {
  # NB with non-overdispersed counts lets shape drift to infinity -> very slow;
  # use init = 0 and a lighter control for NB models
  is_nb <- fam$family == "negbinomial"
  f <- bf(as.formula(paste(resp, "~ stimulus + year + (1 | site)")))
  brm(f, family = fam, data = d, prior = prior, iter = iter, warmup = warmup,
      chains = chains, cores = chains, seed = 123,
      control = if (is_nb) list(adapt_delta = 0.95, max_treedepth = 12) else ctrl,
      init = if (is_nb) 0 else "random",
      file = file.path("data/processed/models", name), file_refit = "on_change")
}

res <- list()
for (resp in c("INDIVIDUOS", "MORFOESPECIE")) {
  mp <- fit(resp, poisson(), name = paste0(resp, "_pois"))
  mn <- fit(resp, negbinomial(), name = paste0(resp, "_nb"))
  mp <- add_criterion(mp, "loo", moment_match = FALSE)
  mn <- add_criterion(mn, "loo", moment_match = FALSE)
  cat("\n=====", resp, "=====\n")
  print(loo_compare(mp, mn))

  # PPC: proportion of zeros, mean, variance, max
  for (m in list(pois = mp, nb = mn)) {
    yrep <- posterior_predict(m)
    y <- d[[resp]]
    stats <- c(
      zeros = mean(rowMeans(yrep == 0) >= mean(y == 0)),
      mean = mean(rowMeans(yrep) >= mean(y)),
      var = mean(apply(yrep, 1, var) >= var(y)),
      max = mean(apply(yrep, 1, max) >= max(y)))
    cat("Bayesian p-values (P[T(yrep) >= T(y)]):\n"); print(round(stats, 3))
  }

  for (nm in c("pois", "nb")) {
    m <- if (nm == "pois") mp else mn
    s <- summary(m)
    fx <- rbind(s$fixed, s$random$site)
    cat("\n", nm, "max Rhat:", round(max(fx$Rhat), 4),
        "min Bulk_ESS:", round(min(fx$Bulk_ESS)), "min Tail_ESS:", round(min(fx$Tail_ESS)), "\n")
    print(round(fx, 3))
    em <- emmeans(m, pairwise ~ stimulus, type = "response")
    cn <- as.data.frame(em$contrasts)
    cn_log <- as.data.frame(emmeans(m, pairwise ~ stimulus)$contrasts)
    print(cn); print(cn_log)
    write.csv(cn_log, sprintf("output/reanalysis/contrasts_%s_%s.csv", resp, nm), row.names = FALSE)
    write.csv(cn, sprintf("output/reanalysis/ratios_%s_%s.csv", resp, nm), row.names = FALSE)
  }

  # trace plots + ppc figures (supplementary)
  png(sprintf("output/reanalysis/trace_%s_pois.png", resp), width = 2000, height = 1600, res = 200)
  print(mcmc_trace(as.array(mp), regex_pars = "^b_|^sd_")); dev.off()
  png(sprintf("output/reanalysis/ppc_%s.png", resp), width = 2000, height = 900, res = 200)
  print(bayesplot_grid(
    pp_check(mp, type = "bars", ndraws = 500) + ggtitle("Poisson"),
    pp_check(mn, type = "bars", ndraws = 500) + ggtitle("Negative binomial"), grid_args = list(ncol = 2)))
  dev.off()

  # prior sensitivity (Poisson model)
  for (sdp in c(2, 10)) {
    pr <- set_prior(sprintf("normal(0, %s)", sdp), class = "b")
    ms <- fit(resp, poisson(), prior = pr, name = paste0(resp, "_pois_prior", sdp))
    cn <- as.data.frame(emmeans(ms, pairwise ~ stimulus)$contrasts)
    cat("\nPrior normal(0,", sdp, ") contrasts (log scale):\n"); print(cn)
    write.csv(cn, sprintf("output/reanalysis/contrasts_%s_pois_prior%s.csv", resp, sdp), row.names = FALSE)
  }
}
sessionInfo()
