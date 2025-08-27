# WP + WPGraphQL + Latest Posts Grid (Docker)

Spin up a WordPress dev stack with **MySQL + PHP-FPM + Nginx**, auto-install **WPGraphQL**, activate the **Latest Posts Grid** block, create a **Home** page with the block inserted, and seed demo posts (with featured images).

---

## Prerequisites
- **Docker Desktop** (includes Docker Compose)
- **Windows PowerShell** (this repo ships PowerShell scripts)
  - If PowerShell blocks scripts, use: `-ExecutionPolicy Bypass`

---

## Quick Start (one command)

```powershell
git clone <this-repo>
cd <this-repo>
.\scripts\bootstrap.ps1   
