# Repo Size Audit

## Scope

Audit target: `xinnan-tech/xiaozhi-esp32-server`

Audit date: `2026-04-07`

## Summary

The repository is large mainly because it tracks binary assets directly in Git, not because it only contains normal source code.

Top heavy areas:

- `main/xiaozhi-server/test/resources/` about `61.8 MB`
- `main/xiaozhi-server/music/` about `14.4 MB`
- `main/xiaozhi-server/models/` about `7.8 MB`
- `main/manager-web/public/generator/` about `71.5 MB`
- `main/manager-mobile/unpackage/` about `0.66 MB`
- `docs/images/` about `12.3 MB`

## Main Findings

### 1. Large binary test fixtures are tracked

Examples:

- `main/xiaozhi-server/test/resources/hiyori_pro_zh/hiyori_pro_t11.cmo3`
- `main/xiaozhi-server/test/resources/natori_pro_zh/natori_pro_t06.cmo3`
- `main/xiaozhi-server/test/resources/.../texture_00.png`
- `main/xiaozhi-server/test/resources/.../*.moc3`

These are the strongest candidates to move out of normal Git history.

### 2. Runtime media and model assets are tracked

Examples:

- `main/xiaozhi-server/music/*.mp3`
- `main/xiaozhi-server/config/assets/*.wav`
- `main/xiaozhi-server/models/**/*.onnx`
- `main/xiaozhi-server/models/**/*.jit`

If these files must exist at runtime, they are better served by:

- release assets
- object storage / CDN
- first-run download scripts
- Git LFS if the team insists on versioning them in Git

### 3. Built frontend artifacts are tracked

Examples:

- `main/manager-web/public/generator/assets/index-*.js`
- `main/manager-web/public/generator/assets/*.css`
- `main/manager-mobile/unpackage/**`

These are normal build outputs and should usually not live in source control.

### 4. Static generator resources are also heavy

Examples:

- `main/manager-web/public/generator/static/fonts/*.ttf`
- `main/manager-web/public/generator/static/fonts/*.bin`
- `main/manager-web/public/generator/static/*model*/**`

These may be legitimate runtime resources, but they should still be evaluated for external hosting or Git LFS.

## Recommended Ignore Rules

These belong in the upstream `xiaozhi-esp32-server` repo, not necessarily in this aggregator repo.

```gitignore
# Frontend build outputs
main/manager-web/public/generator/assets/
main/manager-mobile/unpackage/

# Large local media and generated resources
main/xiaozhi-server/music/
main/xiaozhi-server/config/assets/*.wav
main/xiaozhi-server/config/assets/*.mp3

# Large test fixtures
main/xiaozhi-server/test/resources/

# Model binaries
main/xiaozhi-server/models/**/*.onnx
main/xiaozhi-server/models/**/*.jit
main/xiaozhi-server/models/**/*.bin

# Optional: doc screenshots if they are regenerated externally
docs/images/
```

## Cleanup Strategy

### Low risk

- Stop tracking new build outputs.
- Stop tracking new test fixture binaries.
- Add external download/bootstrap steps for runtime media and models.

### Medium risk

- Move current heavy assets to release artifacts or object storage.
- Keep only a minimal sample set in Git.

### High impact but necessary for real size reduction

Past large files remain in Git history even after deletion.

To really shrink the repository, rewrite history with one of:

- `git filter-repo`
- BFG Repo-Cleaner

Typical targets for history cleanup:

- `main/xiaozhi-server/test/resources/`
- `main/xiaozhi-server/music/`
- `main/xiaozhi-server/models/`
- `main/manager-web/public/generator/assets/`
- `main/manager-mobile/unpackage/`
- `docs/images/`

## Suggested Order

1. Add ignore rules in the upstream repo.
2. Move build outputs out of Git first.
3. Move test fixtures and media out of Git.
4. Decide whether runtime fonts/models should use object storage or Git LFS.
5. Rewrite history only after the team agrees on the new asset strategy.
