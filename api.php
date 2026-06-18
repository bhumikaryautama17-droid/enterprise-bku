<?php
// api.php
// Backend API Controller for PT. Bhumi Karya Utama Workflow System (cPanel SQLite Version)

// ==================== SMTP EMAIL SETTINGS ====================
// Ubah USE_SMTP menjadi true jika fungsi mail() di hosting Anda mati/diblokir.
define('USE_SMTP', false); 
define('SMTP_HOST', 'mail.yourdomain.com');
define('SMTP_PORT', 465); // Port SMTP (biasanya 465 untuk SSL, atau 587 untuk TLS, atau 25)
define('SMTP_USER', 'noreply@yourdomain.com'); // Username SMTP (alamat email pengirim)
define('SMTP_PASS', 'yourpassword'); // Password SMTP email pengirim
define('SMTP_ENC', 'ssl'); // enkripsi: 'ssl', 'tls', atau '' (tanpa enkripsi)
define('SENDER_NAME', 'E-Approval System'); // Nama pengirim di email
define('SENDER_EMAIL', 'noreply@yourdomain.com'); // Alamat email pengirim
// =============================================================

error_reporting(0);
ini_set('display_errors', 0);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');

// Handle CORS preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Check if this is a zip deployment request
if (isset($_GET['action']) && $_GET['action'] === 'deploy') {
    $key = isset($_GET['key']) ? $_GET['key'] : (isset($_POST['key']) ? $_POST['key'] : '');
    define('DEPLOY_KEY', 'enterprise-bku.my.id'); // Secret deploy key
    if ($key !== DEPLOY_KEY) {
        header('HTTP/1.0 403 Forbidden');
        echo json_encode(['success' => false, 'error' => 'Forbidden: Invalid Deploy Key']);
        exit;
    }
    
    if (!isset($_FILES['zip'])) {
        echo json_encode(['success' => false, 'error' => 'Missing zip file']);
        exit;
    }
    
    $zipFile = $_FILES['zip']['tmp_name'];
    $zip = new ZipArchive;
    if ($zip->open($zipFile) === TRUE) {
        // Extract to current directory
        $zip->extractTo(__DIR__);
        $zip->close();
        echo json_encode(['success' => true, 'message' => 'Deploy successful: files updated on cPanel!']);
    } else {
        echo json_encode(['success' => false, 'error' => 'Failed to open zip archive']);
    }
    exit;
}

// Parse request payload first
$rawInput = file_get_contents('php://input');
$payload = json_decode($rawInput, true);

if (!$payload || !isset($payload['action'])) {
    echo json_encode([
        'success' => false,
        'error' => 'Invalid request payload'
    ]);
    exit;
}

$action = $payload['action'];
$args = isset($payload['args']) ? $payload['args'] : [];

$db_file = 'database.sqlite';
$db = null;

try {
    // Connect to SQLite Database
    $db = new PDO("sqlite:" . $db_file);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    
    // Enable SQLite foreign keys
    $db->exec("PRAGMA foreign_keys = ON;");
    
    // Check if table m_users exists and is populated to verify initialization
    $db_is_empty = true;
    try {
        $stmt = $db->query("SELECT COUNT(*) FROM m_users");
        $count = $stmt->fetchColumn();
        if ($count > 0) {
            $db_is_empty = false;
        }
    } catch (Exception $e) {
        $db_is_empty = true;
    }
    
    // Auto-initialize SQLite database if empty
    if ($db_is_empty) {
        if (file_exists('schema.sql')) {
            $sql = file_get_contents('schema.sql');
            $db->exec($sql);
        } else {
            throw new Exception("File schema.sql tidak ditemukan untuk inisialisasi database.");
        }
    } else {
        // Table exists, ensure the email column exists
        try {
            $cols = $db->query("PRAGMA table_info(m_users)")->fetchAll();
            $has_email = false;
            foreach ($cols as $col) {
                if ($col['name'] === 'email') {
                    $has_email = true;
                    break;
                }
            }
            if (!$has_email) {
                $db->exec("ALTER TABLE m_users ADD COLUMN email TEXT DEFAULT NULL");
            }
        } catch (Exception $col_err) {
            // Ignore if already altered or fails
        }
        
        // Self-healing migration for Performance Dashboard tables
        try {
            $perf_exists = $db->query("SELECT count(*) FROM sqlite_master WHERE type='table' AND name='t_perf_kpis'")->fetchColumn();
            if (!$perf_exists) {
                $db->exec("
                    CREATE TABLE IF NOT EXISTS `t_perf_kpis` (
                      `metric_key` TEXT PRIMARY KEY,
                      `metric_label` TEXT NOT NULL,
                      `value_actual` REAL NOT NULL,
                      `value_target` REAL NOT NULL,
                      `unit` TEXT NOT NULL,
                      `sparkline_data` TEXT
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_pit` (
                      `pit_name` TEXT PRIMARY KEY,
                      `target` REAL NOT NULL,
                      `actual` REAL NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_monthly_trends` (
                      `month_name` TEXT PRIMARY KEY,
                      `target` REAL NOT NULL,
                      `actual` REAL NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_vessels` (
                      `id` TEXT PRIMARY KEY,
                      `vessel_name` TEXT NOT NULL,
                      `destination` TEXT NOT NULL,
                      `cargo` REAL NOT NULL,
                      `status` TEXT NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_stockpiles` (
                      `location` TEXT PRIMARY KEY,
                      `volume` REAL NOT NULL,
                      `grade_ni` REAL NOT NULL,
                      `status` TEXT NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_pica` (
                      `id` TEXT PRIMARY KEY,
                      `title` TEXT NOT NULL,
                      `category` TEXT NOT NULL,
                      `owner` TEXT NOT NULL,
                      `due_date` TEXT NOT NULL,
                      `status` TEXT NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_root_causes` (
                      `cause_name` TEXT PRIMARY KEY,
                      `percentage` REAL NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_scorecards` (
                      `department_name` TEXT PRIMARY KEY,
                      `score` REAL NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS `t_perf_alerts` (
                      `id` TEXT PRIMARY KEY,
                      `alert_type` TEXT NOT NULL,
                      `message` TEXT NOT NULL,
                      `timestamp` TEXT NOT NULL
                    );
                    
                    INSERT OR IGNORE INTO `t_perf_kpis` (`metric_key`, `metric_label`, `value_actual`, `value_target`, `unit`, `sparkline_data`) VALUES
                    ('ore_production', 'Ore Production', 1250000.0, 1100000.0, 'WMT', '50,55,60,63,68,75,70,82,88,95,90,113.6'),
                    ('ore_shipment', 'Ore Shipment', 950000.0, 900000.0, 'WMT', '45,48,50,52,55,58,62,60,68,72,80,105.6'),
                    ('rkab_utilization', 'RKAB Utilization', 4050000.0, 5000000.0, 'WMT', NULL),
                    ('ebitda_estimate', 'EBITDA Estimate', 16.1, 14.5, 'USD M', '8,9,11,10,12,13,12,14,15,16,15.5,111.0'),
                    ('avg_ni_grade', 'Avg Ni Grade', 1.82, 1.75, '%', '1.72,1.74,1.75,1.73,1.76,1.78,1.79,1.81,1.80,1.83,1.82,104.0'),
                    ('stripping_ratio', 'Stripping Ratio', 1.85, 2.00, '', '2.1,2.05,2.0,1.98,1.95,1.92,1.9,1.88,1.87,1.86,1.85,92.5');

                    INSERT OR IGNORE INTO `t_perf_pit` (`pit_name`, `target`, `actual`) VALUES
                    ('Pit A', 350000.0, 380000.0),
                    ('Pit B', 280000.0, 265000.0),
                    ('Pit C', 420000.0, 470000.0),
                    ('Pit D', 50000.0, 60000.0);

                    INSERT OR IGNORE INTO `t_perf_monthly_trends` (`month_name`, `target`, `actual`) VALUES
                    ('Jan', 550000.0, 600000.0),
                    ('Feb', 680000.0, 750000.0),
                    ('Mar', 800000.0, 980000.0),
                    ('Apr', 900000.0, 1050000.0),
                    ('May', 950000.0, 1100000.0),
                    ('Jun', 1100000.0, 1250000.0);

                    INSERT OR IGNORE INTO `t_perf_vessels` (`id`, `vessel_name`, `destination`, `cargo`, `status`) VALUES
                    ('VES-1', 'MV Ocean Star', 'China', 55000.0, 'Completed'),
                    ('VES-2', 'MV Pacific Glory', 'China', 52000.0, 'Loading'),
                    ('VES-3', 'MV Eastern Crown', 'Korea', 58000.0, 'Waiting'),
                    ('VES-4', 'MV Golden Sea', 'China', 54000.0, 'Sailing');

                    INSERT OR IGNORE INTO `t_perf_stockpiles` (`location`, `volume`, `grade_ni`, `status`) VALUES
                    ('ROM A', 250000.0, 1.80, 'Ready'),
                    ('ROM B', 180000.0, 1.65, 'Ready'),
                    ('Port Stockpile', 120000.0, 1.85, 'Loading'),
                    ('Emergency Stockpile', 50000.0, 1.75, 'Reserve');

                    INSERT OR IGNORE INTO `t_perf_pica` (`id`, `title`, `category`, `owner`, `due_date`, `status`) VALUES
                    ('PICA-1', 'Low Production Pit B', 'Production', 'Production Dept.', '30 Jun 2026', 'Overdue'),
                    ('PICA-2', 'Excavator Breakdown EX210', 'Equipment', 'Engineering', '28 Jun 2026', 'In Progress'),
                    ('PICA-3', 'Vessel Delay MV Ocean Star', 'Shipment', 'Port Operation', '25 Jun 2026', 'Open'),
                    ('PICA-4', 'Grade Deviation ROM A', 'Quality', 'QAQC Dept.', '27 Jun 2026', 'In Progress');

                    INSERT OR IGNORE INTO `t_perf_root_causes` (`cause_name`, `percentage`) VALUES
                    ('Equipment Breakdown', 35.0),
                    ('Weather', 25.0),
                    ('Manpower', 15.0),
                    ('Road Condition', 12.0),
                    ('Logistic', 8.0),
                    ('Others', 5.0);

                    INSERT OR IGNORE INTO `t_perf_scorecards` (`department_name`, `score`) VALUES
                    ('Production', 95.0),
                    ('Engineering', 88.0),
                    ('SHE', 92.0),
                    ('QAQC', 94.0),
                    ('HRGA', 89.0),
                    ('Security', 91.0);

                    INSERT OR IGNORE INTO `t_perf_alerts` (`id`, `alert_type`, `message`, `timestamp`) VALUES
                    ('ALT-1', 'danger', 'RKAB tersisa 19% atau 950,000 WMT', '10:30'),
                    ('ALT-2', 'danger', '4 PICA Overdue perlu segera ditindaklanjuti', '09:15'),
                    ('ALT-3', 'warning', 'Excavator EX210 Breakdown', '08:45'),
                    ('ALT-4', 'warning', 'Shipment MV Ocean Star Delay 8 Jam', '08:30'),
                    ('ALT-5', 'success', 'Average Grade Ni diatas target RKAB', '07:45');
                ");
            }
        } catch (Exception $mig_err) {
            // Ignore
        }
        
        // Self-healing migration for Fuel Assets
        try {
            $fuel_assets_exists = $db->query("SELECT count(*) FROM sqlite_master WHERE type='table' AND name='m_fuel_assets'")->fetchColumn();
            if (!$fuel_assets_exists) {
                $db->exec("
                    CREATE TABLE IF NOT EXISTS `m_fuel_assets` (
                      `id` TEXT PRIMARY KEY,
                      `asset_name` TEXT NOT NULL,
                      `type` TEXT NOT NULL,
                      `location` TEXT NOT NULL,
                      `install_fuel_level` REAL NOT NULL,
                      `current_fuel_level` REAL NOT NULL,
                      `fuel_capacity` REAL NOT NULL,
                      `remaining_fuel` REAL NOT NULL,
                      `fuel_usage_rate` REAL NOT NULL,
                      `efficiency` REAL NOT NULL,
                      `next_refuel_estimate` TEXT NOT NULL,
                      `status` TEXT NOT NULL
                    );

                    INSERT OR IGNORE INTO `m_fuel_assets` (`id`, `asset_name`, `type`, `location`, `install_fuel_level`, `current_fuel_level`, `fuel_capacity`, `remaining_fuel`, `fuel_usage_rate`, `efficiency`, `next_refuel_estimate`, `status`) VALUES
                    ('LV-01', 'Pickup', 'LV', 'Pit A', 90.0, 69.0, 45.0, 12.0, 1.8, 0.9, 'Refuel in ~12 Hrs', 'Active'),
                    ('LV-02', 'Pickup', 'LV', 'Pit A', 90.0, 60.0, 45.0, 12.0, 1.9, 1.0, 'Refuel in ~12 Hrs', 'Active'),
                    ('LV-03', 'Pickup', 'LV', 'Pit A', 90.0, 61.0, 45.0, 12.0, 1.6, 0.8, 'Refuel in ~12 Hrs', 'Active'),
                    ('GEN-C4', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 18.0, 2.5, 'Refuel in ~3.5 Days', 'Active'),
                    ('GEN-C5', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 16.8, 2.3, 'Refuel in ~3.5 Days', 'Active'),
                    ('GEN-C6', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 18.1, 2.5, 'Refuel in ~3.5 Days', 'Active'),
                    ('GEN-C7', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 16.7, 2.2, 'Refuel in ~3.5 Days', 'Low Fuel'),
                    ('GEN-C8', '500KVA', 'GEN', 'Site B', 85.0, 22.0, 95.0, 21.0, 18.5, 2.6, 'Refuel in ~1.2 Days', 'Critical');
                ");
            }
        } catch (Exception $fuel_mig_err) {
            // Ignore
        }
    }
} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Gagal koneksi atau inisialisasi SQLite database: ' . $e->getMessage() . 
                   '. Pastikan pdo_sqlite aktif di PHP cPanel Anda dan folder memiliki izin menulis (write permission).'
    ]);
    exit;
}

function compressData($data) {
    if (empty($data)) return $data;
    if (strpos($data, 'gz:') === 0) return $data;
    if (strlen($data) > 100 && function_exists('gzcompress')) {
        $compressed = @gzcompress($data, 9);
        if ($compressed !== false) {
            return 'gz:' . base64_encode($compressed);
        }
    }
    return $data;
}

function decompressRow($row) {
    if (is_array($row)) {
        foreach ($row as $key => $val) {
            $row[$key] = decompressRow($val);
        }
    } else if (is_string($row)) {
        if (strpos($row, 'gz:') === 0) {
            if (function_exists('gzdecompress')) {
                $encoded = substr($row, 3);
                $compressed = base64_decode($encoded);
                if ($compressed !== false) {
                    $decompressed = @gzdecompress($compressed);
                    if ($decompressed !== false) {
                        return $decompressed;
                    }
                }
            } else {
                return "[Error: zlib PHP extension is disabled/missing on this server, cannot decompress this field]";
            }
        }
    }
    return $row;
}

try {
    $result = executeAction($action, $args, $db);
    $result = decompressRow($result);
    echo json_encode([
        'success' => true,
        'data' => $result
    ]);
} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'error' => 'API Execution Error: ' . $e->getMessage() . ' in ' . $e->getFile() . ' on line ' . $e->getLine()
    ]);
}

/**
 * Main Action Router
 */
function executeAction($action, $args, $db) {
    switch ($action) {
        case 'loginUser':
            return loginUser($args[0], $args[1], $db);
            
        case 'getDropdownData':
            return getDropdownData($db);
            
        case 'getDashboardData':
            return getDashboardData($db);
            
        case 'getApprovalRequests':
            return getApprovalRequests($args[0], $db);
            
        case 'getRequestDetails':
            return getRequestDetails($args[0], $db);
            
        case 'submitRequest':
            return submitRequest($args[0], $args[1], $db);
            
        case 'processApproval':
            return processApproval($args[0], $args[1], $args[2], $args[3], $args[4], $db);
            
        case 'sendFullApprovalEmailWithPDF':
            return sendFullApprovalEmailWithPDF($args[0], $args[1], $db);
            
        case 'getDocumentHistory':
            return getDocumentHistory($db);
            
        case 'saveUserSignature':
            return saveUserSignature($args[0], $args[1], $db);
            
        case 'createUserRecord':
            return createUserRecord($args[0], $db);
            
        case 'editUserRecord':
            return editUserRecord($args[0], $args[1], $db);
            
        case 'deleteUserRecord':
            return deleteUserRecord($args[0], $db);
            
        case 'saveBudgetLive':
            return saveBudgetLive($args[0], $args[1], $args[2], $args[3], $args[4], $args[5], $db);
            
        case 'deleteBudgetLive':
            return deleteBudgetLive($args[0], $db);
            
        case 'importBudgetLiveCSV':
            return importBudgetLiveCSV($args[0], $db);
            
        case 'createMasterRecord':
            return createMasterRecord($args[0], $args[1], $args[2], $db);
            
        case 'updateMasterRecord':
            return updateMasterRecord($args[0], $args[1], $args[2], $db);
            
        case 'deleteMasterRecord':
            return deleteMasterRecord($args[0], $args[1], $db);
            
        case 'deleteRequestRecord':
            return deleteRequestRecord($args[0], $db);
            
        case 'getPerformanceData':
            return getPerformanceData($db);
            
        case 'savePerformanceKPIs':
            return savePerformanceKPIs($args[0], $db);
            
        case 'savePitPerformance':
            return savePitPerformance($args[0], $db);
            
        case 'saveStockpiles':
            return saveStockpiles($args[0], $db);
            
        case 'saveVessels':
            return saveVessels($args[0], $db);
            
        case 'savePICA':
            return savePICA($args[0], $db);
            
        case 'saveRootCauses':
            return saveRootCauses($args[0], $db);
            
        case 'saveScorecards':
            return saveScorecards($args[0], $db);
            
        case 'saveAlerts':
            return saveAlerts($args[0], $db);
            
        case 'getFuelData':
            return getFuelData($db);
            
        case 'saveFuelStockIn':
            return saveFuelStockIn($args[0], $db);
            
        case 'saveFuelStockOut':
            return saveFuelStockOut($args[0], $db);
            
        default:
            throw new Exception("Action '$action' is not supported.");
    }
}

/**
 * 1. loginUser
 */
function loginUser($username, $password, $db) {
    $inputUserNorm = strtolower(trim(str_replace(' ', '.', $username)));
    
    $stmt = $db->prepare("SELECT * FROM m_users");
    $stmt->execute();
    $users = $stmt->fetchAll();
    
    $foundUser = null;
    foreach ($users as $u) {
        $dbUserNorm = strtolower(trim(str_replace(' ', '.', $u['username'])));
        if ($dbUserNorm === $inputUserNorm) {
            if ($u['password'] === $password) {
                $foundUser = [
                    'id' => $u['id'],
                    'username' => $u['username'],
                    'fullname' => $u['fullname'],
                    'role' => $u['role'],
                    'dept' => $u['department'],
                    'signature' => $u['signature'],
                    'status' => $u['status']
                ];
                break;
            }
        }
    }
    
    if ($foundUser) {
        if ($foundUser['status'] === 'Inactive') {
            return ['success' => false, 'error' => 'Akun Anda dinonaktifkan.'];
        }
        return ['success' => true, 'user' => $foundUser];
    } else {
        return ['success' => false, 'error' => 'Username atau password salah!'];
    }
}

/**
 * 2. getDropdownData
 */
function getDropdownData($db) {
    // Get Departments
    $stmt = $db->query("SELECT code AS Code, name AS Name FROM m_departments ORDER BY code ASC");
    $departments = $stmt->fetchAll();
    
    // Get Projects
    $stmt = $db->query("SELECT code AS Code, name AS Name FROM m_projects ORDER BY code ASC");
    $projects = $stmt->fetchAll();
    
    // Get COAs
    $stmt = $db->query("SELECT code AS Code, name AS Name FROM m_coas ORDER BY code ASC");
    $coas = $stmt->fetchAll();
    
    // Get Users (needed for matrix manager lookup)
    $stmt = $db->query("SELECT id AS ID, username AS Username, fullname AS Fullname, role AS Role, department AS Department, password AS Password, status AS Status, email AS Email FROM m_users ORDER BY username ASC");
    $users = $stmt->fetchAll();
    
    // Get Matrix
    $stmt = $db->query("SELECT id AS ID, doc_type AS DocType, department AS Department, min_amount AS MinAmount, max_amount AS MaxAmount, steps AS Steps FROM t_approval_matrix ORDER BY id ASC");
    $matrix = $stmt->fetchAll();
    
    return [
        'departments' => $departments,
        'projects' => $projects,
        'coas' => $coas,
        'users' => $users,
        'matrix' => $matrix
    ];
}

/**
 * 3. getDashboardData
 */
function getDashboardData($db) {
    // Get Requests mapped to expectations
    $stmt = $db->query("SELECT id AS ID, type AS Type, doc_number AS DocNumber, date AS Date, department AS Department, priority AS Priority, subject AS Subject, requester AS Requester, total_nominal AS TotalNominal, status AS Status, current_approver_role AS CurrentApproverRole, signatures AS Signatures, user_for AS UserFor FROM t_requests ORDER BY rowid DESC");
    $requests = $stmt->fetchAll();
    
    // Get Budgets
    $stmt = $db->query("SELECT id AS id, department AS dept, project AS project, year AS year, annual_budget AS annual, actual_budget AS actual, (annual_budget - actual_budget) AS remaining FROM t_budget ORDER BY department ASC");
    $budget = $stmt->fetchAll();
    
    // Get Logs
    $stmt = $db->query("SELECT id AS id, timestamp AS timestamp, user AS user, activity AS action, module AS module, doc_number AS document, ip_address AS ip FROM t_audit_log ORDER BY timestamp DESC LIMIT 50");
    $logs = $stmt->fetchAll();
    
    // Get Fuel Assets
    $stmt = $db->query("SELECT id AS id, asset_name AS asset_name, type AS type, location AS location, install_fuel_level AS install_fuel_level, current_fuel_level AS current_fuel_level, fuel_capacity AS fuel_capacity, remaining_fuel AS remaining_fuel, fuel_usage_rate AS fuel_usage_rate, efficiency AS efficiency, next_refuel_estimate AS next_refuel_estimate, status AS status FROM m_fuel_assets ORDER BY id ASC");
    $fuel_assets = $stmt->fetchAll();
    
    return [
        'requests' => $requests,
        'budget' => $budget,
        'logs' => $logs,
        'fuel_assets' => $fuel_assets
    ];
}

/**
 * 4. getApprovalRequests
 */
function getApprovalRequests($role, $db) {
    // Check if PM is on leave (Cuti)
    $stmt = $db->prepare("SELECT status FROM m_users WHERE role = 'Project Manager' LIMIT 1");
    $stmt->execute();
    $pm = $stmt->fetch();
    $isPmLeave = ($pm && $pm['status'] === 'Cuti');

    // Fetch pending requests
    $stmt = $db->prepare("SELECT * FROM t_requests WHERE status = 'Pending' ORDER BY rowid DESC");
    $stmt->execute();
    $requests = $stmt->fetchAll();
    
    $filtered = [];
    foreach ($requests as $req) {
        $matches = false;
        if ($req['current_approver_role'] === $role) {
            $matches = true;
        } elseif ($role === 'KTT' && $isPmLeave && $req['current_approver_role'] === 'Project Manager') {
            // Backup KTT role when PM is on leave
            $matches = true;
        }
        
        if ($matches) {
            $filtered[] = [
                'id' => $req['id'],
                'type' => $req['type'],
                'docNumber' => $req['doc_number'],
                'date' => $req['date'],
                'department' => $req['department'],
                'priority' => $req['priority'],
                'subject' => $req['subject'],
                'requester' => $req['requester'],
                'nominal' => (float)$req['total_nominal'],
                'signatures' => json_decode($req['signatures'], true),
                'userFor' => $req['user_for']
            ];
        }
    }
    return $filtered;
}

/**
 * 5. getRequestDetails
 */
function getRequestDetails($requestId, $db) {
    // 1. Fetch Request Metadata
    $stmt = $db->prepare("SELECT * FROM t_requests WHERE id = ?");
    $stmt->execute([$requestId]);
    $req = $stmt->fetch();
    if (!$req) return null;
    
    // 2. Fetch Line Items
    $stmt = $db->prepare("SELECT coa AS COA, part_number AS PartNumber, description AS Description, cost_element AS CostElement, quantity AS Quantity, uom AS UoM, price AS Price, total AS Total FROM t_request_items WHERE request_id = ? ORDER BY id ASC");
    $stmt->execute([$requestId]);
    $items = $stmt->fetchAll();
    
    // 3. Fetch Department Budget
    $stmt = $db->prepare("SELECT id AS id, department AS dept, project AS project, year AS year, annual_budget AS annual, actual_budget AS actual, (annual_budget - actual_budget) AS remaining FROM t_budget WHERE department = ? LIMIT 1");
    $stmt->execute([$req['department']]);
    $budget = $stmt->fetch() ?: null;
    
    $sigs = json_decode($req['signatures'], true) ?: [];
    
    return [
        'metadata' => [
            'id' => $req['id'],
            'type' => $req['type'],
            'docNumber' => $req['doc_number'],
            'date' => $req['date'],
            'department' => $req['department'],
            'priority' => $req['priority'],
            'inventoryType' => $req['inventory_type'],
            'purchaseCategory' => $req['purchase_category'],
            'subject' => $req['subject'],
            'requester' => $req['requester'],
            'nominal' => (float)$req['total_nominal'],
            'status' => $req['status'],
            'current_approver_role' => $req['current_approver_role'],
            'currentApproverRole' => $req['current_approver_role'],
            'signatures' => $sigs,
            'userFor' => $req['user_for'],
            'attachment' => $req['attachment'],
            'attachmentName' => $req['attachment_name'],
            'budgetCapture' => $req['budget_capture']
        ],
        'items' => $items,
        'budget' => $budget,
        'signatures' => $sigs
    ];
}

/**
 * 6. submitRequest
 */
function submitRequest($metadata, $items, $db) {
    // Calculate workflow approval steps
    $stmt = $db->prepare("SELECT * FROM t_approval_matrix WHERE doc_type = ? ORDER BY id ASC");
    $stmt->execute([$metadata['type']]);
    $matrices = $stmt->fetchAll();
    
    $matchedSteps = [];
    foreach ($matrices as $m) {
        $deptMatch = ($m['department'] === 'ALL' || $m['department'] === $metadata['department']);
        $amountMatch = ($metadata['totalNominal'] >= $m['min_amount'] && $metadata['totalNominal'] <= $m['max_amount']);
        if ($deptMatch && $amountMatch) {
            $matchedSteps = array_map('trim', explode(',', $m['steps']));
            break;
        }
    }
    
    if (empty($matchedSteps)) {
        $matchedSteps = ($metadata['type'] === 'PD') ? ['Project Manager', 'Finance'] : ['Supervisor', 'Finance', 'Project Manager'];
    }
    $firstApprover = $matchedSteps[0];
    
    // Fetch requester signature image
    $stmtRequester = $db->prepare("SELECT signature FROM m_users WHERE fullname = ? OR username = ? LIMIT 1");
    $stmtRequester->execute([$metadata['requester'], $metadata['requester']]);
    $requesterObj = $stmtRequester->fetch();
    $requesterSig = ($requesterObj && $requesterObj['signature']) ? $requesterObj['signature'] : "[e-Signed: " . $metadata['requester'] . "]";

    // Initialize Signatures Array template
    $signatures = [];
    $signatures['user'] = [
        'name' => $metadata['requester'],
        'role' => 'User',
        'date' => date('c'),
        'status' => 'SUBMITTED',
        'signatureText' => $requesterSig
    ];

    if ($metadata['type'] === 'PD') {
        $signatures['deptHeadPm'] = ['name' => '', 'role' => 'Supervisor / Head Department', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['projectManager'] = ['name' => ($metadata['customPm'] ?: 'Yohanes Sam'), 'role' => 'Project Manager / Operation Manager', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['financeSite'] = ['name' => '', 'role' => 'Finance Site', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['costControl'] = ['name' => '', 'role' => 'Cost Control', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['gmDept'] = ['name' => '', 'role' => 'GM / CFO', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
    } else {
        $signatures['supervisor'] = ['name' => '', 'role' => 'Supervisor / Head Department', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['finance'] = ['name' => '', 'role' => 'Finance', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['projectManager'] = ['name' => '', 'role' => 'Project Manager', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['costControl'] = ['name' => '', 'role' => 'Cost Control', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
        $signatures['gmCfo'] = ['name' => '', 'role' => 'GM / CFO', 'date' => '', 'status' => 'PENDING', 'signatureText' => ''];
    }
    
    // Generate Document Number and Running ID
    $db->beginTransaction();
    
    $stmt = $db->prepare("SELECT COUNT(*) FROM t_requests WHERE type = ?");
    $stmt->execute([$metadata['type']]);
    $count = $stmt->fetchColumn() + 1;
    
    $newId = 'REQ-' . round(microtime(true) * 1000);
    $year = date('Y');
    $month = date('m');
    $docNumber = sprintf("%03d/%s/%s/%s/%s", $count, $metadata['type'], $metadata['department'], $month, $year);
    
    // Insert request
    $stmt = $db->prepare("INSERT INTO t_requests (id, type, doc_number, date, department, priority, inventory_type, purchase_category, subject, requester, total_nominal, status, current_approver_role, signatures, user_for, attachment, attachment_name, budget_capture) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([
        $newId,
        $metadata['type'],
        $docNumber,
        date('Y-m-d'),
        $metadata['department'],
        $metadata['priority'],
        $metadata['inventoryType'] ?: null,
        $metadata['purchaseCategory'] ?: null,
        $metadata['subject'],
        $metadata['requester'],
        $metadata['totalNominal'],
        'Pending',
        $firstApprover,
        compressData(json_encode($signatures)),
        $metadata['userFor'] ?: '',
        compressData($metadata['attachment'] ?: ''),
        $metadata['attachmentName'] ?: '',
        compressData($metadata['budgetCapture'] ?: '')
    ]);
    
    // Insert line items
    $stmtItem = $db->prepare("INSERT INTO t_request_items (id, request_id, coa, part_number, description, cost_element, quantity, uom, price, total) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $itemIdx = 1;
    foreach ($items as $it) {
        $itemId = 'ITEM-' . round(microtime(true) * 1000) . '-' . $itemIdx++;
        $stmtItem->execute([
            $itemId,
            $newId,
            $it['COA'] ?: null,
            $it['PartNumber'] ?: null,
            $it['Description'],
            $it['CostElement'] ?: null,
            (int)$it['Quantity'],
            $it['UoM'],
            $it['Price'],
            $it['Total']
        ]);
    }
    
    // Audit log
    $logId = 'LOG-' . round(microtime(true) * 1000);
    $stmtLog = $db->prepare("INSERT INTO t_audit_log (id, user, activity, module, doc_number, ip_address) VALUES (?, ?, ?, ?, ?, ?)");
    $stmtLog->execute([
        $logId,
        $metadata['requester'],
        "Create " . $metadata['type'],
        "Requests",
        $docNumber,
        $_SERVER['REMOTE_ADDR']
    ]);
    
    $db->commit();
    return ['success' => true, 'docNumber' => $docNumber];
}

/**
 * 7. processApproval
 */
function processApproval($requestId, $actionType, $role, $comment, $userName, $db) {
    $db->beginTransaction();
    
    // Fetch request
    $stmt = $db->prepare("SELECT * FROM t_requests WHERE id = ?");
    $stmt->execute([$requestId]);
    $request = $stmt->fetch();
    if (!$request) throw new Exception("Document not found");
    
    // Check PM status
    $stmt = $db->prepare("SELECT status FROM m_users WHERE role = 'Project Manager' LIMIT 1");
    $stmt->execute();
    $pm = $stmt->fetch();
    $isPmLeave = ($pm && $pm['status'] === 'Cuti');
    
    $finalRole = $role;
    if ($role === 'KTT' && $isPmLeave && $request['current_approver_role'] === 'Project Manager') {
        $finalRole = 'Project Manager';
    }
    
    $signatures = json_decode($request['signatures'], true) ?: [];
    
    // Get matrix workflow steps
    $stmt = $db->prepare("SELECT * FROM t_approval_matrix WHERE doc_type = ? ORDER BY id ASC");
    $stmt->execute([$request['type']]);
    $matrices = $stmt->fetchAll();
    
    $approvalSteps = [];
    foreach ($matrices as $m) {
        $deptMatch = ($m['department'] === 'ALL' || $m['department'] === $request['department']);
        $amountMatch = ($request['total_nominal'] >= $m['min_amount'] && $request['total_nominal'] <= $m['max_amount']);
        if ($deptMatch && $amountMatch) {
            $approvalSteps = array_map('trim', explode(',', $m['steps']));
            break;
        }
    }
    if (empty($approvalSteps)) {
        $approvalSteps = ($request['type'] === 'PD') ? ['Project Manager', 'Finance'] : ['Supervisor', 'Finance', 'Project Manager'];
    }
    
    // Map Approver Role to Database Signature Key Slot
    function getSigKey($roleVal) {
        $mapping = [
            'Supervisor' => 'supervisor',
            'Head Department' => 'supervisor',
            'Finance' => 'finance',
            'Finance Site' => 'finance',
            'Project Manager' => 'projectManager',
            'Cost Control' => 'costControl',
            'GM/CFO' => 'gmCfo'
        ];
        return isset($mapping[$roleVal]) ? $mapping[$roleVal] : preg_replace('/[^a-z]/', '', strtolower($roleVal));
    }
    
    $key = getSigKey($finalRole);
    if ($request['type'] === 'PD') {
        if ($finalRole === 'Project Manager' && isset($signatures['deptHeadPm'])) {
            $key = 'deptHeadPm';
        } elseif ($finalRole === 'Finance' && isset($signatures['financeSite'])) {
            $key = 'financeSite';
        }
    }
    
    if (!$key) throw new Exception('Invalid Approver Role');
    
    if ($actionType === 'APPROVE') {
        // Get user signature
        $stmt = $db->prepare("SELECT signature FROM m_users WHERE fullname = ? OR username = ? LIMIT 1");
        $stmt->execute([$userName, $userName]);
        $userObj = $stmt->fetch();
        $userSig = ($userObj && $userObj['signature']) ? $userObj['signature'] : "[e-Signed: $userName | " . date('Y-m-d') . "]";
        
        $signatures[$key] = [
            'name' => $userName,
            'role' => $finalRole,
            'date' => date('c'),
            'status' => 'APPROVED',
            'signatureText' => $userSig
        ];
        
        $findStepIndex = function($roleVal, $steps) {
            $cleanRole = strtolower(preg_replace('/[^a-z0-9]/', '', $roleVal));
            foreach ($steps as $idx => $step) {
                $cleanStep = strtolower(preg_replace('/[^a-z0-9]/', '', $step));
                if ($cleanRole === $cleanStep) return $idx;
                
                // Supervisor / Head Department mapping
                if (($cleanRole === 'supervisor' || $cleanRole === 'headdepartment') && 
                    ($cleanStep === 'supervisor' || $cleanStep === 'headdepartment')) {
                    return $idx;
                }
                
                // Finance / Finance Site mapping
                if (($cleanRole === 'finance' || $cleanRole === 'financesite') && 
                    ($cleanStep === 'finance' || $cleanStep === 'financesite')) {
                    return $idx;
                }
            }
            return false;
        };
        
        $currentStepIndex = $findStepIndex($finalRole, $approvalSteps);
        $nextApprover = '';
        $nextStatus = 'Pending';
        
        if ($currentStepIndex !== false && $currentStepIndex < count($approvalSteps) - 1) {
            $nextApprover = $approvalSteps[$currentStepIndex + 1];
        } else {
            $nextStatus = 'Approved';
            $nextApprover = 'None';
        }
        
        // Update request status
        $stmtUpdate = $db->prepare("UPDATE t_requests SET status = ?, current_approver_role = ?, signatures = ? WHERE id = ?");
        $stmtUpdate->execute([$nextStatus, $nextApprover, compressData(json_encode($signatures)), $requestId]);
        
        // If final approved, update the annual budget utilization
        if ($nextStatus === 'Approved') {
            $stmtBud = $db->prepare("UPDATE t_budget SET actual_budget = actual_budget + ? WHERE department = ?");
            $stmtBud->execute([$request['total_nominal'], $request['department']]);
        }
        
        // Write audit log
        $logId = 'LOG-' . round(microtime(true) * 1000);
        $stmtLog = $db->prepare("INSERT INTO t_audit_log (id, user, activity, module, doc_number, ip_address) VALUES (?, ?, ?, ?, ?, ?)");
        $stmtLog->execute([
            $logId,
            $userName,
            "Approved at " . $finalRole,
            "Approval",
            $request['doc_number'],
            $_SERVER['REMOTE_ADDR']
        ]);
        
        $db->commit();
        
        // The frontend will capture the signed PDF and trigger the complete email via sendFullApprovalEmailWithPDF.
        return ['success' => true, 'status' => $nextStatus];
        
    } elseif ($actionType === 'REJECT') {
        $signatures[$key] = [
            'name' => $userName,
            'role' => $finalRole,
            'date' => date('c'),
            'status' => 'REJECTED',
            'signatureText' => "REJECTED"
        ];
        
        // Update request status to Rejected
        $stmtUpdate = $db->prepare("UPDATE t_requests SET status = 'Rejected', current_approver_role = 'None', signatures = ? WHERE id = ?");
        $stmtUpdate->execute([compressData(json_encode($signatures)), $requestId]);
        
        // Write audit log
        $logId = 'LOG-' . round(microtime(true) * 1000);
        $stmtLog = $db->prepare("INSERT INTO t_audit_log (id, user, activity, module, doc_number, ip_address) VALUES (?, ?, ?, ?, ?, ?)");
        $stmtLog->execute([
            $logId,
            $userName,
            "Rejected at $finalRole - $comment",
            "Approval",
            $request['doc_number'],
            $_SERVER['REMOTE_ADDR']
        ]);
        
        $db->commit();
        return ['success' => true, 'status' => 'Rejected'];
    }
}

/**
 * 8. getDocumentHistory
 */
function getDocumentHistory($db) {
    $stmt = $db->query("SELECT id AS id, type AS type, doc_number AS docNumber, date AS date, department AS department, priority AS priority, subject AS subject, requester AS requester, total_nominal AS nominal, signatures AS signatures, user_for AS userFor, status AS status, current_approver_role AS currentApprover FROM t_requests ORDER BY rowid DESC");
    $requests = $stmt->fetchAll();
    
    $formatted = [];
    foreach ($requests as $r) {
        $formatted[] = [
            'id' => $r['id'],
            'type' => $r['type'],
            'docNumber' => $r['docNumber'],
            'date' => $r['date'],
            'department' => $r['department'],
            'priority' => $r['priority'],
            'subject' => $r['subject'],
            'requester' => $r['requester'],
            'nominal' => (float)$r['nominal'],
            'signatures' => json_decode($r['signatures'], true) ?: [],
            'userFor' => $r['userFor'],
            'status' => $r['status'],
            'currentApprover' => $r['currentApprover']
        ];
    }
    return $formatted;
}

/**
 * 9. saveUserSignature
 */
function saveUserSignature($username, $sigDataUrl, $db) {
    $stmt = $db->prepare("UPDATE m_users SET signature = ? WHERE username = ?");
    $stmt->execute([compressData($sigDataUrl), $username]);
    return ['success' => true];
}

/**
 * 10. createUserRecord
 */
function createUserRecord($payload, $db) {
    $stmt = $db->query("SELECT COUNT(*) FROM m_users");
    $count = $stmt->fetchColumn() + 1;
    $newId = 'USR-' . $count;
    
    // Prevent ID duplicates
    $stmtCheck = $db->prepare("SELECT id FROM m_users WHERE id = ?");
    $stmtCheck->execute([$newId]);
    while ($stmtCheck->fetch()) {
        $count++;
        $newId = 'USR-' . $count;
        $stmtCheck->execute([$newId]);
    }
    
    $stmt = $db->prepare("INSERT INTO m_users (id, username, fullname, role, department, password, signature, status, email) VALUES (?, ?, ?, ?, ?, ?, '', ?, ?)");
    $stmt->execute([
        $newId,
        $payload['Username'],
        $payload['Fullname'],
        $payload['Role'],
        $payload['Department'],
        $payload['Password'],
        $payload['Status'] ?: 'Active',
        isset($payload['Email']) ? $payload['Email'] : null
    ]);
    
    return ['success' => true, 'record' => [
        'ID' => $newId,
        'Username' => $payload['Username'],
        'Fullname' => $payload['Fullname'],
        'Role' => $payload['Role'],
        'Department' => $payload['Department'],
        'Status' => $payload['Status'] ?: 'Active',
        'Email' => isset($payload['Email']) ? $payload['Email'] : null
    ]];
}

/**
 * 11. editUserRecord
 */
function editUserRecord($id, $payload, $db) {
    $stmt = $db->prepare("UPDATE m_users SET fullname = ?, username = ?, password = ?, role = ?, department = ?, status = ?, email = ? WHERE id = ?");
    $stmt->execute([
        $payload['Fullname'],
        $payload['Username'],
        $payload['Password'],
        $payload['Role'],
        $payload['Department'],
        $payload['Status'],
        isset($payload['Email']) ? $payload['Email'] : null,
        $id
    ]);
    return ['success' => true];
}

/**
 * 12. deleteUserRecord
 */
function deleteUserRecord($id, $db) {
    $stmt = $db->prepare("DELETE FROM m_users WHERE id = ?");
    $stmt->execute([$id]);
    return ['success' => true];
}

/**
 * 13. saveBudgetLive
 */
function saveBudgetLive($id, $annual, $actual, $remaining, $year, $dept, $db) {
    $stmt = $db->prepare("SELECT id FROM t_budget WHERE id = ?");
    $stmt->execute([$id]);
    $exists = $stmt->fetch();
    if ($exists) {
        $stmt = $db->prepare("UPDATE t_budget SET annual_budget = ?, actual_budget = ?, year = ? WHERE id = ?");
        $stmt->execute([$annual, $actual, $year, $id]);
    } else {
        $stmt = $db->prepare("INSERT INTO t_budget (id, department, project, year, annual_budget, actual_budget) VALUES (?, ?, 'PROJ-CRM', ?, ?, ?)");
        $stmt->execute([$id, $dept, $year, $annual, $actual]);
    }
    return ['success' => true];
}

/**
 * 14. deleteBudgetLive
 */
function deleteBudgetLive($id, $db) {
    $stmt = $db->prepare("DELETE FROM t_budget WHERE id = ?");
    $stmt->execute([$id]);
    return ['success' => true];
}

/**
 * 15. importBudgetLiveCSV
 */
function importBudgetLiveCSV($csvText, $db) {
    $lines = explode("\n", $csvText);
    $count = 0;
    
    $db->beginTransaction();
    for ($i = 1; $i < count($lines); $i++) {
        $line = trim($lines[$i]);
        if (empty($line)) continue;
        
        $parts = str_getcsv($line);
        if (count($parts) >= 2) {
            $dept = trim($parts[0]);
            $annual = (float)$parts[1];
            
            // Check if department exists in budget
            $stmt = $db->prepare("SELECT id FROM t_budget WHERE LOWER(department) = ? LIMIT 1");
            $stmt->execute([strtolower($dept)]);
            $row = $stmt->fetch();
            
            if ($row) {
                $stmtUp = $db->prepare("UPDATE t_budget SET annual_budget = ? WHERE id = ?");
                $stmtUp->execute([$annual, $row['id']]);
                $count++;
            } else {
                $newId = 'B-' . round(microtime(true) * 1000) . '-' . $count;
                $stmtIns = $db->prepare("INSERT INTO t_budget (id, department, project, year, annual_budget, actual_budget) VALUES (?, ?, 'PROJ-CRM', ?, ?, 0.00)");
                $stmtIns->execute([$newId, $dept, (int)date('Y'), $annual]);
                $count++;
            }
        }
    }
    $db->commit();
    return "Imported/Updated $count budget records successfully.";
}

/**
 * Generic CRUD
 */
function createMasterRecord($tableName, $prefix, $payload, $db) {
    if ($tableName === 't_approval_matrix') {
        $stmt = $db->query("SELECT COUNT(*) FROM t_approval_matrix");
        $count = $stmt->fetchColumn() + 1;
        $newId = $prefix . '-' . $count;
        
        // Prevent ID duplicates
        $stmtCheck = $db->prepare("SELECT id FROM t_approval_matrix WHERE id = ?");
        $stmtCheck->execute([$newId]);
        while ($stmtCheck->fetch()) {
            $count++;
            $newId = $prefix . '-' . $count;
            $stmtCheck->execute([$newId]);
        }
        
        $stmt = $db->prepare("INSERT INTO t_approval_matrix (id, doc_type, department, min_amount, max_amount, steps) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $newId,
            $payload['DocType'],
            $payload['Department'],
            $payload['MinAmount'],
            $payload['MaxAmount'],
            $payload['Steps']
        ]);
        
        $payload['ID'] = $newId;
        $payload['id'] = $newId;
        return ['success' => true, 'record' => $payload];
    } elseif ($tableName === 'm_fuel_assets') {
        $stmt = $db->prepare("INSERT INTO m_fuel_assets (id, asset_name, type, location, install_fuel_level, current_fuel_level, fuel_capacity, remaining_fuel, fuel_usage_rate, efficiency, next_refuel_estimate, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $payload['id'],
            $payload['asset_name'],
            $payload['type'],
            $payload['location'],
            $payload['install_fuel_level'],
            $payload['current_fuel_level'],
            $payload['fuel_capacity'],
            $payload['remaining_fuel'],
            $payload['fuel_usage_rate'],
            $payload['efficiency'],
            $payload['next_refuel_estimate'],
            $payload['status']
        ]);
        return ['success' => true, 'record' => $payload];
    }
    throw new Exception("Generic create not implemented for table: $tableName");
}

function updateMasterRecord($tableName, $id, $payload, $db) {
    if ($tableName === 't_approval_matrix') {
        $stmt = $db->prepare("UPDATE t_approval_matrix SET doc_type = ?, department = ?, min_amount = ?, max_amount = ?, steps = ? WHERE id = ?");
        $stmt->execute([
            $payload['DocType'],
            $payload['Department'],
            $payload['MinAmount'],
            $payload['MaxAmount'],
            $payload['Steps'],
            $id
        ]);
        return ['success' => true];
    } elseif ($tableName === 'm_fuel_assets') {
        $stmt = $db->prepare("UPDATE m_fuel_assets SET asset_name = ?, type = ?, location = ?, install_fuel_level = ?, current_fuel_level = ?, fuel_capacity = ?, remaining_fuel = ?, fuel_usage_rate = ?, efficiency = ?, next_refuel_estimate = ?, status = ? WHERE id = ?");
        $stmt->execute([
            $payload['asset_name'],
            $payload['type'],
            $payload['location'],
            $payload['install_fuel_level'],
            $payload['current_fuel_level'],
            $payload['fuel_capacity'],
            $payload['remaining_fuel'],
            $payload['fuel_usage_rate'],
            $payload['efficiency'],
            $payload['next_refuel_estimate'],
            $payload['status'],
            $id
        ]);
        return ['success' => true];
    }
    throw new Exception("Generic update not implemented for table: $tableName");
}

function deleteMasterRecord($tableName, $id, $db) {
    if ($tableName === 't_approval_matrix') {
        $stmt = $db->prepare("DELETE FROM t_approval_matrix WHERE id = ?");
        $stmt->execute([$id]);
        return ['success' => true];
    } elseif ($tableName === 'm_departments') {
        $stmt = $db->prepare("DELETE FROM m_departments WHERE code = ?");
        $stmt->execute([$id]);
        return ['success' => true];
    } elseif ($tableName === 'm_projects') {
        $stmt = $db->prepare("DELETE FROM m_projects WHERE code = ?");
        $stmt->execute([$id]);
        return ['success' => true];
    } elseif ($tableName === 'm_coas') {
        $stmt = $db->prepare("DELETE FROM m_coas WHERE code = ?");
        $stmt->execute([$id]);
        return ['success' => true];
    } elseif ($tableName === 'm_fuel_assets') {
        $stmt = $db->prepare("DELETE FROM m_fuel_assets WHERE id = ?");
        $stmt->execute([$id]);
        return ['success' => true];
    }
    throw new Exception("Generic delete not implemented for table: $tableName");
}

function deleteRequestRecord($id, $db) {
    $db->beginTransaction();
    try {
        $stmt = $db->prepare("DELETE FROM t_request_items WHERE request_id = ?");
        $stmt->execute([$id]);
        
        $stmt = $db->prepare("DELETE FROM t_requests WHERE id = ?");
        $stmt->execute([$id]);
        
        $db->commit();
        return ['success' => true];
    } catch (Exception $e) {
        $db->rollBack();
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

/**
 * saveDatabaseConfig
 */
function saveDatabaseConfig($host, $name, $user, $pass) {
    return ['success' => true];
}

/**
 * sendFullApprovalEmail - Sends HTML email to requester upon full approval
 */
function sendFullApprovalEmail($requestId, $db) {
    // 1. Fetch request details
    $stmt = $db->prepare("SELECT * FROM t_requests WHERE id = ?");
    $stmt->execute([$requestId]);
    $request = $stmt->fetch();
    if (!$request) return;
    
    // 2. Find requester email
    $requesterName = $request['requester'];
    $stmtUser = $db->prepare("SELECT username, email FROM m_users WHERE fullname = ? LIMIT 1");
    $stmtUser->execute([$requesterName]);
    $userObj = $stmtUser->fetch();
    
    $recipientEmail = '';
    if ($userObj) {
        if (!empty($userObj['email'])) {
            $recipientEmail = $userObj['email'];
        } else {
            $recipientEmail = $userObj['username'] . '@bis.co.id';
        }
    } else {
        // Fallback: convert fullname to lowercase dot format
        $cleanName = strtolower(preg_replace('/[^a-zA-Z0-9]/', '.', $requesterName));
        $recipientEmail = $cleanName . '@bis.co.id';
    }
    
    // 3. Format total nominal as IDR Currency
    $nominalFormatted = "Rp " . number_format($request['total_nominal'], 0, ',', '.');
    
    // 4. Construct list of approvers who signed
    $signatures = json_decode($request['signatures'], true) ?: [];
    $approversListHtml = '';
    
    // We want to sort/list them in order of signing
    foreach ($signatures as $key => $sig) {
        // Skip 'user' (prepared by) since they are the requester
        if ($key === 'user') continue;
        if (isset($sig['status']) && ($sig['status'] === 'APPROVED' || $sig['status'] === 'SUBMITTED')) {
            $signerName = isset($sig['name']) ? $sig['name'] : '-';
            $signerRole = isset($sig['role']) ? $sig['role'] : $key;
            $signDate = isset($sig['date']) && !empty($sig['date']) ? date('d/m/Y H:i', strtotime($sig['date'])) : '';
            $approversListHtml .= "<li style='margin-bottom: 6px;'><strong>$signerName</strong> ($signerRole)" . ($signDate ? " pada $signDate" : "") . "</li>";
        }
    }
    
    if (empty($approversListHtml)) {
        $approversListHtml = "<li>Disetujui oleh sistem / penandatangan otomatis</li>";
    }
    
    // 5. Build HTML body
    $host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'enterprise-bku.my.id';
    
    $subject = "[APPROVED] Pengajuan " . $request['type'] . " - " . $request['doc_number'];
    
    $htmlContent = '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Pengajuan Disetujui</title>
    </head>
    <body style="font-family: Arial, sans-serif; background-color: #f4f5f7; margin: 0; padding: 20px; color: #333;">
        <div style="max-width: 600px; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.08); margin: 0 auto; border-top: 5px solid #2e7d32;">
            <div style="padding: 24px; text-align: center; background-color: #e8f5e9;">
                <div style="color: #2e7d32; font-size: 36px; margin-bottom: 10px;">✔️</div>
                <h2 style="color: #2e7d32; margin: 0; font-size: 20px; font-weight: bold;">PENGAJUAN DISETUJUI SEPENUHNYA</h2>
                <p style="color: #555; font-size: 13px; margin: 5px 0 0 0;">Dokumen Anda telah selesai diproses oleh semua penyetuju.</p>
            </div>
            <div style="padding: 24px; font-size: 14px; line-height: 1.6;">
                <p>Halo <strong>' . htmlspecialchars($requesterName) . '</strong>,</p>
                <p>Pengajuan dokumen Anda telah disetujui sepenuhnya (<strong>Full Approved</strong>). Berikut adalah rincian dokumen Anda:</p>
                
                <table style="width: 100%; border-collapse: collapse; margin: 15px 0; font-size: 13px;">
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666; width: 35%;">No. Dokumen</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; font-weight: bold;">' . htmlspecialchars($request['doc_number']) . '</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666;">Jenis Pengajuan</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee;"><span style="background-color: #e3f2fd; color: #0d47a1; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;">' . htmlspecialchars($request['type']) . '</span></td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666;">Subject / Perihal</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee;">' . htmlspecialchars($request['subject']) . '</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666;">Tanggal Pengajuan</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee;">' . htmlspecialchars($request['date']) . '</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666;">Total Nominal</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; font-weight: bold; color: #2e7d32; font-size: 15px;">' . $nominalFormatted . '</td>
                    </tr>
                </table>
                
                <div style="background-color: #fafafa; border: 1px solid #eee; border-radius: 6px; padding: 15px; margin-top: 20px;">
                    <h4 style="margin: 0 0 10px 0; color: #555; font-size: 13px;">Selesai Ditandatangani Oleh:</h4>
                    <ul style="margin: 0; padding-left: 20px; font-size: 12.5px; color: #444;">
                        ' . $approversListHtml . '
                    </ul>
                </div>
                
                <div style="text-align: center; margin: 30px 0 10px 0;">
                    <a href="https://' . $host . '" style="background-color: #2e7d32; color: #ffffff; text-decoration: none; padding: 12px 24px; border-radius: 4px; font-weight: bold; font-size: 14px; display: inline-block;">Buka Aplikasi E-Approval</a>
                </div>
            </div>
            <div style="padding: 16px; background-color: #f9f9f9; text-align: center; font-size: 11px; color: #999; border-top: 1px solid #eee;">
                Pemberitahuan otomatis dari Sistem E-Approval Bara Indah Sinergi Group.<br>Harap tidak membalas email ini.
            </div>
        </div>
    </body>
    </html>';
    
    // 6. Set headers & send with envelope sender flag (-f) to prevent spam block on cPanel
    $cleanHost = $host;
    if (preg_match('/localhost|127\.0\.0\.1|^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/', $cleanHost) || strpos($cleanHost, '.') === false) {
        $cleanHost = 'bis.co.id';
    }
    $fromEmail = "noreply@" . $cleanHost;

    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
    $headers .= "From: E-Approval System <" . $fromEmail . ">\r\n";
    $headers .= "Reply-To: " . $fromEmail . "\r\n";
    $headers .= "X-Mailer: PHP/" . phpversion();
    
    $logMsg = "[" . date('Y-m-d H:i:s') . "] Attempting to send E-Approval email to recipient: $recipientEmail for Request ID: $requestId. Sender Envelope: $fromEmail\n";
    
    $sent = mail($recipientEmail, $subject, $htmlContent, $headers, "-f " . $fromEmail);
    
    if ($sent) {
        $logMsg .= "Result: SUCCESS (mail() returned true)\n\n";
    } else {
        $logMsg .= "Result: FAILED (mail() returned false)\n\n";
    }
    
    file_put_contents('mail_log.txt', $logMsg, FILE_APPEND);
}

function sendFullApprovalEmailWithPDF($requestId, $pdfBase64, $db) {
    // 1. Fetch request details
    $stmt = $db->prepare("SELECT * FROM t_requests WHERE id = ?");
    $stmt->execute([$requestId]);
    $request = $stmt->fetch();
    if (!$request) return ['success' => false, 'error' => 'Request not found'];
    
    // 2. Find requester email
    $requesterName = $request['requester'];
    $stmtUser = $db->prepare("SELECT username, email FROM m_users WHERE fullname = ? LIMIT 1");
    $stmtUser->execute([$requesterName]);
    $userObj = $stmtUser->fetch();
    
    $recipientEmail = '';
    if ($userObj) {
        if (!empty($userObj['email'])) {
            $recipientEmail = $userObj['email'];
        } else {
            $recipientEmail = $userObj['username'] . '@bis.co.id';
        }
    } else {
        $cleanName = strtolower(preg_replace('/[^a-zA-Z0-9]/', '.', $requesterName));
        $recipientEmail = $cleanName . '@bis.co.id';
    }
    
    // 3. Format total nominal as IDR Currency
    $nominalFormatted = "Rp " . number_format($request['total_nominal'], 0, ',', '.');
    
    // 4. Construct list of approvers who signed
    $signatures = json_decode($request['signatures'], true) ?: [];
    $approversListHtml = '';
    foreach ($signatures as $key => $sig) {
        if ($key === 'user') continue;
        if (isset($sig['status']) && ($sig['status'] === 'APPROVED' || $sig['status'] === 'SUBMITTED')) {
            $signerName = isset($sig['name']) ? $sig['name'] : '-';
            $signerRole = isset($sig['role']) ? $sig['role'] : $key;
            $signDate = isset($sig['date']) && !empty($sig['date']) ? date('d/m/Y H:i', strtotime($sig['date'])) : '';
            $approversListHtml .= "<li style='margin-bottom: 6px;'><strong>$signerName</strong> ($signerRole)" . ($signDate ? " pada $signDate" : "") . "</li>";
        }
    }
    if (empty($approversListHtml)) {
        $approversListHtml = "<li>Disetujui oleh sistem / penandatangan otomatis</li>";
    }
    
    // 5. Build HTML body
    $host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'bis.co.id';
    $subject = "[APPROVED] Pengajuan " . $request['type'] . " - " . $request['doc_number'];
    
    $htmlContent = '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Pengajuan Disetujui</title>
    </head>
    <body style="font-family: Arial, sans-serif; background-color: #f4f5f7; margin: 0; padding: 20px; color: #333;">
        <div style="max-width: 600px; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.08); margin: 0 auto; border-top: 5px solid #2e7d32;">
            <div style="padding: 24px; text-align: center; background-color: #e8f5e9;">
                <div style="color: #2e7d32; font-size: 36px; margin-bottom: 10px;">✔️</div>
                <h2 style="color: #2e7d32; margin: 0; font-size: 20px; font-weight: bold;">PENGAJUAN DISETUJUI SEPENUHNYA</h2>
                <p style="color: #555; font-size: 13px; margin: 5px 0 0 0;">Dokumen Anda telah selesai diproses oleh semua penyetuju.</p>
            </div>
            <div style="padding: 24px; font-size: 14px; line-height: 1.6;">
                <p>Halo <strong>' . htmlspecialchars($requesterName) . '</strong>,</p>
                <p>Pengajuan dokumen Anda telah disetujui sepenuhnya (<strong>Full Approved</strong>). Salinan resmi PDF berkas yang telah ditandatangani terlampir di email ini.</p>
                
                <table style="width: 100%; border-collapse: collapse; margin: 15px 0; font-size: 13px;">
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666; width: 35%;">No. Dokumen</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; font-weight: bold;">' . htmlspecialchars($request['doc_number']) . '</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666;">Jenis Pengajuan</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee;"><span style="background-color: #e3f2fd; color: #0d47a1; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;">' . htmlspecialchars($request['type']) . '</span></td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666;">Tanggal Pengajuan</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee;">' . htmlspecialchars($request['date']) . '</td>
                    </tr>
                    <tr>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; color: #666;">Total Nominal</td>
                        <td style="padding: 8px 0; border-bottom: 1px solid #eee; font-weight: bold; color: #2e7d32; font-size: 15px;">' . $nominalFormatted . '</td>
                    </tr>
                </table>
                
                <div style="background-color: #fafafa; border: 1px solid #eee; border-radius: 6px; padding: 15px; margin-top: 20px;">
                    <h4 style="margin: 0 0 10px 0; color: #555; font-size: 13px;">Selesai Ditandatangani Oleh:</h4>
                    <ul style="margin: 0; padding-left: 20px; font-size: 12.5px; color: #444;">
                        ' . $approversListHtml . '
                    </ul>
                </div>
                
                <div style="text-align: center; margin: 30px 0 10px 0;">
                    <a href="https://' . $host . '" style="background-color: #2e7d32; color: #ffffff; text-decoration: none; padding: 12px 24px; border-radius: 4px; font-weight: bold; font-size: 14px; display: inline-block;">Buka Aplikasi E-Approval</a>
                </div>
            </div>
            <div style="padding: 16px; background-color: #f9f9f9; text-align: center; font-size: 11px; color: #999; border-top: 1px solid #eee;">
                Pemberitahuan otomatis dari Sistem E-Approval Bara Indah Sinergi Group.<br>Harap tidak membalas email ini.
            </div>
        </div>
    </body>
    </html>';

    // 6. Decode Base64 PDF
    $pdfData = '';
    if (preg_match('/^data:application\/pdf;base64,(.+)$/i', $pdfBase64, $matches)) {
        $pdfData = base64_decode($matches[1]);
    } elseif (preg_match('/base64,(.+)$/i', $pdfBase64, $matches)) {
        $pdfData = base64_decode($matches[1]);
    } else {
        $pdfData = base64_decode($pdfBase64);
    }
    
    $filename = str_replace('/', '_', $request['doc_number']) . '.pdf';
    $attachment = chunk_split(base64_encode($pdfData));
    
    // 7. MIME Headers for email attachment
    $cleanHost = $host;
    if (preg_match('/localhost|127\.0\.0\.1|^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/', $cleanHost) || strpos($cleanHost, '.') === false) {
        $cleanHost = 'bis.co.id';
    }
    $fromEmail = "noreply@" . $cleanHost;
    
    $boundary = md5(time());
    
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "From: E-Approval System <" . $fromEmail . ">\r\n";
    $headers .= "Reply-To: " . $fromEmail . "\r\n";
    $headers .= "X-Mailer: PHP/" . phpversion() . "\r\n";
    $headers .= "Content-Type: multipart/mixed; boundary=\"" . $boundary . "\"\r\n";
    
    // HTML Message part
    $body = "--" . $boundary . "\r\n";
    $body .= "Content-Type: text/html; charset=UTF-8\r\n";
    $body .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
    $body .= $htmlContent . "\r\n\r\n";
    
    // Attachment part
    $body .= "--" . $boundary . "\r\n";
    $body .= "Content-Type: application/pdf; name=\"" . $filename . "\"\r\n";
    $body .= "Content-Transfer-Encoding: base64\r\n";
    $body .= "Content-Disposition: attachment; filename=\"" . $filename . "\"\r\n\r\n";
    $body .= $attachment . "\r\n\r\n";
    $body .= "--" . $boundary . "--";
    
    if (USE_SMTP) {
        $logMsg = "[" . date('Y-m-d H:i:s') . "] Attempting to send E-Approval email with PDF attachment ($filename) to recipient: $recipientEmail via SMTP (" . SMTP_HOST . ")\n";
        try {
            $success = sendSMTPEmailSocket($recipientEmail, $subject, $htmlContent, $pdfBase64, $requestId, $request['doc_number']);
            $logMsg .= "Result: SUCCESS (SMTP sent successfully)\n\n";
        } catch (Exception $e) {
            $success = false;
            $logMsg .= "Result: FAILED (SMTP Error: " . $e->getMessage() . ")\n\n";
        }
    } else {
        $logMsg = "[" . date('Y-m-d H:i:s') . "] Attempting to send E-Approval email with PDF attachment ($filename) to recipient: $recipientEmail for Request ID: $requestId. Sender Envelope: $fromEmail\n";
        $sent = mail($recipientEmail, $subject, $body, $headers, "-f " . $fromEmail);
        if ($sent) {
            $logMsg .= "Result: SUCCESS (mail() returned true)\n\n";
            $success = true;
        } else {
            $logMsg .= "Result: FAILED (mail() returned false)\n\n";
            $success = false;
        }
    }
    
    file_put_contents('mail_log.txt', $logMsg, FILE_APPEND);
    return ['success' => $success];
}

function sendSMTPEmailSocket($to, $subject, $htmlContent, $pdfBase64 = null, $requestId = null, $docNumber = null) {
    $host = SMTP_HOST;
    $port = (int)SMTP_PORT;
    $username = SMTP_USER;
    $password = SMTP_PASS;
    $encryption = strtolower(SMTP_ENC);
    $senderEmail = SENDER_EMAIL ?: $username;
    
    $boundary = md5(time());
    $filename = $docNumber ? str_replace('/', '_', $docNumber) . '.pdf' : 'document.pdf';
    
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Subject: " . $subject . "\r\n";
    $headers .= "To: " . $to . "\r\n";
    $headers .= "From: " . SENDER_NAME . " <" . $senderEmail . ">\r\n";
    $headers .= "Reply-To: " . $senderEmail . "\r\n";
    $headers .= "X-Mailer: PHP/" . phpversion() . "\r\n";
    
    if ($pdfBase64) {
        $headers .= "Content-Type: multipart/mixed; boundary=\"" . $boundary . "\"\r\n";
        
        $body = "--" . $boundary . "\r\n";
        $body .= "Content-Type: text/html; charset=UTF-8\r\n";
        $body .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
        $body .= $htmlContent . "\r\n\r\n";
        
        $pdfData = '';
        if (preg_match('/^data:application\/pdf;base64,(.+)$/i', $pdfBase64, $matches)) {
            $pdfData = base64_decode($matches[1]);
        } elseif (preg_match('/base64,(.+)$/i', $pdfBase64, $matches)) {
            $pdfData = base64_decode($matches[1]);
        } else {
            $pdfData = base64_decode($pdfBase64);
        }
        $attachment = chunk_split(base64_encode($pdfData));
        
        $body .= "--" . $boundary . "\r\n";
        $body .= "Content-Type: application/pdf; name=\"" . $filename . "\"\r\n";
        $body .= "Content-Transfer-Encoding: base64\r\n";
        $body .= "Content-Disposition: attachment; filename=\"" . $filename . "\"\r\n\r\n";
        $body .= $attachment . "\r\n\r\n";
        $body .= "--" . $boundary . "--";
    } else {
        $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
        $body = $htmlContent;
    }
    
    $socketHost = $host;
    if ($encryption === 'ssl') {
        $socketHost = 'ssl://' . $host;
    }
    
    $socket = @fsockopen($socketHost, $port, $errno, $errstr, 15);
    if (!$socket) {
        throw new Exception("Could not connect to SMTP server: $errstr ($errno)");
    }
    
    $response = fgets($socket, 512);
    
    fwrite($socket, "EHLO " . $_SERVER['HTTP_HOST'] . "\r\n");
    $response = fgets($socket, 512);
    
    if ($encryption === 'tls') {
        fwrite($socket, "STARTTLS\r\n");
        $response = fgets($socket, 512);
        if (stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
            fwrite($socket, "EHLO " . $_SERVER['HTTP_HOST'] . "\r\n");
            $response = fgets($socket, 512);
        } else {
            fclose($socket);
            throw new Exception("TLS negotiation failed");
        }
    }
    
    if (!empty($username) && !empty($password)) {
        fwrite($socket, "AUTH LOGIN\r\n");
        $response = fgets($socket, 512);
        
        fwrite($socket, base64_encode($username) . "\r\n");
        $response = fgets($socket, 512);
        
        fwrite($socket, base64_encode($password) . "\r\n");
        $response = fgets($socket, 512);
        if (strpos($response, '235') === false) {
            fclose($socket);
            throw new Exception("SMTP Authentication failed: " . $response);
        }
    }
    
    fwrite($socket, "MAIL FROM:<" . $senderEmail . ">\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, "RCPT TO:<" . $to . ">\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, "DATA\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, $headers . "\r\n" . $body . "\r\n.\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, "QUIT\r\n");
    fclose($socket);
    return true;
}

/**
 * getPerformanceData
 */
function getPerformanceData($db) {
    return [
        'kpis' => $db->query("SELECT * FROM t_perf_kpis")->fetchAll(),
        'pit' => $db->query("SELECT * FROM t_perf_pit")->fetchAll(),
        'monthly_trends' => $db->query("SELECT * FROM t_perf_monthly_trends ORDER BY rowid")->fetchAll(),
        'vessels' => $db->query("SELECT * FROM t_perf_vessels ORDER BY id")->fetchAll(),
        'stockpiles' => $db->query("SELECT * FROM t_perf_stockpiles ORDER BY location")->fetchAll(),
        'pica' => $db->query("SELECT * FROM t_perf_pica ORDER BY id")->fetchAll(),
        'root_causes' => $db->query("SELECT * FROM t_perf_root_causes ORDER BY percentage DESC")->fetchAll(),
        'scorecards' => $db->query("SELECT * FROM t_perf_scorecards ORDER BY score DESC")->fetchAll(),
        'alerts' => $db->query("SELECT * FROM t_perf_alerts ORDER BY timestamp DESC")->fetchAll()
    ];
}

/**
 * savePerformanceKPIs
 */
function savePerformanceKPIs($args, $db) {
    $db->beginTransaction();
    try {
        $stmt = $db->prepare("UPDATE t_perf_kpis SET value_actual = :act, value_target = :targ WHERE metric_key = :key");
        foreach ($args as $key => $values) {
            $stmt->execute([
                ':act' => $values['actual'],
                ':targ' => $values['target'],
                ':key' => $key
            ]);
        }
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * savePitPerformance
 */
function savePitPerformance($args, $db) {
    $db->beginTransaction();
    try {
        if (!isset($args['trends'])) {
            $stmt = $db->prepare("UPDATE t_perf_pit SET target = :targ, actual = :act WHERE pit_name = :name");
            foreach ($args as $pit) {
                if (!isset($pit['pit_name'])) continue;
                $stmt->execute([
                    ':targ' => $pit['target'],
                    ':act' => $pit['actual'],
                    ':name' => $pit['pit_name']
                ]);
            }
        }
        
        // Also update monthly trends if specified
        if (isset($args['trends'])) {
            $trendStmt = $db->prepare("UPDATE t_perf_monthly_trends SET target = :targ, actual = :act WHERE month_name = :name");
            foreach ($args['trends'] as $trend) {
                $trendStmt->execute([
                    ':targ' => $trend['target'],
                    ':act' => $trend['actual'],
                    ':name' => $trend['month_name']
                ]);
            }
        }
        
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * saveStockpiles
 */
function saveStockpiles($args, $db) {
    $db->beginTransaction();
    try {
        $stmt = $db->prepare("UPDATE t_perf_stockpiles SET volume = :vol, grade_ni = :grade, status = :status WHERE location = :loc");
        foreach ($args as $sp) {
            $stmt->execute([
                ':vol' => $sp['volume'],
                ':grade' => $sp['grade_ni'],
                ':status' => $sp['status'],
                ':loc' => $sp['location']
            ]);
        }
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * saveVessels
 */
function saveVessels($args, $db) {
    $db->beginTransaction();
    try {
        $db->exec("DELETE FROM t_perf_vessels");
        $stmt = $db->prepare("INSERT INTO t_perf_vessels (id, vessel_name, destination, cargo, status) VALUES (:id, :name, :dest, :cargo, :status)");
        foreach ($args as $idx => $v) {
            $stmt->execute([
                ':id' => 'VES-' . ($idx + 1),
                ':name' => $v['vessel_name'],
                ':dest' => $v['destination'],
                ':cargo' => $v['cargo'],
                ':status' => $v['status']
            ]);
        }
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * savePICA
 */
function savePICA($args, $db) {
    $db->beginTransaction();
    try {
        $db->exec("DELETE FROM t_perf_pica");
        $stmt = $db->prepare("INSERT INTO t_perf_pica (id, title, category, owner, due_date, status) VALUES (:id, :title, :cat, :owner, :due, :status)");
        foreach ($args as $idx => $p) {
            $stmt->execute([
                ':id' => 'PICA-' . ($idx + 1),
                ':title' => $p['title'],
                ':cat' => $p['category'],
                ':owner' => $p['owner'],
                ':due' => $p['due_date'],
                ':status' => $p['status']
            ]);
        }
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * saveRootCauses
 */
function saveRootCauses($args, $db) {
    $db->beginTransaction();
    try {
        $stmt = $db->prepare("UPDATE t_perf_root_causes SET percentage = :pct WHERE cause_name = :name");
        foreach ($args as $c) {
            $stmt->execute([
                ':pct' => $c['percentage'],
                ':name' => $c['cause_name']
            ]);
        }
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * saveScorecards
 */
function saveScorecards($args, $db) {
    $db->beginTransaction();
    try {
        $stmt = $db->prepare("UPDATE t_perf_scorecards SET score = :score WHERE department_name = :name");
        foreach ($args as $s) {
            $stmt->execute([
                ':score' => $s['score'],
                ':name' => $s['department_name']
            ]);
        }
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * saveAlerts
 */
function saveAlerts($args, $db) {
    $db->beginTransaction();
    try {
        $db->exec("DELETE FROM t_perf_alerts");
        $stmt = $db->prepare("INSERT INTO t_perf_alerts (id, alert_type, message, timestamp) VALUES (:id, :type, :msg, :time)");
        foreach ($args as $idx => $a) {
            $stmt->execute([
                ':id' => 'ALT-' . ($idx + 1),
                ':type' => $a['alert_type'],
                ':msg' => $a['message'],
                ':time' => $a['timestamp']
            ]);
        }
        $db->commit();
        return true;
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }
}

/**
 * getFuelData
 */
function getFuelData($db) {
    try {
        $tanks = $db->query("SELECT * FROM t_fuel_tanks")->fetchAll(PDO::FETCH_ASSOC);
        $stock_in = $db->query("SELECT * FROM t_fuel_stock_in ORDER BY date DESC LIMIT 50")->fetchAll(PDO::FETCH_ASSOC);
        $stock_out = $db->query("SELECT * FROM t_fuel_stock_out ORDER BY date DESC LIMIT 50")->fetchAll(PDO::FETCH_ASSOC);
        $alerts = $db->query("SELECT * FROM t_fuel_alerts ORDER BY timestamp DESC LIMIT 20")->fetchAll(PDO::FETCH_ASSOC);
        $assets = $db->query("SELECT * FROM m_fuel_assets ORDER BY id ASC")->fetchAll(PDO::FETCH_ASSOC);
        
        return [
            'success' => true,
            'tanks' => $tanks,
            'stock_in' => $stock_in,
            'stock_out' => $stock_out,
            'alerts' => $alerts,
            'assets' => $assets
        ];
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

/**
 * saveFuelStockIn
 */
function saveFuelStockIn($data, $db) {
    $db->beginTransaction();
    try {
        $stmt = $db->prepare("INSERT INTO t_fuel_stock_in (id, date, doc_number, supplier, tank, qty, fuel_type, operator) VALUES (:id, :date, :doc_number, :supplier, :tank, :qty, :fuel_type, :operator)");
        $id = 'IN-' . uniqid();
        $stmt->execute([
            ':id' => $id,
            ':date' => $data['date'],
            ':doc_number' => $data['doc_number'],
            ':supplier' => $data['supplier'],
            ':tank' => $data['tank'],
            ':qty' => (float)$data['qty'],
            ':fuel_type' => $data['fuel_type'],
            ':operator' => $data['operator']
        ]);
        
        // Update tank stock
        $stmtUpdate = $db->prepare("UPDATE t_fuel_tanks SET current_stock = current_stock + :qty WHERE tank_name LIKE :tank OR id = :tank_id");
        $tankPattern = '%' . $data['tank'] . '%';
        $stmtUpdate->execute([
            ':qty' => (float)$data['qty'],
            ':tank' => $tankPattern,
            ':tank_id' => $data['tank']
        ]);
        
        $db->commit();
        return ['success' => true];
    } catch (Exception $e) {
        $db->rollBack();
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

/**
 * saveFuelStockOut
 */
function saveFuelStockOut($data, $db) {
    $db->beginTransaction();
    try {
        $stmt = $db->prepare("INSERT INTO t_fuel_stock_out (id, date, category, unit, purpose, qty, operator) VALUES (:id, :date, :category, :unit, :purpose, :qty, :operator)");
        $id = 'OUT-' . uniqid();
        $stmt->execute([
            ':id' => $id,
            ':date' => $data['date'],
            ':category' => $data['category'],
            ':unit' => $data['unit'],
            ':purpose' => $data['purpose'],
            ':qty' => (float)$data['qty'],
            ':operator' => $data['operator']
        ]);
        
        // Update tank stock
        if (isset($data['tank'])) {
            $stmtUpdate = $db->prepare("UPDATE t_fuel_tanks SET current_stock = current_stock - :qty WHERE tank_name LIKE :tank OR id = :tank_id");
            $tankPattern = '%' . $data['tank'] . '%';
            $stmtUpdate->execute([
                ':qty' => (float)$data['qty'],
                ':tank' => $tankPattern,
                ':tank_id' => $data['tank']
            ]);
        }
        
        $db->commit();
        return ['success' => true];
    } catch (Exception $e) {
        $db->rollBack();
        return ['success' => false, 'error' => $e->getMessage()];
    }
}
?>
