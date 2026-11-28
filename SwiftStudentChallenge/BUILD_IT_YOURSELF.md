# Build your Swift Student Challenge app from scratch

A step-by-step plan for building your entry **yourself**, from a blank project, between now and the **February 8–28, 2027** submission window.

The example app is a **CPR practice coach** (call it whatever you like). If you have a problem from your own life you care about more, use the same steps with that idea instead.

> **Rules for using AI (so the work stays yours):**
> - Ask AI to **explain** ("how does CMMotionManager work?", "why does this error happen?"). Don't ask it to write whole files.
> - Type every line yourself. If you copy a snippet from docs or AI, rewrite it until you understand each line.
> - Keep a **build log** (a notes file). Write down what you tried, what broke and what you measured. It becomes your essay material and your honest AI disclosure.
> - The finished example in `HandsOn.swiftpm` is there if you get completely stuck. Try not to open it. Judges reward *your* thinking.

---

## Timeline at a glance

| When | Phase | Done when… |
|---|---|---|
| Week 1 (now – Nov 30) | 0–1: Set up and pick your story | Xcode runs "Hello"; you've written one true paragraph about *why* |
| Week 2 (Dec 1–7) | 2–3: Blank project and screens | You can click through every screen |
| Week 3 (Dec 8–14) | 4: Content | The emergency steps and hand placement are written and checked against a real source |
| | | **Dec 10: Apple's "Meet with Apple" session. Attend it** |
| Week 4 (Dec 15–21) | 5: Tap practice | Tapping shows a live rate per minute |
| Week 5 (Dec 22–28) | 6: Beat and vibration | A steady 110 bpm click and haptic |
| Weeks 6–7 (Dec 29 – Jan 11) | 7: Motion sensing (the hard part) | Pushing on a cushion counts compressions correctly |
| Week 8 (Jan 12–18) | 8–9: Voice coach and results chart | The app coaches you and shows a chart |
| | | **Jan 14: Meet with Apple** |
| Week 9 (Jan 19–25) | 10: Apple Intelligence tip | The tip works, with a fallback |
| Week 10 (Jan 26 – Feb 1) | 11–12: Accessibility and polish | Passes a VoiceOver test; icon done; under 3 minutes |
| Week 11 (Feb 2–8) | 13: Real people test it | At least 5 people tried it and you changed something |
| | | **Feb 4: Meet with Apple** |
| Weeks 12–13 (Feb 9–28) | 14–15: Write and submit | Submitted **before Feb 28** (aim for Feb 20) |

---

## Phase 0: Set up (week 1)

1. **Get the tools.**
   - On a Mac: install **Xcode** (free, Mac App Store). For the 2027 challenge you need **Xcode 27 or later**.
   - On an iPad: install **Swift Playground** (4.7 or later).
2. **Make a free Apple Developer account** at developer.apple.com.
3. **Sign up for updates** on the Swift Student Challenge page and register for the *Meet with Apple* sessions.
4. **Check you're eligible:** you're a student, you meet the age rule for your country, and you're not employed full time as a developer.
5. **Learn the basics if Swift is new to you** (a few evenings):
   - Apple's free **SwiftUI Tutorials** ("Introducing SwiftUI"). Do the first two chapters.
   - Swift Playground's **"Learn to Code 1"**, if you've never coded.
6. **Make a GitHub account** if you don't have one. You'll back up your work there.

**Checkpoint:** you've built and run any tiny SwiftUI app in the simulator.

---

## Phase 1: Your story (week 1)

1. Write **one honest paragraph** in your build log: *Why do I care about this?* For example, a time you felt helpless, someone in your family, a first-aid class, or a news story that stuck with you.
2. If nothing feels true for CPR, **change the idea now** to something you do care about. It's much easier to win with a smaller idea you care about than a big one you don't.
3. Write **one sentence** describing the app (50 words max). This becomes submission question 1.

**Checkpoint:** a paragraph and a sentence that you'd be happy to say out loud to a judge.

---

## Phase 2: A blank app playground (week 2)

1. **Xcode:** File → New → Project → **iOS → App Playground**. Name it (for example `HandsOn`) and save it in a folder you'll keep, such as `~/Developer`.
   - **Swift Playground on iPad:** tap **+ App** on the home screen.
2. Run it in an **iPhone simulator** (Cmd-R). You should see "Hello, world!".
3. **Back it up:** create a new repository on GitHub (private is fine), then in Terminal:

```bash
cd ~/Developer/HandsOn.swiftpm
```

```bash
git init && git add . && git commit -m "Blank app playground"
```

   Then follow GitHub's "push an existing repository" instructions. **Commit at the end of every session.** It shows the judges, and yourself, how your work grew.

**Checkpoint:** a blank app that runs, saved on GitHub.

---

## Phase 3: Screens and navigation (week 2)

**Goal:** click from screen to screen with placeholder text. No features yet.

Screens: **Welcome → Emergency steps → Hand placement → Practice → Results → Takeaways**.

What to learn and build:
- An `enum Stage` listing each screen, and a `@State` (or `@Observable` model) holding the current stage.
- A `switch` in your root view that shows the right screen.
- A button on each screen that moves to the next stage.

Questions to ask AI: *"How do I switch between views in SwiftUI using an enum?"* or *"What's the difference between @State and @Observable?"*

**Checkpoint:** you can tap through all six screens and back to the start.

---

## Phase 4: Content (week 3)

1. Read a **real source** for hands-only CPR: the American Heart Association (AHA), European Resuscitation Council (ERC), or Red Cross pages. Write the steps **in your own words**:
   - Check it's safe.
   - Check for a response (tap and shout).
   - Check breathing for up to 10 s. Gasping isn't normal breathing.
   - Call your emergency number on speaker, and send someone for an AED.
   - Push hard and fast in the centre of the chest: **5–6 cm, 100–120 per minute**. Let the chest come back up fully, and don't stop.
2. Put each step on its own screen with an SF Symbol and one button.
3. Draw the hand placement: a simple `Canvas` drawing, an SF Symbol, or your own illustration.
4. Add a clear line saying **"Practice tool, not a certified course."** Make sure nothing ever dials a real number.

**Checkpoint:** a friend can read your steps and explain CPR back to you.

---

## Phase 5: Tap practice: your first real feature (week 4)

**Goal:** tap the screen like you're pushing on a chest, and see your rate.

1. Make a full-screen tap area. Each tap records the time (`Date()` or `CACurrentMediaTime()`).
2. Rate = 60 ÷ (average time between your last few taps). Write this as a **small function on its own**.
3. Show the rate in big text. Colour it green between 100 and 120, and orange or red outside that range.
4. Add a 30-second countdown that ends the practice.
5. **Test your function:** call it with fake tap times (for example, every 0.5 s should give 120). Write those results in your build log.

**Checkpoint:** you can tap at "about two a second" and see roughly 110–120.

---

## Phase 6: Beat and vibration (week 5)

1. **Sound:** play a short click 110 times a minute.
   - Simple version: `AVAudioPlayer` with a click sound file plus a `Timer`. Notice how it drifts.
   - Better version: `AVAudioEngine` with one beat-long buffer set to **loop**, which never drifts. Ask AI: *"How do I loop an AVAudioPCMBuffer with AVAudioPlayerNode?"*
   - If you use a sound file, **make or record it yourself**, or credit a free source.
2. **Vibration:** use `Core Haptics` to play a tap on each beat. This helps people who can't hear the click.
3. Add an on/off toggle for the beat.

**Checkpoint:** the click stays perfectly in time for 30 seconds.

---

## Phase 7: Measuring real pushes with Core Motion (weeks 6–7). This is the heart of your app

This part makes your app special, and it's where your build log matters most.

1. **See the data first.** Use `CMMotionManager` with `startDeviceMotionUpdates` at about 100 Hz. For each update, compute the **vertical acceleration**: the dot product of `userAcceleration` with the direction of `gravity`. Plot it live with **Swift Charts**.
2. **Look at the graph while you push on a cushion** with the phone in your hands. What does one push look like? Screenshot it for your log.
3. **Count pushes:** find the peaks. Start simple: a peak counts when the value goes above a threshold, and the next one must be at least 0.3 s later. Then improve it:
   - Smooth the signal (average the last few values).
   - Only count a new peak after the signal drops back below zero.
4. **Measure the rate** from the time between peaks, reusing your Phase 5 function.
5. **Stretch goal: depth.** Integrate acceleration to get velocity, and velocity to get position. Position drifts, so ask AI *why*, and how a "leaky integrator" or high-pass filter helps.
6. **Test it for real.** Put a ruler beside the cushion and push about 5 cm. Do 20 pushes at a known pace (follow your metronome). Write down what the app said against reality. Tune, and repeat.
7. Keep tap mode as the option for Macs and iPads, which have no usable motion sensor. **Judges may run your app on a Mac.**

**Checkpoint:** 20 real pushes give a count of 19–21 and a rate within about 5 of your metronome. Record these numbers. They make great essay material.

---

## Phase 8: Voice coach (week 8)

1. Use `AVSpeechSynthesizer` to say short prompts: "Faster", "Slow down", "Push harder", "Don't stop".
2. Decide the rules yourself, for example: no prompt more often than every 3 seconds; pauses first, then rate, then depth.
3. If **VoiceOver** is on, post the prompt as a VoiceOver announcement instead (`UIAccessibility.post`), so two voices never talk at once.

**Checkpoint:** you can practise with your eyes closed and still improve.

---

## Phase 9: Results screen (week 8)

1. Show the number of pushes, the average rate, the percentage on target, and the longest pause.
2. Plot rate over time with **Swift Charts**, with a shaded green band from 100 to 120.
3. Invent your own **score out of 100** and explain the formula in your build log.

**Checkpoint:** after practising, you can see exactly what to fix.

---

## Phase 10: A personal tip from Apple Intelligence (week 9)

1. Read Apple's **Foundation Models** documentation and watch the WWDC session on it.
2. Create a `LanguageModelSession` with clear instructions: CPR technique only, no medical advice, short, and using only the numbers you give it.
3. Use **guided generation** (`@Generable` struct with a `title` and a `tip`) so you always get clean output.
4. Check `SystemLanguageModel.default.availability`. If it isn't available, show a **rule-based tip you wrote yourself**. Judges might not have Apple Intelligence turned on.
5. Wrap it in `if #available(iOS 26, *)` so older devices still work.

**Checkpoint:** you see the tip on a supported device, and the fallback tip everywhere else.

---

## Phase 11: Accessibility pass (week 10)

- Turn on **VoiceOver** (Settings → Accessibility) and use your whole app with your eyes closed. Fix every unlabeled button.
- Try **Dynamic Type** at the largest text size. Nothing should be cut off.
- Respect **Reduce Motion** for animations.
- Check colour contrast, and never use colour as the only signal.
- Run Xcode's **Accessibility Inspector** (Xcode → Open Developer Tool).

**Checkpoint:** a VoiceOver user could complete the whole app.

---

## Phase 12: Polish (week 10)

1. **App icon:** design it yourself, for example in Keynote, Figma or Sketch, at 1024×1024 with no transparency. Add it to `Assets.xcassets` as `AppIcon`.
2. **Three-minute test:** time a first-time run. Cut anything that pushes it over.
3. **Offline test:** turn on airplane mode, delete the app and reinstall it. Everything must work.
4. **Test on every device type:** iPhone simulator, iPad simulator, and **"My Mac (Designed for iPad)"**, since judges may use any of them.
5. Remove debug prints and placeholder text. Read every sentence out loud.

---

## Phase 13: Real people (week 11)

1. Have **at least five people** try it, including someone who knows first aid if you can (a school nurse, a Red Cross or St John volunteer, a lifeguard).
2. Watch silently. Write down where they get confused.
3. Change at least one thing because of what you saw.
4. If you can, run a short "learn CPR with your phone" session for a class or club. That becomes your community answer.

---

## Phase 14: Write your answers (weeks 12–13)

Write these **yourself** after the app is done. `SUBMISSION_ANSWERS.md` shows the usual questions, but don't copy its wording.
- **One sentence** (Phase 1).
- **Experience, frameworks and AI use (500 words max):** why you built it, what the user does, and each framework and *why you chose it*. Include real numbers from your Phase 7 testing, and exactly how you used AI ("I asked Claude to explain leaky integrators; I wrote the detector myself and tuned it with a ruler").
- **Community (optional, 200 words max):** only what you actually did in Phase 13.

Ask a teacher or friend to read it. Then cut every sentence that sounds like an advert.

---

## Phase 15: Submit (Feb 8–28, 2027)

1. Re-read the official rules at developer.apple.com/swift-student-challenge/eligibility. They can change.
2. Open the project in the **latest Xcode or Swift Playground** and run it one last time, offline.
3. In Finder, right-click the `.swiftpm` folder and choose **Compress**. Check that the ZIP is under the size limit (500 MB in 2027).
4. Submit through the form, with your written answers and AI disclosure.
5. **Submit early** (aim for Feb 20). Don't wait for the last night.

---

## If you get stuck

- Search the error message on the Apple Developer Forums or Stack Overflow.
- Ask AI to *explain* the error, and paste only the small part that's broken.
- Shrink the problem: make a tiny test project with just the broken piece.
- Take a break and write in your build log what you've tried. That often reveals the answer.
