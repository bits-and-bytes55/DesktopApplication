# Hostinger VPS Backend Deployment Guide

This document records the deployment process used for the MudPro backend and explains how to deploy another backend on the same Hostinger VPS.

## Current MudPro Backend Setup

GitHub repository:

```txt
https://github.com/bits-and-bytes55/DesktopApplication.git
```

Backend folder inside repo:

```txt
Mud-pro-Backend
```

VPS project path:

```txt
/var/www/DesktopApplication
```

Backend runtime path:

```txt
/var/www/DesktopApplication/Mud-pro-Backend
```

Backend PM2 process name:

```txt
mudpro-backend
```

Backend port:

```txt
3000
```

Public backend URL:

```txt
http://213.210.37.129
```

Note: `Cannot GET /` on `http://213.210.37.129` is normal if the backend does not define a `/` route. It still confirms that Nginx is reaching the Node.js server.

## Manual Deployment Steps

SSH into the VPS:

```bash
ssh root@213.210.37.129
```

Go to the backend folder:

```bash
cd /var/www/DesktopApplication/Mud-pro-Backend
```

Install dependencies:

```bash
npm install
```

Create or edit the environment file:

```bash
nano .env
```

Example `.env` format:

```env
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
MONGO_URI="your_mongodb_connection_string"
PORT=3000
```

Start the backend with PM2:

```bash
pm2 start server.js --name mudpro-backend
pm2 save
```

If the process already exists, restart it:

```bash
pm2 restart mudpro-backend
pm2 save
```

Check process status:

```bash
pm2 status
```

Check logs:

```bash
pm2 logs mudpro-backend
```

Local server test from inside the VPS:

```bash
curl http://localhost:3000
```

Public server test:

```bash
curl http://213.210.37.129
```

## Nginx Reverse Proxy

Nginx forwards public HTTP traffic to the backend running on port `3000`.

Config file:

```txt
/etc/nginx/sites-available/mudpro-backend
```

Example config:

```nginx
server {
    listen 80;
    server_name 213.210.37.129;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable and restart Nginx:

```bash
ln -s /etc/nginx/sites-available/mudpro-backend /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

If the symlink already exists, the `ln -s` command may show a file-exists message. That is fine.

## Auto Deploy From GitHub

GitHub Actions deploys the backend automatically whenever code is pushed to the `main` branch.

Repository secrets added in GitHub:

```txt
VPS_HOST=213.210.37.129
VPS_USER=root
VPS_PASSWORD=<vps-password>
APP_DIR=/var/www/DesktopApplication
```

GitHub secret path:

```txt
Repository -> Settings -> Secrets and variables -> Actions -> Repository secrets
```

Workflow file:

```txt
.github/workflows/deploy-backend.yml
```

Workflow content:

```yaml
name: Deploy MudPro Backend

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Deploy backend to Hostinger VPS
        uses: appleboy/ssh-action@v1.2.0
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          password: ${{ secrets.VPS_PASSWORD }}
          script: |
            cd ${{ secrets.APP_DIR }}
            git pull origin main

            cd Mud-pro-Backend
            npm install --omit=dev

            pm2 restart mudpro-backend || pm2 start server.js --name mudpro-backend
            pm2 save

            systemctl reload nginx
```

Auto deploy flow:

```txt
Push to main
-> GitHub Actions starts
-> SSH login to VPS
-> git pull origin main
-> npm install --omit=dev
-> PM2 restart
-> Nginx reload
```

Verify after each deployment:

```bash
cd /var/www/DesktopApplication
git log -1 --oneline
pm2 status
curl http://213.210.37.129
```

## Deploying Another Backend On The Same VPS

Each backend on the same VPS must have:

```txt
1. Separate folder
2. Separate port
3. Separate PM2 process name
4. Separate Nginx server block or path rule
5. Separate environment file
```

Example second backend:

```txt
Repo: https://github.com/example/another-backend.git
Folder: /var/www/another-backend
Port: 3001
PM2 name: another-backend
Public URL with domain: api2.yourdomain.com
```

Clone the second backend:

```bash
cd /var/www
git clone https://github.com/example/another-backend.git another-backend
cd another-backend
npm install
nano .env
```

Example `.env`:

```env
PORT=3001
MONGO_URI="second_backend_mongodb_uri"
NODE_ENV=production
```

Start with PM2:

```bash
pm2 start server.js --name another-backend
pm2 save
```

Create Nginx config:

```bash
nano /etc/nginx/sites-available/another-backend
```

If using a domain or subdomain:

```nginx
server {
    listen 80;
    server_name api2.yourdomain.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable it:

```bash
ln -s /etc/nginx/sites-available/another-backend /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

Test it:

```bash
curl http://localhost:3001
curl http://api2.yourdomain.com
```

## Deploying Another Backend Without A Domain

If there is no domain, using the same IP for multiple backends is not clean unless they are separated by URL path.

Example:

```txt
http://213.210.37.129/mudpro
http://213.210.37.129/another
```

Nginx path-based config example:

```nginx
server {
    listen 80;
    server_name 213.210.37.129;

    location /mudpro/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    location /another/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
```

Important: path-based hosting can break APIs if the backend assumes routes start from `/api`. The better approach is to use separate subdomains:

```txt
api.yourdomain.com
api2.yourdomain.com
```

## Auto Deploy For Another Backend

Add secrets in the second backend GitHub repo:

```txt
VPS_HOST=213.210.37.129
VPS_USER=root
VPS_PASSWORD=<vps-password>
APP_DIR=/var/www/another-backend
```

Workflow:

```yaml
name: Deploy Another Backend

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Deploy second backend to VPS
        uses: appleboy/ssh-action@v1.2.0
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          password: ${{ secrets.VPS_PASSWORD }}
          script: |
            cd ${{ secrets.APP_DIR }}
            git pull origin main
            npm install --omit=dev
            pm2 restart another-backend || pm2 start server.js --name another-backend
            pm2 save
            systemctl reload nginx
```

If the second backend is inside a monorepo, set `APP_DIR` to the repo root and then `cd` into the backend folder in the script.

## Useful Commands

List PM2 apps:

```bash
pm2 status
```

Restart one backend:

```bash
pm2 restart mudpro-backend
```

View logs:

```bash
pm2 logs mudpro-backend
```

Stop duplicate PM2 process by id:

```bash
pm2 delete <id>
pm2 save
```

Check Nginx config:

```bash
nginx -t
```

Reload Nginx:

```bash
systemctl reload nginx
```

Restart Nginx:

```bash
systemctl restart nginx
```

Check latest deployed commit:

```bash
cd /var/www/DesktopApplication
git log -1 --oneline
```

## Security Notes

Do not commit `.env` files to GitHub.

Do not paste production secrets in chat, tickets, screenshots, or public places.

If a secret is exposed, rotate it immediately:

```txt
1. Change MongoDB Atlas database user password.
2. Regenerate Cloudinary API secret if needed.
3. Update the VPS .env file.
4. Restart PM2 process.
```

Restart after changing `.env`:

```bash
pm2 restart mudpro-backend
```

For better long-term security, replace password-based GitHub Actions SSH login with SSH-key based deployment.
