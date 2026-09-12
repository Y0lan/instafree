# InstaFree and upstream FeurStagram

InstaFree was forked from [FeurStagram](https://github.com/jean-voila/FeurStagram)
while that project was a shell script driving apktool over smali. Upstream has
since been rewritten around a different architecture, so the two are no longer
mergeable: this document records what changed, what overlaps, and what moving
upstream would actually cost.

## Where the two projects stand

| | InstaFree | Upstream FeurStagram |
|---|---|---|
| Patching | apktool, smali edited in place | [Morphe](https://morphe.software) patcher, Kotlin patches |
| Runtime code | two hand-written smali classes | a compiled Java extension merged into the app |
| Targeting | class, method and string anchors | fingerprints |
| Build inputs | Java, Python, Android build-tools | JDK 21, Android SDK, a GitHub token with `read:packages` |
| Settings | defaults compiled in | in-app settings page, long-press the Home tab |
| License | Unlicense | GPLv3 |

Upstream's last release targets Instagram 444.0.0.46.85.

## What upstream added that InstaFree now also has

Both of these were ported into the smali toolkit rather than pulled in as code:

- **A wider block list.** Ads injected into the feed, stories, profile, DMs and
  Explore; suggested-account recommendations; client logging, "seen" receipts and
  usage stats; shopping and commerce preloads.
- **The deep-link signature bypass.** Instagram checks its own signing
  certificate before following a link into its content, so a re-signed build
  dropped shared links to the home feed. Both projects force that check to pass.
- **A settings page.** InstaFree ships `InstaFreeSettings` plus a launcher
  shortcut. It does not clone FeurStagram's long-press Home-tab entry.

## What upstream has that InstaFree does not

- **Feed-item filtering.** Ads and "suggested" units arrive inline inside the
  `/feed/timeline/` response, so no URL-level rule can catch them; upstream
  rewrites their type token during JSON parsing. InstaFree blocks the timeline
  endpoint outright, so those units never arrive in the first place. This gap
  only matters if the feed is unblocked.
- **Following-feed-only**, a chronological feed limited to accounts you follow.
- **A clone APK** that installs beside the official Instagram.
- **Force SDR**, which stops Instagram forcing its window into HDR and washing
  out the dark UI.
- **An update checker** that prompts on launch when a newer release exists.

## What moving upstream would cost

A move is a fresh fork, not a merge - no shared history or file remains. It
would mean:

- **New build requirements.** The Morphe patcher is fetched from GitHub
  Packages, so every build needs a GitHub token with the `read:packages` scope,
  and the extension is an Android library, so it needs the Android SDK. The
  current toolkit needs neither.
- **A license change.** Upstream is GPLv3; InstaFree is released under the
  Unlicense. Adopting upstream's code means adopting GPLv3.
- **Losing the self-contained patcher.** Today the whole toolkit is a shell
  script, three Python files and two smali classes, all readable in one sitting.

Signing is not affected either way: keep signing with `instafree.keystore` and
existing installs update in place.

## Recommendation

Stay on this toolkit while it keeps applying cleanly - it does everything
InstaFree documents, with no external build dependencies. Revisit if you want
the in-app settings page or the clone APK, which are the two features that are
genuinely hard to reproduce in smali. In that case fork upstream fresh, re-apply
the InstaFree branding and keystore, and retire this repository's patcher rather
than trying to reconcile the two.
