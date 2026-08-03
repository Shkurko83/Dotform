# Dotform

**Languages:** **English** | [Русский](README.ru.md)

**A tactile language and iOS/watchOS app for learning Braille and communicating with blind and deafblind people through vibration on a smartphone and Apple Watch.**

> **DotForm Language** - an original method that turns a six-dot Braille cell into a sequence of vibration signals across three horizontal screen zones. The Dotform project is the software implementation of that method: learning, configurable tactile feedback, and text transfer from a sighted person's device to a blind or deafblind person's phone or watch.

---

<!-- SCREENSHOT: hero / main app screen (lessons list or onboarding with the Dotform name). Preferred size: wide banner or iPhone screenshot. -->
<!-- ![Dotform - home screen](docs/screenshots/01-home-or-lessons.png) -->

## Contents

1. [Why Dotform](#why-dotform)
2. [Authorship and priority statement](#authorship-and-priority-statement)
3. [The invention: DotForm Language](#the-invention-dotform-language)
4. [How a symbol card is "read"](#how-a-symbol-card-is-read)
5. [Learning and practice](#learning-and-practice)
6. [Communication: sending text as vibration](#communication-sending-text-as-vibration)
7. [What the app can do](#what-the-app-can-do)
8. [Technical architecture](#technical-architecture)
9. [Stack and requirements](#stack-and-requirements)
10. [Build and run](#build-and-run)
11. [Repository layout](#repository-layout)
12. [Roadmap](#roadmap)
13. [License and contact](#license-and-contact)

---

## Why Dotform

Classic Braille relies on **touching raised dots**. Digital devices almost never give a deafblind person an equivalent channel: the screen is flat, speech may be unavailable or limited, and standard iOS haptics do not encode letters.

**The problem is especially acute for deafblind people:** no sight and often no hearing - the tactile channel remains. Existing solutions (refreshable Braille displays, tactile signing, palm spelling) are valuable but expensive, require a partner nearby, or need specialized hardware.

**Dotform does not replace** Braille, gesture systems, or teachers of the deafblind. It **complements** them and makes everyday **smartphones and smartwatches** more usable:

- learn symbols via **DotForm cards** by sliding a finger from top to bottom;
- communicate: a sighted person types on their phone - a blind or deafblind person **feels** the same text as vibration on a phone or Apple Watch;
- tune intensity, sharpness, and duration to individual tactile sensitivity.

If the approach takes hold in practice and in the community, it may encourage Apple, Google, and other platforms to grow accessibility APIs so developers can embed DotForm Language in their own apps.

---

## Authorship and priority statement

This open repository records the **concept, encoding method, and software implementation** of learning and transmitting Braille through spatially zoned screen vibration (**DotForm Language**), developed by the project author.

| | |
|---|---|
| **Method name** | DotForm Language |
| **Software product** | Dotform app (iOS / watchOS) |
| **Author** | Shkurko83 ([GitHub repository](https://github.com/Shkurko83/Dotform)) |
| **Source publication** | Public GitHub repository with dated commit history |
| **Purpose of publication** | Open description of the invention; dated evidence of development and priority for patent filing |

Open publication **does not waive rights** in the invention. The author reserves the right to seek patent protection for DotForm Language and related implementations. Use of the code is governed by the repository license (see below); use of the **method idea** in commercial products is not automatically granted.

> This README is part of the public description of the invention: the three-zone layout, the long / single-short / double-short rules, card-based learning scenarios, and cross-device text delivery as a vibration stream.

---

## The invention: DotForm Language

### The Braille cell

Standard six-dot cell:

```
  1   4
  2   5
  3   6
```

Dots 1-3 - left column (top to bottom); dots 4-6 - right column.

### Core DotForm idea

A symbol card on the phone screen is **split into three horizontal zones**:

| Zone | Braille dots |
|------|----------------|
| **Top** | 1 (left) and 4 (right) |
| **Middle** | 2 (left) and 5 (right) |
| **Bottom** | 3 (left) and 6 (right) |

Each zone maps to **one vibration pattern**, depending on which dots in that row are raised:

| Zone contents | DotForm vibration |
|---------------|-------------------|
| **Both** left and right dots | **Long** continuous signal |
| **Left only** | **One short** signal |
| **Right only** | **Two short** signals in a row |
| No dots | Zone signal is **omitted** (pause / skip) |

A Braille character thus becomes an **ordered top-to-bottom sequence of one to three vibration events** (one per non-empty zone). The learner slides a finger **down through all three zones**, receives those signals in order, and builds the letter by touch - without embossed paper and without requiring speech.

That is **DotForm Language**: a spatially zoned vibration language for digital Braille.

<!-- SCREENSHOT: full-screen Braille letter card (BrailleCell / lesson), preferably with visible dots. Caption: "Symbol card - three horizontal zones". -->
<!-- ![DotForm symbol card](docs/screenshots/02-braille-card-zones.png) -->

### Encoding diagram

```
        ┌─────────────┬─────────────┐
   TOP  │   • 1       │   • 4       │  →  long  /  one short  /  two shorts  /  silence
        ├─────────────┼─────────────┤
 MIDDLE │   • 2       │   • 5       │  →  same rule
        ├─────────────┼─────────────┤
 BOTTOM │   • 3       │   • 6       │  →  same rule
        └─────────────┴─────────────┘
              finger moves top ↓ bottom
```

**Example.** A letter with dots 1 and 2 filled (left top and left middle):

1. Top zone → one short (left only).  
2. Middle zone → one short (left only).  
3. Bottom zone → silence (empty).

Sliding top to bottom yields two short pulses with a pause - the tactile "fingerprint" of that letter in DotForm.

<!-- SCREENSHOT: sensory exercise "top / middle / bottom" or a lesson highlighting zones. -->
<!-- ![Three screen zones](docs/screenshots/03-three-zones-exercise.png) -->

---

## How a symbol card is "read"

1. The screen shows a **card** with a Braille cell (dots may be visible for a sighted companion; for a deafblind child visuals are optional).
2. The learner places a finger at the **top** and slowly moves **down**.
3. Entering each zone triggers the matching DotForm pattern (or silence if the zone is empty).
4. After all three zones, the learner has the full tactile form of the symbol.
5. Reinforcement and testing follow (build the letter, distinguish similar shapes, etc.).

The method trains a **new digital way to read Braille**, not an instant replacement for paper Braille. After DotForm is learned, the same zone code can drive **streaming text playback** without finger tracing - the device plays the symbol's signal sequence itself.

---

## Learning and practice

The app moves from sensory prep to letters:

1. **Sensory prep** - tell short from long, soft from strong, left/right, top/middle/bottom.  
2. **Spatial basics** - find one or two dots on the cell.  
3. **First letters and full cell** - study symbols of the active alphabet (Russian / English Grade 1).  
4. **Letter in context and review** - repetition, error-based recommendations, progress.

Profiles:

- **Blind child** - speech, sound, and vibration;  
- **Deafblind child** - vibration as the primary channel;  
- **Parent / teacher** - letter set, difficulty, session controls.

<!-- SCREENSHOT: lessons / levels list. -->
<!-- ![Lessons list](docs/screenshots/04-lessons-list.png) -->

<!-- SCREENSHOT: progress screen. -->
<!-- ![Learning progress](docs/screenshots/05-progress.png) -->

---

## Communication: sending text as vibration

The second part of the invention is a **communication channel**.

1. A **sighted** person (parent, teacher, partner) types ordinary text on an iPhone in **Writer** mode.  
2. Devices **pair locally via QR** (Multipeer Connectivity: Bluetooth / local Wi-Fi).  
3. Text is sent to the **blind or deafblind** phone in **Receiver** mode.  
4. The receiver **shows symbol cards** in order and plays a **vibration stream** using the user's settings (intensity, sharpness, duration, custom patterns).  
5. The same stream can be relayed to an **Apple Watch** via WatchConnectivity - the message can be felt on the wrist.

Someone who has learned DotForm Language can **understand incoming text by touch**, without a Braille display and without requiring speech. The same message protocol is designed so local transport can later be replaced by an internet messenger without changing the "text → symbols → vibration" model.

<!-- SCREENSHOT: Relay screen with QR (receiver mode). -->
<!-- ![QR pairing](docs/screenshots/06-relay-qr.png) -->

<!-- SCREENSHOT: writer screen with text field. -->
<!-- ![Sending text](docs/screenshots/07-relay-writer.png) -->

<!-- SCREENSHOT: receiver - symbol card while a message plays. -->
<!-- ![Receiver symbol playback](docs/screenshots/08-relay-receiver-card.png) -->

---

## What the app can do

| Section | Features |
|---------|----------|
| **Lessons** | Sensory exercises, RU/EN letter learning, model-hand sequence, build-and-check |
| **Progress** | Successes, errors, review recommendations |
| **Signals** | Broad catalog of system and Core Haptics vibrations, system and synthesized sounds; assign signals to feedback roles; **custom haptic builder** (intensity, sharpness, duration, envelope) |
| **Relay** | QR pairing, send/receive text, card queue + vibration, stop, Apple Watch |
| **Settings** | Child profile, Braille script language, letter set, haptic intensity, pauses, play-dots-in-sequence for relay |

<!-- SCREENSHOT: vibration / signal catalog. -->
<!-- ![Signal catalog](docs/screenshots/09-sensory-catalog.png) -->

<!-- SCREENSHOT: custom haptic builder. -->
<!-- ![Custom haptic builder](docs/screenshots/10-custom-haptic.png) -->

<!-- SCREENSHOT: settings (profile / alphabet). -->
<!-- ![Settings](docs/screenshots/11-settings.png) -->

---

## Technical architecture

```
┌──────────────────┐     QR + Multipeer      ┌──────────────────────┐
│  Writer iPhone   │ ───────────────────────► │ Receiver iPhone      │
│  (text)          │     RelayEnvelope JSON   │ cards + vibration    │
└──────────────────┘                          └──────────┬───────────┘
                                                         │ WCSession
                                                         ▼
                                               ┌──────────────────────┐
                                               │ Apple Watch          │
                                               │ symbol + haptic      │
                                               └──────────────────────┘
```

- **Alphabets:** scalable `BrailleScript` / `BrailleGlyph` catalog (full Russian, English Grade 1; ready for more languages).  
- **Feedback:** composite audio/haptic engine, Sensory catalog + Core Haptics, user-defined patterns.  
- **Relay:** versioned `RelayEnvelope` (ready for a future internet transport).  
- **Text tokenization:** `TextToHapticEncoder` → glyph queue → card + playback.  
- **Accessibility:** VoiceOver labels, speech-off profiles for deafblind users, large full-screen cards.

Details - digits and punctuation vibro-alphabet specification (DotForm Language): [`Dotform/Docs/VibroAlphabetDigitsPunctuation.md`](Dotform/Docs/VibroAlphabetDigitsPunctuation.md) (currently in Russian).

---

## Stack and requirements

- **Language:** Swift / SwiftUI  
- **Platforms:** iOS (iPhone), watchOS (Apple Watch)  
- **Key frameworks:** UIKit Feedback / Core Haptics, AVFoundation, MultipeerConnectivity, WatchConnectivity, camera for QR  
- **Xcode:** current version matching the project's deployment target  
- Full scheme with embedded Watch requires the **watchOS platform** installed in Xcode  

---

## Build and run

```bash
git clone git@github.com:Shkurko83/Dotform.git
cd Dotform
open Dotform.xcodeproj
```

1. Select the **Dotform** scheme.  
2. Use a real iPhone (simulator haptics / Core Haptics are limited).  
3. For Watch - **DotformWatch** scheme/target and a paired Apple Watch.  
4. For Relay, allow **Local Network** and **Camera** (QR scan).

---

## Repository layout

```
Dotform/                 # iOS app
  App/                   # Root, AppState, tabs
  Data/                  # RU/EN alphabets, lesson catalog
  Docs/                  # Vibro-alphabet extension docs
  Models/                # Braille, settings, relay, sensory
  Services/              # Haptic, speech, lessons, Multipeer, Watch bridge
  Views/                 # Lessons, cell card, relay, signals, settings
DotformWatch/            # Apple Watch companion
Dotform.xcodeproj/
README.md                # English (this file)
README.ru.md             # Russian
```

---

## Roadmap

- [ ] Full digits and punctuation vibro-alphabet in the learning UI  
- [ ] Internet messenger on the same `RelayEnvelope`  
- [ ] Additional alphabets (e.g. German)  
- [ ] Stronger DotForm Language encoding in streaming playback (explicit long / short / double-short zone patterns per symbol)  
- [ ] Teaching materials for parents and educators  

---

## License and contact

Repository: [github.com/Shkurko83/Dotform](https://github.com/Shkurko83/Dotform)

For licensing, collaboration, and **patent protection of DotForm Language**, contact the author via GitHub.

---

### Short invention formula (reference)

> A method of tactile presentation of a Braille character on a touchscreen electronic device, wherein the screen surface showing the cell is divided into three horizontal zones corresponding to the upper, middle, and lower rows of cell dots; for each zone a vibration signal is formed by the rule: both dots present - long signal; left only - one short; right only - two shorts; the user perceives the character by sliding a touch from top to bottom through those zones. The method also includes transmitting a sequence of text characters as corresponding vibration signals from one device to another (including a wearable device) for communication with blind and deafblind users.

*Publication: public GitHub repository with dated commit history.*
