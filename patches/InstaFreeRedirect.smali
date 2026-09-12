.class public Lcom/instafree/InstaFreeRedirect;
.super Ljava/lang/Object;

# InstaFree Fragment Redirect
# Resolves fragment names at runtime based on user preferences
#
# When Instagram loads a fragment like "fragment_clips", this class
# intercepts it and returns the user's configured redirect
# (e.g., "fragment_direct_tab" for DMs).


# Constructor
.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method


# public static String resolveFragment(String original)
# Compares input with known fragment names and returns configured redirect or original
.method public static resolveFragment(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    # Check if original is "fragment_clips"
    const-string v0, "fragment_clips"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :cond_not_clips

    # It's fragment_clips — return reels redirect
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getReelsRedirect()Ljava/lang/String;
    move-result-object v0
    return-object v0

    :cond_not_clips
    # Check if original is "fragment_feed"
    const-string v0, "fragment_feed"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :cond_not_feed

    # It's fragment_feed — return feed redirect
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getFeedRedirect()Ljava/lang/String;
    move-result-object v0
    return-object v0

    :cond_not_feed
    # No match — return original unchanged
    return-object p0
.end method


# public static String getDefaultFragment()
# Delegates to InstaFreeConfig.getDefaultPage()
.method public static getDefaultFragment()Ljava/lang/String;
    .locals 1

    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getDefaultPage()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method
