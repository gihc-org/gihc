# TODO

## Handover-prompt til næste session

> Du fortsætter arbejdet på GIHC-hjemmesiden i
> `/home/kristian/projects/gihc`.
>
> Læs først `README.adoc`, `WEBSITE.md`, `MAIL.md`, `TODO.md`,
> `samarbejdspartnere.md`, `eleventy.config.js`, `package.json`,
> `artwork/`, `k8s/` og `scripts/`. Kontrollér derefter `git status -sb` og
> `git log -5 --oneline`.
>
> **Aktuel arkitektur**
>
> - Eleventy 3.1.7 genererer siden fra `src/` til `_site/`. `_site/` er
>   genereret og må ikke redigeres manuelt.
> - Dansk indhold ligger i `src/_data/da.yaml`, engelsk i
>   `src/_data/en.yaml`.
> - `src/_includes/base.njk` indeholder fælles HTML, metadata, Open Graph,
>   Twitter Card og favicon.
> - `src/_includes/home.njk` indeholder forsidens fælles sektioner og
>   optional resource-links i scenarie- og aktivitetskort.
> - `src/assets/gihc-og.png` er et 1200 × 630 RGB-PNG uden transparens.
>   Layoutkilden er `src/assets/gihc-og.svg`.
> - Runtime-imaget bruger Nginx 1.31 unprivileged med read-only rootfilsystem,
>   droppede capabilities og seccomp.
> - Kubernetes-workloaden ligger i namespace `gihc-site`, bag ingress-nginx,
>   cert-manager og Let's Encrypt.
> - Produktionsmanifestet pinner et SHA-tag i `k8s/deployment.yaml`.
> - Namespace har Pod Security `restricted`; NetworkPolicy tillader kun
>   ingress fra `ingress-nginx` til port 8080 og blokerer egress.
> - GitHub Actions er SHA-pinnet, Trivy blokerer HIGH/CRITICAL-sårbarheder, og
>   Dependabot opdaterer npm, Actions og Docker ugentligt.
> - CAA tillader kun Let's Encrypt. DNSSEC er fortsat ikke konfigureret.
> - Migadu har den aktive postkasse `mail@gihc.online`. MX, SPF, DKIM og
>   domæneverifikation er grønne.
> - DMARC er `p=none` med `rua`, `adkim=s`, `aspf=r` og `pct=100`. Stram
>   først policyen efter analyse af de faktiske mailheaders.
> - Hjemmesidens offentlige kontaktadresse er `mail@gihc.online`. Den private
>   recovery-adresse bruges kun i Migadu-flowet og må ikke offentliggøres.
> - GIHC Mini-Mesh ligger lokalt som `../gihc-mesh` og offentligt på
>   `https://mesh.gihc.online/`.
> - Sessionens referat ligger i `referater/2026-10-22.md`.
>
> **Status ved handover**
>
> - `https://gihc.online/` og `https://gihc.online/en/` svarer korrekt.
> - Produktionsmanifestet peger på website-image `dbb2b98`; den tilhørende
>   CI-kørsel og efterfølgende smoke-test var grønne.
> - Seneste produktionsdeploy var commit `8d4a860`. Efterfølgende
>   dokumentationscommits kræver ikke nyt website-image.
> - `npm run check` og `scripts/smoke-test.sh https://gihc.online` bestod.
> - Facebook kan hente det nye sociale previewbillede. Sharing Debugger
>   meldte manglende `fb:app_id`; indsæt kun et rigtigt Meta App ID.
> - De fulde Gmail-headers fra den spamplacerede mail mangler stadig.
>
> **Vigtige kommandoer**
>
> ```bash
> npm ci
> npm run dev
> npm run check
> git status -sb
> ./scripts/smoke-test.sh https://gihc.online
> ./scripts/setup-migadu-mail.py --diagnose
> ```
>
> Lokal k3s optager port 6443. Brug derfor:
>
> ```bash
> ssh -L 16443:localhost:6443 -N -f hetzner-k3s
> KUBECTL_SERVER=https://127.0.0.1:16443 ./scripts/deploy.sh
> ```
>
> SSH-nøglen kan være passphrase-beskyttet. Spørg brugeren, hvis den ikke er
> indlæst; læg aldrig passphrase eller private nøgler i filer eller
> kommandoer.
>
> **Arbejdsregler**
>
> - Bevar det nuværende visuelle udtryk uden eksplicit redesignønske.
> - Redigér almindelige tekster i begge YAML-filer, ikke i `_site/`.
> - Nye gentagne kort eller links skal bygges som data og vises via løkker i
>   `home.njk`.
> - Kør `npm run check` efter indholds-, template- eller assetændringer.
> - Test desktop og mobil ved cirka 1440 px og 390 px.
> - Bevar CSP, sikkerhedsheadere, health checks, non-root-container,
>   read-only rootfilsystem og SHA-pinning.
> - Deploy ikke et image med uafhjulpne HIGH- eller CRITICAL-fund.
> - Opdatér `WEBSITE.md`, hvis arbejdsgangen eller filstrukturen ændres.
> - Undgå at ændre den lokale k3s-installation på port 6443.
> - Brug `pass` og Kubernetes Secrets til credentials.
>
> **Deploy ved websiteændringer**
>
> 1. Redigér relevante YAML-, template- eller assetfiler.
> 2. Kør `npm run check`.
> 3. Commit og push til `main`.
> 4. Kontrollér, at workflowet “Publish website image” er grønt.
> 5. Opdatér image-SHA'en i `k8s/deployment.yaml`, og commit/push den.
> 6. Åbn tunnelen på 16443, kør `scripts/deploy.sh`, og kør den offentlige
>    smoke-test.
>
> **Næste relevante opgaver**
>
> - Kør `https://gihc.online/` gennem Facebooks Sharing Debugger og genopslå
>   linket, hvis et ældre preview caches.
> - Opret kun en Meta-app og `fb:app_id`, hvis valideringsadvarslen ønskes
>   fjernet; brug aldrig et gættet ID.
> - Analysér Gmail-headers for SPF, DKIM, DMARC og afsender-IP, før DMARC
>   strammes.
> - Fortsæt opvarmning og test af `mail@gihc.online`.
> - Undersøg DNSSEC hos Simply.com.
> - Brug `samarbejdspartnere.md` til kontaktrunden og udfyld kontaktloggen.
> - Afklar forsikring, børneattester og persondata før fælles aktiviteter
>   med børn og familier.
> - Hvis mærkepakken ændres, opdateres den kanoniske kilde i
>   `artwork/gihc-badge/`, PDF’er eksporteres på ny, og ZIP-filen genbygges og
>   kopieres til `src/assets/`.
> - Hvis sociale previews ændres, følg afsnittet i `WEBSITE.md`, og bevar et
>   fladt 1200 × 630 PNG uden transparens.
>
> **Definition af færdig**
>
> En ændring er først færdig, når `npm run check` består, den offentlige
> smoke-test består efter deploy, desktop og mobil er visuelt kontrolleret, og
> relevante ændringer er committet og synkroniseret med `origin/main`.

## Samarbejde og netværk

Se den samlede liste i [samarbejdspartnere.md](samarbejdspartnere.md).

- [ ] Vælg GIHCs geografiske fokusområde og find de nærmeste lokale afdelinger.
- [ ] Prioritér de fem første kontakter fra samarbejdslisten.
- [ ] Skriv en kort GIHC-præsentation med formål, aktiviteter, målgruppe,
      kontaktoplysninger og rammer for en fælles aktivitet.
- [ ] Lav en kort og konkret henvendelsesskabelon, som kan tilpasses den enkelte
      organisation.
- [ ] Afklar forsikring, børneattester, ansvar og persondata før fælles
      aktiviteter med børn og familier.
- [ ] Kontakt den nærmeste lokale spejdergruppe.
- [ ] Kontakt den lokale EDR-radioamatørklub.
- [ ] Kontakt den nærmeste Repair Café.
- [ ] Kontakt Labitat og/eller Open Space Aarhus.
- [ ] Kontakt Beredskabsforbundet / Beredskab.dk.
- [ ] Kontakt Dansk Røde Kors og Dansk Orienterings-Forbund.
- [ ] Kontakt Permakultur Danmark, Frøsamlerne og Økologisk Landsforening.
- [ ] Kontakt Videnskabsklubben, Coding Pirates og prepper.dk.
- [ ] Notér dato, kontaktperson, svar og næste skridt for hver henvendelse.
- [ ] Følg op efter cirka to uger, hvis der ikke er kommet svar.

## Kontaktlog

| Organisation | Kontaktperson | Dato | Status | Næste skridt |
| --- | --- | --- | --- | --- |
|  |  |  | Ikke kontaktet |  |

## E-mailopsætning

Se [MAIL.md](MAIL.md) og `scripts/setup-migadu-mail.py`.

- [x] Opret Migadu-konto og gem `migadu/account` i `pass`.
- [x] Opret Migadu API-nøgle og gem `migadu/api-key` i `pass`.
- [x] Kør `./scripts/setup-migadu-mail.py` som tørkørsel.
- [x] Kør `./scripts/setup-migadu-mail.py --apply`.
- [x] Kontrollér MX, SPF, DKIM og domæneverifikation med `--diagnose`.
- [x] Aktivér domænet med `--activate`.
- [x] Accepter Migadu-invitationen og vælg adgangskode til `mail@gihc.online`.
- [ ] Test indgående og udgående mail fra Gmail og Outlook.
- [ ] Gem eller kopiér de fulde Gmail-headers fra den første spamplacerede
      mail og kontrollér SPF-, DKIM- og DMARC-resultater samt afsender-IP.
- [ ] Markér adressen som “Ikke spam” og tilføj den til Gmail-kontakter.
- [ ] Stram DMARC til `p=quarantine`, når mailflowet er verificeret.
- [x] Opdatér hjemmesidens kontaktoplysninger til `mail@gihc.online`.
- [ ] Opret en separat Resend API-nøgle til server-side afsendelse.

