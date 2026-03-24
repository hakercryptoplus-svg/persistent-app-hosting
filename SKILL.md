# Persistent Application Hosting Skill

استضافة التطبيقات بشكل مستمر 24/7 على بيئة أي Agent

## نظرة عامة

هذا الـ Skill يوفر حلولاً عملية وسكريبتات جاهزة لاستضافة التطبيقات (مثل n8n، OpenWebUI، أو أي تطبيق آخر) بشكل مستمر على بيئة الـ Agent دون أن تتوقف بعد فترة من عدم النشاط.

### المشكلة الأساسية

بيئات الـ Sandbox في الـ Agents تدخل حالة "النوم" (sleep) بعد فترة من عدم النشاط:
- **المستخدمون المجانيون:** 7 أيام من عدم النشاط
- **المستخدمون Pro:** 21 يوماً من عدم النشاط
- **بيئات أخرى:** تختلف حسب المزود (Replit, Render, Railway, etc.)

عندما تدخل البيئة حالة النوم، تتوقف جميع التطبيقات المستضافة عليها عن العمل.

---

## الحلول المتاحة

### الحل 1: Keep-Alive عبر Cron / Scheduled Tasks ⭐ الأسهل

**الفكرة:** تشغيل سكريبت دوري يحافظ على نشاط البيئة ويفحص صحة الخدمات.

```bash
# إنشاء سكريبت keep-alive
bash scripts/keep-alive.sh

# جدولة التشغيل (حسب بيئة الـ Agent)
# crontab:
# 0 */6 * * * /path/to/keep-alive.sh
# أو عبر schedule tool:
# schedule --type cron --cron "0 */6 * * *" --prompt "bash keep-alive.sh"
```

**متى تستخدمه:** أسرع حل، يعمل مع أي تطبيق موجود.

---

### الحل 2: Docker + docker-compose مع restart: always

**الفكرة:** تشغيل التطبيقات داخل Docker containers مع سياسة إعادة التشغيل التلقائي.

```bash
# نشر n8n
bash scripts/deploy-n8n.sh

# نشر OpenWebUI
bash scripts/deploy-openwebui.sh
```

**متى تستخدمه:** عندما تحتاج عزل التطبيقات وإدارة dependencies.

---

### الحل 3: systemd Services

**الفكرة:** تسجيل التطبيق كخدمة نظام مع إعادة تشغيل تلقائي عند الفشل.

```bash
sudo cp configs/n8n.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now n8n.service
```

**متى تستخدمه:** بيئات Linux كاملة مع صلاحيات sudo.

---

### الحل 4: Process Manager (pm2 / supervisor)

**الفكرة:** استخدام مدير عمليات لتشغيل التطبيقات ومراقبتها.

```bash
# باستخدام pm2 (Node.js apps)
npm install -g pm2
pm2 start app.js --name myapp
pm2 save
pm2 startup

# باستخدام supervisor (Python/أي تطبيق)
sudo apt install supervisor
sudo cp configs/supervisor-app.conf /etc/supervisor/conf.d/
sudo supervisorctl reread && sudo supervisorctl update
```

**متى تستخدمه:** تطبيقات Node.js أو Python بدون Docker.

---

### الحل 5: tmux / screen + Watchdog

**الفكرة:** تشغيل التطبيق في جلسة terminal مستمرة مع سكريبت مراقبة.

```bash
# تشغيل في tmux
tmux new-session -d -s myapp "cd /path/to/app && node server.js"

# سكريبت watchdog
bash scripts/watchdog.sh myapp "node server.js" /path/to/app
```

**متى تستخدمه:** بيئات بسيطة بدون Docker أو systemd.

---

### الحل 6: External Uptime Monitor (UptimeRobot / Healthchecks.io)

**الفكرة:** خدمة خارجية مجانية ترسل HTTP request للتطبيق كل فترة، مما يبقيه نشطاً.

1. سجل حساب مجاني في [UptimeRobot](https://uptimerobot.com/) أو [Healthchecks.io](https://healthchecks.io/)
2. أضف monitor يرسل GET request لرابط تطبيقك كل 5 دقائق
3. سيتلقى التطبيق طلبات مستمرة تمنعه من النوم

**متى تستخدمه:** عندما يكون للتطبيق رابط عام (public URL).

---

### الحل 7: Web Deployment (الأفضل للإنتاج)

**الفكرة:** نشر التطبيق على منصة استضافة دائمة.

**خيارات مجانية/رخيصة:**
- **Railway** — $5 رصيد مجاني شهرياً
- **Render** — free tier للويب
- **Fly.io** — free tier سخي
- **Vercel / Netlify** — للتطبيقات الثابتة و serverless

**متى تستخدمه:** للإنتاج الحقيقي، أعلى موثوقية.

---

## جدول المقارنة

| الحل | التوفر 24/7 | الموثوقية | سهولة الإعداد | التكلفة | يحتاج Docker | يحتاج sudo |
|------|-----------|---------|------------|--------|-------------|-----------|
| Keep-Alive Cron | ⚠️ جزئي | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | مجاني | ❌ | ❌ |
| Docker + restart | ⚠️ جزئي | ⭐⭐⭐⭐ | ⭐⭐⭐ | مجاني | ✅ | ❌ |
| systemd | ⚠️ جزئي | ⭐⭐⭐⭐ | ⭐⭐⭐ | مجاني | ❌ | ✅ |
| pm2 / supervisor | ⚠️ جزئي | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | مجاني | ❌ | ❌ |
| tmux + watchdog | ⚠️ جزئي | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | مجاني | ❌ | ❌ |
| External Monitor | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | مجاني | ❌ | ❌ |
| Web Deployment | ✅ 24/7 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | مجاني-$ | ❌ | ❌ |

> 💡 **نصيحة:** ادمج أكثر من حل! مثلاً: Docker + Keep-Alive Cron + External Monitor = أعلى موثوقية.

---

## البدء السريع

### 1. تثبيت Docker (اختياري)

```bash
sudo apt-get update && sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER
sudo systemctl enable --now docker
```

### 2. نشر تطبيقك

```bash
# n8n
bash scripts/deploy-n8n.sh

# OpenWebUI
bash scripts/deploy-openwebui.sh

# أي تطبيق آخر — عدّل السكريبتات حسب حاجتك
```

### 3. تفعيل Keep-Alive

```bash
bash scripts/keep-alive.sh
```

---

## هيكل الملفات

```
persistent-app-hosting/
├── SKILL.md                              # هذا الملف
├── README.md                             # شرح عام
├── LICENSE                               # MIT License
├── scripts/
│   ├── deploy-n8n.sh                    # نشر n8n تلقائي
│   ├── deploy-openwebui.sh              # نشر OpenWebUI تلقائي
│   ├── keep-alive.sh                    # الحفاظ على نشاط البيئة
│   ├── health-check.sh                  # فحص صحة الخدمات
│   └── watchdog.sh                      # مراقب العمليات (tmux)
├── configs/
│   ├── n8n-docker-compose.yml           # إعداد Docker لـ n8n
│   ├── openwebui-docker-compose.yml     # إعداد Docker لـ OpenWebUI
│   ├── n8n.service                      # خدمة systemd لـ n8n
│   ├── openwebui.service                # خدمة systemd لـ OpenWebUI
│   └── supervisor-app.conf              # إعداد supervisor
└── examples/
    ├── n8n-deployment-guide.md          # دليل n8n مفصل
    ├── openwebui-deployment-guide.md    # دليل OpenWebUI مفصل
    └── scheduled-tasks-example.md       # أمثلة مهام مجدولة
```

---

## الأسئلة الشائعة

**س: أي حل أختار؟**
- للتجربة السريعة: Keep-Alive Cron
- للتطوير: Docker + Keep-Alive
- للإنتاج: Web Deployment

**س: هل يمكن استخدام أكثر من حل؟**
نعم! الدمج يزيد الموثوقية.

**س: بيئتي ما فيها Docker؟**
استخدم pm2 أو tmux + watchdog أو External Monitor.

**س: كيف أتعامل مع فشل الخدمة؟**
كل الحلول تتضمن إعادة تشغيل تلقائي. استخدم `health-check.sh` للتشخيص.

---

## المساهمة

Pull requests مرحب بها! أضف حلول جديدة، حسّن السكريبتات، أو أضف دعم لتطبيقات أخرى.

## الترخيص

MIT License — استخدم بحرية مع الإشارة للمصدر.
