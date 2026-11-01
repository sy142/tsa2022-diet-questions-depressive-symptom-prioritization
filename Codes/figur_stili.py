import io
import json
import re
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib import patheffects as pe
from PIL import Image

KOK = Path(__file__).resolve().parents[1]
VERI = KOK / "R_Data ve Python Data" / "figur_verileri"
if not VERI.is_dir():
    VERI = KOK / "Figures" / "figur_verileri"
SONUC = KOK / "Results"
FIG = KOK / "Figures"
FIG_EK = FIG / "Supplementary"
ETIKET = json.loads((KOK / "Codes" / "etiketler.json").read_text(encoding="utf-8"))

CM = 1 / 2.54
TAM = 17.4 * CM
EK_TAM = 16.0 * CM
TEK = 8.5 * CM

FONT_KLASORU = KOK / "Codes" / "fonts"
YAZI_TIPI = "Lato"
EN_KUCUK_PUNTO = 7.0

MUREKKEP = "#1A1A20"
IKINCIL = "#4F4F56"
SOLUK = "#8B8B92"
IZGARA = "#EBEBEE"
DIKEY = "#D0D0D5"
ZEMIN = "#FFFFFF"
KAGIT = "#F5F5F8"
BANT = "#E8E8EC"

RENK = {
    "M0": "#9698D2",
    "M1": "#5F58B0",
    "M2": "#332968",
    "PHQ2": "#54555B",
    "rastgele": "#85868B",
    "ideal": "#AB5D2B",
    "ideal_kat": "#BC8459",
}
ACIK = {
    "M0": "#EAEBFC",
    "M1": "#DFE0FD",
    "M2": "#D6D5F8",
}
BANT_M1 = "#C5C6F4"
CIZGI = {
    "M0": "-",
    "M1": "-",
    "M2": "-",
    "PHQ2": (0, (5, 1.6, 1.2, 1.6)),
    "rastgele": (0, (3.2, 2.2)),
    "ideal": (0, (1, 1.6)),
    "ideal_kat": (0, (1, 3.4)),
}
HALE = [pe.withStroke(linewidth=2.6, foreground="white")]


def yazi_tipi():
    dosyalar = sorted(FONT_KLASORU.glob("Lato-*.ttf"))
    if not dosyalar:
        raise FileNotFoundError(f"Yazı tipi dosyaları bulunamadı: {FONT_KLASORU}")
    font_manager.fontManager.ttflist = [f for f in font_manager.fontManager.ttflist if f.name != YAZI_TIPI]
    for yol in dosyalar:
        font_manager.fontManager.addfont(str(yol))
    if hasattr(font_manager.fontManager, "_findfont_cached"):
        font_manager.fontManager._findfont_cached.cache_clear()
    for agirlik, stil, dosya in (("normal", "normal", "Lato-Regular.ttf"), ("bold", "normal", "Lato-Bold.ttf"), ("normal", "italic", "Lato-Italic.ttf")):
        bulunan = Path(font_manager.findfont(font_manager.FontProperties(family=YAZI_TIPI, weight=agirlik, style=stil), fallback_to_default=False))
        if bulunan != FONT_KLASORU / dosya:
            raise RuntimeError(f"{YAZI_TIPI} {agirlik}/{stil} için {FONT_KLASORU / dosya} beklenirken {bulunan} yüklendi")
    return YAZI_TIPI


def stil_kur():
    ad = yazi_tipi()
    mpl.rcParams.update({
        "font.family": ad,
        "mathtext.fontset": "custom",
        "mathtext.rm": ad,
        "mathtext.sf": ad,
        "mathtext.it": f"{ad}:italic",
        "mathtext.bf": f"{ad}:bold",
        "mathtext.cal": ad,
        "mathtext.fallback": None,
        "axes.unicode_minus": True,
        "font.size": 8,
        "axes.titlesize": 8.5,
        "axes.labelsize": 8,
        "xtick.labelsize": 7.5,
        "ytick.labelsize": 7.5,
        "legend.fontsize": 7.5,
        "axes.edgecolor": SOLUK,
        "axes.labelcolor": MUREKKEP,
        "axes.linewidth": 0.5,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": True,
        "axes.axisbelow": True,
        "grid.color": IZGARA,
        "grid.linewidth": 0.45,
        "xtick.color": IKINCIL,
        "ytick.color": IKINCIL,
        "xtick.major.width": 0.5,
        "ytick.major.width": 0.5,
        "xtick.major.size": 2.5,
        "ytick.major.size": 2.5,
        "text.color": MUREKKEP,
        "legend.frameon": False,
        "legend.handlelength": 2.2,
        "figure.facecolor": ZEMIN,
        "axes.facecolor": ZEMIN,
        "savefig.facecolor": ZEMIN,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "lines.solid_capstyle": "round",
        "lines.dash_capstyle": "round",
    })


def panel_etiketi(ax, harf, x=-0.02, y=1.02):
    ax.text(x, y, f"({harf})", transform=ax.transAxes, fontsize=11, fontweight="bold", ha="right", va="bottom", color=MUREKKEP)


def panel_etiketi_fig(fig, harf, x, y):
    fig.text(x, y, f"({harf})", fontsize=11, fontweight="bold", ha="left", va="top", color=MUREKKEP)


def cakisma_denetle(fig, ad, pay=1.0):
    fig.set_dpi(300)
    fig.canvas.draw()
    rnd = fig.canvas.get_renderer()
    tick_yazi, gorunur = set(), set()
    for ax in fig.axes:
        for eksen, sinir in ((ax.xaxis, sorted(ax.get_xlim())), (ax.yaxis, sorted(ax.get_ylim()))):
            for tk in eksen.get_major_ticks() + eksen.get_minor_ticks():
                for lb in (tk.label1, tk.label2):
                    tick_yazi.add(id(lb))
                    if tk.get_visible() and lb.get_visible() and sinir[0] - 1e-9 <= tk.get_loc() <= sinir[1] + 1e-9:
                        gorunur.add(id(lb))
    yazilar = [t for t in fig.findobj(mpl.text.Text) if t.get_visible() and t.get_text().strip() and t.get_alpha() != 0 and (id(t) not in tick_yazi or id(t) in gorunur)]
    kutular = []
    for t in yazilar:
        try:
            kutular.append((t, t.get_window_extent(rnd)))
        except Exception:
            continue
    bulunan = []
    for i in range(len(kutular)):
        for j in range(i + 1, len(kutular)):
            a, b = kutular[i][1], kutular[j][1]
            if a.width <= 0 or b.width <= 0:
                continue
            gx = min(a.x1, b.x1) - max(a.x0, b.x0)
            gy = min(a.y1, b.y1) - max(a.y0, b.y0)
            if gx > pay and gy > pay:
                bulunan.append((kutular[i][0].get_text()[:40], kutular[j][0].get_text()[:40]))
    gw, gh = fig.bbox.width, fig.bbox.height
    tasan = [tt.get_text()[:40] for tt, kt in kutular if kt.x0 < 0 or kt.y0 < 0 or kt.x1 > gw or kt.y1 > gh]
    if tasan:
        raise ValueError(f"{ad}: figür sınırından taşan yazı: {tasan}")
    for x, y in bulunan:
        print(f"UYARI {ad}: yazı çakışması: {x!r} ~ {y!r}")
    return bulunan


DENETIM = []


def punto_denetle(fig, ad):
    puntolar = [t.get_fontsize() for t in fig.findobj(mpl.text.Text) if t.get_visible() and t.get_text().strip()]
    kucuk = sorted({round(p, 2) for p in puntolar if p < EN_KUCUK_PUNTO - 1e-9})
    if kucuk:
        raise ValueError(f"{ad}: {EN_KUCUK_PUNTO} pt altında yazı var: {kucuk}")
    return min(puntolar)


def pdf_fontlari(yol):
    ham = Path(yol).read_bytes()
    return sorted({re.sub(rb"^[A-Z]{6}\+", b"", m).decode("latin-1") for m in re.findall(rb"/BaseFont\s*/([^\s/<>\[\]()]+)", ham)})


def kaydet(fig, ad, ek=False):
    cakisma_denetle(fig, ad)
    en_kucuk = punto_denetle(fig, ad)
    klasor = FIG_EK if ek else FIG
    klasor.mkdir(parents=True, exist_ok=True)
    meta_png = {"Software": None}
    fig.savefig(klasor / f"{ad}.png", dpi=600, metadata=meta_png)
    fig.savefig(klasor / f"{ad}.pdf", dpi=600, metadata={"Creator": None, "Producer": None, "CreationDate": None})
    fontlar = pdf_fontlari(klasor / f"{ad}.pdf")
    yabanci = [f for f in fontlar if not f.startswith(YAZI_TIPI)]
    if yabanci:
        raise RuntimeError(f"{ad}.pdf içinde {YAZI_TIPI} dışı gömülü font: {yabanci}")
    DENETIM.append({"figur": ad, "pdf_gomulu_fontlar": "; ".join(fontlar), "en_kucuk_punto": round(en_kucuk, 2),
                    "genislik_cm": round(fig.get_figwidth() * 2.54, 2), "yukseklik_cm": round(fig.get_figheight() * 2.54, 2)})
    tampon = io.BytesIO()
    fig.savefig(tampon, format="png", dpi=600, metadata=meta_png)
    tampon.seek(0)
    Image.open(tampon).convert("RGB").save(klasor / f"{ad}.tiff", compression="tiff_lzw", dpi=(600, 600))
    plt.close(fig)
    return [klasor / f"{ad}.{u}" for u in ("png", "pdf", "tiff")]
