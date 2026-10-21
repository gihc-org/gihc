# TODO

## Handover-prompt til næste session

> Du fortsætter arbejdet på GIHC-hjemmesiden i
> `/home/kristian/projects/gihc`.
>
> Læs først `README.adoc`, `WEBSITE.md`, `MAIL.md`, `TODO.md`,
> `samarbejdspartnere.md`, `eleventy.config.js`, `package.json`,
> `artwork/`, `k8s/` og `scripts/`. Kontrollér derefter `git status` og
> `git log -5 --oneline`.
>
> **Aktuel arkitektur**
>
> - Siden genereres med Eleventy 3.1.7 fra `src/` og outputtet ligger i
>   `_site/`. `_site/` er genereret og må ikke redigeres manuelt.
> - Dansk redaktionelt indhold ligger i `src/_data/da.yaml`, og engelsk
>   indhold ligger i `src/_data/en.yaml`.
> - Fælles HTML og metadata ligger i `src/_includes/base.njk`.
> - Forsidens fælles sektioner ligger i `src/_includes/home.njk`.
> - Dansk forside ligger i `src/index.njk`, engelsk i `src/en/index.njk`,
>   og 404-siden i `src/404.njk`.
> - Sprogskifte og `hreflang` genereres fra de to sprogdatafiler. Dansk er
>   standard på `/`, og engelsk ligger på `/en/`.
> - Styles og statiske filer ligger i `src/assets/`.
> - `Dockerfile` bruger et Node 24-buildtrin og kopierer derefter det
>   statiske Eleventy-output til det eksisterende unprivileged Nginx-image.
> - Kubernetes-workloaden ligger i namespace `gihc-site` og kører på VPS’en
>   bag ingress-nginx, cert-manager og Let’s Encrypt.
> - Produktionsmanifestet pinner et SHA-tag i `k8s/deployment.yaml`.
> - Runtime-imaget bruger Nginx 1.31 med non-root, read-only rootfilsystem,
>   droppede capabilities og seccomp.
> - Namespace har Pod Security `restricted`, og en NetworkPolicy tillader kun
>   ingress-trafik fra `ingress-nginx` til port 8080 samt blokerer egress.
> - CI scanner imaget med Trivy for HIGH/CRITICAL-sårbarheder, før det pushes.
> - GitHub Actions er pinnet til commit-SHA'er, og Dependabot opdaterer npm,
>   Actions og Docker ugentligt.
> - CAA tillader kun Let's Encrypt. DNSSEC er fortsat ikke konfigureret.
> - Migadu er sat op med postkassen `mail@gihc.online`; domænet er aktivt,
>   og MX, SPF, DKIM og verifikation er grønne.
> - Postkassen er taget i brug. Udgående testmail er observeret leveret,
>   men den første mail endte i Gmail-spam.
> - DMARC står fortsat på `p=none`, nu med `rua`, `adkim=s`, `aspf=r` og
>   `pct=100`. Policyen må først strammes efter headeranalyse.
> - Der findes en forenklet GitHub-avatar i SVG og PNG i
>   `artwork/gihc-avatar/`.
> - Sessionens referat ligger i `referater/2026-10-21.md`.
>
> **Status ved handover**
>
> - https://gihc.online og https://gihc.online/en/ svarer korrekt med gyldigt
>   HTTPS-certifikat.
> - Repoet var synkroniseret med `origin/main` ved `5c6333e`, og GitHub
>   Actions-kørslen for den commit var `success`.
> - Produktionsmanifestet peger på website-image `77a68e2`, som indeholder
>   den seneste CSS-rettelse. Efterfølgende commits er dokumentation, mail
>   og avatar og kræver ikke nyt website-image.
> - Kontrollér altid den aktuelle forskel med `git status -sb`.
> - `npm run check` og `scripts/smoke-test.sh https://gihc.online` bestod.
> - Migadus DNS-diagnostik bestod for verify, nameservers, SPF, MX og DKIM.
> - De fulde Gmail-headers fra spammailen mangler stadig.
>
> **Vigtige kommandoer**
>
> ```bash
> npm ci
> npm run dev
> npm run check
> git status
> ./scripts/smoke-test.sh https://gihc.online
> ./scripts/setup-migadu-mail.py --diagnose
> ```
>
> Hvis den lokale k3s-installation optager port 6443, må den ikke bruges til
> VPS-tunnelen. Brug i stedet:
>
> ```bash
> ssh -L 16443:localhost:6443 -N -f hetzner-k3s
> KUBECTL_SERVER=https://127.0.0.1:16443 ./scripts/deploy.sh
> ```
>
> SSH-nøglen kan være passphrase-beskyttet. Spørg brugeren, hvis den ikke er
> indlæst; brug ikke passphrasen som en del af kommandoer eller filer.
>
> **Arbejdsregler**
>
> - Bevar det nuværende visuelle udtryk, medmindre brugeren udtrykkeligt beder
>   om et redesign.
> - Foretag almindelige tekstændringer i både `src/_data/da.yaml` og
>   `src/_data/en.yaml`, ikke i genereret HTML.
> - Kør `npm run check` efter indholds-, template- eller assetændringer.
> - Test både desktop og mobil ved cirka 1440 px og 390 px.
> - Bevar CSP, sikkerhedsheadere, health checks, non-root-container og
>   SHA-pinning.
> - Deploy ikke et image, hvor Trivy finder uafhjulpne HIGH- eller
>   CRITICAL-sårbarheder.
> - Opdatér `WEBSITE.md`, hvis arbejdsgangen eller filstrukturen ændres.
> - Undgå at ændre den lokale k3s-installation på port 6443.
> - Læg aldrig credentials eller private nøgler i filer. Brug `pass` og
>   Kubernetes Secrets.
>
> **Deploy ved indholdsændringer**
>
> 1. Redigér `src/_data/da.yaml` og `src/_data/en.yaml` eller relevante
>    template-/asset-filer.
> 2. Kør `npm run check`.
> 3. Commit og push til `main`.
> 4. Kontrollér, at GitHub Actions-workflowet “Publish website image” bliver
>    grønt.
> 5. Opdatér image-SHA’en i `k8s/deployment.yaml`.
> 6. Åbn tunnelen på 16443, anvend Kustomize-manifesterne med
>    `scripts/deploy.sh`, og kør den offentlige smoke-test.
>
> **Næste relevante opgaver**
>
> - Brug `samarbejdspartnere.md` til den kommende kontaktrunde.
> - Udfyld kontaktloggen i dette dokument med dato, person, status og næste
>   skridt.
> - Afklar forsikring, børneattester og persondata, før der aftales fælles
>   aktiviteter med børn og familier.
> - Hvis der tilføjes nye gentagne sektioner, skal de bygges som data i begge
>   sprogfiler og vises via en løkke i `home.njk` frem for kopieret HTML.
> - Hvis mærkepakken ændres, skal den kanoniske kilde i `artwork/gihc-badge/`
>   opdateres, ZIP-filen genbygges og kopieres til
>   `src/assets/gihc-badge-75mm.zip`.
> - Undersøg hos Simply.com, om DNSSEC kan aktiveres.
> - Hjemmesidens kontaktadresse er `mail@gihc.online`. Den private
>   recovery-adresse bruges kun i Migadu-invitationsflowet.
> - Analysér de fulde Gmail-headers fra den spamplacerede mail. Kontrollér
>   `Authentication-Results`, `Received-SPF`, DKIM og afsender-IP, før DMARC
>   ændres til `p=quarantine`.
> - Fortsæt opvarmningen af `mail@gihc.online` med personlig, almindelig
>   tekst og test både indgående og udgående mail.
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

