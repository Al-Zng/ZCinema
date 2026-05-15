# ZCinema

تطبيق iOS احترافي لمشاهدة الأفلام والمسلسلات والانمي.

---

## المميزات

- واجهة داكنة بتصميم Netflix
- تصفح الأفلام والمسلسلات والانمي
- بحث فوري
- مشغل فيديو احترافي داخلي (AVPlayer)
- استخراج تلقائي لروابط mp4/m3u8 من جميع السيرفرات
- نظام حلقات ومواسم
- شريط تقدم قابل للسحب
- تخطي 10 ثواني للأمام والخلف
- التنقل بين الحلقات من داخل المشغل
- دعم الوضع الأفقي والعمودي

---

## هيكل المشروع

```
ZCinema/
├── ZCinema.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/ZCinema.xcscheme
├── ZCinema/
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── ZCinemaApp.swift
│   │   │   └── ContentView.swift
│   │   ├── Models/
│   │   │   └── Models.swift
│   │   ├── Services/
│   │   │   ├── EgyBestScraper.swift   ← HTML scraping engine
│   │   │   └── StreamResolver.swift   ← Auto mp4/m3u8 extractor
│   │   ├── ViewModels/
│   │   │   └── ViewModels.swift
│   │   ├── Views/
│   │   │   ├── Home/
│   │   │   │   ├── HomeView.swift
│   │   │   │   ├── MediaListViews.swift
│   │   │   │   └── SearchView.swift
│   │   │   ├── Detail/
│   │   │   │   └── DetailView.swift
│   │   │   ├── Player/
│   │   │   │   └── PlayerView.swift   ← Professional AVPlayer
│   │   │   └── Components/
│   │   │       └── MediaCard.swift
│   │   └── Utils/
│   │       ├── ThemeManager.swift
│   │       └── ImageLoader.swift
│   └── Resources/
│       ├── Info.plist
│       └── Assets.xcassets/
├── .github/workflows/
│   └── build.yml                      ← GitHub Actions CI/CD
└── Package.swift
```

---

## كيفية البناء

### محلياً (Xcode)

1. افتح `ZCinema.xcodeproj` في Xcode 15+
2. اختر الـ Target Device
3. اضغط `Cmd+R` للتشغيل

Xcode سيقوم تلقائياً بتحميل SwiftSoup عند أول فتح للمشروع.

### عبر GitHub Actions

#### IPA بدون توقيع (للتثبيت عبر AltStore/Sideloadly)

1. ارفع المشروع على GitHub
2. اضغط على **Actions** → **Build ZCinema IPA** → **Run workflow**
3. بعد اكتمال البناء، حمّل الـ IPA من **Artifacts**
4. ثبّته عبر **AltStore** أو **Sideloadly** أو **TrollStore**

#### IPA موقع (للتوزيع)

أضف هذه الـ Secrets في إعدادات الـ Repo:

| Secret | الوصف |
|--------|-------|
| `CERTIFICATE_BASE64` | شهادة p12 مُشفّرة بـ base64 |
| `CERTIFICATE_PASSWORD` | كلمة سر الشهادة |
| `PROVISIONING_PROFILE_BASE64` | Provisioning Profile مُشفّر بـ base64 |
| `KEYCHAIN_PASSWORD` | أي كلمة سر مؤقتة للـ Keychain |
| `TEAM_ID` | Apple Developer Team ID |

---

## كيف يعمل استخراج الروابط

```
المستخدم يضغط تشغيل
        ↓
DetailViewModel.fetchEpisodeDetail()
        ↓
EgyBestScraper.fetchMediaDetail() → يجلب صفحة الحلقة ويستخرج السيرفرات
        ↓
StreamResolver.resolveBestStream() → يفحص كل السيرفرات بالتوازي
        ↓
لكل سيرفر:
  1. فك تشفير base64 URL
  2. جلب صفحة السيرفر
  3. البحث عن mp4/m3u8/HLS
  4. أنماط مدعومة:
     - CyberVynx / DoodStream / Mixdrop
     - Streamtape / Lulustream
     - JWPlayer / HLS أي مشغل
        ↓
أفضل رابط (mp4 > m3u8 > iframe)
        ↓
AVPlayer يشغل الرابط مباشرة
```

---

## المتطلبات

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
- [SwiftSoup](https://github.com/scinfu/SwiftSoup) (يُحمَّل تلقائياً)

---

## ملاحظات

- التطبيق يستخدم `NSAllowsArbitraryLoads = true` للوصول لروابط HTTP
- يدعم تشغيل الصوت في الخلفية (`UIBackgroundModes: audio`)
- الشاشة لا تُغلَق أثناء التشغيل (`isIdleTimerDisabled = true`)
