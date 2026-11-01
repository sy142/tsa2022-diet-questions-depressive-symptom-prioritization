tasarim_duzeyleri <- list(
  yas_g = c("1", "2", "3", "4"),
  cins = c("1", "2"),
  egitim = c("1", "2", "3", "4"),
  gelir5 = c("1", "2", "3", "4", "5"),
  kronik = c("0", "1", "2", "3"),
  meyve = c("7", "3", "4", "5", "6"),
  sebze = c("7", "3", "4", "5", "6"),
  faaliyet = c("1", "2", "3"),
  yakin = c("1", "2", "3", "4"),
  ilgi = c("5", "4", "3", "2", "6"),
  komsu = c("1", "2", "3", "4", "5"))
tasarim_onek <- c(yas_g = "yas", cins = "cins", egitim = "egt", gelir5 = "gel", kronik = "kro", meyve = "mey", sebze = "seb", faaliyet = "fa", yakin = "yak", ilgi = "ilg", komsu = "kom")
tasarim_gunler <- c("yurume", "bisiklet", "spor")

kukla <- function(f, onek) {
  L <- levels(f)
  m <- vapply(L[-1], function(l) as.integer(f == l), integer(length(f)))
  matrix(as.integer(m), nrow = length(f), ncol = length(L) - 1L, dimnames = list(NULL, paste0(onek, L[-1])))
}

tasarim_faktor <- function(x, v) {
  k <- trimws(as.character(x))
  hatali <- unique(k[is.na(k) | !k %in% tasarim_duzeyleri[[v]]])
  if (length(hatali)) stop(sprintf("%s: geçersiz ya da eksik kod (%s); beklenen kodlar: %s", v, paste(hatali, collapse = ", "), paste(tasarim_duzeyleri[[v]], collapse = ", ")), call. = FALSE)
  factor(k, levels = tasarim_duzeyleri[[v]])
}

tasarim_gun <- function(x, v) {
  g <- suppressWarnings(as.numeric(as.character(x)))
  if (anyNA(g) || any(g < 0 | g > 7 | g != round(g))) stop(sprintf("%s: gün sayısı 0–7 arasında tam sayı olmalı ve eksik olmamalı", v), call. = FALSE)
  as.integer(g)
}

tasarim_kur <- function(veri, yas_dugum = NULL, yas_sinir = NULL) {
  parca <- list()
  for (v in c("yas_g", "cins", "egitim", "gelir5", "kronik", "meyve", "sebze")) if (!is.null(veri[[v]])) parca[[v]] <- kukla(tasarim_faktor(veri[[v]], v), tasarim_onek[[v]])
  for (v in tasarim_gunler) if (!is.null(veri[[v]])) parca[[v]] <- matrix(tasarim_gun(veri[[v]], v), ncol = 1L, dimnames = list(NULL, v))
  for (v in c("faaliyet", "yakin", "ilgi", "komsu")) if (!is.null(veri[[v]])) parca[[v]] <- kukla(tasarim_faktor(veri[[v]], v), tasarim_onek[[v]])
  if (!is.null(veri[["depresyon"]])) {
    dk <- trimws(as.character(veri[["depresyon"]]))
    if (anyNA(dk) || any(!dk %in% c("0", "1"))) stop("depresyon: 0 (hayır) ya da 1 (evet) olmalı ve eksik olmamalı", call. = FALSE)
    parca$dep <- matrix(as.integer(dk), ncol = 1L, dimnames = list(NULL, "dep"))
  }
  if (!is.null(yas_dugum)) {
    ns <- splines::ns(veri[["yas"]], knots = yas_dugum, Boundary.knots = yas_sinir)
    parca$yasns <- matrix(unclass(ns)[, seq_len(ncol(ns)), drop = FALSE], nrow = nrow(ns), dimnames = list(NULL, paste0("yasns", seq_len(ncol(ns)))))
  }
  if (!length(parca)) stop("tasarim_kur: veride model değişkeni yok", call. = FALSE)
  do.call(cbind, unname(parca))
}
