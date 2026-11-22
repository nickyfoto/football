# Swift Student Challenge entries

There are two app playgrounds here. Both are offline, need no sign-in, and take about three minutes.

| | App | What it is |
|---|---|---|
| ⭐ **Recommended** | [`HandsOn.swiftpm`](HandsOn.swiftpm) | Learn hands-only CPR, then practise it. Your phone's motion sensors measure how fast and how deep you push, and it coaches you live by voice, beat and vibration. |
| Alternative | [`Rattle.swiftpm`](Rattle.swiftpm) | Learn blind football by ear, with 3D spatial audio. |

Open either one in Swift Playground (iPad or Mac) or Xcode, and press Run.

---

## 1. What last year's winners did (Swift Student Challenge 2026)

Apple announced 350 winners from 37 countries and regions in May 2026, and invited 50 Distinguished Winners to WWDC. Apple titled the announcement *“AI meets accessibility.”* Four Distinguished Winners were featured:

| App | Who | What it does | Apple tech used | The story behind it |
|---|---|---|---|---|
| **Steady Hands** | Gayatri Goundadkar, 20, India | Helps people with hand tremors draw on iPad | PencilKit and Accelerate analyse stroke and motion data to find tremor frequency. Drawings end up in a "3D museum" | Her grandmother painted Warli art with her until her hands began to shake |
| **Pitch Coach** | Anton Baranov, 22, Germany | Real-time presentation feedback, plus posture tracking through AirPods | **Foundation Models** (on-device AI) for feedback, filler-word detection, AirPods motion. Localised into 20 languages | His mother, a linguistics professor, said her students freeze when presenting. It reached 6,000+ App Store downloads |
| **Asuo** | Karen-Happuch Peprah Henneh, Ghana | Safe evacuation routes in flood zones | A* pathfinding over historic flood data, a rain simulator, **VoiceOver** labels and hints, spoken alerts with AVSpeechSynthesizer | The fatal 2015 Accra floods |
| **LeViola** | Yoonjae Joung, 21, South Korea | Learn the viola without owning one | **Create ML and Core ML** hand-joint and bow-arm tracking through the camera | He couldn't fit his viola in his suitcase for an exchange semester |

### The patterns behind those wins

1. **A real person and a real problem.** Every featured winner opens with a specific human story (a grandmother, a mother's students, a flood, a missing instrument). Apple's official criteria are *“innovation, creativity, social impact, or inclusivity.”*
2. **Accessibility at the core.** It isn't bolted on at the end. All four apps serve people the mainstream design leaves out.
3. **Deep use of one or two Apple frameworks.** PencilKit with Accelerate, Foundation Models, Create ML with Core ML, AVSpeechSynthesizer with VoiceOver. Each app does something that only works well on Apple hardware.
4. **Fully on-device and offline.** Judges run the app offline, so nothing can depend on the network.
5. **A tight, guided experience of about three minutes.** It's a polished, interactive story, not a large app with menus.
6. **AI tools are fine.** Winners openly used Claude, Codex and Gemini to learn and to build. Apple featured this in the announcement.

---

## 2. HandsOn (recommended): why it should win

**The idea:** most people have never practised CPR. When someone collapses, bystanders freeze. HandsOn teaches the steps in about a minute. Then you **practise with your own hands for 30 seconds**: hold your phone and push into a cushion, and the phone measures every compression. It coaches you toward the real guideline numbers (adult hands-only CPR, AHA 2020 and ERC 2021): **100–120 compressions a minute, 5–6 cm deep, with no pauses.**

The three-minute flow: welcome, four quick emergency steps (safe? responsive? breathing? call for help and an AED), hand placement, the 30-second live practice, your results with a chart, and three takeaways.

| What winners had | How HandsOn does it |
|---|---|
| Social impact | CPR is the single most useful thing a bystander can learn. Starting it right away can double or triple the chance of survival. Everyone in three minutes learns a skill that can save a life |
| Quick to try, no sign-in | No account, no network, no assets. A judge is practising within about a minute |
| Deep use of Apple frameworks | **Core Motion**: compressions are measured from gravity-removed acceleration projected onto the vertical, so it works however the phone tilts. **AVAudioEngine**: a 110 bpm metronome synthesised in code that never drifts. **Core Haptics**: a looped beat you can feel. **AVSpeechSynthesizer**: live voice coaching. **Swift Charts**: your rhythm over time against the target band. **SwiftUI** throughout |
| Real signal processing | `Sensing/CompressionDetector.swift` band-passes the signal, picks peaks with hysteresis (each push ends in a sharp upward deceleration spike), and double-integrates with leaky integrators to estimate depth. On synthetic test signals with noise and sensor bias it measures **rate within about 1% and depth within about 5%**, and reports no pushes when the phone is held still |
| Accessibility at the core | You don't need to see the screen during practice, because voice and vibration do the coaching. It supports VoiceOver: prompts become announcements, the tap pad uses direct touch, and charts get Audio Graphs automatically. Deaf and hard-of-hearing users get a haptic beat plus on-screen prompts. It respects Reduce Motion. A **tap mode** works on any device, including Mac, and the keyboard space bar also counts as a push |
| Honest and responsible | It states clearly that it is a practice tool, not a certified course or medical device. It never dials a real number. It uses guideline-accurate steps (for example, "gasping is not normal breathing" and "check breathing for no more than 10 s") |

### Making HandsOn yours

- **Your story:** set `personalNote` in `Views/IntroViews.swift`. Have you ever seen someone collapse, taken a first-aid class, or had a family member with a heart condition? Use something **true**.
- **Validate it for real:** test on an iPhone with a cushion, and compare the depth estimate against a ruler held next to the cushion. If you can, ask a first-aid instructor (for example, from your school or a local Red Cross or St John chapter) to try it, and quote their feedback in your submission.
- **Ideas for extra polish:**
  - Show the local emergency number for the device's region (112, 911, 999…).
  - An AED walkthrough.
  - Apple Watch wrist detection.
  - Localisation.
  - On-device **Foundation Models** to turn your session data into a personalised tip. This is the AI angle Apple highlighted, but it must work offline.

---

## 3. Rattle (alternative): why it fits

| What winners had | How Rattle does it |
|---|---|
| Social impact and inclusivity | It celebrates a Paralympic sport played by blind athletes and builds empathy in sighted players. It is also fully playable *by* blind players |
| Accessibility at the core | The whole game is designed to be played with your eyes closed. It supports VoiceOver (swipe up or down to turn, double-tap to act, rotor actions to dodge), spoken coaching, and hardware-keyboard controls. It also works **without sound**: haptics and a glow get stronger as you face the target, and "See the sound" shows a radar with captions for players who are deaf or hard of hearing |
| Deep use of Apple frameworks | **AVAudioEngine and AVAudioEnvironmentNode** for 3D sound (HRTF), **Core Motion** (you turn your body to look around), **Core Haptics**, and **AVSpeechSynthesizer**. Its `write` method renders “Voy!” and “Here!” into buffers so they can be placed in 3D space. Built with **SwiftUI** (Canvas and TimelineView) |
| Offline, no assets | **Every sound is synthesised in code** (the ball rattle, goalpost knock, whistle and crowd). The ZIP contains no audio files and makes no network calls |
| A three-minute story | Welcome, then four story cards, then three drills of three rounds each (find the ball, dodge, shoot), then a full-time summary |
| Novelty | Most entries are visual. Rattle is an *audio-first* game, which is rare and memorable, and it connects to this repo's football theme |

### How it works

- **3D sound:** each source (ball, defender, guide) is a mono `AVAudioPlayerNode` using `.HRTFHQ` rendering into an `AVAudioEnvironmentNode`. Sources are placed relative to where you face, so turning changes what you hear.
- **Turning your body:** the app takes the dot product of the device's rotation rate with gravity. That gives the turn rate around the vertical axis however the device is held (flat, upright or tilted), and it needs no permission prompt.
- **Voices in 3D:** `AVSpeechSynthesizer.write(_:toBufferCallback:)` produces PCM buffers. The app resamples them to 44.1 kHz mono and trims the silence, so the defender's “Voy!” can come from the correct side. If on-device speech is unavailable, a synthesised shout is used instead.
- **Blind football rules, accurately modelled:** a 3 m goal seen from 9 m gives ±9.5° to score. The guide knocks the left post, then the right post, then calls from the centre. Defenders must call before tackling. The crowd stays silent until a goal.

---

## 4. What YOU still need to do (for either app)

These steps make the difference between a good entry and a winning one. Apple judges *you*, not just the code.

1. **Write your own story.** Set `personalNote` (HandsOn: `Views/IntroViews.swift`; Rattle: `Views/StoryView.swift`) to one or two **true** sentences about why you built this. Did you play football, know a visually impaired person, watch the Paralympics, or wonder what playing blind would feel like? Judges reward authenticity. Don't invent a story. If you have a stronger personal connection to a different problem, use these patterns on *that* idea instead.
2. **Build and test on a real device** (an iPhone for HandsOn's cushion mode; headphones for Rattle). This code was written in a Linux container. It passes a Swift syntax check, but it has **not been compiled against the iOS SDK or run on a device**. Expect to fix a few small compile issues in Xcode or Swift Playground. Then tune the feel: for HandsOn, the detection thresholds and how often the coach speaks; for Rattle, volumes and timing.
3. **Test it with VoiceOver on, and with real users.** For HandsOn, ask a first-aid instructor. For Rattle, ask a blind or low-vision player. Add one line about their feedback to your submission. That is exactly the kind of community impact the winners showed.
4. **Make it yours.** Add a custom app icon instead of the placeholder, and at least one feature you thought of yourself.
5. **Time it.** The full run should take three minutes or less. Use the skip buttons to check every path.
6. **Credit your tools.** Apple allows AI assistance and open-source code, with credit and an explanation. Be honest about how you used AI. The winners were.

### 2027 timeline and rules (from Apple's site, checked November 2026)

- **Submissions:** February 8–28, 2027. Apple's "Meet with Apple" sessions are on December 10, 2026, January 14, 2027 and February 4, 2027. Attend at least one.
- **Format:** an app playground (`.swiftpm`) or Xcode app in a ZIP file of up to 500 MB. It must be **experienced within three minutes**, work **offline**, be your own **individual work**, and be written **in English**.
- **Tools:** built and run with **Xcode 27 or Swift Playground 4.7**, or later. Open and re-save the project in those versions before you submit.
- **Eligibility:** you must be a registered Apple developer (free), not employed full time as a developer, meet your country's minimum age, and be a student (or a recent graduate within the stated window).
- **Limits:** you can win up to three times, but be a Distinguished Winner only once.

Always re-check <https://developer.apple.com/swift-student-challenge/eligibility> before submitting.

### Sources
- Apple Newsroom, “AI meets accessibility in this year's Swift Student Challenge” (May 2026): <https://www.apple.com/newsroom/2026/05/ai-meets-accessibility-in-this-years-swift-student-challenge/>
- Swift Student Challenge: <https://developer.apple.com/swift-student-challenge/>
- Eligibility and requirements: <https://developer.apple.com/swift-student-challenge/eligibility>
- Terms and conditions: <https://developer.apple.com/swift-student-challenge/policy>

---

## Project layout (Rattle)

```
Rattle.swiftpm/
├── Package.swift            iOS 17+ app playground (iPad and iPhone)
├── MyApp.swift
├── Audio/
│   ├── SoundFactory.swift   every sound synthesised in code
│   ├── SpatialAudio.swift   HRTF 3D sound stage (AVAudioEnvironmentNode)
│   └── Speech.swift         speech → 3D voice buffers; spoken coaching / VoiceOver announcements
├── Game/
│   ├── Drill.swift          stages, drill content, helpers
│   ├── GameModel.swift      drills, rules, motion turning, timing
│   └── Haptics.swift        Core Haptics "facing the sound" hum
└── Views/                   SwiftUI screens: welcome, story, drill intro, pitch (radar/orb), finale
```

## Project layout (HandsOn)

```
HandsOn.swiftpm/
├── Package.swift               iOS 17+ app playground (iPhone and iPad; tap mode on Mac)
├── MyApp.swift
├── Sensing/
│   ├── CompressionDetector.swift   pure-Swift rate and depth detection, plus guideline targets
│   └── MotionSensor.swift          Core Motion → vertical acceleration
├── Coach/
│   ├── CoachModel.swift            stages, practice session, live coaching, scoring
│   └── Feedback.swift              metronome (AVAudioEngine), voice coach, haptics
└── Views/                          welcome, emergency steps, hands, mode, practice, results (Swift Charts), finale
```
