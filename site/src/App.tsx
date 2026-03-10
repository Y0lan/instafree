import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Marquee, MarqueeContent, MarqueeItem, MarqueeFade } from "@/components/kibo-ui/marquee";
import Lightning from "@/components/reactbits/Lightning";
import ASCIIText from "@/components/reactbits/ASCIIText";
import BlurText from "@/components/reactbits/BlurText";
import Squares from "@/components/reactbits/Squares";
import GlowCard from "@/components/GlowCard";
import {
  Download,
  Github,
  ShieldOff,
  MessageCircle,
  User,
  Search,
  Bell,
  Play,
  Rss,
  Compass,
  Film,
  Eye,
} from "lucide-react";

interface ReleaseInfo {
  tag: string;
  date: string;
  url: string;
}

function useRelease() {
  const [release, setRelease] = useState<ReleaseInfo | null>(null);
  useEffect(() => {
    fetch("https://api.github.com/repos/Y0lan/instafree/releases/latest")
      .then((r) => r.json())
      .then((data) => {
        const apk = data.assets?.find((a: { name: string }) =>
          a.name.endsWith(".apk")
        );
        setRelease({
          tag: data.tag_name,
          date: new Date(data.published_at).toLocaleDateString("en-US", {
            month: "short",
            day: "numeric",
            year: "numeric",
          }),
          url:
            apk?.browser_download_url ||
            "https://github.com/Y0lan/instafree/releases/latest",
        });
      })
      .catch(() => {});
  }, []);
  return release;
}

const blocked = [
  {
    icon: Rss,
    title: "Feed Posts",
    desc: "The endless homepage feed is gone. No more doomscrolling through posts you didn't ask for.",
  },
  {
    icon: Compass,
    title: "Explore Tab",
    desc: "Explore content is blocked at the network level. The algorithm can't reach you.",
  },
  {
    icon: Film,
    title: "Reels Tab",
    desc: "Tapping Reels redirects straight to your DMs. No infinite video loops.",
  },
  {
    icon: Eye,
    title: "Stories Tray",
    desc: "The stories tray on the homepage is removed. Access stories from DMs or profiles instead.",
  },
];

const working = [
  {
    icon: MessageCircle,
    title: "Direct Messages",
    desc: "Full messaging with shared reels and posts",
  },
  {
    icon: User,
    title: "Profile",
    desc: "View your own stories, posts, and profile page",
  },
  {
    icon: Search,
    title: "Search",
    desc: "Find and follow users normally",
  },
  {
    icon: Bell,
    title: "Notifications",
    desc: "Stay updated on what matters",
  },
  {
    icon: Play,
    title: "Reels in DMs",
    desc: "Reels shared via DMs still play fine",
  },
  {
    icon: ShieldOff,
    title: "Post Stories",
    desc: "Create and post stories as usual",
  },
];

const marqueeItems = [
  "No feed",
  "No explore",
  "No reels",
  "No doomscrolling",
  "Keep DMs",
  "No stories tray",
  "Keep profile",
  "Open source",
  "Free forever",
  "Your phone, your rules",
];

export default function App() {
  const release = useRelease();

  return (
    <div className="min-h-screen bg-background text-foreground overflow-x-hidden">
      {/* Hero Section */}
      <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden">
        {/* Lightning background */}
        <div className="absolute inset-0 opacity-40">
          <Lightning hue={155} xOffset={0} speed={0.6} intensity={1.2} size={1} />
        </div>

        {/* Radial fade overlay */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_30%,var(--background)_75%)]" />
        <div className="absolute bottom-0 left-0 right-0 h-48 bg-gradient-to-t from-background to-transparent" />

        {/* Content */}
        <div className="relative z-10 flex flex-col items-center text-center px-6 gap-8 max-w-4xl">
          <img
            src="app_icon.png"
            alt="InstaFree"
            className="w-24 h-24 rounded-2xl shadow-2xl shadow-emerald-500/20 border border-white/10"
          />

          {/* ASCII Title */}
          <div className="w-full h-36 sm:h-48 relative">
            <ASCIIText
              text="InstaFree"
              asciiFontSize={5}
              textFontSize={120}
              textColor="#10a37f"
              planeBaseHeight={5}
              enableWaves={true}
            />
          </div>

          <p className="text-lg sm:text-xl text-muted-foreground max-w-lg leading-relaxed -mt-2">
            Instagram without the addiction.
            <br />
            <span className="text-foreground/80">
              Keep messaging. Hide stories. Kill the feed.
            </span>
          </p>

          <div className="flex flex-wrap gap-4 justify-center">
            <a href={release?.url || "https://github.com/Y0lan/instafree/releases/latest"}>
              <Button size="lg" className="gap-2 text-base px-8 py-6 cursor-pointer bg-primary hover:bg-primary/90 text-primary-foreground font-semibold shadow-lg shadow-primary/25 transition-all hover:shadow-xl hover:shadow-primary/30 hover:-translate-y-0.5">
                <Download className="w-5 h-5" />
                <div className="flex flex-col items-start leading-tight">
                  <span>Download APK</span>
                  {release && (
                    <span className="text-xs opacity-70 font-normal">
                      {release.tag} &middot; {release.date}
                    </span>
                  )}
                </div>
              </Button>
            </a>
            <a
              href="https://github.com/Y0lan/instafree"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Button
                variant="outline"
                size="lg"
                className="gap-2 text-base px-8 py-6 cursor-pointer border-border/50 hover:border-border hover:bg-secondary/50 transition-all hover:-translate-y-0.5"
              >
                <Github className="w-5 h-5" />
                Source Code
              </Button>
            </a>
          </div>

          <p className="text-sm text-muted-foreground">
            Based on{" "}
            <a
              href="https://github.com/jean-voila/FeurStagram"
              target="_blank"
              rel="noopener noreferrer"
              className="text-primary/80 hover:text-primary underline underline-offset-4 transition-colors"
            >
              FeurStagram
            </a>{" "}
            by{" "}
            <a
              href="https://github.com/jean-voila"
              target="_blank"
              rel="noopener noreferrer"
              className="text-primary/80 hover:text-primary underline underline-offset-4 transition-colors"
            >
              jean-voila
            </a>
          </p>
        </div>
      </section>

      {/* Marquee divider */}
      <div className="relative border-y border-border/30 bg-secondary/20 backdrop-blur-sm">
        <Marquee className="py-4">
          <MarqueeFade side="left" />
          <MarqueeContent pauseOnHover speed={30}>
            {marqueeItems.map((item) => (
              <MarqueeItem key={item}>
                <span className="mx-6 text-sm font-medium tracking-widest uppercase text-muted-foreground/60">
                  {item}
                </span>
              </MarqueeItem>
            ))}
          </MarqueeContent>
          <MarqueeFade side="right" />
        </Marquee>
      </div>

      {/* Blocked + Working — unified section */}
      <div className="relative overflow-hidden">
        {/* Single Squares background spanning both sections */}
        <div className="absolute inset-0">
          <Squares
            direction="diagonal"
            speed={0.25}
            borderColor="rgba(255,255,255,0.04)"
            squareSize={44}
            hoverFillColor="rgba(255,255,255,0.03)"
          />
        </div>

        {/* What's blocked */}
        <section className="pt-24 pb-16 px-6 relative z-10">
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16 space-y-4">
              <Badge
                variant="destructive"
                className="text-xs tracking-wider uppercase px-4 py-1"
              >
                Blocked
              </Badge>
              <BlurText
                text="What gets removed"
                className="text-3xl sm:text-4xl font-bold tracking-tight"
                delay={80}
                direction="bottom"
              />
              <p className="text-muted-foreground text-lg max-w-md mx-auto">
                The features designed to keep you scrolling
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {blocked.map((item) => (
                <GlowCard
                  key={item.title}
                  glowColor="rgba(239, 68, 68, 0.4)"
                  className="rounded-lg"
                >
                  <div className="bg-card/40 backdrop-blur-sm border border-white/[0.04] rounded-lg p-5 h-full group hover:-translate-y-0.5 transition-transform duration-200">
                    <div className="flex items-center gap-3 mb-3">
                      <item.icon className="w-4 h-4 text-destructive shrink-0" />
                      <h3 className="font-medium">{item.title}</h3>
                    </div>
                    <p className="text-sm text-muted-foreground leading-relaxed pl-7">
                      {item.desc}
                    </p>
                  </div>
                </GlowCard>
              ))}
            </div>
          </div>
        </section>

        <div className="max-w-6xl mx-auto px-6 relative z-10">
          <Separator className="opacity-20" />
        </div>

        {/* What still works */}
        <section className="pt-16 pb-24 px-6 relative z-10">
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16 space-y-4">
              <Badge className="text-xs tracking-wider uppercase px-4 py-1 bg-primary/15 text-primary border-primary/20 hover:bg-primary/20">
                Working
              </Badge>
              <BlurText
                text="What still works"
                className="text-3xl sm:text-4xl font-bold tracking-tight"
                delay={80}
                direction="bottom"
              />
              <p className="text-muted-foreground text-lg max-w-md mx-auto">
                Everything you actually need
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {working.map((item) => (
                <GlowCard
                  key={item.title}
                  glowColor="rgba(16, 163, 127, 0.4)"
                  className="rounded-lg"
                >
                  <div className="bg-card/40 backdrop-blur-sm border border-white/[0.04] rounded-lg p-5 h-full group hover:-translate-y-0.5 transition-transform duration-200">
                    <div className="flex items-center gap-3 mb-2">
                      <item.icon className="w-4 h-4 text-primary shrink-0" />
                      <h3 className="font-medium">{item.title}</h3>
                    </div>
                    <p className="text-sm text-muted-foreground pl-7">{item.desc}</p>
                  </div>
                </GlowCard>
              ))}
            </div>
          </div>
        </section>
      </div>

      {/* How it works */}
      <section className="py-24 px-6 bg-secondary/20 border-y border-border/20">
        <div className="max-w-3xl mx-auto space-y-12">
          <div className="text-center space-y-4">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
              How it works
            </h2>
            <p className="text-muted-foreground text-lg">
              Two surgical patches. Nothing else changes.
            </p>
          </div>

          <div className="grid gap-8">
            <div className="flex gap-6">
              <div className="flex-shrink-0 w-10 h-10 rounded-full bg-primary/15 flex items-center justify-center text-primary font-bold text-sm border border-primary/20">
                1
              </div>
              <div className="space-y-2 pt-1">
                <h3 className="font-semibold text-lg">Network Blocking</h3>
                <p className="text-muted-foreground leading-relaxed">
                  Hooks into{" "}
                  <code className="text-xs bg-muted px-1.5 py-0.5 rounded font-mono">
                    TigonServiceLayer
                  </code>{" "}
                  (Instagram's named, non-obfuscated network class) and blocks
                  requests to{" "}
                  <code className="text-xs bg-muted px-1.5 py-0.5 rounded font-mono">
                    /feed/timeline/
                  </code>
                  ,{" "}
                  <code className="text-xs bg-muted px-1.5 py-0.5 rounded font-mono">
                    /discover/topical_explore
                  </code>
                  , and other addictive endpoints.
                </p>
              </div>
            </div>

            <div className="flex gap-6">
              <div className="flex-shrink-0 w-10 h-10 rounded-full bg-primary/15 flex items-center justify-center text-primary font-bold text-sm border border-primary/20">
                2
              </div>
              <div className="space-y-2 pt-1">
                <h3 className="font-semibold text-lg">Tab Redirect</h3>
                <p className="text-muted-foreground leading-relaxed">
                  Intercepts fragment loading. When Instagram tries to load{" "}
                  <code className="text-xs bg-muted px-1.5 py-0.5 rounded font-mono">
                    fragment_clips
                  </code>{" "}
                  (Reels), it redirects to{" "}
                  <code className="text-xs bg-muted px-1.5 py-0.5 rounded font-mono">
                    fragment_direct_tab
                  </code>{" "}
                  (DMs).
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-32 px-6 relative overflow-hidden">
        <div className="absolute inset-0 opacity-20">
          <Lightning hue={155} xOffset={0} speed={0.3} intensity={0.8} size={1.5} />
        </div>
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_20%,var(--background)_70%)]" />

        <div className="relative z-10 max-w-2xl mx-auto text-center space-y-8">
          <h2 className="text-4xl sm:text-5xl font-bold tracking-tight">
            Take back your
            <br />
            <span className="text-primary">attention</span>
          </h2>
          <p className="text-muted-foreground text-lg">
            Free. Open source. No tracking. No accounts. Just an APK.
          </p>
          <a href={release?.url || "https://github.com/Y0lan/instafree/releases/latest"}>
            <Button
              size="lg"
              className="gap-2 text-lg px-10 py-7 cursor-pointer bg-primary hover:bg-primary/90 text-primary-foreground font-semibold shadow-lg shadow-primary/25 transition-all hover:shadow-xl hover:shadow-primary/30 hover:-translate-y-0.5"
            >
              <Download className="w-6 h-6" />
              Download InstaFree
            </Button>
          </a>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border/20 py-8 px-6">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-muted-foreground">
          <p>
            Free and open-source. Based on{" "}
            <a
              href="https://github.com/jean-voila/FeurStagram"
              className="text-primary/70 hover:text-primary transition-colors"
              target="_blank"
              rel="noopener noreferrer"
            >
              FeurStagram
            </a>
          </p>
          <a
            href="https://github.com/Y0lan/instafree"
            className="text-primary/70 hover:text-primary transition-colors flex items-center gap-1.5"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Github className="w-4 h-4" />
            Y0lan/instafree
          </a>
        </div>
      </footer>
    </div>
  );
}
