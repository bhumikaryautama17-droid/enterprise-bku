<?php
// config.php
// Database Credentials for PT. Bhumi Karya Utama Workflow System

define('DB_HOST', 'localhost');      // Biasanya 'localhost' di cPanel
define('DB_NAME', 'nama_database');  // Ganti dengan nama database Anda
define('DB_USER', 'username_db');    // Ganti dengan username database Anda
define('DB_PASS', 'password_db');    // Ganti dengan password database Anda

// Aktifkan reporting error jika dalam mode development (set false di production)
define('DEV_MODE', true);

if (DEV_MODE) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}
?>
