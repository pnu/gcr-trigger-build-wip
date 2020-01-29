#!/bin/bash
GCP_PROJECT=$(gcloud config get-value project)

GCR_WATCHER_CONFIG="projects/${GCP_PROJECT}/secrets/gcr-watcher-config"
TRIGGER_BUILD_CONFIG="projects/${GCP_PROJECT}/secrets/trigger-build-config"
WEBHOOK_WATCHER_CONFIG="projects/${GCP_PROJECT}/secrets/webhook-watcher-config"

## gcrWatcher config
##
cat <<EOD |
{
  "gcrAction": "INSERT",
  "gcrTag": "gcr.io/$GCP_PROJECT/build:latest",
  "buildMessage": "prerender"
}
EOD
gcloud beta secrets versions add $GCR_WATCHER_CONFIG --data-file=-

## triggerBuild config
##
cat <<EOD |
{
  "trigger": "prerender",
  "project": "$GCP_PROJECT",
  "specification": $(cat gcloud-config-prerender.json),
  "substitutions": {
    "_BUILD_IMAGE_NAME": "gcr.io/$GCP_PROJECT/build:latest",
    "_FIREBASE_HOSTING_PROJECT": "$GCP_PROJECT",
    "_FIREBASE_HOSTING_TARGET": "staging"
  }
}
EOD
gcloud beta secrets versions add $TRIGGER_BUILD_CONFIG --data-file=-

## webhookWatcher config
##
AUTH_HEADER="X-Webhook-Secret"
AUTH_SECRET=$(dd if=/dev/urandom bs=1k count=1 2>/dev/null | md5)
cat <<EOD |
{
  "authHeader": "$AUTH_HEADER",
  "authSecret": "$AUTH_SECRET"
}
EOD
gcloud beta secrets versions add $WEBHOOK_WATCHER_CONFIG --data-file=-
echo
echo "Webhook authentication header:"
echo "$AUTH_HEADER: $AUTH_SECRET"
