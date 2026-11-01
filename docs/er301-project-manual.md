# ER-301 Custom Firmware — User Manual

This manual covers the features this project adds to the ER-301 firmware. It is based on the official firmware **v0.6.16**. Everything not described here works exactly as in the official firmware.

| | |
|---|---|
| Firmware | `er-301-v0.6.16-us15j.zip` (shown as version **0.6.16**, status **us15j** under Admin > Current Firmware) |
| Covers | Hold-to-edit on the sub buttons, gain default, automatic input assignment ("auto"), built-in Teletype/i2c inputs incl. MIDI via i2c, true levels in the source overview |
| Not covered | The official ER-301 manual, which remains valid for everything else |

---

## 1. Installing and reverting

1. Copy the firmware zip file to the **front** SD card (any folder).
2. Insert the card, power on, switch STORAGE to **admin**, select **Install Firmware** and pick the zip file.
3. Wait for *"Update succeeded. Reboot to use new firmware."*, then power-cycle the unit.
4. Check **Admin > Current Firmware**: it should read version 0.6.16 with status `us15j`.

To go back, install the official `er-301-v0.6.16-stable.zip` the same way. Keep a copy on the card.

> **Always power-cycle after installing.** A plain re-insert of a unit can keep using cached code.

---

## 2. Editing a value by holding a sub button

The sub buttons **S1–S3** below the sub display now have two behaviours:

| Action | Result |
|---|---|
| **Short press** | Exactly as before: the value is focused, the encoder changes it, and **UP** (or pressing the main button again) leaves the focus. |
| **Press and hold** | The value is focused only while you hold the button. Turn the encoder to change it. **On release the new value stays active and the focus is released**, so the encoder immediately moves between parameters again. No need to press UP. |

### When does a press count as "held"?

A press counts as held when either:

- you hold the button longer than the **hold time**, or
- you turn the encoder while the button is down (this counts immediately).

The **hold time** is the setting **Admin > Settings > General > "Long press time for floating menu"** plus **0.15 s**. With the setting at 0.2 s you hold for 0.35 s, at 0.3 s for 0.45 s, and at 0.5 s for 0.65 s. The extra margin keeps quick taps from being mistaken for holds. The floating menu on the main buttons M1–M6 still uses the setting itself.

### Where it works

| Control | Sub buttons | Notes |
|---|---|---|
| **Gain/Bias** controls (most CV-modulatable parameters) | **S2** = gain, **S3** = bias | A second short press on the already focused value opens the number keyboard, as before. |
| **V/Oct** (pitch) | **S2** and **S3** = tune | S3 used to have no function and now behaves like S2. A short press now focuses tune (before, it did nothing unless already focused). |
| **Clock** | **S2** = multiplier, **S3** = divider | |
| **Gate** | **S2** = threshold | **S3** stays the manual trigger. |
| **Input gate** | **S2** = threshold | **S3** stays the manual trigger. |
| **Faders** (parameters without a CV input, e.g. *fade* in the Variable Speed Player) | **S1, S2, S3** = value | These had no sub buttons before. A second short press opens a number keyboard. The sub display still shows the scope; the buttons are not labelled. |

**Unchanged:** SHIFT + sub button, **CANCEL** (restores the value from when the focus started), the S1 branch button on short press, and the floating menu on M1–M6.

---

## 3. Gain starts at 1

The **gain** of a Gain/Bias control now starts at **1.0** instead of 0. A modulation source you choose for a parameter therefore takes effect right away. Without a source the gain has no audible effect.

Presets keep the gain they were saved with, including 0.

---

## 4. Choosing a modulation input

### 4.1 Opening the branch

A short press on **S1** of a modulatable control opens its modulation branch as before. The cursor now lands **directly on the chain input field** (sub display: *Set Chain Input*), so you can pick the input right away.

### 4.2 Set Chain Input

With the cursor on the chain input field, the sub display shows:

| Button | Function |
|---|---|
| Main button below the field | Opens the source chooser (as before). |
| **S2 — auto** | Listens for an active source and assigns it (see 4.4). Press S2 again to cancel. |
| **S3 — clear** | Removes the input (as before). |

**Automatic return:** as soon as an input has been chosen inside a modulation branch, either manually in the chooser or by *auto*, the branch closes and you are back at the unit. No need to press UP.

### 4.3 Assigning without opening the branch: hold S1

On any control with a modulation branch (Gain/Bias, V/Oct, Gate, Clock, mixer channel, state machine), **press and hold S1**:

1. After the hold time, the display shows *"Listening for a source..."*.
2. While still holding, move the source you want: turn a fader, send a gate, change a voltage.
3. The first active source becomes the branch input. The display confirms it, e.g. *"Input: TCV3"*. The branch does **not** open.
4. Release S1. If nothing was detected, nothing changes.

A short press on S1 still opens the branch.

### 4.4 How "auto" decides

- When listening starts, *auto* waits about 0.3 s and takes a **baseline** of every source.
- After that, the **first source that changes** against its baseline wins. That means a change in level of more than about 2 % of full scale, or a clearly larger signal swing. Short pulses, such as Teletype triggers, are caught as well.
- A signal that is **already present and unchanged** when listening starts does not trigger. This covers a constant voltage or a clock or audio signal that keeps running the same way. To assign it, start listening first, then start or change the signal.
- *Auto* listens to **IN1–IN4, G1–G4, A1–A3 … D1–D3** and to all **Teletype/i2c inputs** that are currently shown (see 5). It does not listen to OUT1–OUT4.
- Listening stops when you press S2 again, move the cursor away, or release S1.

---

## 5. Built-in Teletype / i2c inputs

i2c reception (Teletype, 16n-style fader banks such as the **Sweet Sixteen**, [github.com/ralbring/Sweet-Sixteen](https://github.com/ralbring/Sweet-Sixteen)) is now part of the firmware. Received values appear as **ordinary inputs** in the source chooser, in new groups after **Gx**, with the same scopes as the jacks. You choose them like IN1, and *auto* detects them.

All i2c values are **positive only** (0 to full scale). Their scopes show the zero line at the bottom, as for the gate inputs.

### 5.1 Input groups

| Group | Inputs | i2c port | Source of the data |
|---|---|---|---|
| **TT CV** | TCV1 … TCV16 | CV 1–16 | Teletype `SC.CV n …` / Sweet Sixteen faders 1–16 |
| **TT TR** | TTR1 … TTR8 | TR 1–8 | Teletype `SC.TR n …`, `SC.TR.P n` / Sweet Sixteen GESS gates 1–8 |
| **MIDI P** | MP1 … MP8 | CV 21–28 | MIDI pitch, channels 1–8 (1 V/oct, MIDI note 21 = 0 V) |
| **MIDI V** | MV1 … MV8 | CV 31–38 | MIDI velocity, channels 1–8 |
| **MIDI G** | MG1 … MG8 | TR 21–28 | MIDI gate (on while the note is held), channels 1–8 |
| **MIDI CC** | CC1/33 … CC8/33, CC1/34 … CC8/34 | CV 41–48, 51–58 | MIDI CC 33 and CC 34, channels 1–8 (`CC3/34` = CC 34 on channel 3) |
| **DRUM T** | DT-C3 … DT-D#4 | TR 61–76 | MIDI channel 10 (drums): one trigger per note, C3 (note 36) to D#4 (note 51) |
| **DRUM V** | DV-C3 … DV-D#4 | CV 61–76 | MIDI channel 10: velocity of each drum note |

Notes:

- The **number in a name is the port number** for TT CV/TR (Teletype `SC.CV 3 …` arrives on **TCV3**), and the **MIDI channel** for the MIDI groups.
- Each MIDI channel is **monophonic**: one pitch and one gate per channel (last note wins). Use several channels for several voices.
- On channel 10 the **note number selects the drum** (General MIDI: C3/36 = bass drum, D3/38 = snare, …). Channel 9, channels 11–16 and drum notes outside C3–D#4 are not available.
- The MIDI groups follow the MIDI-to-i2c conversion of the **Sweet Sixteen** firmware *Sweet_3* (function `doMidiRead()`), see [github.com/ralbring/Sweet-Sixteen](https://github.com/ralbring/Sweet-Sixteen) (`firmware/Sweet_3/Sweet_3.ino`). This MIDI-to-i2c mapping is **not** part of the standard 16n faderbank firmware; other 16n-based devices will not send these ports unless they implement the same mapping. Another device works the same way only if it sends the same i2c commands to the same ports.
- The prefixes (TCV, DT-, …) are needed because names like *C1* or *A1* already belong to the ER-301's own jacks.

### 5.2 Source overview

In the chooser, each collapsed group shows one small bar per input. Large groups are drawn as rows of up to 8 bars. Press the main button below a group to expand it.

The bars now show the **actual level** of each input, so a resting fader or a constant voltage stays visible. Before, they behaved like an AC-coupled loudness meter and dropped to zero when the value stopped changing. This applies to all groups, including the jacks.

### 5.3 Settings

**Admin > Settings > Teletype:**

| Setting | Default | Effect |
|---|---|---|
| **Teletype i2c enabled?** | yes | Turns i2c reception on or off. With *no*, all i2c groups (TT, MIDI, DRUM) disappear from the chooser and from *auto*. |
| **Teletype i2c address:** | 0x31 | The i2c address the ER-301 answers to (0x31–0x33). Teletype and the Sweet Sixteen address the ER-301 at 0x31. |
| **MIDI via i2c?** | yes | With *no*, the MIDI and DRUM groups disappear; TT CV and TT TR stay. |

Hiding a group does not break presets: inputs that are already assigned keep working. A chooser that is already open shows the change only after you reopen it. On *testing* firmware builds with developer mode enabled, i2c stays off because the serial console uses the same pins.

### 5.4 The former Teletype package

The separate **Teletype package** and its units **SC.CV (i2c)** and **SC.TR (i2c)** are gone. If the old package is still installed on the card, it is ignored at startup (log: *"superseded by built-in teletype i2c"*), so it cannot interfere.

- **Presets that contain SC.CV/SC.TR units no longer load those units.** Re-create them by choosing the matching TT input (e.g. `SC.CV` port 5 → **TCV5**) as the chain input.
- **Circuit Drums** (project mod) needs the old package and does not load with this firmware yet.

---

## 6. Known limitations

- *Auto* cannot detect a signal that is already running unchanged when listening starts (see 4.4).
- The *auto* thresholds were chosen for typical CV, gate and fader use and have not been tuned for very small or noisy signals.
- Fader controls have no labels on their sub buttons, because the scope uses the whole sub display.
- In the source chooser, a collapsed group opens with the main button below it. ENTER does not open it.
