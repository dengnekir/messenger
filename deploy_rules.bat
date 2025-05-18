@echo off
echo Firebase Kurallarını Yükleme
echo --------------------------
echo.

REM Kuralların olduğu dosyayı oku
type firebase_rules.txt > firestore.rules

echo Firestore kuralları güncelleniyor...
firebase deploy --only firestore:rules

echo.
echo İşlem tamamlandı.
pause 