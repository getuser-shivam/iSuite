@echo off
REM PocketBase Setup Script for Windows - Completely Free Backend Solution
REM This script sets up PocketBase with free hosting options

setlocal enabledelayedexpansion

echo.
echo ========================================
echo 🚀 PocketBase Setup - Free Backend
echo ========================================
echo.

REM Configuration variables
set POCKETBASE_VERSION=0.23.2
set POCKETBASE_DIR=pocketbase
set POCKETBASE_URL=https://github.com/pocketbase/pocketbase/releases/download/v%POCKETBASE_VERSION%/pocketbase_%POCKETBASE_VERSION%_windows_amd64.zip

REM Create pocketbase directory
echo 📁 Creating PocketBase directory...
if not exist %POCKETBASE_DIR% mkdir %POCKETBASE_DIR%
cd %POCKETBASE_DIR%

REM Check if curl is available
where curl >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ Error: curl is not installed or not in PATH
    echo Please install curl or use Git Bash with the Linux script
    pause
    exit /b 1
)

REM Download PocketBase
echo ⬇️  Downloading PocketBase v%POCKETBASE_VERSION%...
curl -sL %POCKETBASE_URL% -o pocketbase.zip
if %ERRORLEVEL% neq 0 (
    echo ❌ Error downloading PocketBase
    pause
    exit /b 1
)

REM Extract PocketBase
echo 📦 Extracting PocketBase...
powershell -Command "Expand-Archive -Path 'pocketbase.zip' -Force"
if %ERRORLEVEL% neq 0 (
    echo ❌ Error extracting PocketBase
    pause
    exit /b 1
)

REM Clean up zip file
del pocketbase.zip

REM Create necessary directories
echo 📂 Creating data directories...
if not exist data mkdir data
if not exist logs mkdir logs
if not exist storage mkdir storage

REM Create initial configuration
echo ⚙️  Creating initial configuration...
echo { > pb_config.json
echo   "logs": { >> pb_config.json
echo     "console": { >> pb_config.json
echo       "level": "info" >> pb_config.json
echo     }, >> pb_config.json
echo     "file": { >> pb_config.json
echo       "level": "info", >> pb_config.json
echo       "path": "logs\pocketbase.log", >> pb_config.json
echo       "maxSize": 10, >> pb_config.json
echo       "maxAge": 7 >> pb_config.json
echo     } >> pb_config.json
echo   }, >> pb_config.json
echo   "api": { >> pb_config.json
echo     "cors": { >> pb_config.json
echo       "enabled": true, >> pb_config.json
echo       "allowedOrigins": ["http://localhost:3000", "http://localhost:8080", "http://localhost:3000"], >> pb_config.json
echo       "allowedMethods": ["GET", "POST", "PUT", "DELETE", "PATCH"], >> pb_config.json
echo       "allowedHeaders": ["Content-Type", "Authorization", "X-Requested-With"] >> pb_config.json
echo     } >> pb_config.json
echo   }, >> pb_config.json
echo   "security": { >> pb_config.json
echo     "rateLimit": { >> pb_config.json
echo       "enabled": true, >> pb_config.json
echo       "max": 100, >> pb_config.json
echo       "duration": "1m" >> pb_config.json
echo     } >> pb_config.json
echo   } >> pb_config.json
echo } >> pb_config.json

REM Create startup script
echo 📝 Creating startup script...
echo @echo off > start.bat
echo echo 🚀 Starting PocketBase... >> start.bat
echo pocketbase.exe serve --http=0.0.0.0:8090 >> start.bat
echo pause >> start.bat

REM Create admin user script
echo 👤 Creating admin user setup script...
echo @echo off > setup_admin.bat
echo echo 👤 Setting up admin user... >> setup_admin.bat
echo echo Please visit http://localhost:8090/_/ to create your admin account >> setup_admin.bat
echo echo Press Enter to continue after creating admin account... >> setup_admin.bat
echo pause >> setup_admin.bat

REM Create deployment scripts
echo 🌐 Creating deployment scripts...

REM Railway deployment
echo 🚂 Creating Railway deployment script...
echo @echo off > deploy_railway.bat
echo echo 🚂 Deploying to Railway... >> deploy_railway.bat
echo where npm >nul 2>nul >> deploy_railway.bat
echo if %%ERRORLEVEL%% neq 0 ( >> deploy_railway.bat
echo   echo Installing Node.js and npm... >> deploy_railway.bat
echo   echo Please install Node.js from https://nodejs.org/ >> deploy_railway.bat
echo   pause >> deploy_railway.bat
echo   exit /b 1 >> deploy_railway.bat
echo ^) >> deploy_railway.bat
echo npm install -g @railway/cli >> deploy_railway.bat
echo echo Creating Railway configuration... >> deploy_railway.bat
echo { > railway.json
echo   "build": { >> railway.json
echo     "builder": "NIXPACKS" >> railway.json
echo   }, >> railway.json
echo   "deploy": { >> railway.json
echo     "startCommand": "./pocketbase serve --http=0.0.0.0:%%PORT%%", >> railway.json
echo     "healthcheckPath": "/api/health" >> railway.json
echo   } >> railway.json
echo ^} >> railway.json
echo echo Creating nixpacks configuration... >> deploy_railway.bat
echo [[phases]] > nixpacks.toml
echo name = "setup" >> nixpacks.toml
echo nixPkgs = ["unzip"] >> nixpacks.toml
echo. >> nixpacks.toml
echo [[phases]] >> nixpacks.toml
echo name = "build" >> nixpacks.toml
echo cmds = ["wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip", "unzip pocketbase_linux_amd64.zip", "chmod +x pocketbase"] >> nixpacks.toml
echo. >> nixpacks.toml
echo [[phases]] >> nixpacks.toml
echo name = "start" >> nixpacks.toml
echo cmd = "./pocketbase serve --http=0.0.0.0:%%PORT%%" >> nixpacks.toml
echo railway login >> deploy_railway.bat
echo railway init >> deploy_railway.bat
echo railway up >> deploy_railway.bat
echo echo ✅ Railway deployment complete! >> deploy_railway.bat
echo pause >> deploy_railway.bat

REM Render deployment
echo 🎨 Creating Render deployment script...
echo @echo off > deploy_render.bat
echo echo 🎨 Deploying to Render... >> deploy_render.bat
echo services: > render.yaml
echo   - type: web >> render.yaml
echo     name: pocketbase-app >> render.yaml
echo     runtime: docker >> render.yaml
echo     dockerfilePath: ./Dockerfile >> render.yaml
echo     envVars: >> render.yaml
echo       - key: PORT >> render.yaml
echo         value: 10000 >> render.yaml
echo FROM alpine:latest > Dockerfile
echo. >> Dockerfile
echo RUN apk add --no-cache unzip wget >> Dockerfile
echo. >> Dockerfile
echo WORKDIR /app >> Dockerfile
echo. >> Dockerfile
echo RUN wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip ^&^& \ >> Dockerfile
echo     unzip pocketbase_linux_amd64.zip ^&^& \ >> Dockerfile
echo     chmod +x pocketbase ^&^& \ >> Dockerfile
echo     rm pocketbase_linux_amd64.zip >> Dockerfile
echo. >> Dockerfile
echo EXPOSE 10000 >> Dockerfile
echo. >> Dockerfile
echo CMD ["./pocketbase", "serve", "--http=0.0.0.0:10000"] >> Dockerfile
echo echo ✅ Render configuration created! >> deploy_render.bat
echo echo Upload these files to your Render repository to deploy. >> deploy_render.bat
echo pause >> deploy_render.bat

REM Fly.io deployment
echo ✈️  Creating Fly.io deployment script...
echo @echo off > deploy_flyio.bat
echo echo ✈️  Deploying to Fly.io... >> deploy_flyio.bat
echo where flyctl >nul 2>nul >> deploy_flyio.bat
echo if %%ERRORLEVEL%% neq 0 ( >> deploy_flyio.bat
echo   echo Installing Fly.io CLI... >> deploy_flyio.bat
echo   curl -L https://fly.io/install.sh ^| sh >> deploy_flyio.bat
echo ^) >> deploy_flyio.bat
echo app = "your-pocketbase-app" > fly.toml
echo. >> fly.toml
echo [[services]] >> fly.toml
echo   http_checks = [] >> fly.toml
echo   internal_port = 8090 >> fly.toml
echo   protocol = "tcp" >> fly.toml
echo. >> fly.toml
echo   [services.concurrency] >> fly.toml
echo     hard_limit = 25 >> fly.toml
echo     soft_limit = 20 >> fly.toml
echo. >> fly.toml
echo   [[services.ports]] >> fly.toml
echo     handlers = ["http"] >> fly.toml
echo     port = 80 >> fly.toml
echo. >> fly.toml
echo   [[services.ports]] >> fly.toml
echo     handlers = ["tls", "http"] >> fly.toml
echo     port = 443 >> fly.toml
echo. >> fly.toml
echo   [[services.tcp_checks]] >> fly.toml
echo     grace_period = "1s" >> fly.toml
echo     interval = "15s" >> fly.toml
echo     restart_limit = 0 >> fly.toml
echo     timeout = "2s" >> fly.toml
echo. >> fly.toml
echo [deploy] >> fly.toml
echo   strategy = "immediate" >> fly.toml
echo FROM alpine:latest > Dockerfile
echo. >> Dockerfile
echo RUN apk add --no-cache unzip wget >> Dockerfile
echo. >> Dockerfile
echo WORKDIR /app >> Dockerfile
echo. >> Dockerfile
echo RUN wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip ^&^& \ >> Dockerfile
echo     unzip pocketbase_linux_amd64.zip ^&^& \ >> Dockerfile
echo     chmod +x pocketbase ^&^& \ >> Dockerfile
echo     rm pocketbase_linux_amd64.zip >> Dockerfile
echo. >> Dockerfile
echo EXPOSE 8090 >> Dockerfile
echo. >> Dockerfile
echo CMD ["./pocketbase", "serve", "--http=0.0.0.0:8090"] >> Dockerfile
echo flyctl launch >> deploy_flyio.bat
echo echo ✅ Fly.io deployment complete! >> deploy_flyio.bat
echo pause >> deploy_flyio.bat

REM Create environment file
echo 🔧 Creating environment configuration...
echo # PocketBase Configuration > .env
echo POCKETBASE_HOST=localhost >> .env
echo POCKETBASE_PORT=8090 >> .env
echo POCKETBASE_URL=http://localhost:8090 >> .env
echo. >> .env
echo # Database Configuration >> .env
echo DATABASE_PATH=data\pocketbase.db >> .env
echo DATABASE_BACKUP_ENABLED=true >> .env
echo. >> .env
echo # Authentication >> .env
echo JWT_SECRET=your-secret-key-change-this-in-production >> .env
echo. >> .env
echo # Email Configuration ^(choose one^) >> .env
echo RESEND_API_KEY=your_resend_api_key >> .env
echo SENDGRID_API_KEY=your_sendgrid_api_key >> .env
echo MAILGUN_API_KEY=your_mailgun_api_key >> .env
echo. >> .env
echo # OAuth Configuration ^(optional^) >> .env
echo GOOGLE_CLIENT_ID=your_google_client_id >> .env
echo GOOGLE_CLIENT_SECRET=your_google_client_secret >> .env
echo GITHUB_CLIENT_ID=your_github_client_id >> .env
echo GITHUB_CLIENT_SECRET=your_github_client_secret >> .env
echo. >> .env
echo # Storage Configuration ^(optional^) >> .env
echo SUPABASE_URL=your_supabase_url >> .env
echo SUPABASE_ANON_KEY=your_supabase_anon_key >> .env
echo CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name >> .env
echo CLOUDINARY_API_KEY=your_cloudinary_api_key >> .env
echo CLOUDINARY_API_SECRET=your_cloudinary_api_secret >> .env
echo. >> .env
echo # Hosting Configuration ^(optional^) >> .env
echo RAILWAY_API_KEY=your_railway_api_key >> .env
echo RENDER_API_KEY=your_render_api_key >> .env
echo FLY_API_KEY=your_fly_api_key >> .env
echo DIGITALOCEAN_API_KEY=your_digitalocean_api_key >> .env
echo HEROKU_API_KEY=your_heroku_api_key >> .env

REM Create README
echo 📖 Creating README...
echo # PocketBase Setup - Free Backend Solution > README.md
echo. >> README.md
echo ## 🚀 Quick Start >> README.md
echo. >> README.md
echo 1. **Start PocketBase locally:** >> README.md
echo    ```cmd >> README.md
echo    start.bat >> README.md
echo    ``` >> README.md
echo. >> README.md
echo 2. **Setup admin account:** >> README.md
echo    - Open http://localhost:8090/_/ >> README.md
echo    - Create your admin account >> README.md
echo    - Run `setup_admin.bat` when done >> README.md
echo. >> README.md
echo 3. **Configure your app:** >> README.md
echo    - Copy `.env` file to your Flutter app >> README.md
echo    - Update the configuration as needed >> README.md
echo. >> README.md
echo ## 🌐 Free Deployment Options >> README.md
echo. >> README.md
echo ### Railway ^($0/month^) >> README.md
echo ```cmd >> README.md
echo deploy_railway.bat >> README.md
echo ``` >> README.md
echo - Free tier: 500 hours/month >> README.md
echo - Custom domain: Available >> README.md
echo - SSL: Included >> README.md
echo. >> README.md
echo ### Render ^($0/month^) >> README.md
echo ```cmd >> README.md
echo deploy_render.bat >> README.md
echo ``` >> README.md
echo - Free tier: 750 hours/month >> README.md
echo - Custom domain: Available >> README.md
echo - SSL: Included >> README.md
echo. >> README.md
echo ### Fly.io ^(Free allowance^) >> README.md
echo ```cmd >> README.md
echo deploy_flyio.bat >> README.md
echo ``` >> README.md
echo - Free allowance: 160 hours/month >> README.md
echo - Custom domain: Available >> README.md
echo - SSL: Included >> README.md
echo. >> README.md
echo ### Self-Hosted ^(Completely Free^) >> README.md
echo - Your own server/VPS >> README.md
echo - Docker deployment >> README.md
echo - Full control >> README.md
echo. >> README.md
echo ## 📁 Directory Structure >> README.md
echo. >> README.md
echo ``` >> README.md
echo pocketbase/ >> README.md
echo ├── pocketbase.exe          # PocketBase executable >> README.md
echo ├── data/              # Database files >> README.md
echo ├── logs/              # Log files >> README.md
echo ├── storage/           # File storage >> README.md
echo ├── pb_config.json     # PocketBase configuration >> README.md
echo ├── start.bat          # Startup script >> README.md
echo ├── setup_admin.bat    # Admin setup script >> README.md
echo ├── deploy_railway.bat # Railway deployment >> README.md
echo ├── deploy_render.bat  # Render deployment >> README.md
echo ├── deploy_flyio.bat   # Fly.io deployment >> README.md
echo ├── .env               # Environment variables >> README.md
echo └── README.md          # This file >> README.md
echo ``` >> README.md
echo. >> README.md
echo ## 🔧 Configuration >> README.md
echo. >> README.md
echo All configuration is parameterized through environment variables. See `.env` file for available options. >> README.md
echo. >> README.md
echo ## 📚 Documentation >> README.md
echo. >> README.md
echo - [PocketBase Documentation](https://pocketbase.io/docs/) >> README.md
echo - [Flutter Integration](https://pocketbase.io/docs/flutter/) >> README.md
echo - [API Reference](https://pocketbase.io/docs/api/) >> README.md
echo. >> README.md
echo ## 🆘 Support >> README.md
echo. >> README.md
echo - [PocketBase Discord](https://discord.gg/pMjRAhYzZf) >> README.md
echo - [GitHub Issues](https://github.com/pocketbase/pocketbase/issues) >> README.md
echo. >> README.md
echo ## 💡 Tips >> README.md
echo. >> README.md
echo 1. Always change the JWT_SECRET in production >> README.md
echo 2. Enable SSL in production environments >> README.md
echo 3. Regularly backup your database >> README.md
echo 4. Monitor your free tier usage >> README.md
echo 5. Use environment variables for sensitive data >> README.md

REM Success message
echo.
echo ✅ PocketBase setup complete!
echo ================================
echo.
echo Next steps:
echo 1. Run: cd %POCKETBASE_DIR%
echo 2. Run: start.bat
echo 3. Open: http://localhost:8090/_/
echo 4. Create admin account
echo 5. Run: setup_admin.bat
echo.
echo Deploy to free hosting:
echo - Railway: deploy_railway.bat
echo - Render:  deploy_render.bat
echo - Fly.io:  deploy_flyio.bat
echo.
echo 🎉 Your free backend is ready!
echo.
pause
