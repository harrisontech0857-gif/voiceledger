# 寵物生圖 Prompt 清單 — 逐張生成

> 每張圖都附上風格前綴 + 個別描述，直接複製貼給 Gemini ImageFX。
> 生成後另存為對應檔名，放入 `app/assets/images/pet/` 目錄。

---

## 風格前綴（每張都要加在最前面）

```
Flat kawaii 2D game character illustration, chibi proportions, soft rounded shapes,
clean outlines, warm color palette (orange #E07C4F, gold #FFD700, white, red accents),
transparent background, no shadow, centered in frame with 10% padding,
512x512 pixels, PNG format.
```

---

## 1. egg.png — 神秘蛋

```
A golden egg with subtle cat paw print patterns on the surface.
A glowing crack on the upper portion emitting warm orange-gold light.
The egg is slightly tilted, looking alive and about to hatch.
Soft golden sparkles around the crack.
```

---

## 2. baby_happy.png — 幼貓 開心

```
A tiny adorable orange and white kitten just hatched, wearing half a golden
eggshell as a hat. Oversized round eyes with star-shaped sparkles in them.
Big happy W-shaped mouth. Tiny pink hearts floating above its head.
Very small body with big head (chibi proportions). Short stubby tail wagging.
```

## 3. baby_neutral.png — 幼貓 日常

```
A tiny adorable orange and white kitten wearing half a golden eggshell as a hat.
Normal round eyes looking forward with curiosity. Small gentle smile.
Sitting calmly with paws together. Short stubby tail resting.
Big head, small body, chibi proportions.
```

## 4. baby_hungry.png — 幼貓 餓了

```
A tiny orange and white kitten wearing half a golden eggshell as a hat.
Big watery teary eyes looking up pleadingly. Mouth slightly open showing
a tiny tongue. A speech bubble with "..." above its head.
Droopy ears. Looks sad and hungry. Chibi proportions.
```

## 5. baby_sleepy.png — 幼貓 想睡

```
A tiny orange and white kitten wearing half a golden eggshell as a hat.
Eyes half-closed, almost shut. Mouth open in a tiny yawn.
"Zzz" text floating above its head. Slightly slumped posture.
Chibi proportions, looks very drowsy and cute.
```

---

## 6. teen_happy.png — 少年貓 開心

```
A young orange tabby cat with a gold bell on a red collar.
One paw raised like a maneki-neko. Eyes sparkling with star shapes.
Big cheerful grin. Golden tail tip glowing. Small hearts and sparkles
floating around. Confident and energetic pose. Chibi proportions.
```

## 7. teen_neutral.png — 少年貓 日常

```
A young orange tabby cat with a gold bell on a red collar.
Normal round eyes with a friendly expression. Small smile.
One paw slightly raised in a casual wave. Golden tail tip.
Relaxed sitting pose. Chibi proportions.
```

## 8. teen_hungry.png — 少年貓 餓了

```
A young orange tabby cat with a gold bell on a red collar.
Frowning with furrowed brows. Eyes looking annoyed and hungry.
A speech bubble with "..." above its head. Tail drooping.
Arms crossed or paws on belly. Chibi proportions, grumpy cute expression.
```

## 9. teen_sleepy.png — 少年貓 想睡

```
A young orange tabby cat with a gold bell on a red collar.
Eyes almost completely closed, nodding off. "Zzz" floating above.
Mouth in a sleepy pout. Tail curled around body. Slightly hunched over.
Chibi proportions, peacefully drowsy.
```

---

## 10. adult_happy.png — 招財貓 開心

```
A cute chibi maneki-neko (lucky cat) in orange and white.
Right paw raised high beckoning. Left paw holding a gold coin with "NT$" symbol.
Wearing a red bib with Chinese character "語" embroidered on it.
Gold bell on collar. Eyes squeezed shut in a big happy smile.
Small hearts and golden sparkles around. Radiating joy.
```

## 11. adult_neutral.png — 招財貓 日常

```
A cute chibi maneki-neko (lucky cat) in orange and white.
Right paw raised beckoning. Left paw holding a gold coin with "NT$" symbol.
Wearing a red bib with Chinese character "語". Gold bell on collar.
Normal round friendly eyes. Gentle warm smile. Standard pose.
```

## 12. adult_hungry.png — 招財貓 餓了

```
A cute chibi maneki-neko (lucky cat) in orange and white.
Both paws down, no longer beckoning. Wearing a red bib with "語".
Watery big eyes looking sad. A teardrop on cheek. Speech bubble with "...".
Gold coin on the ground beside it. Looks abandoned and hungry.
```

## 13. adult_sleepy.png — 招財貓 想睡

```
A cute chibi maneki-neko (lucky cat) in orange and white.
Wearing a red bib with "語". Eyes completely closed.
Head tilted to one side, dozing off. "Zzz" floating above.
Gold coin loosely held, about to drop. Peaceful sleeping expression.
```

---

## 14. master_happy.png — 金財神貓 開心

```
A majestic chibi golden lucky cat wearing a tiny jeweled crown
and a flowing red-gold cape. Entire body glowing with golden aura.
Eyes with star sparkles, wide beaming smile. Floating gold coins
and golden sparkles all around. Radiating power and prosperity.
The most impressive and regal version of the lucky cat.
```

## 15. master_neutral.png — 金財神貓 日常

```
A majestic chibi golden lucky cat wearing a tiny crown and red-gold cape.
Golden aura glowing softly. Normal confident eyes with a serene smile.
A few floating gold coins around. Dignified and calm pose.
Royal but approachable expression.
```

## 16. master_hungry.png — 金財神貓 餓了

```
A majestic chibi golden lucky cat wearing a crown and red-gold cape.
Golden aura dimmed and flickering. Sad teary eyes, pouty mouth.
Crown slightly tilted. Speech bubble with "...".
Gold coins on the ground instead of floating. Looks neglected despite royalty.
```

## 17. master_sleepy.png — 金財神貓 想睡

```
A majestic chibi golden lucky cat wearing a crown and red-gold cape.
Eyes closed, head nodding forward. Crown slipping. "Zzz" above head.
Golden aura very faint and dim. Cape draped over body like a blanket.
Gold coins scattered on the ground. Peaceful royal slumber.
```

---

## 生成後放置路徑

```
app/assets/images/pet/
├── egg.png
├── baby_happy.png
├── baby_neutral.png
├── baby_hungry.png
├── baby_sleepy.png
├── teen_happy.png
├── teen_neutral.png
├── teen_hungry.png
├── teen_sleepy.png
├── adult_happy.png
├── adult_neutral.png
├── adult_hungry.png
├── adult_sleepy.png
├── master_happy.png
├── master_neutral.png
├── master_hungry.png
└── master_sleepy.png
```

全部放好後告訴我，我會更新程式碼從 emoji 切換為圖片顯示。
