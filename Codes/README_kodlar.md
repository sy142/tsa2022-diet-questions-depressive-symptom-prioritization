# Kodlar: çalıştırma sırası, süreler, ortam

Bütün komutlar depo (proje) kökünden çalıştırılır; göreli yollar köke göredir. Ham veri klasörü varsayılan olarak `R_Data ve Python Data/kaynak` (TÜİK'ten alınan dosyaların bulunduğu klasör ya da ona sembolik bağlantı); başka yerdeyse `TSA_KAYNAK` ortam değişkeniyle verilir. Klasörde `TSA_2022_MIKROVERI_REV.csv` ve `TSA2022_kodlama_sozlugu.R` bulunmalıdır. Ham klasöre yazılmaz. Analiz planı (talimat): `docs/analysis_plan_TR.md`; çıktılardaki "talimat Bölüm …" atıfları bu belgenin bölümleridir.

## Sıra

1. `Rscript Codes/analiz.R`
   Tek giriş noktası. Sırasıyla:
   - **Okuma** (yalnız ilk çalıştırmada): `TSA_2022_MIKROVERI_REV.csv` analiz planındaki `read_delim` çağrısıyla, bütün sütunlar metin. Çıktılar `R_Data ve Python Data/tsa2022.parquet` ve `.rds`, `sozluk.csv` (soru metinleri), `kodlar.csv` (kmap kod–etiket eşlemeleri), `okuma_bilgisi.txt` (CSV md5'i ve okuma süresi). kmap ve vlab, `TSA2022_kodlama_sozlugu.R` ayrı bir ortamda çalıştırılarak alınır ve `R_Data ve Python Data/kodlama_sozlugu_kmap_vlab.rds`'ye kaydedilir; sonraki koşular bu kopyayı okur. Ham CSV her koşuda yalnız md5 denetimi için aranır; bulunamazsa ilgili kontrol satırı "Tutmadı" olur, betik durmaz.
   - **Doğrulama kapısı:** analiz planı Bölüm 0'daki 18 sayı ve analist ekleri `Results/dogrulama_kontrolleri.csv`'ye yazılır. Kapı sayılarından biri tutmazsa betik durur.
   - **Değişken kurulumu:** eksik veri dökümü, gelir gruplaması, kronik sayısı, kukla tasarım matrisi ve yaş spline'ı (`Codes/tasarim.R` içindeki `tasarim_kur`; `skorla.R` aynı dosyayı kaynak olarak okur, kopya yok); analiz çerçevesi `R_Data ve Python Data/analiz_cercevesi.parquet|.rds`; `Results/table1_veri.csv`, `Results/degisken_tanimlari.csv`; 470 grubu ve hizmet kapsamı betimlemesi.
   - **Prior predictive check** (önbellek `onbellek/oncel_ongoru_<özet>.rds`) ve öncel kuralı (`Results/model_protokolu.csv`, ilk satır; `Results/denetim/oncel_ongoru.csv`).
   - **Pilot** (yalnız `Results/log/pilot_sureleri.csv` yoksa): CPU 4×4 iş parçacığı, CPU 4×1, OpenCL, tek kat ve 4 eşzamanlı kat süreleri.
   - **Tam veri modelleri** M0, M1, M2 (önbellek `onbellek/tam_M*_w1000_s1500_t<tohum>_<model_anahtar>.rds`): `Results/Supplementary/katsayilar.csv`, `Results/model_ozetleri.txt`. Her modelden 1.000 inceltilmiş posterior çekilişi `Results/model_cekilisleri/M0.csv|M1.csv|M2.csv` (sütunlar `cekilis` = brms çekiliş sırası, `Intercept`, bütün katsayılar brms terim adlarıyla) ve terim sözlüğü `terimler.csv` (terim → girdi sütunu, düzey kodu ve etiketi, referans düzey, ölçek, modeller). `skorla()` bu çekilişlerle analiz çerçevesinde yeniden skorlanır ve brms `posterior_epred` ortalamasıyla aynı çekilişler üzerinden karşılaştırılır; en büyük fark 1e−6'yı aşarsa betik durur (`Results/denetim/skorla_dogrulama.csv`).
   - **Hane bloklu çapraz doğrulama:** 230 uyum (her biri ayrı önbellek dosyası `onbellek/cv/<model>_<varyant>_r<tekrar>_k<kat>_w<ısınma>_s<örnekleme>_t<tohum>_<model_anahtar>.rds`): 4 eşzamanlı uyum × 4 zincir × 1 iş parçacığı (`future` + `furrr`). İlerleme `Results/log/cv_ilerleme.txt`. Kişi düzeyi tahminler `R_Data ve Python Data/cv_tahminleri.parquet` (ana modeller, 5 tekrar), aynı içerikte CSV kopyası `cv_tahminleri.csv` (sütunlar id, hh, w, phq_pos, phq2, p_hat_M0, p_hat_M1, p_hat_M2, kat, tekrar; ondalık nokta, UTF-8; sayılar 15 anlamlı basamakla, parquet'e göre en büyük göreli fark 5e−15) ve `cv_tahminleri_duyarlilik.parquet`.
   - **Kapasite analizi:** tek seçim fonksiyonu `secim_kesri` (ağırlıklı kantil + kesirli dahil etme) ve birim testleri (`Results/denetim/birim_testleri.csv`); nokta tahminleri; eşlenik hane kümesi bootstrap'ı (B = 2.000; çarpan matrisi `onbellek/boot_carpan_B2000_t20261131.rds`, sonuçlar `onbellek/boot_sonuc_*.rds`; 14 işçi).
   - **Özetler:** kapasite eğrisi ve farklar, PHQ-2 ≥ 3 noktası, kat düzeyi tavan (beş kat ataması, %2–50 ızgarası ve kat prevalanslarındaki kırılma noktaları; `Results/denetim/kat_duzeyi_tavan.csv`), eşitlik senaryosu, alt grup kapsamı, duyarlılıklar A–G, model temelli Δ dağılımı (`onbellek/model_temelli_delta_*.rds`), Monte Carlo hatası denetimi, ayrım ve kalibrasyon (`onbellek/perf_boot_*.rds`).
   - **Tablolar:** Table 1–2 ve Table S1–S11 (docx + csv), `Results/tablolar_tumu.xlsx` (`Codes/xlsx_simge.py` alt/üst simgeleri gerçek biçime çevirir); figür verileri; `Results/sayilar.json`; `model_protokolu.csv`; `paket_atiflari.txt`; `sessionInfo.txt`; `python_ortam.txt`.
2. `python3 Codes/figurler.py` (bu çalışmada `~/veri-ortami/bin/python3`)
   Bütün figürler `R_Data ve Python Data/figur_verileri/*.csv` dosyalarından (bu klasör yoksa depodaki `Figures/figur_verileri/`'den) çizilir; figür kodu veri hesaplamaz. matplotlib Agg arka ucu kullanılır (figür boyutları ortamdan bağımsız); figür sınırından taşan yazı ya da 7 pt altı yazı betiği durdurur. Ana metin Figure 1–3, ek Figure S1–S4 (`Figures/Supplementary/`). Tek figür: `python Codes/figurler.py 2` ya da `python Codes/figurler.py S3`. Ortak stil ve palet `Codes/figur_stili.py`, metin etiketleri `Codes/etiketler.json` (R tabloları da aynı dosyayı okur). Yazı tipi Lato (SIL OFL 1.1; Regular, Italic, Bold), sistem kurulumuna bağlı kalmadan `Codes/fonts/` altındaki TTF'lerden (`OFL.txt` lisansıyla) `font_manager.addfont` ile yüklenir. Sistemde kurulu bir Lato varsa önce matplotlib'in listesinden çıkarılır. Dosyalar yoksa ya da Lato yine başka bir yerden yüklenirse betik durur, varsayılan fonta düşmez. Her figürde 7 pt altı yazı varsa ya da PDF'e Lato dışı bir font gömülürse betik durur; gömülü font adları ve en küçük punto `Results/denetim/figur_font_denetimi.csv`'ye yazılır.
3. İsteğe bağlı: `Rscript Codes/skorla.R` sentetik dört kişilik örneği (dosyanın başında; mikro veri değil) M0, M1 ve M2 ile skorlar.

**Skor fonksiyonu (`Codes/skorla.R`).** `source("Codes/skorla.R")` sonra `skorla(yeni_veri, model = "M1", dogrusal = FALSE)`. Çıktı: her kişi için `p_ortalama` ve `dogrusal = TRUE` ise `eta_ortalama` (lineer öngörücünün ortalaması).
- `p_ortalama`, 1.000 çekiliş üzerinden logit⁻¹(η) ortalamasıdır: dış kat tahminleriyle aynı türde (posterior ortalama olasılık) ve aynı inceltme kuralıyla hesaplanır. Kapasite analizleri tam veri modellerini değil, dış kat modellerini kullanır; tam veri modelleri betimseldir.
- Ortalama katsayılardaki olasılık, logit⁻¹(ortalama η), posterior ortalama olasılık değildir; analiz çerçevesinde fark M2'de 0,017'ye kadar çıkar.
- Doğrulama: aynı 1.000 çekilişte brms ile en büyük fark < 1e−15. 6.000 çekilişin tamamına göre bireysel tahminler en çok 0,0065 (M2) farklı, ortalama mutlak fark en çok 0,00022 (M2). Girdi: Table S1'deki **ham kodlar** (etiket değil), her model için gereken sütunlar:
- M0: `yas_g` (1 = 18–34, 2 = 35–49, 3 = 50–64, 4 = ≥ 65), `cins` (1 erkek, 2 kadın), `egitim` (1 ilkokul ve altı, 2 ortaokul, 3 lise, 4 yükseköğretim; ham EGITIM kodlarının gruplanışı Table S1'de), `gelir5` (1–5; HANE_GELIR_GRUP bantlarının gruplanışı Table S1'de), `kronik` (0, 1, 2, 3 = ≥ 3).
- M1: M0 + `meyve`, `sebze` (7 = günde bir ya da daha fazla, 3 = haftada 4–6, 4 = haftada 1–3, 5 = haftada birden az, 6 = hiç).
- M2: M1 + `yurume`, `bisiklet`, `spor` (haftada gün, 0–7 tam sayı), `faaliyet` (1–3), `yakin` (1 = hiç, 2 = 1–2, 3 = 3–5, 4 = ≥ 6), `ilgi` (5 çok, 4 biraz, 3 belirsiz, 2 az, 6 hiç), `komsu` (1 çok kolay … 5 çok zor).
Geçersiz ya da eksik kodda ve modelin gerektirdiği bir sütun yoksa açıklayıcı hatayla durur. Tek kişilik girdi de skorlanır. Düzeyler ve referanslar `Codes/tasarim.R` (`tasarim_duzeyleri`) ve `Results/model_cekilisleri/terimler.csv`'de. Yollar betiğin kendi konumuna göre çözülür; `source()` ya da `Rscript` ile herhangi bir klasörden çalışır. (`tasarim_kur`'un duyarlılık F için kullandığı `depresyon` sütunu 0/1 bekler; M0–M2'de yoktur.)

Tekrar üretim denetimi: `python Codes/sayilar_karsilastir.py eski/sayilar.json Results/sayilar.json` iki koşunun bütün sayısal alanlarını karşılaştırır (süre alanları hariç).

## Önbellekler

`R_Data ve Python Data/onbellek/` altında. Dosya varsa yeniden hesaplanmaz. Önbellek adları girdilerin özetini taşır:
- CV uyumları ve tam veri modelleri: model, varyant, tekrar, kat, ısınma/örnekleme sayısı, Stan tohumu ve `model_anahtar` (tasarım matrisi, sonuç, ağırlık, hane, beş kat ataması, öncel ölçekleri, sağ taraf listeleri ve `prior_kur` kodunun özeti).
- Öncel öngörü: tasarım matrisi, ağırlık, model listeleri, tohum ve fonksiyon kodu.
- Bootstrap: skorlar, tabakalar, kapasiteler, y, w, hane indeksi, eşitlik tabakaları, alt grup değişkenleri, çarpan matrisi ve `secim_kesri`, `tabakali_secim`, `olcu_tablo` kodları.
- Model temelli Δ: kullanılan CV dosyalarının md5'leri, y, w, tasarım matrisi, katlar ve seçim fonksiyonu.
- Performans: skorlar, y, w, hane indeksi, çarpan matrisi ve fonksiyon kodları.

Bu girdilerden biri değişirse ilgili adım yeniden hesaplanır. Anahtarın kapsamadığı değişiklikler (örneğin `brm_kur`'un örnekleyici ayarları ya da paket sürümleri) için ilgili önbellek elle arşive taşınmalıdır. `stan/` derlenmiş Stan modellerini tutar; silinirse yeniden derlenir.

**Temiz çalıştırma:** `onbellek/`, `R_Data ve Python Data/` altındaki türetilmiş dosyalar (`tsa2022.*` dahil), `Results/` ve `Figures/` bir arşiv klasörüne taşınır; `analiz.R` gerekli klasörleri kendisi kurar. Kodun üretmediği elle yazılmış dosyalar (`Figures/figur_altyazilari.md`, `Results/log/_ilk_kosu_s1500/`) taşınmaz ya da koşudan sonra geri konur. Eski önbellek arşivleri de arşive taşınır. Pilot yalnız `Results/log/pilot_sureleri.csv` yoksa koşar (temiz koşuda koşar).

**Ortam değişkenleri:** `TSA_KAYNAK` (ham veri klasörü; varsayılan `R_Data ve Python Data/kaynak`), `PY_YORUMLAYICI` (Python; varsayılan `~/veri-ortami/bin/python3`, yoksa `python3`).

**Beklenen yeniden üretim:**
- Aynı makine, aynı derleyici ve paket sürümleriyle bit düzeyinde.
- Başka bir makinede ya da derleyicide Stan çekilişleri değişir. Sonuçlar Monte Carlo hatası içinde kalmalıdır; birincil Δ(0,20) için MC SD ≈ 0,04/1.000.
- Ham CSV'nin md5'i her koşuda parquet'in okunduğu dosyayla karşılaştırılır (`dogrulama_kontrolleri.csv`).
- Figür yazı tipi depoyla birlikte gelir (`Codes/fonts/`); sistem fontuna bağlı değildir.
- R paket kilidi: `renv.lock` (proje kökü; `Rscript Codes/renv_kilidi.R` ile). İçeriği: doğrudan kullanılan 14 paket, oturumda yüklenen 7 brms önerisi, renv ve bağımlılıkları; toplam 137 paket. Depolar CRAN ve cmdstanr için `https://stan-dev.r-universe.dev`; ikisi de kilitte kayıtlı, `renv::restore()` ile kurulur. CmdStan 2.40.0 ayrıca `cmdstanr::install_cmdstan(version = "2.40.0")` ile kurulur. Projede `renv/` klasörü ya da `.Rprofile` yok. Python sürümleri `Results/python_ortam.txt`'te; tam oturum `Results/sessionInfo.txt`.
- Önbellek anahtarları `rlang::hash` ve `deparse` çıktısına dayanır; R ya da rlang sürümü değişirse anahtarlar değişebilir ve 230 CV uyumu (~50 dk) yeniden kurulur. Bu yanlış sonuç vermez, yalnız süre ekler.

Derleme notu: CmdStan'in önceden derlenmiş başlık dosyaları (PCH) bu Mac'teki güncel clang ile uyumsuz olduğundan modeller `PRECOMPILED_HEADERS=false` ile derlenir (`brm_kur` içinde `stan_model_args`). Sonuçları etkilemez, yalnız derleme süresini.

## Tohumlar

- Genel: `set.seed(20261101)` (betik başı).
- Kat atamaları: tekrar r için `20261110 + r` (r = 1–5); hane düzeyinde dengeli rastgele permütasyon.
- Prior predictive check: 20261102.
- Tam veri modelleri (Stan): 20261111 (M0), 20261112 (M1), 20261113 (M2).
- CV uyumları (Stan): `20261200 + 1000 × tekrar + 10 × kat + 100000 × model-varyant sırası` (`cv_tohum`).
- Seçim fonksiyonu birim testleri: 20261120.
- Hane bootstrap'ı: 20261131 (B = 2.000; aynı çarpan matrisi bütün stratejilerde, kapasitelerde, duyarlılıklarda ve performans ölçütlerinde kullanılır).
- Monte Carlo hatası denetimi: 20261141.

## Süreler (64 GB, 18 çekirdekli Mac)

Her koşunun adım süreleri `Results/log/analiz_sureleri.csv`'ye (son koşu) ve koşu kimliğiyle `Results/log/analiz_sureleri_gecmis.csv`'ye (bütün koşular) yazılır; pilot süreleri `Results/log/pilot_sureleri.csv`. `analiz.R`'nin konsol çıktısı `sink` ile `Results/log/analiz_log.txt`'e de yazılır (her koşuda üzerine yazılır).
- Sıfırdan tam koşu (temiz çalıştırma, 01.11.2026): 42,4 dk; 39,1 dk'sı CV uyumları (1.000 + 6.000 × 4 zincir; ağırlıklı (C) uyumlar en yavaşı). Sonuçlar önceki koşuyla bit düzeyinde aynı: `sayilar.json`'ın bütün alanları, bütün csv'ler (süre sütunları hariç), figür verileri, figür PNG'leri ve kişi düzeyi parquet'ler. Konsol logu `Results/log/kosu_temiz.txt`.
- Önbellekli koşu: ~20 sn (skorla doğrulaması dahil); bootstrap, model temelli Δ ve performans yeniden hesaplanırsa ~40 sn.
- Figürler: ~5 sn.

Temiz çalıştırmanın adım süreleri `Results/log/analiz_sureleri_gecmis.csv`'de (koşu 2026-11-01 01:36).

## Ortam

- R 4.6.1 (Apple Accelerate BLAS); brms 2.23.0, cmdstanr 0.9.0, CmdStan 2.40.0, posterior 1.7.0, WeightedROC 2026.8.27; tam liste `Results/sessionInfo.txt`.
- Python 3.13 (`~/veri-ortami`, uv sanal ortamı); paketler `Results/python_ortam.txt`.
- Paralel hesap: CV'de 4 işçi × 4 zincir (16 süreç), bootstrap'ta 14 işçi; işçilerde `VECLIB_MAXIMUM_THREADS = 1`. GPU (OpenCL) denendi, çalışmadı (pilot).

## Veri güvenliği

Mikro veri ve kişi düzeyindeki ara dosyalar (CV tahminleri `cv_tahminleri.parquet|.csv` dahil, CV posterior çekilişleri, model nesneleri) yalnız `R_Data ve Python Data/` altında; `Results/` ya da `Figures/` altına kopyalanmaz ve 5429 sayılı Kanun gereği hiçbir çevrim içi hizmete yüklenmez. `Results/` ve `Figures/` yalnız toplulaştırılmış çıktı içerir. `Results/model_cekilisleri/` altındaki dosyalar model parametrelerinin posterior çekilişleridir (sabit terim ve katsayılar); hiçbir satırı bir kişiye karşılık gelmez, parametre çekilişleri mikro veri içermez. Ağırlıksız n < 20 olan hücrelerde tahmin verilmez, 20–50 arası işaretlenir.
