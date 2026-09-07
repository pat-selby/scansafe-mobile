# Vision — ScanSafe

> Captured by the Product Planner skill. This file is the source of truth for
> generating product-vision.md, prd.md, and product-roadmap.md. Edit it directly
> and re-run the Product Planner to regenerate downstream documents.

**Created:** 2026-09-07
**Updated:** 2026-09-07

## Founder

- **Name:** Patrick Selby
- **Expertise:** Cybersecurity — undergraduate at Grambling State University, researcher in the AIoT Lab under Dr. Vasanth Iyer
- **Background:** I built ScanSafe as lab research into whether a fully on-device, classical computer-vision pipeline can provide meaningful QR phishing protection in low-connectivity and privacy-sensitive environments. Two working implementations came out of that: an iOS Swift app with 18 heuristic rules, and a Python Flask prototype with 22 rules, LCS fuzzy matching, and an NSF research write-up. Both proved the idea. Neither reaches both platforms, so I'm rebuilding the detection engine once, cross-platform, and carrying the research forward from there.

## Purpose

- **Who you help:** University students and staff who scan QR codes as part of daily campus life — dining hall menus, parking meters, event flyers, class handouts — usually on patchy campus Wi-Fi, and who have no way to tell where a code leads before they land there.
- **Problem you solve:** A QR code is an opaque link. You cannot hover over it, you cannot read it, and by the time the URL is visible in the address bar the page has already loaded. Quishing attacks exist precisely because of that gap. Real campaigns at GSU have used SafeLinks wrappers to hide the destination, a `wixsite.com` page impersonating OneDrive, and `blob:` URLs that never appear in a legitimate QR code.
- **Desired transformation:** From "scan and hope" to "scan and know." The verdict arrives before the page loads, in plain English, with reasoning the person can actually check rather than a black-box score.
- **Why you:** I'm a cybersecurity student who investigated real phishing campaigns on my own campus and turned what I found into detection rules. Rule 13 exists because of a SafeLinks-wrapped attack. Rule 14's `blob:` weighting exists because of a specific case. Rule 22 exists because of `ivoryrobinson94.wixsite.com/0ne-dr1ve`. I'm not guessing at what attackers do here — I'm encoding what they did to people I know.

## Product

- **Name:** ScanSafe
- **One-liner:** ScanSafe checks where a QR code really goes before you open it, entirely on your phone.
- **How it works:** You point the camera at a QR code. OpenCV finds it in the frame and decodes it on-device. The URL is scored against 22 independent rules — no network, no model, fully deterministic. You get a SAFE, SUSPICIOUS, or HIGH RISK verdict with plain-English reasons, and technical detail for each finding behind a toggle. The scan is saved to local history that never leaves the phone.
- **Key capabilities:**
  - On-device QR detection and decoding via OpenCV, with a multi-stage fallback for coloured, branded, and low-contrast codes
  - 22-rule explainable URL risk scoring, deterministic and offline
  - Dual-layer findings — plain English always visible, technical detail on demand
  - Local scan history, capped at 50 entries, never uploaded
  - Works with the network fully off
- **Platform:** cross-platform
- **Market differentiation:** Every other option fails the same way. Built-in phone camera scanners open the link with no check at all. Third-party QR apps are ad-supported and frequently upload every URL you scan. Browser safe-browsing only helps after the page has loaded. ScanSafe sends nothing anywhere and shows its reasoning instead of asking you to trust a verdict.
- **Magic moment:** You point the phone at a QR code on a campus flyer, and before the page can load the screen says HIGH RISK — because the domain closely resembles "paypal" without being it, and the app tells you exactly that.

## Audience

- **Primary user:** A Grambling undergraduate who scans QR codes several times a week without thinking about it — dining, parking, flyers, handouts — on a phone with unreliable campus Wi-Fi. They have already received at least one phishing text this semester and know the risk is real, but have no practical way to check a code before scanning it.
- **Secondary users:**
  - University IT and security-awareness staff who need an explainable tool to demonstrate to students, where "why" matters more than the verdict
  - Security researchers evaluating the tradeoffs between deterministic heuristics and ML-based phishing detection
  - Privacy-conscious people who will not install a scanner that transmits every link they encounter
- **Current alternatives:** The built-in iOS and Android camera QR readers, generic QR scanner apps from the app stores, and browser-level safe-browsing warnings.
- **Frustrations:** Built-in scanners give no safety signal whatsoever. Third-party scanners are ad-heavy and often send scanned URLs to a server, which is exactly the privacy cost the tool is supposed to save you from. Cloud reputation checks need connectivity that campus Wi-Fi does not reliably provide. And none of them explain themselves — you get a verdict with no reasoning, so you cannot tell a real warning from a false alarm.

## Business

- **Revenue model:** free
- **90-day goal:** Shipped free on Google Play and the App Store. The 22-rule engine verified at parity with the Python research prototype by an automated test corpus. Used in at least one GSU security-awareness session. False-positive rate on a legitimate-domain corpus measured and documented.
- **6-month vision:** The Layer 7 agentic investigation module shipped as an optional, clearly-labelled addition that only activates on ambiguous verdicts — including DNS-based pharming defence, which heuristics alone cannot catch. A published evaluation comparing heuristics alone against heuristics plus the agent layer. Adoption beyond Grambling.
- **Constraints:** Solo student developer carrying a full course load. Primary machine is Windows, so iOS builds require borrowed Mac access and cannot be verified day to day. No budget for paid APIs. Two hard research constraints: OpenCV must do all computer vision, and Layers 1-6 must contain no pretrained ML — the deterministic, explainable pipeline is the research contribution, not an implementation detail.
- **Go-to-market:** Campus first. GSU security-awareness sessions, the ACM student chapter, and the AIoT Lab. The research write-up is the credibility anchor — this is a tool with published reasoning behind it, not another app store QR scanner.

## Brand Voice

- **Personality:** The careful friend who checks things for you. Calm, unhurried, never alarmist. Confident because it shows its work, not because it raises its voice. It respects that the person on the other end is capable of understanding the reasoning if you bother to explain it.
- **Tone of voice:** Plain language, second person, short sentences. Always names the pattern actually detected rather than issuing generic warnings. Never uses fear as a substitute for explanation. Example high-risk: "This link isn't going where it says. The domain closely resembles 'paypal' but isn't it." Example safe: "Nothing here matched a known phishing pattern. That checks the link itself, not the page it leads to." Example error: "The camera couldn't read that code. Try moving a little closer."

> Visual identity (mood, anti-patterns, design tokens) is deliberately not
> captured here — it lives in docs/design.md, generated by the Design System
> skill from image references.

## Tech Stack

- **App type:** cross-platform
- **Frontend:** Flutter — one codebase for iOS and Android, so the rule engine that is the actual research contribution gets written once instead of maintained twice; strong OpenCV plugin ecosystem; Dart is approachable from a Swift/Python/Java background
- **Backend:** None — every layer in the MVP runs on-device. A backend would break the core privacy claim the research rests on.
- **Database:** None — on-device key-value storage only, capped at 50 scans. A 50-item cap does not justify a database.
- **Auth:** None — there are no accounts. Nothing to sign into means nothing to breach.
- **Payments:** None — the app is free, and monetisation would compromise the research posture.
- **Analytics:** None — product telemetry would directly contradict the "nothing leaves the device" promise. Store-level install counts are the only measurement.
- **Email:** None — no accounts, so no transactional email.
- **Error tracking:** Sentry — crash reports only, required for responsible public store releases. Scanned URLs, decoded payloads, and scan history are never attached to a report. This is the single network call in the app and it must be documented in the privacy policy.

## Tooling

- **Coding agent:** Claude Code
