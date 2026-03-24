# Persistent Application Hosting

**استضافة التطبيقات بشكل مستمر 24/7 على بيئة أي Agent**

> حوّل بيئة الـ Agent المؤقتة إلى خادم دائم 🚀

---

## المشكلة

بيئات الـ Sandbox في الـ Agents (مثل Manus, Replit, وغيرها) تدخل حالة النوم بعد فترة من عدم النشاط. هذا يوقف جميع التطبيقات المستضافة.

## الحل

مجموعة حلول وسكريبتات جاهزة تحافظ على نشاط البيئة وتضمن استمرار عمل تطبيقاتك.

### 7 حلول متاحة:

| # | الحل | سهولة الإعداد | الموثوقية |
|---|------|-------------|---------|
| 1 | 🕐 Keep-Alive Cron | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 2 | 🐳 Docker + restart: always | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| 3 | ⚙️ systemd Services | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| 4 | 📦 pm2 / supervisor | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 5 | 🖥️ tmux + Watchdog | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 6 | 🌐 External Uptime Monitor | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 7 | ☁️ Web Deployment | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## البدء السريع

### نشر n8n
```bash
bash scripts/deploy-n8n.sh
```

### نشر OpenWebUI
```bash
bash scripts/deploy-openwebui.sh
```

### تفعيل Keep-Alive
```bash
bash scripts/keep-alive.sh
```

### فحص صحة الخدمات
```bash
bash scripts/health-check.sh
```

## هيكل المشروع

```
persistent-app-hosting/
├── SKILL.md                    # التوثيق الرئيسي (مفصل)
├── README.md                   # هذا الملف
├── LICENSE                     # MIT License
├── scripts/
│   ├── deploy-n8n.sh          # نشر n8n تلقائي
│   ├── deploy-openwebui.sh    # نشر OpenWebUI تلقائي
│   ├── keep-alive.sh          # حفاظ على نشاط البيئة
│   ├── health-check.sh        # فحص صحة الخدمات
│   └── watchdog.sh            # مراقب العمليات
├── configs/
│   ├── n8n-docker-compose.yml
│   ├── openwebui-docker-compose.yml
│   ├── n8n.service
│   ├── openwebui.service
│   └── supervisor-app.conf
└── examples/
    ├── n8n-deployment-guide.md
    ├── openwebui-deployment-guide.md
    └── scheduled-tasks-example.md
```

## التوثيق المفصل

راجع [SKILL.md](SKILL.md) للتوثيق الكامل مع شرح كل حل وجدول المقارنة.

## التطبيقات المدعومة

- ✅ **n8n** — أتمتة Workflows
- ✅ **OpenWebUI** — واجهة ChatGPT مفتوحة المصدر
- ✅ **أي تطبيق آخر** — عدّل السكريبتات حسب حاجتك

## المتطلبات

- Linux (أي توزيعة)
- Bash shell
- Docker + docker-compose (اختياري)
- 2 GB RAM على الأقل
- اتصال إنترنت مستقر

## المساهمة

Pull requests مرحب بها! يمكنك:
- إضافة حلول جديدة
- تحسين السكريبتات الحالية
- إضافة دعم لتطبيقات أخرى
- ترجمة التوثيق

## الترخيص

[MIT License](LICENSE)

---

**صنع بـ ❤️ للمجتمع العربي**
