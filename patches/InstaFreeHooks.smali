.class public Lcom/instafree/InstaFreeHooks;
.super Ljava/lang/Object;

# InstaFree Network Hooks
# Called from TigonServiceLayer before every API request. Requests for blocked
# surfaces raise an IOException, which Instagram treats as an ordinary network
# failure, so the surface stays empty instead of crashing.
#
# Blocked by default, switchable through InstaFreeConfig:
#   - the home feed, the stories tray, and the Reels feed
#
# Always blocked:
#   - Explore
#   - ads injected into the feed, stories, profile, DMs and Explore
#   - suggested-account recommendations
#   - analytics, telemetry and shopping preloads
#
# Reels shared in DMs still play: they are fetched per-media, not through the
# Reels feed endpoints. Posting stories and viewing your own from your profile
# are likewise untouched.


.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method


# Log a message under the "InstaFree" tag (adb logcat -s "InstaFree:D").
.method public static log(Ljava/lang/String;)V
    .locals 1
    const-string v0, "InstaFree"
    invoke-static {v0, p0}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
    return-void
.end method


# Report a blocked request path.
.method private static logBlocked(Ljava/lang/String;)V
    .locals 2

    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "BLOCKED "
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->log(Ljava/lang/String;)V

    return-void
.end method


# Explore tab content
.method private static isExplore(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/discover/topical_explore"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Sponsored units across feed, stories, profile, DMs and Explore
.method private static isAd(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/api/v1/ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/feed/async_ads_ranking/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/feed/contextual_multi_ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/feed/shop_everything_feed_of_ads"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/feed/user_interests_contextual_feed_of_ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/clips/ads_discover_sync_flow/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/chaining_experience_contextual_ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/chaining_experience_notification_ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/direct_v2/ads_for_ctd_ads_thread_view/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/direct_v2/should_show_ad_responses_tab/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/profile_ads/get_profile_ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/stories/stories_high_intent_discovery_ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/stories/stories_intent_aware_ads/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/commerce/product_collections/ads_collection_page/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Suggested-account and "recommended for you" surfaces
.method private static isSuggestedAccounts(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/discover/ayml/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/sectioned_ayml/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/chaining/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/recommended_accounts_for_category/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/suggested_businesses/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/recs_from_friends_suggestions/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/recs_from_friends_user_info/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/surface_with_su/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/fetch_suggestion_details/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/account_discovery/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/discover/reshare_suggestions/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/fbsearch/accounts_recs/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/friendships/feed_favorites_suggestions/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/friendships/share_to_friends_story_suggested_users/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/direct_v2/search_friending_suggestions/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/business/discovery/suggest_business/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Client logging, telemetry and engagement analytics
.method private static isTracking(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/feed/injected_reels_media"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/logging/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/async_ads_privacy/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/async_critical_notices/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/api/v1/fbupload/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/api/v1/stats/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Shopping and commerce preloads
.method private static isCommerce(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/api/v1/commerce/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/api/v1/shopping/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/api/v1/sellable_items/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Home feed posts
.method private static isFeedSurface(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/feed/timeline/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Stories tray
.method private static isStoriesSurface(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/feed/reels_tray"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Reels feed and discovery
.method private static isReelsSurface(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/clips/home/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/clips/discover"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const-string v0, "/clips/get_blend_medias/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-nez v1, :cond_match

    const/4 v0, 0x0
    return v0

    :cond_match
    const/4 v0, 0x1
    return v0
.end method


# Post "seen" receipts (/api/v1/media/<id>/seen/)
.method private static isMediaSeen(Ljava/lang/String;)Z
    .locals 2

    const-string v0, "/api/v1/media/"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-eqz v1, :cond_no

    const-string v0, "/seen"
    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-eqz v1, :cond_no

    const/4 v0, 0x1
    return v0

    :cond_no
    const/4 v0, 0x0
    return v0
.end method


# Main hook: throws IOException when this request should be blocked.
.method public static throwIfBlocked(Ljava/net/URI;)V
    .locals 2

    if-eqz p0, :cond_allow

    invoke-virtual {p0}, Ljava/net/URI;->getPath()Ljava/lang/String;
    move-result-object v0

    if-eqz v0, :cond_allow

    # Home feed posts
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->isFeedDisabled()Z
    move-result v1
    if-eqz v1, :cond_keep_feed
    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isFeedSurface(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block
    :cond_keep_feed

    # Stories tray
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->isStoriesDisabled()Z
    move-result v1
    if-eqz v1, :cond_keep_stories
    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isStoriesSurface(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block
    :cond_keep_stories

    # Reels feed and discovery
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->isReelsDisabled()Z
    move-result v1
    if-eqz v1, :cond_keep_reels
    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isReelsSurface(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block
    :cond_keep_reels

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isExplore(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isAd(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isSuggestedAccounts(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isTracking(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isCommerce(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block

    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->isMediaSeen(Ljava/lang/String;)Z
    move-result v1
    if-nez v1, :cond_block

    :cond_allow
    return-void

    :cond_block
    invoke-static {v0}, Lcom/instafree/InstaFreeHooks;->logBlocked(Ljava/lang/String;)V

    new-instance v1, Ljava/io/IOException;
    const-string v0, "Blocked by InstaFree"
    invoke-direct {v1, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V
    throw v1
.end method
