#!/bin/bash

echo "========================================"
echo "Building and installing Pastiera"
echo "========================================"
echo ""

# Set JAVA_HOME to Android Studio's JDK
export JAVA_HOME="$HOME/Applications/Android Studio.app/Contents/jbr/Contents/Home"

ls -la "$JAVA_HOME"

# Check if JAVA_HOME is valid
if [ ! -f "$JAVA_HOME/bin/java" ]; then
    echo "ERROR: Java not found at $JAVA_HOME"
    echo "Make sure Android Studio is installed."
    exit 1
fi

# Find ADB path
ADB_PATH=""
if [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
    ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
elif [ -f "./local.properties" ]; then
    SDK_DIR=$(grep "sdk.dir" ./local.properties | cut -d'=' -f2)
    if [ -f "$SDK_DIR/platform-tools/adb" ]; then
        ADB_PATH="$SDK_DIR/platform-tools/adb"
    fi
fi

if [ -z "$ADB_PATH" ]; then
    ADB_PATH=$(which adb 2>/dev/null)
fi

if [ -z "$ADB_PATH" ] || [ ! -f "$ADB_PATH" ]; then
    echo "ERROR: ADB not found."
    echo "Make sure Android SDK is installed and platform-tools is present."
    exit 1
fi

# Check if device is connected
echo "Checking for connected device..."
DEVICE_COUNT=$("$ADB_PATH" devices | grep -v "List" | grep "device$" | wc -l | tr -d ' ')
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "WARNING: No Android device connected."
    echo "Connect a device or start an emulator before continuing."
    echo ""
    echo "Building APK..."
    ./gradlew assembleDebug
    if [ $? -eq 0 ]; then
        echo ""
        echo "========================================"
        echo "APK built successfully!"
        echo "========================================"
        echo "APK available at: app/build/outputs/apk/debug/app-debug.apk"
        exit 0
    else
        echo ""
        echo "ERROR: Build failed."
        exit 1
    fi
fi

# Compile and install the app
./gradlew installDebug

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Installation completed successfully!"
    echo "========================================"
    echo ""
    echo "Launching the app on device..."
    
    # Launch the app on Android device
    "$ADB_PATH" shell am start -n it.palsoftware.pastiera/.MainActivity
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "App launched successfully!"
        exit 0
    else
        echo ""
        echo "ERROR: Failed to launch the app."
        echo "Make sure the device is connected and ADB is configured correctly."
        exit 1
    fi
else
    echo ""
    echo "ERROR: Build/installation failed."
    echo "Check the errors above."
    exit 1
fi

