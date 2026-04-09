# Architectural Concerns

**Analysis Date:** 2026-04-08

## Primary Risks

### 1. Dirty submodule state at bootstrap time

- `git status --short` shows `xiaozhi-esp32` and `xiaozhi-esp32-server` are already modified from the root repo perspective.
- This increases the risk of mixing architecture initialization with unrelated in-flight work.
- Mitigation: keep this task scoped to `.planning/`, PM write-back, and Feishu doc sync.

### 2. Root repo lacks a unified source-of-truth readme

- `README.md` at the root currently only contains the repository title.
- New contributors cannot understand how the three submodules and deploy overlay fit together without deeper manual exploration.

### 3. `xiaozhi-server` deployment still relies on runtime hotfix copying

- `deploy/refresh-xiaozhi-hotfix.sh` and the Sealos manifest copy individual Python files into containers at startup.
- This is flexible, but it creates drift between upstream images and deployed runtime behavior.

### 4. `xiaozhi-web` deployment truth has been corrected, but regression is still possible

- The manager web rollout now forces `command: ["/start.sh"]` and should execute `/app/xiaozhi-esp32-api.jar` from the image.
- This removes the old “PVC hotfix jar overrides the image” problem for the admin surface.
- The remaining risk is regression: if the workflow trigger or rollout patch is reverted, the old drift pattern can come back.

### 5. No root-level end-to-end verification contract

- Each submodule has its own toolchain, but the root repo has no automated check proving firmware, server, deploy overlay, and OpenClaw plugin still match.
- Integration failures will likely appear late unless a root checklist or smoke flow is added.

### 6. Large binary assets live in the server submodule

- `REPO_SIZE_AUDIT.md` confirms heavy assets and generated artifacts inside `xiaozhi-esp32-server`.
- This is not a blocker for architecture init, but it will affect clone cost, CI speed, and long-term maintainability.

## Recommended Follow-Up

- Add a root-level integration readiness checklist before deeper feature work.
- Define a release policy for submodule revisions and deploy/hotfix compatibility.
- Make architecture docs and STATE updates the working memory for future root-repo tasks.

---

*Concerns analysis: 2026-04-08*
