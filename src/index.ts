import { PubSub } from '@google-cloud/pubsub';
import { CloudBuildClient } from '@google-cloud/cloudbuild';
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

export async function webhookWatcher(req: any, res: any) {
  const config = await getConfig(process.env.CONFIG);
  if (
    req.get('Content-Type') === 'application/json' &&
    req.get(config.authHeader) === config.authSecret
  ) {
    const message = req.body.trigger;
    const messageId = await sendPubSub(process.env.BUILD_TOPIC, message);
    console.log(
      `WEBHOOK ${req.rawBody} TRIGGER ${message} PUBSUB ${messageId}`
    );
  }
  res.status(204).send('');
}

export async function gcrWatcher(msg: any) {
  const event: any = JSON.parse(Buffer.from(msg.data, 'base64').toString());
  const config = await getConfig(process.env.CONFIG);
  if (event.action === config.gcrAction && event.tag === config.gcrTag) {
    const messageId = await sendPubSub(
      process.env.BUILD_TOPIC,
      config.buildMessage
    );
    console.log(
      `GCR ${event.action} ${event.tag} TRIGGER ${config.buildMessage} PUBSUB ${messageId}`
    );
  }
}

export async function triggerBuild(msg: any) {
  const message: any = Buffer.from(msg.data, 'base64').toString();
  const config = await getConfig(process.env.CONFIG);
  if (message === config.trigger) {
    const cloudBuild = new CloudBuildClient();
    const [_, op] = await cloudBuild.createBuild({
      projectId: config.project,
      build: { ...config.specification, substitutions: config.substitutions }
    });
    console.log(`TRIGGER ${message} BUILD ${op.name}`);
  }
}

// Utility

async function getConfig(key: string) {
  const secretManager = new SecretManagerServiceClient();
  const name = `${key}/versions/latest`;
  const [version] = await secretManager.accessSecretVersion({ name });
  return JSON.parse(version.payload.data.toString());
}

async function sendPubSub(topic: string, message: string) {
  const buffer = Buffer.from(message);
  const pubSubClient = new PubSub();
  return await pubSubClient.topic(topic).publish(buffer);
}
