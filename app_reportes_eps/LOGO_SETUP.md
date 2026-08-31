# 📸 Logo Setup Instructions

## Quick Start
The logo image needs to be saved to: `assets/images/logo.png`

### Option 1: Auto-Save (Recommended)
1. Save the EPS Sanitas logo image from the attachment
2. Right-click → Save As
3. Location: `c:\Users\Aprendiz\Downloads\pdf2\app_reportes_eps\assets\images\`
4. Filename: `logo.png`

### Option 2: Manual Copy
If you have the logo file elsewhere:
1. Copy your logo image file
2. Paste into: `c:\Users\Aprendiz\Downloads\pdf2\app_reportes_eps\assets\images\`
3. Rename to: `logo.png`

## Supported Formats
- PNG ✅ (recommended)
- JPG ✅
- GIF ✅

## Logo Size Recommendations
- Recommended: 200x200px to 600x600px
- The app will scale it appropriately (50-60px in PDFs)

## Verification
After saving:
```bash
cd c:\Users\Aprendiz\Downloads\pdf2\app_reportes_eps
flutter pub get
flutter run -d chrome
```

The logo will appear in:
- PDF comprobantes (receipts) - top left corner
- PDF reporte general (general reports) - header section
