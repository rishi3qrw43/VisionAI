# External Integrations

**Analysis Date:** 2026-07-15

## APIs & External Services

**Content Delivery:**
- Google Fonts - Web font service
  - Usage: Loaded via stylesheet in `my-project/my_app_projects_1232_this_/app/root.tsx` line 22-23
  - Integration: Preconnect to fonts.googleapis.com and fonts.gstatic.com
  - Fonts: Inter family (variable weight 100-900)

**Demo/Asset Services:**
- Unsplash - Image CDN for demo content
  - Usage: Referenced in `ASSIST/ContentView.swift` for sample history items
  - Integration: Direct AsyncImage URLs loaded from unsplash.com
  - Note: Demo images only, not production critical

## Data Storage

**Databases:**
- Not detected - No external database integrations observed

**File Storage:**
- Local filesystem - Camera and photo capture stored locally
  - Implementation: `AVFoundation` `AVCaptureSession` in `ASSIST/ContentView.swift`
  - CameraManager class handles photo and video capture to device storage
  - No cloud storage detected

**Caching:**
- None detected - No Redis, Memcached, or other caching services

## Authentication & Identity

**Auth Provider:**
- None detected - Application uses local device authentication only
- No OAuth, Auth0, Firebase Auth, or other third-party auth services integrated

**Note (iOS/macOS):**
- Camera and microphone permissions managed through native iOS request (AVCaptureDevice authorization)
- No user account system or remote authentication observed

## Monitoring & Observability

**Error Tracking:**
- None detected - No Sentry, Rollbar, or similar error tracking services

**Logs:**
- Local console logging only - No centralized logging service detected
- TypeScript projects use console output via standard JavaScript APIs

**Analytics:**
- None detected - No Google Analytics, Mixpanel, Segment, or similar

## CI/CD & Deployment

**Hosting:**
- Not configured - Local development only
- No deployment platform detected (no Heroku, Vercel, AWS, etc. configuration)

**CI Pipeline:**
- None detected - No GitHub Actions, GitLab CI, Circle CI, or similar workflow files

**Version Control:**
- Git repository initialized (`.git/` directory present)
- Main branch is primary branch

## Environment Configuration

**Required env vars:**
- None detected - No `.env` files or environment variable requirements in configuration

**Secrets location:**
- No secrets management detected - On-device operation only for ASSIST app
- Web projects contain no credential configuration

**No external API keys or credentials required for:**
- AI/ML services (using on-device FoundationModels)
- Database connections
- Third-party APIs
- Payment processors

## Webhooks & Callbacks

**Incoming:**
- None detected - No webhook endpoint configuration

**Outgoing:**
- None detected - No webhook calls to external services

## Summary: Integration Profile

**ASSIST iOS App:**
- Completely self-contained: on-device AI (FoundationModels), local camera, on-device storage
- Zero external service dependencies
- No network calls to backend required
- Demo images from Unsplash only (non-functional)

**React Router Web Apps:**
- Minimal integration surface: Google Fonts stylesheet only
- No API endpoints configured
- No database connections
- No authentication services
- Starter templates without production integrations

---

*Integration audit: 2026-07-15*
