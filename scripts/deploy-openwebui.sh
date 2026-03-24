#!/bin/bash

# OpenWebUI Deployment Script
# هذا السكريبت يقوم بتثبيت ونشر OpenWebUI مع Docker

set -e

echo "=========================================="
echo "OpenWebUI Deployment Script"
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
OPENWEBUI_DIR="${HOME}/openwebui"
print_info "إنشاء مجلد العمل: $OPENWEBUI_DIR"
mkdir -p "$OPENWEBUI_DIR"
cd "$OPENWEBUI_DIR"

# إنشاء ملف docker-compose.yml
print_info "إنشاء ملف docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  openwebui:
    image: ghcr.io/open-webui/open-webui:latest
    container_name: openwebui
    ports:
      - "8080:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - OPENAI_API_KEY=${OPENAI_API_KEY:-}
      - OPENAI_API_BASE_URL=${OPENAI_API_BASE_URL:-https://api.openai.com/v1}
    volumes:
      - openwebui_data:/app/backend/data
    restart: always
    networks:
      - openwebui_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # اختياري: Ollama للنماذج المحلية
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    restart: always
    networks:
      - openwebui_network
    environment:
      - OLLAMA_HOST=0.0.0.0:11434

volumes:
  openwebui_data:
    driver: local
  ollama_data:
    driver: local

networks:
  openwebui_network:
    driver: bridge
EOF

print_info "تم إنشاء docker-compose.yml ✓"

# بدء الخدمة
print_info "بدء خدمة OpenWebUI..."
docker-compose up -d

# الانتظار قليلاً للتأكد من بدء الخدمة
print_info "الانتظار لبدء الخدمة (40 ثانية)..."
sleep 40

# التحقق من حالة الخدمة
print_info "التحقق من حالة الخدمة..."
if docker-compose ps | grep -q "openwebui.*Up"; then
    print_info "تم بدء OpenWebUI بنجاح ✓"
else
    print_error "فشل بدء OpenWebUI"
    docker-compose logs
    exit 1
fi

# الحصول على رابط الوصول
print_info "معلومات الوصول:"
echo "=========================================="
echo -e "${GREEN}OpenWebUI URL: http://localhost:8080${NC}"
echo "=========================================="

# إنشاء سكريبت keep-alive
print_info "إنشاء سكريبت keep-alive..."
cat > keep-alive.sh << 'EOF'
#!/bin/bash
# Keep-alive script for OpenWebUI

while true; do
    echo "[$(date)] Checking OpenWebUI health..."
    
    # التحقق من صحة الخدمة
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "[$(date)] OpenWebUI is healthy ✓"
    else
        echo "[$(date)] OpenWebUI health check failed ⚠️"
        # محاولة إعادة تشغيل الخدمة
        docker-compose restart openwebui
    fi
    
    # الانتظار 6 ساعات قبل الفحص التالي
    sleep 21600
done
EOF

chmod +x keep-alive.sh
print_info "تم إنشاء سكريبت keep-alive ✓"

# إنشاء ملف systemd service
print_info "إنشاء ملف خدمة systemd..."
cat > openwebui.service << EOF
[Unit]
Description=OpenWebUI - Open-source ChatGPT Interface
After=docker.service
Requires=docker.service

[Service]
Type=simple
WorkingDirectory=$OPENWEBUI_DIR
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always
RestartSec=10
User=$USER

[Install]
WantedBy=multi-user.target
EOF

print_info "ملف الخدمة جاهز في: $OPENWEBUI_DIR/openwebui.service"

# التعليمات النهائية
echo ""
echo "=========================================="
echo "تم الانتهاء من التثبيت بنجاح! ✓"
echo "=========================================="
echo ""
echo "الخطوات التالية:"
echo "1. افتح المتصفح وانتقل إلى: http://localhost:8080"
echo "2. قم بإعداد OpenWebUI حسب احتياجاتك"
echo ""
echo "لتشغيل OpenWebUI كخدمة systemd:"
echo "  sudo cp $OPENWEBUI_DIR/openwebui.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable openwebui.service"
echo "  sudo systemctl start openwebui.service"
echo ""
echo "لمراقبة الخدمة:"
echo "  docker-compose logs -f"
echo ""
echo "لإيقاف OpenWebUI:"
echo "  docker-compose down"
echo ""
echo "لتحميل نموذج محلي (اختياري):"
echo "  docker exec ollama ollama pull llama2"
echo ""
echo "=========================================="
