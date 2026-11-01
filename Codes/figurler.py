import sys

sys.dont_write_bytecode = True

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Rectangle

from figur_stili import (ACIK, BANT, BANT_M1, CIZGI, CM, DENETIM, DIKEY, EK_TAM, ETIKET, IKINCIL, KAGIT, MUREKKEP, RENK, SOLUK, SONUC, TAM, TEK, VERI, YAZI_TIPI, kaydet,
                         panel_etiketi, panel_etiketi_fig, stil_kur)

stil_kur()
ST = ETIKET["strateji"]
STK = ETIKET["strateji_kisa"]
KAT = ETIKET["kategori"]
DEG = ETIKET["degisken"]


def sabit(kalem):
    s = pd.read_csv(VERI / "sabitler.csv")
    return float(s.loc[s.kalem == kalem, "deger"].iloc[0])


def bicim(n):
    return f"{int(n):,}"


def kutu(ax, x, y, g, y_, yuz, kenar, lw=0.8, r=0.02):
    ax.add_patch(FancyBboxPatch((x, y), g, y_, boxstyle=f"round,pad=0,rounding_size={r}", linewidth=lw, facecolor=yuz, edgecolor=kenar))


def ok(ax, x0, y0, x1, y1, renk=IKINCIL, lw=0.8):
    ax.add_patch(FancyArrowPatch((x0, y0), (x1, y1), arrowstyle="-|>", mutation_scale=7, linewidth=lw, color=renk, shrinkA=0, shrinkB=0))


def tuval(fig, konum):
    ax = fig.add_axes(konum)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_axis_off()
    return ax


def figur1():
    akis = pd.read_csv(VERI / "fig1_akis.csv")
    n = dict(zip(akis.kod, akis.n))
    dis = dict(zip(akis.kod, akis.dislanan))
    fig = plt.figure(figsize=(TAM, 10.0 * CM))
    ax = tuval(fig, [0.0, 0.0, 0.46, 0.92])
    adimlar = [("ham", "Survey respondents, all ages"), ("yetiskin", "Adults aged ≥ 18 years"), ("hekim", "GP or family physician visit, past 12 months"),
               ("uygun", "Eligible population"), ("analiz", f"Analysis frame ({bicim(n['hane'])} households)")]
    dislanan = {"yetiskin": f"Excluded: aged < 18 years (n = {bicim(dis['yetiskin'])})", "hekim": f"Excluded: no GP or family physician visit\nin the past 12 months (n = {bicim(dis['hekim'])})",
                "uygun": f"Excluded: psychologist, psychotherapist or\npsychiatrist visit, past 12 months (n = {bicim(dis['uygun'])})",
                "analiz": f"Excluded: missing household income (n = {bicim(dis['analiz'])})"}
    x0, gmax, h, adim_y = 0.05, 0.44, 0.075, 0.185
    omurga = x0 + 0.018
    for i, (k, et) in enumerate(adimlar):
        y = 0.965 - i * adim_y - h
        g = gmax * n[k] / n["ham"]
        son = k == "analiz"
        ax.add_patch(Rectangle((x0, y), g, h, facecolor=ACIK["M1"] if son else ACIK["M0"], edgecolor=RENK["M0"], linewidth=0.6))
        if son:
            gp = g * n["pozitif"] / n["analiz"]
            ax.add_patch(Rectangle((x0 + g - gp, y), gp, h, facecolor=MUREKKEP, edgecolor=MUREKKEP, linewidth=0.6))
        ax.text(x0 + g + 0.02, y + h * 0.70, bicim(n[k]), ha="left", va="center", fontsize=7.8, fontweight="bold", color=MUREKKEP)
        ax.text(x0 + g + 0.02, y + h * 0.18, et, ha="left", va="center", fontsize=7.0, color=IKINCIL)
        if i > 0:
            ust_y = y + adim_y
            ok(ax, omurga, ust_y - 0.001, omurga, y + h + 0.003, lw=0.7)
            orta = (ust_y + y + h) / 2
            ax.plot([omurga, omurga + 0.045], [orta, orta], color=SOLUK, linewidth=0.6)
            ax.text(omurga + 0.055, orta, dislanan[k], ha="left", va="center", fontsize=7.0, color=IKINCIL, linespacing=1.15)
    y_son = 0.965 - 4 * adim_y - h
    ax.add_patch(Rectangle((x0, y_son - 0.085), 0.03, 0.035, facecolor=MUREKKEP, edgecolor=MUREKKEP, linewidth=0.6))
    ax.text(x0 + 0.045, y_son - 0.0675, f"PHQ-8 ≥ 10 (n = {bicim(n['pozitif'])})", ha="left", va="center", fontsize=7.0, color=MUREKKEP)
    ax.text(x0, y_son - 0.125, "Bar widths are proportional to unweighted counts.", ha="left", va="center", fontsize=7.0, color=IKINCIL, style="italic")
    panel_etiketi_fig(fig, "a", 0.004, 0.995)

    bx = tuval(fig, [0.485, 0.0, 0.515, 0.92])
    bx.text(0.25, 0.985, "Information available before assessment\n(no depressive-symptom questions)", ha="center", va="top", fontsize=7.0, fontweight="bold", color=MUREKKEP, linespacing=1.2)
    katman = [("M0", "Routine characteristics", "age, sex, education, household\nincome, chronic conditions"),
              ("M1", "+ Two diet questions", "fruit and vegetable/salad\nconsumption frequency"),
              ("M2", "+ Activity and social support", "walking, cycling and sport days,\nphysical demand of daily\nactivities, social support (3 items)")]
    yk = [(0.725, 0.15), (0.525, 0.15), (0.26, 0.215)]
    for (m, bas, alt), (yy, hh) in zip(katman, yk):
        kutu(bx, 0.0, yy, 0.53, hh, ACIK[m], RENK[m], lw=1.0)
        bx.text(0.025, yy + hh - 0.028, m, ha="left", va="top", fontsize=8.2, fontweight="bold", color=MUREKKEP)
        bx.text(0.115, yy + hh - 0.028, bas, ha="left", va="top", fontsize=7.0, fontweight="bold", color=MUREKKEP)
        bx.text(0.115, yy + hh - 0.073, alt, ha="left", va="top", fontsize=7.0, color=IKINCIL, linespacing=1.2)
    for (y1, _), (y2, h2) in ((yk[0], yk[1]), (yk[1], yk[2])):
        ok(bx, 0.265, y1 - 0.002, 0.265, y2 + h2 + 0.003, lw=0.7)
    bx.plot([0.545, 0.565, 0.565, 0.545], [yk[0][0] + yk[0][1], yk[0][0] + yk[0][1], yk[2][0], yk[2][0]], color=IKINCIL, linewidth=0.7)
    adimlar_b = [("Rank adults by predicted\nprobability of PHQ-8 ≥ 10", 0.725, 0.15), ("Invite the top share c\n(c = assessment capacity)", 0.525, 0.15),
                 ("Detailed assessment", 0.26, 0.215)]
    for metin, yy, hh in adimlar_b:
        kutu(bx, 0.625, yy, 0.37, hh, KAGIT, IKINCIL)
    for metin, yy, hh in adimlar_b[:2]:
        bx.text(0.81, yy + hh / 2, metin, ha="center", va="center", fontsize=7.0, color=MUREKKEP, linespacing=1.25)
    bx.text(0.81, adimlar_b[2][1] + adimlar_b[2][2] - 0.033, "Detailed assessment", ha="center", va="top", fontsize=7.0, color=MUREKKEP)
    bx.text(0.81, adimlar_b[2][1] + 0.02, "Detection yield: selected\nPHQ-8–positive adults\nper 1,000 eligible adults", ha="center", va="bottom", fontsize=7.0, color=IKINCIL, linespacing=1.2)
    ok(bx, 0.565, 0.80, 0.625, 0.80)
    ok(bx, 0.81, 0.725 - 0.002, 0.81, 0.525 + 0.15 + 0.003)
    ok(bx, 0.81, 0.525 - 0.002, 0.81, 0.26 + 0.215 + 0.003)
    bx.add_patch(Rectangle((0.0, 0.0), 1.0, 0.215, facecolor=KAGIT, edgecolor="none"))
    bx.text(0.025, 0.195, "Comparators at the same capacity", ha="left", va="top", fontsize=7.0, fontweight="bold", color=MUREKKEP)
    karsi = [("rastgele", "Random selection", 0.025, 0.125), ("ideal", "Perfect ranking (upper bound)", 0.50, 0.125),
             ("PHQ2", "PHQ-2 ranking: symptom-based comparator sharing two\nitems with the PHQ-8; not an upper bound", 0.025, 0.05)]
    for k, et, xx, yy in karsi:
        bx.plot([xx, xx + 0.06], [yy, yy], color=RENK[k], linestyle=CIZGI[k], linewidth=1.3)
        bx.text(xx + 0.075, yy, et, ha="left", va="center", fontsize=7.0, color=MUREKKEP, linespacing=1.2)
    panel_etiketi_fig(fig, "b", 0.478, 0.995)
    return kaydet(fig, "Figure1")


def figur2():
    eg = pd.read_csv(VERI / "kapasite_egrisi.csv")
    fk = pd.read_csv(VERI / "fark_egrisi.csv")
    p2 = pd.read_csv(VERI / "phq2_3_noktasi.csv").set_index("olcu")
    p = sabit("p")
    fig, (ax, bx) = plt.subplots(1, 2, figsize=(TAM, 9.0 * CM), gridspec_kw={"width_ratios": [1.12, 1], "wspace": 0.34})
    fig.subplots_adjust(left=0.085, right=0.985, bottom=0.14, top=0.80)
    for a_ in (ax, bx):
        a_.grid(axis="x", visible=False)
        for k in (10, 20, 30):
            a_.axvline(k, color=DIKEY, linewidth=0.5, linestyle="-", zorder=0.5)
    if sabit("tavan_kat_ciz") == 1:
        tk = pd.read_csv(VERI / "tavan_kat_duzeyi.csv").sort_values("c")
        tk = tk.iloc[: int(np.argmax(tk.D.to_numpy() >= 1000 * p - 1e-9)) + 1]
        ax.plot(100 * tk.c.to_numpy(), tk.D, color=RENK["ideal_kat"], linestyle=CIZGI["ideal_kat"], linewidth=1.3, label=ST["ideal_kat"], zorder=2)
    sira = ["ideal", "PHQ2", "M2", "M1", "M0", "rastgele"]
    for st in sira:
        x = eg[eg.strateji == st].sort_values("c")
        c = 100 * x.c.to_numpy()
        lw = 1.6 if st in ("M0", "M1", "M2") else 1.15
        ax.plot(c, x.D, color=RENK[st], linestyle=CIZGI[st], linewidth=lw, label=ST[st], zorder=3 if st == "M1" else 2)
    ax.plot(100 * p2.loc["c", "tahmin"], p2.loc["D", "tahmin"], marker="D", markersize=4.6, color=RENK["PHQ2"], markerfacecolor="white", markeredgewidth=1.1, zorder=5, linestyle="none")
    ax.plot([], [], marker="D", markersize=4.6, color=RENK["PHQ2"], markerfacecolor="white", markeredgewidth=1.1, linestyle="none", label=ST["PHQ2_3"])
    ax.text(100 * p2.loc["c", "tahmin"] + 1.6, p2.loc["D", "tahmin"] - 2.2, f"PHQ-2 ≥ 3 (c = {100 * p2.loc['c', 'tahmin']:.1f}%)", fontsize=7.0, color=MUREKKEP, ha="left", va="center",
            bbox=dict(boxstyle="square,pad=0.15", facecolor="white", edgecolor="none"), zorder=6)
    for k in (10, 20, 30):
        ax.text(k + 0.4, 1.0, f"{k}%", fontsize=7.0, color=IKINCIL, ha="left", va="bottom")
    ax.set_xlim(0, 51)
    ax.set_ylim(0, 50)
    ax.set_xticks([2, 10, 20, 30, 40, 50])
    ax.set_xlabel("Assessment capacity, % of eligible adults invited")
    ax.set_ylabel("PHQ-8–positive adults selected\nper 1,000 eligible adults")
    h, l = ax.get_legend_handles_labels()
    sira_l = [ST[k] for k in ("M0", "M1", "M2", "PHQ2", "PHQ2_3", "rastgele", "ideal", "ideal_kat")]
    hl = sorted(zip(h, l), key=lambda t: sira_l.index(t[1]))
    ax.legend([t[0] for t in hl], [t[1] for t in hl], loc="lower left", bbox_to_anchor=(-0.02, 1.01), ncol=2, fontsize=7.0, handlelength=2.4, labelspacing=0.3, columnspacing=0.9,
              handletextpad=0.5, borderaxespad=0.0)
    ax.text(50.5, 1000 * p + 0.8, f"Plateau: 1,000 × p = {1000 * p:.1f}", ha="right", va="bottom", fontsize=7.0, color=IKINCIL)
    panel_etiketi_fig(fig, "a", 0.004, 0.995)
    x = fk[fk.karsilastirma == "M1 − M0"].sort_values("c")
    c = 100 * x.c.to_numpy()
    bx.axhspan(-1, 1, color=BANT, zorder=0.2, linewidth=0, label="±1 per 1,000 (practical-importance bound)")
    bx.axhline(0, color=IKINCIL, linewidth=0.7, zorder=1)
    for s in (-1, 1):
        bx.axhline(s, color=SOLUK, linewidth=0.6, linestyle=(0, (3, 2)), zorder=1)
    bx.fill_between(c, x.alt, x.ust, color=BANT_M1, alpha=0.8, linewidth=0, zorder=2, label="Pointwise 95% bootstrap CI")
    bx.plot(c, x.fark, color=RENK["M1"], linewidth=1.6, zorder=3, label="Δ(c) = D$_{\\mathrm{M1}}$(c) − D$_{\\mathrm{M0}}$(c)")
    r = x[np.isclose(x.c, 0.20)].iloc[0]
    bx.errorbar([20], [r.fark], yerr=[[r.fark - r.alt], [r.ust - r.fark]], fmt="o", color=RENK["M1"], markersize=4, markerfacecolor="white", markeredgewidth=1.1, elinewidth=1.0, capsize=2, zorder=4)
    alt_s = min(-2.5, np.floor(x.alt.min() - 0.8)) - 0.5
    ust_s = max(3.0, np.ceil(x.ust.max() + 1.6))
    bx.set_ylim(alt_s, ust_s)
    bx.annotate(f"Δ(0.20) = {r.fark:.2f} ({r.alt:.2f} to {r.ust:.2f})".replace("-", "−"), xy=(20, r.ust), xytext=(22.0, ust_s - 0.55), fontsize=7.0, color=MUREKKEP, va="center",
                arrowprops=dict(arrowstyle="-", color=IKINCIL, linewidth=0.6, shrinkA=0, shrinkB=2))
    bx.set_xlim(0, 51)
    bx.set_xticks([2, 10, 20, 30, 40, 50])
    bx.set_xlabel("Assessment capacity, % of eligible adults invited")
    bx.set_ylabel("Difference in detection yield, M1 − M0\n(per 1,000 eligible adults)")
    bx.legend(loc="lower left", ncol=1, fontsize=7.0, handlelength=2.0, borderaxespad=0.4, labelspacing=0.3, frameon=True, facecolor="white", edgecolor="none", framealpha=0.9)
    panel_etiketi_fig(fig, "b", 0.56, 0.995)
    return kaydet(fig, "Figure2")


def figur3():
    ag = pd.read_csv(VERI / "fig3a_altgrup.csv", dtype={"duzey": str})
    es = pd.read_csv(VERI / "fig3b_esitlik.csv", dtype={"duzey": str})
    fig = plt.figure(figsize=(TAM, 10.6 * CM))
    ax = fig.add_axes([0.20, 0.115, 0.36, 0.825])
    bx = fig.add_axes([0.685, 0.155, 0.30, 0.50])
    cx = fig.add_axes([0.685, 0.80, 0.30, 0.14])
    gruplar = ["yas_g", "cins", "egitim", "gelir5"]
    duzey_sira = {"yas_g": ["1", "2", "3", "4"], "cins": ["1", "2"], "egitim": ["1", "2", "3", "4"], "gelir5": ["1", "2", "3", "4", "5"]}
    y = 0.0
    yt, yl = [], []
    baslik_y = []
    for g in gruplar:
        baslik_y.append((y, DEG[g] if g != "gelir5" else "Household income group"))
        y -= 1.0
        for d in duzey_sira[g]:
            for st, dy in (("M0", 0.17), ("M1", -0.17)):
                r = ag[(ag.degisken == g) & (ag.duzey == d) & (ag.strateji == st) & (ag.olcu == "yakalama")]
                if len(r) and not np.isnan(r.tahmin.iloc[0]):
                    r = r.iloc[0]
                    ax.plot([100 * r.alt, 100 * r.ust], [y + dy, y + dy], color=RENK[st], linewidth=1.0, solid_capstyle="butt")
                    ax.plot(100 * r.tahmin, y + dy, "o", color=RENK[st], markersize=3.8, markeredgecolor="white", markeredgewidth=0.5, zorder=3)
            yt.append(y)
            yl.append(KAT[g][d])
            y -= 1.0
        y -= 0.35
    ax.set_yticks(yt)
    ax.set_yticklabels(yl, fontsize=7.0)
    for yy, et in baslik_y:
        ax.text(-0.02, yy - 0.15, et, transform=ax.get_yaxis_transform(), ha="right", va="center", fontsize=7.2, fontweight="bold", color=MUREKKEP)
    ax.set_ylim(y + 0.6, 0.6)
    ax.set_xlim(0, 100)
    ax.grid(axis="y", visible=False)
    ax.set_xlabel("PHQ-8–positive adults selected at 20% capacity, %")
    ax.plot([], [], "o-", color=RENK["M0"], markersize=3.8, linewidth=1.0, label=STK["M0"])
    ax.plot([], [], "o-", color=RENK["M1"], markersize=3.8, linewidth=1.0, label=STK["M1"])
    ax.legend(loc="lower right", fontsize=7.0, handlelength=1.6, borderaxespad=0.2)
    panel_etiketi_fig(fig, "a", 0.005, 0.995)
    m1 = es[es.strateji == "M1"]
    for k, d in enumerate(["1", "2", "3", "4", "5"]):
        for kural, dx, dolu in (("unconstrained", -0.13, True), ("equal", 0.13, False)):
            r = m1[(m1.duzey == d) & (m1.olcu == f"Sens_{kural}")].iloc[0]
            bx.plot([k + dx, k + dx], [100 * r.alt, 100 * r.ust], color=RENK["M1"], linewidth=1.0, solid_capstyle="butt")
            bx.plot(k + dx, 100 * r.tahmin, "o", color=RENK["M1"], markersize=4.2, markerfacecolor=RENK["M1"] if dolu else "white", markeredgewidth=1.0, zorder=3)
    bx.set_xticks(range(5))
    bx.set_xticklabels([KAT["gelir5"][d].replace(" (lowest)", "\nlowest").replace(" (highest)", "\nhighest") for d in ["1", "2", "3", "4", "5"]], fontsize=7.0)
    bx.set_xlabel("Household income group")
    bx.set_ylabel("PHQ-8–positive adults selected, %")
    bx.set_ylim(0, 100)
    bx.grid(axis="x", visible=False)
    bx.plot([], [], "o", color=RENK["M1"], markersize=4.2, label="Unconstrained selection")
    bx.plot([], [], "o", color=RENK["M1"], markersize=4.2, markerfacecolor="white", markeredgewidth=1.0, label="Equal selection proportion")
    bx.legend(loc="upper right", fontsize=7.0, handlelength=1.0, borderaxespad=0.2)
    tt = m1[m1.duzey == "Total"].set_index("olcu")
    for j, (k, et, dolu) in enumerate((("D_kisitsiz", "Unconstrained", True), ("D_esit", "Equal selection proportion", False))):
        r = tt.loc[k]
        cx.plot([r.alt, r.ust], [1 - j, 1 - j], color=RENK["M1"], linewidth=1.0, solid_capstyle="butt")
        cx.plot(r.tahmin, 1 - j, "o", color=RENK["M1"], markersize=4.2, markerfacecolor=RENK["M1"] if dolu else "white", markeredgewidth=1.0, zorder=3)
    cx.set_yticks([1, 0])
    cx.set_yticklabels(["Unconstrained", "Equal selection\nproportion"], fontsize=7.0)
    cx.set_ylim(-0.6, 1.6)
    cx.grid(axis="y", visible=False)
    cx.set_xlabel("M1 detection yield per 1,000 at 20% capacity", fontsize=7.0, labelpad=1.5)
    cx.tick_params(axis="x", labelsize=7.0)
    f = tt.loc["fark_D"]
    cx.text(1.0, 1.32, f"Difference, equal − unconstrained: {f.tahmin:.2f} ({f.alt:.2f} to {f.ust:.2f})".replace("-", "−"), transform=cx.get_yaxis_transform(), ha="right", va="bottom", fontsize=7.0, color=IKINCIL,
            bbox=dict(boxstyle="square,pad=0.15", facecolor="white", edgecolor="none"))
    panel_etiketi_fig(fig, "b", 0.585, 0.995)
    return kaydet(fig, "Figure3")


def figur_s_kalibrasyon():
    k = pd.read_csv(VERI / "figS_kalibrasyon.csv")
    fig, ax = plt.subplots(figsize=(9.0 * CM, 8.2 * CM))
    fig.subplots_adjust(left=0.17, right=0.97, bottom=0.15, top=0.96)
    ust = 100 * max(k.beklenen.max(), k.gozlenen.max()) * 1.08
    ax.plot([0, ust], [0, ust], color=SOLUK, linewidth=0.7, linestyle=(0, (3, 2)))
    for m in ("M0", "M1", "M2"):
        x = k[k.model == m].sort_values("dl")
        ax.plot(100 * x.beklenen, 100 * x.gozlenen, "o-", color=RENK[m], markersize=3.4, linewidth=1.0, label=STK[m], markeredgecolor="white", markeredgewidth=0.4)
    ax.set_xlim(0, ust)
    ax.set_ylim(0, ust)
    ax.set_xlabel("Mean predicted probability, % (weighted decile)")
    ax.set_ylabel("Observed PHQ-8 ≥ 10, % (weighted)")
    ax.legend(loc="upper left", fontsize=7.0)
    return kaydet(fig, "FigureS2_kalibrasyon", ek=True)


def figur_s_duyarlilik():
    d = pd.read_csv(VERI / "figS_duyarlilik.csv")
    sira = ["primary", "A_r2", "A_r3", "A_r4", "A_r5", "B", "C", "D", "E", "F"]
    d = d.set_index("kod").reindex([s for s in sira if s in set(d.kod)]).reset_index()
    fig, ax = plt.subplots(figsize=(TEK * 1.45, 7.6 * CM))
    fig.subplots_adjust(left=0.47, right=0.97, bottom=0.15, top=0.97)
    ax.axvspan(-1, 1, color=BANT, linewidth=0, zorder=0)
    ax.axvline(0, color=IKINCIL, linewidth=0.7)
    for i, r in d.iterrows():
        yy = -i
        renk = RENK["M1"] if r.kod == "primary" else MUREKKEP
        ax.plot([r.alt, r.ust], [yy, yy], color=renk, linewidth=1.0, solid_capstyle="butt")
        ax.plot(r.tahmin, yy, "o", color=renk, markersize=3.8, markerfacecolor="white" if r.kod != "primary" else renk, markeredgewidth=1.0, zorder=3)
    ax.set_yticks(-np.arange(len(d)))
    ax.set_yticklabels(d.analiz, fontsize=7.0)
    ax.grid(axis="y", visible=False)
    ax.set_xlabel("Δ(0.20), M1 − M0, per 1,000 eligible adults")
    return kaydet(fig, "FigureS4_duyarlilik", ek=True)


def figur_s_delta():
    d = pd.read_csv(VERI / "figS_delta_dagilimlari.csv")
    fig, axs = plt.subplots(1, 2, figsize=(EK_TAM, 6.2 * CM), sharex=True)
    fig.subplots_adjust(left=0.075, right=0.985, bottom=0.2, top=0.86, wspace=0.18)
    lo, hi = np.floor(d.deger.min()) - 0.5, np.ceil(d.deger.max()) + 0.5
    kutular = np.linspace(lo, hi, 60)
    for ax, (k, et, harf) in zip(axs, (("bootstrap", "Household cluster bootstrap replicates (B = 2,000)", "a"), ("model_temelli", "Model-based draws (1,000 outer-fold posterior draws)", "b"))):
        x = d[d.kaynak == k].deger
        ax.axvspan(-1, 1, color=BANT, linewidth=0, zorder=0)
        ax.hist(x, bins=kutular, color=ACIK["M1"], edgecolor=RENK["M1"], linewidth=0.4, zorder=2)
        ax.axvline(0, color=IKINCIL, linewidth=0.7, zorder=3)
        ax.set_title(et, fontsize=7.6, loc="left")
        ax.set_xlabel("Δ(0.20), M1 − M0, per 1,000 eligible adults")
        ax.grid(axis="x", visible=False)
        panel_etiketi_fig(fig, harf, 0.004 if harf == "a" else 0.515, 0.995)
    axs[0].set_ylabel("Count")
    axs[1].set_ylabel("Count")
    return kaydet(fig, "FigureS3_delta_dagilimlari", ek=True)


def figur_s_oncel():
    d = pd.read_csv(VERI / "figS_oncel_ongoru.csv")
    modeller = list(dict.fromkeys(d.model))
    et = {"M0": "M0", "M1": "M1", "M2": "M2, prior SD 1 per day (originally specified)"}
    for m in modeller:
        if m not in et:
            et[m] = "M2, prior SD 1/SD per day" if "1/SD_x" in m else "M2, prior SD 1/(2 SD) per day (used)"
    renk = {"M0": RENK["M0"], "M1": RENK["M1"]}
    fig, axs = plt.subplots(1, 2, figsize=(EK_TAM, 7.6 * CM))
    fig.subplots_adjust(left=0.085, right=0.97, bottom=0.32, top=0.88, wspace=0.25)
    for m in modeller:
        x = d[d.model == m]
        r = renk.get(m, RENK["M2"])
        ls = "-" if m in ("M0", "M1") or "2 SD" in m else ((0, (3, 2)) if m == "M2" else (0, (1, 1.4)))
        pay = np.sort(100 * x.pay.to_numpy())
        axs[0].step(pay, np.arange(1, len(pay) + 1) / len(pay), where="post", color=r, linestyle=ls, linewidth=1.1)
        h, kenar = np.histogram(np.clip(x.xb_sd, 0, 10), bins=np.linspace(0, 10, 51), density=True)
        axs[1].step(kenar[:-1], h, where="post", color=r, linestyle=ls, linewidth=1.1, label=et[m])
    axs[0].set_xlim(0, 100)
    axs[0].set_ylim(0, 1)
    axs[1].set_xlim(0, 10)
    axs[0].set_xlabel("Prior-implied weighted share with PHQ-8 ≥ 10, %")
    axs[1].set_xlabel("Prior-implied between-person SD of the linear predictor")
    axs[0].set_ylabel("Cumulative proportion")
    axs[1].set_ylabel("Density")
    h_, l_ = axs[1].get_legend_handles_labels()
    fig.legend(h_, l_, loc="lower center", ncol=3, fontsize=7.0, frameon=False, bbox_to_anchor=(0.5, 0.0), handlelength=2.4, columnspacing=1.4)
    panel_etiketi_fig(fig, "a", 0.004, 0.995)
    panel_etiketi_fig(fig, "b", 0.52, 0.995)
    return kaydet(fig, "FigureS1_oncel_ongoru", ek=True)


FIGURLER = {"1": figur1, "2": figur2, "3": figur3, "S1": figur_s_oncel, "S2": figur_s_kalibrasyon, "S3": figur_s_delta, "S4": figur_s_duyarlilik}

if __name__ == "__main__":
    secim = sys.argv[1:] or list(FIGURLER)
    for k in secim:
        for yol in FIGURLER[k]():
            print(yol.relative_to(yol.parents[1]) if "Supplementary" not in str(yol) else yol.relative_to(yol.parents[2]))
    if not sys.argv[1:]:
        pd.DataFrame(DENETIM).assign(yazi_tipi=YAZI_TIPI).to_csv(SONUC / "denetim" / "figur_font_denetimi.csv", index=False)
        print(pd.DataFrame(DENETIM).to_string(index=False))
