# XAMPP VHost Setup & Projektübersicht

Dieses Projekt besteht aus zwei Komponenten zur Unterstützung lokaler Webentwicklung mit XAMPP unter Windows:

---

## 🧰 1. `vhost-setup.cmd`

Ein Batch-Skript zur automatisierten Erstellung von VirtualHosts inkl.:
- Projektverzeichnis
- SSL-Zertifikaten (lokal)
- Einträgen in `hosts` und Apache-Konfiguration
- `sitemap.xml` und `robots.txt`

Ziel: Vereinfachung und Automatisierung wiederkehrender Setup-Aufgaben bei lokalen Projekten.

---

## 🖥️ 2. Projektübersicht (`htdocs/`)

Eine einfache Startseite, die lokal in XAMPP unter `htdocs/` genutzt werden kann, um verfügbare Projekte übersichtlich anzuzeigen.

**Dateien:**
- `index.php` – Übersicht der vorhandenen lokalen Domains
- `config.php` – Konfigurationsmöglichkeiten
- `styles.css` – Gestaltung

---

## 🔄 Weiterentwicklung

Ich arbeite aktuell an einer erweiterten Version mit grafischer Oberfläche (Electron) und Unterstützung für Linux/macOS – Ziel ist ein plattformübergreifendes Open-Source-Tool zur lokalen Projektverwaltung mit VHost-Setup, Übersicht, Domainmanagement & mehr.

Die neue Version soll **nicht mehr exklusiv für XAMPP** sein:  
Benutzer:innen können ihren bevorzugten lokalen Webserver (z. B. XAMPP, Laragon, MAMP oder eine manuelle Apache/nginx-Installation) auswählen oder individuell konfigurieren.

---

## 📄 Lizenz

Dieses Projekt steht unter der [CC BY-NC 4.0 Lizenz](LICENSE).  
Eine Nutzung ist **frei für nicht-kommerzielle Zwecke**, Namensnennung erwünscht.

---

**Autor:** Marco Henninger  
**GitHub:** [@henningerdev](https://github.com/henningerdev)
