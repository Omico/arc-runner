FROM ghcr.io/actions/actions-runner:latest

ARG CACHE_BUSTER=1

RUN sudo rm -f /etc/apt/apt.conf.d/docker-clean

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    sudo ./bin/installdependencies.sh

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    sudo apt update && sudo apt upgrade -y

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    sudo apt install -y \
      apt-transport-https \
      p7zip-full \
      wget \
      zip \
      zstd

RUN wget -qO - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/chrome-keyring.gpg > /dev/null

RUN sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chrome-keyring.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    sudo apt update && sudo apt install -y google-chrome-stable

RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null

RUN echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    sudo apt update && sudo apt install -y \
    temurin-21-jdk \
    temurin-17-jdk \
    temurin-11-jdk \
    temurin-8-jdk

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash \
    && sudo apt install -y git-lfs

ENV GRADLE_HOME=/opt/gradle

RUN GRADLE_DISTRIBUTION_URL=$(curl -s "https://services.gradle.org/versions/current" | jq -r .downloadUrl); \
    curl -sL ${GRADLE_DISTRIBUTION_URL} -o /tmp/gradle.zip; \
    unzip /tmp/gradle.zip; \
    sudo mv gradle-* ${GRADLE_HOME}; \
    sudo ln -s ${GRADLE_HOME}/bin/gradle /usr/local/bin/gradle; \
    rm /tmp/gradle.zip

ENV ANDROID_ROOT=/usr/local/lib/android
ENV ANDROID_SDK_ROOT=${ANDROID_ROOT}/sdk
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}

RUN ANDROID_SDK_TOOLS_VERSION="13114758" \
    && curl https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -o /tmp/android-sdk-tools.zip \
    && sudo mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && sudo unzip -d ${ANDROID_SDK_ROOT}/cmdline-tools /tmp/android-sdk-tools.zip \
    && sudo mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/android-sdk-tools.zip

ENV PATH=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}

RUN yes | sudo sdkmanager --licenses

RUN sudo sdkmanager "platform-tools"

RUN sudo sdkmanager "platforms;android-34"
RUN sudo sdkmanager "build-tools;34.0.0"

RUN sudo sdkmanager "platforms;android-35"
RUN sudo sdkmanager "build-tools;35.0.0"
RUN sudo sdkmanager "build-tools;35.0.1"

RUN sudo sdkmanager "platforms;android-36"
RUN sudo sdkmanager "build-tools;36.0.0"

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    echo "Forcing with cache buster: $CACHE_BUSTER" \
    && sudo apt update && sudo apt upgrade -y

RUN echo "Forcing with cache buster: $CACHE_BUSTER" \
    && sudo sdkmanager --update \
    && sudo rm -rf ${ANDROID_SDK_ROOT}/.temp
