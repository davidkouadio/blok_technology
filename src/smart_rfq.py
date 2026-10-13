import re
import math
import unicodedata
from difflib import SequenceMatcher

import pandas as pd

UNITES_SPEC = {"kg": ("masse", 1), "g": ("masse", 0.001), "l": ("volume", 1), "cl": ("volume", 0.01),
               "m": ("longueur", 1), "cm": ("longueur", 0.01), "mm": ("diametre", 1), "m3": ("m3", 1)}
MOTS_UNITE = {"sac", "barre", "seau", "camion", "rame", "bidon", "pack", "colis", "paire", "boite",
              "rouleau", "piece", "carton", "unite"}
APPROX = {"centaine": 100, "dizaine": 10, "douzaine": 12, "cinquantaine": 50, "vingtaine": 20}


def normaliser(texte):
    """Minuscules, sans accents, décimales avec un point, 'x4' -> 'x 4', '50 kg' -> '50kg'."""
    t = unicodedata.normalize("NFKD", str(texte).lower()).encode("ascii", "ignore").decode()
    t = re.sub(r"(\d),(\d)", r"\1.\2", t)
    t = re.sub(r"\bx(\d)", r"x \1", t)
    t = re.sub(r"(\d+(?:\.\d+)?)\s+(kg|g|l|cl|m3|m|cm|mm)\b", r"\1\2", t)
    return t


def singulier(mot):
    return mot[:-1] if len(mot) > 3 and mot[-1] in "sx" else mot


def analyser(texte):
    """Sépare un texte en mots, codes (a4, 85a, 6/10), spécifications chiffrées avec unité et nombres nus."""
    t = normaliser(texte)
    mots, codes, specs, nombres = [], [], [], []
    for brut in re.findall(r"\d+/\d+|[a-z0-9.]+", t):
        brut = brut.strip(".")
        m = re.fullmatch(r"(\d+(?:\.\d+)?)(kg|g|l|cl|m3|m|cm|mm)", brut)
        if m:
            dim, facteur = UNITES_SPEC[m.group(2)]
            specs.append((dim, float(m.group(1)) * facteur))
        elif re.fullmatch(r"\d+(?:\.\d+)?", brut):
            nombres.append(float(brut))
        elif re.fullmatch(r"\d+/\d+|[a-z]\d+|\d+[a-z]", brut):
            codes.append(brut)
        elif re.fullmatch(r"[a-z]+\d+", brut):
            lettres, chiffres = re.fullmatch(r"([a-z]+)(\d+)", brut).groups()
            mots.append(lettres); nombres.append(float(chiffres))
        elif brut.isalpha() and len(brut) > 1:
            mots.append(singulier(brut))
    return mots, codes, specs, nombres


class Catalogue:
    def __init__(self, variants: pd.DataFrame):
        self.produits = []
        for r in variants.itertuples():
            mots, codes, specs, nombres = analyser(r.product_name)
            self.produits.append({"id": r.variant_id, "nom": r.product_name, "mots": set(mots),
                                  "codes": set(codes), "specs": specs, "nombres": nombres})
        n = len(self.produits)
        df = {}
        for p in self.produits:
            for m in p["mots"]:
                df[m] = df.get(m, 0) + 1
        self.idf = {m: math.log(1 + n / d) for m, d in df.items()}

    def mot_proche(self, mot, mots_produit):
        """Correspondance exacte, par préfixe (secu/securite) ou floue (fautes de frappe)."""
        for m in mots_produit:
            if mot == m:
                return m, False
        for m in mots_produit:
            court, long_ = sorted([mot, m], key=len)
            if len(court) >= 4 and long_.startswith(court):
                return m, True
            if len(mot) >= 5 and SequenceMatcher(None, mot, m).ratio() >= 0.85:
                return m, True
        return None, False

    def score_mots(self, mots, produit):
        trouves, flou = set(), False
        for mot in mots:
            m, approx = self.mot_proche(mot, produit["mots"])
            if m:
                trouves.add(m); flou = flou or approx
        return sum(self.idf[m] for m in trouves), trouves, flou


def nombre_correspond(n, nombres_produit):
    return any(n == a or (int(n) == int(a) and abs(n - a) < 1 and n == int(n)) for a in nombres_produit)


def extraire_segment(segment, cat: Catalogue):
    mots, codes, specs, nombres = analyser(segment)
    t = normaliser(segment)

    # famille de produits
    scores = [(cat.score_mots(mots, p), p) for p in cat.produits]
    meilleur = max(s[0][0] for s in scores)
    if meilleur == 0:
        return {"statut": "absent du catalogue", "variant_id": None, "quantite": None,
                "confiance": 0.8, "motif": "aucun produit reconnu"}
    famille = [(s, p) for s, p in scores if s[0] == meilleur]

    # départage par les caractéristiques
    def accord(p):
        ok = sum(c in p["codes"] for c in codes)
        ok += sum(any(d == dp and abs(v - vp) < 1e-9 for dp, vp in p["specs"]) or
                  (d == "diametre" and nombre_correspond(v, p["nombres"])) for d, v in specs)
        ok += sum(nombre_correspond(n, p["nombres"]) for n in nombres)
        conflit = any(any(d == dp and abs(v - vp) > 1e-9 for dp, vp in p["specs"]) and
                      not any(d == dp and abs(v - vp) < 1e-9 for dp, vp in p["specs"]) for d, v in specs)
        return ok, conflit
    evals = [(accord(p), s, p) for s, p in famille]
    max_ok = max(e[0][0] for e in evals)
    retenus = [e for e in evals if e[0][0] == max_ok]

    # quantité
    p0 = retenus[0][2]
    libres = [n for n in nombres if not (len(retenus) == 1 and nombre_correspond(n, p0["nombres"]))]
    libres = [n for n in libres if not re.search(rf"pointure\s+{int(n)}\b", t)]
    quantite, approx_q = None, False
    m = re.search(r"\bx\s+(\d+)", t)
    if m:
        quantite = float(m.group(1))
    else:
        for n in libres:
            if re.search(rf"\b{int(n)}\s+({'|'.join(MOTS_UNITE)})", t):
                quantite = n; break
        if quantite is None and libres:
            quantite = libres[-1]
    if quantite is None:
        for mot, val in APPROX.items():
            if mot in t:
                quantite, approx_q = val, True
    restants = [n for n in libres if n != quantite]

    # décision
    if len(retenus) == 1 and retenus[0][0][1]:
        return {"statut": "absent du catalogue", "variant_id": None, "quantite": quantite, "confiance": 0.6,
                "motif": f"variante non référencée (catalogue : {p0['nom']})"}
    if len(famille) > 1 and restants and max_ok == 0:
        return {"statut": "absent du catalogue", "variant_id": None, "quantite": quantite, "confiance": 0.6,
                "motif": f"caractéristique {restants[0]:g} inconnue pour : " + ", ".join(p['nom'] for _, p in famille)}
    if len(retenus) > 1:
        return {"statut": "ambigu, à faire préciser", "variant_id": None, "quantite": quantite, "confiance": 0.5,
                "motif": "plusieurs produits possibles : " + " / ".join(e[2]["nom"] for e in retenus)}
    (_, trouves, flou) = retenus[0][1]
    confiance = 0.95 - 0.15 * flou - 0.15 * (len(trouves) == 1) - 0.2 * approx_q - 0.3 * (quantite is None)
    return {"statut": "ok" if confiance >= 0.6 else "à vérifier", "variant_id": int(p0["id"]),
            "quantite": quantite, "confiance": round(confiance, 2), "motif": p0["nom"]}


def extraire(message, cat: Catalogue):
    """Un message peut contenir plusieurs produits : on découpe sur '+' et ' et '."""
    segments = [s for s in re.split(r"\s\+\s|\set\s", normaliser(message)) if s.strip()]
    return [extraire_segment(s, cat) for s in segments]
