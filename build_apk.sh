#!/bin/bash
# Script para compilar la app Outdoor Social en APK
# Ejecutar: bash build_apk.sh

set -e

echo "=== Outdoor Social - Build APK ==="

# 1. Verificar/Instalar Flutter
if ! command -v flutter &> /dev/null; then
    echo "[1/6] Instalando Flutter..."
    git clone https://github.com/flutter/flutter.git ~/flutter --depth 1 -b stable
    export PATH="$PATH:$HOME/flutter/bin"
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
else
    echo "[1/6] Flutter ya instalado"
fi

# 2. Verificar Dart SDK
echo "[2/6] Verificando Flutter..."
flutter --version 2>&1 | head -3

# 3. Generar estructura del proyecto
echo "[3/6] Generando estructura Android..."
cd frontend
flutter create --project-name outdoor_app . 2>/dev/null || true
mkdir -p lib/config lib/models lib/services lib/providers lib/screens lib/widgets

# 4. Instalar dependencias
echo "[4/6] Instalando dependencias..."
flutter pub get

# 5. Verificar Android SDK
echo "[5/6] Verificando Android SDK..."
flutter doctor -v 2>&1 | head -20

# 6. Compilar APK
echo "[6/6] Compilando APK..."
flutter build apk --release

echo ""
echo "=== APK generado en: frontend/build/app/outputs/flutter-apk/app-release.apk ==="
