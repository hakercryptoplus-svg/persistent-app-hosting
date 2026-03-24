#!/bin/bash

# N8N Deployment Script
# هذا السكريبت يقوم بتثبيت ونشر n8n مع Docker

set -e

echo "=========================================="
echo "N8N Deployment Script"
echo "=========================================="

# الألوان للطباعة
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# الدوال المساعدة
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# التحقق من وجود Docker
print_info "التحقق من وجود Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker غير مثبت. يرجى تثبيت Docker أولاً."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose غير مثبت. يرجى تثبيت docker-compose أولاً."
    exit 1
fi

print_info "Docker موجود ✓"

# إنشاء مجلد العمل
N8N_DIR="${HOME}/n8n"
print_info "إنشاء مجلد العمل: $N8N_DIR"
mkdir -p "$N8N_DIR"
cd "$N8N_DIR"

# إنشاء ملف docker-compose.yml
print_info "إنشاء ملف docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - GENERIC_TIMEZONE=UTC
      - TZ=UTC
    volumes:
      - n8n_data:/home/node/.n8n
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
    networks:
      - n8n_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  n8n_data:
    driver: local

networks:
  n8n_network:
    driver: bridge
EOF

print_info "تم إنشاء docker-compose.yml ✓"

# بدء الخدمة
print_info "بدء خدمة n8n..."
docker-compose up -d

# الانتظار قليلاً للتأكد من بدء الخدمة
print_info "الانتظار لبدء الخدمة (30 ثانية)..."
sleep 30

# التحقق من حالة الخدمة
print_info "التحقق من حالة الخدمة..."
if docker-compose ps | grep -q "n8n.*Up"; then
    print_info "تم بدء n8n بنجاح ✓"
else
    print_error "فشل بدء n8n"
    docker-compose logs
    exit 1
fi

# الحصول على رابط الوصول
print_info "معلومات الوصول:"
echo "=========================================="
echo -e "${GREEN}N8N URL: http://localhost:5678${NC}"
echo "=========================================="

# إنشاء سكريبت keep-alive
print_info "إنشاء سكريبت keep-alive..."
cat > keep-alive.sh << 'EOF'
#!/bin/bash
# Keep-alive script for n8n

while true; do
    echo "[$(date)] Checking n8n health..."
    
    # التحقق من صحة الخدمة
    if curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
        echo "[$(date)] N8N is healthy ✓"
    else
        echo "[$(date)] N8N health check failed ⚠️"
        # محاولة إعادة تشغيل الخدمة
        docker-compose restart n8n
    fi
    
    # الانتظار 6 ساعات قبل الفحص التالي
    sleep 21600
done
EOF

chmod +x keep-alive.sh
print_info "تم إنشاء سكريبت keep-alive ✓"

# إنشاء ملف systemd service
print_info "إنشاء ملف خدمة systemd..."
cat > n8n.service << EOF
[Unit]
Description=N8N Workflow Automation
After=docker.service
Requires=docker.service

[Service]
Type=simple
WorkingDirectory=$N8N_DIR
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
EOF

print_info "ملف الخدمة جاهز في: $N8N_DIR/n8n.service"

# التعليمات النهائية
echo ""
echo "=========================================="
echo "تم الانتهاء من التثبيت بنجاح! ✓"
echo "=========================================="
echo ""
echo "الخطوات التالية:"
echo "1. افتح المتصفح وانتقل إلى: http://localhost:5678"
echo "2. قم بإعداد n8n حسب احتياجاتك"
echo ""
echo "لتشغيل n8n كخدمة systemd:"
echo "  sudo cp $N8N_DIR/n8n.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable n8n.service"
echo "  sudo systemctl start n8n.service"
echo ""
echo "لمراقبة الخدمة:"
echo "  docker-compose logs -f"
echo ""
echo "لإيقاف n8n:"
echo "  docker-compose down"
echo ""
echo "=========================================="
