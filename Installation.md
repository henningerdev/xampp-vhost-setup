## 🔧 Installation & Nutzung

### 1. `vhost-setup.cmd`

- Diese Datei sollte mit **Administratorrechten ausgeführt** werden (Rechtsklick → „Als Administrator ausführen“).
- Sie automatisiert das Erstellen eines neuen Projektverzeichnisses inkl.:
  - VirtualHost-Konfiguration (Apache)
  - SSL-Zertifikat
  - `hosts`-Eintrag
  - `robots.txt` und `sitemap.xml`

### 2. Projektübersicht (`htdocs/`)

- Die Dateien `index.php`, `config.php` und `styles.css` gehören in den Ordner:  
  `[XAMPP-Verzeichnis]\htdocs\`  
  *(z. B. `C:\xampp\htdocs\` oder `D:\xampp\htdocs\`, je nach deinem Installationspfad)*

- Die Übersicht wird automatisch beim Aufruf von `http://localhost` im Browser angezeigt.
