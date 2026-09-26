FROM barichello/godot-ci:4.3 AS build
WORKDIR /app
COPY . .

# Build dedicated PNG mob frames from the original sprite sheet, then import them.
RUN mkdir -p assets/mobs/generated && \
    godot --headless --script scripts/tools/extract_mob_pngs.gd && \
    godot --headless --editor --quit

# Parse-check the scripts changed by this update before integration tests.
RUN godot --headless --check-only --script scripts/items.gd && \
    godot --headless --check-only --script scripts/account_store.gd && \
    godot --headless --check-only --script scripts/world.gd && \
    godot --headless --check-only --script scripts/main.gd

# Full integration test before export: accounts/save, mining/drop pickup,
# finite boundaries and desert generation, then lake/Leviathan progression.
RUN godot --headless --script tests/smoke.gd
RUN godot --headless --script tests/lake_smoke.gd

# Web build
RUN mkdir -p build/web && godot --headless --export-release "Web" build/web/index.html

# Android APK build. Uses the same Godot CI image/signing identity as the existing APK workflow
# so this APK can update the previously installed Dreads Craft debug build.
ENV HOME=/root
ENV XDG_CONFIG_HOME=/tmp/godot-config
ENV XDG_DATA_HOME=/root/.local/share
ENV ANDROID_HOME=/usr/lib/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV GODOT_ANDROID_KEYSTORE_DEBUG_PATH=/root/debug.keystore
ENV GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
ENV GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
ENV GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/root/debug.keystore
ENV GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey
ENV GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android

RUN mkdir -p build/android /tmp/godot-config/godot && \
    printf '%s\n' \
      '[gd_resource type="EditorSettings" format=3]' \
      '' \
      '[resource]' \
      'export/android/java_sdk_path = "/usr/lib/jvm/java-17-openjdk-amd64"' \
      'export/android/android_sdk_path = "/usr/lib/android-sdk"' \
      'export/android/debug_keystore = "/root/debug.keystore"' \
      'export/android/debug_keystore_user = "androiddebugkey"' \
      'export/android/debug_keystore_pass = "android"' \
      > /tmp/godot-config/godot/editor_settings-4.3.tres && \
    test -f /root/.local/share/godot/export_templates/4.3.stable/android_release.apk && \
    test -f /root/debug.keystore && \
    godot --headless --export-release "Android" build/android/DreadsCraft.apk && \
    test -s build/android/DreadsCraft.apk

FROM node:20-alpine
WORKDIR /srv
COPY package.json server.js ./
RUN npm install --omit=dev
COPY --from=build /app/build/web ./public
COPY --from=build /app/build/android/DreadsCraft.apk ./public/DreadsCraft.apk
ENV PORT=8080
EXPOSE 8080
CMD ["node","server.js"]
