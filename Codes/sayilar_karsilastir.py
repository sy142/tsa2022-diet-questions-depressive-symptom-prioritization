import json
import sys
from collections import defaultdict


def duzlestir(nesne, yol="", cikti=None):
    if cikti is None:
        cikti = {}
    if isinstance(nesne, dict):
        for k, v in nesne.items():
            duzlestir(v, f"{yol}/{k}", cikti)
    elif isinstance(nesne, list):
        for i, v in enumerate(nesne):
            anahtar = None
            if isinstance(v, dict):
                anahtar = "|".join(str(v[a]) for a in ("model", "buyukluk", "rope", "senaryo", "kategori", "kod", "yil", "k", "grup", "kontrol", "tekrar", "olcek", "kose", "dugum", "adim") if a in v)
            duzlestir(v, f"{yol}[{anahtar or i}]", cikti)
    else:
        cikti[yol] = nesne
    return cikti


eski = duzlestir(json.load(open(sys.argv[1], encoding="utf-8")))
yeni = duzlestir(json.load(open(sys.argv[2], encoding="utf-8")))
haric = ("sure", "dakika", "olusturma", "model_sureleri", "adim_sureleri")
ozet = defaultdict(lambda: {"ortak": 0, "ayni": 0, "en_buyuk_fark": 0.0, "ornek": ""})
for k in sorted(set(eski) & set(yeni)):
    if any(h in k for h in haric):
        continue
    grup = k.split("/")[1].split("[")[0]
    o = ozet[grup]
    o["ortak"] += 1
    a, b = eski[k], yeni[k]
    if a == b:
        o["ayni"] += 1
    elif isinstance(a, (int, float)) and isinstance(b, (int, float)):
        if abs(a - b) > o["en_buyuk_fark"]:
            o["en_buyuk_fark"] = abs(a - b)
            o["ornek"] = f"{k}: {a} → {b}"
    elif not o["ornek"]:
        o["ornek"] = f"{k}: {a} → {b}"
print(f"Ortak alan: {sum(o['ortak'] for o in ozet.values())}; yalnız eskide: {len(set(eski) - set(yeni))}; yalnız yenide: {len(set(yeni) - set(eski))}")
for g, o in sorted(ozet.items()):
    print(f"{g:24s} ortak {o['ortak']:6d}  aynı {o['ayni']:6d}  en büyük sayısal fark {o['en_buyuk_fark']:.6g}  {o['ornek'][:140]}")
