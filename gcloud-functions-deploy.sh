#!/bin/bash
GCP_PROJECT=$(gcloud config get-value project)

GCR_WATCHER_CONFIG="projects/${GCP_PROJECT}/secrets/gcr-watcher-config"
TRIGGER_BUILD_CONFIG="projects/${GCP_PROJECT}/secrets/trigger-build-config"
WEBHOOK_WATCHER_CONFIG="projects/${GCP_PROJECT}/secrets/webhook-watcher-config"

GCR_TOPIC="gcr"
BUILD_TOPIC="trigger-build"

gcloud functions deploy gcrWatcher \
  --runtime="nodejs10" \
  --trigger-topic="$GCR_TOPIC" \
  --set-env-vars="CONFIG=$GCR_WATCHER_CONFIG,BUILD_TOPIC=$BUILD_TOPIC"

gcloud functions deploy webhookWatcher \
  --runtime="nodejs10" --trigger-http --allow-unauthenticated \
  --set-env-vars="CONFIG=$WEBHOOK_WATCHER_CONFIG,BUILD_TOPIC=$BUILD_TOPIC"

gcloud functions deploy triggerBuild \
  --runtime="nodejs10" \
  --trigger-topic="$BUILD_TOPIC" \
  --set-env-vars="CONFIG=$TRIGGER_BUILD_CONFIG"

WEBHOOK_URL=$(gcloud functions describe webhookWatcher --format=value\(httpsTrigger.url\))
echo
echo "Webhook URL: $WEBHOOK_URL"
