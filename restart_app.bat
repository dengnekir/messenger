@echo off
echo Flutter Uygulamasını Yeniden Başlatma
echo ---------------------------------
echo.

echo Eski oturumu sonlandırıyorum...
taskkill /F /IM flutter.exe /T 2>NUL
taskkill /F /IM dart.exe /T 2>NUL
taskkill /F /IM "emulator.exe" /T 2>NUL

echo Önbelleği temizliyorum...
flutter clean

echo Paketleri güncelliyorum...
flutter pub get

echo Uygulamayı yeniden başlatıyorum...
flutter run --no-sound-null-safety

echo.
echo İşlem tamamlandı.
pause 