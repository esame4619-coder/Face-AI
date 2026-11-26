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


## Additional grouped pass (2026-11-25)
- Backend API Tests #74 (run `45546300658`) SUCCESS; Manager Docker Build Check #49 (run `45546300588`) SUCCESS.
- Added video failure-path tests in `backend/tests/test_video_failures.py`: no-face detection maps to a controlled 503; ffprobe process failure maps to a controlled 400.
- Backend API Tests #75 (run `45548055464`) SUCCESS; Manager Docker Build Check #50 (run `45548055371`) SUCCESS.
- Extended `backend/tests/test_worker_pool.py` with concurrent quota reservation, video detection failover without consuming quota, and video swap forwarding/API-key/quota tests. Commit: `a9a9251ea6e876894d1b5a48398cefe84f578e0e`.
- Backend API Tests #76 (run `45548109911`) SUCCESS.
- Clarified MP4/MOV support in backend error text and Flutter video picker description. Backend commit: `3dea14f88b4f036c6be1d960a44f2cbbf439d97a`; Flutter commit: `454d1e0049eb3286a6ea202ce17950edf3c28a3b`.
- Added MOV container acceptance test and fixed its ffprobe fixture newline. Latest test fixture commit: `6b6ec4fe2b258df102f7768065de0c1c8bac0398`.
- Latest CI at checkpoint: Backend API Tests #77 run `45548122148` is in progress on commit `29a479afc285394734c4da81e427b76b175f92aa`; Manager Docker Build Check #52 run `45548122186` is in progress on same commit. APK Build #108 run `45548116299` is in progress on Flutter commit `454d1e0049eb3286a6ea202ce17950edf3c28a3b`. Poll all three before reporting final status.
- The audio/voice screens remain UI-only and explicitly tell users no processing engine is connected yet. Do not present them as working features. Image enhancement is basic Pillow/Lanczos, not AI super-resolution.
- Worker quota reservation is intentionally charged before processing; a worker attempt that fails after dispatch may still count. This avoids unsafe refunds when a timed-out worker may actually have completed work. If exposing usage to users, label it as attempts/processing slots rather than guaranteed successful outputs.


## Latest test and compatibility fixes (2026-11-25)
- Backend API Tests #77 (run `45548122148`) initially FAILED: the new MOV test fixture returned a literal backslash-n, not two ffprobe output lines. The implementation itself accepted MOV; the test fixture was corrected.
- Backend API Tests #78 (run `45548144657`) SUCCESS: 48 passed, 1 upstream Starlette/httpx deprecation warning. The fixture now builds stdout using `chr(10).join(...)`.
- Manager Docker Build Check #53 (run `45548144703`) SUCCESS.
- Backend `inspect_video` error text now accurately says MP4 or MOV, matching the content-type checks and ffprobe container validation. Commit: `5fdebce51ab827bba68c6932225401a0303b1c02`.
- Latest Backend API Tests #79 run `45548219309` and Manager Docker Build Check #54 run `45548219238` are in progress on commit `5fdebce51ab827bba68c6932225401a0303b1c02`.
- APK Build #108 run `45548116299` remains in progress on Flutter commit `454d1e0049eb3286a6ea202ce17950edf3c28a3b`. This build contains the UI copy update that says MP4 or MOV; poll before delivery.


## Final status at latest work batch (2026-11-25)
- Backend API Tests #79 (run `45548219309`) SUCCESS after correcting MOV duration error wording; Manager Docker Build Check #54 (run `45548219238`) SUCCESS.
- Added an API-level test that submits a `video/quicktime` MOV upload to `/api/video-faces`; commit `98342a15a1ffd33ee26712ae14ea229ae4b8d348`.
- Backend API Tests #80 run `45548349510` and Manager Docker Build Check #55 run `45548349368` are queued on that commit.
- APK Build #108 run `45548116299` (Flutter commit `454d1e0049eb3286a6ea202ce17950edf3c28a3b`) was still in progress at the latest poll. It has not yet produced a confirmed downloadable artifact. Poll it and fetch artifact after success.
- FaceFusion 3.9.2 source inspection reconfirmed `face_detector.pre_check()` downloads/checks detector models; `detect_faces(frame)` returns bounding boxes, scores and landmarks; `create_program()` exposes `headless-run`; and the CLI flags for detector model/size/score, selector order, reference frame and face position exist. This is static upstream-source validation only, not a successful live inference test.


- Backend API Tests #80 (run `45548349510`) SUCCESS: 49 passed, 1 upstream Starlette/httpx deprecation warning. The new API-level MOV upload test passes.
- Manager Docker Build Check #55 (run `45548349368`) was still in progress at this checkpoint.


## Quality and regression pass (2026-11-26)
- Expanded API regression coverage for all four processing endpoints when an API key is configured, valid-key access to image enhancement, worker-pool health reporting, controlled video-swap unavailability when FaceFusion is absent, and EXIF orientation correction.
- Added operational exception logging for failed video face-swap jobs; client responses remain generic and do not expose server internals.
- Backend API Tests run `45738038145` SUCCESS: **57 passed, 1 upstream Starlette/httpx deprecation warning**.
- Manager Docker Build Check run `45738038128` SUCCESS.
- Added Flutter widget smoke test at `test/app_smoke_test.dart` and made the Android APK workflow run `flutter test` before building.
- Flutter smoke test passed in Android Build run `45738195335` (run #109). APK build was still running at the time this checkpoint entry was written; do not claim a new APK exists until the run and public release workflow both succeed.
- Relevant commits: API tests `098e421576115a3f261d49fb94e94745b768a998`; video error logging `81bef3ba6e052867d655798942d34dc251507114`; Flutter smoke test `0bff1afb5ff314a4d9741ca6781aa7bf82d6e819`; APK workflow test gate `3e8a4e13df1f37ec07c67598dc196969d3bf5225`.
- The six-tool UI is not equivalent to six live AI engines. Photo/video face swap still requires a real, reachable FaceFusion worker and a live inference test. Voice cloning, voice changing and song generation remain UI-only. Image enhancement is basic Pillow/Lanczos processing, not AI super-resolution. No free GPU workers are configured or verified.


- Android Build #109 run `45738195335`: SUCCESS. The new Flutter smoke test passed before APK compilation; APK upload passed.
- Public release workflow run `45738904246`: SUCCESS. Downloadable APK: https://github.com/esame4619-coder/Face-AI/releases/download/apk-build-45739348131/app-release.apk
- APK size: 53,385,271 bytes. SHA-256: `10bf07ab870caeabf63060cb088f8fbb35e779049975bd016f97290f2d8891ed`.
- Latest verified automated quality set: backend tests 57 passed; manager Docker image build passed; Flutter Arabic home-screen smoke test passed; Android release APK build and publication passed.
- This is a CI-built installable app package, not proof of live AI inference or real-device compatibility. A real device installation and live FaceFusion worker test remain required.


- Final Android Build #112 run `45739348131`: SUCCESS. Static analysis, Flutter widget smoke test, APK build and artifact upload all passed.
- Public release workflow run `45740163450`: SUCCESS. Final APK #112 is published at https://github.com/esame4619-coder/Face-AI/releases/download/apk-build-45739348131/app-release.apk
- Final APK SHA-256: `2a2e1dd072be466cf7b41c07362fe9a564576f3c23dc70aff0876f6b190451f8` (53,385,271 bytes).
- Flutter analyzer initially identified deprecated dropdown parameters; these were migrated to `initialValue`. The remaining Flutter Material umbrella-import deprecation is currently suppressed at that import until Flutter's suggested replacement package is part of the stable SDK. Final analyzer gate passed.


## Work batch — 2026-11-26 (after APK 112 user device confirmation)
- User installed APK 112 and confirmed the app opens and screens work on their Android phone.
- Added `POST /api/change-voice`: validates audio via ffprobe, enforces 30 MB / 10 minute limits, and generates an MP3 with FFmpeg pitch/equalization effects for male/female/child presets.
- Connected Flutter's "تغيير الأصوات" screen to the new endpoint; it uploads the selected audio, handles API errors, saves the returned MP3 in app documents, and lists it in My Works.
- Important accuracy: this is offline pitch/effect processing, not AI voice identity cloning. Voice cloning and AI song generation remain unimplemented.
- Added success, invalid-input, empty-file and API-key tests for the audio endpoint. Backend API Tests #86 run `45741189209`: **61 passed, 1 upstream Starlette/httpx deprecation warning**.
- Added optional Colab GPU setup: the temporary-server notebook detects a Colab GPU, installs FaceFusion `cuda@12`, verifies `CUDAExecutionProvider`, and configures FaceFusion to use CUDA with CPU fallback. CPU mode remains supported when no GPU is allocated.
- Updated FaceFusion engine command construction to pass explicit execution providers only when configured.
- FaceFusion Docker Build Check #20 run `45741149004`: SUCCESS, including Docker image build, CLI checks, and an actual CPU FaceFusion face-swap inference that produced a valid image.
- Manager Docker Build Check #61 run `45741189266`: SUCCESS.
- Android Build #113 run `45741007604` (commit `2078da5b33feb9d1eaba505d7e77caa3b82d9736`) passed Flutter static analysis and widget smoke tests; APK compilation was still running at checkpoint update. Do not claim APK 113 published until build and release workflow succeed.
- Colab GPU availability is not guaranteed; the notebook uses one temporary session and does not create a persistent multi-worker pool.


## Final verified release — 2026-11-26
- Android Build #116 (run `45742663569`) SUCCESS: Flutter analyze, widget smoke test, release APK build and artifact upload all passed.
- Publish APK Download #26 (run `45743403455`) SUCCESS. Public APK: https://github.com/esame4619-coder/Face-AI/releases/download/apk-build-45742663569/app-release.apk
- APK size: 53,713,679 bytes. SHA-256: `eabd5fe69a1a40a716051e79807a635bcdd08c8a12bdab71d077b61e9e72dc75`.
- Backend API Tests #89 run `45742291420`: 61 passed.
- Manager Docker Build Check #68 run `45742340148`: SUCCESS, including container startup, authenticated API health, a generated WAV upload, actual FFmpeg conversion, and MP3 output verification.
- FaceFusion Docker Build Check #20 run `45741149004`: SUCCESS, including actual CPU FaceFusion inference and valid output image.
- Manager runtime image now includes FFmpeg and `rotation_policy.py`; the latter was necessary for manager startup.
- Colab notebook now supports GPU-aware installation (`cuda@12` when Colab GPU is allocated), explicit CUDA provider selection, and model pre-download/validation before opening the temporary tunnel.
- Flutter My Works now previews saved MP3 outputs and offers native share/export.
- User has confirmed APK 112 opens on their physical phone. APK 116 includes the voice-change and share/export changes; it still needs the user's physical-device install check.
- Still not implemented: AI voice cloning, AI song generation, AI super-resolution. Voice changer is a tested FFmpeg pitch effect, not AI speaker identity conversion. Video identity consistency across multiple faces/occlusion remains unverified.
- No free GPU host is provisioned persistently. The Colab notebook creates one temporary worker session only; it does not create 10 workers or guarantee 70 jobs/day.


## Continued work — 2026-11-26
- Added optional EDSR x2 AI super-resolution engine in `backend/enhance_engine.py`; model is loaded lazily and only when a valid model file (>1 MB) is configured. Large images are downscaled to bound memory before inference.
- `POST /api/enhance` now uses EDSR x2 when available and reports `X-Enhancement-Engine: EDSR-x2`; otherwise it safely falls back to Pillow and reports `Pillow-fallback`. Health endpoint reports `ai_enhance_available`.
- Colab notebook installs OpenCV contrib and downloads the EDSR x2 model into `/content/models/EDSR_x2.pb`; model is active only in that temporary Colab session.
- Flutter image studio now tells the user which enhancement engine actually processed the image.
- Added two API tests. Backend API Tests #94 run `45754958762`: 63 passed. Manager Docker Build Check #73 run `45754958742`: success, including actual FFmpeg conversion and MP3 validation. Manager #72 also succeeded.
- APK Build #117 run `45754977733` was in progress at checkpoint write; confirm completion and publish latest release before declaring updated APK ready.
- Remaining audio model constraints: AI voice cloning and sung-lyrics music generation are still not activated. Do not claim these as functional. No persistent free GPU workers are provisioned.
