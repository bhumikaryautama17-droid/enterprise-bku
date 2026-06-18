<?php
// diagnose.php
// Diagnostic tool for PT. Bhumi Karya Utama SQLite Deployment

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<html><head><title>System Diagnostic</title><style>
body { font-family: sans-serif; background: #0f172a; color: #f1f5f9; padding: 40px; }
h1 { color: #00e5ff; }
.card { background: #1e293b; padding: 20px; border-radius: 8px; border: 1px solid #334155; margin-bottom: 20px; }
.status { font-weight: bold; }
.ok { color: #10b981; }
.fail { color: #ef4444; }
pre { background: #0f172a; padding: 10px; border-radius: 4px; overflow: auto; border: 1px solid #334155; }
</style></head><body>";

echo "<h1>System Diagnostic Report</h1>";

echo "<div class='card'>";
echo "<h2>Environment Info</h2>";
echo "PHP Version: <strong>" . PHP_VERSION . "</strong><br/>";
echo "Server Software: <strong>" . (isset($_SERVER['SERVER_SOFTWARE']) ? $_SERVER['SERVER_SOFTWARE'] : 'N/A') . "</strong><br/>";
echo "Current Directory: <strong>" . __DIR__ . "</strong><br/>";
echo "</div>";

echo "<div class='card'>";
echo "<h2>Database Drivers Check</h2>";

$pdo_exists = class_exists('PDO');
echo "PDO Extension: " . ($pdo_exists ? "<span class='status ok'>LOADED</span>" : "<span class='status fail'>MISSING</span>") . "<br/>";

if ($pdo_exists) {
    $drivers = PDO::getAvailableDrivers();
    echo "Available Drivers: <strong>" . implode(', ', $drivers) . "</strong><br/>";
    $sqlite_ok = in_array('sqlite', $drivers);
    echo "SQLite Driver: " . ($sqlite_ok ? "<span class='status ok'>LOADED</span>" : "<span class='status fail'>MISSING (Please enable pdo_sqlite in cPanel -> Select PHP Version -> Extensions)</span>") . "<br/>";
} else {
    $sqlite_ok = false;
}
echo "</div>";

echo "<div class='card'>";
echo "<h2>File Permissions Check</h2>";
$dir_writable = is_writable(__DIR__);
echo "Directory Writable: " . ($dir_writable ? "<span class='status ok'>YES</span>" : "<span class='status fail'>NO (Please set write permissions for the website directory)</span>") . "<br/>";

$schema_exists = file_exists('schema.sql');
echo "schema.sql Found: " . ($schema_exists ? "<span class='status ok'>YES</span>" : "<span class='status fail'>NO (Please ensure schema.sql is uploaded)</span>") . "<br/>";

$db_file = 'database.sqlite';
if (file_exists($db_file)) {
    echo "database.sqlite Found: <span class='status ok'>YES</span><br/>";
    echo "database.sqlite Writable: " . (is_writable($db_file) ? "<span class='status ok'>YES</span>" : "<span class='status fail'>NO</span>") . "<br/>";
} else {
    echo "database.sqlite Found: <span class='status fail'>NO (Will be created automatically on first connection)</span><br/>";
}
echo "</div>";

if ($pdo_exists && $sqlite_ok && $dir_writable && $schema_exists) {
    echo "<div class='card'>";
    echo "<h2>Connection Test</h2>";
    try {
        $test_db = new PDO("sqlite:" . $db_file);
        $test_db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        echo "<span class='status ok'>SQLite Connection successful!</span><br/>";
        
        // Check if tables are loaded
        $stmt = $test_db->query("SELECT name FROM sqlite_master WHERE type='table' AND name='m_users'");
        if ($stmt->fetch()) {
            echo "Database Tables: <span class='status ok'>INITIALIZED & SEEDED</span><br/>";
            
            // Show users count
            $users_count = $test_db->query("SELECT COUNT(*) FROM m_users")->fetchColumn();
            echo "Total Registered Users: <strong>$users_count</strong><br/>";
        } else {
            echo "Database Tables: <span class='status fail'>NOT INITIALIZED</span> (Accessing the index.html should initialize them automatically)<br/>";
        }
    } catch (Exception $e) {
        echo "<span class='status fail'>Connection Test failed: " . $e->getMessage() . "</span><br/>";
    }
    echo "</div>";
}

echo "</body></html>";
?>
