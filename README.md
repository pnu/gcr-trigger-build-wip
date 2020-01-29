# Setup

    gcloud config set project <PROJECT>
    gcloud config set functions/region <REGION>
    ./gcloud-initial-setup.sh
    yarn deploy

# Components

  GCR => `gcrWatcher` => PubSub

  HTTP => `webhookWatcher` => PubSub

  PubSub => `triggerBuild` => Cloud build => Firebase

# Description

Cloud Function `gcrWatcher` subscribes to the GCR PubSub topic.
If a new tag that matches the configuration (see
`gcloud-config-update.sh`) is inserted to the GCR, the function
triggers a new Cloud build task. This happens by publishing a
message to another topic. Message body defines name of the
requested build job.

Cloud Function `triggerBuild` subcribes to this second topic
and launches the actual Cloud build job, if build job name
matches the configured name.

Cloud Function `webhookWatcher` is attached to an HTTPS endpoint.
The request is authenticated with a shared secret. HTTP body
contains a JSON payload that defines the requested build job, which
is then triggered by sending a message to `triggerBuild`.

Configuration is stored in GCP Secrects Manager, because it may
contain some sensitive API-keys or tokens for deployment. It also
means that the configuration can be changed dynamically without
redeploying the code. For example webhook authentication secret
can be rotated as a configuration task only. Script
`gcloud-config-update.sh` can be used to update the configuration.
This script also generates a webhook authentication secret,
which needs to be included in the webhook call.

# Example use-case

When new image is pushed to GCR and tagged with `latest`,
this automation takes the build image, and runs a prerendering
task _inside_ that prebuilt image (running in Cloud build runtime).
The created assets are then deployed to Firebase hosting.
This buildtask is defined as a json configuration, in `gcloud-config-prerender.json`.

In addition to new build images, the same prerendering task
is run when content in an external CMS changes. The CMS system
triggers a webhook POST (with json payload describing the
requested buildtask). Webhook triggers the same build task
as the GCR use-case above.

Same automation can be used for triggering any build task on GCR
changes or webhooks, and can be deployed multiple times to same
project if taking care of naming the functions and configuration
entries separately for each use-case.

# Miscellaneous

The prerendering task in `gcloud-config-prerender.json` is included
as part of the dynamic configuration (see `gcloud-config-update.sh`).
Ie. this _file_ is not shipped to the functions.

For testing purposes the bare JSON file can be used to trigger a cloud build job manually, eg:

    GCP_PROJECT=<PROJECT>

    gcloud builds submit --no-source --config gcloud-config-prerender.json --substitutions="_BUILD_IMAGE_NAME=gcr.io/${GCP_PROJECT}/build:latest,_FIREBASE_HOSTING_PROJECT=${GCP_PROJECT},_FIREBASE_HOSTING_TARGET=staging"
