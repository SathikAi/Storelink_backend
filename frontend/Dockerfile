# Stage 1: Build Flutter Web
FROM ubuntu:22.04 AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter Web
RUN flutter config --enable-web

# Copy project files
WORKDIR /app
COPY . .

# Build for web with production API base URL
# Note: In a real CI/CD, you would pass this as an ARG
ARG API_BASE_URL=http://localhost/v1
ARG WEB_APP_URL=http://localhost
RUN flutter pub get
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=WEB_APP_URL=${WEB_APP_URL}

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
