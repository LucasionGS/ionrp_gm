# IonRP Gamemode - Image Assets

This folder should contain the following image files:

## icon24.png
- **Size**: 24x24 pixels (can be up to 32x32)
- **Format**: PNG with transparency
- **Purpose**: Appears in the server browser and gamemode selection menu
- **Description**: Small icon representing your gamemode

## logo.png
- **Size**: 128 pixels high, up to 1024 pixels wide
- **Recommended**: 288x128 pixels (default size)
- **Format**: PNG with transparency
- **Purpose**: Appears in the main menu when your gamemode is selected
- **Description**: Full logo/banner for your gamemode

## How to Add Images

1. Create your icon and logo images using an image editor (GIMP, Photoshop, etc.)
2. Save them with the exact filenames: `icon24.png` and `logo.png`
3. Place them in the root directory: `/home/ion/development/ionrp/`

## Background Images (Optional)

You can also add background images for the menu:
- Place JPG images in the `backgrounds/` folder
- All images must be in JPG format
- They will be randomly displayed in the main menu

To add backgrounds:
```
mkdir /home/ion/development/ionrp/backgrounds
# Then add your .jpg files there
```
