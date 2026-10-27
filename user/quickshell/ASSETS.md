# Assets

`ui/assets/wallpaper.png` was generated with the built-in `image_gen` tool for
this rice, then copied into the repository. It is a 1672 × 941 PNG. The tool
selected that resolution despite the higher-resolution request in the prompt.

Final prompt:

> Use case: stylized-concept. Asset type: a finished wide 16:9 desktop wallpaper,
> landscape, ideally 3840x2160. Primary request: a dark purple Frutiger Aero /
> Windows Vista 2007 nostalgic wallpaper. Deep plum and amethyst night background,
> lustrous translucent violet soap bubbles and polished glass ribbon flowing
> diagonally along the right half, one subtle lilac five-petal glass flower near
> the bottom right, tiny restrained pinpoint glints, soft underwater caustic light
> with a deep inky violet gradient. Materials: convincing glossy blown glass,
> dark liquid purple, pearlescent silver reflections and a faint cool mint
> reflection. Composition: generous dark negative space on the left half for
> open application windows and a narrow vertical dock on the left edge; objects
> live mostly at the right and lower right. Look like a high quality 2007 Aero
> wallpaper rendered today, elegant and moody, tactile and organic, rich deep
> purple instead of pink, keep average luminance dark. Not a modern flat vector
> illustration or neon cyberpunk. No interface, no icons, no text, no logos,
> no watermark. Full bleed finished wallpaper.

Icons and the user tile use the packaged Oxygen artwork. Kvantum's original
KvDark theme is supplied by the Kvantum package; `user/gtk/kvantum.py` recolors
that dependency at build time. Their upstream licenses remain with the packages.

## ChomikBox mascot

`ui/assets/chomikbox/` contains original Chomikuj.pl artwork from ChomikBox
2.0.8.2 (2017), extracted from `ChomikBox.msi` and supplied by the user in
`chomikbox-assets/`. The images belong to Chomikuj.pl; they are used here for
the user's desktop pet. This does not relicense them under the dotfiles license.

The PNG and animated WebP files were copied without modifying their pixels,
alpha channels or frame timing. `sources.json` records each file's path in the
supplied extraction, frame count and original frame duration (50 ms).
`ChomikSprite.qml` maps movement, drag and drop clips to desktop interactions
and schedules the remaining clips as idle behaviour. Every few seconds a
weighted random draw picks a frequent fidget (blink, look, nose, yawn, yawn2,
sway, peek or cross-eyed staring) or, less often, a bigger activity: digging
a burrow, launching a paper plane, reading the newspaper, reading the book or
napping on the pillow. The last three chain their original
`AnimIdleStart1/2/3` start → loop → finish clips. Looping clips play for the
display duration chosen in `ChomikSprite.qml`; `sources.json` keeps the
intrinsic frame timing. Every clip retains the original 256 × 256 canvas and a
common foot position; QML scales the character for the small desktop widget.
The header uses a view of the same original idle PNG.
The `music` and `screenshot` clips are `AnimMusicStart` and
`AnimScreenShotFinish`; MPRIS playback and successful `aero-screenshot` captures
trigger them. Captured screenshots are also added to the file stash.
