# BYD Sealion 7 DMS shortcut + Claude Android without GMS (research as of 2026-10-04)

## 1. Quickest official way to turn off Driver Monitoring (DMS) on Sealion 7

- CONFIRMED: Full menu path: Settings (gear) → Vehicle → Cabin Perception → Driver Attention Warning → Off → confirm OK. Turning it off **lasts for the current drive only** and it comes back on after a restart.
  https://www.youtube.com/watch?v=Q4m8j0TMONE (HardReset_info, May 2026, generic BYD)
- CONFIRMED (owner reports): AU owners put DMS on the **swipe-down control panel / quick menu shortcut**. "It's called DMS. If you swipe down on the control panel it will have a shortcut."
  https://www.reddit.com/r/BYDShark_AUS_owners/comments/1kiwc63/how_to_turn_off_driver_monitoring/ (search snippet; full page wouldn't load)
  "I have just put it in my quick menu and just turn it off" — https://www.reddit.com/r/AustralianEV/comments/1rbzwk8/thoughts_on_byd_sealion_7/ (snippet)
- CONFIRMED (one owner report): AU Sealion 7 owner: the shortcut turns LKA off in 1 tap, but **driver monitoring takes 2–3 taps** (probably tap the tile, then confirm the dialog).
  https://www.reddit.com/r/BYD/comments/1jp7z47/adas_reliability_and_shortcuts_with_sealion_7/ (snippet)
- CONFIRMED: BYD told a carsales reader that ADAS items can be switched off but turn back on with every start.
  https://www.carsales.com.au/editorial/details/your-questions-answered-how-can-i-permanently-switch-off-annoying-driver-assist-systems-143213/
- UNCERTAIN / not found: no source shows a voice command ("Hi BYD, turn off driver monitoring") that works for DMS. The manual's example voice commands cover only climate, navigation, media and calls. Worth trying, but it is unverified.
- UNCERTAIN / not found: no source shows the custom steering-wheel button can be set to toggle DMS. An r/BYD "Sealion 7 Shortcuts" thread lists a steering-wheel "turn off warnings" button as a *wish*, which suggests it doesn't exist.
  https://www.reddit.com/r/BYD/comments/1qmmrc3/byd_sealion_7_shortcuts/
- CONFIRMED (one owner report, same thread, comment by u/jemesct, 26 Jan 2026, re-read 2026-10-04): "When the system sounds a fatigue or distraction warning, pressing the scroll button on the steering wheel pauses the warning for 15 minutes, during which no warnings will be given." This does not switch DMS off; it pauses the warnings. Single report, car market not stated, not tried on an Australian car.
- UNCERTAIN: persistence after an OTA. OTA 3.0.0 made **Child Presence Detection** stay off after a restart (https://www.reddit.com/r/BYD/comments/1nm0h7y/ota_300_news/ ; Whirlpool p141 snippet). No source says any 3.x update (3.0.1 / 3.1.0 / 3.2.x; 3.2.3 = 51.1.4.2604130.1) made DMS persist. Reports up to mid-2026 still say it re-enables every drive. One Whirlpool post says Child Protection kept turning back on after an update.
  https://forums.whirlpool.net.au/thread/3vw46lj5?p=141 (snippet only) ; https://www.mybyd.co.uk/byd-sealion-7-ota-3-2-2/
- Note (observation, not a method): one Whirlpool user says sunglasses trigger a "driver monitoring disabled" message.

**Best answer:** add the DMS tile to the swipe-down quick-control panel. That's about 2–3 taps per drive (swipe, tap DMS, confirm). No official way to keep it off permanently was found.

## 2. Claude Android app (com.anthropic.claude) without Google Play Services

- CONFIRMED: Official minimum is **Android 8.0 Oreo**, so Android 11 is fine. Other sites say Android 10 or 14; the 14 figure is only for the Health Connect feature.
  https://support.claude.com/en/articles/9612887-install-claude-for-android
- CONFIRMED: The only official install source is the Play Store. "Unsupported device" is given as a reason it may not appear.
  (same URL)
- CONFIRMED (one user report, 2024): "The Claude app just launched and works on Huawei" (no GMS).
  https://www.reddit.com/r/Huawei/comments/1e450gw/chatgpt_does_not_work/ (snippet)
- UNCERTAIN: GrapheneOS thread titled "Can't install Perplexity, ChatGPT, Claude". The page didn't load, so the cause is unknown (possibly Play-side device/integrity filtering). The reply recommends using the website instead.
  https://www.reddit.com/r/GrapheneOS/comments/1qfhtig/cant_install_perplexity_chatgpt_claude/
- UNCERTAIN: no reports found specific to microG, LineageOS without gapps, or car head units.
- UNCERTAIN: whether it's a single APK or a split bundle. APKMirror has many versions (https://www.apkmirror.com/apk/anthropic/claude/), but the format of current builds wasn't checked. Most modern Play apps ship as split bundles, which Aurora Store installs natively. Aurora downloads Google's own developer-signed packages (anonymous login works).
- CONFIRMED: Email login exists ("Continue with email" sends a magic link). If the link is opened on another device or in a browser, it shows a **verification code** to type into the app.
  https://support.claude.com/en/articles/13189465-log-in-to-your-claude-account
- CONFIRMED (user reports): Email login on mobile can be flaky. The link opens the browser instead of the app. Workaround: open the link in a private tab or on another device, say "no" to opening the app, then enter the code it shows.
  https://www.reddit.com/r/ClaudeAI/comments/1rpv2t8/claude_mobile_app_asks_for_a_login_code_that/
- UNCERTAIN: whether push notifications or voice work without GMS. Notifications almost certainly use FCM, so expect none.
- CONFIRMED (fallback): claude.ai works in a mobile browser and can be installed as a PWA ("Install app" from the Chrome menu).
  https://www.reddit.com/r/ClaudeAI/comments/1b82i3v/i_signed_up_for_claude_ai_but_i_dont_find_an/
  Note: the "Claude in Chrome" *extension* is desktop-only. That is separate from using claude.ai in a mobile browser.
  https://support.claude.com/en/articles/12012173-get-started-with-claude-in-chrome
- UNCERTAIN: no official supported-browser list was found for Brave/Chrome on Android 11. A current Chrome/Brave (Chromium) build should work. The real risk is an outdated system WebView/Chrome on the head unit.
