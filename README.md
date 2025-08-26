# WP + WPGraphQL + Latest Posts Grid (Docker)

## Prereqs
- Docker Desktop (includes docker compose)
- Windows PowerShell (this repo ships a PowerShell setup script)

## Quick start
git clone <this-repo>
cd <this-repo>
docker compose up -d --build
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1

Open: http://localhost:8080
Admin: http://localhost:8080/wp-admin  (admin / AdminPass123!)
GraphQL: POST http://localhost:8080/graphql

## Notes
- The plugin code lives at `wp-content/plugins/latest-posts-grid/`.
- Its compiled assets in `/build` are committed so no Node is required.
- To develop the block, run `npm install` + `npm run build` inside the plugin folder and reload.
