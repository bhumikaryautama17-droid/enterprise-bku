# deploy_to_github.py
# Auto-deployer script for PT. Bhumi Karya Utama Workflow System
# This script has zero dependencies (uses built-in urllib) and uploads your files directly to GitHub.

import os
import json
import base64
import urllib.request
import urllib.error

def upload_file_to_github(owner, repo, branch, token, repo_path, local_path):
    try:
        with open(local_path, 'rb') as f:
            content = f.read()
    except Exception as e:
        print(f"[-] Gagal membaca file lokal {local_path}: {e}")
        return False

    # Base64 encode content
    content_b64 = base64.b64encode(content).decode('utf-8')

    # API Endpoint URL
    url = f"https://api.github.com/repos/{owner}/{repo}/contents/{repo_path}?ref={branch}"

    # Check if file already exists to get its SHA (required for updates)
    sha = None
    req = urllib.request.Request(url)
    req.add_header('Authorization', f'token {token}')
    req.add_header('Accept', 'application/vnd.github.v3+json')
    req.add_header('User-Agent', 'Python-Deployer')
    
    try:
        with urllib.request.urlopen(req) as res:
            data = json.loads(res.read().decode('utf-8'))
            sha = data.get('sha')
    except urllib.error.HTTPError as e:
        if e.code != 404:
            print(f"[-] Gagal memeriksa status file {repo_path} di GitHub: HTTP {e.code} {e.reason}")
            return False
    except Exception as e:
        print(f"[-] Gagal memeriksa status file {repo_path} di GitHub: {e}")
        return False

    # Prepare Commit Payload
    payload = {
        "message": f"Upload {repo_path} via Python Auto-Deployer",
        "content": content_b64,
        "branch": branch
    }
    if sha:
        payload["sha"] = sha

    # Send PUT request to create/update file
    req_put = urllib.request.Request(url, method='PUT')
    req_put.add_header('Authorization', f'token {token}')
    req_put.add_header('Content-Type', 'application/json')
    req_put.add_header('Accept', 'application/vnd.github.v3+json')
    req_put.add_header('User-Agent', 'Python-Deployer')
    
    try:
        body = json.dumps(payload).encode('utf-8')
        with urllib.request.urlopen(req_put, data=body) as res:
            print(f"[+] Berhasil mengunggah/memperbarui: {repo_path}")
            return True
    except urllib.error.HTTPError as e:
        try:
            err_msg = json.loads(e.read().decode('utf-8')).get('message', '')
        except:
            err_msg = e.reason
        print(f"[-] Gagal mengunggah {repo_path}: HTTP {e.code} - {err_msg}")
        return False
    except Exception as e:
        print(f"[-] Gagal mengunggah {repo_path}: {e}")
        return False

def main():
    print("="*60)
    print("      GITHUB AUTO-DEPLOYER - PT. BHUMI KARYA UTAMA      ")
    print("="*60)
    
    owner = input("Masukkan GitHub Owner (Username/Organisasi): ").strip()
    repo = input("Masukkan GitHub Repository Name: ").strip()
    branch = input("Masukkan GitHub Branch [default: main]: ").strip() or "main"
    token = input("Masukkan GitHub Personal Access Token (PAT): ").strip()

    if not owner or not repo or not token:
        print("[-] Error: Owner, Repository, dan Token wajib diisi!")
        input("\nTekan Enter untuk keluar...")
        return

    # Resolve local dist directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    dist_dir = os.path.join(current_dir, "dist_github_db")
    if not os.path.exists(dist_dir):
        # Fallback if script is run from inside dist_github_db
        if os.path.exists(os.path.join(current_dir, "index.html")) and os.path.exists(os.path.join(current_dir, "db")):
            dist_dir = current_dir
        else:
            print("[-] Folder 'dist_github_db' tidak ditemukan. Pastikan script ini dijalankan di dalam direktori proyek Anda.")
            input("\nTekan Enter untuk keluar...")
            return

    print("\nLokasi Database JSON di Repositori Anda:")
    print("1. Di dalam folder 'db/' (Direkomendasikan: db/m_users.json, dll.)")
    print("2. Langsung di root folder (Contoh: m_users.json, dll.)")
    choice = input("Pilih lokasi database [1 atau 2, default: 1]: ").strip() or "1"
    use_db_folder = (choice == "1")

    print(f"\n[*] Memulai proses unggah file dari: {dist_dir}")
    print(f"[*] Repositori target: {owner}/{repo} (branch: {branch})")
    print("-" * 60)

    success_count = 0
    fail_count = 0

    for root, dirs, files in os.walk(dist_dir):
        # Skip unnecessary folders
        if ".git" in root or "__pycache__" in root:
            continue
            
        for file in files:
            # Skip python scripts from being uploaded to production repository
            if file == "deploy_to_github.py" or file.endswith(".py"):
                continue
                
            local_file_path = os.path.join(root, file)
            # Calculate relative path from dist_dir
            rel_path = os.path.relpath(local_file_path, dist_dir)
            
            # Normalize path separator for GitHub (always forward slash)
            repo_path = rel_path.replace("\\", "/")
            
            # If the database files should go to root instead of db/
            if not use_db_folder and repo_path.startswith("db/"):
                repo_path = repo_path[3:]  # Remove "db/" prefix
                
            print(f"[*] Mengunggah {repo_path}...")
            if upload_file_to_github(owner, repo, branch, token, repo_path, local_file_path):
                success_count += 1
            else:
                fail_count += 1

    print("-" * 60)
    print("PROSES DEPLOY SELESAI")
    print(f"[+] Berhasil diunggah: {success_count} file")
    if fail_count > 0:
        print(f"[-] Gagal diunggah: {fail_count} file (Periksa error di atas)")
    else:
        print("[+] Semua file berhasil dideploy secara lengkap!")
    
    input("\nTekan Enter untuk keluar...")

if __name__ == "__main__":
    main()
