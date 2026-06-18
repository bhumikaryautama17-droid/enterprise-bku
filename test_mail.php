<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Parse SMTP settings dynamically from api.php
$useSmtp = false;
$smtpHost = '';
$smtpPort = 25;
$smtpUser = '';
$smtpPass = '';
$smtpEnc = '';

if (file_exists('api.php')) {
    $apiContent = file_get_contents('api.php');
    if (preg_match('/define\(\s*\'USE_SMTP\'\s*,\s*(true|false)\s*\)/i', $apiContent, $matches)) {
        $useSmtp = strtolower($matches[1]) === 'true';
    }
    if (preg_match('/define\(\s*\'SMTP_HOST\'\s*,\s*\'([^\']+)\'\s*\)/i', $apiContent, $matches)) {
        $smtpHost = $matches[1];
    }
    if (preg_match('/define\(\s*\'SMTP_PORT\'\s*,\s*(\d+)\s*\)/i', $apiContent, $matches)) {
        $smtpPort = (int)$matches[1];
    }
    if (preg_match('/define\(\s*\'SMTP_USER\'\s*,\s*\'([^\']*)\'\s*\)/i', $apiContent, $matches)) {
        $smtpUser = $matches[1];
    }
    if (preg_match('/define\(\s*\'SMTP_PASS\'\s*,\s*\'([^\']*)\'\s*\)/i', $apiContent, $matches)) {
        $smtpPass = $matches[1];
    }
    if (preg_match('/define\(\s*\'SMTP_ENC\'\s*,\s*\'([^\']*)\'\s*\)/i', $apiContent, $matches)) {
        $smtpEnc = $matches[1];
    }
}

$testEmail = isset($_GET['email']) ? trim($_GET['email']) : '';

if (empty($testEmail)) {
    echo '<div style="font-family: Arial; padding: 20px; max-width: 550px; margin: 50px auto; border: 1px solid #ddd; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.05);">
        <h3 style="color:#2e7d32; margin-top:0;">E-Approval Test Email Utility</h3>
        <p style="font-size:13px; color:#666;">Gunakan form ini untuk menguji apakah fungsi pengiriman email pada hosting Anda aktif dan berjalan dengan benar.</p>
        
        <div style="background:#f9f9f9; border-left:4px solid #2e7d32; padding:10px; font-size:12px; margin:15px 0; color:#444;">
            <strong>Konfigurasi Terdeteksi di api.php:</strong><br>
            • Mode Pengiriman: ' . ($useSmtp ? '<strong style="color:blue;">SMTP (Aktif)</strong>' : '<strong style="color:green;">PHP mail() (Bawaan)</strong>') . '<br>
            • SMTP Host: ' . htmlspecialchars($smtpHost ?: '-') . '<br>
            • SMTP Port: ' . htmlspecialchars($smtpPort ?: '-') . '<br>
            • SMTP User: ' . htmlspecialchars($smtpUser ?: '-') . '<br>
            • Enkripsi: ' . htmlspecialchars($smtpEnc ?: 'none') . '
        </div>

        <form method="GET" style="margin-top:20px;">
            <label style="font-size:12px; font-weight:bold; display:block; margin-bottom:5px;">Email Penerima:</label>
            <input type="email" name="email" required style="padding:8px; width:100%; border:1px solid #ccc; border-radius:4px; box-sizing:border-box; margin-bottom:15px;" placeholder="Masukkan email aktif Anda..."> 
            <button type="submit" style="padding:10px 15px; background-color:#2e7d32; color:#fff; border:none; border-radius:4px; font-weight:bold; cursor:pointer; width:100%;">Kirim Test Email</button>
        </form>
    </div>';
    exit;
}

$host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : 'bis.co.id';
$cleanHost = $host;
if (preg_match('/localhost|127\.0\.0\.1|^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/', $cleanHost) || strpos($cleanHost, '.') === false) {
    $cleanHost = 'bis.co.id';
}
$fromEmail = "noreply@" . $cleanHost;

$subject = "Test E-Approval Mail System";
$htmlContent = '
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
    <div style="max-width: 600px; border: 1px solid #eee; padding: 20px; border-radius: 8px; border-top: 4px solid #2e7d32;">
        <h2 style="color:#2e7d32;">Koneksi Berhasil!</h2>
        <p>Jika Anda menerima pesan ini, sistem pengiriman email real-time dari aplikasi E-Approval di server hosting Anda telah berjalan lancar sekali dan siap digunakan.</p>
        <p style="font-size:12px; color:#888;">Dikirim secara otomatis pada: ' . date('Y-m-d H:i:s') . '</p>
    </div>
</body>
</html>';

echo '<div style="font-family: Arial; padding: 20px; max-width: 600px; margin: 30px auto; border: 1px solid #ddd; border-radius: 8px;">';
echo '<h3 style="margin-top:0;">Hasil Pengujian Pengiriman Email:</h3>';
echo "Mengirim email uji coba ke: <strong>" . htmlspecialchars($testEmail) . "</strong>...<br><br>";

if ($useSmtp) {
    echo "Metode: <strong>SMTP Socket Connection</strong><br>";
    try {
        $sent = testSMTPSend($testEmail, $subject, $htmlContent, $smtpHost, $smtpPort, $smtpUser, $smtpPass, $smtpEnc);
        echo "<div style='background-color:#e8f5e9; color:#2e7d32; padding:15px; border-radius:4px; font-weight:bold; margin:15px 0;'>
            ✔️ BERHASIL! Pengiriman SMTP sukses dilakukan tanpa kendala.
        </div>";
    } catch (Exception $e) {
        $sent = false;
        echo "<div style='background-color:#ffebee; color:#c62828; padding:15px; border-radius:4px; font-weight:bold; margin:15px 0;'>
            ❌ GAGAL! SMTP error: " . htmlspecialchars($e->getMessage()) . "
        </div>";
    }
} else {
    echo "Metode: <strong>PHP mail() Function</strong><br>";
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
    $headers .= "From: E-Approval Test <" . $fromEmail . ">\r\n";
    $headers .= "Reply-To: " . $fromEmail . "\r\n";
    $headers .= "X-Mailer: PHP/" . phpversion();

    $sent = mail($testEmail, $subject, $htmlContent, $headers, "-f " . $fromEmail);

    if ($sent) {
        echo "<div style='background-color:#e8f5e9; color:#2e7d32; padding:15px; border-radius:4px; font-weight:bold; margin:15px 0;'>
            ✔️ BERHASIL! Fungsi PHP mail() mengembalikan nilai TRUE.
        </div>";
    } else {
        echo "<div style='background-color:#ffebee; color:#c62828; padding:15px; border-radius:4px; font-weight:bold; margin:15px 0;'>
            ❌ GAGAL! Fungsi PHP mail() mengembalikan nilai FALSE.
        </div>";
    }
}

if ($sent) {
    echo "<p style='font-size:13px; color:#555;'>Silakan periksa folder <strong>Inbox (Masuk)</strong> atau folder <strong>Spam/Junk (Sampah)</strong> pada email penerima Anda beberapa saat lagi.</p>";
} else {
    echo "<p style='font-size:13px; color:#555;'>Silakan periksa pengaturan email server Anda. Jika Anda menggunakan shared hosting, kami sarankan mengubah pengaturan di <strong>api.php</strong> untuk menggunakan <strong>SMTP (USE_SMTP = true)</strong> menggunakan akun email cPanel resmi Anda.</p>";
}

echo '<br><a href="test_mail.php" style="color:#2e7d32; text-decoration:none; font-weight:bold;">← Kembali ke form pengujian</a>';
echo '</div>';

function testSMTPSend($to, $subject, $htmlContent, $host, $port, $username, $password, $encryption) {
    $senderEmail = $username ?: 'noreply@' . $_SERVER['HTTP_HOST'];
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Subject: " . $subject . "\r\n";
    $headers .= "To: " . $to . "\r\n";
    $headers .= "From: E-Approval Test <" . $senderEmail . ">\r\n";
    $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
    
    $socketHost = $host;
    if ($encryption === 'ssl') {
        $socketHost = 'ssl://' . $host;
    }
    
    $socket = @fsockopen($socketHost, $port, $errno, $errstr, 15);
    if (!$socket) {
        throw new Exception("Koneksi gagal: $errstr ($errno)");
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
            throw new Exception("Autentikasi gagal: " . $response);
        }
    }
    
    fwrite($socket, "MAIL FROM:<" . $senderEmail . ">\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, "RCPT TO:<" . $to . ">\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, "DATA\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, $headers . "\r\n" . $htmlContent . "\r\n.\r\n");
    $response = fgets($socket, 512);
    
    fwrite($socket, "QUIT\r\n");
    fclose($socket);
    return true;
}
?>
