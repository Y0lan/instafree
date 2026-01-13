.class public Lcom/feurstagram/FeurConfig;
.super Ljava/lang/Object;

# FeurStagram Configuration
# Hardcoded settings for distraction-free mode
# 
# Disables: Feed content, Explore content, Reels content
# Keeps: Stories, DMs, Profile

.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

# Returns true if feed content should be disabled
.method public static isFeedDisabled()Z
    .locals 1
    const/4 v0, 0x1
    return v0
.end method