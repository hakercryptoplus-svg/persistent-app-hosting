#!/bin/bash

# Health Check Script
# هذا السكريبت يتحقق من صحة جميع الخدمات المستضافة

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# العدادات
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# الدوال المساعدة
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

check_service() {
    local service_name=$1
    local url=$2
    local expected_code=${3:-200}
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "فحص $service_name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✓ متاح (HTTP $response)${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗ غير متاح (HTTP $response)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

check_docker_service() {
    local container_name=$1
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "فحص حالة Docker Container ($container_name)... "
    
    if docker ps | grep -q "$container_name"; then
        echo -e "${GREEN}✓ قيد التشغيل${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗ متوقف${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

check_disk_space() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "فحص مساحة القرص... "
    
    usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$usage" -lt 90 ]; then
        echo -e "${GREEN}✓ مساحة كافية ($usage%)${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️ مساحة منخفضة ($usage%)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

check_memory() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "فحص الذاكرة المتاحة... "
    
    mem_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
    
    if [ "$mem_usage" -lt 90 ]; then
        echo -e "${GREEN}✓ ذاكرة كافية ($mem_usage%)${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️ ذاكرة منخفضة ($mem_usage%)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

check_network() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    echo -n "فحص الاتصال بالإنترنت... "
    
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ متصل${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗ غير متصل${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}ملخص الفحوصات${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "إجمالي الفحوصات: $TOTAL_CHECKS"
    echo -e "${GREEN}نجح: $PASSED_CHECKS${NC}"
    echo -e "${RED}فشل: $FAILED_CHECKS${NC}"
    
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        echo -e "${GREEN}الحالة: جميع الخدمات تعمل بشكل صحيح ✓${NC}"
    else
        echo -e "${YELLOW}الحالة: هناك مشاكل تحتاج إلى انتباه ⚠️${NC}"
    fi
    echo -e "${BLUE}========================================${NC}"
}

# البرنامج الرئيسي
main() {
    print_header "فحص صحة الخدمات"
    
    echo ""
    echo "فحص الخدمات:"
    
    # فحص الخدمات
    if [ -d "${HOME}/n8n" ]; then
        check_docker_service "n8n"
        check_service "N8N HTTP" "http://localhost:5678/healthz"
    fi
    
    if [ -d "${HOME}/openwebui" ]; then
        check_docker_service "openwebui"
        check_service "OpenWebUI HTTP" "http://localhost:8080/health"
    fi
    
    if docker ps | grep -q "ollama"; then
        check_docker_service "ollama"
        check_service "Ollama API" "http://localhost:11434/api/tags"
    fi
    
    echo ""
    echo "فحص موارد النظام:"
    
    # فحص موارد النظام
    check_disk_space
    check_memory
    check_network
    
    # طباعة الملخص
    print_summary
    
    # إرجاع رمز الخروج المناسب
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# تشغيل البرنامج
main
