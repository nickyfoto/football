# HandsOn: draft written answers

> **Read this first.**
> - **Apple's terms require the essay answers to be written by you.** Use these drafts as a starting point. Rewrite them in your own voice and fill in every `[bracket]` with something true. Judges read thousands of these, and a real, specific detail beats polished wording every time.
> - **Check the live form when it opens (February 2027).** The questions and word limits below match the format Apple has recently used. They could change.
> - **Be honest about AI.** Apple allows AI tools if you disclose them, but the work must substantially be yours and you must understand it. So far, most of HandsOn's code was generated with Claude. Before you submit, rebuild, change and extend it yourself until you can explain every file. Then describe that work truthfully in the AI section below.

---

## 1. Describe your app playground in one sentence (max 50 words)

> HandsOn teaches anyone hands-only CPR in three minutes, then turns an iPhone into a real-time coach that measures the speed and depth of your chest compressions with Core Motion, coaches you by voice and vibration, and gives a personal tip written on-device by Apple Intelligence.

*(46 words)*

---

## 2. Describe the user experience you were aiming for, the frameworks you used and why, and how you used any AI tools (max 500 words)

> [One or two TRUE sentences about why you care, e.g. a moment you felt helpless, a family member, a first-aid class. No story? Say honestly what made you curious.]
>
> When someone's heart stops, bystanders are the only help before an ambulance arrives, and most freeze. Reading about CPR doesn't build muscle memory. I wanted a three-minute experience, with no account or internet, that leaves you having *actually done* chest compressions and knowing whether they would have helped.
>
> HandsOn walks you through a bystander's four decisions (safety, response, breathing, calling for help and an AED) and shows where to place your hands. Then comes a 30-second practice. You hold your phone in your hands and push into a cushion, and HandsOn measures every compression against the guideline targets: 100–120 per minute, 5–6 cm deep, with no pauses. Because you can't look at the screen while doing compressions, all coaching is by voice ("Faster", "Push harder", "Don't stop") and by a beat you can hear and feel. Afterwards you get a score, a rhythm chart and a personal tip.
>
> **Core Motion** is the heart of the app. I project the gravity-free acceleration onto the gravity vector, which gives up-and-down movement however the phone is tilted. A detector band-pass filters it, finds the sharp upward spike at the bottom of each push, and double-integrates acceleration to estimate depth. On test signals it measured rate within about 1% and depth within about 5%. [Add what you found testing it with a ruler on a real cushion.]
>
> **AVAudioEngine** plays a 110 bpm metronome built from one synthesised beat on a loop, so it never drifts and needs no audio files. **Core Haptics** loops the same beat as a vibration, so Deaf and hard-of-hearing users can feel the rhythm. **AVSpeechSynthesizer** speaks the coaching. **Swift Charts** plots your rate against the target band, and VoiceOver users get an Audio Graph automatically. The **Foundation Models** framework uses Apple Intelligence on-device to write one personalised tip from your numbers. I used guided generation (`@Generable`) so the model always returns a short title and tip. Its instructions limit it to CPR technique: no diagnosis and no invented numbers. If Apple Intelligence isn't available, the app falls back to rule-based tips, so it works on every device and offline.
>
> Accessibility shaped the design: VoiceOver announcements instead of overlapping voices, direct touch on the tap pad, Reduce Motion support, and a tap-to-the-beat mode for devices without suitable motion sensors.
>
> **AI tools:** I used Claude (Anthropic) to [research past winners and the CPR guidelines, generate a first version of the code, …]. I then [rewrote X, tuned the detector thresholds on my own phone, redesigned Y, added Z]. Every part of the app was tested and adjusted by me, and I can explain how each part works. [Be specific and truthful.]

*(about 470 words with the placeholders. Recount after you edit.)*

---

## 3. (Optional) Tell us about how you've shared your knowledge or used technology to help your community (max 200 words)

> Only write about things you've **actually done**. Some ideas for the time between now and the February 2027 deadline:
> - Ask a first-aid instructor (school nurse, Red Cross, St John Ambulance, or a local fire department) to try HandsOn, and add their feedback.
> - Run a 10-minute "learn CPR with your phone" session for a class or club. Say how many people took part and what you changed afterwards.
> - Teach Swift to someone, mentor at a coding club, or publish the detector as open-source code.

Template:

> [Describe what you did, with whom, and a number if you have one.] For example: "In January I ran a lunchtime session for [N] classmates in our school's first-aid club. Each person practised for 30 seconds with HandsOn. Their average on-target rate went from [x]% on their first try to [y]% on their second. Our school nurse, [name/role], suggested [change], which I added." [Then one sentence on what you plan to do next, such as releasing it on the App Store for free or translating it for your community.]

---

## 4. (Optional) Anything else?

> [If it's true for you: "I plan to release HandsOn for free on the App Store," or "I'd like to work with [organisation] to bring it to schools." Keep it to one or two sentences.]

---

### Tips for the written part
- **Lead with the human reason.** Every 2026 Distinguished Winner did.
- **Be specific.** "Depth was 0.6 cm too shallow on my sofa cushion, so I…" beats "I used advanced algorithms".
- **Name the frameworks and say *why* you chose each one.** Judges want to see that you understand your own app.
- **Only make claims you can stand behind.** Avoid medical claims. It's a practice tool.
