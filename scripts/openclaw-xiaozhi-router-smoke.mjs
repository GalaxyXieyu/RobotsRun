import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import { XiaozhiAgentRouter } from "../openclaw-xiaozhi/packages/openclaw-xiaozhi/src/router/agent-router.js";

class OverrideStore {
  constructor() {
    this.map = new Map();
  }

  key(account, peer) {
    return `${account}::${peer}`;
  }

  get(account, peer) {
    return this.map.get(this.key(account, peer)) ?? null;
  }

  set(account, peer, agentId) {
    this.map.set(this.key(account, peer), agentId);
  }

  delete(account, peer) {
    this.map.delete(this.key(account, peer));
  }

  clear() {
    this.map.clear();
  }
}

class SessionStore {
  constructor() {
    this.map = new Map();
  }

  remember(sessionKey, target) {
    this.map.set(sessionKey, target);
  }

  get(sessionKey) {
    return this.map.get(sessionKey) ?? null;
  }

  set(sessionKey, target) {
    this.map.set(sessionKey, target);
  }

  delete(sessionKey) {
    this.map.delete(sessionKey);
  }

  deleteByXiaozhiSession(account, sessionId) {
    for (const [key, value] of this.map.entries()) {
      if (value?.account === account && value?.sessionId === sessionId) {
        this.map.delete(key);
      }
    }
  }

  clear() {
    this.map.clear();
  }

  inherit(sourceSessionKey, childSessionKey) {
    const value = this.get(sourceSessionKey);
    if (!value) {
      return null;
    }
    this.map.set(childSessionKey, value);
    return value;
  }
}

function readConfig() {
  const configPath = path.join(os.homedir(), ".openclaw", "openclaw.json");
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function buildApi(cfg) {
  return {
    logger: {
      info() {},
      warn() {},
      error() {},
      debug() {}
    },
    runtime: {
      config: {
        loadConfig: () => cfg
      },
      channel: {
        routing: {
          resolveAgentRoute: ({ cfg: routingCfg }) => {
            const agentId = routingCfg?.bindings?.[0]?.agentId || "main";
            return {
              agentId,
              matchedBy: "smoke",
              lastRoutePolicy: "direct",
              sessionKey: `smoke:${agentId}`,
              mainSessionKey: `smoke:${agentId}`
            };
          }
        },
        reply: {
          dispatchReplyWithBufferedBlockDispatcher: async ({ cfg: routingCfg, dispatcherOptions }) => {
            const agentId = routingCfg?.bindings?.[0]?.agentId || "main";
            const text = agentId === "main" ? "本地 smoke main。" : `本地 smoke ${agentId}。`;
            await dispatcherOptions.deliver({ type: "text", text }, { kind: "final" });
          },
          finalizeInboundContext: (ctx) => ctx
        },
        session: {
          resolveStorePath: () => "smoke-path",
          recordInboundSession: async () => {}
        }
      }
    }
  };
}

async function main() {
  const cfg = readConfig();
  const account = process.env.ACCOUNT || "default";
  const peerA = process.env.PEER_A || "peerA";
  const peerB = process.env.PEER_B || "peerB";
  const agentAEnv = process.env.AGENT_A || "";
  const agentBEnv = process.env.AGENT_B || "";

  const overrides = new OverrideStore();
  const sessionTargets = new SessionStore();
  const router = new XiaozhiAgentRouter(buildApi(cfg), overrides, sessionTargets);

  const inventory = await router.getInventory({ account });
  const allAgents = inventory.agents.map((item) => item.value).filter(Boolean);
  const agentA = agentAEnv || inventory.defaultAgentId;
  const agentB = agentBEnv || allAgents.find((item) => item !== agentA) || agentA;

  await router.bindPeerAgent({ account, peerId: peerA, agentId: agentA });
  await router.bindPeerAgent({ account, peerId: peerB, agentId: agentB });

  const replyA = await router.routeChat({ account, peerId: peerA, text: "smoke A" });
  const replyB = await router.routeChat({ account, peerId: peerB, text: "smoke B" });
  const clearA = await router.clearPeerSession({ account, peerId: peerA });

  console.log(
    JSON.stringify(
      {
        account,
        bridgeId: inventory.bridgeId,
        defaultAgentId: inventory.defaultAgentId,
        agents: allAgents,
        replyA,
        replyB,
        clearA,
        peerAAfterClear: overrides.get(account, peerA),
        peerBAfterClear: overrides.get(account, peerB)
      },
      null,
      2
    )
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.stack || error.message : String(error));
  process.exitCode = 1;
});
