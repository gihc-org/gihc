# Vedligeholdelse af GIHC-hjemmesiden

Siden bruger Eleventy til at generere statisk HTML fra kilderne i `src/`.
Den færdige side ligger i `_site/`, som er genereret og ikke skal redigeres.

## Første gang

```bash
npm ci
```

## Daglig redigering

Start den lokale udviklingsserver:

```bash
npm run dev
```

Åbn `http://localhost:8080`.

### Almindelige tekstændringer

Redigér `src/_data/site.yaml`. Her ligger:

- forside, hero og call-to-action
- scenarier og aktiviteter
- kontaktoplysninger
- downloadlink til mærkepakken
- navigation og footer

Hvis en tekst indeholder et kolon eller starter med et specialtegn, bør den
sættes i citationstegn:

```yaml
title: "Et eksempel: med kolon"
```

### Tilføj en ny aktivitet

Tilføj et element under `activities.cards` i `src/_data/site.yaml`:

```yaml
- className: activity-workshops
  icon: workshop
  format: Format 05
  title: Reparationsværksted
  text: Vi undersøger, fejlfinder og reparerer noget, der ellers ville blive smidt væk.
  detail: Tag gerne en defekt ting med.
```

Tilgængelige ikoner er `workshop`, `camp`, `training` og `game`. Nye ikoner
tilføjes i `src/_includes/activity-icon.njk`.

### Ændr layout eller styling

- Overordnet HTML-layout: `src/_includes/base.njk`
- Forsidens sektioner: `src/index.njk`
- 404-siden: `src/404.njk`
- Farver, typografi og responsivt layout: `src/assets/styles.css`

### Opdatér filer og downloads

Læg statiske filer i `src/assets/`. Eleventy kopierer hele mappen til
`_site/assets/` under build.

Den offentlige mærkepakke ligger i:

```text
src/assets/gihc-badge-75mm.zip
```

Den kanoniske kilde til mærkepakken ligger fortsat i `artwork/gihc-badge/`.
Hvis pakken ændres, skal ZIP-filen genbygges og kopieres til `src/assets/`.

## Kontrollér ændringerne

```bash
npm run check
```

Kommandoen bygger siden og kontrollerer blandt andet:

- at forside og 404-side genereres
- at centrale tekster og kontaktlinks findes
- at lokale links og assets eksisterer
- at mærkepakken er en gyldig ZIP-fil
- at der ikke er udfyldte Nunjucks-tags tilbage i HTML'en

Test også gerne siden manuelt ved cirka 390 px og 1440 px bredde.

## Byg og deploy

Den normale produktionsvej er:

1. Commit ændringerne til `main`.
2. Push til GitHub, så GitHub Actions bygger et nyt image.
3. Opdatér image-SHA'en i `k8s/deployment.yaml`.
4. Åbn tunnel til VPS'en og deploy:

```bash
ssh -L 16443:localhost:6443 -N -f hetzner-k3s
KUBECTL_SERVER=https://127.0.0.1:16443 ./scripts/deploy.sh
./scripts/smoke-test.sh https://gihc.online
```

Den lokale container kan testes uden at ramme VPS'en:

```bash
docker build -t ghcr.io/gihc-org/gihc:local .
docker run --rm -d --name gihc-local -p 4174:8080 ghcr.io/gihc-org/gihc:local
./scripts/smoke-test.sh http://127.0.0.1:4174
docker stop gihc-local
```

## Vigtige filer

| Fil | Formål |
| --- | --- |
| `src/_data/site.yaml` | Alt redaktionelt indhold |
| `src/index.njk` | Forsidens struktur og gentagelser |
| `src/_includes/base.njk` | Fælles HTML, metadata, header og footer |
| `src/assets/styles.css` | Design og responsivitet |
| `eleventy.config.js` | Eleventy-konfiguration og asset-kopiering |
| `package-lock.json` | Låste build-afhængigheder |
| `Dockerfile` | Eleventy-build og statisk Nginx-image |
| `scripts/check-build.mjs` | Automatisk indholds- og linkkontrol |

