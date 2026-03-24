#!/bin/bash

# Universal Keep-Alive Script
# هذا السكريبت يحافظ على نشاط البيئة من خلال تنفيذ عمليات دورية

set -e

# الإعدادات
LOG_FILE="${HOME}/.keep-alive.log"
CHECK_INTERVAL=3600  # 1 ساعة
SERVICES_TO_CHECK=("n8n" "openwebui" "ollama")

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# الدوال المساعدة
log_info() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} [INFO] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} [ERROR] $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} [WARNING] $1" | tee -a "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} [DEBUG] $1" | tee -a "$LOG_FILE"
}

# التحقق من صحة الخدمات
check_services() {
    log_info "بدء فحص الخدمات..."
    
    # فحص n8n
    if command -v docker &> /dev/null; then
        if docker ps | grep -q "n8n"; then
            log_info "✓ N8N قيد التشغيل"
            if ! curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
                log_warning "⚠️ N8N غير مستجيب، محاولة إعادة التشغيل..."
                cd "${HOME}/n8n" && docker-compose restart n8n || log_error "فشل إعادة تشغيل N8N"
            fi
        fi
        
        # فحص OpenWebUI
        if docker ps | grep -q "openwebui"; then
            log_info "✓ OpenWebUI قيد التشغيل"
            if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
                log_warning "⚠️ OpenWebUI غير مستجيب، محاولة إعادة التشغيل..."
                cd "${HOME}/openwebui" && docker-compose restart openwebui || log_error "فشل إعادة تشغيل OpenWebUI"
            fi
        fi
        
        # فحص Ollama
        if docker ps | grep -q "ollama"; then
            log_info "✓ Ollama قيد التشغيل"
            if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
                log_warning "⚠️ Ollama غير مستجيب، محاولة إعادة التشغيل..."
                docker restart ollama || log_error "فشل إعادة تشغيل Ollama"
            fi
        fi
    fi
    
    log_info "انتهى فحص الخدمات"
}

# تنفيذ عمليات النظام
perform_system_operations() {
    log_info "تنفيذ عمليات النظام..."
    
    # تحديث قائمة الحزم
    log_debug "تحديث قائمة الحزم..."
    apt-get update > /dev/null 2>&1 || log_warning "فشل تحديث قائمة الحزم"
    
    # تنظيف الملفات المؤقتة
    log_debug "تنظيف الملفات المؤقتة..."
    rm -rf /tmp/* > /dev/null 2>&1 || log_warning "فشل تنظيف الملفات المؤقتة"
    
    # تنظيف Docker
    if command -v docker &> /dev/null; then
        log_debug "تنظيف Docker..."
        docker system prune -f > /dev/null 2>&1 || log_warning "فشل تنظيف Docker"
    fi
    
    log_info "انتهت عمليات النظام"
}

# تسجيل معلومات النظام
log_system_info() {
    log_info "معلومات النظام:"
    log_debug "استخدام CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
    log_debug "استخدام الذاكرة: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
    log_debug "استخدام القرص: $(df -h / | tail -1 | awk '{print $5}')"
    log_debug "عدد العمليات: $(ps aux | wc -l)"
}

# الحلقة الرئيسية
main() {
    log_info "=========================================="
    log_info "Keep-Alive Script Started"
    log_info "=========================================="
    log_info "Check Interval: ${CHECK_INTERVAL} seconds"
    log_info "Log File: ${LOG_FILE}"
    
    while true; do
        log_info "---"
        log_info "Cycle started at $(date)"
        
        # تنفيذ الفحوصات والعمليات
        check_services
        perform_system_operations
        log_system_info
        
        log_info "Cycle completed, waiting ${CHECK_INTERVAL} seconds..."
        sleep "$CHECK_INTERVAL"
    done
}

# معالج الإشارات
trap 'log_info "Keep-Alive Script Stopped"; exit 0' SIGTERM SIGINT

# بدء البرنامج
main
