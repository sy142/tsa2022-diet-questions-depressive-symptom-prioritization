paketler <- c("brms", "cmdstanr", "posterior", "WeightedROC", "data.table", "readr", "arrow", "jsonlite", "future", "furrr", "flextable", "officer", "openxlsx", "rlang",
              "emmeans", "estimability", "patchwork", "sandwich", "survival", "xtable", "zoo", "renv")
options(repos = c(CRAN = "https://cloud.r-project.org", stan = "https://stan-dev.r-universe.dev"))
kilit <- renv::lockfile_create(type = "custom", packages = paketler, project = getwd(), prompt = FALSE)
renv::lockfile_write(kilit, file = "renv.lock")
cat("renv.lock:", length(kilit$Packages), "paket (doğrudan kullanılanlar ve bağımlılıkları); R", kilit$R$Version, "\n")
