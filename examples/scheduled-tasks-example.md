# مثال: استخدام Scheduled Tasks للحفاظ على النشاط

## المفهوم الأساسي

استخدام ميزة المهام المجدولة (Scheduled Tasks) في الـ Agent لتشغيل سكريبت "keep-alive" بشكل دوري، مما يحافظ على نشاط البيئة ويمنع دخولها حالة النوم.

---

## الحل 1: استخدام Cron Expression

### الخطوة 1: إنشاء سكريبت Keep-Alive

```bash
cat > ~/keep-alive-simple.sh << 'EOF'
#!/bin/bash

# سكريبت بسيط للحفاظ على النشاط
echo "[$(date)] Keep-alive check executed"

# فحص الخدمات
if command -v docker &> /dev/null; then
    # فحص N8N
    if docker ps | grep -q "n8n"; then
        curl -s http://localhost:5678/healthz > /dev/null && echo "N8N OK" || echo "N8N FAILED"
    fi
    
    # فحص OpenWebUI
    if docker ps | grep -q "openwebui"; then
        curl -s http://localhost:8080/health > /dev/null && echo "OpenWebUI OK" || echo "OpenWebUI FAILED"
    fi
fi

# تنفيذ عملية بسيطة للحفاظ على النشاط
ls -la ~/ > /dev/null
echo "[$(date)] Keep-alive check completed"
EOF

chmod +x ~/keep-alive-simple.sh
```

### الخطوة 2: جدولة المهمة

استخدم أداة `schedule` في الـ Agent:

```bash
# تشغيل keep-alive كل 6 ساعات
schedule --type cron --cron "0 */6 * * *" --name "keep-alive-6h" --prompt "تشغيل سكريبت keep-alive للحفاظ على نشاط البيئة"
```

### شرح Cron Expression

```
0 */6 * * *
│ │   │ │ │
│ │   │ │ └─ يوم الأسبوع (0-6, 0 = الأحد)
│ │   │ └─── الشهر (1-12)
│ │   └───── يوم الشهر (1-31)
│ └───────── الساعة (0-23) - كل 6 ساعات
└─────────── الدقيقة (0-59)
```

---

## الحل 2: استخدام Interval

### الخطوة 1: جدولة مهمة بفاصل زمني

```bash
# تشغيل keep-alive كل 6 ساعات (21600 ثانية)
schedule --type interval --interval 21600 --name "keep-alive-interval" --prompt "تشغيل فحص صحة الخدمات"
```

---

## الحل 3: Cron Expressions المختلفة

اختر التعبير المناسب حسب احتياجاتك:

### كل ساعة
```
0 * * * *
```

### كل 3 ساعات
```
0 */3 * * *
```

### كل 6 ساعات
```
0 */6 * * *
```

### كل 12 ساعة
```
0 */12 * * *
```

### يومياً في الساعة 12 ظهراً
```
0 12 * * *
```

### كل يوم الاثنين في الساعة 9 صباحاً
```
0 9 * * 1
```

### كل يوم في الساعة 3 صباحاً
```
0 3 * * *
```

---

## مثال عملي شامل

### الخطوة 1: إنشاء سكريبت متقدم

```bash
cat > ~/keep-alive-advanced.sh << 'EOF'
#!/bin/bash

# سكريبت متقدم للحفاظ على النشاط مع تسجيل مفصل

LOG_FILE="$HOME/.keep-alive-log.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# بدء الفحص
log "=== Keep-Alive Check Started ==="

# 1. فحص الذاكرة والقرص
log "System Resources:"
log "  Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
log "  Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2}')"

# 2. فحص الخدمات
log "Service Status:"

if docker ps | grep -q "n8n"; then
    if curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
        log "  N8N: ✓ Running"
    else
        log "  N8N: ⚠️ Not responding"
        docker-compose -f ~/n8n/docker-compose.yml restart n8n >> "$LOG_FILE" 2>&1
    fi
fi

if docker ps | grep -q "openwebui"; then
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        log "  OpenWebUI: ✓ Running"
    else
        log "  OpenWebUI: ⚠️ Not responding"
        docker-compose -f ~/openwebui/docker-compose.yml restart openwebui >> "$LOG_FILE" 2>&1
    fi
fi

# 3. تنفيذ عمليات النظام
log "System Operations:"
apt-get update > /dev/null 2>&1 && log "  Package update: ✓" || log "  Package update: ✗"
docker system prune -f > /dev/null 2>&1 && log "  Docker cleanup: ✓" || log "  Docker cleanup: ✗"

# 4. إنهاء الفحص
log "=== Keep-Alive Check Completed ==="
log ""
EOF

chmod +x ~/keep-alive-advanced.sh
```

### الخطوة 2: جدولة المهمة

```bash
# جدولة المهمة المتقدمة
schedule --type cron --cron "0 */6 * * *" --name "keep-alive-advanced" --prompt "تشغيل فحص صحة الخدمات المتقدم"
```

### الخطوة 3: مراقبة السجلات

```bash
# عرض السجلات
tail -f ~/.keep-alive-log.txt

# عرض آخر 50 سطر
tail -50 ~/.keep-alive-log.txt
```

---

## استراتيجيات متعددة المستويات

### المستوى 1: Keep-Alive بسيط (كل 6 ساعات)

```bash
schedule --type cron --cron "0 */6 * * *" --prompt "bash ~/keep-alive-simple.sh"
```

### المستوى 2: Keep-Alive متقدم (كل 3 ساعات)

```bash
schedule --type cron --cron "0 */3 * * *" --prompt "bash ~/keep-alive-advanced.sh"
```

### المستوى 3: فحص صحة شامل (كل ساعة)

```bash
schedule --type cron --cron "0 * * * *" --prompt "bash /home/ubuntu/skills/persistent-app-hosting/scripts/health-check.sh"
```

---

## نصائح وأفضل الممارسات

### 1. اختيار الفاصل الزمني المناسب

| الفاصل الزمني | الاستخدام |
|-------------|---------|
| كل ساعة | للخدمات الحرجة جداً |
| كل 3 ساعات | للخدمات المهمة |
| كل 6 ساعات | الخيار الموصى به |
| كل 12 ساعة | للخدمات غير الحرجة |

### 2. تقليل استهلاك الموارد

استخدم سكريبتات بسيطة بدلاً من المعقدة:

```bash
# ✓ بسيط وفعال
curl -s http://localhost:5678/healthz > /dev/null

# ✗ معقد وغير ضروري
curl -v http://localhost:5678/healthz | grep "HTTP/1.1 200"
```

### 3. تسجيل العمليات

احتفظ بسجلات للمهام المجدولة:

```bash
# أضف تسجيل إلى السكريبت
echo "[$(date)] Task executed" >> ~/task-log.txt
```

### 4. معالجة الأخطاء

تأكد من أن السكريبت يتعامل مع الأخطاء:

```bash
#!/bin/bash
set -e  # إيقاف عند أول خطأ

# أو استخدم try-catch
if ! curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
    echo "Service failed, restarting..."
    docker-compose restart n8n
fi
```

---

## استكشاف الأخطاء

### المشكلة: المهمة لا تعمل

```bash
# تحقق من أن السكريبت قابل للتنفيذ
ls -l ~/keep-alive-simple.sh

# جرب تشغيل السكريبت يدويًا
bash ~/keep-alive-simple.sh
```

### المشكلة: المهمة تستغرق وقتاً طويلاً

```bash
# استخدم timeout
timeout 300 bash ~/keep-alive-advanced.sh
```

### المشكلة: لا توجد سجلات

```bash
# تأكد من وجود ملف السجل
touch ~/.keep-alive-log.txt

# تحقق من الأذونات
chmod 644 ~/.keep-alive-log.txt
```

---

## أمثلة متقدمة

### مثال 1: Keep-Alive مع إشعارات

```bash
cat > ~/keep-alive-notify.sh << 'EOF'
#!/bin/bash

# فحص الخدمات مع إرسال إشعارات

check_service() {
    local url=$1
    local name=$2
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo "✓ $name is OK"
    else
        echo "✗ $name is DOWN"
        # يمكن إضافة إرسال إشعار هنا
    fi
}

check_service "http://localhost:5678/healthz" "N8N"
check_service "http://localhost:8080/health" "OpenWebUI"
EOF

chmod +x ~/keep-alive-notify.sh
```

### مثال 2: Keep-Alive مع تنظيف تلقائي

```bash
cat > ~/keep-alive-cleanup.sh << 'EOF'
#!/bin/bash

# فحص الخدمات مع تنظيف تلقائي

# تنظيف الملفات المؤقتة
rm -rf /tmp/* 2>/dev/null

# تنظيف Docker
docker system prune -f > /dev/null 2>&1

# فحص الخدمات
curl -s http://localhost:5678/healthz > /dev/null || docker-compose -f ~/n8n/docker-compose.yml restart n8n

echo "Cleanup and health check completed"
EOF

chmod +x ~/keep-alive-cleanup.sh
```

---

## الخطوات التالية

1. اختر استراتيجية Keep-Alive المناسبة
2. أنشئ السكريبت المناسب
3. جدول المهمة باستخدام `schedule` tool
4. راقب السجلات للتأكد من عمل المهمة
5. اضبط الفاصل الزمني حسب احتياجاتك

---

## الموارد الإضافية

- [Cron Expression Generator](https://crontab.guru/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [Docker Documentation](https://docs.docker.com/)
