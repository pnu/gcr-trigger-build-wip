#!/bin/bash
GCP_PROJECT=$(gcloud config get-value project)
GCP_PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT --format=value\(projectNumber\))

GCR_WATCHER_CONFIG="projects/${GCP_PROJECT}/secrets/gcr-watcher-config"
TRIGGER_BUILD_CONFIG="projects/${GCP_PROJECT}/secrets/trigger-build-config"
WEBHOOK_WATCHER_CONFIG="projects/${GCP_PROJECT}/secrets/webhook-watcher-config"

## Create the configs
##
gcloud beta secrets create $GCR_WATCHER_CONFIG --replication-policy=automatic 2>/dev/null
gcloud beta secrets create $TRIGGER_BUILD_CONFIG --replication-policy=automatic 2>/dev/null
gcloud beta secrets create $WEBHOOK_WATCHER_CONFIG --replication-policy=automatic 2>/dev/null

## Allow Cloud Functions to access the configs
##
gcloud beta secrets add-iam-policy-binding $GCR_WATCHER_CONFIG \
  --member=serviceAccount:$GCP_PROJECT@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor >/dev/null

gcloud beta secrets add-iam-policy-binding $TRIGGER_BUILD_CONFIG \
  --member=serviceAccount:$GCP_PROJECT@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor >/dev/null

gcloud beta secrets add-iam-policy-binding $WEBHOOK_WATCHER_CONFIG \
  --member=serviceAccount:$GCP_PROJECT@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor >/dev/null

## Allow Cloud Build processes to deploy Firebase hosting
##
gcloud projects add-iam-policy-binding $GCP_PROJECT \
  --member=serviceAccount:$GCP_PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/firebasehosting.admin >/dev/null

## Set configuration values
##
./gcloud-config-update.sh
