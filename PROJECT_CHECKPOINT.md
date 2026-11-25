# Project Checkpoint — المحترف في AI
Last updated: 2026-11-25

## Repository
- GitHub: https://github.com/esame4619-coder/Face-AI
- Branch: main
- Current phase: stabilize backend video workflow and audit remaining app tools. Do not start provisioning worker servers until the app/backend is stable.

## Latest Android APK
- Build workflow #107, run `45540671376`, SUCCESS.
- Artifact id `14989476190`; extracted APK: `/mnt/data/build107/app-release.apk` (about 51 MB).
- SHA256: `f4942512d6548e1e971e51f6522636fd53d26fe86f542f44be922beb9ee0e0c9`.
- This build predates the latest backend-only changes; it does include the latest Flutter video face-selection UI at commit `ccd6535d110a4293f435ea9b37ce1af16b893432`.
- No real-device install/runtime test has been confirmed.

## Video workflow implementation
- `lib/main.dart`: user selects source face + target video, calls `/api/video-faces`, selects a detected face tile, then submits the selected reference frame/face position to `/api/faceswap-video`; UI displays the sampled timestamp and plays/saves returned MP4.
- `backend/main.py`: validates MP4/MOV container and 1–60 second duration, max 100 MB; exposes `POST /api/video-faces` and `POST /api/faceswap-video`; rejects negative reference indices; supports optional API key.
- `backend/engine.py`: samples five video frames with OpenCV, calls FaceFusion detector, returns thumbnails; video swap uses FaceFusion reference selector and restores original audio with ffmpeg.
- FaceFusion 3.9.2 source was checked for relevant detector method and CLI option names. This verifies API/CLI names only, not a live inference run or model availability.
- The reference selector/tracker has not been validated for identity continuity through crossings, occlusion, or camera-angle changes. Do not promise guaranteed tracking.

## Verified CI
- Backend API Tests #70 run `45541715790`: SUCCESS.
- Backend API Tests #71 run `45541780503`: SUCCESS.
- Backend API Tests #72 run `45541871755`: FAILURE caused by a test fixture using escaped literal newlines; fixed in commit `bcea8b88576094f4b6c2cf8c9c38f5ba7d36d7a3`.
- Backend API Tests #73 run `45541928715`: SUCCESS on commit `bcea8b88576094f4b6c2cf8c9c38f5ba7d36d7a3`; all workflow steps completed successfully.
- Manager Docker Build Check #48 run `45541928702`: SUCCESS on the same commit.
- Test suite at #73 includes 43 tests (confirm exact count from log if needed; job's Run API tests step passed).

## Worker-pool audit findings
- `backend/worker_pool.py` forwards `reference_frame_number` and `reference_face_position` as multipart form fields to `/api/faceswap-video`.
- Video detection dispatches to `/api/video-faces` and intentionally does not reserve a second quota slot; the actual video swap reserves one job.
- Both detection and video swap rotate among active workers and try up to three candidates. Health is checked before dispatch.
- Important remaining issue: quota is reserved before processing; if a worker fails during the actual request, that failed attempt still consumes a daily quota unit. Decide whether to refund failed attempts safely or document quota as attempts rather than successful jobs. Do not silently overstate daily successful job capacity.
- Existing Colab/remote workers may not yet run this code or expose `/api/video-faces`; no live worker URLs are configured/verified.
- `daily_jobs=0` currently means unlimited in `_try_reserve_job` and status reporting. Keep this explicit in admin/config UX; it is not a sensible default for real free-tier workers.

## Remaining backend validation
1. Add tests for no-face detection response, ffprobe failure/invalid metadata, worker detection failover, worker API-key forwarding, and failed processing/quota semantics.
2. Review whether `/api/video-faces` should accept `video/quicktime` while client error text says MP4 only; align behavior and user-facing message.
3. Validate FaceFusion helper initialization, detector model download/pre-check, and actual inference on a real worker before claiming video processing works.
4. Test multi-person videos, face crossing/occlusion, and camera changes; reference selector is not proven identity tracking.
5. Verify response size/timeouts and Android playback/save behavior with real video samples.

## Six product tools audit
- Photo face swap: FaceFusion backend path exists, but live engine/model inference still needs verification.
- Video studio/face swap: UI and API path exist; live inference and identity consistency unverified.
- Voice cloning, voice changing, AI song creation: still contain placeholder/UI-only paths and need real open-source processing engines.
- Photo enhancement: currently Pillow contrast/color/sharpen + Lanczos 2x, not AI super-resolution.
- Continue auditing and implementing tools before server provisioning.

## Product constraints
- One Arabic Android app: "المحترف في AI", six tools listed above.
- Must remain free to the user: no paid APIs, subscriptions, external paid GPUs, or paid cloud services. Use open-source software and legitimate free/user-owned compute; explain free-tier limits.
- The target of about 10 free workers / 70 tasks per day is aspirational, not guaranteed. Do not promise capacity until providers, quotas, uptime, and workers are actually tested.
- App first, worker connection/provisioning last.

## Resume instruction
Continue directly from this checkpoint. Do not ask the user to repeat project requirements. Next, strengthen backend tests and audit/implement the six tools; do not create a new APK unless Flutter code changes.
