# CryptoWatch 🪙

🚀 Projet : CryptoWatch
Application mobile de suivi des cours de cryptomonnaies en temps réel : liste du marché avec prix en direct, recherche et tri, fiche détaillée par crypto et watchlist personnelle sauvegardée localement.

📅 _Début :_ 2 septembre 2026
🏁 _Fin prévue :_ 16 septembre 2026

👥 Membres de l'équipe :
Guy Eclador TETANG ;
Joseph Tchapo NABOUDJA ;
Ruben Esli Guelahibi TONETY ;
Uriel HOUEGBE ;
Yannick Ulrich OUEDRAOGO ;
Eliel Koni Gmiminou COULIBALY .

👨‍💼 Chef d'équipe : Eliel Koni Gmiminou COULIBALY

🎓 Mentor : David BONGOUADE

---

## 1. L'architecture en bref

Nous utilisons une architecture **feature-first avec 3 couches par feature** (clean architecture allégée) :

- **Feature-first** : le code est rangé **par fonctionnalité** (marché, fiche crypto, watchlist…), pas par type de fichier. Pour travailler sur ta tâche, tu ouvres UN dossier et tout y est.
- **3 couches dans chaque feature** : `domain` (les classes métier), `data` (l'accès aux données), `presentation` (ce qui s'affiche). Chaque couche a une règle simple, expliquée plus bas.

**La règle d'or entre les couches** (à retenir, c'est la seule) :

```
presentation ──► data ──► domain
```

Les flèches pointent vers `domain`, jamais l'inverse : `domain` ne connaît personne, `data` ne connaît que `domain`, `presentation` peut connaître les deux. Si tu écris un import qui va dans l'autre sens, c'est le signe que quelque chose est au mauvais endroit - demande sur le groupe avant de forcer.

---

## 2. La structure des dossiers

```
lib/
├── main.dart                  # Point d'entrée : démarrage de l'app
├── app/                       # Ce qui concerne l'application ENTIÈRE
│   ├── app.dart               # Widget racine (MaterialApp, thème)
│   ├── router/                # Les routes de navigation (toutes ici)
│   └── theme/                 # Couleurs, styles de texte partagés
│
├── features/                  # UNE FONCTIONNALITÉ = UN DOSSIER
│   ├── market/                # La liste des cryptos et leurs prix
│   │   ├── domain/            #   → classes Crypto, Ticker… (T-02)
│   │   ├── data/              #   → accès API et temps réel (T-03, T-07)
│   │   └── presentation/      #   → écrans, widgets, providers (T-04, T-05, T-08)
│   │
│   ├── crypto_detail/         # La fiche d'une crypto
│   │   ├── data/              #   → historique des prix (T-10a)
│   │   └── presentation/      #   → écran de détail, graphique (T-06, T-10b)
│   │
│   └── watchlist/             # Les cryptos favorites
│       ├── data/              #   → sauvegarde locale (T-09b)
│       └── presentation/      #   → étoile, écran watchlist, providers (T-09a)
│
└── shared/                    # Ce qui est utilisé par PLUSIEURS features
    ├── widgets/               # Widgets réutilisables (ex: indicateur de variation)
    └── utils/                 # Petites fonctions utilitaires (ex: formatage des prix)

test/                          # Les tests - même logique de nommage que lib/
assets/                        # Images, icônes éventuelles
```

## Les écrans de l'application

| Écran                | Tâches           | Ce qu'il affiche                                                                                                                                                                    |
| -------------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| _Marché_ (principal) | T-04, T-05, T-08 | Recherche + tri · par crypto : logo, nom, symbole, prix _en direct_, variation 24h colorée (flash vert/rouge au changement) · étoile watchlist · indicateur de connexion temps réel |
| _Fiche crypto_       | T-06, T-10       | Logo, nom, symbole, rang · prix, variation 24h · plus haut / plus bas 24h · volume, capitalisation · courbe d'évolution 7 jours · étoile watchlist                                  |
| _Watchlist_          | T-09             | Les cryptos marquées d'une étoile, mêmes cartes que le marché · état vide avec message d'invitation                                                                                 |

Navigation : 2 onglets (Marché / Watchlist) · tap sur une carte → Fiche crypto.

## Les sources de données

Deux APIs gratuites et complémentaires - décision d'équipe :

- _CoinGecko (REST)_ - l'annuaire : donne naissance aux objets Crypto (nom, logo, prix,
  capitalisation, rang…).
  - Liste : https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1
  - Historique 7 jours : https://api.coingecko.com/api/v3/coins/{id}/market_chart?vs_currency=usd&days=7
  - Limite sans clé : ~30 appels/min - notre app n'en fait qu'une poignée au chargement, ça suffit.
- _Binance (WebSocket)_ - le pouls : fait évoluer les prix en continu, sans clé.
  - Stream : wss://stream.binance.com:9443/ws/<symbole>usdt@miniTicker (ex: btcusdt)

Le modèle Crypto reflète cette dualité : il _naît_ complet via CoinGecko
(fromCoinGeckoJson) et _évolue_ partiellement via Binance (updateFromBinanceTicker) -
voir la documentation de la classe pour le détail.

---

## 3. Chaque dossier expliqué

### `lib/main.dart`

Le point d'entrée. Il initialise ce qui doit l'être au démarrage puis lance l'application. **On n'y met aucune logique métier** - il doit rester court.

### `lib/app/`

Tout ce qui concerne l'application **dans son ensemble**, pas une fonctionnalité en particulier.

- `app.dart` : le widget racine - thème, configuration générale.
- `router/` : **toutes** les routes de navigation sont déclarées ici, à un seul endroit. Pour ajouter un écran, tu ajoutes sa route ici (et nulle part ailleurs).
- `theme/` : les couleurs et styles partagés, pour une app visuellement cohérente sans copier-coller de codes couleur.

### `lib/features/` - le cœur du projet

Chaque sous-dossier est une fonctionnalité complète et autonome. À l'intérieur, les 3 couches :

**`domain/` - les classes métier (Dart pur)**
Les classes qui représentent nos données : `Crypto`, `Ticker`, etc. avec leur logique propre (parsing, formatage, calculs).
✅ Uniquement du Dart standard.
❌ **Aucun import Flutter, aucun package externe.** Test rapide : ce dossier doit pouvoir se compiler dans un simple programme console. C'est ce qui rend ces classes ultra-simples à tester.

**`data/` - l'accès aux données**
Les _repositories_ : les classes qui vont chercher les données (API, temps réel, stockage local) et les transforment en classes du `domain`. C'est ICI qu'on gère les exceptions réseau, les timeouts, les réponses invalides.
✅ Importe `domain`.
❌ N'importe jamais rien de `presentation` - un repository ne sait pas qu'un écran existe.

**`presentation/` - ce qui s'affiche et réagit**
Trois sous-dossiers habituels :

- `screens/` : les écrans complets ;
- `widgets/` : les morceaux d'interface propres à cette feature (ex: la carte crypto de T-04a) ;
- `providers/` : la gestion d'état - le lien entre les données et l'affichage (chargement, erreur, données, mises à jour temps réel).
  ✅ Importe `data` et `domain`.
  ❌ Ne contient pas d'appel direct à une API : un écran demande au provider, qui demande au repository.

### `lib/shared/`

Ce qui sert à **plusieurs** features. Règle pratique : un widget ou une fonction naît dans SA feature ; on ne le déplace dans `shared/` que le jour où une **deuxième** feature en a besoin. (On ne crée pas du « réutilisable » par anticipation.)

### `test/`

Les tests suivent la même organisation que `lib/` : le test de `features/market/domain/crypto.dart` s'appelle `test/crypto_test.dart` (ou dans une arborescence miroir si on préfère). **Chaque tâche livre ses tests avec elle** — c'est dans les critères des PRs.

---

## 4. « Où va mon code ? » - correspondance avec les tâches

| Ta tâche                      | Ton dossier de travail                                |
| ----------------------------- | ----------------------------------------------------- |
| T-02 (classe Crypto)          | `features/market/domain/`                             |
| T-03a/b (API + exceptions)    | `features/market/data/`                               |
| T-04a (carte crypto)          | `features/market/presentation/widgets/`               |
| T-04b (liste + états)         | `features/market/presentation/` (screens + providers) |
| T-05a/b (recherche, tri)      | `features/market/presentation/providers/` + screens   |
| T-06a/b (fiche crypto)        | `features/crypto_detail/presentation/`                |
| T-07 / T-08 (temps réel)      | `features/market/data/` + `presentation/providers/`   |
| T-09a/b (watchlist)           | `features/watchlist/`                                 |
| T-10a/b (historique + courbe) | `features/crypto_detail/` (data + presentation)       |
| T-11 (tests)                  | `test/`                                               |

Si ta tâche te semble toucher un dossier qui n'est pas dans sa ligne → question sur le groupe AVANT de coder, on clarifie ensemble en 2 minutes.

---

## 5. Nos règles de travail Git

- **`main`** : la version stable et démontrable. On n'y pousse jamais directement.
- **`dev`** : la branche d'intégration - c'est elle que tu cibles avec tes Pull Requests.
- **`feature/<ton-initiale>/T-XX-description`** : ta branche de travail, une par tâche (ex: `feature/e/T-02-modele-crypto`), créée depuis `dev` à jour :

```bash
git checkout dev && git pull
git checkout -b feature/e/T-02-modele-crypto
```

- Avant chaque commit : `flutter analyze` (0 issue) et `flutter test` (tout vert).
- Ta PR : petite, centrée sur TA tâche, avec ses tests. La CI vérifie automatiquement ; une review d'un coéquipier, puis merge dans `dev`.
- Jamais fait de PR ? Dis-le, on fait la première ensemble en partage d'écran.

---

## 6. Lancer le projet

```bash
git clone https://github.com/Cooleliel/cryptowatch.git
cd cryptowatch
git checkout dev
flutter pub get
flutter run
```

Et pour vérifier avant de pousser :

```bash
flutter analyze && flutter test
```

---

_Ce README évoluera avec le projet (captures, fonctionnalités livrées, guide de démo) — version finale préparée en T-12._
