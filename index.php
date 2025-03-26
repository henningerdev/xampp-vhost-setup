<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>XAMPP Projektübersicht</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <?php 
    /**
     * XAMPP Projekt Manager - Projektübersicht
     * 
     * Diese Datei stellt die Web-Oberfläche für den XAMPP Projekt Manager dar.
     * Sie zeigt alle gefundenen Projekte in einer übersichtlichen Grid-Ansicht an.
     */
    
    // Projektdaten laden
    require_once 'config.php'; 
    ?>
    
    <div class="container">
        <h1>XAMPP Projektübersicht</h1>
        
        <!-- Informationsleiste mit Server-Infos -->
        <div class="info-bar">
            <?php echo count($projects); ?> Projekte gefunden | 
            Server: <?php echo $_SERVER['SERVER_SOFTWARE']; ?> | 
            PHP Version: <?php echo PHP_VERSION; ?>
        </div>

        <!-- Projekt-Grid -->
        <div class="projects-grid">
            <?php foreach($projects as $project): ?>
                <div class="project-card">
                    <h2 class="project-title"><?php echo htmlspecialchars($project['title']); ?></h2>
                    <div class="project-description">
                        <?php echo htmlspecialchars($project['description']); ?>
                    </div>
                    <?php if($project['hasIndex']): ?>
                        <div class="project-links">
                            <?php 
                            // Domain aus dem Projekt abrufen
                            $domain = $project['domain'];
                            
                            // Standard-Endung falls keine in der Domain angegeben ist
                            $defaultSuffix = '.local';
                            
                            // Nur das Standard-Suffix hinzufügen, wenn kein anderes Suffix vorhanden ist
                            if (!hasDomainSuffix($domain)) {
                                $domain .= $defaultSuffix;
                            }
                            ?>
                            <a href="http://<?php echo $domain; ?>" 
                               class="project-link http-link" 
                               target="_blank">HTTP</a>
                            <a href="https://<?php echo $domain; ?>" 
                               class="project-link https-link" 
                               target="_blank">HTTPS</a>
                        </div>
                    <?php else: ?>
                        <div class="error-message">Keine index.php/html gefunden</div>
                    <?php endif; ?>
                    <div class="last-modified">
                        📅 Zuletzt geändert: <?php echo $project['lastModified']; ?>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    </div>
</body>
</html>