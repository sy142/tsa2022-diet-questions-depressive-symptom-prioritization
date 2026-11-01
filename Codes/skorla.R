ornek_kisiler <- data.frame(
  yas_g = c(1, 2, 3, 4), cins = c(2, 1, 2, 1), egitim = c(1, 3, 2, 4), gelir5 = c(1, 2, 4, 5), kronik = c(0, 1, 3, 2),
  meyve = c(7, 4, 3, 6), sebze = c(7, 5, 3, 7), yurume = c(7, 0, 3, 5), bisiklet = c(0, 0, 1, 0), spor = c(0, 2, 0, 1),
  faaliyet = c(1, 2, 1, 3), yakin = c(3, 2, 4, 1), ilgi = c(5, 4, 3, 6), komsu = c(1, 2, 3, 5))

skorla_kok <- local({
  ofile <- NULL
  for (fr in rev(sys.frames())) if (!is.null(fr$ofile)) {
    ofile <- fr$ofile
    break
  }
  arg <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)), fixed = TRUE)
  yol <- if (!is.null(ofile)) ofile else if (length(arg)) arg[1] else file.path("Codes", "skorla.R")
  normalizePath(file.path(dirname(yol), ".."), mustWork = TRUE)
})
source(file.path(skorla_kok, "Codes", "tasarim.R"))

skorla_cekilis <- function(model, dizin = file.path(skorla_kok, "Results", "model_cekilisleri")) {
  cek <- as.matrix(utils::read.csv(file.path(dizin, paste0(model, ".csv")), check.names = FALSE))
  if (!all(c("cekilis", "Intercept") %in% colnames(cek))) stop("çekiliş dosyasında cekilis ve Intercept sütunları yok: ", model, call. = FALSE)
  cek
}

skorla <- function(yeni_veri, model = c("M0", "M1", "M2"), dogrusal = FALSE, dizin = file.path(skorla_kok, "Results", "model_cekilisleri")) {
  model <- match.arg(model)
  cek <- skorla_cekilis(model, dizin)
  terim <- setdiff(colnames(cek), c("cekilis", "Intercept"))
  X <- tasarim_kur(yeni_veri)
  eksik <- setdiff(terim, colnames(X))
  onek <- sub("[0-9]+$", "", eksik)
  if (length(eksik)) stop(sprintf("%s için gerekli değişkenler eksik: %s", model, paste(unique(ifelse(onek %in% tasarim_onek, names(tasarim_onek)[match(onek, tasarim_onek)], onek)), collapse = ", ")), call. = FALSE)
  eta <- X[, terim, drop = FALSE] %*% t(cek[, terim, drop = FALSE])
  eta <- sweep(eta, 2L, cek[, "Intercept"], "+")
  sonuc <- data.frame(p_ortalama = rowMeans(stats::plogis(eta)))
  if (dogrusal) sonuc$eta_ortalama <- rowMeans(eta)
  sonuc
}

if (sys.nframe() == 0L) {
  print(cbind(ornek_kisiler[, c("yas_g", "cins", "meyve", "sebze")], M0 = skorla(ornek_kisiler, "M0")$p_ortalama, M1 = skorla(ornek_kisiler, "M1")$p_ortalama,
              M2 = skorla(ornek_kisiler, "M2")$p_ortalama), digits = 4)
}
