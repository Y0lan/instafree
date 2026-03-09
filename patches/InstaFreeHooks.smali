.class public Lcom/instafree/InstaFreeHooks;
.super Ljava/lang/Object;

# InstaFree Network Hooks
# Intercepts network requests and blocks unwanted content
#
# Blocked endpoints:
#   - /feed/timeline/ (feed posts)
#   - /discover/topical_explore (explore content)
#   - /clips/discover (reels discovery)
#   - /feed/reels_tray/ (stories tray - can still post & view own from profile)
#
# Note: /clips/home/ is NOT blocked because the Reels tab is already
#       redirected at the UI level - users can still view reels shared in DMs


.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method


# Log a message with tag "InstaFree" (visible via: adb logcat -s "InstaFree:D")
.method public static log(Ljava/lang/String;)V
    .locals 1
    const-string v0, "InstaFree"
    invoke-static {v0, p0}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    return-void
.end method


# Log network request URL for debugging
.method public static logRequest(Ljava/net/URI;)V
    .locals 3

    if-eqz p0, :cond_return

    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "REQ: "
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {p0}, Ljava/net/URI;->getPath()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->log(Ljava/lang/String;)V

    :cond_return
    return-void
.end method


# Main hook: Throws IOException if request should be blocked
# Called from TigonServiceLayer before each network request
.method public static throwIfBlocked(Ljava/net/URI;)V
    .locals 4

    # Log the request (comment out for production)
    invoke-static {p0}, Lcom/instafree/InstaFreeHooks;->logRequest(Ljava/net/URI;)V

    # Get the path from URI
    invoke-virtual {p0}, Ljava/net/URI;->getPath()Ljava/lang/String;
    move-result-object v0

    if-eqz v0, :cond_return

    # Block feed timeline (posts) - Stories load separately from /feed/reels_tray/
    const-string v1, "/feed/timeline/"
    invoke-virtual {v0, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-nez v2, :cond_block

    # Block explore content
    const-string v1, "/discover/topical_explore"
    invoke-virtual {v0, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-nez v2, :cond_block

    # Block reels discovery
    const-string v1, "/clips/discover"
    invoke-virtual {v0, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-nez v2, :cond_block

    # Block stories tray (can still post & view own stories from profile)
    const-string v1, "/feed/reels_tray/"
    invoke-virtual {v0, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-nez v2, :cond_block

    # Not blocked, return normally
    :cond_return
    return-void

    # Block by throwing IOException
    :cond_block
    const-string v1, "BLOCKED!"
    invoke-static {v1}, Lcom/instafree/InstaFreeHooks;->log(Ljava/lang/String;)V

    new-instance v3, Ljava/io/IOException;
    const-string v1, "Blocked by InstaFree"
    invoke-direct {v3, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
    throw v3

.end method
