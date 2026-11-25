# Project Checkpoint — المحترف في AI
Last updated: 2026-11-25

## Repository
- GitHub: https://github.com/esame4619-coder/Face-AI
- Branch: main
- Current task: implement real video face discovery and target-person selection.

## Latest APK build status at checkpoint
- Build workflow #107
- Run ID: 45540671376
- Commit: ccd6535d110a4293f435ea9b37ce1af16b893432
- Final status: SUCCESS (completed 2026-11-25 03:37 UTC).
- Artifact: `Face-AI-APK` (artifact id `14989476190`, ZIP size 25,453,112 bytes); downloaded as `Face-AI-build107.zip` and extracted to `/mnt/data/build107/app-release.apk`.
- APK artifact was available and downloaded; build #107 is the current app build. Build #106 (run 45540621347) had been cancelled.
- GitHub Actions run: https://github.com/esame4619-coder/Face-AI/actions/runs/45540671376

## Work just committed
- backend/engine.py: added a FaceFusion-based video face detection method that samples frames, returns face thumbnails and a reference frame/time; video swap command was extended to use FaceFusion reference selector options.
- backend/main.py: added POST /api/video-faces and added reference_frame_number/reference_face_position form fields to POST /api/faceswap-video.
- backend/worker_pool.py: added worker dispatch for /api/video-faces and forwards selected reference frame/face position to worker video swap requests.
- lib/main.dart: replaced the prior video swap screen with a flow to select replacement face + video, detect faces, show selectable thumbnails, and submit the selected reference target. UI shows the exact sampled timestamp returned by backend.
- Latest Flutter commit: ccd6535d110a4293f435ea9b37ce1af16b893432 ("Show exact sampled video frame time in face selection").
- Backend API Tests #68 passed on an earlier backend commit (f9c0c6e10be36eea3049a074b849817aa1a1c025); that does NOT yet prove the newest face-detection implementation passes tests.

## New work completed after build #107
- Backend main.py commit `4628be720d12d6a3429884afbbb02fe7eca43460`: corrected the inspect_video docstring to 1–60 seconds, constrained reference frame/face form values to non-negative integers, and documented that face discovery is a preparation step and does not consume a second worker quota slot.
- Backend tests commit `d436cfee9f5aa76eab64363094eed2e24742bcbd`: added coverage for local video face detection, content type, empty file, upload size, API-key protection, selected-face forwarding to workers, and negative reference rejection.
- Backend tests workflow #70 (run `45541715790`) completed SUCCESS on commit `d436cfee9f5aa76eab64363094eed2e24742bcbd`.
- Engine commit `9a6e128ff0408f60260e211a7520a33bc3e623fb`: explicitly sets FaceFusion `face-selector-order=large-small` in preview detection and video processing so tile positions match.
- FaceFusion 3.9.2 source was checked: `face_detector.detect_faces(frame)` returns bounding boxes, scores, and landmarks; `--reference-frame-number`, `--reference-face-position`, `--reference-face-distance`, `--face-selector-order`, and `--face-tracker-score` are actual CLI options. This validates names/signatures, but not a live GPU/model run.

## Important validation gaps / next actions
1. Poll the latest Backend API Tests run triggered by engine commit `9a6e128ff0408f60260e211a7520a33bc3e623fb`; fix any failure.
2. Continue reviewing the FaceFusion helper initialization and test it on a worker with FaceFusion 3.9.2 and downloaded detector models. CLI/API names are verified against upstream source, but live inference is not yet verified.
3. Review the actual FaceFusion 3.9.2 API/CLI integration in backend/engine.py. The detector helper imports FaceFusion modules and calls face_detector.detect_faces; verify the exact API and tuple return shape against the pinned source. Verify the CLI options used for reference selection are accepted by the installed FaceFusion version. Do not assume these calls are valid until tested.
4. Inspect backend/main.py to confirm the existing inspect_video helper and all multipart field names match the new routes.
5. Inspect worker_pool.py quota behavior: detection currently dispatches to workers without reserving/decrementing a daily job quota; decide whether detection should consume quota, and keep policy consistent.
6. Ensure workers run the same updated backend version and support /api/video-faces. Existing remote Colab notebook/server may not yet contain this endpoint; old workers will fail detection and failover.
7. Critical behavior: FaceFusion reference selection must consistently identify the same person throughout the video. Sampling a single reference frame and selecting face position is only a reference selector, not a verified tracker. Test clips with multiple people, crossing/occlusion, and changing camera angles. Do not claim reliable tracking until validated.
8. Add backend tests for /api/video-faces (auth, content type, size/duration limits, no-face result, worker/local error handling) and for passing reference fields to video swap.
9. Then continue the broader audit of all six tools. Several audio tools are still UI placeholders; image enhancement currently uses Pillow operations and Lanczos upscaling, not a true AI super-resolution model.

## Product constraints / project goals
- One Arabic Android app named "المحترف في AI" with six tools: photo face swap, AI video studio/video face swap, voice cloning (with consent), voice changing, AI song creation, and photo enhancement.
- User wants no paid APIs, paid cloud GPUs, or paid external services. Use open-source software and resources the user owns or legitimately free resources; be explicit about limits of free tiers.
- The multi-worker goal (roughly 10 free workers and ~70 jobs/day) is aspirational only, not guaranteed. No real worker URLs or credentials are configured yet.
- Work on the app first; connect/operate servers after the app's functionality is stable.
- The previous verified APK was build #105 at /mnt/data/build105/app-release.apk in the prior session. It predates the latest video face-selection changes and must not be presented as the new build.

## Resume instruction
When the user returns, continue from this checkpoint without asking them to repeat project details. Start by checking the latest GitHub Actions run for build #107 and then proceed with validation/fixes.


## Latest grouped validation pass (2026-11-25)
- `backend/main.py`: reference frame and face positions now reject negative values; the 1–60 second duration rule is documented accurately. Face discovery intentionally does not consume a second worker quota slot for the same video-swap operation.
- `backend/engine.py` commit `9a6e128ff0408f60260e211a7520a33bc3e623fb` explicitly uses FaceFusion's `large-small` selector order for both preview and processing, matching the order of the selectable thumbnails.
- Backend API Tests #70 (run `45541715790`) and #71 (run `45541780503`) passed.
- Expanded test commit `e563ea32265a39d87940de93add19b8fa2ee5ccc` added ffprobe duration/container tests and a mocked video-engine command/audio-mux test. Run #72 failed 1 test because the test fixture encoded literal `\\n` instead of line breaks; 42 other tests passed.
- Fixed that test fixture in commit `bcea8b88576094f4b6c2cf8c9c38f5ba7d36d7a3`. Backend API Tests #73 (run `45541928715`) is currently in progress. Check its result before making further changes.
- Latest backend test command is expected to cover 43 tests. Do not report it as passing until run #73 completes.
