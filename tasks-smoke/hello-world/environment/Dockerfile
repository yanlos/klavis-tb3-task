FROM node:22.23.2-bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates curl git python3 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
CMD ["sleep", "infinity"]
