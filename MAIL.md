# GIHC-mail

Opsætningen bruger Migadu til postkassen og Resend til udgående systemmail.
Migadu-API'et opretter domænet, inviterer `mail@gihc.online` og leverer de
DNS-records, som scriptet kan overføre til Simply.com.

## Engangsopsætning

1. Opret en konto på <https://migadu.com/>.
2. Opret en API-nøgle under **My Account → API Keys**.
3. Gem kontoens mailadresse og API-nøglen i `pass`:

   ```bash
   pass insert migadu/account
   pass insert migadu/api-key
   ```

Credentials til Simply.com skal allerede ligge som `simply/account` og
`simply/api-key`.

## Tørkørsel

Kontrollér opsætningen uden at ændre noget:

```bash
./scripts/setup-migadu-mail.py
```

## Anvend

Opret domænet, postkassen og de manglende DNS-records:

```bash
./scripts/setup-migadu-mail.py --apply
```

Migadu sender en invitation til
`kristian.n.jensen@gmail.com`. Invitationen bruges til at vælge adgangskode
til postkassen.

Scriptet stopper uden ændringer, hvis der findes konfliktende MX-, SPF- eller
CNAME-records. Den eksisterende Resend/SES-konfiguration på
`send.gihc.online` berøres ikke.

## Efter DNS-propagering

Kontrollér DNS og aktivér domænet:

```bash
./scripts/setup-migadu-mail.py --diagnose
./scripts/setup-migadu-mail.py --activate
```

Forventet DNS-opsætning fra Migadu omfatter:

- to MX-records på `@`
- SPF på `@`
- tre DKIM CNAME-records
- én TXT-record til domæneverifikation

DMARC-recorden på `_dmarc` findes allerede med `p=none`. Den bør først strammes
til `p=quarantine`, når både indgående og udgående mail er verificeret.

## Afsendelse fra kode

Resend API-nøglen skal gemmes som en Kubernetes Secret og må aldrig være del af
den statiske browserkode:

```bash
pass insert resend/api-key
```

Til afsendelsen bruges en server-side funktion eller en lille separat service.
Den statiske GIHC-side må ikke kalde Resend direkte fra browseren.

