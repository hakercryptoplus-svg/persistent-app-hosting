# دليل نشر OpenWebUI - خطوة بخطوة

## المتطلبات الأساسية

- Docker و docker-compose مثبتة
- 4 GB RAM على الأقل (8 GB موصى به)
- 20 GB مساحة قرص متاحة (للنماذج المحلية)
- اتصال إنترنت مستقر

## الطريقة 1: استخدام السكريبت التلقائي (الموصى به)

### الخطوة 1: تشغيل السكريبت

```bash
bash /home/ubuntu/skills/persistent-app-hosting/scripts/deploy-openwebui.sh
```

السكريبت سيقوم بـ:
- التحقق من وجود Docker
- إنشاء مجلد العمل
- إنشاء ملف docker-compose.yml
- بدء OpenWebUI و Ollama
- إنشاء سكريبت keep-alive

### الخطوة 2: الوصول إلى OpenWebUI

افتح المتصفح وانتقل إلى:
```
http://localhost:8080
```

---

## الطريقة 2: التثبيت اليدوي

### الخطوة 1: إنشاء مجلد العمل

```bash
mkdir -p ~/openwebui
cd ~/openwebui
```

### الخطوة 2: إنشاء ملف docker-compose.yml

انسخ محتوى الملف من `configs/openwebui-docker-compose.yml`:

```bash
cp /home/ubuntu/skills/persistent-app-hosting/configs/openwebui-docker-compose.yml ~/openwebui/docker-compose.yml
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
NAME       STATUS
openwebui  Up X seconds
ollama     Up X seconds
```

---

## الوصول والإعداد الأولي

### 1. الوصول إلى الواجهة

```
URL: http://localhost:8080
```

### 2. إنشاء حساب

عند الدخول لأول مرة:
- اضغط "Sign Up"
- أدخل اسم المستخدم والبريد الإلكتروني
- اختر كلمة مرور قوية
- اضغط "Create Account"

### 3. تسجيل الدخول

استخدم بيانات الحساب التي أنشأتها.

---

## إعداد النماذج (Models)

### تحميل نموذج محلي باستخدام Ollama

#### الخطوة 1: الوصول إلى Ollama

```bash
# في terminal منفصل
docker exec -it ollama bash
```

#### الخطوة 2: تحميل نموذج

```bash
# تحميل نموذج llama2 (أساسي)
ollama pull llama2

# أو نموذج أخف (mistral)
ollama pull mistral

# أو نموذج أكثر قوة (neural-chat)
ollama pull neural-chat
```

#### الخطوة 3: التحقق من النماذج المثبتة

```bash
ollama list
```

### استخدام نماذج خارجية (OpenAI, etc.)

#### إضافة مفتاح OpenAI

1. في OpenWebUI، اذهب إلى **Settings** → **Models**
2. اختر **OpenAI** من القائمة
3. أدخل مفتاح API الخاص بك
4. اضغط **Save**

#### إضافة نماذج أخرى

يمكنك إضافة نماذج من:
- Anthropic Claude
- Google PaLM
- Hugging Face
- وغيرها...

---

## الخيارات المتقدمة

### تفعيل المصادقة

عدّل `docker-compose.yml`:

```yaml
environment:
  - WEBUI_AUTH=true
  - WEBUI_AUTH_TRUSTED_EMAIL_HEADER=X-Remote-User
```

### تغيير المنفذ

إذا كان المنفذ 8080 مشغولاً:

```yaml
ports:
  - "8888:8080"  # استخدم 8888 بدلاً من 8080
```

### إضافة متغيرات بيئة مخصصة

```yaml
environment:
  - WEBUI_AUTH=true
  - WEBUI_AUTH_TRUSTED_EMAIL_HEADER=X-Remote-User
  - WEBUI_SECRET_KEY=your-secret-key
  - WEBUI_SESSION_TIMEOUT=3600
```

### زيادة موارد Ollama

للنماذج الكبيرة، زيادة الموارد:

```yaml
ollama:
  deploy:
    resources:
      limits:
        cpus: '4'
        memory: 8G
      reservations:
        cpus: '2'
        memory: 4G
```

---

## المراقبة والصيانة

### عرض السجلات

```bash
# السجلات الحية
docker-compose logs -f

# سجلات OpenWebUI فقط
docker-compose logs -f openwebui

# سجلات Ollama فقط
docker-compose logs -f ollama
```

### التحقق من الصحة

```bash
# استخدم السكريبت المرفق
bash /home/ubuntu/skills/persistent-app-hosting/scripts/health-check.sh

# أو يدويًا
curl http://localhost:8080/health
curl http://localhost:11434/api/tags
```

### إعادة التشغيل

```bash
# إعادة تشغيل الخدمة
docker-compose restart

# إعادة تشغيل OpenWebUI فقط
docker-compose restart openwebui

# إعادة تشغيل Ollama فقط
docker-compose restart ollama
```

### التحديث إلى نسخة أحدث

```bash
# سحب الصور الأحدث
docker pull ghcr.io/open-webui/open-webui:latest
docker pull ollama/ollama:latest

# إعادة تشغيل الخدمة
docker-compose down
docker-compose up -d
```

---

## تشغيل كخدمة systemd (اختياري)

### 1. نسخ ملف الخدمة

```bash
sudo cp /home/ubuntu/skills/persistent-app-hosting/configs/openwebui.service /etc/systemd/system/
```

### 2. تحديث systemd

```bash
sudo systemctl daemon-reload
```

### 3. تفعيل الخدمة

```bash
sudo systemctl enable openwebui.service
```

### 4. بدء الخدمة

```bash
sudo systemctl start openwebui.service
```

### 5. التحقق من الحالة

```bash
sudo systemctl status openwebui.service
```

### إدارة الخدمة

```bash
# إيقاف الخدمة
sudo systemctl stop openwebui.service

# إعادة تشغيل الخدمة
sudo systemctl restart openwebui.service

# عرض السجلات
sudo journalctl -u openwebui.service -f
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

### المشكلة: المنفذ 8080 مشغول

```bash
# العثور على العملية المستخدمة للمنفذ
lsof -i :8080

# قتل العملية (إذا لزم الأمر)
kill -9 <PID>
```

### المشكلة: الخدمة لا تبدأ

```bash
# عرض السجلات التفصيلية
docker-compose logs openwebui

# التحقق من توفر الذاكرة
free -h

# التحقق من مساحة القرص
df -h
```

### المشكلة: بطء الأداء

```bash
# تحقق من استخدام الموارد
docker stats

# تقليل حجم النموذج المستخدم
# أو زيادة الموارد المخصصة
```

### المشكلة: Ollama لا يستجيب

```bash
# إعادة تشغيل Ollama
docker-compose restart ollama

# التحقق من الاتصال
curl http://localhost:11434/api/tags
```

---

## أمثلة عملية

### مثال 1: محادثة بسيطة

1. افتح OpenWebUI
2. اختر نموذج من القائمة
3. اكتب رسالتك
4. اضغط Send

### مثال 2: استخدام نموذج محلي

1. تأكد من تحميل النموذج: `ollama pull llama2`
2. في OpenWebUI، اختر "llama2" من قائمة النماذج
3. ابدأ المحادثة

### مثال 3: استخدام OpenAI

1. أضف مفتاح OpenAI في Settings
2. اختر "gpt-4" أو "gpt-3.5-turbo"
3. ابدأ المحادثة

---

## النسخ الاحتياطية

### نسخ احتياطية من البيانات

```bash
# إنشاء نسخة احتياطية من OpenWebUI
docker run --rm -v openwebui_data:/data -v $(pwd):/backup \
  busybox tar czf /backup/openwebui-backup.tar.gz -C /data .

# إنشاء نسخة احتياطية من Ollama
docker run --rm -v ollama_data:/data -v $(pwd):/backup \
  busybox tar czf /backup/ollama-backup.tar.gz -C /data .
```

### استعادة من نسخة احتياطية

```bash
# استعادة OpenWebUI
docker run --rm -v openwebui_data:/data -v $(pwd):/backup \
  busybox tar xzf /backup/openwebui-backup.tar.gz -C /data

# استعادة Ollama
docker run --rm -v ollama_data:/data -v $(pwd):/backup \
  busybox tar xzf /backup/ollama-backup.tar.gz -C /data
```

---

## الخطوات التالية

1. **استكشاف النماذج**: جرب نماذج مختلفة
2. **تخصيص الإعدادات**: اضبط الإعدادات حسب احتياجاتك
3. **إضافة Integrations**: ربط مع خدمات أخرى
4. **المراقبة**: راقب الأداء والموارد
5. **النسخ الاحتياطية**: قم بعمل نسخ احتياطية منتظمة

---

## الموارد الإضافية

- [توثيق OpenWebUI](https://docs.openwebui.com/)
- [توثيق Ollama](https://ollama.ai/)
- [مجتمع OpenWebUI](https://github.com/open-webui/open-webui)
- [Docker Documentation](https://docs.docker.com/)
