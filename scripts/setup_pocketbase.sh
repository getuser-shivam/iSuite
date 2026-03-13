#!/bin/bash

# PocketBase Setup Script - Completely Free Backend Solution
# This script sets up PocketBase with free hosting options

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
POCKETBASE_VERSION="0.23.2"
POCKETBASE_DIR="pocketbase"
POCKETBASE_URL="https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_linux_amd64.zip"

echo -e "${BLUE}🚀 Setting up PocketBase - Free Backend Solution${NC}"
echo -e "${BLUE}===============================================${NC}"

# Create pocketbase directory
echo -e "${YELLOW}📁 Creating PocketBase directory...${NC}"
mkdir -p $POCKETBASE_DIR
cd $POCKETBASE_DIR

# Download PocketBase
echo -e "${YELLOW}⬇️  Downloading PocketBase v${POCKETBASE_VERSION}...${NC}"
if command -v wget &> /dev/null; then
    wget -q $POCKETBASE_URL -O pocketbase.zip
elif command -v curl &> /dev/null; then
    curl -sL $POCKETBASE_URL -o pocketbase.zip
else
    echo -e "${RED}❌ Error: Neither wget nor curl is installed${NC}"
    exit 1
fi

# Extract PocketBase
echo -e "${YELLOW}📦 Extracting PocketBase...${NC}"
unzip -q pocketbase.zip
rm pocketbase.zip

# Make executable
echo -e "${YELLOW}🔧 Making PocketBase executable...${NC}"
chmod +x pocketbase

# Create necessary directories
echo -e "${YELLOW}📂 Creating data directories...${NC}"
mkdir -p data logs storage

# Create initial configuration
echo -e "${YELLOW}⚙️  Creating initial configuration...${NC}"
cat > pb_config.json << 'EOF'
{
  "logs": {
    "console": {
      "level": "info"
    },
    "file": {
      "level": "info",
      "path": "logs/pocketbase.log",
      "maxSize": 10,
      "maxAge": 7
    }
  },
  "api": {
    "cors": {
      "enabled": true,
      "allowedOrigins": ["http://localhost:3000", "http://localhost:8080", "http://localhost:3000"],
      "allowedMethods": ["GET", "POST", "PUT", "DELETE", "PATCH"],
      "allowedHeaders": ["Content-Type", "Authorization", "X-Requested-With"]
    }
  },
  "security": {
    "rateLimit": {
      "enabled": true,
      "max": 100,
      "duration": "1m"
    }
  }
}
EOF

# Create startup script
echo -e "${YELLOW}📝 Creating startup script...${NC}"
cat > start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting PocketBase..."
./pocketbase serve --http=0.0.0.0:8090
EOF
chmod +x start.sh

# Create admin user script
echo -e "${YELLOW}👤 Creating admin user setup script...${NC}"
cat > setup_admin.sh << 'EOF'
#!/bin/bash
echo "👤 Setting up admin user..."
echo "Please visit http://localhost:8090/_/ to create your admin account"
echo "Press Enter to continue after creating admin account..."
read
EOF
chmod +x setup_admin.sh

# Create deployment scripts
echo -e "${YELLOW}🌐 Creating deployment scripts...${NC}"

# Railway deployment
cat > deploy_railway.sh << 'EOF'
#!/bin/bash
echo "🚂 Deploying to Railway..."
if ! command -v railway &> /dev/null; then
    echo "Installing Railway CLI..."
    npm install -g @railway/cli
fi

# Create Railway configuration
cat > railway.json << 'INNER_EOF'
{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "./pocketbase serve --http=0.0.0.0:$PORT",
    "healthcheckPath": "/api/health"
  }
}
INNER_EOF

# Create nixpacks configuration
cat > nixpacks.toml << 'INNER_EOF'
[[phases]]
name = "setup"
nixPkgs = ["unzip"]

[[phases]]
name = "build"
cmds = ["wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip", "unzip pocketbase_linux_amd64.zip", "chmod +x pocketbase"]

[[phases]]
name = "start"
cmd = "./pocketbase serve --http=0.0.0.0:$PORT"
INNER_EOF

railway login
railway init
railway up
echo "✅ Railway deployment complete!"
EOF
chmod +x deploy_railway.sh

# Render deployment
cat > deploy_render.sh << 'EOF'
#!/bin/bash
echo "🎨 Deploying to Render..."
cat > render.yaml << 'INNER_EOF'
services:
  - type: web
    name: pocketbase-app
    runtime: docker
    dockerfilePath: ./Dockerfile
    envVars:
      - key: PORT
        value: 10000
INNER_EOF

cat > Dockerfile << 'INNER_EOF'
FROM alpine:latest

RUN apk add --no-cache unzip wget

WORKDIR /app

RUN wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip && \
    unzip pocketbase_linux_amd64.zip && \
    chmod +x pocketbase && \
    rm pocketbase_linux_amd64.zip

EXPOSE 10000

CMD ["./pocketbase", "serve", "--http=0.0.0.0:10000"]
INNER_EOF

echo "✅ Render configuration created!"
echo "Upload these files to your Render repository to deploy."
EOF
chmod +x deploy_render.sh

# Fly.io deployment
cat > deploy_flyio.sh << 'EOF'
#!/bin/bash
echo "✈️  Deploying to Fly.io..."
if ! command -v flyctl &> /dev/null; then
    echo "Installing Fly.io CLI..."
    curl -L https://fly.io/install.sh | sh
fi

# Create Fly.io configuration
cat > fly.toml << 'INNER_EOF'
app = "your-pocketbase-app"

[[services]]
  http_checks = []
  internal_port = 8090
  protocol = "tcp"

  [services.concurrency]
    hard_limit = 25
    soft_limit = 20

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

  [[services.tcp_checks]]
    grace_period = "1s"
    interval = "15s"
    restart_limit = 0
    timeout = "2s"

[deploy]
  strategy = "immediate"
INNER_EOF

# Create Dockerfile for Fly.io
cat > Dockerfile << 'INNER_EOF'
FROM alpine:latest

RUN apk add --no-cache unzip wget

WORKDIR /app

RUN wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip && \
    unzip pocketbase_linux_amd64.zip && \
    chmod +x pocketbase && \
    rm pocketbase_linux_amd64.zip

EXPOSE 8090

CMD ["./pocketbase", "serve", "--http=0.0.0.0:8090"]
INNER_EOF

flyctl launch
echo "✅ Fly.io deployment complete!"
EOF
chmod +x deploy_flyio.sh

# Create environment file
echo -e "${YELLOW}🔧 Creating environment configuration...${NC}"
cat > .env << 'EOF'
# PocketBase Configuration
POCKETBASE_HOST=localhost
POCKETBASE_PORT=8090
POCKETBASE_URL=http://localhost:8090

# Database Configuration
DATABASE_PATH=data/pocketbase.db
DATABASE_BACKUP_ENABLED=true

# Authentication
JWT_SECRET=your-secret-key-change-this-in-production

# Email Configuration (choose one)
RESEND_API_KEY=your_resend_api_key
SENDGRID_API_KEY=your_sendgrid_api_key
MAILGUN_API_KEY=your_mailgun_api_key

# OAuth Configuration (optional)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# Storage Configuration (optional)
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Hosting Configuration (optional)
RAILWAY_API_KEY=your_railway_api_key
RENDER_API_KEY=your_render_api_key
FLY_API_KEY=your_fly_api_key
DIGITALOCEAN_API_KEY=your_digitalocean_api_key
HEROKU_API_KEY=your_heroku_api_key
EOF

# Create README
echo -e "${YELLOW}📖 Creating README...${NC}"
cat > README.md << 'EOF'
# PocketBase Setup - Free Backend Solution

## 🚀 Quick Start

1. **Start PocketBase locally:**
   ```bash
   ./start.sh
   ```

2. **Setup admin account:**
   - Open http://localhost:8090/_/
   - Create your admin account
   - Run `./setup_admin.sh` when done

3. **Configure your app:**
   - Copy `.env` file to your Flutter app
   - Update the configuration as needed

## 🌐 Free Deployment Options

### Railway ($0/month)
```bash
./deploy_railway.sh
```
- Free tier: 500 hours/month
- Custom domain: Available
- SSL: Included

### Render ($0/month)
```bash
./deploy_render.sh
```
- Free tier: 750 hours/month
- Custom domain: Available
- SSL: Included

### Fly.io (Free allowance)
```bash
./deploy_flyio.sh
```
- Free allowance: 160 hours/month
- Custom domain: Available
- SSL: Included

### Self-Hosted (Completely Free)
- Your own server/VPS
- Docker deployment
- Full control

## 📁 Directory Structure

```
pocketbase/
├── pocketbase          # PocketBase executable
├── data/              # Database files
├── logs/              # Log files
├── storage/           # File storage
├── pb_config.json     # PocketBase configuration
├── start.sh           # Startup script
├── setup_admin.sh     # Admin setup script
├── deploy_railway.sh  # Railway deployment
├── deploy_render.sh   # Render deployment
├── deploy_flyio.sh    # Fly.io deployment
├── .env               # Environment variables
└── README.md          # This file
```

## 🔧 Configuration

All configuration is parameterized through environment variables. See `.env` file for available options.

## 📚 Documentation

- [PocketBase Documentation](https://pocketbase.io/docs/)
- [Flutter Integration](https://pocketbase.io/docs/flutter/)
- [API Reference](https://pocketbase.io/docs/api/)

## 🆘 Support

- [PocketBase Discord](https://discord.gg/pMjRAhYzZf)
- [GitHub Issues](https://github.com/pocketbase/pocketbase/issues)

## 💡 Tips

1. Always change the JWT_SECRET in production
2. Enable SSL in production environments
3. Regularly backup your database
4. Monitor your free tier usage
5. Use environment variables for sensitive data
EOF

# Success message
echo -e "${GREEN}✅ PocketBase setup complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run: ${YELLOW}cd $POCKETBASE_DIR${NC}"
echo -e "2. Run: ${YELLOW}./start.sh${NC}"
echo -e "3. Open: ${YELLOW}http://localhost:8090/_/${NC}"
echo -e "4. Create admin account"
echo -e "5. Run: ${YELLOW}./setup_admin.sh${NC}"
echo -e ""
echo -e "${BLUE}Deploy to free hosting:${NC}"
echo -e "- Railway: ${YELLOW}./deploy_railway.sh${NC}"
echo -e "- Render:  ${YELLOW}./deploy_render.sh${NC}"
echo -e "- Fly.io:  ${YELLOW}./deploy_flyio.sh${NC}"
echo -e ""
echo -e "${GREEN}🎉 Your free backend is ready!${NC}"
