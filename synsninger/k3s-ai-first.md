Det er mandag aften. Jeg sidder og konfigurerer OpenTofu til at administrere en VPS med to apps.

Jeg er ikke Google. Jeg behøver ikke Kubernetes.

Men mit nuværende setup er et snowflake. Hver gang jeg deployer, skal jeg huske hvilke quirks der gælder: at Caddy inde i Docker ikke kan bruge systemets DNS, at ACME fejler lydløst hvis DNS ikke er propageret endnu, at netværk skal oprettes i den rigtige rækkefølge. Det virker — men kun fordi jeg husker det.

Det er ikke holdbar infrastruktur. Det er holdbar hukommelse.

Så jeg migrerer til k3s. Ikke fordi jeg skal bruge Kubernetes, men fordi jeg kender det fra EKS og Rancher, og fordi deklarativ infrastruktur er reproducerbar infrastruktur. Næste gang jeg bygger det op, behøver jeg ikke huske quirksene — de er i koden.

Det interessante er, hvordan jeg planlægger det: jeg sætter mig ned med Claude Code, beskriver hvad jeg vil opnå, og vi laver en plan sammen. Fire faser, klare beslutninger, dokumenteret i referater jeg kan læse op næste session. AI som pairing-partner til at tænke med — ikke som skriveassistent.

Det er "AI first" for mig.

Bruger andre AI aktivt i infrastruktur-beslutninger — eller er det primært til kode?

#Kubernetes #DevOps #AIFirst #k3s #Infrastructure
