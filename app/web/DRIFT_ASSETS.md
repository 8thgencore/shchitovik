# Drift web assets

`drift_worker.js` and `sqlite3.wasm` are taken from the GitHub release `drift-2.35.2`
(https://github.com/simolus3/drift/releases/tag/drift-2.35.2) and must match the drift version
in `pubspec.lock`. After upgrading drift, download them again from the matching release.

The server must send `sqlite3.wasm` with `Content-Type: application/wasm`. For the fastest
storage (OPFS) also send `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`; without them drift falls back to IndexedDB.
