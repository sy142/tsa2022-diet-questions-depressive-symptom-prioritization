options(warn = 1, width = 160, datatable.print.nrows = 200, scipen = 6)
suppressPackageStartupMessages({
  library(data.table)
  library(readr)
  library(arrow)
  library(jsonlite)
})
set.seed(20261101)
baslangic <- Sys.time()
ddir <- "R_Data ve Python Data"
odir <- file.path(ddir, "onbellek")
fvdir <- file.path(ddir, "figur_verileri")
for (k in c("Results/log", "Results/denetim", "Results/Supplementary", "Figures/Supplementary", odir, fvdir)) dir.create(k, showWarnings = FALSE, recursive = TRUE)
sink("Results/log/analiz_log.txt", split = TRUE)
cat("analiz.R başladı:", format(baslangic), "\n")
sureler <- list()
sure_ekle <- function(adim, t0, yer = "CPU") {
  sureler[[length(sureler) + 1]] <<- data.table(adim = adim, yer = yer, dakika = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2))
  fwrite(rbindlist(sureler), "Results/log/analiz_sureleri.csv")
  invisible(NULL)
}
say <- list()
yuzde_w <- function(x, w) 100 * sum(w[x]) / sum(w)

t0 <- Sys.time()
kaynak_dizin <- Sys.getenv("TSA_KAYNAK", file.path(ddir, "kaynak"))
csv_yolu <- file.path(kaynak_dizin, "TSA_2022_MIKROVERI_REV.csv")
pq <- file.path(ddir, "tsa2022.parquet")
if (!file.exists(pq)) {
  ham <- as.data.table(read_delim(csv_yolu, delim = ";", col_types = cols(.default = col_character()), na = c("", "NA"),
                                  locale = locale(encoding = "UTF-8"), show_col_types = FALSE, progress = FALSE))
  write_parquet(ham, pq)
  saveRDS(ham, file.path(ddir, "tsa2022.rds"))
  writeLines(c(unname(tools::md5sum(csv_yolu)), format(round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))), file.path(ddir, "okuma_bilgisi.txt"))
  rm(ham)
  invisible(gc())
}
d <- as.data.table(read_parquet(pq))
ham_sutun <- ncol(d)
okuma <- readLines(file.path(ddir, "okuma_bilgisi.txt"))
csv_md5_simdi <- if (file.exists(csv_yolu)) unname(tools::md5sum(csv_yolu)) else NA_character_
cat("Ham veri:", nrow(d), "satır,", ncol(d), "sütun; CSV md5 (okumada):", okuma[1], "; şimdi:", csv_md5_simdi, "; okuma süresi (sn):", okuma[2], "\n")

sozluk_rds <- file.path(ddir, "kodlama_sozlugu_kmap_vlab.rds")
if (!file.exists(sozluk_rds)) {
  sozluk_env <- new.env()
  sys.source(file.path(kaynak_dizin, "TSA2022_kodlama_sozlugu.R"), envir = sozluk_env, keep.source = FALSE)
  saveRDS(list(kmap = sozluk_env$kmap, vlab = sozluk_env$vlab), sozluk_rds)
}
sozluk_env <- list2env(readRDS(sozluk_rds))
kmap <- sozluk_env$kmap
vlab <- sozluk_env$vlab
phq_mad <- c("ZEVK_DUYMA", "BUNALIM", "UYKU_SORUN", "YORGUNLUK", "ISTAHSIZLIK", "DEGERSIZ_HISSETME", "KONSANTRASYON_PRB", "HUZURSUZLUK")
mh_degisken <- c("SON12AY_PSIKOLOG", "SON12AY_PSIKOTERAPIST", "SON12AY_PSIKIYATRIST")
kronik_tum <- grep("^KRONIKHAST_", names(d), value = TRUE)
kronik_say <- setdiff(kronik_tum, c("KRONIKHAST_DEPRESYON", "KRONIKHAST_MADDEKUL"))
kullanilan <- c("YAS", "CINSIYET", "EGITIM", "HANE_GELIR_GRUP", phq_mad, "AILE_PRTS_HEK_HIZALMDRM", mh_degisken, kronik_tum, "MEYVE_YEMESIKLIK", "SEBZE_SALATA_YEMESIKLIK",
                "YURUME_10DAK_GUN", "BISIKLET_GUN", "SPOR_GUN", "GUNLUK_FAALIYETDURUM", "GUVENILIR_YAKIN", "CEVRE_ILGI", "KOMSU_YARDIM", "hane", "FERTNO", "FERTFAKTOR")
sozluk_tab <- data.table(degisken = kullanilan, soru = vapply(kullanilan, function(v) if (is.null(vlab[[v]])) "" else vlab[[v]], ""),
                         kmap_var = kullanilan %in% names(kmap))
fwrite(sozluk_tab, file.path(ddir, "sozluk.csv"))
kodlar_tab <- rbindlist(lapply(intersect(kullanilan, names(kmap)), function(v) data.table(degisken = v, kod = kmap[[v]][[1]], etiket = kmap[[v]][[2]])))
fwrite(kodlar_tab, file.path(ddir, "kodlar.csv"))
etiket_coz <- function(v, x = d[[v]]) kmap[[v]][[2]][match(x, kmap[[v]][[1]])]
sure_ekle("okuma", t0)

t0 <- Sys.time()
dogr <- list()
kontrol <- function(ad, beklenen, bulunan, tol = 0, kaynak = "talimat Bölüm 0") {
  fark <- if (is.numeric(beklenen) && is.numeric(bulunan)) bulunan - beklenen else NA_real_
  durum <- if (is.numeric(beklenen) && is.numeric(bulunan)) abs(fark) <= tol + 1e-9 else identical(as.character(beklenen), as.character(bulunan))
  dogr[[length(dogr) + 1]] <<- data.table(buyukluk = ad, kaynak = kaynak, beklenen = as.character(beklenen), bulunan = as.character(bulunan),
                                          fark = if (is.na(fark)) "" else format(round(fark, 4)), tolerans = tol, durum = if (durum) "Tuttu" else "Tutmadı")
  invisible(durum)
}
d[, w := as.numeric(gsub(",", ".", FERTFAKTOR, fixed = TRUE))]
d[, yas := as.integer(YAS)]
d[, id := paste(hane, FERTNO, sep = "_")]
agirlik_ozet <- d[, .(n = .N, eksik = sum(is.na(w)), sifir_negatif = sum(w <= 0, na.rm = TRUE), virgullu = sum(grepl(",", FERTFAKTOR, fixed = TRUE)),
                      noktali = sum(grepl(".", FERTFAKTOR, fixed = TRUE)), en_kucuk = min(w), q25 = quantile(w, 0.25), medyan = median(w), ortalama = mean(w),
                      q75 = quantile(w, 0.75), en_buyuk = max(w), toplam = sum(w))]
print(agirlik_ozet)
fwrite(agirlik_ozet, "Results/denetim/agirlik_ozeti.csv")
puan_etiket <- c("Hic", "Bazi gunler", "Bir haftadan fazla", "Neredeyse her gun")
for (v in phq_mad) {
  et <- etiket_coz(v)
  stopifnot(all(is.na(d[[v]]) | !is.na(et)))
  set(d, j = paste0("p_", v), value = match(et, puan_etiket) - 1L)
}
stopifnot(identical(kmap$ZEVK_DUYMA[[1]][match(puan_etiket, kmap$ZEVK_DUYMA[[2]])], c("6", "16", "17", "18")))
d[, phq8 := Reduce(`+`, .SD), .SDcols = paste0("p_", phq_mad)]
d[, phq2 := p_ZEVK_DUYMA + p_BUNALIM]
d[, phq_pos := as.integer(phq8 >= 10)]
d[, mh_temas := Reduce(`|`, lapply(.SD, function(x) x %in% "1")), .SDcols = mh_degisken]
d[, mh_hepsi_hayir := Reduce(`&`, lapply(.SD, function(x) x %in% "2")), .SDcols = mh_degisken]
d[, hekim := AILE_PRTS_HEK_HIZALMDRM %in% "3"]
d[, uygun := yas >= 18 & hekim & !mh_temas]
d[, uygun_hayir_tanimi := yas >= 18 & hekim & mh_hepsi_hayir]
d[, gunluk_degil_ikisi := !(MEYVE_YEMESIKLIK %in% "7") & !(SEBZE_SALATA_YEMESIKLIK %in% "7")]
a18 <- d[yas >= 18]
u0 <- d[uygun == TRUE]
kontrol("Ham CSV md5'i parquet'in okunduğu dosyayla aynı", okuma[1], csv_md5_simdi, kaynak = "analist")
kontrol("Veri satırı", 29761, nrow(d))
kontrol("Sütun", 295, ham_sutun)
kontrol("18+ yetişkin", 21444, nrow(a18))
kontrol("18+ içinde eksik PHQ-8 maddesi olan kişi", 0, a18[, sum(rowSums(is.na(.SD)) > 0), .SDcols = phq_mad])
kontrol("Uygun grup", 12843, nrow(u0))
kontrol("Uygun grup, üç uzman sorusunun üçü de Hayır tanımı", 12843, d[uygun_hayir_tanimi == TRUE, .N])
kontrol("Uygun gruptaki hane sayısı", 7726, uniqueN(u0$hane))
kontrol("Uygun grupta PHQ-8 ≥ 10 (kişi)", 581, u0[, sum(phq_pos)])
kontrol("Uygun grupta PHQ-8 ≥ 10 ağırlıklı yüzde", 4.57, round(u0[, yuzde_w(phq_pos == 1, w)], 2), tol = 0.005)
kontrol("581 içinde meyve ve sebzenin ikisi de günlük değil", 332, u0[phq_pos == 1 & gunluk_degil_ikisi, .N])
g470 <- a18[phq_pos == 1 & gunluk_degil_ikisi & !mh_temas]
kontrol("18+ PHQ-8 ≥ 10, ikisi de günlük değil, ruh sağlığı teması yok", 470, nrow(g470))
kontrol("470 içinde hekim teması var", 332, g470[hekim == TRUE, .N])
kontrol("470 içinde hekim teması yok", 138, g470[hekim == FALSE, .N])
kontrol("Uygun grupta PHQ-2 ≥ 3 ağırlıklı yüzde", 5.58, round(u0[, yuzde_w(phq2 >= 3, w)], 2), tol = 0.005)
kontrol("Uygun grupta PHQ-2 = 2 ağırlıklı yüzde", 20.25, round(u0[, yuzde_w(phq2 == 2, w)], 2), tol = 0.005)
ongorucu_ham <- c("YAS", "CINSIYET", "EGITIM", "HANE_GELIR_GRUP", kronik_say, "MEYVE_YEMESIKLIK", "SEBZE_SALATA_YEMESIKLIK", "YURUME_10DAK_GUN", "BISIKLET_GUN", "SPOR_GUN",
                  "GUNLUK_FAALIYETDURUM", "GUVENILIR_YAKIN", "CEVRE_ILGI", "KOMSU_YARDIM", "KRONIKHAST_DEPRESYON")
eksik_ham <- u0[, lapply(.SD, function(x) sum(is.na(x))), .SDcols = ongorucu_ham]
eksik_ham[, EGITIM := EGITIM + u0[, sum(EGITIM %in% "99")]]
kontrol("Uygun grupta eksik öngörücüsü olan kişi", 1, u0[, sum(rowSums(is.na(.SD)) > 0 | EGITIM %in% "99"), .SDcols = ongorucu_ham])
kontrol("Uygun grupta eksik HANE_GELIR_GRUP", 1, eksik_ham$HANE_GELIR_GRUP)
kontrol("Uygun grupta HANE_GELIR_GRUP dışında eksik öngörücü", 0, sum(unlist(eksik_ham)) - eksik_ham$HANE_GELIR_GRUP)
kontrol("FERTFAKTOR sayıya çevrilemeyen değer", 0, agirlik_ozet$eksik, kaynak = "analist")
kontrol("FERTFAKTOR sıfır veya negatif", 0, agirlik_ozet$sifir_negatif, kaynak = "analist")
kontrol("FERTFAKTOR ondalık virgüllü değer sayısı (talimat: virgüllü)", 29761, agirlik_ozet$virgullu, kaynak = "talimat Bölüm 2 ve 12")
kontrol("Kişi kimliği (hane + FERTNO) tekil", 0, d[, sum(duplicated(id))], kaynak = "analist")
kontrol("18+ PHQ maddelerinde kmap dışı kod", 0, a18[, sum(sapply(.SD, function(x) sum(!x %in% kmap$ZEVK_DUYMA[[1]]))), .SDcols = phq_mad], kaynak = "analist")
kontrol("KRONIKHAST_ değişken sayısı", 22, length(kronik_tum), kaynak = "talimat Bölüm 12")
kontrol("Kronik sayımına giren madde", 20, length(kronik_say), kaynak = "talimat Bölüm 4")
dogr_tab <- rbindlist(dogr)
fwrite(dogr_tab, "Results/dogrulama_kontrolleri.csv")
print(dogr_tab)
kapi <- dogr_tab[kaynak == "talimat Bölüm 0"]
kapi_hata <- kapi[durum != "Tuttu"]
if (nrow(kapi_hata)) {
  print(kapi_hata)
  stop("Aşama 0 kapısı: talimat Bölüm 0'daki doğrulanmış sayılardan ", nrow(kapi_hata), " tanesi tutmadı; modellere geçilmedi.")
}
cat("Aşama 0 kapısı geçildi:", nrow(kapi), "/", nrow(kapi), "talimat sayısı tuttu.\n")
say$dogrulama <- list(kapi_toplam = nrow(kapi), kapi_tutan = sum(kapi$durum == "Tuttu"), ek_kontrol = nrow(dogr_tab) - nrow(kapi),
                      fertfaktor_ondalik = if (agirlik_ozet$virgullu == 0) "nokta" else "virgül")
sure_ekle("doğrulama kapısı", t0)

t0 <- Sys.time()
etk <- fromJSON("Codes/etiketler.json", simplifyVector = TRUE)
eksik_veri <- data.table(degisken = names(eksik_ham), eksik_n = as.integer(unlist(eksik_ham)))
eksik_veri <- rbind(eksik_veri, data.table(degisken = c(phq_mad, "FERTFAKTOR", "hane", "FERTNO"), eksik_n = c(u0[, vapply(.SD, function(x) sum(is.na(x)), 0L), .SDcols = phq_mad],
                                                                                                          sum(is.na(u0$w)), sum(is.na(u0$hane)), sum(is.na(u0$FERTNO)))))
eksik_veri[, `:=`(n_uygun = nrow(u0), eksik_yuzde = round(100 * eksik_n / nrow(u0), 3))]
eksik_veri[, not := fifelse(degisken == "EGITIM", sprintf("EGITIM = 99 (Bilinmeyen) eksik sayıldı; 99 kodlu kişi: %d", u0[, sum(EGITIM %in% "99")]), "")]
print(eksik_veri[eksik_n > 0 | degisken == "EGITIM"])
fwrite(eksik_veri, "Results/denetim/eksik_veri.csv")

u <- copy(u0)
u[, yas_g := factor(cut(yas, c(17, 34, 49, 64, Inf), labels = FALSE), levels = 1:4)]
u[, cins := factor(CINSIYET, levels = c("1", "2"))]
egitim_esle <- data.table(kod = c("6", "1", "2", "31", "32", "33", "4", "511", "512", "52", "53", "99"), egitim = c(1L, 1L, 1L, 2L, 2L, 2L, 3L, 4L, 4L, 4L, 4L, NA))
egitim_esle[, etiket_kmap := etiket_coz("EGITIM", kod)]
egitim_esle[, etiket_en := c("cannot read or write", "no school completed", "primary school", "general lower secondary", "vocational or technical lower secondary",
                             "8-year primary education", "general, vocational or technical upper secondary", "2- or 3-year higher education", "4-year higher education or faculty",
                             "master's degree", "doctorate", "unknown")]
stopifnot(all(u$EGITIM %in% egitim_esle$kod))
u[, egitim := factor(egitim_esle$egitim[match(EGITIM, egitim_esle$kod)], levels = 1:4)]
gb <- u[!is.na(HANE_GELIR_GRUP), .(n = .N, w = sum(w)), keyby = .(bant = as.integer(HANE_GELIR_GRUP))]
gb[, `:=`(pay = w / sum(w), kum_pay = cumsum(w) / sum(w))]
gelir_kesim <- vapply(c(0.2, 0.4, 0.6, 0.8), function(t) gb$bant[which.min(abs(gb$kum_pay - t))], 0L)
gb[, gelir5 := 1L + vapply(bant, function(b) sum(b > gelir_kesim), 0L)]
gb[, etiket_kmap := etiket_coz("HANE_GELIR_GRUP", as.character(bant))]
print(gb)
fwrite(gb, "Results/denetim/gelir_bantlari.csv")
kontrol("Gelir grubu kesimleri (son bantlar)", "10, 13, 17, 19", paste(gelir_kesim, collapse = ", "), kaynak = "talimat Bölüm 4")
u[, gelir5 := factor(gb$gelir5[match(as.integer(HANE_GELIR_GRUP), gb$bant)], levels = 1:5)]
tl_sayi <- function(x) formatC(as.numeric(x), format = "d", big.mark = ",")
gelir_grup <- gb[, .(bantlar = if (min(bant) == max(bant)) as.character(min(bant)) else paste0(min(bant), "–", max(bant)), n = sum(n), agirlikli_yuzde = round(100 * sum(w) / sum(gb$w), 2),
                     tl_alt = as.numeric(gsub(" - .*| TL|\\+", "", etiket_kmap[1])), tl_ust = as.numeric(gsub(".* - | TL|\\+", "", etiket_kmap[.N])),
                     acik_uclu = grepl("\\+", etiket_kmap[.N])), keyby = gelir5]
gelir_grup[, tl_aralik := fifelse(acik_uclu, paste0("≥", tl_sayi(tl_alt), " TL"), paste0(tl_sayi(tl_alt), "–", tl_sayi(tl_ust), " TL"))]
print(gelir_grup)
fwrite(gelir_grup, "Results/denetim/gelir_gruplari.csv")
u[, kronik_n := Reduce(`+`, lapply(.SD, function(x) as.integer(x %in% "1"))), .SDcols = kronik_say]
u[, kronik := factor(pmin(kronik_n, 3L), levels = 0:3)]
siklik_sira <- c("7", "3", "4", "5", "6")
stopifnot(identical(etiket_coz("MEYVE_YEMESIKLIK", siklik_sira)[1], "Gunde bir kere ya da daha fazla"), identical(etiket_coz("MEYVE_YEMESIKLIK", siklik_sira)[5], "Hic"))
u[, meyve := factor(MEYVE_YEMESIKLIK, levels = siklik_sira)]
u[, sebze := factor(SEBZE_SALATA_YEMESIKLIK, levels = siklik_sira)]
for (v in c("YURUME_10DAK_GUN", "BISIKLET_GUN", "SPOR_GUN")) set(u, j = tolower(sub("_.*", "", v)), value = as.integer(u[[v]]))
gun_aralik <- u[, .(yurume = paste(range(yurume), collapse = "–"), bisiklet = paste(range(bisiklet), collapse = "–"), spor = paste(range(spor), collapse = "–"))]
kontrol("Gün sayıları aralığı (yürüme, bisiklet, spor)", "0–7, 0–7, 0–7", paste(unlist(gun_aralik), collapse = ", "), kaynak = "talimat Bölüm 4")
u[, faaliyet := factor(GUNLUK_FAALIYETDURUM, levels = kmap$GUNLUK_FAALIYETDURUM[[1]])]
u[, yakin := factor(GUVENILIR_YAKIN, levels = kmap$GUVENILIR_YAKIN[[1]])]
u[, ilgi := factor(CEVRE_ILGI, levels = kmap$CEVRE_ILGI[[1]])]
u[, komsu := factor(KOMSU_YARDIM, levels = kmap$KOMSU_YARDIM[[1]])]
u[, depresyon := as.integer(KRONIKHAST_DEPRESYON %in% "1")]
u[, hh := hane]
faktorler <- c("yas_g", "cins", "egitim", "gelir5", "kronik", "meyve", "sebze", "faaliyet", "yakin", "ilgi", "komsu")
gunler <- c("yurume", "bisiklet", "spor")
u[, tam := complete.cases(.SD), .SDcols = c(faktorler, gunler, "depresyon", "w")]
dusen <- u[tam == FALSE]
say$orneklem <- list(ham = nrow(d), yetiskin = nrow(a18), hekim_temasi = a18[, sum(hekim)], hekim_temasi_uzman_yok = nrow(u0),
                     uzman_temasi_dislanan = a18[hekim == TRUE, sum(mh_temas)], hekim_temasi_olmayan = a18[, sum(!hekim)],
                     uygun = nrow(u0), dusen_eksik = nrow(dusen), dusen_gelir = dusen[, sum(is.na(gelir5))], dusen_egitim99 = dusen[, sum(is.na(egitim))],
                     analiz = u[, sum(tam)], analiz_pozitif = u[tam == TRUE, sum(phq_pos)], analiz_hane = u[tam == TRUE, uniqueN(hh)],
                     dusen_pozitif = dusen[, sum(phq_pos)])
print(say$orneklem)
a <- u[tam == TRUE]
kat_olay <- rbindlist(lapply(faktorler, function(v) a[, .(n = .N, olay = sum(phq_pos)), keyby = .(duzey = get(v))][, degisken := v]))
setcolorder(kat_olay, c("degisken", "duzey"))
birlesim_log <- character(0)
for (v in c("meyve", "sebze")) {
  repeat {
    ol <- a[, .(n = .N, olay = sum(phq_pos)), keyby = .(duzey = get(v))]
    sifir_k <- which(ol$olay == 0)
    if (!length(sifir_k)) break
    k <- sifir_k[1]
    L <- levels(a[[v]])
    komsu_k <- if (k == 1) 2 else if (k == length(L)) k - 1 else if (ol$n[k - 1] <= ol$n[k + 1]) k - 1 else k + 1
    birlesim_log <- c(birlesim_log, sprintf("%s: '%s' sıfır olaylı, '%s' ile birleştirildi", v, L[k], L[komsu_k]))
    levels(a[[v]])[k] <- L[komsu_k]
  }
}
say$kategori_birlestirme <- if (length(birlesim_log)) birlesim_log else "yok"
cat("Sıfır olaylı kategori birleştirmesi:", say$kategori_birlestirme, "\n")
print(kat_olay)
fwrite(kat_olay, "Results/denetim/kategori_olay_sayilari.csv")
gun_olay <- rbindlist(lapply(gunler, function(v) a[, .(n = .N, olay = sum(phq_pos)), keyby = .(duzey = get(v))][, degisken := v]))
fwrite(gun_olay, "Results/denetim/gun_sayisi_olay.csv")

source("Codes/tasarim.R")
for (v in names(tasarim_duzeyleri)) if (!identical(levels(a[[v]]), tasarim_duzeyleri[[v]])) stop("tasarim.R düzeyleri analiz çerçevesiyle uyuşmuyor: ", v)
yas_dugum <- quantile(a$yas, c(1 / 3, 2 / 3), names = FALSE)
yas_sinir <- range(a$yas)
X <- tasarim_kur(a, yas_dugum, yas_sinir)
blok <- list(yas = grep("^yas[0-9]", colnames(X), value = TRUE), cins = "cins2", egt = grep("^egt", colnames(X), value = TRUE), gel = grep("^gel", colnames(X), value = TRUE),
             kro = grep("^kro", colnames(X), value = TRUE), mey = grep("^mey", colnames(X), value = TRUE), seb = grep("^seb", colnames(X), value = TRUE), gun = gunler,
             fa = grep("^fa", colnames(X), value = TRUE), yak = grep("^yak", colnames(X), value = TRUE), ilg = grep("^ilg", colnames(X), value = TRUE),
             kom = grep("^kom", colnames(X), value = TRUE), dep = "dep", yasns = grep("^yasns", colnames(X), value = TRUE))
sag <- list(M0 = c(blok$yas, blok$cins, blok$egt, blok$gel, blok$kro))
sag$M1 <- c(sag$M0, blok$mey, blok$seb)
sag$M2 <- c(sag$M1, blok$gun, blok$fa, blok$yak, blok$ilg, blok$kom)
sag$M0_dep <- c(sag$M0, "dep")
sag$M1_dep <- c(sag$M1, "dep")
sag$M0_ns <- c(blok$yasns, setdiff(sag$M0, blok$yas))
sag$M1_ns <- c(blok$yasns, setdiff(sag$M1, blok$yas))
print(lengths(sag))
a <- cbind(a[, .(id, hh, w, phq_pos, phq8, phq2, yas, yas_g, cins, egitim, gelir5, kronik, kronik_n, meyve, sebze, yurume, bisiklet, spor, faaliyet, yakin, ilgi, komsu, depresyon,
                 gelir_bant = as.integer(HANE_GELIR_GRUP), EGITIM, hekim, mh_temas)], as.data.table(X))
stopifnot(!anyNA(a[, c(colnames(X), "w", "phq_pos"), with = FALSE]))
write_parquet(a, file.path(ddir, "analiz_cercevesi.parquet"))
saveRDS(list(a = a, sag = sag, blok = blok, yas_dugum = yas_dugum, yas_sinir = yas_sinir, gelir_kesim = gelir_kesim), file.path(ddir, "analiz_cercevesi.rds"))
p_pay <- a[, sum(w * phq_pos) / sum(w)]
phq2_3_pay <- a[, sum(w * (phq2 >= 3)) / sum(w)]
say$p <- p_pay
say$capa <- list(p_yuzde = 100 * p_pay, phq2_3_kapasite_yuzde = 100 * phq2_3_pay, phq2_2_yuzde = 100 * a[, sum(w * (phq2 == 2)) / sum(w)],
                 uygun_grup_p_yuzde = 100 * u0[, sum(w * phq_pos) / sum(w)], uygun_grup_phq2_3_yuzde = 100 * u0[, sum(w * (phq2 >= 3)) / sum(w)])
cat(sprintf("Analiz çerçevesi: n = %d, hane = %d, pozitif = %d, p = %.4f, PHQ-2 ≥ 3 payı = %.4f\n", nrow(a), uniqueN(a$hh), sum(a$phq_pos), p_pay, phq2_3_pay))

degisken_tanimlari <- rbind(
  data.table(degisken = "phq_pos", etiket = etk$sonuc$uzun, kaynak = paste(phq_mad, collapse = ", "),
             kodlama = "Items scored 6 = 0 (not at all), 16 = 1 (several days), 17 = 2 (more than half the days), 18 = 3 (nearly every day); PHQ-8 = sum of eight items (0–24), computed only when all eight items are present; positive if ≥ 10",
             referans = "", modeller = "Outcome"),
  data.table(degisken = "phq2", etiket = "PHQ-2 score (symptom-based comparator sharing two items with the PHQ-8; not an upper bound)", kaynak = "ZEVK_DUYMA, BUNALIM", kodlama = "Sum of the two item scores (0–6)", referans = "", modeller = "Comparator ranking"),
  data.table(degisken = "uygun", etiket = "Eligible population", kaynak = paste(c("YAS", "AILE_PRTS_HEK_HIZALMDRM", mh_degisken), collapse = ", "),
             kodlama = "Age ≥ 18; general practitioner or family physician seen < 12 months ago (code 3); none of psychologist, psychotherapist or psychiatrist visited in the past 12 months (none coded 1 = yes)",
             referans = "", modeller = "Analysis frame"),
  data.table(degisken = "yas_g", etiket = etk$degisken$yas_g, kaynak = "YAS", kodlama = "18–34, 35–49, 50–64, ≥ 65", referans = "18–34", modeller = "M0, M1, M2"),
  data.table(degisken = "cins", etiket = etk$degisken$cins, kaynak = "CINSIYET", kodlama = "1 = men, 2 = women", referans = "Men", modeller = "M0, M1, M2"),
  data.table(degisken = "egitim", etiket = etk$degisken$egitim, kaynak = "EGITIM",
             kodlama = paste(egitim_esle[!is.na(egitim), .(t = sprintf("%s: %s", etk$kategori$egitim[[as.character(egitim[1])]], paste(sprintf("%s (%s)", kod, etiket_en), collapse = ", "))), by = egitim]$t,
                             collapse = "; "),
             referans = "Primary or less", modeller = "M0, M1, M2"),
  data.table(degisken = "gelir5", etiket = etk$degisken$gelir5, kaynak = "HANE_GELIR_GRUP",
             kodlama = paste0("Monthly net household income, 20 survey bands grouped at the weighted cumulative shares closest to 20%, 40%, 60% and 80%: ",
                              paste(gelir_grup[, sprintf("group %d = %s %s (%s; weighted %.1f%%)", gelir5, fifelse(grepl("–", bantlar), "bands", "band"), bantlar, tl_aralik, agirlikli_yuzde)], collapse = "; ")),
             referans = "Group 1 (lowest)", modeller = "M0, M1, M2"),
  data.table(degisken = "kronik", etiket = etk$degisken$kronik, kaynak = paste(kronik_say, collapse = ", "), kodlama = "Count of 'yes' answers across 20 conditions (KRONIKHAST_DEPRESYON and KRONIKHAST_MADDEKUL excluded): 0, 1, 2, ≥ 3",
             referans = "0", modeller = "M0, M1, M2"),
  data.table(degisken = c("meyve", "sebze"), etiket = c(etk$degisken$meyve, etk$degisken$sebze), kaynak = c("MEYVE_YEMESIKLIK", "SEBZE_SALATA_YEMESIKLIK"),
             kodlama = paste(sprintf("%s = %s", siklik_sira, unlist(etk$kategori$siklik[siklik_sira])), collapse = "; "), referans = "Daily or more", modeller = "M1, M2"),
  data.table(degisken = gunler, etiket = unlist(etk$degisken[gunler]), kaynak = c("YURUME_10DAK_GUN", "BISIKLET_GUN", "SPOR_GUN"), kodlama = "Days per week (0–7), numeric as recorded; fields not summed",
             referans = "", modeller = "M2"),
  data.table(degisken = "faaliyet", etiket = etk$degisken$faaliyet, kaynak = "GUNLUK_FAALIYETDURUM", kodlama = paste(sprintf("%s = %s", names(etk$kategori$faaliyet), unlist(etk$kategori$faaliyet)), collapse = "; "),
             referans = "Mostly sitting or standing", modeller = "M2"),
  data.table(degisken = c("yakin", "ilgi", "komsu"), etiket = c(etk$degisken$yakin, etk$degisken$ilgi, etk$degisken$komsu), kaynak = c("GUVENILIR_YAKIN", "CEVRE_ILGI", "KOMSU_YARDIM"),
             kodlama = c(paste(sprintf("%s = %s", names(etk$kategori$yakin), unlist(etk$kategori$yakin)), collapse = "; "),
                         paste(sprintf("%s = %s", names(etk$kategori$ilgi), unlist(etk$kategori$ilgi)), collapse = "; "),
                         paste(sprintf("%s = %s", names(etk$kategori$komsu), unlist(etk$kategori$komsu)), collapse = "; ")),
             referans = c("None", "A lot", "Very easy"), modeller = "M2"),
  data.table(degisken = "dep", etiket = etk$degisken$depresyon, kaynak = "KRONIKHAST_DEPRESYON", kodlama = "1 = yes, 2 = no", referans = "No", modeller = "Sensitivity F only"),
  data.table(degisken = "yasns", etiket = etk$degisken$yas_ns, kaynak = "YAS", kodlama = sprintf("Natural cubic spline, interior knots at ages %s (tertiles), boundary knots %s", paste(yas_dugum, collapse = " and "),
                                                                                                paste(yas_sinir, collapse = " and ")), referans = "", modeller = "Sensitivity E only"),
  data.table(degisken = "w", etiket = "Individual survey weight", kaynak = "FERTFAKTOR", kodlama = "Converted to numeric (decimal point in the source file)", referans = "", modeller = "All population-level quantities"))
fwrite(degisken_tanimlari, "Results/degisken_tanimlari.csv")
fwrite(egitim_esle, "Results/denetim/egitim_eslemesi.csv")

wsd <- function(x, w) sqrt(sum(w * (x - sum(w * x) / sum(w))^2) / sum(w))
t1_satir <- function(x, v, etiketler) {
  rbindlist(lapply(levels(x[[v]]), function(l) {
    s <- x[[v]] == l
    data.table(degisken = v, duzey = l, etiket = etiketler[[l]], tur = "kategori",
               n_toplam = sum(s), yuzde_toplam = 100 * sum(x$w[s]) / sum(x$w),
               n_pozitif = sum(s & x$phq_pos == 1), yuzde_pozitif = 100 * sum(x$w[s & x$phq_pos == 1]) / sum(x$w[x$phq_pos == 1]),
               n_negatif = sum(s & x$phq_pos == 0), yuzde_negatif = 100 * sum(x$w[s & x$phq_pos == 0]) / sum(x$w[x$phq_pos == 0]))
  }))
}
t1_gun <- function(x, v) {
  ort <- function(s) sprintf("%.2f (%.2f)", sum(x$w[s] * x[[v]][s]) / sum(x$w[s]), wsd(x[[v]][s], x$w[s]))
  rbind(data.table(degisken = v, duzey = "ort_sd", etiket = etk$gun_satiri$ort, tur = "ortalama",
                   n_toplam = nrow(x), yuzde_toplam = NA_real_, n_pozitif = sum(x$phq_pos == 1), yuzde_pozitif = NA_real_, n_negatif = sum(x$phq_pos == 0), yuzde_negatif = NA_real_,
                   ort_toplam = ort(rep(TRUE, nrow(x))), ort_pozitif = ort(x$phq_pos == 1), ort_negatif = ort(x$phq_pos == 0)),
        t1_satir(x[, .(w, phq_pos, z = factor(fifelse(get(v) == 0L, "0", "1+"), levels = c("0", "1+")))], "z", list("0" = etk$gun_satiri$sifir, "1+" = "1+"))[duzey == "0"][, degisken := v],
        fill = TRUE)
}
table1 <- rbind(t1_satir(a, "yas_g", etk$kategori$yas_g), t1_satir(a, "cins", etk$kategori$cins), t1_satir(a, "egitim", etk$kategori$egitim),
                t1_satir(a, "gelir5", etk$kategori$gelir5), t1_satir(a, "kronik", etk$kategori$kronik), t1_satir(a, "meyve", etk$kategori$siklik),
                t1_satir(a, "sebze", etk$kategori$siklik), t1_gun(a, "yurume"), t1_gun(a, "bisiklet"), t1_gun(a, "spor"), t1_satir(a, "faaliyet", etk$kategori$faaliyet),
                t1_satir(a, "yakin", etk$kategori$yakin), t1_satir(a, "ilgi", etk$kategori$ilgi), t1_satir(a, "komsu", etk$kategori$komsu), fill = TRUE)
table1[, degisken_etiket := unlist(etk$degisken[degisken])]
print(table1[, .(degisken, etiket, n_toplam, yuzde_toplam = round(yuzde_toplam, 1), n_pozitif, yuzde_pozitif = round(yuzde_pozitif, 1), n_negatif, yuzde_negatif = round(yuzde_negatif, 1), ort_toplam, ort_pozitif)])
fwrite(table1, "Results/table1_veri.csv")

a18[, hekim_f := hekim]
pos_uzmansiz <- a18[phq_pos == 1 & !mh_temas]
say$hizmet_kapsami <- list(tanim = "18+ adults with PHQ-8 >= 10 and no psychologist, psychotherapist or psychiatrist visit in the past 12 months",
                           n = nrow(pos_uzmansiz), n_hekim = pos_uzmansiz[, sum(hekim)],
                           hekim_temasi_agirlikli_yuzde = 100 * pos_uzmansiz[, sum(w * hekim) / sum(w)])
cat(sprintf("Hizmet kapsamı: 18+ PHQ-8 ≥ 10 ve uzman teması yok n = %d; son 12 ayda hekim teması ağırlıklı %%%.1f\n", nrow(pos_uzmansiz), say$hizmet_kapsami$hekim_temasi_agirlikli_yuzde))
g470_tab <- rbind(
  g470[, .(grup = "Total", n = .N, agirlikli_kisi = sum(w), yuzde_18_ustu = 100 * sum(w) / sum(a18$w), yuzde_18_ustu_pozitif = 100 * sum(w) / a18[phq_pos == 1, sum(w)],
           yuzde_grup_ici = 100)],
  g470[, .(n = .N, agirlikli_kisi = sum(w), yuzde_18_ustu = 100 * sum(w) / sum(a18$w), yuzde_18_ustu_pozitif = 100 * sum(w) / a18[phq_pos == 1, sum(w)],
           yuzde_grup_ici = 100 * sum(w) / sum(g470$w)), keyby = .(grup = fifelse(hekim, "GP or family physician seen < 12 months ago (within the eligible population)", "No GP or family physician visit in the past 12 months (outside the eligible population)"))],
  fill = TRUE)
g470_tab[, tanim := "Adults aged ≥ 18 with PHQ-8 ≥ 10, fruit and vegetable/salad both less than daily, and no psychologist, psychotherapist or psychiatrist visit in the past 12 months"]
print(g470_tab)
fwrite(g470_tab, "Results/Supplementary/grup470.csv")
say$grup470 <- list(n = nrow(g470), n_hekim = g470[, sum(hekim)], n_hekimsiz = g470[, sum(!hekim)], agirlikli_kisi = sum(g470$w),
                    yuzde_hekim_agirlikli = 100 * g470[, sum(w * hekim) / sum(w)])
write_json(say, "Results/sayilar.json", auto_unbox = TRUE, digits = NA, pretty = TRUE)
fwrite(rbindlist(dogr), "Results/dogrulama_kontrolleri.csv")
sure_ekle("değişken kurulumu ve Table 1 verisi", t0)

t0 <- Sys.time()
Sys.setenv(VECLIB_MAXIMUM_THREADS = "1")
suppressPackageStartupMessages({
  library(brms)
  library(cmdstanr)
  library(posterior)
  library(future)
  library(furrr)
})
stan_dir <- normalizePath(file.path(odir, "stan"), mustWork = FALSE)
dir.create(stan_dir, showWarnings = FALSE, recursive = TRUE)
options(cmdstanr_write_stan_file_dir = stan_dir)
wq <- function(x, w, p) {
  o <- order(x)
  cw <- cumsum(w[o]) / sum(w)
  vapply(p, function(pp) x[o][which(cw >= pp)[1]], 0)
}
Xa <- as.matrix(a[, colnames(X), with = FALSE])
oncel_tohum <- 20261102L
oncel_ongoru <- function(sutun, sd_b, B = 2000L) {
  set.seed(oncel_tohum)
  Xm <- Xa[, sutun, drop = FALSE]
  Xc <- sweep(Xm, 2, colMeans(Xm))
  sd_v <- if (length(sd_b) == 1) rep(sd_b, length(sutun)) else sd_b[sutun]
  bloklar <- Filter(length, lapply(blok, intersect, sutun))
  w <- a$w
  wsd0 <- function(v) sqrt(sum(w * (v - sum(w * v) / sum(w))^2) / sum(w))
  rbindlist(lapply(seq_len(B), function(b) {
    a0 <- 2.5 * rt(1, 3)
    beta <- setNames(rnorm(length(sutun), 0, sd_v), sutun)
    xb <- drop(Xc %*% beta)
    p <- plogis(a0 + xb)
    cbind(data.table(cekilis = b, pay = sum(w * p) / sum(w), xb_sd = wsd0(xb), p_q10 = wq(p, w, 0.1), p_q90 = wq(p, w, 0.9),
                     uc_pay = sum(w * (p < 0.001 | p > 0.999)) / sum(w)),
          as.data.table(lapply(setNames(bloklar, paste0("sd_", names(bloklar))), function(k) wsd0(drop(Xc[, k, drop = FALSE] %*% beta[k])))))
  }), fill = TRUE)
}
oo_ozet_f <- function(x, model, varyant) {
  blok_s <- grep("^sd_", names(x), value = TRUE)
  cbind(data.table(model = model, varyant = varyant, cekilis = nrow(x),
                   pay_q05 = quantile(x$pay, 0.05), pay_q50 = median(x$pay), pay_q95 = quantile(x$pay, 0.95), pay_1_99_disi = mean(x$pay < 0.01 | x$pay > 0.99),
                   xb_sd_q50 = median(x$xb_sd), xb_sd_q90 = quantile(x$xb_sd, 0.9), uc_pay_q50 = median(x$uc_pay), oran_q90_q10_q50 = median(x$p_q90 / x$p_q10)),
        as.data.table(lapply(x[, ..blok_s], median)))
}
oo_dosya <- file.path(odir, sprintf("oncel_ongoru_%s.rds", substr(rlang::hash(list(Xa, a$w, sag, oncel_tohum, deparse(oncel_ongoru))), 1, 10)))
if (!file.exists(oo_dosya)) {
  oo <- list(M0 = oncel_ongoru(sag$M0, 1), M1 = oncel_ongoru(sag$M1, 1), M2 = oncel_ongoru(sag$M2, 1))
  saveRDS(oo, oo_dosya)
}
oo <- readRDS(oo_dosya)
oo_ozet <- rbindlist(lapply(c("M0", "M1", "M2"), function(m) oo_ozet_f(oo[[m]], m, "talimat: b ~ N(0, 1)")), fill = TRUE)
gun_sd <- vapply(gunler, function(v) sqrt(sum(a$w * (a[[v]] - sum(a$w * a[[v]]) / sum(a$w))^2) / sum(a$w)), 0)
kategorik_blok_max <- max(unlist(oo_ozet[model == "M2", .(sd_yas, sd_cins, sd_egt, sd_gel, sd_kro, sd_mey, sd_seb, sd_fa, sd_yak, sd_ilg, sd_kom)]))
gun_blok <- oo_ozet[model == "M2", sd_gun]
oncel_kural <- gun_blok > 2 * kategorik_blok_max
sd_b_ana <- setNames(rep(1, ncol(Xa)), colnames(Xa))
oncel_adaylar <- list("gün katsayıları N(0, 1/SD_x)" = 1 / gun_sd, "gün katsayıları N(0, 1/(2 SD_x)), Gelman 2008" = 1 / (2 * gun_sd))
oncel_secilen <- "talimat: b ~ N(0, 1)"
if (oncel_kural) {
  for (k in names(oncel_adaylar)) {
    s <- sd_b_ana
    s[gunler] <- oncel_adaylar[[k]]
    if (is.null(oo[[k]])) {
      oo[[k]] <- oncel_ongoru(sag$M2, s)
      saveRDS(oo, oo_dosya)
    }
    oo_ozet <- rbind(oo_ozet, oo_ozet_f(oo[[k]], "M2", k), fill = TRUE)
    if (median(oo[[k]]$sd_gun) <= 2 * kategorik_blok_max) {
      sd_b_ana <- s
      oncel_secilen <- k
      break
    }
  }
}
oo_ozet[, `:=`(kategorik_blok_sd_max = kategorik_blok_max, gun_sd_yurume = gun_sd[["yurume"]], gun_sd_bisiklet = gun_sd[["bisiklet"]], gun_sd_spor = gun_sd[["spor"]])]
print(oo_ozet, digits = 3)
fwrite(oo_ozet, "Results/denetim/oncel_ongoru.csv")
fwrite(rbindlist(lapply(names(oo), function(m) oo[[m]][, .(model = m, cekilis, pay, xb_sd, uc_pay)])), file.path(fvdir, "figS_oncel_ongoru.csv"))
say$oncel <- list(kural = "Gün sayısı bloğunun önsel kişi arası x'b SD medyanı en büyük kategorik bloğunkinin 2 katını aşarsa gün katsayılarının ölçeği sırayla 1/SD_x ve 1/(2 SD_x) yapılır; ölçütü ilk sağlayan seçilir",
                  gun_blok_sd = gun_blok, kategorik_blok_sd_max = kategorik_blok_max, uygulandi = oncel_kural, secilen = oncel_secilen,
                  gun_prior_sd = as.list(round(sd_b_ana[gunler], 4)))
cat("Önsel kural uygulandı mı:", oncel_kural, "; seçilen:", oncel_secilen, "; gün bloğu SD (talimat):", round(gun_blok, 2), "; en büyük kategorik blok SD:", round(kategorik_blok_max, 2), "\n")
print(round(sd_b_ana[gunler], 4))
sure_ekle("önsel öngörü denetimi", t0)

t0 <- Sys.time()
sd_b_genis <- setNames(rep(2.5, ncol(Xa)), colnames(Xa))
prior_kur <- function(sutun, sd_b) {
  sdv <- sd_b[sutun]
  pr <- c(prior(student_t(3, 0, 2.5), class = Intercept), prior_string("normal(0, 1)", class = "b"))
  if (all(sdv == sdv[1])) return(c(prior(student_t(3, 0, 2.5), class = Intercept), prior_string(sprintf("normal(0, %s)", format(sdv[1])), class = "b")))
  for (k in sutun[sdv != 1]) pr <- c(pr, prior_string(sprintf("normal(0, %s)", format(sdv[[k]], digits = 15)), class = "b", coef = k))
  pr
}
brm_kur <- function(veri, sutun, sd_b, agirlikli = FALSE, iter, warmup, tohum, threads = NULL, chains = 4L, adapt_delta = 0.9, opencl_ac = FALSE) {
  lhs <- if (agirlikli) "phq_pos | weights(w_norm)" else "phq_pos"
  f <- bf(as.formula(paste(lhs, "~", paste(sutun, collapse = " + "))))
  brm(f, data = veri, family = bernoulli(link = "logit"), prior = prior_kur(sutun, sd_b), chains = chains, cores = chains, iter = iter, warmup = warmup, seed = tohum,
      backend = "cmdstanr", threads = if (is.null(threads)) NULL else threading(threads, static = TRUE), opencl = if (opencl_ac) opencl(c(0, 0)) else NULL,
      control = list(adapt_delta = adapt_delta), refresh = 0, silent = 2, stan_model_args = list(cpp_options = list(PRECOMPILED_HEADERS = "false")))
}
ebfmi_f <- function(fit) {
  en <- as.data.table(nuts_params(fit))[Parameter == "energy__"]
  min(en[, .(e = sum(diff(Value)^2) / sum((Value - mean(Value))^2)), by = Chain]$e)
}
tani_f <- function(fit, sutun) {
  dr <- as_draws_array(fit, variable = c("b_Intercept", paste0("b_", sutun)))
  sm <- summarise_draws(dr, "rhat", "ess_bulk", "ess_tail")
  np <- as.data.table(nuts_params(fit))
  data.table(parametre = nrow(sm), rhat_max = max(sm$rhat), ess_bulk_min = min(sm$ess_bulk), ess_tail_min = min(sm$ess_tail),
             diverjans = np[Parameter == "divergent__", sum(Value)], agac_siniri = np[Parameter == "treedepth__", sum(Value >= 10)], ebfmi_min = ebfmi_f(fit))
}
yakinsama_ok <- function(tn) tn$rhat_max <= 1.01 && tn$ess_bulk_min >= 400 && tn$ess_tail_min >= 400 && tn$diverjans == 0 && tn$ebfmi_min > 0.3
for (r in 1:5) {
  set.seed(20261110L + r)
  hhs <- sort(unique(a$hh))
  kat_h <- sample(rep_len(1:10, length(hhs)))
  set(a, j = paste0("kat_r", r), value = kat_h[match(a$hh, hhs)])
}
kat_ozet <- rbindlist(lapply(1:5, function(r) a[, .(tekrar = r, n = .N, hane = uniqueN(hh), pozitif = sum(phq_pos), agirlik_payi = sum(w) / sum(a$w)), keyby = .(kat = get(paste0("kat_r", r)))]))
fwrite(kat_ozet, "Results/denetim/kat_ozeti.csv")
kontrol("CV sızıntısı: birden çok katta yer alan hane (5 tekrar)", 0, sum(vapply(1:5, function(r) a[, uniqueN(get(paste0("kat_r", r))), by = hh][V1 > 1, .N], 0L)), kaynak = "talimat Bölüm 13")
cv_dir <- file.path(odir, "cv")
dir.create(cv_dir, showWarnings = FALSE, recursive = TRUE)
model_anahtar <- substr(rlang::hash(list(Xa, a$phq_pos, a$w, a$hh, as.matrix(a[, paste0("kat_r", 1:5), with = FALSE]), sd_b_ana, sd_b_genis, sag, deparse(prior_kur))), 1, 8)
cv_dosya <- function(j) file.path(cv_dir, sprintf("%s_%s_r%d_k%02d_w%d_s%d_t%d_%s.rds", j$model, j$varyant, j$tekrar, j$kat, j$warmup, j$ornek, j$tohum, model_anahtar))
cv_is <- function(j) {
  dosya <- cv_dosya(j)
  if (file.exists(dosya)) return(dosya)
  options(cmdstanr_write_stan_file_dir = stan_dir)
  kat <- a[[paste0("kat_r", j$tekrar)]]
  egt <- a[kat != j$kat]
  tst <- a[kat == j$kat]
  if (length(intersect(egt$hh, tst$hh))) stop("hane sızıntısı: ", dosya)
  if (j$agirlikli) egt[, w_norm := .N * w / sum(w)]
  sutun <- sag[[j$sag]]
  sd_b <- if (j$varyant == "oncel25") sd_b_genis else sd_b_ana
  warmup <- j$warmup
  ornek <- j$ornek
  ad <- 0.9
  deneme <- list()
  repeat {
    t1 <- Sys.time()
    fit <- brm_kur(egt, sutun, sd_b, j$agirlikli, iter = warmup + ornek, warmup = warmup, tohum = j$tohum, adapt_delta = ad)
    if (nrow(fit$data) != nrow(egt)) stop("brms satır düşürdü: ", dosya)
    tn <- cbind(tani_f(fit, sutun), warmup = warmup, ornek = ornek, adapt_delta = ad, dakika = as.numeric(difftime(Sys.time(), t1, units = "mins")))
    deneme[[length(deneme) + 1]] <- tn
    if (yakinsama_ok(tn) || length(deneme) >= 3) break
    if (tn$diverjans > 0) ad <- min(0.99, ad + 0.05)
    warmup <- 2L * warmup
    ornek <- 2L * ornek
  }
  dm <- as_draws_matrix(as_draws_array(fit, variable = c("b_Intercept", paste0("b_", sutun))))
  Xt <- as.matrix(tst[, ..sutun])
  eta <- dm[, paste0("b_", sutun), drop = FALSE] %*% t(Xt) + as.numeric(dm[, "b_Intercept"])
  P <- plogis(eta)
  p_hat <- colMeans(P)
  kontrol_n <- min(40L, nrow(tst))
  epred_fark <- max(abs(colMeans(posterior_epred(fit, newdata = tst[seq_len(kontrol_n)])) - p_hat[seq_len(kontrol_n)]))
  if (epred_fark > 1e-9) stop("p_hat ile posterior_epred uyuşmuyor: ", dosya, " ", epred_fark)
  desen <- match(apply(Xt, 1, paste, collapse = ""), unique(apply(Xt, 1, paste, collapse = "")))
  tek <- !duplicated(desen)
  nzin <- nchains(fit)
  arr <- array(P[, tek, drop = FALSE], dim = c(nrow(P) / nzin, nzin, sum(tek)))
  mcse_u <- apply(arr, 3, posterior::mcse_mean)
  mcse <- mcse_u[match(desen, desen[tek])]
  out <- list(id = tst$id, p_hat = p_hat, mcse = mcse, desen = desen,
              tani = cbind(data.table(model = j$model, varyant = j$varyant, tekrar = j$tekrar, kat = j$kat, n_egitim = nrow(egt), n_test = nrow(tst), deneme = length(deneme),
                                      epred_fark = epred_fark, mcse_max = max(mcse), mcse_medyan = median(mcse)), tn),
              denemeler = rbindlist(deneme), cek = if (isTRUE(j$cek_sakla)) dm[unique(round(seq(1, nrow(dm), length.out = 1000L))), , drop = FALSE] else NULL)
  saveRDS(out, dosya)
  dosya
}
cv_tohum <- function(model, varyant, tekrar, kat) 20261200L + 1000L * tekrar + 10L * kat + match(paste(model, varyant), c("M0 ana", "M1 ana", "M2 ana", "M0 agirlikli", "M1 agirlikli",
                                                                                                                        "M0 oncel25", "M1 oncel25", "M0 spline", "M1 spline", "M0 depresyon", "M1 depresyon")) * 100000L
is_tanim <- function(model, varyant, tekrar, sag_ad, agirlikli = FALSE, cek_sakla = FALSE, warmup = 1000L, ornek = 6000L) {
  rbindlist(lapply(1:10, function(k) data.table(model = model, varyant = varyant, tekrar = tekrar, kat = k, sag = sag_ad, agirlikli = agirlikli, cek_sakla = cek_sakla,
                                                 warmup = warmup, ornek = ornek, tohum = cv_tohum(model, varyant, tekrar, k))))
}
plan_cv <- rbind(is_tanim("M0", "ana", 1L, "M0", cek_sakla = TRUE), is_tanim("M1", "ana", 1L, "M1", cek_sakla = TRUE), is_tanim("M2", "ana", 1L, "M2", cek_sakla = TRUE),
                 is_tanim("M0", "agirlikli", 1L, "M0", agirlikli = TRUE), is_tanim("M1", "agirlikli", 1L, "M1", agirlikli = TRUE),
                 is_tanim("M0", "spline", 1L, "M0_ns"), is_tanim("M1", "spline", 1L, "M1_ns"),
                 is_tanim("M0", "depresyon", 1L, "M0_dep"), is_tanim("M1", "depresyon", 1L, "M1_dep"),
                 rbindlist(lapply(2:5, function(r) rbind(is_tanim("M0", "ana", r, "M0"), is_tanim("M1", "ana", r, "M1")))),
                 is_tanim("M0", "oncel25", 1L, "M0"), is_tanim("M1", "oncel25", 1L, "M1"),
                 rbindlist(lapply(2:5, function(r) is_tanim("M2", "ana", r, "M2"))))
plan_cv[, sira := .I]
cat("CV iş planı:", nrow(plan_cv), "uyum\n")
print(plan_cv[, .N, keyby = .(varyant, model, tekrar)])

pilot_dosya <- "Results/log/pilot_sureleri.csv"
if (!file.exists(pilot_dosya)) {
  zaman <- function(ad, expr) {
    t1 <- Sys.time()
    r <- tryCatch({ force(expr); "çalıştı" }, error = function(e) paste("hata:", substr(conditionMessage(e), 1, 300)))
    data.table(deneme = ad, dakika = round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 3), durum = r)
  }
  pilot <- list()
  pilot[[1]] <- zaman("CPU 4 zincir × 4 iş parçacığı (reduce_sum), M2, tam veri, 300 + 300; derleme dahil", brm_kur(a, sag$M2, sd_b_ana, iter = 600L, warmup = 300L, tohum = 11L, threads = 4L))
  pilot[[2]] <- zaman("CPU 4 zincir × 4 iş parçacığı (reduce_sum), M2, tam veri, 300 + 300; derlenmiş", brm_kur(a, sag$M2, sd_b_ana, iter = 600L, warmup = 300L, tohum = 12L, threads = 4L))
  pilot[[3]] <- zaman("CPU 4 zincir × 1 iş parçacığı (glm), M2, tam veri, 300 + 300; derleme dahil", brm_kur(a, sag$M2, sd_b_ana, iter = 600L, warmup = 300L, tohum = 11L))
  pilot[[4]] <- zaman("CPU 4 zincir × 1 iş parçacığı (glm), M2, tam veri, 300 + 300; derlenmiş", brm_kur(a, sag$M2, sd_b_ana, iter = 600L, warmup = 300L, tohum = 12L))
  pilot[[5]] <- zaman("GPU OpenCL (brms opencl(c(0, 0))), M2, tam veri, 300 + 300", brm_kur(a, sag$M2, sd_b_ana, iter = 600L, warmup = 300L, tohum = 11L, opencl_ac = TRUE))
  pilot[[6]] <- zaman("CPU 4 zincir × 1 iş parçacığı, M0, tam veri, 300 + 300; derleme dahil", brm_kur(a, sag$M0, sd_b_ana, iter = 600L, warmup = 300L, tohum = 11L))
  pilot[[7]] <- zaman(sprintf("Tek kat: M2 tekrar 1 kat 1, 4 zincir × 1 iş parçacığı, %d + %d (sıralı)", plan_cv$warmup[1], plan_cv$ornek[1]), cv_is(as.list(plan_cv[model == "M2" & varyant == "ana" & tekrar == 1 & kat == 1])))
  plan(multisession, workers = 4L)
  pilot[[8]] <- zaman(sprintf("Kat paralelliği: M2 tekrar 1 kat 2–5, 4 eşzamanlı uyum × 4 zincir × 1 iş parçacığı, %d + %d", plan_cv$warmup[1], plan_cv$ornek[1]),
                      future_map(split(plan_cv[model == "M2" & varyant == "ana" & tekrar == 1 & kat %in% 2:5], by = "kat"), function(j) cv_is(as.list(j)),
                                 .options = furrr_options(seed = NULL, packages = c("data.table", "brms", "posterior"))))
  plan(sequential)
  pilot <- rbindlist(pilot)
  print(pilot)
  fwrite(pilot, pilot_dosya)
}
pilot <- fread(pilot_dosya)
print(pilot)
sure_ekle("pilot", t0)

t0 <- Sys.time()
tam_modeller <- list()
tam_tani <- list()
for (m in c("M0", "M1", "M2")) {
  dosya <- file.path(odir, sprintf("tam_%s_w1000_s1500_t%d_%s.rds", m, 20261110L + match(m, c("M0", "M1", "M2")), model_anahtar))
  if (!file.exists(dosya)) {
    warmup <- 1000L
    ornek <- 1500L
    ad <- 0.9
    deneme <- list()
    repeat {
      t1 <- Sys.time()
      fit <- brm_kur(a, sag[[m]], sd_b_ana, iter = warmup + ornek, warmup = warmup, tohum = 20261110L + match(m, c("M0", "M1", "M2")), adapt_delta = ad)
      if (nrow(fit$data) != nrow(a)) stop("brms satır düşürdü: ", m)
      tn <- cbind(data.table(model = m, varyant = "tam veri", n_egitim = nrow(a)), tani_f(fit, sag[[m]]), warmup = warmup, ornek = ornek, adapt_delta = ad,
                  dakika = as.numeric(difftime(Sys.time(), t1, units = "mins")))
      deneme[[length(deneme) + 1]] <- tn
      if (yakinsama_ok(tn) || length(deneme) >= 3) break
      if (tn$diverjans > 0) ad <- min(0.99, ad + 0.05)
      warmup <- 2L * warmup
      ornek <- 2L * ornek
    }
    attr(fit, "tani") <- rbindlist(deneme)
    saveRDS(fit, dosya)
  }
  tam_modeller[[m]] <- readRDS(dosya)
  tam_tani[[m]] <- attr(tam_modeller[[m]], "tani")
}
tam_tani <- rbindlist(tam_tani)
print(tam_tani)
terim_et <- rbind(
  data.table(terim = blok$yas, degisken = "yas_g", duzey = unlist(etk$kategori$yas_g)[2:4]),
  data.table(terim = "cins2", degisken = "cins", duzey = etk$kategori$cins[["2"]]),
  data.table(terim = blok$egt, degisken = "egitim", duzey = unlist(etk$kategori$egitim)[2:4]),
  data.table(terim = blok$gel, degisken = "gelir5", duzey = unlist(etk$kategori$gelir5)[2:5]),
  data.table(terim = blok$kro, degisken = "kronik", duzey = unlist(etk$kategori$kronik)[2:4]),
  data.table(terim = blok$mey, degisken = "meyve", duzey = unlist(etk$kategori$siklik[sub("mey", "", blok$mey)])),
  data.table(terim = blok$seb, degisken = "sebze", duzey = unlist(etk$kategori$siklik[sub("seb", "", blok$seb)])),
  data.table(terim = gunler, degisken = gunler, duzey = "Per day"),
  data.table(terim = blok$fa, degisken = "faaliyet", duzey = unlist(etk$kategori$faaliyet[sub("fa", "", blok$fa)])),
  data.table(terim = blok$yak, degisken = "yakin", duzey = unlist(etk$kategori$yakin[sub("yak", "", blok$yak)])),
  data.table(terim = blok$ilg, degisken = "ilgi", duzey = unlist(etk$kategori$ilgi[sub("ilg", "", blok$ilg)])),
  data.table(terim = blok$kom, degisken = "komsu", duzey = unlist(etk$kategori$komsu[sub("kom", "", blok$kom)])),
  data.table(terim = "dep", degisken = "depresyon", duzey = "Yes"),
  data.table(terim = blok$yasns, degisken = "yas_ns", duzey = paste("Basis", 1:3)))
terim_et[, degisken_etiket := unlist(etk$degisken[degisken])]
stopifnot(setequal(terim_et$terim, colnames(X)))
katsayilar <- rbindlist(lapply(names(tam_modeller), function(m) {
  dr <- as_draws_matrix(tam_modeller[[m]], variable = paste0("b_", sag[[m]]))
  e <- exp(dr)
  data.table(model = m, terim = sag[[m]], b_ortalama = colMeans(dr), b_sd = apply(dr, 2, sd), or_medyan = apply(e, 2, median),
             or_alt = apply(e, 2, quantile, 0.025), or_ust = apply(e, 2, quantile, 0.975), oncel_sd = unname(sd_b_ana[sag[[m]]]))
}))
katsayilar <- merge(katsayilar, terim_et, by = "terim", sort = FALSE)
katsayilar[, aralik_turu := "95% posterior interval (2.5th–97.5th percentiles)"]
fwrite(katsayilar, "Results/Supplementary/katsayilar.csv")
kesisim <- rbindlist(lapply(names(tam_modeller), function(m) {
  b0 <- as.numeric(as_draws_matrix(tam_modeller[[m]], variable = "b_Intercept"))
  data.table(model = m, ortalama = mean(b0), alt = quantile(b0, 0.025, names = FALSE), ust = quantile(b0, 0.975, names = FALSE))
}))
cek_dir <- "Results/model_cekilisleri"
dir.create(cek_dir, showWarnings = FALSE, recursive = TRUE)
cek_ids <- list()
for (m in names(tam_modeller)) {
  dm <- as_draws_matrix(tam_modeller[[m]], variable = c("b_Intercept", paste0("b_", sag[[m]])))
  i <- unique(round(seq(1, nrow(dm), length.out = 1000L)))
  cek_ids[[m]] <- i
  cm <- matrix(as.numeric(dm), nrow = nrow(dm), dimnames = list(NULL, sub("^b_", "", colnames(dm))))[i, , drop = FALSE]
  fwrite(data.table(cekilis = i, cm), file.path(cek_dir, paste0(m, ".csv")))
}
kat_anahtar <- c(yas_g = "yas_g", cins = "cins", egitim = "egitim", gelir5 = "gelir5", kronik = "kronik", meyve = "siklik", sebze = "siklik", faaliyet = "faaliyet", yakin = "yakin", ilgi = "ilgi", komsu = "komsu")
terimler <- rbind(
  data.table(terim = "Intercept", girdi_sutunu = "", degisken = "Intercept", duzey_kodu = "", duzey = "", referans_kodu = "", referans_duzey = "",
             olcek = "log-odds when every indicator is 0 (all reference categories) and, in M2, all day counts are 0"),
  rbindlist(lapply(names(tasarim_duzeyleri), function(v) {
    L <- tasarim_duzeyleri[[v]]
    et <- etk$kategori[[kat_anahtar[[v]]]]
    data.table(terim = paste0(tasarim_onek[[v]], L[-1]), girdi_sutunu = v, degisken = etk$degisken[[v]], duzey_kodu = L[-1], duzey = unlist(et[L[-1]], use.names = FALSE),
               referans_kodu = L[1], referans_duzey = et[[L[1]]], olcek = "indicator: 1 if the input code equals duzey_kodu, otherwise 0")
  })),
  data.table(terim = tasarim_gunler, girdi_sutunu = tasarim_gunler, degisken = unlist(etk$degisken[tasarim_gunler], use.names = FALSE), duzey_kodu = "", duzey = "", referans_kodu = "", referans_duzey = "",
             olcek = "per day (days per week, integer 0–7)"))
terimler <- terimler[match(c("Intercept", sag$M2), terim)]
terimler[, modeller := vapply(terim, function(t) paste(c("M0", "M1", "M2")[vapply(c("M0", "M1", "M2"), function(m) t == "Intercept" || t %in% sag[[m]], NA)], collapse = ", "), "")]
stopifnot(!anyNA(terimler$terim))
fwrite(terimler, file.path(cek_dir, "terimler.csv"))
source("Codes/skorla.R")
skorla_dogrulama <- rbindlist(lapply(names(tam_modeller), function(m) {
  sk <- skorla(a, m, dogrusal = TRUE)
  ep <- colMeans(posterior_epred(tam_modeller[[m]], newdata = a, draw_ids = cek_ids[[m]]))
  lp <- colMeans(posterior_linpred(tam_modeller[[m]], newdata = a, draw_ids = cek_ids[[m]]))
  ep_tum <- colMeans(posterior_epred(tam_modeller[[m]], newdata = a))
  data.table(model = m, kisi = nrow(a), cekilis = length(cek_ids[[m]]), olcut = 1e-6, en_buyuk_fark_p = max(abs(sk$p_ortalama - ep)), en_buyuk_fark_eta = max(abs(sk$eta_ortalama - lp)),
             tum_cekilislerle_en_buyuk_fark_p = max(abs(sk$p_ortalama - ep_tum)), tum_cekilislerle_ort_mutlak_fark_p = mean(abs(sk$p_ortalama - ep_tum)),
             ortalama_etada_olasilik_en_buyuk_fark = max(abs(sk$p_ortalama - plogis(sk$eta_ortalama))))
}))
skorla_dogrulama[, sonuc := fifelse(en_buyuk_fark_p < olcut & en_buyuk_fark_eta < olcut, "sağlandı", "SAĞLANMADI")]
print(skorla_dogrulama)
fwrite(skorla_dogrulama, "Results/denetim/skorla_dogrulama.csv")
if (any(skorla_dogrulama$sonuc != "sağlandı")) stop("skorla() ile posterior_epred uyuşmuyor")
say$model_cekilisleri <- list(klasor = cek_dir, cekilis = length(cek_ids[[1]]), secim = sprintf("unique(round(seq(1, %d, length.out = 1000))) over the post-warm-up draws (4 chains)", ndraws(tam_modeller[[1]])),
                              skorla_dogrulama = lapply(split(skorla_dogrulama[, .(model, en_buyuk_fark_p, en_buyuk_fark_eta, tum_cekilislerle_en_buyuk_fark_p, ortalama_etada_olasilik_en_buyuk_fark)], by = "model", keep.by = FALSE), as.list),
                              kesisim = lapply(split(kesisim, by = "model", keep.by = FALSE), as.list))
sink("Results/model_ozetleri.txt")
for (m in names(tam_modeller)) {
  cat("====", m, "(tam veri, n =", nrow(a), ")\n")
  print(summary(tam_modeller[[m]]))
  cat("\n")
}
sink()
sink("Results/log/analiz_log.txt", append = TRUE, split = TRUE)
sure_ekle("tam veri modelleri", t0)

t0 <- Sys.time()
eksik_is <- plan_cv[!file.exists(cv_dosya(plan_cv))]
cat("CV: planlanan", nrow(plan_cv), "uyum, eksik", nrow(eksik_is), "\n")
if (nrow(eksik_is)) {
  ilerleme <- "Results/log/cv_ilerleme.txt"
  cat(format(Sys.time()), "CV başladı, eksik uyum:", nrow(eksik_is), "\n", file = ilerleme, append = TRUE)
  plan(multisession, workers = 4L)
  invisible(future_map(split(eksik_is, by = "sira"), function(j) {
    r <- cv_is(as.list(j))
    cat(format(Sys.time()), basename(r), "\n", file = ilerleme, append = TRUE)
    r
  }, .options = furrr_options(seed = NULL, scheduling = Inf, packages = c("data.table", "brms", "posterior"))))
  plan(sequential)
  cat(format(Sys.time()), "CV bitti\n", file = ilerleme, append = TRUE)
}
cv_oku <- lapply(seq_len(nrow(plan_cv)), function(i) {
  j <- plan_cv[i]
  r <- readRDS(cv_dosya(j))
  list(tahmin = data.table(id = r$id, model = j$model, varyant = j$varyant, tekrar = j$tekrar, kat = j$kat, p_hat = r$p_hat, mcse = r$mcse, desen = r$desen),
       tani = r$tani, deneme = cbind(j[, .(model, varyant, tekrar, kat)], r$denemeler))
})
cvl <- rbindlist(lapply(cv_oku, `[[`, "tahmin"))
cv_tani <- rbindlist(lapply(cv_oku, `[[`, "tani"))
cv_deneme <- rbindlist(lapply(cv_oku, `[[`, "deneme"))
rm(cv_oku)
kapsam <- cvl[, .(n = .N, tekil = uniqueN(id)), by = .(model, varyant, tekrar)]
kontrol("CV: her model ve tekrarda herkesin tam bir dış kat tahmini var", 0L, kapsam[n != nrow(a) | tekil != nrow(a), .N], kaynak = "analist")
kontrol("CV: dış kat ile kişinin kat ataması uyumlu", 0L, cvl[a[, .(id, k1 = kat_r1, k2 = kat_r2, k3 = kat_r3, k4 = kat_r4, k5 = kat_r5)], on = "id"][
  kat != fcase(tekrar == 1, k1, tekrar == 2, k2, tekrar == 3, k3, tekrar == 4, k4, tekrar == 5, k5), .N], kaynak = "talimat Bölüm 13")
model_tanilari <- rbind(tam_tani[, .(model, varyant, tekrar = NA_integer_, kat = NA_integer_, n_egitim, parametre, rhat_max, ess_bulk_min, ess_tail_min, diverjans, agac_siniri,
                                     ebfmi_min, warmup, ornek, adapt_delta, dakika, deneme = .N), by = model][, .SD[.N], by = model],
                        cv_tani[, .(model, varyant, tekrar, kat, n_egitim, parametre, rhat_max, ess_bulk_min, ess_tail_min, diverjans, agac_siniri, ebfmi_min, warmup, ornek,
                                    adapt_delta, dakika, deneme, mcse_max, mcse_medyan, epred_fark)], fill = TRUE)
fwrite(model_tanilari, "Results/denetim/model_tanilari.csv")
fwrite(cv_deneme, "Results/denetim/cv_yakinsama_denemeleri.csv")
cat("CV tanıları: R-hat en büyük", round(max(cv_tani$rhat_max), 4), "; bulk ESS en küçük", round(min(cv_tani$ess_bulk_min)), "; tail ESS en küçük", round(min(cv_tani$ess_tail_min)),
    "; divergence toplam", sum(cv_tani$diverjans), "; E-BFMI en küçük", round(min(cv_tani$ebfmi_min), 3), "; ikinci deneme gereken", sum(cv_tani$deneme > 1),
    "; ölçütü sağlamayan", cv_tani[!(rhat_max <= 1.01 & ess_bulk_min >= 400 & ess_tail_min >= 400 & diverjans == 0 & ebfmi_min > 0.3), .N], "\n")
ana_gen <- dcast(cvl[varyant == "ana"], id + tekrar ~ model, value.var = "p_hat")
setnames(ana_gen, c("M0", "M1", "M2"), c("p_hat_M0", "p_hat_M1", "p_hat_M2"))
ana_gen <- merge(a[, .(id, hh, w, phq_pos, phq2, kat_r1, kat_r2, kat_r3, kat_r4, kat_r5)], ana_gen, by = "id")
ana_gen[, kat := fcase(tekrar == 1, kat_r1, tekrar == 2, kat_r2, tekrar == 3, kat_r3, tekrar == 4, kat_r4, tekrar == 5, kat_r5)]
ana_gen[, paste0("kat_r", 1:5) := NULL]
setcolorder(ana_gen, c("id", "hh", "w", "phq_pos", "phq2", "p_hat_M0", "p_hat_M1", "p_hat_M2", "kat", "tekrar"))
setorder(ana_gen, tekrar, id)
write_parquet(ana_gen, file.path(ddir, "cv_tahminleri.parquet"))
fwrite(ana_gen, file.path(ddir, "cv_tahminleri.csv"))
duy_gen <- dcast(cvl[varyant != "ana"], id + varyant ~ model, value.var = "p_hat")
setnames(duy_gen, c("M0", "M1"), c("p_hat_M0", "p_hat_M1"))
write_parquet(duy_gen, file.path(ddir, "cv_tahminleri_duyarlilik.parquet"))
sure_ekle("hane bloklu çapraz doğrulama", t0)
write_json(say, "Results/sayilar.json", auto_unbox = TRUE, digits = NA, pretty = TRUE)
fwrite(rbindlist(dogr), "Results/dogrulama_kontrolleri.csv")

t0 <- Sys.time()
secim_kesri <- function(s, W, c) {
  tek <- is.null(dim(W))
  Wm <- if (tek) matrix(W, ncol = 1L) else W
  dz <- sort(unique(s), decreasing = TRUE)
  g <- match(s, dz)
  G <- length(dz)
  B <- ncol(Wm)
  Wg <- rowsum(Wm, g, reorder = TRUE)
  Cw <- matrix(if (G == 1L) Wg else apply(Wg, 2L, cumsum), nrow = G)
  once <- rbind(0, Cw[-G, , drop = FALSE])
  sonuc <- lapply(c, function(cc) {
    H <- matrix(cc * Cw[G, ], G, B, byrow = TRUE)
    fg <- (H - once) / Wg
    fg[!is.finite(fg)] <- 0
    fg <- pmin(pmax(fg, 0), 1)
    dimnames(fg) <- NULL
    f <- fg[g, , drop = FALSE]
    esik <- dz[pmin(G, colSums(Cw < H - 1e-10 * H) + 1L)]
    if (tek) f <- f[, 1L]
    attr(f, "esik") <- esik
    f
  })
  if (length(c) == 1L) sonuc[[1L]] else sonuc
}
tabakali_secim <- function(s, W, c, tabaka) {
  tek <- is.null(dim(W))
  Wm <- if (tek) matrix(W, ncol = 1L) else W
  out <- lapply(seq_along(c), function(k) matrix(0, nrow(Wm), ncol(Wm)))
  for (i in split(seq_along(s), tabaka)) {
    r <- secim_kesri(s[i], Wm[i, , drop = FALSE], c)
    if (length(c) == 1L) r <- list(r)
    for (k in seq_along(c)) out[[k]][i, ] <- r[[k]]
  }
  if (tek) out <- lapply(out, function(m) m[, 1L])
  if (length(c) == 1L) out[[1L]] else out
}
birim <- list()
bt <- function(ad, kosul) birim[[length(birim) + 1L]] <<- data.table(test = ad, sonuc = if (isTRUE(kosul)) "geçti" else "KALDI")
s0 <- c(0.9, 0.8, 0.8, 0.5, 0.1)
w0 <- c(1, 2, 1, 3, 3)
bt("Elle örnek, c = 0,20: f = (1, 1/3, 1/3, 0, 0)", isTRUE(all.equal(as.numeric(secim_kesri(s0, w0, 0.2)), c(1, 1 / 3, 1 / 3, 0, 0))))
bt("Elle örnek, c = 0,20: seçilen ağırlık = 2 ve eşik = 0,8", isTRUE(all.equal(sum(w0 * secim_kesri(s0, w0, 0.2)), 2)) && attr(secim_kesri(s0, w0, 0.2), "esik") == 0.8)
bt("Elle örnek, c = 0,40 (sınır tam grup sonunda): f = (1, 1, 1, 0, 0)", isTRUE(all.equal(as.numeric(secim_kesri(s0, w0, 0.4)), c(1, 1, 1, 0, 0))))
bt("Elle örnek, c = 0,45: f = (1, 1, 1, 1/6, 0)", isTRUE(all.equal(as.numeric(secim_kesri(s0, w0, 0.45)), c(1, 1, 1, 1 / 6, 0))))
bt("c = 0 hiç kimseyi, c = 1 herkesi seçer", all(secim_kesri(s0, w0, 0) == 0) && all(secim_kesri(s0, w0, 1) == 1))
W0 <- cbind(w0, c(0, 2, 1, 3, 3))
f0 <- secim_kesri(s0, W0, 0.2)
bt("Matris ağırlık (bootstrap sütunları), sıfır ağırlıklı kişi: seçilen ağırlık c × toplam", isTRUE(all.equal(colSums(f0 * W0), 0.2 * colSums(W0))) && isTRUE(all.equal(f0[2:3, 2], c(0.6, 0.6))))
set.seed(20261120L)
s1 <- round(runif(3000), 2)
w1 <- runif(3000, 0.5, 3)
p1 <- sample(3000)
bt("Sıra değişmezliği (3.000 kişi, yoğun eşitlik)", isTRUE(all.equal(secim_kesri(s1, w1, 0.2)[p1], as.numeric(secim_kesri(s1[p1], w1[p1], 0.2)), check.attributes = FALSE)))
bt("Rastgele veride her c için seçilen ağırlık = c × toplam", all(vapply(seq(0.01, 0.99, by = 0.01), function(cc) abs(sum(w1 * secim_kesri(s1, w1, cc)) - cc * sum(w1)) < 1e-8, NA)))
s2 <- runif(3000)
esik2 <- attr(secim_kesri(s2, w1, 0.2), "esik")
bt("Eşik = ağırlıklı (1 − c) kantili: eşik üstü ağırlık < cW ≤ eşik ve üstü ağırlık", sum(w1[s2 > esik2]) < 0.2 * sum(w1) && sum(w1[s2 >= esik2]) >= 0.2 * sum(w1) &&
     isTRUE(all.equal(esik2, wq(-s2, w1, 0.2) * -1)))
bt("Tabakalı seçim: her tabakada seçilen ağırlık c × tabaka toplamı", {
  tb <- sample(1:7, 3000, replace = TRUE)
  ft <- tabakali_secim(s1, w1, 0.3, tb)
  all(abs(tapply(w1 * ft, tb, sum) - 0.3 * tapply(w1, tb, sum)) < 1e-8)
})
bt("Vektör ve tek sütunlu matris aynı sonucu verir", isTRUE(all.equal(as.numeric(secim_kesri(s1, w1, 0.2)), as.numeric(secim_kesri(s1, matrix(w1), 0.2)))))
birim <- rbindlist(birim)
print(birim)
fwrite(birim, "Results/denetim/birim_testleri.csv")
if (any(birim$sonuc != "geçti")) stop("Seçim fonksiyonu birim testi kaldı")

kap_izgara <- round(seq(0.02, 0.50, by = 0.02), 2)
kap3 <- c(0.10, 0.20, 0.30)
y <- a$phq_pos
w <- a$w
gen1 <- ana_gen[tekrar == 1][match(a$id, id)]
stopifnot(identical(gen1$id, a$id))
skor <- list(M0 = gen1$p_hat_M0, M1 = gen1$p_hat_M1, M2 = gen1$p_hat_M2, PHQ2 = a$phq2)
tabaka <- list(M0 = a$kat_r1, M1 = a$kat_r1, M2 = a$kat_r1, PHQ2 = a$kat_r1)
for (r in 2:5) {
  gr <- ana_gen[tekrar == r][match(a$id, id)]
  for (m in c("M0", "M1", "M2")) if (!all(is.na(gr[[paste0("p_hat_", m)]]))) {
    skor[[sprintf("%s_r%d", m, r)]] <- gr[[paste0("p_hat_", m)]]
    tabaka[[sprintf("%s_r%d", m, r)]] <- a[[paste0("kat_r", r)]]
  }
}
for (v in c("agirlikli", "oncel25", "spline", "depresyon")) {
  gv <- duy_gen[varyant == v][match(a$id, id)]
  for (m in c("M0", "M1")) {
    skor[[sprintf("%s_%s", m, v)]] <- gv[[paste0("p_hat_", m)]]
    tabaka[[sprintf("%s_%s", m, v)]] <- a$kat_r1
  }
}
for (m in c("M0", "M1", "M2")) {
  skor[[paste0(m, "_havuz")]] <- skor[[m]]
  tabaka[[paste0(m, "_havuz")]] <- rep(1L, nrow(a))
}
stopifnot(!anyNA(unlist(skor)))
egri_str <- c("M0", "M1", "M2", "PHQ2")
duy_str <- setdiff(names(skor), egri_str)
grup_deg <- c("yas_g", "cins", "egitim", "gelir5")
esit_tabaka <- paste(a$kat_r1, a$gelir5)
phq2_3 <- as.numeric(a$phq2 >= 3)

olcu_tablo <- function(Wm, b_ad) {
  WY <- Wm * y
  top <- colSums(Wm)
  poz <- colSums(WY)
  out <- list()
  for (st in egri_str) {
    fl <- tabakali_secim(skor[[st]], Wm, kap_izgara, tabaka[[st]])
    out$egri[[st]] <- rbindlist(lapply(seq_along(kap_izgara), function(k) data.table(b = b_ad, strateji = st, c = kap_izgara[k], yakalanan = colSums(fl[[k]] * WY),
                                                                                     secilen = colSums(fl[[k]] * Wm))))
    f20 <- fl[[which(kap_izgara == 0.20)]]
    out$altgrup[[st]] <- rbindlist(lapply(grup_deg, function(gv) {
      gr <- as.character(a[[gv]])
      yk <- rowsum(f20 * WY, gr)
      sc <- rowsum(f20 * Wm, gr)
      pz <- rowsum(WY, gr)
      tp <- rowsum(Wm, gr)
      rbindlist(lapply(rownames(yk), function(l) data.table(b = b_ad, strateji = st, degisken = gv, duzey = l, yakalanan = yk[l, ], secilen = sc[l, ], pozitif = pz[l, ], toplam = tp[l, ])))
    }))
  }
  out$duy <- rbindlist(lapply(duy_str, function(st) {
    fl <- tabakali_secim(skor[[st]], Wm, kap3, tabaka[[st]])
    rbindlist(lapply(seq_along(kap3), function(k) data.table(b = b_ad, strateji = st, c = kap3[k], yakalanan = colSums(fl[[k]] * WY))))
  }))
  out$esit <- rbindlist(lapply(c("M0", "M1", "M2"), function(st) {
    fl <- tabakali_secim(skor[[st]], Wm, kap3, esit_tabaka)
    rbindlist(lapply(seq_along(kap3), function(k) {
      gr <- as.character(a$gelir5)
      yk <- rowsum(fl[[k]] * WY, gr)
      sc <- rowsum(fl[[k]] * Wm, gr)
      rbind(data.table(b = b_ad, strateji = st, c = kap3[k], duzey = "Toplam", yakalanan = colSums(fl[[k]] * WY), secilen = colSums(fl[[k]] * Wm)),
            rbindlist(lapply(rownames(yk), function(l) data.table(b = b_ad, strateji = st, c = kap3[k], duzey = l, yakalanan = yk[l, ], secilen = sc[l, ]))))
    }))
  }))
  out$esit_kisitsiz <- rbindlist(lapply(c("M0", "M1", "M2"), function(st) {
    fl <- tabakali_secim(skor[[st]], Wm, kap3, tabaka[[st]])
    rbindlist(lapply(seq_along(kap3), function(k) {
      gr <- as.character(a$gelir5)
      yk <- rowsum(fl[[k]] * WY, gr)
      sc <- rowsum(fl[[k]] * Wm, gr)
      rbindlist(lapply(rownames(yk), function(l) data.table(b = b_ad, strateji = st, c = kap3[k], duzey = l, yakalanan = yk[l, ], secilen = sc[l, ])))
    }))
  }))
  gr <- as.character(a$gelir5)
  out$gelir_top <- rbindlist(lapply(rownames(rowsum(Wm[, 1, drop = FALSE], gr)), function(l) data.table(b = b_ad, duzey = l, pozitif = rowsum(WY, gr)[l, ], toplam = rowsum(Wm, gr)[l, ])))
  out$phq2_3 <- data.table(b = b_ad, yakalanan = colSums(WY * phq2_3), secilen = colSums(Wm * phq2_3))
  out$toplam <- data.table(b = b_ad, toplam = top, pozitif = poz)
  out$egri <- rbindlist(out$egri)
  out$altgrup <- rbindlist(out$altgrup)
  out
}
nokta <- olcu_tablo(matrix(w, ncol = 1L), 0L)
nokta$egri[, `:=`(D = 1000 * yakalanan / nokta$toplam$toplam, Sens = yakalanan / nokta$toplam$pozitif, PPV = yakalanan / secilen)]
kontrol("Kapasite: her strateji ve c'de seçilen ağırlıklı pay = c", 0L, nokta$egri[abs(secilen / nokta$toplam$toplam - c) > 1e-9, .N], kaynak = "talimat Bölüm 7")
kontrol("Kapasite: D = 1000 p Sens = 1000 c PPV (en büyük sapma < 1e−9)", 0L,
        nokta$egri[abs(D - 1000 * say$p * Sens) > 1e-9 | abs(D - 1000 * c * PPV) > 1e-9, .N], kaynak = "talimat Bölüm 13")
print(nokta$egri[c %in% kap3, .(strateji, c, D = round(D, 2), Sens = round(Sens, 3), PPV = round(PPV, 4))])

B_boot <- 2000L
boot_tohum <- 20261131L
hhs <- sort(unique(a$hh))
hh_i <- match(a$hh, hhs)
carpan_dosya <- file.path(odir, sprintf("boot_carpan_B%d_t%d.rds", B_boot, boot_tohum))
if (!file.exists(carpan_dosya)) {
  set.seed(boot_tohum)
  Mh <- matrix(0L, length(hhs), B_boot)
  for (b in seq_len(B_boot)) Mh[, b] <- tabulate(sample.int(length(hhs), length(hhs), replace = TRUE), length(hhs))
  saveRDS(Mh, carpan_dosya)
}
Mh <- readRDS(carpan_dosya)
kontrol("Bootstrap: her tekrarda yeniden örneklenen hane sayısı = H", 0L, sum(colSums(Mh) != length(hhs)), kaynak = "analist")
boot_dosya <- file.path(odir, sprintf("boot_sonuc_B%d_t%d_%s.rds", B_boot, boot_tohum, substr(rlang::hash(list(skor, tabaka, kap_izgara, kap3, y, w, hh_i, esit_tabaka, as.matrix(a[, grup_deg, with = FALSE]), Mh, deparse(secim_kesri), deparse(tabakali_secim), deparse(olcu_tablo))), 1, 10)))
if (!file.exists(boot_dosya)) {
  parcalar <- split(seq_len(B_boot), ceiling(seq_len(B_boot) / 50L))
  plan(multisession, workers = 14L)
  bs <- future_map(parcalar, function(cols) olcu_tablo(w * Mh[hh_i, cols, drop = FALSE], cols),
                   .options = furrr_options(seed = NULL, scheduling = Inf, packages = "data.table"))
  plan(sequential)
  boot <- lapply(names(bs[[1]]), function(k) rbindlist(lapply(bs, `[[`, k)))
  names(boot) <- names(bs[[1]])
  saveRDS(boot, boot_dosya)
  rm(bs)
}
boot <- readRDS(boot_dosya)
sure_ekle("kapasite: nokta tahminleri ve eşlenik hane bootstrap'ı", t0)

t0 <- Sys.time()
alt <- function(x) quantile(x, 0.025, names = FALSE, type = 7)
ust <- function(x) quantile(x, 0.975, names = FALSE, type = 7)
tum_egri <- function(o) {
  tp <- o$toplam[, .(b, toplam, pozitif, p = pozitif / toplam)]
  eg <- merge(o$egri, tp, by = "b")
  eg[, `:=`(D = 1000 * yakalanan / toplam, Sens = yakalanan / pozitif, PPV = yakalanan / secilen)]
  ek <- CJ(b = tp$b, c = kap_izgara)[tp, on = "b"]
  rbind(eg[, .(b, strateji, c, D, Sens, PPV)],
        ek[, .(b, strateji = "rastgele", c, D = 1000 * c * p, Sens = c, PPV = p)],
        ek[, .(b, strateji = "ideal", c, D = 1000 * pmin(c, p), Sens = pmin(c, p) / p, PPV = pmin(c, p) / c)])
}
eg_n <- tum_egri(nokta)
eg_b <- tum_egri(boot)
ozetle <- function(n, bdt, by) {
  olc <- intersect(c("D", "Sens", "PPV", "fark", "deger"), names(n))
  uz_n <- melt(n, id.vars = by, measure.vars = olc, variable.name = "olcu", value.name = "tahmin")
  uz_b <- melt(bdt, id.vars = c("b", by), measure.vars = olc, variable.name = "olcu", value.name = "v")[, .(alt = alt(v), ust = ust(v), b_medyan = median(v), b_sayi = .N), by = c(by, "olcu")]
  merge(uz_n, uz_b, by = c(by, "olcu"), sort = FALSE)
}
egri_oz <- ozetle(eg_n[, !"b"], eg_b, c("strateji", "c"))
fark_kur <- function(eg, st1, st0) {
  x <- merge(eg[strateji == st1, .(b, c, D1 = D)], eg[strateji == st0, .(b, c, D0 = D)], by = c("b", "c"))
  x[, .(b, c, karsilastirma = paste(st1, "−", st0), fark = D1 - D0)]
}
karsilastirmalar <- list(c("M1", "M0"), c("M2", "M1"), c("M2", "M0"), c("PHQ2", "M0"), c("rastgele", "M0"), c("ideal", "M0"), c("M1", "rastgele"), c("M0", "rastgele"))
fark_n <- rbindlist(lapply(karsilastirmalar, function(k) fark_kur(eg_n, k[1], k[2])))
fark_b <- rbindlist(lapply(karsilastirmalar, function(k) fark_kur(eg_b, k[1], k[2])))
fark_oz <- ozetle(fark_n[, !"b"], fark_b, c("karsilastirma", "c"))
print(fark_oz[c %in% kap3])
d20 <- fark_b[karsilastirma == "M1 − M0" & c == 0.20, fark]
bolge <- function(x, s) data.table(sinir = s, buyuk = mean(x > s), icinde = mean(abs(x) <= s), kucuk = mean(x < -s))
tekrar_oran <- rbindlist(lapply(c("M1 − M0", "M2 − M1"), function(k) rbindlist(lapply(c(0.5, 1, 2), function(s) cbind(karsilastirma = k, c = 0.20,
                                                                                                                  bolge(fark_b[karsilastirma == k & c == 0.20, fark], s))))))
tekrar_oran[, not := sprintf("Bootstrap replicate proportions (household cluster bootstrap, B = %s); not posterior probabilities", format(B_boot, big.mark = ","))]
fwrite(tekrar_oran, "Results/Supplementary/bootstrap_tekrar_oranlari.csv")
p2 <- rbind(nokta$phq2_3, boot$phq2_3)
p2 <- merge(p2, rbind(nokta$toplam, boot$toplam), by = "b")
p2[, `:=`(c = secilen / toplam, D = 1000 * yakalanan / toplam, Sens = yakalanan / pozitif, PPV = yakalanan / secilen)]
p2_oz <- melt(p2, id.vars = "b", measure.vars = c("c", "D", "Sens", "PPV"), variable.name = "olcu")[, .(tahmin = value[b == 0], alt = alt(value[b > 0]), ust = ust(value[b > 0]), b_medyan = median(value[b > 0])), by = olcu]
print(p2_oz)
fwrite(merge(egri_oz[olcu == "D"], egri_oz[olcu == "Sens", .(strateji, c, Sens = tahmin, Sens_alt = alt, Sens_ust = ust)], by = c("strateji", "c"))[
  egri_oz[olcu == "PPV", .(strateji, c, PPV = tahmin, PPV_alt = alt, PPV_ust = ust)], on = c("strateji", "c")][, .(strateji, c, D = tahmin, D_alt = alt, D_ust = ust, Sens, Sens_alt, Sens_ust, PPV, PPV_alt, PPV_ust)],
  file.path(fvdir, "kapasite_egrisi.csv"))
p_b <- boot$toplam[, pozitif / toplam]
ideal_kirilma <- data.table(strateji = "ideal", c = say$p, D = 1000 * say$p, D_alt = alt(1000 * pmin(say$p, p_b)), D_ust = ust(1000 * pmin(say$p, p_b)),
                            Sens = 1, Sens_alt = alt(pmin(say$p, p_b) / p_b), Sens_ust = ust(pmin(say$p, p_b) / p_b), PPV = 1, PPV_alt = alt(pmin(say$p, p_b) / say$p), PPV_ust = ust(pmin(say$p, p_b) / say$p))
fwrite(ideal_kirilma, file.path(fvdir, "kapasite_egrisi.csv"), append = TRUE)
tavan_esik <- 0.2
tavan_kat <- rbindlist(lapply(1:5, function(r) {
  kt <- a[[paste0("kat_r", r)]]
  Wk <- as.numeric(tapply(w, kt, sum))
  Pk <- as.numeric(tapply(w * y, kt, sum))
  cc <- sort(unique(c(kap_izgara, Pk / Wk, say$p)))
  data.table(tekrar = r, c = cc, izgara = cc %in% kap_izgara, kirilma = !cc %in% kap_izgara, D_kat = vapply(cc, function(x) 1000 * sum(pmin(x * Wk, Pk)) / sum(w), 0),
             D_nufus = 1000 * pmin(cc, say$p), kat_p_min = min(Pk / Wk), kat_p_max = max(Pk / Wk))
}))
tavan_kat[, fark := D_nufus - D_kat]
fwrite(tavan_kat, "Results/denetim/kat_duzeyi_tavan.csv")
tavan_ozet <- tavan_kat[, .(izgara_en_buyuk_fark = max(fark[izgara]), izgara_en_buyuk_fark_c = c[izgara][which.max(fark[izgara])], surekli_en_buyuk_fark = max(fark),
                            surekli_en_buyuk_fark_c = c[which.max(fark)], kat_p_min = kat_p_min[1], kat_p_max = kat_p_max[1]), keyby = tekrar]
print(tavan_ozet)
tavan_ciz <- tavan_ozet[tekrar == 1, izgara_en_buyuk_fark] >= tavan_esik
fwrite(tavan_kat[tekrar == 1, .(c, D = D_kat, izgara)], file.path(fvdir, "tavan_kat_duzeyi.csv"))
fwrite(fark_oz[olcu == "fark", .(karsilastirma, c, fark = tahmin, alt, ust, b_medyan)], file.path(fvdir, "fark_egrisi.csv"))
ince_c <- round(seq(0.08, 0.32, by = 0.005), 3)
ince <- rbindlist(lapply(c("M0", "M1", "M2"), function(st) {
  fl <- tabakali_secim(skor[[st]], w, ince_c, tabaka[[st]])
  data.table(strateji = st, c = ince_c, D = vapply(fl, function(f) 1000 * sum(w * f * y) / sum(w), 0))
}))
ince_w <- dcast(ince, c ~ strateji, value.var = "D")
ince_w[, `:=`(M1_M0 = M1 - M0, M2_M1 = M2 - M1)]
fwrite(ince_w, "Results/denetim/ince_izgara_farklar.csv")
yerel <- rbindlist(lapply(kap3, function(cc) {
  x <- ince_w[abs(c - cc) <= 0.02 + 1e-9]
  rbind(x[, .(karsilastirma = "M1 − M0", c = cc, nokta = .N, ort = mean(M1_M0), en_kucuk = min(M1_M0), en_buyuk = max(M1_M0))],
        x[, .(karsilastirma = "M2 − M1", c = cc, nokta = .N, ort = mean(M2_M1), en_kucuk = min(M2_M1), en_buyuk = max(M2_M1))])
}))
print(yerel)
fwrite(p2_oz, file.path(fvdir, "phq2_3_noktasi.csv"))
say$kapasite <- list(
  B = B_boot, tohum = boot_tohum, aralik = "percentile 2.5–97.5, household cluster bootstrap, fixed model fits and fold assignments",
  delta_020 = as.list(fark_oz[karsilastirma == "M1 − M0" & c == 0.20 & olcu == "fark", .(tahmin, alt, ust, b_medyan)]),
  m2_m1_020 = as.list(fark_oz[karsilastirma == "M2 − M1" & c == 0.20 & olcu == "fark", .(tahmin, alt, ust, b_medyan)]),
  m2_m0_020 = as.list(fark_oz[karsilastirma == "M2 − M0" & c == 0.20 & olcu == "fark", .(tahmin, alt, ust, b_medyan)]),
  senaryolar = lapply(split(egri_oz[c %in% kap3], by = c("c", "strateji", "olcu"), keep.by = FALSE, drop = TRUE), as.list),
  farklar = lapply(split(fark_oz[c %in% kap3], by = c("c", "karsilastirma"), keep.by = FALSE, drop = TRUE), as.list),
  phq2_3 = lapply(split(p2_oz, by = "olcu", keep.by = FALSE, drop = TRUE), as.list),
  pratik_sinir = 1, sinir_karsiliklari = list(sens_yuzde_puan = 100 * 1 / (1000 * say$p), ppv_yuzde_puan_c020 = 100 * 1 / (1000 * 0.20)),
  tekrar_oranlari = lapply(split(tekrar_oran, by = c("karsilastirma", "sinir"), keep.by = FALSE, drop = TRUE), as.list))
sure_ekle("kapasite: özetler", t0)

t0 <- Sys.time()
tp_all <- rbind(nokta$toplam, boot$toplam)
nb_oz <- function(x, by, olc) {
  uz <- melt(x, id.vars = c("b", by), measure.vars = olc, variable.name = "olcu", value.name = "v")[!is.na(v)]
  uz[, .(tahmin = v[b == 0], alt = alt(v[b > 0]), ust = ust(v[b > 0]), b_medyan = median(v[b > 0]), b_sayi = sum(b > 0)), by = c(by, "olcu")]
}
es <- rbind(nokta$esit, boot$esit)
ek <- rbind(nokta$esit_kisitsiz, boot$esit_kisitsiz)
gt <- rbind(nokta$gelir_top, boot$gelir_top)
es_top <- merge(es[duzey == "Toplam"], tp_all, by = "b")[, .(b, strateji, c, D_esit = 1000 * yakalanan / toplam, Sens_esit = yakalanan / pozitif)]
ks_top <- rbind(eg_n, eg_b)[strateji %in% c("M0", "M1", "M2") & c %in% kap3, .(b, strateji, c, D_kisitsiz = D, Sens_kisitsiz = Sens)]
es_top <- merge(es_top, ks_top, by = c("b", "strateji", "c"))
es_top[, fark_D := D_esit - D_kisitsiz]
es_top_oz <- nb_oz(es_top, c("strateji", "c"), c("D_kisitsiz", "D_esit", "fark_D", "Sens_kisitsiz", "Sens_esit"))
gg <- rbind(es[duzey != "Toplam", .(b, strateji, c, kural = "equal", duzey, yakalanan, secilen)], ek[, .(b, strateji, c, kural = "unconstrained", duzey, yakalanan, secilen)])
gg <- merge(gg, gt, by = c("b", "duzey"))
gg[, `:=`(Sens = yakalanan / pozitif, secim_payi = secilen / toplam)]
gg_w <- dcast(gg, b + strateji + c + duzey ~ kural, value.var = c("Sens", "secim_payi"))
gg_w[, fark_Sens := Sens_equal - Sens_unconstrained]
gg_oz <- nb_oz(gg_w, c("strateji", "c", "duzey"), c("Sens_unconstrained", "Sens_equal", "fark_Sens", "secim_payi_unconstrained", "secim_payi_equal"))
gelir_n <- a[, .(n = .N, n_pozitif = sum(phq_pos)), keyby = .(duzey = as.character(gelir5))]
gg_oz <- merge(gg_oz, gelir_n, by = "duzey")
esitlik <- rbind(es_top_oz[, .(strateji, c, duzey = "Total", olcu, tahmin, alt, ust, b_sayi)], gg_oz[, .(strateji, c, duzey, olcu, tahmin, alt, ust, b_sayi, n, n_pozitif)], fill = TRUE)
esitlik[, aciklama := "equal selection proportion across income groups: within each fold and income group the weighted share selected equals c; unconstrained: within-fold selection"]
fwrite(esitlik, "Results/esitlik_senaryosu.csv")
fwrite(esitlik[c == 0.20 & strateji %in% c("M0", "M1")], file.path(fvdir, "fig3b_esitlik.csv"))
print(es_top_oz[c == 0.20])

ag <- rbind(nokta$altgrup, boot$altgrup)
ag[, `:=`(yakalama = yakalanan / pozitif, secilen_dagilim = secilen / sum(secilen), nufus_payi = toplam / sum(toplam), prevalans = pozitif / toplam), by = .(b, strateji, degisken)]
ag_w <- dcast(ag[strateji %in% c("M0", "M1", "M2")], b + degisken + duzey ~ strateji, value.var = "yakalama")
ag_w[, `:=`(fark_M1_M0 = M1 - M0, fark_M2_M1 = M2 - M1)]
ag_oz <- rbind(nb_oz(ag, c("strateji", "degisken", "duzey"), c("yakalama", "secilen_dagilim", "nufus_payi", "prevalans")),
               nb_oz(ag_w[, .(b, degisken, duzey, strateji = "M1 − M0", fark = fark_M1_M0)], c("strateji", "degisken", "duzey"), "fark"),
               nb_oz(ag_w[, .(b, degisken, duzey, strateji = "M2 − M1", fark = fark_M2_M1)], c("strateji", "degisken", "duzey"), "fark"))
grup_n <- rbindlist(lapply(grup_deg, function(gv) a[, .(n = .N, n_pozitif = sum(phq_pos)), keyby = .(duzey = as.character(get(gv)))][, degisken := gv]))
ag_oz <- merge(ag_oz, grup_n, by = c("degisken", "duzey"))
ag_oz[, kucuk_hucre := fifelse(olcu %in% c("yakalama", "fark"), fifelse(n_pozitif < 20, "suppressed", fifelse(n_pozitif <= 50, "flag 20–50", "")),
                               fifelse(n < 20, "suppressed", fifelse(n <= 50, "flag 20–50", "")))]
ag_oz[kucuk_hucre == "suppressed", c("tahmin", "alt", "ust") := NA_real_]
ag_oz[, etiket := mapply(function(d, l) etk$kategori[[d]][[l]], degisken, duzey)]
ag_oz[, c := 0.20]
setorder(ag_oz, degisken, duzey, strateji, olcu)
fwrite(ag_oz, "Results/altgrup_kapsami.csv")
fwrite(ag_oz[strateji %in% c("M0", "M1", "M1 − M0") & olcu %in% c("yakalama", "fark")], file.path(fvdir, "fig3a_altgrup.csv"))

duy_b <- merge(rbind(nokta$duy, boot$duy), tp_all, by = "b")[, .(b, strateji, c, D = 1000 * yakalanan / toplam)]
duy_b <- rbind(duy_b, rbind(eg_n, eg_b)[strateji %in% c("M0", "M1", "M2") & c %in% kap3, .(b, strateji, c, D)])
duy_tanim <- data.table(
  analiz = c("Primary (fold assignment 1)", sprintf("A. Fold assignment %d", 2:5), "B. Pooled ranking across folds", "C. Weighted training (pseudo-posterior)", "D. Normal coefficient priors with SD 2.5",
             "E. Age as natural spline (3 df)", "F. Self-reported depression added"),
  kod = c("primary", paste0("A_r", 2:5), "B", "C", "D", "E", "F"),
  m0 = c("M0", paste0("M0_r", 2:5), "M0_havuz", "M0_agirlikli", "M0_oncel25", "M0_spline", "M0_depresyon"),
  m1 = c("M1", paste0("M1_r", 2:5), "M1_havuz", "M1_agirlikli", "M1_oncel25", "M1_spline", "M1_depresyon"),
  m2 = c("M2", paste0("M2_r", 2:5), "M2_havuz", NA, NA, NA, NA))
duy_tanim <- duy_tanim[m1 %in% unique(duy_b$strateji)]
duy_fark <- rbindlist(lapply(seq_len(nrow(duy_tanim)), function(i) {
  r <- duy_tanim[i]
  x <- merge(duy_b[strateji == r$m1, .(b, c, D1 = D)], duy_b[strateji == r$m0, .(b, c, D0 = D)], by = c("b", "c"))
  out <- x[, .(b, c, analiz = r$analiz, kod = r$kod, D_M0 = D0, D_M1 = D1, fark = D1 - D0, karsilastirma = "M1 − M0")]
  if (!is.na(r$m2) && r$m2 %in% duy_b$strateji) {
    x2 <- merge(duy_b[strateji == r$m2, .(b, c, D2 = D)], duy_b[strateji == r$m1, .(b, c, D1 = D)], by = c("b", "c"))
    out <- rbind(out, x2[, .(b, c, analiz = r$analiz, kod = r$kod, D_M0 = NA_real_, D_M1 = D1, fark = D2 - D1, karsilastirma = "M2 − M1")])
  }
  out
}))
duy_oz <- nb_oz(duy_fark, c("analiz", "kod", "karsilastirma", "c"), c("fark", "D_M0", "D_M1"))[!is.na(tahmin)]
a_dag <- duy_oz[kod %in% c("primary", paste0("A_r", 2:5)) & olcu == "fark", .(analiz = "A. Five fold assignments (mean and range of point estimates)", kod = "A_aralik", tahmin = mean(tahmin),
                                                                              alt = min(tahmin), ust = max(tahmin), b_sayi = .N), by = .(karsilastirma, c)][, olcu := "fark_5tekrar_ort_min_max"]
g_satir <- tekrar_oran[karsilastirma == "M1 − M0", .(analiz = sprintf("G. Practical-importance bound ±%s per 1,000", format(sinir)), kod = "G", karsilastirma, c,
                                                     olcu = c("bootstrap_oran_buyuk", "bootstrap_oran_icinde", "bootstrap_oran_kucuk"), tahmin = c(buyuk, icinde, kucuk)), by = sinir][, sinir := NULL]
h_satir <- yerel[, .(analiz = "H. Capacity window c ± 0.02 (step 0.005; point estimates)", kod = "H", karsilastirma, c, olcu = "fark_yerel_ort_min_max", tahmin = ort, alt = en_kucuk, ust = en_buyuk,
                     izgara_noktasi = nokta)]
duyarlilik <- rbind(duy_oz, a_dag, g_satir, h_satir, fill = TRUE)
duyarlilik[, aralik_turu := fcase(grepl("^bootstrap_oran", olcu), "bootstrap replicate proportion (not a posterior probability)",
                                  olcu == "fark_5tekrar_ort_min_max", "mean (min–max) over five split repeats",
                                  olcu == "fark_yerel_ort_min_max", "mean (min–max) of point estimates over capacities within ±0.02",
                                  default = "95% bootstrap CI (percentile)")]
fwrite(duyarlilik, "Results/Supplementary/duyarlilik.csv")
print(duyarlilik[c == 0.20 & olcu %in% c("fark", "fark_5tekrar_ort_min_max")])

mb_dosya <- file.path(odir, sprintf("model_temelli_delta_%s.rds", substr(rlang::hash(list(unname(tools::md5sum(cv_dosya(plan_cv[varyant == "ana" & tekrar == 1 & model != "M2"]))), y, w, Xa, a$kat_r1, sag, deparse(secim_kesri))), 1, 10)))
if (!file.exists(mb_dosya)) {
  mb <- sapply(c("M0", "M1"), function(m) {
    Dm <- 0
    for (k in 1:10) {
      i <- which(a$kat_r1 == k)
      dm <- readRDS(cv_dosya(plan_cv[model == m & varyant == "ana" & tekrar == 1 & kat == k]))$cek
      P <- plogis(as.numeric(dm[, "b_Intercept"]) + dm[, paste0("b_", sag[[m]]), drop = FALSE] %*% t(Xa[i, sag[[m]], drop = FALSE]))
      Dm <- Dm + vapply(seq_len(nrow(P)), function(d) sum(w[i] * secim_kesri(P[d, ], w[i], 0.20) * y[i]), 0)
    }
    1000 * Dm / sum(w)
  })
  saveRDS(mb, mb_dosya)
}
mb <- readRDS(mb_dosya)
mb_delta <- mb[, "M1"] - mb[, "M0"]
model_temelli <- data.table(buyukluk = c("D_M0(0.20)", "D_M1(0.20)", "Delta(0.20) = M1 − M0"), medyan = c(median(mb[, "M0"]), median(mb[, "M1"]), median(mb_delta)),
                            alt = c(alt(mb[, "M0"]), alt(mb[, "M1"]), alt(mb_delta)), ust = c(ust(mb[, "M0"]), ust(mb[, "M1"]), ust(mb_delta)), cekilis = nrow(mb),
                            etiket = "Model-based distribution over 1,000 thinned outer-fold posterior draws (repeat 1), conditional on the fixed data and fold assignments; not a bootstrap interval")
print(model_temelli)
fwrite(model_temelli, "Results/Supplementary/model_temelli_delta.csv")
fwrite(rbind(data.table(kaynak = "bootstrap", deger = d20), data.table(kaynak = "model_temelli", deger = mb_delta)), file.path(fvdir, "figS_delta_dagilimlari.csv"))

set.seed(20261141L)
cv1 <- cvl[varyant == "ana" & tekrar == 1][match(paste(rep(c("M0", "M1", "M2"), each = nrow(a)), rep(a$id, 3)), paste(model, id))]
mc_tekrar <- 200L
mc_d <- rbindlist(lapply(seq_len(mc_tekrar), function(r) {
  Dm <- vapply(c("M0", "M1", "M2"), function(m) {
    x <- cv1[model == m]
    anahtar <- paste(x$kat, x$desen)
    z <- rnorm(uniqueN(anahtar))[match(anahtar, unique(anahtar))]
    1000 * sum(w * tabakali_secim(x$p_hat + z * x$mcse, w, 0.20, a$kat_r1) * y) / sum(w)
  }, 0)
  data.table(tekrar = r, M1_M0 = Dm[["M1"]] - Dm[["M0"]], M2_M1 = Dm[["M2"]] - Dm[["M1"]])
}))
mc_ozet <- data.table(karsilastirma = c("M1 − M0", "M2 − M1"), nokta = c(fark_oz[karsilastirma == "M1 − M0" & c == 0.20 & olcu == "fark", tahmin], fark_oz[karsilastirma == "M2 − M1" & c == 0.20 & olcu == "fark", tahmin]),
                      mc_sd = c(sd(mc_d$M1_M0), sd(mc_d$M2_M1)), mc_en_buyuk_sapma = c(max(abs(mc_d$M1_M0 - mean(mc_d$M1_M0))), max(abs(mc_d$M2_M1 - mean(mc_d$M2_M1)))),
                      p_hat_mcse_medyan = median(cv1$mcse), p_hat_mcse_max = max(cv1$mcse), tekrar = mc_tekrar)
print(mc_ozet)
fwrite(mc_ozet, "Results/denetim/mcse_delta_denetimi.csv")
sure_ekle("eşitlik, alt grup, duyarlılık, model temelli Δ, MC hatası", t0)

t0 <- Sys.time()
suppressPackageStartupMessages(library(WeightedROC))
auc_agirlikli <- function(s, yy, W) {
  Wm <- if (is.null(dim(W))) matrix(W, ncol = 1L) else W
  g <- match(s, sort(unique(s)))
  Wp <- rowsum(Wm * yy, g, reorder = TRUE)
  Wn <- rowsum(Wm * (1 - yy), g, reorder = TRUE)
  Cn <- matrix(apply(Wn, 2L, cumsum), nrow = nrow(Wn)) - Wn
  colSums(Wp * (Cn + 0.5 * Wn)) / (colSums(Wp) * colSums(Wn))
}
kal_f <- function(p, yy, ww) {
  lp <- qlogis(p)
  wn <- ww / mean(ww)
  e <- glm.fit(cbind(1, lp), yy, weights = wn, family = quasibinomial())$coefficients[2]
  k <- glm.fit(matrix(1, length(yy), 1), yy, weights = wn, offset = lp, family = quasibinomial())$coefficients[1]
  c(egim = unname(e), kesisim = unname(k), oe = sum(ww * yy) / sum(ww * p))
}
perf_skor <- list(M0 = skor$M0, M1 = skor$M1, M2 = skor$M2, PHQ2 = skor$PHQ2)
auc_nokta <- vapply(perf_skor, function(s) WeightedAUC(WeightedROC(s, y, w)), 0)
auc_kendi <- vapply(perf_skor, function(s) auc_agirlikli(s, y, w), 0)
kontrol("Ağırlıklı AUC: WeightedROC ile ağırlıklı Mann–Whitney özdeşliği (en büyük fark < 1e−10)", 0L, sum(abs(auc_nokta - auc_kendi) > 1e-10), kaynak = "analist")
perf_dosya <- file.path(odir, sprintf("perf_boot_%s.rds", substr(rlang::hash(list(perf_skor, y, w, hh_i, Mh, deparse(kal_f), deparse(auc_agirlikli))), 1, 10)))
if (!file.exists(perf_dosya)) {
  parcalar <- split(seq_len(B_boot), ceiling(seq_len(B_boot) / 100L))
  plan(multisession, workers = 14L)
  pb <- future_map(parcalar, function(cols) {
    Wm <- w * Mh[hh_i, cols, drop = FALSE]
    au <- sapply(perf_skor, function(s) auc_agirlikli(s, y, Wm))
    kl <- rbindlist(lapply(c("M0", "M1", "M2"), function(m) rbindlist(lapply(seq_along(cols), function(k) {
      i <- Wm[, k] > 0
      as.data.table(as.list(kal_f(perf_skor[[m]][i], y[i], Wm[i, k])))[, `:=`(b = cols[k], model = m)]
    }))))
    list(auc = data.table(b = cols, au), kal = kl)
  }, .options = furrr_options(seed = NULL, scheduling = Inf, packages = c("data.table", "stats")))
  plan(sequential)
  saveRDS(list(auc = rbindlist(lapply(pb, `[[`, "auc")), kal = rbindlist(lapply(pb, `[[`, "kal"))), perf_dosya)
}
pb <- readRDS(perf_dosya)
kal_n <- rbindlist(lapply(c("M0", "M1", "M2"), function(m) as.data.table(as.list(kal_f(perf_skor[[m]], y, w)))[, model := m]))
auc_b <- melt(pb$auc, id.vars = "b", variable.name = "model", value.name = "AUC")
auc_b <- rbind(auc_b, dcast(auc_b, b ~ model, value.var = "AUC")[, .(model = c("M1 − M0", "M2 − M1"), AUC = c(M1 - M0, M2 - M1)), by = b])
auc_n <- data.table(model = c(names(auc_nokta), "M1 − M0", "M2 − M1"), AUC = c(auc_nokta, auc_nokta[["M1"]] - auc_nokta[["M0"]], auc_nokta[["M2"]] - auc_nokta[["M1"]]))
performans <- rbind(
  merge(auc_n, auc_b[, .(alt = alt(AUC), ust = ust(AUC), b_medyan = median(AUC)), by = model], by = "model")[, .(model, olcu = "AUC", tahmin = AUC, alt, ust, b_medyan)],
  merge(melt(kal_n, id.vars = "model", variable.name = "olcu", value.name = "tahmin"),
        melt(pb$kal, id.vars = c("b", "model"), variable.name = "olcu")[, .(alt = alt(value), ust = ust(value), b_medyan = median(value)), by = .(model, olcu)], by = c("model", "olcu")))
performans[, `:=`(aralik_turu = sprintf("95%% bootstrap CI (percentile, household cluster bootstrap, B = %s)", format(B_boot, big.mark = ",")), tahmin_kaynagi = "outer-fold predictions, repeat 1, weighted")]
print(performans)
fwrite(performans, "Results/Supplementary/performans.csv")
dilim <- function(p, ww) {
  o <- order(p)
  cw <- cumsum(ww[o]) / sum(ww)
  d <- integer(length(p))
  d[o] <- pmin(10L, pmax(1L, ceiling(cw * 10 - 1e-9)))
  d
}
kalibrasyon <- rbindlist(lapply(c("M0", "M1", "M2"), function(m) {
  dd <- data.table(p = perf_skor[[m]], y = y, w = w, dl = dilim(perf_skor[[m]], w))
  dd[, .(n = .N, n_pozitif = sum(y), beklenen = sum(w * p) / sum(w), gozlenen = sum(w * y) / sum(w)), keyby = dl][, model := m]
}))
fwrite(rbind(kalibrasyon, kal_n[, .(model, egim, kesisim, oe)], fill = TRUE), "Results/Supplementary/kalibrasyon.csv")
fwrite(kalibrasyon, file.path(fvdir, "figS_kalibrasyon.csv"))
say$performans <- lapply(split(performans, by = c("model", "olcu"), keep.by = FALSE, drop = TRUE), function(x) as.list(x[, .(tahmin, alt, ust)]))
sure_ekle("ayrım ve kalibrasyon", t0)

suppressPackageStartupMessages({
  library(flextable)
  library(officer)
  library(openxlsx)
})
yuv0 <- function(x, d) { x <- round(x, d); x[!is.na(x) & x == 0] <- 0; x }
f1 <- function(x) formatC(yuv0(x, 1), format = "f", digits = 1, big.mark = ",")
f2 <- function(x) formatC(yuv0(x, 2), format = "f", digits = 2, big.mark = ",")
nfmt <- function(n) formatC(n, format = "d", big.mark = ",")
sinir_f <- function(x, d) ifelse(!is.na(x) & x < 0 & round(x, d) == 0, paste0("-", formatC(0, format = "f", digits = d)), formatC(yuv0(x, d), format = "f", digits = d))
ga <- function(e, l, u, d = 1) paste0(formatC(yuv0(e, d), format = "f", digits = d), " (", sinir_f(l, d), ", ", sinir_f(u, d), ")")
pfmt <- function(p) fifelse(is.na(p), "", fifelse(p < 0.001, "<0.001", formatC(p, format = "f", digits = 3)))
yazi_tipi_t <- "Times New Roman"
tablo_bicim <- function(ft, notlar = character(0), grup_satir = integer(0)) {
  ft <- font(ft, fontname = yazi_tipi_t, part = "all")
  ft <- fontsize(ft, size = 9, part = "all")
  ft <- border_remove(ft)
  ust <- fp_border(color = "black", width = 1)
  ince <- fp_border(color = "black", width = 0.5)
  ft <- hline_top(ft, border = ust, part = "header")
  ft <- hline_bottom(ft, border = ince, part = "header")
  ft <- hline_bottom(ft, border = ust, part = "body")
  ft <- bold(ft, part = "header")
  ft <- align(ft, align = "center", part = "header")
  ft <- align(ft, j = 1, align = "left", part = "all")
  ft <- valign(ft, valign = "center", part = "header")
  ft <- padding(ft, padding.top = 1, padding.bottom = 1, part = "all")
  if (length(grup_satir)) ft <- bold(ft, i = grup_satir, j = 1, part = "body")
  for (k in seq_along(notlar)) ft <- add_footer_lines(ft, values = notlar[k])
  if (length(notlar)) {
    ft <- fontsize(ft, size = 8, part = "footer")
    ft <- font(ft, fontname = yazi_tipi_t, part = "footer")
  }
  ft <- autofit(ft)
  ft
}
simge_re <- "(_|\\^)\\{([^}]*)\\}"
duz_csv <- function(x) gsub("\\^\\{([^}]*)\\}", " [\\1]", gsub("_\\{([^}]*)\\}", "_\\1", x))
duz <- function(x) gsub(simge_re, "\\2", x)
parcala <- function(s) {
  m <- gregexpr(simge_re, s, perl = TRUE)[[1]]
  bas <- c(1, m + attr(m, "match.length"))
  out <- list()
  for (k in seq_along(m)) {
    if (m[k] > bas[k]) out[[length(out) + 1]] <- as_chunk(substr(s, bas[k], m[k] - 1))
    tok <- substr(s, m[k], m[k] + attr(m, "match.length")[k] - 1)
    ic <- sub(simge_re, "\\2", tok)
    out[[length(out) + 1]] <- if (substr(tok, 1, 1) == "_") as_sub(ic) else as_sup(ic)
  }
  if (bas[length(bas)] <= nchar(s)) out[[length(out) + 1]] <- as_chunk(substr(s, bas[length(bas)], nchar(s)))
  out
}
simge_uygula <- function(ft, disp, notlar, ust_lab = NULL) {
  for (j in seq_len(ncol(disp))) for (i in which(grepl(simge_re, disp[[j]]))) ft <- compose(ft, i = i, j = j, part = "body", value = do.call(as_paragraph, parcala(disp[[j]][i])))
  for (k in which(grepl(simge_re, notlar))) ft <- compose(ft, i = k, j = 1, part = "footer", value = do.call(as_paragraph, parcala(notlar[k])))
  hi <- nrow_part(ft, "header")
  for (j in which(grepl(simge_re, names(disp)))) ft <- compose(ft, i = hi, j = j, part = "header", value = do.call(as_paragraph, parcala(trimws(names(disp)[j]))))
  ft
}
tablo_yaz <- function(ft, dosya, baslik, yatay = FALSE) {
  doc <- read_docx()
  doc <- body_set_default_section(doc, prop_section(page_size = page_size(orient = if (yatay) "landscape" else "portrait"), page_margins = page_mar(top = 0.8, bottom = 0.8, left = 0.8, right = 0.8)))
  etiket <- regmatches(baslik, regexpr("^Table S?[0-9]+[ab]?\\.", baslik))
  doc <- body_add_fpar(doc, fpar(ftext(etiket, prop = fp_text(font.family = yazi_tipi_t, font.size = 10, bold = TRUE)),
                                 ftext(substring(baslik, nchar(etiket) + 1), prop = fp_text(font.family = yazi_tipi_t, font.size = 10))))
  doc <- body_add_flextable(doc, ft)
  print(doc, target = dosya)
}
wb <- createWorkbook()
xl_stil <- list(
  govde = createStyle(fontName = yazi_tipi_t, fontSize = 9, valign = "center"),
  baslik = createStyle(fontName = yazi_tipi_t, fontSize = 9, textDecoration = "bold", halign = "center", valign = "center", wrapText = TRUE),
  ust = createStyle(border = "top", borderStyle = "medium"),
  alt_ince = createStyle(border = "bottom", borderStyle = "thin"),
  alt_kalin = createStyle(border = "bottom", borderStyle = "medium"),
  not = createStyle(fontName = yazi_tipi_t, fontSize = 8),
  kalin = createStyle(textDecoration = "bold"),
  girinti = createStyle(indent = 1),
  tbaslik = createStyle(fontName = yazi_tipi_t, fontSize = 10, textDecoration = "bold")
)
tablo_listesi <- list()
metin_inc <- function(x, kalin = FALSE) {
  x <- duz(as.character(x))
  x[is.na(x)] <- ""
  vapply(x, function(s) {
    ch <- strsplit(s, "")[[1]]
    if (!length(ch)) return(0)
    w <- rep(0.5, length(ch))
    w[grepl("^[a-z]$", ch)] <- 0.47
    w[ch %in% c("i", "j", "l", "t")] <- 0.28
    w[ch %in% c("f", "r")] <- 0.34
    w[ch %in% c("m", "w")] <- 0.75
    w[grepl("^[A-Z]$", ch)] <- 0.68
    w[ch %in% c("I", "J")] <- 0.36
    w[ch %in% c("M", "W")] <- 0.9
    w[ch %in% c(" ", " ", ".", ",", ":", ";", "'")] <- 0.25
    w[ch %in% c("(", ")", "[", "]", "-", "/")] <- 0.333
    w[ch %in% c("=", "+", "<", ">", "−", "≤", "≥", "±", "×", "Δ")] <- 0.6
    w[ch == "%"] <- 0.833
    w[ch == "—"] <- 1
    w[ch == "|"] <- 0.2
    sum(w) * 0.125 * if (kalin) 1.06 else 1
  }, 0, USE.NAMES = FALSE)
}
tablo_cikar <- function(disp, ad, baslik, ust = NULL, notlar = character(0), grup_satir = integer(0), girinti = integer(0), yatay = FALSE, klasor = "Results", soluk = integer(0), orta = TRUE, ilk_gen = NULL) {
  disp <- as.data.frame(disp, stringsAsFactors = FALSE, check.names = FALSE)
  disp[] <- lapply(disp, function(x) gsub("(^|[ (\\[,;])-([0-9.])", "\\1−\\2", x))
  notlar <- gsub("(^|[ (\\[,;])-([0-9.])", "\\1−\\2", notlar)
  ft <- flextable(disp)
  jj_cizgi <- integer(0)
  if (!is.null(ust)) {
    seg <- rep(ust$degerler, ust$genislik)
    alt_lab <- trimws(names(disp))
    alt_lab[ust$dikey] <- seg[ust$dikey]
    ft <- set_header_df(ft, mapping = data.frame(col_keys = names(disp), ust = seg, alt = alt_lab, stringsAsFactors = FALSE), key = "col_keys")
    ft <- merge_h(ft, i = 1, part = "header")
    ft <- merge_v(ft, j = ust$dikey, part = "header")
    bas_j <- cumsum(c(1, head(ust$genislik, -1)))
    jj_cizgi <- unlist(lapply(which(ust$genislik > 1), function(k) bas_j[k]:(bas_j[k] + ust$genislik[k] - 1)))
  } else {
    ft <- set_header_labels(ft, values = setNames(as.list(trimws(names(disp))), names(disp)))
  }
  ft <- tablo_bicim(ft, duz(notlar), grup_satir)
  ft <- simge_uygula(ft, disp, notlar)
  if (!is.null(ust)) {
    bas_j <- cumsum(c(1, head(ust$genislik, -1)))
    for (k in which(grepl(simge_re, ust$degerler) & !(bas_j %in% ust$dikey))) ft <- compose(ft, i = 1, j = bas_j[k], part = "header", value = do.call(as_paragraph, parcala(ust$degerler[k])))
    for (j in intersect(ust$dikey, which(grepl(simge_re, rep(ust$degerler, ust$genislik))))) ft <- compose(ft, i = 1, j = j, part = "header", value = do.call(as_paragraph, parcala(rep(ust$degerler, ust$genislik)[j])))
  }
  ft <- font(ft, fontname = yazi_tipi_t, part = "all")
  ft <- fontsize(ft, size = 8, part = "footer")
  if (length(soluk)) {
    ft <- color(ft, i = soluk, color = "#5A5A5A", part = "body")
    ft <- italic(ft, i = soluk, part = "body")
  }
  dar <- ncol(disp) >= 9
  if (dar) ft <- padding(ft, padding.left = 2, padding.right = 2, part = "all")
  if (length(girinti)) ft <- padding(ft, i = girinti, j = 1, padding.left = 12, part = "body")
  if (length(jj_cizgi)) ft <- hline(ft, i = 1, j = jj_cizgi, border = fp_border(color = "black", width = 0.5), part = "header")
  ft <- align(ft, j = 1, align = "left", part = "header")
  if (orta && ncol(disp) > 1) ft <- align(ft, j = 2:ncol(disp), align = "center", part = "body")
  pad <- if (dar) 0.21 else 0.32
  bas_m <- lapply(seq_len(ncol(disp)), function(j) trimws(names(disp)[j]))
  if (!is.null(ust)) {
    tek <- which(rep(ust$genislik, ust$genislik) == 1)
    ust_m <- rep(ust$degerler, ust$genislik)
    for (j in tek) bas_m[[j]] <- unique(c(bas_m[[j]], ust_m[j]))
  }
  govde_g <- vapply(seq_len(ncol(disp)), function(j) max(c(0, metin_inc(disp[[j]]))), 0) + pad
  if (length(girinti)) govde_g[1] <- max(c(0, metin_inc(disp[[1]][girinti]) + 7 / 72, metin_inc(disp[[1]][setdiff(seq_len(nrow(disp)), c(girinti, grup_satir))]))) + pad
  govde_g <- pmin(govde_g, c(3.6, rep(3.2, ncol(disp) - 1)))
  if (length(grup_satir) && ncol(disp) > 1) for (i in grup_satir) ft <- merge_at(ft, i = i, j = seq_len(ncol(disp)), part = "body")
  if (length(grup_satir)) ft <- align(ft, i = grup_satir, j = 1, align = "left", part = "body")
  bas_tam <- vapply(bas_m, function(b) max(metin_inc(b, kalin = TRUE)), 0) + pad
  bas_kelime <- vapply(bas_m, function(b) max(metin_inc(unlist(strsplit(b, " ")), kalin = TRUE)), 0) + pad
  tam <- pmax(govde_g, bas_tam, 0.45)
  en_az <- pmax(govde_g, bas_kelime, 0.45)
  en_az[1] <- max(bas_kelime[1], min(govde_g[1], 1.5))
  maks <- if (yatay) 9.6 else 6.9
  sar <- vapply(seq_len(ncol(disp)), function(j) any(grepl("[A-Za-z]{3,} [A-Za-z(]", duz(disp[[j]]))), NA)
  sar[1] <- FALSE
  kelime_g <- vapply(seq_len(ncol(disp)), function(j) max(c(0, metin_inc(unlist(strsplit(duz(disp[[j]]), " "))))), 0) + pad
  sar_alt <- pmax(bas_kelime, kelime_g, 1.1)
  daralt <- function(g, alt, j, fazla) {
    pay <- pmax(g[j] - alt[j], 0)
    if (!length(j) || sum(pay) <= 0 || fazla <= 0) return(g)
    g[j] <- g[j] - pay * min(1, fazla / sum(pay))
    g
  }
  gen <- tam
  if (sum(gen) > maks) gen[-1] <- en_az[-1]
  if (sum(gen) > maks) gen <- daralt(gen, replace(en_az, 1, max(en_az[1], min(tam[1], 2))), 1, sum(gen) - maks)
  if (sum(gen) > maks) gen <- daralt(gen, sar_alt, which(sar), sum(gen) - maks)
  if (sum(gen) > maks) gen <- daralt(gen, en_az, 1, sum(gen) - maks)
  if (sum(gen) > maks) {
    gen <- gen * maks / sum(gen)
  } else if (sum(gen) < maks && any(gen[-1] < tam[-1])) {
    ek <- tam[-1] - gen[-1]
    gen[-1] <- gen[-1] + ek * min(1, (maks - sum(gen)) / sum(ek))
  }
  if (!is.null(ilk_gen)) {
    gen[1] <- ilk_gen
    gen[-1] <- (maks - ilk_gen) / (length(gen) - 1)
  }
  bos_s <- which(trimws(names(disp)) == "")
  if (length(bos_s)) {
    fazla <- sum(gen[bos_s]) - 0.1 * length(bos_s)
    gen[bos_s] <- 0.1
    gen[-c(1, bos_s)] <- gen[-c(1, bos_s)] + fazla / (length(gen) - 1 - length(bos_s))
  }
  ft <- width(ft, width = gen)
  tablo_yaz(ft, file.path(klasor, paste0(ad, ".docx")), baslik, yatay)
  names(disp) <- gsub(" ", " ", names(disp), fixed = TRUE)
  disp_x <- disp
  notlar_x <- notlar
  disp[] <- lapply(disp, duz_csv)
  csv_ad <- trimws(names(disp))
  if (!is.null(ust)) csv_ad <- ifelse(rep(ust$genislik, ust$genislik) > 1, paste(rep(ust$degerler, ust$genislik), csv_ad), csv_ad)
  csv_tut <- trimws(names(disp)) != ""
  fwrite(setNames(disp, duz_csv(csv_ad))[, csv_tut, drop = FALSE], file.path(klasor, paste0(ad, ".csv")))
  if (length(notlar)) cat(c("", paste0("\"Note: ", gsub("\"", "\"\"", trimws(duz_csv(notlar))), "\""), ""), file = file.path(klasor, paste0(ad, ".csv")), sep = "\n", append = TRUE)
  sayfa <- ad
  addWorksheet(wb, sayfa)
  writeData(wb, sayfa, baslik, startRow = 1, startCol = 1)
  addStyle(wb, sayfa, xl_stil$tbaslik, rows = 1, cols = 1)
  r0 <- 3
  nc <- ncol(disp)
  if (!is.null(ust)) {
    bas <- unlist(mapply(function(v, w) c(v, rep("", w - 1)), ust$degerler, ust$genislik))
    writeData(wb, sayfa, t(bas), startRow = r0, startCol = 1, colNames = FALSE)
    cc <- 1
    for (k in seq_along(ust$genislik)) {
      if (ust$genislik[k] > 1) mergeCells(wb, sayfa, cols = cc:(cc + ust$genislik[k] - 1), rows = r0)
      cc <- cc + ust$genislik[k]
    }
    for (j in ust$dikey) {
      mergeCells(wb, sayfa, cols = j, rows = r0:(r0 + 1))
      writeData(wb, sayfa, trimws(names(disp)[j]), startRow = r0, startCol = j)
    }
    addStyle(wb, sayfa, xl_stil$baslik, rows = r0, cols = 1:nc, gridExpand = TRUE)
    addStyle(wb, sayfa, xl_stil$ust, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
    r0 <- r0 + 1
    hdr <- trimws(names(disp))
    hdr[ust$dikey] <- ""
    writeData(wb, sayfa, t(hdr), startRow = r0, startCol = 1, colNames = FALSE)
  } else {
    writeData(wb, sayfa, t(trimws(names(disp))), startRow = r0, startCol = 1, colNames = FALSE)
    addStyle(wb, sayfa, xl_stil$ust, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  }
  addStyle(wb, sayfa, xl_stil$baslik, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sayfa, xl_stil$alt_ince, rows = r0, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  writeData(wb, sayfa, disp_x, startRow = r0 + 1, startCol = 1, colNames = FALSE)
  addStyle(wb, sayfa, xl_stil$govde, rows = (r0 + 1):(r0 + nrow(disp)), cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  if (orta && nc > 1) addStyle(wb, sayfa, createStyle(halign = "center"), rows = (r0 + 1):(r0 + nrow(disp)), cols = 2:nc, gridExpand = TRUE, stack = TRUE)
  addStyle(wb, sayfa, xl_stil$alt_kalin, rows = r0 + nrow(disp), cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  if (length(grup_satir)) addStyle(wb, sayfa, xl_stil$kalin, rows = r0 + grup_satir, cols = 1, stack = TRUE)
  if (length(grup_satir) && nc > 1) for (i in grup_satir) {
    mergeCells(wb, sayfa, cols = 1:nc, rows = r0 + i)
    addStyle(wb, sayfa, createStyle(halign = "left"), rows = r0 + i, cols = 1, stack = TRUE)
  }
  if (length(soluk)) addStyle(wb, sayfa, createStyle(fontColour = "#5A5A5A", textDecoration = "italic"), rows = r0 + soluk, cols = 1:nc, gridExpand = TRUE, stack = TRUE)
  if (length(girinti)) addStyle(wb, sayfa, xl_stil$girinti, rows = r0 + girinti, cols = 1, stack = TRUE)
  if (length(notlar)) {
    writeData(wb, sayfa, notlar_x, startRow = r0 + nrow(disp) + 1, startCol = 1)
    addStyle(wb, sayfa, xl_stil$not, rows = r0 + nrow(disp) + seq_along(notlar), cols = 1, stack = TRUE)
  }
  setColWidths(wb, sayfa, cols = 1:nc, widths = c(48, rep(16, nc - 1)))
  tablo_listesi[[ad]] <<- disp
  invisible(ft)
}

t0 <- Sys.time()
py <- Sys.getenv("PY_YORUMLAYICI", if (file.exists(path.expand("~/veri-ortami/bin/python3"))) path.expand("~/veri-ortami/bin/python3") else "python3")
ek_kl <- "Results/Supplementary"
ek_no <- c(degisken = "S1", eksik = "S2", model = "S3", katsayi = "S4", yazilim = "S5", performans = "S6", bootstrap = "S7", duyarlilik = "S8", altgrup = "S9", esitlik = "S10", grup470 = "S11")
kucuk <- function(deger, n) fifelse(n < 20, "–", fifelse(n <= 50, paste0(deger, "^{a}"), deger))
kucuk_n <- function(n, yuzde) fifelse(n < 20, paste0(nfmt(n), " (–)"), fifelse(n <= 50, paste0(nfmt(n), " (", f1(yuzde), ")^{a}"), paste0(nfmt(n), " (", f1(yuzde), ")")))
ga2 <- function(e, l, u) ga(e, l, u, 2)
yuzde_f <- function(x) f1(100 * x)
ga1 <- function(e, l, u, d = 1) ga(e, l, u, d)
gay <- function(e, l, u) ga(100 * e, 100 * l, 100 * u, 1)
n_poz <- sum(a$phq_pos)
n_neg <- nrow(a) - n_poz

t1_disp <- list()
grup_i <- integer(0)
gir_i <- integer(0)
for (v in unique(table1$degisken)) {
  x <- table1[degisken == v]
  t1_disp[[length(t1_disp) + 1]] <- data.table(k = x$degisken_etiket[1], t = "", p = "", n = "")
  grup_i <- c(grup_i, sum(vapply(t1_disp, nrow, 0L)))
  for (i in seq_len(nrow(x))) {
    r <- x[i]
    hc <- if (r$tur == "ortalama") c(r$ort_toplam, r$ort_pozitif, r$ort_negatif) else
      c(kucuk_n(r$n_toplam, r$yuzde_toplam), kucuk_n(r$n_pozitif, r$yuzde_pozitif), kucuk_n(r$n_negatif, r$yuzde_negatif))
    t1_disp[[length(t1_disp) + 1]] <- data.table(k = r$etiket, t = hc[1], p = hc[2], n = hc[3])
    gir_i <- c(gir_i, sum(vapply(t1_disp, nrow, 0L)))
  }
}
t1_disp <- rbindlist(t1_disp)
setnames(t1_disp, c("Characteristic", sprintf("Total (n = %s)", nfmt(nrow(a))), sprintf("PHQ-8 ≥ 10 (n = %s)", nfmt(n_poz)), sprintf("PHQ-8 < 10 (n = %s)", nfmt(n_neg))))
tablo_cikar(t1_disp, "Table1", sprintf("Table 1. Characteristics of the analysis frame (eligible adults with complete predictor data) by PHQ-8 positivity, Türkiye Health Survey 2022 (n = %s adults in %s households).", nfmt(nrow(a)), nfmt(uniqueN(a$hh))),
            notlar = c("Values are n (%) unless stated otherwise; n, unweighted count; %, column percentage weighted by the individual survey weight. Day counts are weighted means (SD).",
                       "PHQ-8, eight-item Patient Health Questionnaire depression scale; PHQ-8 ≥ 10, high depressive-symptom burden. Eligible adults: aged ≥ 18 years, saw a general practitioner or family physician in the past 12 months, and reported no psychologist, psychotherapist or psychiatrist visit in the past 12 months.",
                       sprintf("Household income groups combine the 20 survey income bands at weighted cumulative shares closest to 20%%, 40%%, 60%% and 80%% (bands %s; Table %s).", paste(gelir_grup$bantlar, collapse = ", "), ek_no[["degisken"]]),
                       "^{a} Percentage based on 20–50 unweighted observations; (–) percentage not shown for cells with fewer than 20 unweighted observations."),
            grup_satir = grup_i, girinti = gir_i)

st_sira <- c("rastgele", "PHQ2", "M0", "M1", "M2")
t2 <- list()
t2_grup <- integer(0)
t2_gir <- integer(0)
for (cc in kap3) {
  t2[[length(t2) + 1]] <- data.table(s = sprintf("Capacity %d%% (%s per 1,000 invited)", round(100 * cc), nfmt(round(1000 * cc))), D = "", S = "", P = "", F = "")
  t2_grup <- c(t2_grup, sum(vapply(t2, nrow, 0L)))
  for (st in st_sira) {
    e <- egri_oz[strateji == st & c == cc]
    fk <- fark_oz[karsilastirma == paste(st, "−", "M0") & c == cc & olcu == "fark"]
    etiket <- etk$strateji[[st]]
    if (st == "rastgele") etiket <- paste0(etiket, "^{b}")
    if (st == "PHQ2") etiket <- paste0(etiket, "^{c}")
    fark_h <- if (st == "M0") "Reference" else fk[, ga2(tahmin, alt, ust)]
    if (st == "M1" && cc == 0.20) fark_h <- paste0(fark_h, "^{a}")
    t2[[length(t2) + 1]] <- data.table(s = etiket, D = e[olcu == "D", ga1(tahmin, alt, ust)], S = if (st == "rastgele") f1(100 * cc) else e[olcu == "Sens", gay(tahmin, alt, ust)],
                                       P = e[olcu == "PPV", gay(tahmin, alt, ust)], F = fark_h)
    t2_gir <- c(t2_gir, sum(vapply(t2, nrow, 0L)))
  }
  fk <- fark_oz[karsilastirma == "M2 − M1" & c == cc & olcu == "fark"]
  t2[[length(t2) + 1]] <- data.table(s = "M2 − M1", D = "", S = "", P = "", F = fk[, ga2(tahmin, alt, ust)])
  t2_gir <- c(t2_gir, sum(vapply(t2, nrow, 0L)))
}
t2 <- rbindlist(t2)
setnames(t2, c("Strategy", "Detection yield per 1,000 (95% CI)", "Sensitivity at capacity, % (95% CI)", "PPV among selected, % (95% CI)", "Difference in detection yield per 1,000 (95% CI)"))
p2t <- p2_oz[, setNames(tahmin, olcu)]
d30 <- fark_oz[karsilastirma == "M1 − M0" & c == 0.30 & olcu == "fark"]
a5_t2 <- duyarlilik[kod == "A_aralik" & c == 0.20]
tablo_cikar(t2, "Table2", "Table 2. Detection yield, sensitivity and positive predictive value at prespecified assessment capacities, by prioritization strategy.",
            notlar = c(sprintf("Detection yield: selected PHQ-8–positive adults per 1,000 eligible adults. Detection yield, sensitivity and PPV are three scales of the same captured quantity: D = 1,000 × p × sensitivity = 1,000 × c × PPV, where p = %.4f is the weighted share with PHQ-8 ≥ 10 and c the capacity (for point estimates and within each bootstrap replicate); at 10%% capacity, PPV (%%) and detection yield therefore coincide numerically.", say$p),
                       "PHQ-8 and PHQ-2, eight- and two-item Patient Health Questionnaire depression scales; PPV, positive predictive value; CI, confidence interval. Differences are relative to M0 within each capacity block, except the M2 − M1 rows.",
                       "Model rankings use outer-fold posterior mean probabilities from 10-fold household-blocked cross-validation (first, primary fold assignment); selection is made within each fold at the weighted (1 − c) quantile, with fractional inclusion of the boundary group. Capacities are planning scenarios, not measured service capacities.",
                       sprintf("95%% CI: percentile interval from a paired household cluster bootstrap (%s replicates), conditional on the fixed model fits and fold assignments; it does not include model-development uncertainty. The bootstrap distribution can be asymmetric; for M1 − M0 at 30%% capacity its median is %.2f. Across five fold assignments, the point estimate of Δ(0.20) averaged %s (range %s to %s) and that of M2 − M1 at 20%% capacity %s (range %s to %s).",
                               nfmt(B_boot), d30$b_medyan, f2(a5_t2[karsilastirma == "M1 − M0", tahmin]), f2(a5_t2[karsilastirma == "M1 − M0", alt]), f2(a5_t2[karsilastirma == "M1 − M0", ust]),
                               f2(a5_t2[karsilastirma == "M2 − M1", tahmin]), f2(a5_t2[karsilastirma == "M2 − M1", alt]), f2(a5_t2[karsilastirma == "M2 − M1", ust])),
                       sprintf("^{a} Primary result: Δ(0.20) = D_{M1}(0.20) − D_{M0}(0.20); prespecified practical-importance bound ±1 per 1,000. ^{b} Analytic: D = 1,000 × c × p and sensitivity = c; the intervals for D and PPV reflect bootstrap variation in p only. ^{c} Symptom-based comparator sharing two items with the PHQ-8; not an upper bound. The PHQ-2 ≥ 3 rule implies a capacity of %.2f%% (detection yield %.1f per 1,000; sensitivity %.1f%%; PPV %.1f%%). Perfect ranking (population-level upper bound): D = 1,000 × min(c, p) = %.1f per 1,000 at every capacity shown; the upper bound under within-fold selection is the same at these capacities.",
                               100 * p2t[["c"]], p2t[["D"]], 100 * p2t[["Sens"]], 100 * p2t[["PPV"]], 1000 * say$p)),
            grup_satir = t2_grup, girinti = t2_gir, yatay = TRUE)
sure_ekle("ana tablolar", t0)

t0 <- Sys.time()
s1 <- degisken_tanimlari[, .(Variable = etiket, `Source variable(s)` = kaynak, Coding = kodlama, Reference = referans, `Used in` = modeller)]
tablo_cikar(s1, paste0("Table", ek_no[["degisken"]], "_degisken_tanimlari"), sprintf("Table %s. Variable definitions and coding.", ek_no[["degisken"]]), klasor = ek_kl, yatay = TRUE, orta = FALSE,
            notlar = c("Source variables are those of the Türkiye Health Survey 2022 microdata (TurkStat). Codes are the raw codes of the microdata file.",
                       "Fruit and vegetable/salad frequencies are self-reported consumption frequencies; quantity and diet quality were not measured.",
                       "Social support items follow the Oslo-3 Social Support Scale of the European Health Interview Survey; the Turkish response options (Çok fazla, Fazla, Orta, Az, Hiç; Çok kolay, Kolay, Orta, Zor, Çok zor) are shown with their standard English equivalents."))
s2 <- eksik_veri[, .(Variable = degisken, `Missing, n` = nfmt(eksik_n), `Missing, %` = formatC(eksik_yuzde, format = "f", digits = 3))]
tablo_cikar(s2, paste0("Table", ek_no[["eksik"]], "_eksik_veri"), sprintf("Table %s. Missing values in the eligible population (n = %s) and records excluded from the analysis frame.", ek_no[["eksik"]], nfmt(nrow(u0))), klasor = ek_kl,
            notlar = c(sprintf("Complete-case rule for predictors: %d adult excluded (household income missing); analysis frame n = %s adults, %s PHQ-8 positive, %s households. EGITIM = 99 (unknown) was treated as missing; no eligible adult had this code.",
                               say$orneklem$dusen_eksik, nfmt(say$orneklem$analiz), nfmt(say$orneklem$analiz_pozitif), nfmt(say$orneklem$analiz_hane)),
                       "PHQ-8 items were complete for all adults aged ≥ 18 years; multiple imputation was not used."))
cv_ozet <- cv_tani[, .(uyum = .N, rhat_max = max(rhat_max), ess_bulk_min = min(ess_bulk_min), ess_tail_min = min(ess_tail_min), diverjans = sum(diverjans), ebfmi_min = min(ebfmi_min),
                       ikinci_deneme = sum(deneme > 1), mcse_max = max(mcse_max)), keyby = .(varyant)]
cv_ozet <- cv_ozet[order(match(varyant, c("ana", "agirlikli", "oncel25", "spline", "depresyon")))]
oo_kullanilan <- if (oncel_kural) oo_ozet_f(oo[[oncel_secilen]], "M2", oncel_secilen) else NULL
ornekleme_metni <- sprintf("4 chains; full-data models %s warm-up + %s sampling iterations per chain; cross-validation models %s + %s (increased from 1,500 under the prespecified Monte Carlo error rule); adapt_delta %s; CmdStan via cmdstanr",
                           paste(nfmt(unique(tam_tani[, .SD[.N], by = model]$warmup)), collapse = "/"), paste(nfmt(unique(tam_tani[, .SD[.N], by = model]$ornek)), collapse = "/"),
                           paste(nfmt(unique(cv_tani$warmup)), collapse = "/"), paste(nfmt(unique(cv_tani$ornek)), collapse = "/"),
                           paste(unique(c(tam_tani$adapt_delta, cv_tani$adapt_delta)), collapse = "/"))
s3 <- rbind(
  data.table(Item = "Likelihood", Value = "Bernoulli with logit link; unweighted training (weighted pseudo-likelihood only in sensitivity analysis C)"),
  data.table(Item = "Intercept prior", Value = "Student-t(3, 0, 2.5) on the intercept of the centered design matrix (brms default parameterization)"),
  data.table(Item = "Coefficient priors", Value = sprintf("Normal with SD 1 for all indicator coefficients; normal with SD 1/(2 SD_{x}) per day for the three day-count variables in M2 (day-count SD %s; prior SD %s), chosen by prior predictive check before model fitting",
                                                        paste(sprintf("%.2f", gun_sd), collapse = ", "), paste(sprintf("%.3f", sd_b_ana[gunler]), collapse = ", "))),
  data.table(Item = "Parameters and events", Value = sprintf("M0 %d, M1 %d, M2 %d coefficients plus intercept; %d events (%.1f, %.1f and %.1f events per coefficient)", length(sag$M0), length(sag$M1), length(sag$M2), n_poz,
                                                           n_poz / length(sag$M0), n_poz / length(sag$M1), n_poz / length(sag$M2))),
  rbindlist(lapply(c("M0", "M1", "M2", if (!is.null(oo_kullanilan)) "M2_kullanilan"), function(m) {
    o <- if (m == "M2_kullanilan") oo_kullanilan else oo_ozet[model == m][1]
    et <- c(M0 = "Prior predictive, M0", M1 = "Prior predictive, M1", M2 = if (is.null(oo_kullanilan)) "Prior predictive, M2" else "Prior predictive, M2 with prior SD 1 per day (not used)",
            M2_kullanilan = "Prior predictive, M2 with prior SD 1/(2 SD) per day (used)")[[m]]
    data.table(Item = et, Value = sprintf("weighted positive share median %.2f (5th–95th percentile %.3f–%.3f); median between-person SD of x'β %.2f; median share of adults with p < 0.001 or > 0.999: %.3f",
                                          o$pay_q50, o$pay_q05, o$pay_q95, o$xb_sd_q50, o$uc_pay_q50))
  })),
  data.table(Item = "Sampling", Value = ornekleme_metni),
  tam_tani[, .(Item = sprintf("Full-data %s", model), Value = sprintf("max R-hat %.4f; min bulk ESS %s; min tail ESS %s; divergent transitions %d; min E-BFMI %.2f", rhat_max, nfmt(round(ess_bulk_min)),
                                                                     nfmt(round(ess_tail_min)), as.integer(diverjans), ebfmi_min))],
  cv_ozet[, .(Item = sprintf("Cross-validation fits, %s (n = %d)", c(ana = "main models, five fold assignments", agirlikli = "weighted training", oncel25 = "prior SD 2.5", spline = "age spline", depresyon = "depression added")[varyant], uyum),
              Value = sprintf("max R-hat %.4f; min bulk ESS %s; min tail ESS %s; divergent transitions %d; min E-BFMI %.2f; refits needed %d; max MCSE of an outer-fold predicted probability %.5f", rhat_max,
                              nfmt(round(ess_bulk_min)), nfmt(round(ess_tail_min)), as.integer(diverjans), ebfmi_min, ikinci_deneme, mcse_max))])
tablo_cikar(s3, paste0("Table", ek_no[["model"]], "_model_tanilari"), sprintf("Table %s. Model specification, prior predictive check and convergence diagnostics.", ek_no[["model"]]), klasor = ek_kl, orta = FALSE,
            notlar = c("Convergence criteria: R-hat ≤ 1.01, bulk and tail effective sample size ≥ 400, no divergent transitions and E-BFMI > 0.3 for every model; all were met.",
                       sprintf("Monte Carlo error of the primary difference: perturbing outer-fold probabilities by their Monte Carlo standard errors changed Δ(0.20) with SD %.3f per 1,000 (%d replicates).", mc_ozet[karsilastirma == "M1 − M0", mc_sd], mc_tekrar)))
ks <- dcast(katsayilar[, .(terim, degisken_etiket, duzey, model, h = ga(or_medyan, or_alt, or_ust, 2))], terim + degisken_etiket + duzey ~ model, value.var = "h", fill = "")
ks <- ks[match(colnames(X)[colnames(X) %in% ks$terim], terim)]
s4 <- list(kesisim[, .(k = "Intercept, log-odds at the reference categories, posterior mean (95% PI)", m = model, h = ga(ortalama, alt, ust, 2))][, setNames(as.list(h), m), by = k])
s4_grup <- integer(0)
s4_gir <- integer(0)
for (dv in unique(ks$degisken_etiket)) {
  x <- ks[degisken_etiket == dv]
  s4[[length(s4) + 1]] <- data.table(k = dv, M0 = "", M1 = "", M2 = "")
  s4_grup <- c(s4_grup, sum(vapply(s4, nrow, 0L)))
  for (i in seq_len(nrow(x))) {
    s4[[length(s4) + 1]] <- x[i, .(k = duzey, M0, M1, M2)]
    s4_gir <- c(s4_gir, sum(vapply(s4, nrow, 0L)))
  }
}
s4 <- rbindlist(s4)
setnames(s4, c("Term", "M0, OR (95% PI)", "M1, OR (95% PI)", "M2, OR (95% PI)"))
tablo_cikar(s4, paste0("Table", ek_no[["katsayi"]], "_katsayilar"), sprintf("Table %s. Posterior odds ratios of the full-data models.", ek_no[["katsayi"]]), klasor = ek_kl, grup_satir = s4_grup, girinti = s4_gir,
            notlar = c("Table S4 provides descriptive summaries of the full-data model coefficients (posterior mean intercept; posterior median odds ratios). Exact predictions require the posterior draws (Results/model_cekilisleri) and the scoring function (Codes/skorla.R) provided in the repository, because the posterior mean probability is not the probability at the posterior mean or median coefficients.",
                       "Intercept: posterior mean of the log-odds of PHQ-8 ≥ 10 when every predictor is at its reference category (day counts at 0), with its 95% posterior interval. OR, posterior median odds ratio; 95% PI, 2.5th–97.5th percentiles of the posterior distribution. Models are fitted to the full analysis frame without survey weights and are reported for description only; the capacity analyses use outer-fold predictions.",
                       "Reference categories: age 18–34 years; men; primary education or less; income group 1; no chronic condition; fruit and vegetable daily or more; mostly sitting or standing; no close persons; a lot of interest and concern; very easy help from neighbors. Day counts: odds ratio per day.",
                       "Coefficients are conditional associations within each model and do not represent effects."))
pf <- dcast(performans[, .(model, olcu, h = ga(tahmin, alt, ust, 3))], model ~ olcu, value.var = "h", fill = "")
pf <- pf[match(c("M0", "M1", "M2", "PHQ2", "M1 − M0", "M2 − M1"), model)]
pf[, model := c(etk$strateji$M0, etk$strateji$M1, etk$strateji$M2, etk$strateji$PHQ2, "Difference, M1 − M0", "Difference, M2 − M1")]
s5 <- pf[, .(Strategy = model, `AUC (95% CI)` = AUC, `Calibration slope (95% CI)` = egim, `Calibration intercept (95% CI)` = kesisim, `Observed/expected (95% CI)` = oe)]
tablo_cikar(s5, paste0("Table", ek_no[["performans"]], "_performans"), sprintf("Table %s. Discrimination and calibration of outer-fold predictions (first, primary fold assignment).", ek_no[["performans"]]), klasor = ek_kl,
            notlar = c("All measures are weighted by the individual survey weight. AUC: weighted area under the ROC curve (ties counted as one half). Calibration slope: coefficient of the logit of the predicted probability in a weighted logistic regression; calibration intercept: intercept with the logit as an offset; observed/expected: weighted observed over weighted mean predicted positives.",
                       paste0("The PHQ-2 score is a symptom-based comparator sharing two items with the PHQ-8; it is not an upper bound, and calibration is not defined for it. 95% CI: household cluster bootstrap (", nfmt(B_boot),
                              " replicates), conditional on the fixed model fits.")))
duy_kodlar <- list(c("primary", paste0("A_r", 2:5)), c("primary", paste0("A_r", 2:5), "B", "C", "D", "E", "F"), c("primary", paste0("A_r", 2:5)))
s6d <- list()
s6_grup <- integer(0)
s6_gir <- integer(0)
for (k in seq_along(kap3)) {
  cc <- kap3[k]
  s6d[[length(s6d) + 1]] <- data.table(a = sprintf("Capacity %d%% (%s per 1,000 invited)", round(100 * cc), nfmt(round(1000 * cc))), d0 = "", d1 = "", f = "", f21 = "")
  s6_grup <- c(s6_grup, sum(vapply(s6d, nrow, 0L)))
  s6 <- dcast(duyarlilik[c == cc & olcu %in% c("fark", "D_M0", "D_M1") & karsilastirma == "M1 − M0"], analiz + kod ~ olcu, value.var = c("tahmin", "alt", "ust"))
  m21 <- duyarlilik[c == cc & olcu == "fark" & karsilastirma == "M2 − M1", .(kod, m21 = ga2(tahmin, alt, ust))]
  s6 <- merge(s6, m21, by = "kod", all.x = TRUE)
  s6 <- s6[match(duy_kodlar[[k]], kod)][!is.na(kod)]
  s6d[[length(s6d) + 1]] <- s6[, .(a = analiz, d0 = ga(tahmin_D_M0, alt_D_M0, ust_D_M0, 1), d1 = ga(tahmin_D_M1, alt_D_M1, ust_D_M1, 1), f = ga2(tahmin_fark, alt_fark, ust_fark),
                                   f21 = fifelse(is.na(m21), "–", m21))]
  s6_gir <- c(s6_gir, sum(vapply(s6d, nrow, 0L)) - nrow(s6) + seq_len(nrow(s6)))
}
s6d <- rbindlist(s6d)
setnames(s6d, c("Analysis", "D_{M0}(c) (95% CI)", "D_{M1}(c) (95% CI)", "Δ(c), M1 − M0 (95% CI)", "M2 − M1 (95% CI)"))
ad5 <- duyarlilik[kod == "A_aralik"]
ad5_f <- function(cc, k) ad5[c == cc & karsilastirma == k, sprintf("%s (range %s to %s)", f2(tahmin), f2(alt), f2(ust))]
hy <- duyarlilik[kod == "H" & c == 0.20]
tablo_cikar(s6d, paste0("Table", ek_no[["duyarlilik"]], "_duyarlilik"), sprintf("Table %s. Sensitivity analyses of the detection yield of M0 and M1 and of the differences in detection yield at 10%%, 20%% and 30%% capacity (per 1,000 eligible adults).", ek_no[["duyarlilik"]]),
            klasor = ek_kl, yatay = TRUE, grup_satir = s6_grup, girinti = s6_gir,
            notlar = c(sprintf("Every analysis uses the same within-fold selection rule (except B), capacity definition and paired household bootstrap (%s replicates) as the primary analysis; intervals are 95%% percentile bootstrap CIs conditional on the fixed model fits and fold assignments. D_{M0}(c) and D_{M1}(c), detection yield at capacity c; Δ(c) = D_{M1}(c) − D_{M0}(c). The primary analysis and the four further fold assignments (A) are shown at 10%%, 20%% and 30%% capacity; B–F at 20%% capacity only.", nfmt(B_boot)),
                       "A: four further random household-blocked fold assignments. B: all outer-fold predictions ranked in one pool with one weighted threshold. C: training weighted by the normalized survey weight (pseudo-posterior). D: normal coefficient priors with SD 2.5. E: age as a natural cubic spline instead of age bands. F: self-reported depression in the past 12 months added to M0 and M1 (its reporting window overlaps the outcome window, so it is not part of the primary models).",
                       sprintf("Across the five fold assignments, the point estimate of Δ averaged %s at 10%% capacity, %s at 20%% and %s at 30%%; that of M2 − M1 averaged %s at 10%%, %s at 20%% and %s at 30%%.",
                               ad5_f(0.10, "M1 − M0"), ad5_f(0.20, "M1 − M0"), ad5_f(0.30, "M1 − M0"), ad5_f(0.10, "M2 − M1"), ad5_f(0.20, "M2 − M1"), ad5_f(0.30, "M2 − M1")),
                       sprintf("G (alternative practical-importance bounds ±0.5 and ±2 per 1,000) is a relabeling of the primary bootstrap distribution; see Table %s.", ek_no[["bootstrap"]]),
                       sprintf("H (capacity window): point estimates of Δ at capacities from 0.18 to 0.22 in steps of 0.005 averaged %s (range %s to %s); the estimator is not smooth in c because few PHQ-8–positive adults lie near each fold threshold.",
                               f2(hy[karsilastirma == "M1 − M0", tahmin]), f2(hy[karsilastirma == "M1 − M0", alt]), f2(hy[karsilastirma == "M1 − M0", ust])),
                       "–, not computed (M2 was not refitted in analyses C–F)."))
s7 <- rbind(tekrar_oran[, .(Quantity = sprintf("%s, bound ±%s per 1,000", karsilastirma, format(sinir)), `Difference > bound` = f1(100 * buyuk), `|Difference| ≤ bound` = f1(100 * icinde),
                            `Difference < −bound` = f1(100 * kucuk))])
tablo_cikar(s7, paste0("Table", ek_no[["bootstrap"]], "_bootstrap_oranlari"), sprintf("Table %s. Bootstrap replicate proportions (%%) for the differences in detection yield at 20%% capacity, and the model-based distribution of the primary difference.", ek_no[["bootstrap"]]),
            klasor = ek_kl,
            notlar = c(sprintf("Proportions of the %s paired household bootstrap replicates falling in each region; they describe sampling variability conditional on the fixed model fits and are not posterior probabilities. Bootstrap medians: M1 − M0 %s, M2 − M1 %s.",
                               nfmt(B_boot), f2(fark_oz[karsilastirma == "M1 − M0" & c == 0.20 & olcu == "fark", b_medyan]), f2(fark_oz[karsilastirma == "M2 − M1" & c == 0.20 & olcu == "fark", b_medyan])),
                       sprintf("Model-based distribution (1,000 thinned outer-fold posterior draws of the first fold assignment, with draw-specific rankings and selections, conditional on the fixed data and fold assignments): Δ(0.20) median %s (2.5th–97.5th percentiles %s to %s) per 1,000.",
                               f2(model_temelli[3, medyan]), f2(model_temelli[3, alt]), f2(model_temelli[3, ust]))))
s8 <- g470_tab[, .(Group = sub("GP or family physician", "General practitioner or family physician", sub("No GP or family physician visit", "No general practitioner or family physician visit", grup)),
                   n = nfmt(n), `Weighted population, millions` = formatC(agirlikli_kisi / 1e6, format = "f", digits = 2), `% of adults ≥ 18` = f2(yuzde_18_ustu),
                   `% of PHQ-8–positive adults ≥ 18` = f1(yuzde_18_ustu_pozitif), `% of the group` = f1(yuzde_grup_ici))]
tablo_cikar(s8, paste0("Table", ek_no[["grup470"]], "_grup470"), sprintf("Table %s. Adults aged ≥ 18 years with PHQ-8 ≥ 10, fruit and vegetable/salad consumption both less than daily, and no mental health specialist contact in the past 12 months.", ek_no[["grup470"]]),
            klasor = ek_kl,
            notlar = c("n, unweighted; percentages and population weighted by the individual survey weight. The adults without a general practitioner or family physician visit in the past 12 months lie outside the eligible population of the main analysis.",
                       "The group is defined using the outcome, and the diet condition is part of its definition; capture of this group by M1 is therefore not the primary measure of success. Not reporting specialist contact does not imply being undiagnosed or untreated."))
sure_ekle("ek tablolar S1–S8", t0)

t0 <- Sys.time()
agt <- ag_oz[strateji %in% c("M0", "M1", "M1 − M0")]
h_ag <- function(dg, dz, st, ol, yuz = TRUE) {
  x <- agt[degisken == dg & duzey == dz & strateji == st & olcu == ol]
  if (!nrow(x) || is.na(x$tahmin)) return("–")
  v <- if (yuz) gay(x$tahmin, x$alt, x$ust) else ga1(x$tahmin, x$alt, x$ust)
  if (x$kucuk_hucre == "flag 20–50") paste0(v, "^{a}") else v
}
s9 <- list()
s9_grup <- integer(0)
s9_gir <- integer(0)
for (dg in grup_deg) {
  s9[[length(s9) + 1]] <- data.table(k = etk$degisken[[dg]], n = "", pz = "", np = "", s0 = "", s1 = "", y0 = "", y1 = "", f = "")
  s9_grup <- c(s9_grup, sum(vapply(s9, nrow, 0L)))
  for (dz in levels(a[[dg]])) {
    x0 <- agt[degisken == dg & duzey == dz & strateji == "M0"]
    s9[[length(s9) + 1]] <- data.table(k = etk$kategori[[dg]][[dz]], n = nfmt(x0$n[1]), pz = nfmt(x0$n_pozitif[1]), np = f1(100 * x0[olcu == "nufus_payi", tahmin]),
                                       s0 = f1(100 * x0[olcu == "secilen_dagilim", tahmin]), s1 = f1(100 * agt[degisken == dg & duzey == dz & strateji == "M1" & olcu == "secilen_dagilim", tahmin]),
                                       y0 = h_ag(dg, dz, "M0", "yakalama"), y1 = h_ag(dg, dz, "M1", "yakalama"), f = h_ag(dg, dz, "M1 − M0", "fark"))
    s9_gir <- c(s9_gir, sum(vapply(s9, nrow, 0L)))
  }
}
s9 <- rbindlist(s9)
setnames(s9, c("Group", "n", "PHQ-8 positive, n", "Share of eligible adults, %", "Share of selected, M0, %", "Share of selected, M1, %", "Positives selected, M0, % (95% CI)",
               "Positives selected, M1, % (95% CI)", "Difference, M1 − M0, percentage points (95% CI)"))
tablo_cikar(s9, paste0("Table", ek_no[["altgrup"]], "_altgrup"), sprintf("Table %s. Distribution of selection and within-group capture of PHQ-8–positive adults at 20%% capacity, by subgroup.", ek_no[["altgrup"]]), klasor = ek_kl,
            grup_satir = s9_grup, girinti = s9_gir, yatay = TRUE,
            notlar = c(sprintf("n, unweighted; percentages weighted. Positives selected: weighted share of PHQ-8–positive adults in the group who are selected under within-fold selection at 20%% capacity (sensitivity within the group). 95%% CI: paired household cluster bootstrap (%s replicates), conditional on the fixed model fits. Share of selected: distribution of the selected adults across the groups of each characteristic (columns sum to 100%%). Subgroup comparisons were not prespecified tests; 15 groups are shown.",
                               nfmt(B_boot)),
                       if (any(grepl("\\^\\{a\\}|^–$", unlist(s9)))) "^{a} 20–50 unweighted PHQ-8–positive adults in the group; – fewer than 20 (estimate suppressed)."))
esg <- esitlik[strateji %in% c("M0", "M1", "M2") & c == 0.20]
s9b <- list()
s9b_grup <- integer(0)
s9b_gir <- integer(0)
for (st in c("M0", "M1", "M2")) {
  x <- esg[strateji == st]
  s9b[[length(s9b) + 1]] <- data.table(k = etk$strateji[[st]], u = "", e = "", f = "", su = "")
  s9b_grup <- c(s9b_grup, sum(vapply(s9b, nrow, 0L)))
  tt <- x[duzey == "Total"]
  s9b[[length(s9b) + 1]] <- data.table(k = "Detection yield per 1,000, all groups", u = tt[olcu == "D_kisitsiz", ga1(tahmin, alt, ust)], e = tt[olcu == "D_esit", ga1(tahmin, alt, ust)],
                                       f = tt[olcu == "fark_D", ga2(tahmin, alt, ust)], su = "")
  s9b_gir <- c(s9b_gir, sum(vapply(s9b, nrow, 0L)))
  for (dz in levels(a$gelir5)) {
    g <- x[duzey == dz]
    s9b[[length(s9b) + 1]] <- data.table(k = paste("Sensitivity, %, income group", etk$kategori$gelir5[[dz]]), u = g[olcu == "Sens_unconstrained", gay(tahmin, alt, ust)],
                                         e = g[olcu == "Sens_equal", gay(tahmin, alt, ust)], f = g[olcu == "fark_Sens", ga(100 * tahmin, 100 * alt, 100 * ust, 2)],
                                         su = g[olcu == "secim_payi_unconstrained", gay(tahmin, alt, ust)])
    s9b_gir <- c(s9b_gir, sum(vapply(s9b, nrow, 0L)))
  }
}
s9b <- rbindlist(s9b)
setnames(s9b, c("Strategy and quantity", "Unconstrained selection (95% CI)", "Equal selection proportion (95% CI)", "Difference, equal − unconstrained (95% CI)", "Share of group selected, unconstrained, % (95% CI)"))
tablo_cikar(s9b, paste0("Table", ek_no[["esitlik"]], "_esitlik"), sprintf("Table %s. Equal selection proportion across income groups compared with unconstrained selection at 20%% capacity.", ek_no[["esitlik"]]), klasor = ek_kl,
            grup_satir = s9b_grup, girinti = s9b_gir, yatay = TRUE,
            notlar = c("Equal selection proportion across income groups: within each fold and income group, the weighted share selected equals the capacity (20%), using the same weighted-quantile and fractional-inclusion rule. Unconstrained: within-fold selection over all groups. Share of group selected: weighted share of adults in the income group who are selected; it equals the capacity (20%) in every group under the equal selection proportion rule. Difference in sensitivity in percentage points.",
                       sprintf("95%% CI: paired household cluster bootstrap (%s replicates), conditional on the fixed model fits; the same replicates are used for both rules.", nfmt(B_boot))))
pk_rol <- data.table(
  paket = c("brms", "cmdstanr", "posterior", "splines", "WeightedROC", "data.table", "readr", "arrow", "jsonlite", "future", "furrr", "flextable", "officer", "openxlsx", "rlang"),
  rol = c("Bayesian logistic models (Stan interface)", "CmdStan backend for brms", "Posterior draws, R-hat, ESS and Monte Carlo standard errors", "Natural cubic spline for age (sensitivity analysis E)",
          "Weighted ROC curves and AUC", "Data handling (auxiliary)", "Reading the semicolon-delimited microdata file (auxiliary)", "Parquet storage of intermediate data (auxiliary)",
          "Machine-readable numbers file (auxiliary)", "Parallel computation (auxiliary)", "Parallel computation (auxiliary)", "Word tables (auxiliary)", "Word documents (auxiliary)",
          "Excel tables (auxiliary)", "Hashing of cache keys (auxiliary)"),
  temel = c(rep(TRUE, 5), rep(FALSE, 10)))
pk_rol[, surum := vapply(paket, function(p) as.character(packageVersion(p)), "")]
py_ortam <- system2(py, c("-I", shQuote(normalizePath("Codes/python_ortam.py"))), stdout = TRUE)
writeLines(py_ortam, "Results/python_ortam.txt")
s10 <- rbind(data.table(Software = "R", Version = paste(R.version$major, R.version$minor, sep = "."), Role = "Statistical computing environment"),
             data.table(Software = "CmdStan (Stan)", Version = as.character(cmdstanr::cmdstan_version()), Role = "Hamiltonian Monte Carlo sampling (NUTS)"),
             pk_rol[, .(Software = paste("R package", paket), Version = surum, Role = rol)],
             data.table(Software = "Python", Version = sub("Python ([0-9.]+).*", "\\1", py_ortam[1]), Role = "Figures"),
             data.table(Software = sub(" .*", "", py_ortam[-1]), Version = sub(".* ", "", py_ortam[-1]),
                        Role = c(matplotlib = "Figures", numpy = "Arrays (auxiliary)", pandas = "Reading figure data (auxiliary)", openpyxl = "Excel subscripts (auxiliary)",
                                 fonttools = "Font embedding (auxiliary)", pillow = "TIFF output (auxiliary)")[sub(" .*", "", py_ortam[-1])]))
tablo_cikar(s10, paste0("Table", ek_no[["yazilim"]], "_yazilim"), sprintf("Table %s. Software and packages.", ek_no[["yazilim"]]), klasor = ek_kl, orta = FALSE,
            notlar = c("Auxiliary packages support data handling and output only. Full session information: sessionInfo.txt; Python environment: python_ortam.txt; citations: paket_atiflari.txt."))
sayfa_sira <- function(ad) {
  if (grepl("^Table[0-9]", ad)) return(as.numeric(sub("^Table([0-9]+).*", "\\1", ad)) / 10)
  as.numeric(sub("^TableS([0-9]+).*", "\\1", ad)) + c(a = 0.1, b = 0.2)[sub("^TableS[0-9]+([ab]?)_.*", "\\1", ad)] %||% 0
}
`%||%` <- function(x, y) if (length(x) && !is.na(x)) x else y
worksheetOrder(wb) <- order(vapply(names(wb), function(ad) unname(sayfa_sira(ad)), 0))
saveWorkbook(wb, "Results/tablolar_tumu.xlsx", overwrite = TRUE)
system2(py, c("-I", shQuote(normalizePath("Codes/xlsx_simge.py")), shQuote(normalizePath("Results/tablolar_tumu.xlsx"))))
sure_ekle("ek tablolar S9–S11 ve xlsx", t0)

t0 <- Sys.time()
akis <- data.table(adim = 1:7, kod = c("ham", "yetiskin", "hekim", "uygun", "analiz", "pozitif", "hane"),
                   n = c(say$orneklem$ham, say$orneklem$yetiskin, say$orneklem$hekim_temasi, say$orneklem$uygun, say$orneklem$analiz, say$orneklem$analiz_pozitif, say$orneklem$analiz_hane),
                   etiket = c("Survey respondents (all ages)", "Adults aged ≥ 18 years", "Saw a general practitioner or family physician in the past 12 months", "Eligible: no psychologist, psychotherapist or psychiatrist visit",
                              "Analysis frame (complete predictors)", "PHQ-8 ≥ 10", "Households in the analysis frame"),
                   dislanan = c(NA, say$orneklem$ham - say$orneklem$yetiskin, say$orneklem$hekim_temasi_olmayan, say$orneklem$uzman_temasi_dislanan, say$orneklem$dusen_eksik, NA, NA),
                   dislanan_etiket = c("", "Aged < 18 years", "No general practitioner or family physician visit in the past 12 months", "Mental health specialist visit in the past 12 months", "Missing household income", "", ""))
fwrite(akis, file.path(fvdir, "fig1_akis.csv"))
fwrite(duyarlilik[c == 0.20 & olcu == "fark" & karsilastirma == "M1 − M0"][, .(analiz, kod, tahmin, alt, ust)], file.path(fvdir, "figS_duyarlilik.csv"))
fwrite(data.table(kalem = c("p", "phq2_3_c", "B", "pratik_sinir", "tavan_kat_ciz"), deger = c(say$p, p2t[["c"]], B_boot, 1, as.numeric(tavan_ciz))), file.path(fvdir, "sabitler.csv"))

say$tanilar <- list(tam = lapply(split(tam_tani, by = "model", keep.by = FALSE, drop = TRUE), function(x) as.list(x[.N, .(rhat_max, ess_bulk_min, ess_tail_min, diverjans, ebfmi_min)])),
                    cv = list(uyum = nrow(cv_tani), rhat_max = max(cv_tani$rhat_max), ess_bulk_min = min(cv_tani$ess_bulk_min), ess_tail_min = min(cv_tani$ess_tail_min),
                              diverjans = sum(cv_tani$diverjans), ebfmi_min = min(cv_tani$ebfmi_min), ikinci_deneme = sum(cv_tani$deneme > 1), mcse_max = max(cv_tani$mcse_max)),
                    mc_delta = as.list(mc_ozet[karsilastirma == "M1 − M0", .(mc_sd, mc_en_buyuk_sapma)]))
say$duyarlilik <- lapply(split(duyarlilik[c == 0.20 & olcu %in% c("fark", "fark_5tekrar_ort_min_max")], by = c("kod", "karsilastirma"), keep.by = FALSE, drop = TRUE), function(x) as.list(x[, .(tahmin, alt, ust)]))
say$esitlik <- lapply(split(esitlik[c == 0.20], by = c("strateji", "duzey", "olcu"), keep.by = FALSE, drop = TRUE), function(x) as.list(x[, .(tahmin, alt, ust)]))
say$altgrup <- lapply(split(ag_oz[olcu %in% c("yakalama", "fark", "secilen_dagilim", "nufus_payi")], by = c("strateji", "degisken", "duzey", "olcu"), keep.by = FALSE, drop = TRUE),
                      function(x) as.list(x[, .(tahmin, alt, ust)]))
say$model_temelli <- as.list(model_temelli[3, .(medyan, alt, ust)])
say$gelir_gruplari <- lapply(split(gelir_grup, by = "gelir5", keep.by = FALSE, drop = TRUE), as.list)
table1_json <- copy(table1)[, `:=`(yuzde_toplam = fifelse(n_toplam < 20, NA_real_, yuzde_toplam), yuzde_pozitif = fifelse(n_pozitif < 20, NA_real_, yuzde_pozitif),
                                   yuzde_negatif = fifelse(n_negatif < 20, NA_real_, yuzde_negatif))]
say$table1 <- lapply(split(table1_json[, .(degisken, duzey, n_toplam, yuzde_toplam, n_pozitif, yuzde_pozitif, n_negatif, yuzde_negatif, ort_toplam, ort_pozitif, ort_negatif)],
                           by = c("degisken", "duzey"), keep.by = FALSE, drop = TRUE), function(x) as.list(x[, lapply(.SD, function(v) if (all(is.na(v))) NULL else v)]))
say$katsayilar <- lapply(split(katsayilar[, .(model, terim, or_medyan, or_alt, or_ust)], by = c("model", "terim"), keep.by = FALSE, drop = TRUE), as.list)
say$ince_izgara <- lapply(split(yerel, by = c("karsilastirma", "c"), keep.by = FALSE, drop = TRUE), as.list)
kat_atama_json <- function(cc) lapply(split(duyarlilik[c == cc & kod %in% c("primary", paste0("A_r", 2:5), "A_aralik") & olcu %in% c("fark", "D_M0", "D_M1", "fark_5tekrar_ort_min_max")],
                                            by = c("kod", "karsilastirma", "olcu"), keep.by = FALSE, drop = TRUE), function(x) as.list(x[, .(tahmin, alt, ust)]))
say$duyarlilik$kat_atamasi <- list(c0.10 = kat_atama_json(0.10), c0.30 = kat_atama_json(0.30))
tk1 <- tavan_kat[tekrar == 1]
tavan_c <- function(cc) as.list(tk1[abs(c - cc) < 1e-12, .(D_kat_tavan = D_kat, D_nufus_tavan = D_nufus, fark)])
say$tavan <- list(kat_duzeyi = list(
  tanim = "D_tavan,kat(c) = 1000 × Σ_k min(c × W_k, Σ_{i∈k} w_i y_i) / Σ_i w_i; folds of the primary (first) fold assignment",
  c0.10 = tavan_c(0.10), c0.20 = tavan_c(0.20), c0.30 = tavan_c(0.30),
  en_buyuk_fark = tavan_ozet[tekrar == 1, izgara_en_buyuk_fark], en_buyuk_fark_c = tavan_ozet[tekrar == 1, izgara_en_buyuk_fark_c],
  surekli_en_buyuk_fark = tavan_ozet[tekrar == 1, surekli_en_buyuk_fark], surekli_en_buyuk_fark_c = tavan_ozet[tekrar == 1, surekli_en_buyuk_fark_c],
  kat_prevalans_min = tavan_ozet[tekrar == 1, kat_p_min], kat_prevalans_max = tavan_ozet[tekrar == 1, kat_p_max],
  tekrarlar_izgara_en_buyuk_fark = as.list(setNames(tavan_ozet$izgara_en_buyuk_fark, paste0("r", tavan_ozet$tekrar))),
  karar_esigi = tavan_esik, figur2a_ikinci_cizgi = tavan_ciz))
write_json(say, "Results/sayilar.json", auto_unbox = TRUE, digits = NA, pretty = TRUE)

atif_paket <- c("base", "brms", "cmdstanr", "posterior", "WeightedROC", "splines", "data.table", "readr", "arrow", "jsonlite", "future", "furrr", "flextable", "officer", "openxlsx", "rlang")
atif <- c("# Paket atıfları (citation() çıktıları)", "", "Analizde doğrudan rol oynayanlar: R, brms, cmdstanr (CmdStan/Stan), posterior, splines (R çekirdeği), WeightedROC. Ötekiler yardımcıdır; rolleri Table S5'da.", "")
for (p in atif_paket) {
  atif <- c(atif, sprintf("## %s %s — %s", if (p == "base") "R" else p, if (p == "base") paste(R.version$major, R.version$minor, sep = ".") else as.character(packageVersion(p)),
                          if (p == "base") "statistical computing environment" else pk_rol[paket == p, rol]),
            format(citation(p), style = "text"), "")
}
atif <- c(atif, sprintf("## Stan (CmdStan %s)", cmdstanr::cmdstan_version()),
          "Carpenter, B., Gelman, A., Hoffman, M. D., Lee, D., Goodrich, B., Betancourt, M., Brubaker, M., Guo, J., Li, P., & Riddell, A. (2017). Stan: A probabilistic programming language. Journal of Statistical Software, 76(1), 1–32. https://doi.org/10.18637/jss.v076.i01",
          sprintf("Stan Development Team (%s). Stan Modeling Language Users Guide and Reference Manual, version %s. https://mc-stan.org", format(Sys.Date(), "%Y"), cmdstanr::cmdstan_version()), "",
          "## Prior scaling (Gelman 2008)", "Gelman, A. (2008). Scaling regression inputs by dividing by two standard deviations. Statistics in Medicine, 27(15), 2865–2873. https://doi.org/10.1002/sim.3107", "",
          "## Python — figure scripts", "Van Rossum, G., & Drake, F. L. (2009). Python 3 Reference Manual. CreateSpace.", "",
          "## matplotlib — figures", "Hunter, J. D. (2007). Matplotlib: A 2D graphics environment. Computing in Science & Engineering, 9(3), 90–95. https://doi.org/10.1109/MCSE.2007.55", "",
          "## NumPy — arrays", "Harris, C. R., Millman, K. J., van der Walt, S. J., et al. (2020). Array programming with NumPy. Nature, 585, 357–362. https://doi.org/10.1038/s41586-020-2649-2", "",
          "## pandas — reading figure data", "McKinney, W. (2010). Data structures for statistical computing in Python. Proceedings of the 9th Python in Science Conference, 56–61. https://doi.org/10.25080/Majora-92bf1922-00a",
          "The pandas development team. pandas-dev/pandas: Pandas. Zenodo. https://doi.org/10.5281/zenodo.3509134", "",
          "## openpyxl, Pillow, fonttools — xlsx subscripts, TIFF output and font embedding; auxiliary; no recommended citation")
writeLines(atif, "Results/paket_atiflari.txt")
clang_surum <- tryCatch(system2("clang", "--version", stdout = TRUE)[1], error = function(e) NA_character_)
writeLines(c(capture.output(sessionInfo()), "", sprintf("CmdStan: %s (%s)", cmdstanr::cmdstan_version(), basename(cmdstanr::cmdstan_path())),
             sprintf("C++ derleyici: %s", clang_surum), "CmdStan derleme seçeneği: PRECOMPILED_HEADERS=false (brm_kur, stan_model_args)",
             sprintf("Ham CSV md5: %s", okuma[1])), "Results/sessionInfo.txt")
protokol <- rbind(
  data.table(kontrol = "Prior predictive check", olcut = "Gün bloğunun önsel x'β SD medyanı ≤ 2 × en büyük kategorik blok; değilse 1/SD_x, sonra 1/(2 SD_x)", sonuc = sprintf("Talimat önceliyle %.2f > 2 × %.2f; 1/SD_x ile %.2f; 1/(2 SD_x) ile %.2f", gun_blok, kategorik_blok_max,
                                                                                                                                                                   median(oo[[names(oncel_adaylar)[1]]]$sd_gun), median(oo[[names(oncel_adaylar)[2]]]$sd_gun)),
             karar = oncel_secilen, onceden_belirlenmis = "analist, model uyumundan önce (K8)"),
  data.table(kontrol = "Olay / parametre", olcut = "Raporlanır", sonuc = sprintf("%d olay; M0 %d, M1 %d, M2 %d katsayı", n_poz, length(sag$M0), length(sag$M1), length(sag$M2)), karar = "Büzme öncelleri (talimat)", onceden_belirlenmis = "talimat"),
  data.table(kontrol = "Hesaplama yolu (pilot)", olcut = "OpenCL çalışıyor ve hızlıysa GPU, değilse CPU", sonuc = paste(pilot$deneme, pilot$dakika, "dk,", pilot$durum, collapse = " | "), karar = "CPU; 4 eşzamanlı uyum × 4 zincir × 1 iş parçacığı (K11)",
             onceden_belirlenmis = "talimat"),
  data.table(kontrol = "Yakınsama (tam veri, 3 model)", olcut = "R-hat ≤ 1,01; bulk ve tail ESS ≥ 400; divergence 0; E-BFMI > 0,3", sonuc = sprintf("R-hat en büyük %.4f; ESS en küçük %d; divergence %d; E-BFMI en küçük %.2f",
                                                                                                                                     max(tam_tani$rhat_max), round(min(tam_tani$ess_bulk_min, tam_tani$ess_tail_min)), sum(tam_tani$diverjans), min(tam_tani$ebfmi_min)),
             karar = "Kabul", onceden_belirlenmis = "talimat (ESS eşiği 400 analistin)"),
  data.table(kontrol = sprintf("Yakınsama (CV, %d uyum)", nrow(cv_tani)), olcut = "Aynı; sağlanmazsa iterasyon iki katına, divergence varsa adapt_delta +0,05 (en çok 3 deneme)", sonuc = sprintf("R-hat en büyük %.4f; ESS en küçük %d; divergence %d; E-BFMI en küçük %.2f; ikinci deneme %d",
                                                                                                                                                                        max(cv_tani$rhat_max), round(min(cv_tani$ess_bulk_min, cv_tani$ess_tail_min)), sum(cv_tani$diverjans), min(cv_tani$ebfmi_min), sum(cv_tani$deneme > 1)),
             karar = if (cv_tani[!(rhat_max <= 1.01 & ess_bulk_min >= 400 & ess_tail_min >= 400 & diverjans == 0 & ebfmi_min > 0.3), .N] == 0) "Kabul" else "Ölçütü sağlamayan uyum var", onceden_belirlenmis = "talimat"),
  data.table(kontrol = "p̂ Monte Carlo hatası", olcut = "Δ(0,20) üzerindeki MC kaynaklı SD < 0,05 / 1.000 (analist)", sonuc = sprintf("p̂ MCSE medyan %.6f, en büyük %.5f; Δ(0,20) MC SD %.4f, M2 − M1 %.4f", median(cv1$mcse), max(cv1$mcse),
                                                                                                                                                        mc_ozet$mc_sd[1], mc_ozet$mc_sd[2]),
             karar = if (max(mc_ozet$mc_sd) < 0.05) "İhmal edilebilir" else "İterasyon artırılmalı", onceden_belirlenmis = "talimat (eşik analistin)"),
  data.table(kontrol = "p̂ ile posterior_epred özdeşliği", olcut = "Her CV uyumunda ilk 40 kişide en büyük fark < 1e−9", sonuc = sprintf("En büyük fark %.2e", max(cv_tani$epred_fark)), karar = "Sağlandı", onceden_belirlenmis = "analist"),
  data.table(kontrol = "Satır düşmesi", olcut = "brms veri satırı = eğitim satırı (her uyum)", sonuc = "Bütün uyumlarda eşit (aksi hâlde betik durur)", karar = "Sağlandı", onceden_belirlenmis = "talimat"),
  data.table(kontrol = "CV sızıntısı", olcut = "Aynı hane eğitim ve değerlendirmede olamaz", sonuc = "Her uyumda hane kesişimi boş; 5 tekrarda birden çok katta hane 0", karar = "Sağlandı", onceden_belirlenmis = "talimat"),
  data.table(kontrol = "Seçim fonksiyonu", olcut = "Birim testleri; her strateji ve c'de seçilen ağırlıklı pay = c; D özdeşliği", sonuc = sprintf("%d/%d birim testi geçti", sum(birim$sonuc == "geçti"), nrow(birim)), karar = "Sağlandı",
             onceden_belirlenmis = "talimat"))
fwrite(protokol, "Results/model_protokolu.csv")
fwrite(rbindlist(dogr), "Results/dogrulama_kontrolleri.csv")
sure_ekle("figür verileri, sayilar.json, atıflar", t0)
toplam_dk <- round(as.numeric(difftime(Sys.time(), baslangic, units = "mins")), 2)
sure_ekle("toplam", baslangic)
fwrite(cbind(kosu = format(baslangic, "%Y-%m-%d %H:%M:%S"), rbindlist(sureler)), "Results/log/analiz_sureleri_gecmis.csv", append = file.exists("Results/log/analiz_sureleri_gecmis.csv"))
say$sure_dakika <- toplam_dk
say$dogrulama$ek_kontrol <- nrow(rbindlist(dogr)) - say$dogrulama$kapi_toplam
say$dogrulama$tutmayan <- rbindlist(dogr)[durum != "Tuttu", buyukluk]
write_json(say, "Results/sayilar.json", auto_unbox = TRUE, digits = NA, pretty = TRUE)
cat("analiz.R bitti:", format(Sys.time()), "; toplam", toplam_dk, "dk\n")
sink()

