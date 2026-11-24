# Rewire – אפליקציית זמן מסך ל-iOS

אפליקציה מלאה ב-SwiftUI לשליטה בזמן מסך. היא בנויה על ה-Screen Time API של אפל:
**FamilyControls**, **ManagedSettings** ו-**DeviceActivity**.

## מה יש באפליקציה

| פיצ'ר | איפה בקוד |
|---|---|
| שאלון פתיחה (10 שאלות) עם ציון Brain Rot | `App/Models/Quiz.swift`, `App/Views/Onboarding/IntroViews.swift` |
| בשאלון: כמה זמן מסך יש לך היום ומה היעד, עם סליידר ומשוב חי | `App/Views/Onboarding/ScreenTimeInputViews.swift` |
| התקדמות מול היעד היומי בדוח של היום, ועריכת היעד בהגדרות | `Extensions/Report/ReportViews.swift`, `SettingsView` |
| מסך "מחשב…", ציון מול ממוצע, תחזית של שנים שהולכות לטלפון | `App/Views/Onboarding/ResultViews.swift` |
| חיבור לזמן מסך של אפל (`AuthorizationCenter`) | `PermissionView` ב-`SetupViews.swift` |
| בחירת אפליקציות, קטגוריות ואתרים (`FamilyActivityPicker`) | `SelectAppsView`, `SelectionSummary` |
| מגבלה יומית: חסימה אוטומטית כשנגמר הזמן, והתראה 5 דקות לפני | `ActivityScheduler.refreshDailyLimit` ← `Extensions/Monitor` |
| חסימה מתוזמנת (לילה, לימודים, עבודה) | `ActivityScheduler.refreshSchedule` |
| סשן פוקוס: "חסום עכשיו" עם טיימר | `FocusView` |
| מסך חסימה מותאם, עם ציטוטים ומונה של ניסיונות פתיחה | `Extensions/ShieldConfiguration` |
| כפתורי מסך החסימה: סגירה או בקשת שחרור | `Extensions/ShieldAction` |
| שחרור עם חיכוך: נשימה והמתנה, מספר שחרורים מוגבל ביום, ונעילה מחדש אוטומטית | `UnlockFlowView` |
| מצב קשוח: בלי שחרורים ובלי סיום מוקדם של סשן | `SettingsView` |
| דוחות זמן מסך: היום, לפי אפליקציה, הרמות טלפון, גרף שבועי | `Extensions/Report` |
| רצף ימים, שיא, דקות פוקוס | `SharedStore` |
| התחייבות ב"החזקת אצבע" | `CommitmentView` |

## איך מריצים

> חובה **Mac עם Xcode 15 ומעלה** ו**אייפון אמיתי**. ה-Screen Time API לא עובד בסימולטור.

1. מתקינים XcodeGen ומייצרים את הפרויקט:
   ```bash
   brew install xcodegen
   ```
   ```bash
   cd Rewire && xcodegen generate && open Rewire.xcodeproj
   ```
2. ב-`project.yml` משנים את:
   - `DEVELOPMENT_TEAM` ל-Team ID שלך.
   - `com.example.rewire` ל-Bundle ID שלך (בכל 5 ה-targets).
   - `group.com.example.rewire` ל-App Group שלך. הוא מופיע גם ב-`Shared/SharedConstants.swift`.
3. ב-Apple Developer:
   - יוצרים App Group ומשייכים אותו לאפליקציה ולשלוש ההרחבות (Monitor, ShieldConfiguration, ShieldAction).
   - מפעילים את ה-capability **Family Controls** בכל ה-App IDs.
4. מריצים על המכשיר (Development). ההרשאה `com.apple.developer.family-controls` עובדת בפיתוח בלי אישור מיוחד.

### לפני העלאה ל-App Store
צריך לבקש מאפל את **Family Controls (Distribution) entitlement** בטופס:
https://developer.apple.com/contact/request/family-controls-distribution
הבקשה מוגשת לכל Bundle ID: האפליקציה וכל אחת מ-4 ההרחבות.

## ארכיטקטורה

```
App (SwiftUI)
 ├─ AppModel ── SharedStore (App Group UserDefaults) ◄── משותף לכל ההרחבות
 ├─ ActivityScheduler ── DeviceActivityCenter.startMonitoring(...)
 └─ ShieldController ── ManagedSettingsStore("rewire")

Extensions
 ├─ Monitor          ← iOS מעיר אותה: תחילת/סוף אינטרוול, הגעה לסף
 ├─ ShieldConfig     ← מצייר את מסך החסימה
 ├─ ShieldAction     ← לחיצות על כפתורי מסך החסימה
 └─ Report           ← קורא ומציג את נתוני זמן המסך (sandbox)
```

- **ShieldController.reconcile()** מחשב בכל פעם אם צריך לחסום ולמה: שחרור זמני, אחריו סשן, אחריו מגבלה, ואחריו תזמון. כך האפליקציה וההרחבות לא מתנגשות זו בזו.
- **אינטרוולים קצרים מ-15 דקות.** DeviceActivity דורש לפחות 15 דקות, אז תחילת האינטרוול נקבעת בעבר, ורק `intervalDidEnd` משמש כטיימר. ראו `scheduleOneShot`.
- **שחרור ממסך החסימה.** הרחבה לא יכולה לפתוח את האפליקציה, ולכן נשלחת התראה. לחיצה עליה פותחת את מסך השחרור.

## מגבלות של אפל שכדאי להכיר
- נתוני השימוש זמינים רק בתוך הרחבת ה-Report, ואי אפשר להוציא אותם לאפליקציה.
- להרחבת ה-Monitor יש מגבלת זיכרון של כ-6MB, ולכן היא נשארת רזה.
- `eventDidReachThreshold` מגיע לפעמים באיחור של דקה או שתיים. זו התנהגות של iOS.
