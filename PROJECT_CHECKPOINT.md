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
- Status at last check: in_progress, currently on the "Build APK" step after dependencies and Android plugin compileSdk patch completed.
- Build #106 (run 45540621347) was cancelled when the newer build was triggered.
- Do not claim APK #107 is ready until the run succeeds and its artifact is downloaded and checked.
- GitHub Actions run: https://github.com/esame4619-coder/Face-AI/actions/runs/45540671376

## Work just committed
- backend/engine.py: added a FaceFusion-based video face detection method that samples frames, returns face thumbnails and a reference frame/time; video swap command was extended to use FaceFusion reference selector options.
- backend/main.py: added POST /api/video-faces and added reference_frame_number/reference_face_position form fields to POST /api/faceswap-video.
- backend/worker_pool.py: added worker dispatch for /api/video-faces and forwards selected reference frame/face position to worker video swap requests.
- lib/main.dart: replaced the prior video swap screen with a flow to select replacement face + video, detect faces, show selectable thumbnails, and submit the selected reference target. UI shows the exact sampled timestamp returned by backend.
- Latest Flutter commit: ccd6535d110a4293f435ea9b37ce1af16b893432 ("Show exact sampled video frame time in face selection").
- Backend API Tests #68 passed on an earlier backend commit (f9c0c6e10be36eea3049a074b849817aa1a1c025); that does NOT yet prove the newest face-detection implementation passes tests.

## Important validation gaps / next actions
1. First poll Build #107 (run 45540671376). If it succeeds, download artifact, extract APK, verify archive integrity, then share the exact APK link. If it fails, inspect job logs and fix the compile issue.
2. Run backend tests on the latest main commit, especially imports and endpoint signatures.
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
