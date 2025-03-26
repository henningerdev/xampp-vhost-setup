<?php
/**
 * XAMPP Projekt Manager - Konfigurationsdatei
 * 
 * Diese Datei enthält die grundlegende Konfiguration für den Projekt Manager:
 * - Definition der auszuschließenden Verzeichnisse
 * - Funktionen zum Erkennen von Projekten
 * - Funktionen zum Auslesen von Projektmetadaten
 * - Sammeln aller verfügbaren Projekte mit ihren Metadaten
 */

// Liste der zu ignorierenden Verzeichnisse
$excludeDirs = array('.', '..', 'dashboard', 'img', 'webalizer', 'security');

// Festlegen des Basis-Pfads (aktuelle Verzeichnis)
$htdocsPath = __DIR__;

/**
 * Prüft, ob ein Verzeichnis ein gültiges Projekt ist
 * 
 * @param string $dir Der zu prüfende Verzeichnisname
 * @return bool True, wenn es sich um ein Projekt handelt, sonst False
 */
function isProjectDir($dir) {
    global $excludeDirs, $htdocsPath;
    return is_dir($htdocsPath . '/' . $dir) 
           && !in_array($dir, $excludeDirs) 
           && !str_starts_with($dir, '.');
}

/**
 * Prüft, ob eine Domain bereits eine Endung hat (z.B. .local, .test)
 * 
 * @param string $domain Die zu prüfende Domain
 * @return bool True, wenn die Domain eine Endung hat, sonst False
 */
function hasDomainSuffix($domain) {
    return preg_match('/\.[a-z0-9]+$/i', $domain);
}

/**
 * Liest die Metadaten eines Projekts aus der project.json
 * 
 * @param string $projectPath Pfad zum Projektverzeichnis
 * @return array Array mit Titel, Beschreibung und Domain des Projekts
 */
function getProjectMetadata($projectPath) {
    $metadataFile = $projectPath . '/project.json';
    if (file_exists($metadataFile)) {
        $metadata = json_decode(file_get_contents($metadataFile), true);
        return [
            'title' => $metadata['title'] ?? basename($projectPath),
            'description' => $metadata['description'] ?? 'Keine Beschreibung verfügbar',
            'domain' => $metadata['domain'] ?? basename($projectPath) // Domain als separate Eigenschaft
        ];
    }
    
    // Fallback für Projekte ohne project.json
    return [
        'title' => basename($projectPath),
        'description' => 'Keine Beschreibung verfügbar',
        'domain' => basename($projectPath) // Domain ist standardmäßig der Verzeichnisname
    ];
}

/**
 * Sammelt alle Projekte und ihre Metadaten
 * 
 * Scannt alle Verzeichnisse im htdocs-Ordner und filtert gültige Projekte.
 * Für jedes Projekt werden die Metadaten gelesen und weitere Infos gesammelt.
 */
$projects = array_map(function($dir) use ($htdocsPath) {
    $projectPath = $htdocsPath . '/' . $dir;
    $metadata = getProjectMetadata($projectPath);
    
    return [
        'dir' => $dir,                     // Verzeichnisname
        'path' => $projectPath,            // Vollständiger Pfad
        'title' => $metadata['title'],     // Projekttitel
        'description' => $metadata['description'], // Projektbeschreibung
        'domain' => $metadata['domain'],   // Domain für Links (kann vom Verzeichnisnamen abweichen)
        'lastModified' => date("d.m.Y H:i", filemtime($projectPath)), // Letztes Änderungsdatum
        'hasIndex' => file_exists($projectPath . '/index.php') || 
                     file_exists($projectPath . '/index.html') // Prüft ob eine Index-Datei existiert
    ];
}, array_filter(scandir($htdocsPath), 'isProjectDir'));
?>