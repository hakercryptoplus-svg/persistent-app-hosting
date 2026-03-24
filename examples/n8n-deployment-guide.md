# دليل نشر N8N - خطوة بخطوة

## المتطلبات الأساسية

- Docker و docker-compose مثبتة
- صلاحيات sudo (للخدمات الاختيارية)
- 2 GB RAM على الأقل
- 5 GB مساحة قرص متاحة

## الطريقة 1: استخدام السكريبت التلقائي (الموصى به)

### الخطوة 1: تشغيل السكريبت

```bash
bash /home/ubuntu/skills/persistent-app-hosting/scripts/deploy-n8n.sh
```

السكريبت سيقوم بـ:
- التحقق من وجود Docker
- إنشاء مجلد العمل
- إنشاء ملف docker-compose.yml
- بدء الخدمة
- إنشاء سكريبت keep-alive

### الخطوة 2: الوصول إلى N8N

افتح المتصفح وانتقل إلى:
```
http://localhost:5678
```

---

## الطريقة 2: التثبيت اليدوي

### الخطوة 1: إنشاء مجلد العمل

```bash
mkdir -p ~/n8n
cd ~/n8n
```

### الخطوة 2: إنشاء ملف docker-compose.yml

انسخ محتوى الملف من `configs/n8n-docker-compose.yml`:

```bash
cp /home/ubuntu/skills/persistent-app-hosting/configs/n8n-docker-compose.yml ~/n8n/docker-compose.yml
```

### الخطوة 3: بدء الخدمة

```bash
docker-compose up -d
```

### الخطوة 4: التحقق من الحالة

```bash
docker-compose ps
```

يجب أن ترى:
```
NAME    STATUS
n8n     Up X seconds
```

---

## الوصول والإعداد الأولي

### 1. الوصول إلى الواجهة

```
URL: http://localhost:5678
```

### 2. إنشاء حساب إداري

عند الدخول لأول مرة، ستُطلب منك إنشاء حساب إداري:
- أدخل بريدك الإلكتروني
- اختر كلمة مرور قوية
- اضغط "Setup"

### 3. تسجيل الدخول

استخدم بيانات الحساب التي أنشأتها للدخول.

---

## الخيارات المتقدمة

### تفعيل قاعدة البيانات الخارجية

إذا أردت استخدام MySQL بدلاً من SQLite:

1. عدّل ملف `docker-compose.yml`:

```yaml
environment:
  - DB_TYPE=mysql
  - DB_MYSQL_HOST=mysql
  - DB_MYSQL_PORT=3306
  - DB_MYSQL_DATABASE=n8n
  - DB_MYSQL_USER=n8n
  - DB_MYSQL_PASSWORD=your_password
```

2. أضف خدمة MySQL:

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: n8n
      MYSQL_USER: n8n
      MYSQL_PASSWORD: your_password
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - n8n_network
```

3. أعد تشغيل الخدمة:

```bash
docker-compose down
docker-compose up -d
```

### تفعيل المصادقة الأساسية

لتأمين N8N بكلمة مرور:

```yaml
environment:
  - N8N_AUTH_BASIC_ENABLED=true
  - N8N_AUTH_BASIC_AUTH_ACTIVE=true
  - N8N_AUTH_BASIC_AUTH_USER=admin
  - N8N_AUTH_BASIC_AUTH_PASSWORD=your_secure_password
```

### تعيين مفتاح التشفير

لحماية البيانات الحساسة:

```bash
# توليد مفتاح عشوائي
openssl rand -base64 32

# أضفه إلى docker-compose.yml
environment:
  - N8N_ENCRYPTION_KEY=your_generated_key
```

---

## المراقبة والصيانة

### عرض السجلات

```bash
# السجلات الحية
docker-compose logs -f

# آخر 100 سطر
docker-compose logs --tail=100
```

### التحقق من الصحة

```bash
# استخدم السكريبت المرفق
bash /home/ubuntu/skills/persistent-app-hosting/scripts/health-check.sh

# أو يدويًا
curl http://localhost:5678/healthz
```

### إعادة التشغيل

```bash
# إعادة تشغيل الخدمة
docker-compose restart n8n

# إيقاف الخدمة
docker-compose stop

# بدء الخدمة
docker-compose start
```

### التحديث إلى نسخة أحدث

```bash
# سحب الصورة الأحدث
docker pull n8nio/n8n:latest

# إعادة تشغيل الخدمة
docker-compose down
docker-compose up -d
```

---

## تشغيل كخدمة systemd (اختياري)

لتشغيل N8N تلقائياً عند بدء النظام:

### 1. نسخ ملف الخدمة

```bash
sudo cp /home/ubuntu/skills/persistent-app-hosting/configs/n8n.service /etc/systemd/system/
```

### 2. تحديث systemd

```bash
sudo systemctl daemon-reload
```

### 3. تفعيل الخدمة

```bash
sudo systemctl enable n8n.service
```

### 4. بدء الخدمة

```bash
sudo systemctl start n8n.service
```

### 5. التحقق من الحالة

```bash
sudo systemctl status n8n.service
```

### إدارة الخدمة

```bash
# إيقاف الخدمة
sudo systemctl stop n8n.service

# إعادة تشغيل الخدمة
sudo systemctl restart n8n.service

# عرض السجلات
sudo journalctl -u n8n.service -f
```

---

## الحفاظ على النشاط (Keep-Alive)

لمنع توقف الخدمة بسبب عدم النشاط:

### الطريقة 1: استخدام Scheduled Tasks

```bash
# استخدم schedule tool
schedule --type cron --cron "0 */6 * * *" --prompt "bash /home/ubuntu/skills/persistent-app-hosting/scripts/keep-alive.sh"
```

### الطريقة 2: تشغيل Keep-Alive Script

```bash
# في الخلفية
nohup bash /home/ubuntu/skills/persistent-app-hosting/scripts/keep-alive.sh > ~/.keep-alive.log 2>&1 &

# أو باستخدام tmux
tmux new-session -d -s keep-alive "bash /home/ubuntu/skills/persistent-app-hosting/scripts/keep-alive.sh"
```

---

## استكشاف الأخطاء

### المشكلة: المنفذ 5678 مشغول

```bash
# العثور على العملية المستخدمة للمنفذ
lsof -i :5678

# قتل العملية (إذا لزم الأمر)
kill -9 <PID>
```

### المشكلة: الخدمة لا تبدأ

```bash
# عرض السجلات التفصيلية
docker-compose logs n8n

# التحقق من توفر الذاكرة
free -h

# التحقق من مساحة القرص
df -h
```

### المشكلة: بطء الأداء

```bash
# تحقق من استخدام الموارد
docker stats n8n

# زيادة الموارد المخصصة في docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
```

---

## الخطوات التالية

1. **إنشاء Workflows**: ابدأ بإنشاء workflows بسيطة
2. **إضافة Integrations**: ربط N8N مع الخدمات الأخرى
3. **جدولة المهام**: استخدم Cron للمهام الدورية
4. **المراقبة**: راقب الأداء والأخطاء بانتظام
5. **النسخ الاحتياطية**: قم بعمل نسخ احتياطية من البيانات بانتظام

---

## الموارد الإضافية

- [توثيق N8N الرسمية](https://docs.n8n.io/)
- [مجتمع N8N](https://community.n8n.io/)
- [Docker Documentation](https://docs.docker.com/)
