# İki beslenme sorusu ve kapasite kısıtı altında depresif belirti önceliklendirmesi: Analiz Talimatı

> Arşiv sürümü (v1.0.0): dergi ve özel sayı bilgisi, önceki çalışmaların ve klasörlerin adları, kullanıcı yolları ve çalışma ortamına ilişkin notlar köşeli parantez içinde çıkarıldı ya da `~/` ile kısaltıldı; belgenin muhatabı "analist" olarak anıldı. Analiz tanımlarında, sayılarda ve kurallarda hiçbir değişiklik yapılmadı. Çıktılardaki "talimat Bölüm …" atıfları bu belgenin bölümleridir.

Sürüm 1.1, 31 Ekim 2026 (1.0'dan farkı: [makale şablonu dosyasının adı]; alt grup kapsamına eğitim eklendi). Bu belge analizi yürütecek analiste yazılmıştır. Makaleyi biz yazacağız; senden istenen, aşağıdaki analizlerin tamamını bitirmiş, dosyalanmış, yeniden üretilebilir ve raporlanmış olarak teslim etmendir.

Okuma sırası:

1. Bu belgenin tamamı.
2. Veri klasöründeki sözlükler: `TSA2022_kodlama_sozlugu.R` (kmap ve vlab nesneleri), `TSA2022_Olcek_ve_Degisken_Sozlugu.docx` ve gerektiğinde `turkiye-saglik-arastirmasi.pdf`.
3. Biçim ve işleyiş örneği olarak önceki çalışmalar: `../[önceki çalışma 1]/Rapor.md`, `../[önceki çalışma 1]/Codes/README_kodlar.md` ve `../[önceki çalışma 2]/[analiz planı]`. Klasör düzeni, Rapor.md yapısı, tablo kurucu ve figür stili için örnek olarak oku. O çalışmaların verisi (GYKA), sorusu ve sonuçlarıyla bu çalışmanın ilgisi yoktur; hiçbir sonucu veya tanımı oradan taşıma.

[Çalışma ortamına ilişkin not çıkarıldı.] Proje kökü dışındaki hiçbir klasöre yazma; veri klasörünü salt okunur say.

Sorularını ve kararlarını `Rapor.md` içinde tut. Bizden cevap beklemeden ilerleyebileceğin her yerde varsayılan kararı uygula ve kaydet.

---

## 0. Çalışmanın özü

**Soru.** Depresif belirti soruları kullanılmadan yapılan bir önceliklendirmede, iki meyve ve sebze tüketim sıklığı sorusu rutin özelliklere eklendiğinde, aynı değerlendirme kapasitesiyle kaç ek PHQ-8 pozitif yetişkin seçilebilir?

**Karar bağlamı.** Her 1.000 uygun yetişkinden yalnız bir bölümünün ayrıntılı ruhsal değerlendirmeye davet edilebildiği bir planlama senaryosu. Birincil senaryo %20 kapasitedir; %10 ve %30 ile sürekli kapasite eğrisi bağlamı verir. Kapasiteler ölçülmüş kurum kapasiteleri değildir; analitik senaryolardır ve ikisi veri içi çapaya göre konumlanır: uygun grupta ağırlıklı PHQ-8 ≥ 10 payı yaklaşık %4,57 ve standart PHQ-2 ≥ 3 kuralının ima ettiği iş yükü yaklaşık %5,58. Senaryolar bu kuralın tetikleyeceğinden daha geniş değerlendirme kapasitesi durumlarını temsil eder; bunu raporda ve Methods notlarında böyle yaz.

**Makale.** Taslak başlık: "Do Two Diet Questions Improve the Prioritization of Adults for Depressive-Symptom Assessment? Evidence from a Nationally Representative Health Survey in Türkiye". [Hedef dergi bilgisi çıkarıldı.] Araştırma makalesi; raporlama çerçevesi TRIPOD+AI. [Makale şablonu dosyasına ilişkin not çıkarıldı.]

**Tasarım türü.** 2022 kesit verisi üzerinde geçmişe dönük önceliklendirme değerlendirmesi ve planlama simülasyonu. İleriye dönük tahmin, tanı doğrulama veya tarama programı değerlendirmesi değildir. Sonuç PHQ-8 pozitifliğidir; klinik tanı değildir.

**Araştırma soruları.** Yönlü hipotez yoktur. Beslenme katkısının sıfıra yakın çıkması da araştırma sorusunun geçerli bir yanıtıdır; sonucu güzelleştirmeye çalışma.

- RQ1 (birincil): %20 kapasitede beslenme modelinin temel modele göre ek saptama verimi, Δ(0,20) = D_M1(0,20) − D_M0(0,20).
- RQ2: Fiziksel aktivite ve sosyal destek bilgisinin beslenme sonrası ek katkısı, M2 − M1.
- RQ3: Seçim ve kaçırma hangi yaş, cinsiyet ve gelir gruplarında yoğunlaşıyor; gelir gruplarında eşit seçim oranı kuralı toplam saptamayı nasıl değiştiriyor?
- Bağlam karşılaştırıcıları: rastgele seçim, kusursuz sıralama (tavan) ve PHQ-2 (belirti temelli karşılaştırıcı).

**Veri.** TÜİK Türkiye Sağlık Araştırması 2022 mikro verisi. Kaynak klasör (salt okunur): `[veri klasörü]`. Ham dosya `TSA_2022_MIKROVERI_REV.csv`: noktalı virgül ayraçlı, 29.761 veri satırı, 295 sütun. Aynı klasördeki `TSA2022_kodlanmis_veriseti.rds` ve `TSA2022_turetilmis_veriseti.rds` başka bir çalışma için üretilmiştir; çapraz kontrol dışında kullanma (Bölüm 12).

**Uygun grup.** 18 yaş ve üzeri, son 12 ayda pratisyen veya aile hekiminden hizmet almış (AILE_PRTS_HEK_HIZALMDRM = 3) ve son 12 ayda psikolog, psikoterapist ve psikiyatristin hiçbirine gitmemiş kişiler.

**Doğrulanmış sayılar.** Aşağıdaki değerler 28 Ekim 2026'da ham CSV'den bağımsız olarak yeniden üretildi. Aşama 0'daki kapın bunlardır:

| Büyüklük | Değer |
|---|---|
| Veri satırı; sütun | 29.761; 295 |
| 18+ yetişkin | 21.444 |
| 18+ içinde eksik PHQ-8 maddesi olan kişi | 0 |
| Uygun grup | 12.843 |
| Uygun gruptaki hane sayısı | 7.726 |
| Uygun grupta PHQ-8 ≥ 10 | 581 (ağırlıklı %4,57) |
| 581 içinde meyve ve sebzenin ikisi de günlük değil | 332 |
| 18+ içinde PHQ-8 ≥ 10, ikisi de günlük değil, ruh sağlığı teması yok | 470 = 332 (hekim teması var) + 138 (yok) |
| Uygun grupta PHQ-2 ≥ 3 ağırlıklı pay | %5,58 |
| Uygun grupta PHQ-2 = 2 ağırlıklı pay | %20,25 |
| Uygun grupta eksik öngörücü | yalnız 1 kişide HANE_GELIR_GRUP |

**Senin ürünün.**

- Kodlar (`Codes/`).
- Veri setleri (`R_Data ve Python Data/`).
- Sonuç tabloları (docx, csv, xlsx).
- Figürler (PNG, PDF, TIFF).
- `sayilar.json`.
- `Rapor.md` ve `README_kodlar.md`.
- İngilizce figür altyazı ve tablo notu taslakları.
- `Rapor.md` içinde İngilizce Methods notları ve LaTeX denklemler.
- `tripod_ai_notlari.md`: TRIPOD+AI maddelerine göre, her maddenin hangi çıktı veya karardan karşılanacağına ilişkin notlar.

Makale metnini yazma.

---

## 1. Klasör yapısı ve dosya kuralları

Proje kökü: `[proje kökü]/`. Bütün komutlar kökten çalıştırılır; göreli yollar köke göredir.

```
[proje kökü]/
  [makale şablonu]                  (dokunma)
  [yazarların literatür notları]    (dokunma)
  [bu belge]
  Rapor.md                          (sen yazacaksın)
  Codes/
    README_kodlar.md
    analiz.R                        (tek giriş noktası)
    figurler.py, figur_stili.py, etiketler.json
    xlsx_simge.py                   ([önceki çalışma 1]'den kopyalanabilir)
  Figures/                          (Figure1–3: png/pdf/tiff; figur_altyazilari.md)
  Figures/Supplementary/
  R_Data ve Python Data/            (parquet, rds, csv; yalnız burada kişi düzeyi veri)
  R_Data ve Python Data/onbellek/   (Stan modelleri, CV tahminleri, posterior çekilişleri, bootstrap)
  R_Data ve Python Data/figur_verileri/
  Results/                          (Table1–2 docx/csv, tablolar_tumu.xlsx, sayilar.json, ...)
  Results/Supplementary/
  Results/denetim/                  (doğrulama ve tanı çıktıları; yayın öğesi değil)
  Results/log/
  docs/                             (bu belgenin arşiv kopyası, CHANGELOG.md)
```

**Ham veri.**

- `TSA_2022_MIKROVERI_REV.csv` bir kez okunur: `read_delim(delim = ";", col_types = cols(.default = col_character()), na = c("", "NA"), locale = locale(encoding = "UTF-8"))`.
- Kod çözümü `TSA2022_kodlama_sozlugu.R` içindeki kmap ile yapılır; ama analiz değişkenlerinin tamamını bu talimattaki tanımlarla kendin türet.
- `R_Data ve Python Data/tsa2022.parquet` ve `.rds` yazılır; kullanılan kod eşlemeleri `sozluk.csv` ve `kodlar.csv` olarak aynı klasöre gider.

**Yeniden kullanım.** `../[önceki çalışma 1]/Codes/` altından `figur_stili.py`, `xlsx_simge.py` ve `analiz.R` içindeki `tablo_cikar` (flextable + xlsx tablo kurucu) alınabilir. Kopyaladığın her parçayı `Rapor.md`'de belirt ve bu çalışmaya göre denetle.

**Tek komutla üretim.**

- `Rscript Codes/analiz.R` sırasıyla üretir: okuma ve doğrulama; değişken kurulumu; modeller; çapraz doğrulama; kapasite ve senaryo analizleri; performans; duyarlılıklar; tablolar, figür verileri ve `sayilar.json`.
- Ardından `~/veri-ortami/bin/python3 Codes/figurler.py` bütün figürleri `figur_verileri/*.csv` dosyalarından çizer. Figür kodu veri hesaplamaz.
- Uzun hesaplar önbelleklenir; dosya varsa yeniden hesaplanmaz.

**Veri güvenliği.**

- Kişi düzeyindeki dosyalar yalnız `R_Data ve Python Data/` altında durur. `Results/` ve `Figures/` yalnız toplulaştırılmış çıktı içerir.
- Ağırlıksız n < 20 olan hücrelerde tahmin verilmez; 20–50 arası hücreler işaretlenir. Bu kural figürler için de geçerlidir.
- Mikro veri 5429 sayılı Kanun gereği hiçbir çevrim içi hizmete yüklenmez.

---

## 2. Çalışma kuralları (kalıcı tercihlerimiz)

### Kod

- Veri düzenleme, Bayesçi modeller, çapraz doğrulama, kapasite analizleri ve tablolar R'de; figürler Python'da (matplotlib, yorumlayıcı `~/veri-ortami/bin/python3`). Bir figür R'de daha iyi olacaksa R kullanabilirsin; gerekçesini raporla.
- Önce veri düzenleme, ardından analiz gelir; hepsi `analiz.R` içinde ilerler. Her parça kaldığı yerden devam eder; önceki parçalardaki nesneler ve paketler tekrar kurulmaz.
- Kod bir yıl sonra açıldığında baştan sona hatasız ve aynı sonuçlarla çalışmalı. Tohumlar sabittir ve `README_kodlar.md`'de yazılıdır.
- R kodunda `#` ile açıklama veya bölüm başlığı satırı yazma; `# ====`, `# ----` gibi ASCII süslemeler yok. Gereken her karakter (ı, ş, ğ, ≥, ±) doğrudan karakter olarak yazılır, kaçış koduyla değil; dosyalar UTF-8. Değişken adları ASCII ve küçük harfli kalabilir.
- Python'da ASCII kuralı geçerli değildir; kod yine açıklama satırlarından arındırılmış ve sade olsun.
- Paket atıfları uydurulmaz. `citation("paket")` çıktıları `Results/paket_atiflari.txt`'e yazılır. Önemli olanlar analizde doğrudan rol oynayan paketlerdir (brms, cmdstanr ve Stan, posterior, splines ve AUC hesabında kullanılan paket). Yardımcı paketleri de listele, rollerini ayrı yaz. Python kütüphanelerinin önerdiği atıflar aynı dosyaya girer. `sessionInfo()` çıktısı `Results/sessionInfo.txt`'e, Python ortamı `Results/python_ortam.txt`'e.

### Donanım

- Mac: 64 GB bellek, 18 çekirdek CPU, 40 çekirdek GPU.
- CPU'da en çok 16 iş parçacığı: Stan'de 4 zincir × 4 iş parçacığı (`threads = threading(4)`, gerekirse `reduce_sum`). Kat düzeyinde paralellik kurarsan toplam iş parçacığı yine 16'yı aşmasın.
- Modeller küçük lojistik modellerdir; CPU varsayılandır. İstersen pilotta brms `opencl()` seçeneğini dene; çalışıyor ve hızlıysa kullan, değilse CPU'da kal. Denemenin sonucunu ve her adımın süresini `Rapor.md` Bölüm 12'ye yaz.
- Önce kısa bir pilot koşu yap; tek model ve tek kat süresinden toplam süre bütçesini çıkar ve raporla.

### Ağırlık ve tasarım

- Analiz birimi kişidir; ağırlık FERTFAKTOR. Ham sütun ondalık virgüllüdür, açıkça sayıya çevrilir (Bölüm 12).
- Modeller ağırlıksız kurulur. Gerekçe "sıralamada ağırlık gerekmez" değildir; ağırlıksız eğitim bu çalışmada tercih edilen öğrenme yaklaşımıdır ve ağırlıklı eğitim aynı çapraz doğrulama düzeninde duyarlılık olarak sınanır (Bölüm 9 C). Bütün nüfus düzeyi büyüklükler (D, duyarlılık, PPV, eşikler, paylar) FERTFAKTOR ile ağırlıklı hesaplanır.
- Kapasite ağırlıklı nüfus üzerinden uygulanır: seçilenlerin ağırlıklı payı c olur; eşik ağırlıklı kantille belirlenir (Bölüm 7).
- Tabaka ve birincil örnekleme birimi değişkenleri veride yoktur. Hane içi benzerlik kat bloklaması ve hane kümesi bootstrap ile ele alınır; tasarım belirsizliğinin eksik tahmin edilmiş olabileceği sınırlılık olarak raporlanır.
- Tablolarda n ağırlıksız, yüzdeler ağırlıklıdır; bu durum tablo notunda yazar.

### Dil, terimler ve çıktı biçimi

- Rapor ve karar defteri Türkçe. Figür içindeki bütün yazılar, tablo başlıkları, sütun adları, notlar ve altyazılar Amerikan İngilizcesi. Ortak metinler `Codes/etiketler.json`'da tek yerden tanımlanır; R tabloları da aynı dosyayı okur.
- Nedensel dil yok: "association", "difference", "detection yield", "conditional on". "Effect", "impact", "because of" yok.
- Terimler:
  - Sonuç: "high depressive-symptom burden (PHQ-8 ≥ 10)", kısaca "PHQ-8 positivity". "Depression cases", "diagnosis", "stress" değil.
  - İş: "prioritization for assessment". "Screening program", "case finding" değil.
  - Birincil ölçüt: "detection yield: selected PHQ-8–positive adults per 1,000 eligible adults".
  - PHQ-2 her geçtiğinde bir kez şu nitelik belirtilir: PHQ-8 ile iki madde paylaşan belirti temelli karşılaştırıcı; üst sınır değil.
  - Kronik değişken: "number of reported chronic conditions other than depression and substance-use disorder".
- **Tablolar.** flextable ile docx, aynı içerikte csv ve `Results/tablolar_tumu.xlsx` (sayfa başına bir tablo; alt ve üst simgeler `xlsx_simge.py` ile gerçek biçimde). Times New Roman, hücreler 9 pt, notlar 8 pt. Yalnız üst ve alt çizgiler ile başlık altı çizgisi. Birbirini kapsayan başlıklar birleşik hücre; grup başlıkları bir kez yazılır. "Decision", "Reject" gibi sütun yok. Q~1~–Q~3~ gibi gösterimlerde gerçek alt simge.
- **Figürler.** Üstte "Figure 1." başlığı olmaz. Paneller aynı figürde kurulur ve dergi biçiminde (**a**), (**b**) etiketlenir. 600 dpi PNG, yazı tipi gömülü PDF ve LZW TIFF. Varsayılan matplotlib görünümü kabul edilmez; önceki çalışmaların font ailesi korunabilir (Avenir Next, yoksa Helvetica Neue; temel 8 pt, panel harfi 11 pt kalın). Bu çalışmanın kendine ait, renk körlüğüne uygun bir paleti olsun; kadın ve erkeği pembe ve mavi gibi kalıp renklerle kodlama. Çift eksen yok. Her figürün İngilizce altyazı taslağı `Figures/figur_altyazilari.md`'ye yazılır, kısa tutulur.
- **Denetim çıktısı ile yayın çıktısını ayır.** Tanı grafikleri `Results/denetim/` ve `Results/log/` altında kalır ve raporda özetlenir; her biri Supplementary öğesine dönüşmez.

### Rapor.md

[Önceki çalışmalardaki] yapıyı kullan:

0. Durum: son güncelleme, aşama, bitenler, sırada ne var, tahmini süre. Uzun koşularda ilerleme satırı.
1. Aşama günlüğü: her aşama için amaç, yapılan, bulunan, üretilen dosyalar.
2. Karar defteri: K1, K2, ... Her kayıtta karar, gerekçe, alternatif ve etkisi. Sonuçlar görüldükten sonra alınan kararlar ayrıca işaretlenir.
3. Doğrulama kontrolleri.
4. Çapraz doğrulama ve bootstrap protokolü.
5. Model kurma protokolü ve tanılar: kontrol, ölçüt, sonuç, karar.
6. Nihai değişken tanımları.
7. Ana sayılar (Results için).
8. Methods notları (İngilizce taslak cümleler ve LaTeX denklemler).
9. Araştırma sorularının değerlendirmesi: her biri için kanıt ve iddianın düzeyi.
10. Bize sorular: her soru için uyguladığın varsayılan karar.
11. Eksikler ve yapılamayanlar.
12. Dosya envanteri ve süreler.
13. İç denetim turları.

Her aşama bittiğinde ve 30 dakikayı aşan her hesabın ortasında güncelle.

### İnisiyatif

Bu belge bir başlangıç tasarımıdır, mekanik bir liste değildir. Gerekçeli yargı kullanmanı istiyoruz.

**Sen karar verirsin; gerekçeyi karar defterine yazarsın:**

- Örnekleyici ayarları, iterasyon sayıları (Bölüm 5'teki alt sınırlar ve ölçütlerle), `adapt_delta`.
- Sıfır olaylı kategori birleştirmeleri (Bölüm 4'teki kuralla).
- Prior ölçeklerinin prior predictive check'e göre düzeltilmesi (sonuçlar görülmeden).
- Hesaplama yolu (CPU veya GPU), önbellekleme, bellek yönetimi.
- Figür düzeni (stil içinde) ve tablo ayrıntıları.
- Bir tanının gerektirdiği orantılı düzeltme.

**Ek analiz ekleyebilirsin.** Ayrı bir soruyu yanıtlıyorsa veya ana sonucun bağlı olduğu önemli bir belirsizliği değerlendiriyorsa; hangi soruyu yanıtladığını yaz. Gerekçesiz genişletme yapma.

**Bize sorarsın; soruyu yazar ve varsayılanla devam edersin:**

- Uygun grup, sonuç veya maruziyet tanımında değişiklik.
- Birincil kapasitenin, Δ tanımının veya ±1/1.000 sınırının değiştirilmesi.
- Bir ana analizin çıkarılması veya bir nüfus grubunun dışlanması.
- M0'ın değişken kümesinin değiştirilmesi (Bölüm 9 F'deki duyarlılık hariç).

**Bu planda bir hata veya veriyle uyuşmayan bir varsayım görürsen** kanıtıyla "Bize sorular"a yaz, en makul düzeltmeyi uygula ve devam et.

**Sonuçlara bakarak tanım değiştirme.** Sonuçlar görüldükten sonra yapılan her değişiklik karar defterinde öyle işaretlenir.

---

## 3. Aşama 0: Okuma ve doğrulama (kapı)

1. CSV'yi oku, kmap ile kod çözümünü uygula; satır ve sütun sayısını doğrula.
2. FERTFAKTOR'u ondalık virgülden sayıya çevir; özeti raporla (negatif veya sıfır ağırlık olmamalı).
3. PHQ-8 maddelerini puanla. Sekiz madde: ZEVK_DUYMA, BUNALIM, UYKU_SORUN, YORGUNLUK, ISTAHSIZLIK, DEGERSIZ_HISSETME, KONSANTRASYON_PRB, HUZURSUZLUK. Ham kodlar 6 = Hic = 0, 16 = Bazi gunler = 1, 17 = Bir haftadan fazla = 2, 18 = Neredeyse her gun = 3. Toplam 0–24; yalnız sekiz maddenin tamamı doluysa hesaplanır. PHQ-2 = ZEVK_DUYMA + BUNALIM puanı, 0–6.
4. Uygun grubu kur: YAS ≥ 18; AILE_PRTS_HEK_HIZALMDRM = 3; SON12AY_PSIKOLOG, SON12AY_PSIKOTERAPIST ve SON12AY_PSIKIYATRIST'in hiçbiri Evet değil. Üçünün de Hayir olduğu tanımla "hiçbiri Evet değil" tanımının aynı sayıyı verdiğini de doğrula (vermeli; uygun grupta bu üç değişkende eksik yok).
5. Bölüm 0'daki doğrulanmış sayılar tablosundaki her değeri yeniden üret ve `Results/dogrulama_kontrolleri.csv` dosyasına yaz (büyüklük, beklenen, bulunan, fark). HERHANGİ BİRİ UYUŞMUYORSA DUR: farkın olası nedenini raporla, "Bize sorular"a yaz ve modellere geçme.
6. Eksik veri dökümü: uygun grupta her analiz değişkeni için eksik sayısı ve yüzdesi → `Results/denetim/eksik_veri.csv`. Beklenti: yalnız 1 kişide HANE_GELIR_GRUP eksik; EGITIM = 99 (Bilinmeyen) varsa o kişiler de eksik sayılır ve sayısı raporlanır.

---

## 4. Aşama 1: Değişken kurulumu

Analiz çerçevesi uygun gruptur; öngörücülerde tam veri (complete case) kuralı uygulanır. Beklenen analiz çerçevesi 12.842 kişidir (1 gelir eksiği); EGITIM = 99 nedeniyle ek düşüş olursa raporla. Düşen her kişi sayılır ve `Rapor.md`'ye yazılır.

Önceden belirlenmiş kodlama; değiştirme:

- Sonuç: `phq_pos = 1(PHQ8 >= 10)`.
- Yaş grupları: 18–34, 35–49, 50–64, 65+ (referans 18–34).
- Cinsiyet: CINSIYET, referans Erkek (kod 1).
- Eğitim, dört küme (referans ilkokul ve altı):
  - İlkokul ve altı: kodlar 6 (Okuma-yazma bilmeyen), 1 (Bir okul bitirmedi), 2 (İlkokul).
  - Ortaokul: 31, 32, 33.
  - Lise: 4.
  - Yükseköğretim: 511, 512, 52, 53.
  - 99 (Bilinmeyen) eksik sayılır. Eşlemeyi `Results/degisken_tanimlari.csv`'ye yaz.
- Gelir: HANE_GELIR_GRUP'un 20 bandı, uygun gruptaki ağırlıklı kümülatif paylara göre beş gruba indirilir. Kesimler kümülatif ağırlıklı payın %20, %40, %60 ve %80'e en yakın olduğu bantlardan geçer. Beklenen gruplama 1–10 / 11–13 / 14–17 / 18–19 / 20 (ağırlıklı paylar yaklaşık %20,6 / %20,1 / %19,1 / %20,4 / %19,8). Gerçekleşen gruplamayı ve payları logla; referans en düşük grup. Eşitlik senaryosunun birimi de bu beş gruptur.
- Kronik durum sayısı: 22 KRONIKHAST_ değişkeninden KRONIKHAST_DEPRESYON ve KRONIKHAST_MADDEKUL çıkarılır; kalan 20 maddede Evet sayısı → 0 / 1 / 2 / 3+ kategorileri (referans 0). Sayılan maddeleri logla. KRONIKHAST_DEPRESYON Bölüm 9 F'deki duyarlılık için ayrı değişken olarak saklanır.
- Meyve ve sebze sıklığı: MEYVE_YEMESIKLIK ve SEBZE_SALATA_YEMESIKLIK, beşer kategoriyle olduğu gibi, ayrı değişkenler. Sıklık sırası ham kod sırası değildir: 7 = günde bir veya daha fazla (referans), 3 = haftada 4–6, 4 = haftada 1–3, 5 = haftada birden az, 6 = hiç. Kategoriler birleştirilmez; yalnız bütün örneklemde sıfır olaylı (phq_pos = 1 içermeyen) kategori çıkarsa komşu sıklık kategorisiyle birleştirilir ve loglanır. Her kategorideki kişi ve olay sayısı raporlanır.
- Aktivite (M2): YURUME_10DAK_GUN, BISIKLET_GUN, SPOR_GUN gün sayıları (0–7, sayısal, olduğu gibi; aralığı doğrula) ve GUNLUK_FAALIYETDURUM (üç kategori, referans "çoğunlukla oturan veya duran"). Alanlar toplanmaz; "toplam aktif gün" türetilmez.
- Sosyal destek (M2): GUVENILIR_YAKIN (4 kategori), CEVRE_ILGI (5), KOMSU_YARDIM (5); anket kategorileriyle, referans her birinde ilk kod. Katsayılar yalnız Supplementary içindir; referans seçimi sıralamayı etkilemez.
- `w = FERTFAKTOR`, `hh = hane`, kişi kimliği hane + FERTNO.

Table 1 verisi: analiz çerçevesinde değişkenlerin dağılımı, PHQ-8 pozitif ve negatif sütunlarıyla; ağırlıksız n, ağırlıklı yüzde → `Results/table1_veri.csv`.

---

## 5. Aşama 2: Modeller ve önceller

Üç Bayesçi lojistik model (brms, `bernoulli(logit)`, cmdstanr arka ucu), hepsi aynı analiz çerçevesinde:

- M0: yaş grubu + cinsiyet + eğitim + gelir grubu + kronik durum sayısı.
- M1: M0 + meyve sıklığı + sebze sıklığı.
- M2: M1 + yürüme + bisiklet + spor gün sayıları + günlük faaliyet durumu + üç sosyal destek maddesi.

Model denklemi (Methods notlarına LaTeX olarak da yaz; Word denklemine biz çevireceğiz):

```
y_i ~ Bernoulli(pi_i)
logit(pi_i) = alpha + x_i' beta
beta_k ~ Normal(0, 1)
alpha ~ Student-t(3, 0, 2.5)
```

**Önceller.** Katsayılar Normal(0, 1), sabit terim Student-t(3, 0, 2,5). Prior predictive check yap: öncellerin ima ettiği pozitiflik payı dağılımını üret, `Results/denetim/oncel_ongoru.csv`'ye yaz. Ölçekler gerekirse sonuçlar görülmeden düzeltilir ve karar defterine kaydedilir. Olay sayısı (581) ile parametre sayısını (M1 yaklaşık 22, M2 yaklaşık 38) model protokolünde birlikte raporla; büzme öncelleri bu yükün gerekçesidir.

**Örnekleme.**

- Tam veri modelleri (katsayıları raporlanacak olanlar): 4 zincir, en az 1.000 ısınma + 1.500 örnekleme, sabit tohum.
- Çapraz doğrulama içi modeller: hedef dış kat posterior ortalama olasılıklardır; 4 zincir, en az 500 ısınma + 750 örnekleme ile başlayabilirsin. Ölçüt: her CV modelinde Rhat ≤ 1,01 ve yeterli bulk/tail ESS; p_hat'lerin Monte Carlo hatası sıralama ayrıntısına göre ihmal edilebilir olmalı. Sağlanmıyorsa iterasyonu artır ve logla.
- Tanılar `Results/denetim/model_tanilari.csv`: Rhat, ESS, divergence (sıfır olmalı), E-BFMI > 0,3.
- brms'te öngörücüsü eksik satır sessizce düşer; her modelde uyum öncesi ve sonrası satır sayısını denetle ve logla.

**Geri dönüş kuralları.**

1. Divergence veya Rhat sorunu: önce `adapt_delta` (0,95–0,99) ve iterasyon; çözülmezse parametrizasyonu gözden geçir, raporla.
2. Sıfır olaylı kategori: Bölüm 4'teki birleştirme kuralı; sonuçlar görüldükten sonra başka birleştirme yapılmaz.
3. Doğrulama sayısı uyuşmazlığı: dur ve sor (Aşama 0).

Tam veri katsayıları (OR, %95 posterior aralığı) üç model için `Results/Supplementary/katsayilar.csv`'ye; bunlar yalnız Supplementary içindir, Δ hesabında kullanılmaz.

---

## 6. Aşama 3: Hane bloklu çapraz doğrulama

- Birincil düzen: 10 katlı, hane bloklu CV. Aynı hanedeki (hh) herkes aynı kattadır; katlar hane düzeyinde rastgele atanır, tohum sabittir.
- Her katta M0, M1 ve M2 eğitim verisinde yeniden kurulur; dışarıda kalan kişiler için posterior ortalama olasılık p_hat üretilir. Böylece herkesin, eğitiminde görülmediği modelden bir p_hat'i olur. Üç model aynı bölünmeleri kullanır.
- Tekrar: aynı düzen 5 ayrı tohumla kurulur (tekrar 1 birincildir). Tekrar 1'de üç model de koşulur; tekrar 2–5'te M0 ve M1 zorunludur, M2 süre bütçesi elverirse eklenir. Tekrarlar bölünme duyarlılığı içindir (Bölüm 9 A).
- Tekrar 1'in dış kat posterior çekilişleri de saklanır (kişi başına en çok 1.000 çekilişe inceltilebilir); bunlar Bölüm 9'daki model temelli ikincil belirsizlik analizi içindir.
- Çıktı: kişi bazında `id, hh, w, phq_pos, phq2, p_hat_M0, p_hat_M1, p_hat_M2, kat, tekrar` → `R_Data ve Python Data/cv_tahminleri.parquet`.

---

## 7. Aşama 4: Kapasite analizi (birincil sonuç)

### Tanımlar

Ağırlıklı pozitiflik payı p (yaklaşık 0,0457) analiz çerçevesinden hesaplanır ve `sayilar.json`'a yazılır.

**Seçim kuralı (birincil).** Kapasite c'de, strateji m için seçim her değerlendirme katının içinde yapılır: katın ağırlıklı (1 − c) kantili eşik alınır ve eşik üzerindekiler seçilir; böylece her katta seçilenlerin ağırlıklı payı c olur. Eşik değerinde yığılma varsa sınır grubundan kesirli dahil etme uygulanır: sınır değerli kişiler, kalan kapasitenin sınır grubunun ağırlığına oranı kadar kesirle sayılır (rastgele eşitlik bozmanın beklenen değeri). Aynı kural her stratejide ve bootstrap içinde aynen kullanılır. Kantil ve kesir hesabını tek bir fonksiyonda topla ve birim testle doğrula (küçük elle kurulmuş örnekte beklenen seçim payını vermeli).

**Ölçüler** (katlar üzerinden birleştirilir: paydalar bütün çerçevenin ağırlık toplamları):

- Saptama verimi: D_m(c) = 1000 × Σ_seçilen w_i y_i / Σ w_i.
- Kapasitede duyarlılık: Sens_m(c) = Σ_seçilen w_i y_i / Σ w_i y_i.
- Seçilenlerde PPV: PPV_m(c) = Σ_seçilen w_i y_i / Σ_seçilen w_i.
- Özdeşlik: D = 1000 p Sens = 1000 c PPV. Üçü aynı yakalanan pozitif miktarının farklı ölçekleridir; Table 2 notunda bu yazılır, üç ayrı kanıt gibi sunulmaz.
- Birincil sonuç: Δ(c) = D_M1(c) − D_M0(c); birincil senaryo Δ(0,20). İkincil farklar: M2 − M1 ve M2 − M0.

**Karşılaştırıcılar.**

- Rastgele seçim (analitik): D_rand(c) = 1000 c p.
- Kusursuz sıralama (tavan, analitik): D_ideal(c) = 1000 min(c, p). Eğri p'ye kadar yükselir, sonra yataylaşır; sabit 45,7 çizgisi çizilmez.
- PHQ-2 sıralaması: phq2 puanına göre, kesirli dahil etme kuralıyla (0–6 arası kaba puan olduğundan sınır grubu büyüktür; %20 kapasitede eşik PHQ-2 = 2 grubunun içine düşer).
- PHQ-2 ≥ 3 politika noktası: ima ettiği kapasite = ağırlıklı PHQ-2 ≥ 3 payı (yaklaşık %5,58); o noktadaki D, Sens ve PPV hesaplanır ve Figure 2a'da tek nokta olarak işaretlenir.

**Kapasite ızgarası.** Birincil 0,20; tablo senaryoları 0,10 / 0,20 / 0,30; eğri için c = 0,02'den 0,50'ye 0,02 adımlarla bütün stratejiler → `R_Data ve Python Data/figur_verileri/kapasite_egrisi.csv`.

### Belirsizlik

**Birincil yöntem: eşlenik hane kümesi bootstrap.** Haneler yerine koyarak yeniden örneklenir, B = 2.000, tohum sabit. Her tekrarda aynı yeniden örneklenen haneler bütün stratejilerde ve bütün kapasitelerde kullanılır (eşlenik). Kat atamaları ve CV p_hat'leri sabittir; her tekrarda kat içi ağırlıklı eşikler, seçimler, D'ler ve Δ yeniden hesaplanır. Modeller yeniden kurulmaz; bu sınırlama raporda ve Methods notlarında açıkça yazılır: aralık, sabit model uyumları ve sabit kat atamaları koşuluyla hane örneklemesinden gelen belirsizliği kapsar, model geliştirme belirsizliğini kapsamaz.

- Ana sunum: Δ̂(0,20), yüzdelik %95 güven aralığı (2,5–97,5) ve önceden belirlenmiş pratik önem sınırı ±1/1.000. Sınırın işlevsel karşılıkları raporda yazılır: p = 0,0457'de ±1/1.000 yaklaşık 2,19 yüzde puan duyarlılık farkına, %20 kapasitede 0,50 yüzde puan PPV farkına karşılık gelir.
- Bootstrap tekrarlarının Δ > 1, |Δ| ≤ 1 ve Δ < −1 bölgelerindeki payları YALNIZ Supplementary'ye, "bootstrap tekrar oranı" adıyla yazılır. Bunlar posterior olasılık değildir ve posterior gibi adlandırılmaz; "P(Δ > 0)" biçiminde sunulmaz.
- Aynı bootstrap bütün tablo büyüklüklerinin (D, Sens, PPV, farklar) aralıklarını verir.

**İkincil yöntem (Supplementary):** tekrar 1'in saklanan dış kat posterior çekilişleriyle, her çekilişte çekiliş-özel olasılıklarla sıralama ve seçim yapılarak Δ(0,20) dağılımı üretilir. Bu, sabit veri ve sabit katlar koşuluyla model temelli bir dağılımdır; öyle etiketlenir.

### Eşitlik ve alt grup analizleri

- **Gelir gruplarında eşit seçim oranı senaryosu:** her gelir grubunun içinde ağırlıklı payı c olacak şekilde grup içi sıralama ve seçim (kat içi, aynı kesir kuralı). Kısıtsız seçimle karşılaştır: toplam D farkı ve gruplara göre duyarlılık → `Results/esitlik_senaryosu.csv`. Adlandırma "equal selection proportion across income groups"; "adil tarama" gibi bir genel etiket kullanılmaz. Grup içi duyarlılığı hedefleyen ayrı bir kural uygulanmaz.
- **Alt grup kapsamı:** c = 0,20'de M0 ve M1 altında yaş grubu, cinsiyet, eğitim ve gelir grubuna göre seçilenlerin dağılımı ve pozitiflerin grup içi yakalanma oranı (ağırlıklı) → `Results/altgrup_kapsami.csv`. Ağırlıksız n < 20 hücre kuralı geçerli.

### Hizmet kapsamı betimlemesi ve 470 grubu

- **Ana metin için tek betimleyici sayı:** 18+ nüfusta PHQ-8 ≥ 10 olan ve ruh sağlığı uzmanı teması bildirmeyen kişilerin (beslenme koşulu olmadan) ağırlıklı yüzde kaçının son 12 ayda hekim teması bildirdiği. Bu, uygun grup tanımının kapsamını gerekçeler → `sayilar.json`.
- **470 grubu yalnız Supplementary:** tanım (PHQ-8 ≥ 10 + meyve ve sebze ikisi de günlük değil + ruh sağlığı uzmanı teması yok), ağırlıksız ve ağırlıklı büyüklükler, 332/138 ayrımı → `Results/Supplementary/grup470.csv`. Ulaşma ve katılım varsayımlı senaryo tablosu üretilmez. Rapor notuna şu çekinceleri yaz (Supplementary metnine biz işleyeceğiz): 138 kişi uygun grubun dışındadır; grup sonuç bilgisiyle tanımlanmıştır; beslenme koşulu tanımın içindedir, bu yüzden M1'in bu grubu yakalaması ana başarı ölçütü değildir; uzman teması bildirmemek tanısız veya tedavisiz olmak demek değildir.

---

## 8. Aşama 5: Ayrım ve kalibrasyon (TRIPOD+AI)

Dış kat tahminleriyle (tekrar 1), ağırlıklı:

- AUC: M0, M1, M2 ve PHQ-2 puanı.
- Kalibrasyon: eğim ve kesişim; ağırlıklı onluk dilimlerle gözlenen–beklenen verisi → `Results/Supplementary/kalibrasyon.csv` ve bir Supplementary kalibrasyon figürü verisi.
- Çıktı: `Results/Supplementary/performans.csv`. Bunlar kapasite analizinin yerini almaz; modelin tahmin özelliklerini tamamlar.

---

## 9. Duyarlılık analizleri

Her biri tek bir soruyu yanıtlar; hepsinin çıktısı `Results/Supplementary/duyarlilik.csv` (uzun biçim: analiz, büyüklük, tahmin, aralık) ve raporda bir satır özet:

- **A. Bölünme duyarlılığı.** Tekrar 2–5 ile Δ(0,20) yeniden hesaplanır; beş tekrarın dağılımı raporlanır. Soru: birincil sonuç kat atamasına mı bağlı?
- **B. Birleştirme kuralı.** Kat içi seçim yerine bütün dış kat p_hat'leri tek havuzda sıralanıp tek ağırlıklı eşikle seçim. Soru: sonuç birleştirme kuralına duyarlı mı?
- **C. Ağırlıklı eğitim.** w_norm = n × w / Σw ile `weights(w_norm)` pseudo-posterior modeli, aynı CV düzeninde, M0 ve M1. Soru: ağırlıksız eğitim tercihi Δ'yı değiştiriyor mu?
- **D. Öncel ölçeği.** Katsayılar Normal(0, 2,5) ile M0 ve M1, tam CV. Soru: büzme ölçüsü sonucu değiştiriyor mu?
- **E. Sürekli yaş.** Yaş bantları yerine doğal spline (ns, df = 3), M0 ve M1, tam CV. Soru: bantlama Δ'yı değiştiriyor mu?
- **F. Depresyon bildirimi.** M0 + KRONIKHAST_DEPRESYON ve M1 + KRONIKHAST_DEPRESYON, tam CV; Δ bu bilgi varken yeniden hesaplanır. Soru: son 12 ay depresyon bildirimi kayıtta bilinseydi iki beslenme sorusunun katkısı kalır mıydı? (Bildirim penceresi sonuç penceresiyle örtüştüğünden birincil modellere konmaz; bu gerekçe raporda yazılır.)
- **G. Pratik önem sınırı.** ±0,5 ve ±2/1.000 sınırlarıyla aynı sunum (yalnız yeniden etiketleme, yeni hesap gerekmez).

Her duyarlılıkta seçim kuralı, bootstrap ve kapasite tanımı birincille aynıdır. B–F süre bütçesine göre önceliklendirilir: zorunlu olanlar C, E ve F'dir; B ve D elverişli sürede eklenir, eklenemeyen raporda gerekçesiyle "yapılamadı" diye yazılır.

---

## 10. Eksik veri

PHQ-8 maddeleri 18+ nüfusta eksiksizdir (doğrulandı). Öngörücülerde tam veri kuralı; beklenen kayıp 1 kişi (gelir), artı varsa EGITIM = 99. Kayıp %1'in çok altında kaldığından çoklu atama yapılmaz; düşen kişi sayısı ve özellikleri raporlanır. Beklenmedik biçimde herhangi bir öngörücüde eksik %5'i aşarsa dur ve sor.

---

## 11. Tablolar ve figürler

Ana metin beş öğedir. Okuma sırası Figure 1 → Table 1 → Figure 2 → Table 2 → Figure 3. Ağırlık merkezi Figure 2 ve Table 2'dir.

**Figure 1. Tasarım ve örneklem.**

- **(a) Örneklem akışı:** 29.761 kişi → 21.444 yetişkin → hizmet filtreleri (hekim teması, uzman teması dışlaması) → 12.843 uygun → tam veri çerçevesi; içinde 581 pozitif ve 7.726 hane. 470 grubu bu akışta yer almaz. Kutu veya bant boyutları sayılarla orantılı.
- **(b) Kavram şeması:** bilgi katmanları (M0 rutin özellikler → M1 + iki beslenme sorusu → M2 + aktivite ve sosyal destek) → sıralama → ağırlıklı kapasite eşiği → değerlendirmeye davet; altta karşılaştırıcılar (rastgele, PHQ-2, kusursuz sıralama). Panelin görevi okuyucuya karar problemini öğretmektir; denklem konmaz.

**Table 1. Analiz çerçevesinin özellikleri.** Sütunlar: Total, PHQ-8 ≥ 10, PHQ-8 < 10. Satır grupları: yaş, cinsiyet, eğitim, gelir grubu, kronik durum sayısı, meyve sıklığı, sebze sıklığı, aktivite, sosyal destek. Ağırlıksız n, ağırlıklı yüzde; p değeri yok; grup başlıkları birleşik hücre.

**Figure 2. Kapasite ve saptama (ana figür).**

- **(a)** Yatay eksen kapasite c (0,02–0,50), dikey eksen D (1.000 uygun yetişkin başına seçilen PHQ-8 pozitif). Eğriler: rastgele, M0, M1, M2, PHQ-2 sıralaması; kusursuz sıralama tavanı parçalı eğri olarak. PHQ-2 ≥ 3 politika noktası tek işaret. c = 0,10 / 0,20 / 0,30 dikey ince çizgilerle işaretli.
- **(b)** Δ(c) = M1 − M0 eğrisi, bootstrap %95 bandı, sıfır çizgisi ve ±1/1.000 sınır çizgileri.

**Table 2. Önceden belirlenmiş senaryo sonuçları.** Satır blokları c = 0,10 / 0,20 / 0,30; her blokta rastgele, PHQ-2, M0, M1, M2. Sütunlar: D (%95 GA), kapasitede duyarlılık, PPV, M0'a göre fark (%95 GA). M1 − M0 satırı c = 0,20'de birincil sonuç olarak dipnotla işaretlenir; M2 − M1 ayrıca verilir. Not: D, duyarlılık ve PPV'nin aynı miktarın ölçekleri olduğu tek cümleyle yazılır.

**Figure 3. Dağılım ve eşitlik.**

- **(a)** c = 0,20'de yaş, cinsiyet, eğitim ve gelir gruplarına göre pozitiflerin yakalanma oranı, M0 ve M1 yan yana. Eğitimin eklenme gerekçesi: beslenme maddeleri sosyoekonomik eğim taşır; risk temelli seçimin dezavantajlı grupları dışarıda bırakıp bırakmadığı görünür olmalı.
- **(b)** Kısıtsız seçim ile gelir gruplarında eşit seçim oranı: toplam D ve gelir gruplarına göre duyarlılık; eşitlik kuralının saptama maliyeti görünür olsun.

**Supplementary taslak listesi** (numaralar ana metindeki ilk atıf sırasına göre en sonda kesinleşir):

1. Değişken tanımları ve kodlama (degisken_tanimlari).
2. Eksik veri ve düşen kayıtlar.
3. Model denklemleri, önceller, prior predictive, yakınsama tanıları.
4. Tam veri katsayıları (üç model).
5. Ayrım ve kalibrasyon (AUC, kalibrasyon figürü).
6. Duyarlılık analizleri A–G (tablo ve gerekirse bir orman figürü).
7. Bootstrap tekrar oranları ve ikincil model temelli Δ dağılımı.
8. 470 grubu betimlemesi.
9. Eşitlik senaryosu ayrıntıları.
10. Yazılım ve paketler.

Her Supplementary öğesinin ana metinde nereden atıflanacağını `Rapor.md`'de not et.

**sayilar.json.** Makalede geçecek her sayı (örneklem akışı, p, D'ler, Δ'lar, aralıklar, AUC'ler, alt grup değerleri, çapalar) makine okunur biçimde.

**tripod_ai_notlari.md.** TRIPOD+AI maddelerine göre kısa notlar: her madde için karşılığın hangi dosya, karar veya raporda olduğu.

---

## 12. Tuzaklar (kontrol listesine al)

- CSV noktalı virgül ayraçlıdır; FERTFAKTOR ondalık virgüllüdür. Otomatik tür çevirisi bu sütunu bozar veya karakter bırakır; açıkça çevir ve dağılımını doğrula.
- PHQ maddelerinin ham kodları 6 / 16 / 17 / 18'dir; 6 = Hiç = 0 puandır. Kod değerini puan sanma.
- MEYVE_YEMESIKLIK ve SEBZE_SALATA_YEMESIKLIK kodları sıklık sırasında değildir: 7 en sık (günlük), 6 en seyrek (hiç). Sayısal koda göre sıralama yanlış sonuç verir.
- EGITIM'de kod 6 "Okuma-yazma bilmeyen"dir, yüksek düzey değildir; 99 "Bilinmeyen"dir ve eksik sayılır.
- HANE_GELIR_GRUP 20 TL bandıdır, beşte birlik dilim değildir; beş grup Bölüm 4'teki kuralla kurulur.
- AILE_PRTS_HEK_HIZALMDRM kodları: 3 = 12 aydan az, 5 = 12 ay ve daha fazla, 15 = hiçbir zaman. Uygun grup yalnız kod 3'tür.
- 22 KRONIKHAST_ değişkeni vardır; sayımdan DEPRESYON ve MADDEKUL çıkar (20 kalır). KRONIKHAST_DEPRESYON yalnız duyarlılık F'de kullanılır.
- Veri klasöründeki `TSA2022_turetilmis_veriseti` içindeki KRONIK_SAYI depresyonu içerir, FIZIKSEL_AKTIVITE_GUN gün sayılarını toplar, SAGLIKLI_BESLENME iki sıklığı ortalar; üçü de bu çalışmanın tanımlarıyla çelişir. Analiz değişkenlerini kendin türet; türetilmiş seti yalnız çapraz kontrol için kullan.
- Hane kimliği küçük harfli `hane` sütunudur; kişi kimliği hane + FERTNO.
- brms öngörücüsü eksik satırı sessizce düşürür; her modelde satır sayısını denetle.
- Ağırlıklı kantil ve kesirli dahil etme tek fonksiyonda tanımlanır ve her yerde (stratejiler, eşitlik senaryosu, bootstrap, eğri) aynı fonksiyon kullanılır.
- PHQ modülü ankette 15+ nüfusa sorulur; bu çalışma 18+ ile sınırlıdır.
- Tabaka ve PSU değişkeni yoktur; bootstrap tasarım belirsizliğini eksik tahmin edebilir, sınırlılık olarak raporlanır.
- Kapasiteler senaryodur; "ölçülmüş kapasite" gibi yazılmaz. Çapalar: p = %4,57, PHQ-2 ≥ 3 iş yükü = %5,58.
- Methods notlarına şu önermeyi yaz (net fayda bağlantısı): sabit kapasitede seçilen kişi sayısı sabittir (TP + FP = cN), dolayısıyla net fayda NB = TP − w·FP = (1 + w)·TP − w·c·N her w değişim oranında TP ile monoton artar; aynı kapasitede daha çok pozitif yakalayan strateji, eşit değerlendirme maliyeti varsayımıyla her değişim oranında daha iyi net fayda sırası verir. Klinik yarar veya maliyet etkinliği iddiası kurulmaz.

---

## 13. İç denetim

Analizler bittikten sonra en az iki bağımsız iç denetim turu yap ve `Rapor.md` Bölüm 13'e işle:

1. Kod, sayılar ve yöntem: bir hakem gözüyle. Özellikle ağırlıklı kantil fonksiyonu, kesir kuralı, D özdeşliği (1000 p Sens = 1000 c PPV tutmalı), bootstrap eşlenikliği ve CV sızıntısızlığı (aynı hane eğitim ve değerlendirmede olamaz) denetlenir.
2. Sunum ve yorum: tablo ve figür metinleri, terimler, Amerikan İngilizcesi, posterior ve bootstrap etiketlerinin karışmaması.

[İç denetim turlarının yürütülüşüne ilişkin çalışma ortamı notu çıkarıldı.] Bulguları ve verdiğin kararları kaydet.

---

## 14. Teslim listesi

- **`Codes/`:** çalışır scriptler ve `README_kodlar.md` (çalıştırma sırası, süreler, ortam, tohumlar, önbellekler).
- **`R_Data ve Python Data/`:** parquet dosyaları, CV tahminleri, önbellekler, `figur_verileri/`.
- **`Results/`:** Table 1–2 (docx ve csv), `tablolar_tumu.xlsx`, `Supplementary/` tabloları, `sayilar.json`, `model_ozetleri.txt`, `model_protokolu.csv`, `dogrulama_kontrolleri.csv`, `degisken_tanimlari.csv`, `tripod_ai_notlari.md`, `paket_atiflari.txt`, `sessionInfo.txt`, `python_ortam.txt`, `denetim/` ve `log/`.
- **`Figures/`:** Figure 1–3 (PNG 600 dpi, PDF, TIFF), `Supplementary/`, `figur_altyazilari.md`.
- **`Rapor.md`** tamamlanmış olarak.
- **`docs/`:** bu belgenin arşiv kopyası ve `CHANGELOG.md`.
- **Temiz çalıştırma:** türetilmiş dosyalar bir arşiv klasörüne taşınır ve her şey ham CSV'den baştan çalıştırılır. Ardından `sayilar.json` önceki koşuyla karşılaştırılır ve sonuç `Rapor.md`'ye yazılır.

---

## Ek A. Yazım tercihlerimizden bu işi ilgilendirenler

Makaleyi biz yazacağız, ama senin çıktıların doğrudan metne girecek. Şu kurallar senin için de geçerlidir.

- **Veriye sadakat.** Sayıları, yönleri, aralıkları, n'leri ve analiz birimini aynen raporla. Koşullu ilişkiyi nedensel etki gibi yazma. Kesitsel veriden zaman sırası çıkarma. Aralığı ±1 bandının içinde kalan Δ'yı "katkı yok" diye kesinleştirme; tahminin ve belirsizliğin neyi desteklediğini yaz. Duyarlılıklar ana yorumu zayıflatıyorsa bunu ana bulgularda yaz.
- **Ölçümün niteliği.** PHQ-8 ≥ 10 bir tarama pozitifliğidir, klinik tanı değildir. PHQ-2 karşılaştırması aynı anketin maddeleri arasındadır, bağımsız doğrulama değildir. Beslenme sıklığı iki soruluk bir öz bildirimdir, diyet kalitesi ölçümü değildir.
- **Posterior ve bootstrap ayrımı.** Model katsayıları posterior aralıklarla, kapasite büyüklükleri bootstrap güven aralıklarıyla sunulur; iki etiket hiçbir çıktıda karışmaz.
- **Methods notları.** İngilizce, kısa ve kesintisiz paragraflar halinde; denklemler LaTeX olarak. Paket atıfları `citation()` çıktısına dayanır.
- **Tablo ve figür metinleri.** Amerikan İngilizcesi; uzun altyazı ve not yazılmaz; Supplementary öğelerinin atıf yerleri raporda notlanır.
- **Rapor dili.** Bulgu, yorum ve olası mekanizma ayrılır. "Bu çok önemli" yerine neyi değiştirdiği yazılır.
