# Android Development Environment
# Activated via profile module: modules=android

# Android SDK (installed by Android Studio)
if [[ -d "$HOME/Library/Android/sdk" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    [[ -d "$ANDROID_HOME/platform-tools" ]] && export PATH="$ANDROID_HOME/platform-tools:$PATH"
    [[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]] && export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi

# Android NDK (brew install android-ndk)
if [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/share/android-ndk" ]]; then
    export ANDROID_NDK_HOME="${HOMEBREW_PREFIX:-/opt/homebrew}/share/android-ndk"
fi
