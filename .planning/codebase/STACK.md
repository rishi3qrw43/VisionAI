# Technology Stack

**Analysis Date:** 2026-07-15

## Languages

**Primary:**
- Swift - iOS 26.5+ - Used for ASSIST iOS application in `ASSIST/`
- TypeScript - 5.9.3 - Used for React Router applications in `my-project/my_app_projects_1232_this_/` and `my-project/my-react-router-app/`
- JavaScript - ES2022 module syntax - Supporting runtime for React projects

**Secondary:**
- JSON - Configuration and asset manifests
- CSS - Tailwind CSS for styling React applications

## Runtime

**Environment:**
- **iOS/macOS:** iOS 26.5+, macOS 26.5+, visionOS/xrOS (via SUPPORTED_PLATFORMS in `ASSIST.xcodeproj/project.pbxproj`)
- **Web:** Node.js (version inferred from npm lockfile v3 in `my-project/package-lock.json`)

**Package Manager:**
- **Xcode:** Built-in for Swift/iOS dependencies (no external SPM packages required)
- **npm:** 3.x lockfile format in `my-project/package-lock.json`
- Lockfile: Present (`my-project/package-lock.json`)

## Frameworks

**Core (Swift/iOS):**
- SwiftUI - UI framework for ASSIST app (`ASSIST/ContentView.swift` and `ASSIST/ASSISTApp.swift`)
- AVFoundation - Camera and audio capture (`import AVFoundation` in `ASSIST/ContentView.swift`)
- AVKit - Video framework for media playback
- Vision - Image classification and analysis (`import Vision` in `ASSIST/ContentView.swift`)
- FoundationModels - On-device AI/ML (`import FoundationModels` in `ASSIST/ContentView.swift`)
- Combine - Reactive programming (`import Combine` in `ASSIST/ContentView.swift`)
- UIKit - Low-level UI components, imported for specialized needs (`import UIKit` in `ASSIST/ContentView.swift`)

**Core (Web):**
- React - 19.2.7 - Component library (in `my-project/my_app_projects_1232_this_/package.json` and `my-project/my-react-router-app/package.json`)
- React Router - 8.0.0 - Routing and SSR framework (in both React projects)
- react-dom - 19.2.7 - React DOM rendering

**Styling:**
- Tailwind CSS - 4.2.2 - Utility-first CSS framework (dev dependency in both React projects)
- @tailwindcss/vite - 4.2.2 - Vite integration for Tailwind (in both React projects)

**Build/Dev:**
- Vite - 8.0.3 - Frontend build tool and dev server (in both React projects via `vite.config.ts`)
- @react-router/dev - 8.0.0 - Development server and build tools
- @react-router/serve - 8.0.0 - Production server for SSR apps
- @react-router/node - 8.0.0 - Node.js integration for React Router

## Key Dependencies

**Critical (Swift):**
- FoundationModels - On-device generative AI, no network calls - core to ASSIST functionality
- Vision framework - Image classification and object detection
- AVFoundation - Camera access and media capture - critical for scanning feature

**Critical (Web):**
- React 19.2.7 - Core UI rendering
- React Router 8.0.0 - SSR and routing, no separate API client dependency visible
- Tailwind CSS 4.2.2 - Styling system

**Infrastructure/Utilities (Web):**
- isbot - 5.1.36 - Bot detection for React Router SSR (`my-project/my_app_projects_1232_this_/package.json`)
- chalk - 5.6.2 - Terminal color output (in `my-project/package.json`)
- typescript - 5.9.3 - Type checking
- @types/node - 22.x - Node.js type definitions
- @types/react - 19.2.14 - React type definitions
- @types/react-dom - 19.2.3 - React DOM type definitions

## Configuration

**Environment (Swift/iOS):**
- Build target: `ASSIST` (Product Name: `SMFR2` in project settings)
- Bundle ID: `rishi.SMFR2` (in `ASSIST.xcodeproj/project.pbxproj`)
- Info.plist Keys: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` (in build settings)
- Deployment: Supports iPhone, iPad, macOS, xrOS
- No environment variable configuration detected - on-device operation only

**Environment (Web):**
- TypeScript strict mode enabled in `tsconfig.json` for both React projects
- Path aliases: `~/*` maps to `./app/*` (in `my-project/my_app_projects_1232_this_/tsconfig.json`)
- Module: ES2022 with ESM syntax
- React Router SSR enabled by default (ssr: true in `react-router.config.ts`)

**Build Configuration:**
- **Swift:** Xcode 26.6 (LastUpgradeCheck in `ASSIST.xcodeproj/project.pbxproj`)
- **Web:** Vite 8.0.3 with React Router plugin, Tailwind CSS plugin
- **TypeScript:** Target ES2022, lib includes DOM and ES2022

## Platform Requirements

**Development:**
- **iOS/macOS:** Xcode 26.6+ with iOS 26.5+ SDK
- **Web:** Node.js (version via npm v3 lockfile), npm 9+
- XcodeBuildMCP 1.x for IDE integration (registered in `.mcp.json`)

**Production:**
- **iOS/macOS:** iOS 26.5+, macOS 26.5+, or xrOS runtime
- **Web:** Node.js-compatible server environment with ES2022 support

---

*Stack analysis: 2026-07-15*
