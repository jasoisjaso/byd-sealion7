# 0002 — Driver monitoring stays out of scope

Date: 2026-10-04
Status: Accepted

## Context
The owner finds the "keep eyes on road" Driver Attention Warning intrusive and asked for a way to keep it off. Research found: on Australian Sealion 7s it switches back on every drive by design (BYD confirmed this to carsales), no report was found that any update up to 3.3.0 changes that, and owners on r/BYD trade Tasker/ADB automations and sell camera covers to get around it.

## Decision
The kit does nothing to driver monitoring: no ADB settings changes, no Tasker automation, no disabling of its service, no hardware advice. docs/beyond-the-script.md gives the owner the quickest built-in ways to switch it off per drive (the DMS tile on the swipe-down panel, the steering-wheel scroll button that one owner reports pauses warnings for 15 minutes).

## Why
- It is a crash-avoidance system. Switching it off automatically from a sideloaded app changes the car's safety behaviour in a way no insurer or safety rating assumes.
- Anything that works today needs the same ADB access BYD keeps removing in updates, so it would break at the next update anyway.
- The built-in methods are 2-3 taps and work on every software version.

## Alternatives rejected
- Tasker or a boot-time script toggling the setting: needs an always-on sideloaded app with accessibility rights; fragile; alters safety behaviour.
- `adb shell settings put` or `pm disable` on the monitoring service: system-level change, contradicts ADR 0001, unknown side effects on the other cabin functions (child presence detection shares the camera).
- Camera covers: blind the sensor, not the logic; owners report child-presence alerts still fire; legal and insurance position unknown.
