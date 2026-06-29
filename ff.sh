# 1. Importer Mozillas signeringsnøgle
sudo mkdir -p /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

# 2. Tilføj repo
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null

# 3. Tving APT til at foretrække Mozillas repo over Ubuntus snap-wrapper
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1' | sudo tee /etc/apt/preferences.d/mozilla

# 4. Fjern snap-versionen og installer den rigtige
sudo apt update
sudo snap remove --purge firefox
sudo apt install firefox

