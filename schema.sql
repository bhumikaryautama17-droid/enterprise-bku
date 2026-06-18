-- schema.sql
-- Database schema for PT. Bhumi Karya Utama Workflow System (SQLite Version)

PRAGMA foreign_keys = OFF;
DROP TABLE IF EXISTS `t_audit_log`;
DROP TABLE IF EXISTS `t_budget`;
DROP TABLE IF EXISTS `t_approval_matrix`;
DROP TABLE IF EXISTS `t_request_items`;
DROP TABLE IF EXISTS `t_requests`;
DROP TABLE IF EXISTS `m_users`;
DROP TABLE IF EXISTS `m_cost_elements`;
DROP TABLE IF EXISTS `m_coas`;
DROP TABLE IF EXISTS `m_projects`;
DROP TABLE IF EXISTS `m_departments`;
PRAGMA foreign_keys = ON;

-- 1. Departments Table
CREATE TABLE `m_departments` (
  `id` TEXT PRIMARY KEY,
  `code` TEXT UNIQUE NOT NULL,
  `name` TEXT NOT NULL
);

-- 2. Projects Table
CREATE TABLE `m_projects` (
  `id` TEXT PRIMARY KEY,
  `code` TEXT UNIQUE NOT NULL,
  `name` TEXT NOT NULL
);

-- 3. COA Table
CREATE TABLE `m_coas` (
  `id` TEXT PRIMARY KEY,
  `code` TEXT UNIQUE NOT NULL,
  `name` TEXT NOT NULL
);

-- 4. Cost Elements Table
CREATE TABLE `m_cost_elements` (
  `id` TEXT PRIMARY KEY,
  `code` TEXT UNIQUE NOT NULL,
  `name` TEXT NOT NULL
);

-- 5. Users Table
CREATE TABLE `m_users` (
  `id` TEXT PRIMARY KEY,
  `username` TEXT UNIQUE NOT NULL,
  `fullname` TEXT NOT NULL,
  `role` TEXT NOT NULL,
  `department` TEXT NOT NULL,
  `password` TEXT NOT NULL,
  `signature` TEXT,
  `status` TEXT DEFAULT 'Active',
  `email` TEXT DEFAULT NULL
);

-- 6. Document Requests Table
CREATE TABLE `t_requests` (
  `id` TEXT PRIMARY KEY,
  `type` TEXT NOT NULL,
  `doc_number` TEXT UNIQUE NOT NULL,
  `date` TEXT NOT NULL,
  `department` TEXT NOT NULL,
  `priority` TEXT NOT NULL,
  `inventory_type` TEXT DEFAULT NULL,
  `purchase_category` TEXT DEFAULT NULL,
  `subject` TEXT NOT NULL,
  `requester` TEXT NOT NULL,
  `total_nominal` REAL NOT NULL,
  `status` TEXT NOT NULL,
  `current_approver_role` TEXT NOT NULL,
  `created_at` TEXT DEFAULT CURRENT_TIMESTAMP,
  `signatures` TEXT,
  `user_for` TEXT,
  `attachment` TEXT,
  `attachment_name` TEXT DEFAULT NULL,
  `budget_capture` TEXT
);

-- 7. Request Items Table
CREATE TABLE `t_request_items` (
  `id` TEXT PRIMARY KEY,
  `request_id` TEXT NOT NULL,
  `coa` TEXT,
  `part_number` TEXT,
  `description` TEXT NOT NULL,
  `cost_element` TEXT,
  `quantity` INTEGER NOT NULL,
  `uom` TEXT NOT NULL,
  `price` REAL NOT NULL,
  `total` REAL NOT NULL,
  FOREIGN KEY (`request_id`) REFERENCES `t_requests` (`id`) ON DELETE CASCADE
);

-- 8. Approval Matrix Table
CREATE TABLE `t_approval_matrix` (
  `id` TEXT PRIMARY KEY,
  `doc_type` TEXT NOT NULL,
  `department` TEXT NOT NULL,
  `min_amount` REAL NOT NULL,
  `max_amount` REAL NOT NULL,
  `steps` TEXT NOT NULL
);

-- 9. Budget Table
CREATE TABLE `t_budget` (
  `id` TEXT PRIMARY KEY,
  `department` TEXT NOT NULL,
  `project` TEXT NOT NULL,
  `year` INTEGER NOT NULL,
  `annual_budget` REAL NOT NULL,
  `actual_budget` REAL NOT NULL
);

-- 10. Audit Trail Log Table
CREATE TABLE `t_audit_log` (
  `id` TEXT PRIMARY KEY,
  `timestamp` TEXT DEFAULT CURRENT_TIMESTAMP,
  `user` TEXT NOT NULL,
  `activity` TEXT NOT NULL,
  `module` TEXT NOT NULL,
  `doc_number` TEXT DEFAULT NULL,
  `ip_address` TEXT DEFAULT NULL
);


-- ==================== SEED DATA ====================

-- Seed Departments
INSERT INTO `m_departments` (`id`, `code`, `name`) VALUES
('DEPT-1', 'HRGA', 'Human Resources & General Affairs'),
('DEPT-2', 'QAQC', 'Quality Assurance & Quality Control'),
('DEPT-3', 'SHE', 'Safety, Health & Environment'),
('DEPT-4', 'Engineering', 'Engineering Department'),
('DEPT-5', 'Plant', 'Plant Operation'),
('DEPT-6', 'External', 'External Affairs'),
('DEPT-7', 'Eksplorasi', 'Eksplorasi & Geological');

-- Seed Projects
INSERT INTO `m_projects` (`id`, `code`, `name`) VALUES
('PROJ-1', 'PROJ-CRM', 'CRM System Development'),
('PROJ-2', 'PROJ-MSR', 'MSR Safety Procurement'),
('PROJ-3', 'PROJ-EXPL', 'Sko Coal Drilling Plan');

-- Seed COAs
INSERT INTO `m_coas` (`id`, `code`, `name`) VALUES
('COA-1', '610-02-03-001', 'Kipas Angin Regency 16 Inch'),
('COA-2', '610-02-03-002', 'Stop Kontak Arde 5 Meter'),
('COA-3', '610-02-05-001', 'Termometer Digital'),
('COA-4', '610-02-05-002', 'Safety Helmet Yellow'),
('COA-5', '610-02-06-001', 'Kertas A4 80gr Sinar Dunia');

-- Seed Cost Elements
INSERT INTO `m_cost_elements` (`id`, `code`, `name`) VALUES
('CE-1', '612.01.04', 'Office Supplies'),
('CE-2', '612.01.05', 'Tool Equipment'),
('CE-3', '612.02.01', 'Safety Equipment');

-- Seed Approval Matrix
INSERT INTO `t_approval_matrix` (`id`, `doc_type`, `department`, `min_amount`, `max_amount`, `steps`) VALUES
('AM-1', 'PD', 'ALL', 0.00, 99999999999.00, 'Project Manager, Finance'),
('AM-2', 'PR', 'ALL', 0.00, 99999999999.00, 'Supervisor, Finance, Project Manager');

-- Seed Budgets
INSERT INTO `t_budget` (`id`, `department`, `project`, `year`, `annual_budget`, `actual_budget`) VALUES
('B-1', 'HRGA', 'PROJ-CRM', 2026, 650000000.00, 420000000.00),
('B-2', 'QAQC', 'PROJ-CRM', 2026, 320000000.00, 150000000.00),
('B-3', 'SHE', 'PROJ-MSR', 2026, 180000000.00, 80000000.00),
('B-4', 'Engineering', 'PROJ-CRM', 2026, 2100000000.00, 1200000000.00),
('B-5', 'Plant', 'PROJ-CRM', 2026, 4200000000.00, 2800000000.00),
('B-6', 'External', 'PROJ-CRM', 2026, 252000000.00, 110000000.00),
('B-7', 'Eksplorasi', 'PROJ-EXPL', 2026, 2000000000.00, 1400000000.00);

-- Seed Users
INSERT INTO `m_users` (`id`, `username`, `fullname`, `role`, `department`, `password`, `signature`, `status`) VALUES
('USR-1', 'mona.asrani', 'Mona Asrani', 'Supervisor', 'HRGA', 'BARAindah@2026', '', 'Active'),
('USR-2', 'rosalia.natalia', 'Rosalia Natalia', 'Project Manager', 'Management', 'BARAindah@2026', '', 'Active'),
('USR-3', 'putri.amalia', 'Putri Amalia', 'Finance', 'Finance', 'BARAindah@2026', '', 'Active'),
('USR-4', 'rosmina.rabbang', 'Rosmina Rabbang', 'Supervisor', 'SHE', 'BARAindah@2026', '', 'Active'),
('USR-5', 'erwin.eka', 'Erwin Eka', 'Supervisor', 'External', 'BARAindah@2026', '', 'Active'),
('USR-6', 'yusril', 'Yusril', 'Supervisor', 'QAQC', 'BARAindah@2026', '', 'Active'),
('USR-7', 'roymon.biang', 'Roymon Biang', 'Supervisor', 'Engineering', 'BARAindah@2026', '', 'Active'),
('USR-8', 'muh.said', 'Muh. Said', 'Supervisor', 'Plant', 'BARAindah@2026', '', 'Active'),
('USR-9', 'laode.rusman', 'Laode Rusman', 'Supervisor', 'Eksplorasi', 'BARAindah@2026', '', 'Active'),
('USR-10', 'idul.yusuf', 'Muh Idul Adhan Yusuf', 'User', 'HRGA', 'BARAindah@2026', '', 'Active'),
('USR-11', 'saiful.basri', 'Saiful Basri', 'User', 'SHE', 'BARAindah@2026', '', 'Active'),
('USR-12', 'admin', 'System Administrator', 'Administrator', 'IT', 'BARAindah@2026', '', 'Active');

-- Seed Requests
INSERT INTO `t_requests` (`id`, `type`, `doc_number`, `date`, `department`, `priority`, `inventory_type`, `purchase_category`, `subject`, `requester`, `total_nominal`, `status`, `current_approver_role`, `created_at`, `signatures`, `user_for`, `attachment`, `attachment_name`, `budget_capture`) VALUES
('REQ-1', 'PR', 'PR-2026-00045', '2026-05-15', 'HRGA', 'P1', 'NON STOCK', 'Office Equipment', 'Kebutuhan Kipas Angin Regency Periode Maret 2026', 'Muh Idul Adhan Yusuf', 995000.00, 'Pending', 'Finance', '2026-05-15 10:00:00', '{"user":{"name":"Muh Idul Adhan Yusuf","role":"User","date":"2026-05-15T10:00:00Z","status":"SUBMITTED","signatureText":"Muh Idul Adhan Yusuf"},"supervisor":{"name":"Mona Asrani","role":"Supervisor","date":"2026-05-15T10:30:00Z","status":"APPROVED","signatureText":"[e-Signed: Mona Asrani]"},"finance":{"name":"","role":"Finance","date":"","status":"PENDING","signatureText":""},"projectManager":{"name":"","role":"Project Manager","date":"","status":"PENDING","signatureText":""}}', 'Kebutuhan Kipas Angin Regency Periode Maret 2026', '', '', ''),
('REQ-2', 'PD', 'PD-2026-00012', '2026-06-14', 'HRGA', 'P2', '', '', 'Kebutuhan Operasional Proyek Maret 2026', 'Mona Asrani', 15450000.00, 'Pending', 'Project Manager', '2026-06-14 09:00:00', '{"user":{"name":"Mona Asrani","role":"User","date":"2026-06-14T09:00:00Z","status":"SUBMITTED","signatureText":"Mona Asrani"},"deptHeadPm":{"name":"","role":"Dept Head / PM","date":"","status":"PENDING","signatureText":""},"financeSite":{"name":"","role":"Finance Site","date":"","status":"PENDING","signatureText":""}}', 'Dana operasional operasional proyek lapangan', '', '', ''),
('REQ-3', 'PR', 'PR-2026-00046', '2026-06-14', 'QAQC', 'P3', 'STOCK', 'Tools', 'Pembelian Alat Lab & Termometer', 'Yusril', 3250000.00, 'Approved', 'None', '2026-06-14 09:15:00', '{"user":{"name":"Yusril","role":"User","date":"2026-06-14T09:15:00Z","status":"SUBMITTED","signatureText":"Yusril"},"supervisor":{"name":"Yusril","role":"Supervisor","date":"2026-06-14T09:20:00Z","status":"APPROVED","signatureText":"[e-Signed: Yusril]"},"finance":{"name":"Putri Amalia","role":"Finance","date":"2026-06-14T09:25:00Z","status":"APPROVED","signatureText":"[e-Signed: Putri Amalia]"},"projectManager":{"name":"Rosalia Natalia","role":"Project Manager","date":"2026-06-14T09:30:00Z","status":"APPROVED","signatureText":"[e-Signed: Rosalia Natalia]"}}', 'Penyediaan termometer digital proyek QAQC', '', '', '');

-- Seed Request Items
INSERT INTO `t_request_items` (`id`, `request_id`, `coa`, `part_number`, `description`, `cost_element`, `quantity`, `uom`, `price`, `total`) VALUES
('ITEM-1', 'REQ-1', '610-02-03-001', 'KIP-REG-16', 'Kipas Angin Regency 16 Inch', '612.01.04', 5, 'Unit', 150000.00, 750000.00),
('ITEM-2', 'REQ-1', '610-02-03-002', 'EXT-CORD-5M', 'Stop Kontak Arde 5 Meter', '612.01.04', 5, 'Unit', 49000.00, 245000.00),
('ITEM-3', 'REQ-2', '610-02-06-001', 'ATK-A4-SD', 'Kertas A4 80gr Sinar Dunia', '612.01.04', 309, 'Box', 50000.00, 15450000.00),
('ITEM-4', 'REQ-3', '610-02-05-001', 'TERM-DIG', 'Termometer Digital', '612.01.05', 10, 'Unit', 325000.00, 3250000.00);

-- Seed Audit Trail Log
INSERT INTO `t_audit_log` (`id`, `timestamp`, `user`, `activity`, `module`, `doc_number`, `ip_address`) VALUES
('LOG-1', '2026-06-14 10:00:00', 'Muh Idul Adhan Yusuf', 'Create PR', 'Requests', 'PR-2026-00045', '192.168.10.12'),
('LOG-2', '2026-06-14 10:30:00', 'Mona Asrani', 'Approved at Supervisor', 'Approval', 'PR-2026-00045', '192.168.10.13'),
('LOG-3', '2026-06-14 09:00:00', 'Mona Asrani', 'Create PD', 'Requests', 'PD-2026-00012', '192.168.10.13'),
('LOG-4', '2026-06-14 09:15:00', 'Yusril', 'Create PR', 'Requests', 'PR-2026-00046', '192.168.10.15'),
('LOG-5', '2026-06-14 09:25:00', 'Putri Amalia', 'Approved at Finance', 'Approval', 'PR-2026-00046', '192.168.10.14');


-- ==================== PERFORMANCE DASHBOARD SCHEMA ====================

DROP TABLE IF EXISTS `t_perf_kpis`;
CREATE TABLE `t_perf_kpis` (
  `metric_key` TEXT PRIMARY KEY,
  `metric_label` TEXT NOT NULL,
  `value_actual` REAL NOT NULL,
  `value_target` REAL NOT NULL,
  `unit` TEXT NOT NULL,
  `sparkline_data` TEXT
);

DROP TABLE IF EXISTS `t_perf_pit`;
CREATE TABLE `t_perf_pit` (
  `pit_name` TEXT PRIMARY KEY,
  `target` REAL NOT NULL,
  `actual` REAL NOT NULL
);

DROP TABLE IF EXISTS `t_perf_monthly_trends`;
CREATE TABLE `t_perf_monthly_trends` (
  `month_name` TEXT PRIMARY KEY,
  `target` REAL NOT NULL,
  `actual` REAL NOT NULL
);

DROP TABLE IF EXISTS `t_perf_vessels`;
CREATE TABLE `t_perf_vessels` (
  `id` TEXT PRIMARY KEY,
  `vessel_name` TEXT NOT NULL,
  `destination` TEXT NOT NULL,
  `cargo` REAL NOT NULL,
  `status` TEXT NOT NULL
);

DROP TABLE IF EXISTS `t_perf_stockpiles`;
CREATE TABLE `t_perf_stockpiles` (
  `location` TEXT PRIMARY KEY,
  `volume` REAL NOT NULL,
  `grade_ni` REAL NOT NULL,
  `status` TEXT NOT NULL
);

DROP TABLE IF EXISTS `t_perf_pica`;
CREATE TABLE `t_perf_pica` (
  `id` TEXT PRIMARY KEY,
  `title` TEXT NOT NULL,
  `category` TEXT NOT NULL,
  `owner` TEXT NOT NULL,
  `due_date` TEXT NOT NULL,
  `status` TEXT NOT NULL
);

DROP TABLE IF EXISTS `t_perf_root_causes`;
CREATE TABLE `t_perf_root_causes` (
  `cause_name` TEXT PRIMARY KEY,
  `percentage` REAL NOT NULL
);

DROP TABLE IF EXISTS `t_perf_scorecards`;
CREATE TABLE `t_perf_scorecards` (
  `department_name` TEXT PRIMARY KEY,
  `score` REAL NOT NULL
);

DROP TABLE IF EXISTS `t_perf_alerts`;
CREATE TABLE `t_perf_alerts` (
  `id` TEXT PRIMARY KEY,
  `alert_type` TEXT NOT NULL,
  `message` TEXT NOT NULL,
  `timestamp` TEXT NOT NULL
);

-- ==================== PERFORMANCE SEED DATA ====================

INSERT INTO `t_perf_kpis` (`metric_key`, `metric_label`, `value_actual`, `value_target`, `unit`, `sparkline_data`) VALUES
('ore_production', 'Ore Production', 1250000.0, 1100000.0, 'WMT', '50,55,60,63,68,75,70,82,88,95,90,113.6'),
('ore_shipment', 'Ore Shipment', 950000.0, 900000.0, 'WMT', '45,48,50,52,55,58,62,60,68,72,80,105.6'),
('rkab_utilization', 'RKAB Utilization', 4050000.0, 5000000.0, 'WMT', NULL),
('avg_ni_grade', 'Avg Ni Grade', 1.82, 1.75, '%', '1.72,1.74,1.75,1.73,1.76,1.78,1.79,1.81,1.80,1.83,1.82,104.0'),
('stripping_ratio', 'Stripping Ratio', 1.85, 2.00, '', '2.1,2.05,2.0,1.98,1.95,1.92,1.9,1.88,1.87,1.86,1.85,92.5');

INSERT INTO `t_perf_pit` (`pit_name`, `target`, `actual`) VALUES
('Pit A', 350000.0, 380000.0),
('Pit B', 280000.0, 265000.0),
('Pit C', 420000.0, 470000.0),
('Pit D', 50000.0, 60000.0);

INSERT INTO `t_perf_monthly_trends` (`month_name`, `target`, `actual`) VALUES
('Jan', 550000.0, 600000.0),
('Feb', 680000.0, 750000.0),
('Mar', 800000.0, 980000.0),
('Apr', 900000.0, 1050000.0),
('May', 950000.0, 1100000.0),
('Jun', 1100000.0, 1250000.0);

INSERT INTO `t_perf_vessels` (`id`, `vessel_name`, `destination`, `cargo`, `status`) VALUES
('VES-1', 'MV Ocean Star', 'China', 55000.0, 'Completed'),
('VES-2', 'MV Pacific Glory', 'China', 52000.0, 'Loading'),
('VES-3', 'MV Eastern Crown', 'Korea', 58000.0, 'Waiting'),
('VES-4', 'MV Golden Sea', 'China', 54000.0, 'Sailing');

INSERT INTO `t_perf_stockpiles` (`location`, `volume`, `grade_ni`, `status`) VALUES
('ROM A', 250000.0, 1.80, 'Ready'),
('ROM B', 180000.0, 1.65, 'Ready'),
('Port Stockpile', 120000.0, 1.85, 'Loading'),
('Emergency Stockpile', 50000.0, 1.75, 'Reserve');

INSERT INTO `t_perf_pica` (`id`, `title`, `category`, `owner`, `due_date`, `status`) VALUES
('PICA-1', 'Low Production Pit B', 'Production', 'Production Dept.', '30 Jun 2026', 'Overdue'),
('PICA-2', 'Excavator Breakdown EX210', 'Equipment', 'Engineering', '28 Jun 2026', 'In Progress'),
('PICA-3', 'Vessel Delay MV Ocean Star', 'Shipment', 'Port Operation', '25 Jun 2026', 'Open'),
('PICA-4', 'Grade Deviation ROM A', 'Quality', 'QAQC Dept.', '27 Jun 2026', 'In Progress');

INSERT INTO `t_perf_root_causes` (`cause_name`, `percentage`) VALUES
('Equipment Breakdown', 35.0),
('Weather', 25.0),
('Manpower', 15.0),
('Road Condition', 12.0),
('Logistic', 8.0),
('Others', 5.0);

INSERT INTO `t_perf_scorecards` (`department_name`, `score`) VALUES
('Production', 95.0),
('Engineering', 88.0),
('SHE', 92.0),
('QAQC', 94.0),
('HRGA', 89.0),
('Security', 91.0);

INSERT INTO `t_perf_alerts` (`id`, `alert_type`, `message`, `timestamp`) VALUES
('ALT-1', 'danger', 'RKAB tersisa 19% atau 950,000 WMT', '10:30'),
('ALT-2', 'danger', '4 PICA Overdue perlu segera ditindaklanjuti', '09:15'),
('ALT-3', 'warning', 'Excavator EX210 Breakdown', '08:45'),
('ALT-4', 'warning', 'Shipment MV Ocean Star Delay 8 Jam', '08:30'),
('ALT-5', 'success', 'Average Grade Ni diatas target RKAB', '07:45');


DROP TABLE IF EXISTS `m_fuel_assets`;
CREATE TABLE `m_fuel_assets` (
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

DROP TABLE IF EXISTS `t_fuel_tanks`;
CREATE TABLE `t_fuel_tanks` (
  `id` TEXT PRIMARY KEY,
  `tank_name` TEXT NOT NULL,
  `fuel_type` TEXT NOT NULL,
  `capacity` REAL NOT NULL,
  `current_stock` REAL NOT NULL,
  `status` TEXT NOT NULL
);

DROP TABLE IF EXISTS `t_fuel_stock_in`;
CREATE TABLE `t_fuel_stock_in` (
  `id` TEXT PRIMARY KEY,
  `date` TEXT NOT NULL,
  `doc_number` TEXT NOT NULL,
  `supplier` TEXT NOT NULL,
  `tank` TEXT NOT NULL,
  `qty` REAL NOT NULL,
  `fuel_type` TEXT NOT NULL,
  `operator` TEXT NOT NULL
);

DROP TABLE IF EXISTS `t_fuel_stock_out`;
CREATE TABLE `t_fuel_stock_out` (
  `id` TEXT PRIMARY KEY,
  `date` TEXT NOT NULL,
  `category` TEXT NOT NULL,
  `unit` TEXT NOT NULL,
  `purpose` TEXT NOT NULL,
  `qty` REAL NOT NULL,
  `operator` TEXT NOT NULL
);

DROP TABLE IF EXISTS `t_fuel_alerts`;
CREATE TABLE `t_fuel_alerts` (
  `id` TEXT PRIMARY KEY,
  `level` TEXT NOT NULL,
  `title` TEXT NOT NULL,
  `message` TEXT NOT NULL,
  `timestamp` TEXT NOT NULL
);

-- Seed Fuel Data
INSERT INTO `t_fuel_tanks` (`id`, `tank_name`, `fuel_type`, `capacity`, `current_stock`, `status`) VALUES
('TANK-1', 'TANK 01 (Solar)', 'Solar', 50000.0, 28500.0, 'Normal'),
('TANK-2', 'TANK 02 (Solar)', 'Solar', 50000.0, 16200.0, 'Low'),
('TANK-3', 'TANK 03 (Solar)', 'Solar', 50000.0, 6800.0, 'Critical');

INSERT INTO `t_fuel_stock_in` (`id`, `date`, `doc_number`, `supplier`, `tank`, `qty`, `fuel_type`, `operator`) VALUES
('IN-1', '2026-06-17 08:15', 'SI-260617-001', 'PT Berkah Fuel', 'TANK 01', 20000.0, 'Solar', 'Admin Fuel'),
('IN-2', '2026-06-16 14:20', 'SI-260616-002', 'PT Berkah Fuel', 'TANK 02', 20000.0, 'Solar', 'Admin Fuel'),
('IN-3', '2026-06-15 09:10', 'SI-260615-001', 'PT Berkah Fuel', 'TANK 03', 20000.0, 'Solar', 'Admin Fuel'),
('IN-4', '2026-06-14 10:45', 'SI-260614-001', 'PT Berkah Fuel', 'TANK 01', 20000.0, 'Solar', 'Admin Fuel'),
('IN-5', '2026-06-13 08:30', 'SI-260613-001', 'PT Berkah Fuel', 'TANK 02', 20000.0, 'Solar', 'Admin Fuel');

INSERT INTO `t_fuel_stock_out` (`id`, `date`, `category`, `unit`, `purpose`, `qty`, `operator`) VALUES
('OUT-1', '2026-06-17 07:30', 'LV', 'LV-0234', 'Operational', 55.0, 'Operator LV'),
('OUT-2', '2026-06-17 07:15', 'LV', 'LV-0412', 'Operational', 45.0, 'Operator LV'),
('OUT-3', '2026-06-15 06:50', 'Genset', 'GEN-02 (500 KVA)', 'Operational', 120.0, 'Operator Genset'),
('OUT-4', '2026-06-14 06:35', 'Genset', 'GEN-01 (250 KVA)', 'Operational', 80.0, 'Operator Genset'),
('OUT-5', '2026-06-17 08:20', 'LV', 'LV-0156', 'Operational', 50.0, 'Operator LV');

INSERT INTO `t_fuel_alerts` (`id`, `level`, `title`, `message`, `timestamp`) VALUES
('ALT-F1', 'danger', 'TANK 03', 'Stock level is below minimum', '17/06/2026 08:30'),
('ALT-F2', 'warning', 'High Usage', 'Genset GEN-02 usage is high', '17/06/2026 07:45'),
('ALT-F3', 'info', 'Reconciliation', 'Daily reconciliation required', '17/06/2026 07:00');

INSERT INTO `m_fuel_assets` (`id`, `asset_name`, `type`, `location`, `install_fuel_level`, `current_fuel_level`, `fuel_capacity`, `remaining_fuel`, `fuel_usage_rate`, `efficiency`, `next_refuel_estimate`, `status`) VALUES
('LV-01', 'Pickup', 'LV', 'Pit A', 90.0, 69.0, 45.0, 12.0, 1.8, 0.9, 'Refuel in ~12 Hrs', 'Active'),
('LV-02', 'Pickup', 'LV', 'Pit A', 90.0, 60.0, 45.0, 12.0, 1.9, 1.0, 'Refuel in ~12 Hrs', 'Active'),
('LV-03', 'Pickup', 'LV', 'Pit A', 90.0, 61.0, 45.0, 12.0, 1.6, 0.8, 'Refuel in ~12 Hrs', 'Active'),
('GEN-C4', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 18.0, 2.5, 'Refuel in ~3.5 Days', 'Active'),
('GEN-C5', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 16.8, 2.3, 'Refuel in ~3.5 Days', 'Active'),
('GEN-C6', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 18.1, 2.5, 'Refuel in ~3.5 Days', 'Active'),
('GEN-C7', '500KVA', 'GEN', 'Site B', 85.0, 70.0, 95.0, 33.0, 16.7, 2.2, 'Refuel in ~3.5 Days', 'Low Fuel'),
('GEN-C8', '500KVA', 'GEN', 'Site B', 85.0, 22.0, 95.0, 21.0, 18.5, 2.6, 'Refuel in ~1.2 Days', 'Critical');
