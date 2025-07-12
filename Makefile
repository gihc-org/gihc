pub/index.html: dokument.adoc formål.adoc beskrivelse.adoc
	mkdir -p siden && asciidoctor -a lang=da dokument.adoc -o pub/index.html
