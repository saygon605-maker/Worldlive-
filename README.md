# WorldLive 🌍

تطبيق متكامل للمراسلة + المنشورات + البث المباشر + التفاعلات

## المميزات

### الدردشة
- رسائل نصية فورية
- إرسال صور وفيديوهات
- أزرار مكالمات صوتية وفيديو (جاهزة لربط Agora)
- حالة الاتصال

### المنشورات والتفاعل
- نشر نصوص + صور + فيديوهات
- إعجاب (Like)
- تعليقات
- مشاركة

### البث المباشر
- بدء بث مباشر
- قائمة البثوث الحية
- هيكل جاهز لربط WebRTC أو Agora

### التصميم
- واجهة داكنة عصرية
- ألوان: بنفسجي (#6C5CE7) + فيروزي (#00CEC9)
- دعم كامل للعربية (RTL)

---

## التشغيل

```bash
cd worldlive
flutter create . --project-name worldlive --org com.worldlive
flutter pub get
```

### إعداد Firebase
1. أنشئ مشروع في Firebase Console
2. فعّل Authentication (Email + Google)
3. فعّل Firestore + Storage
4. ضع `google-services.json` في `android/app/`

### قواعد Firestore المقترحة
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### قواعد Storage
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## تفعيل المكالمات والبث المباشر (اختياري)

أضف حزمة Agora:

```yaml
agora_rtc_engine: ^6.3.2
```

ثم أضف App ID من [Agora Console](https://console.agora.io).

---

## البناء والنشر

```bash
flutter build appbundle --release
```

ثم ارفع الملف على Google Play Console.

---

صُنع لـ WorldLive 💜
