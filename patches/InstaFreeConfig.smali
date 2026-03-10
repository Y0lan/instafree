.class public Lcom/instafree/InstaFreeConfig;
.super Ljava/lang/Object;

# InstaFree Configuration
# Dynamic settings via SharedPreferences for distraction-free mode
#
# Disables: Feed content, Explore content, Reels content, Stories tray
# Keeps: DMs, Profile, posting stories, viewing own stories from profile

# Static fields
.field private static appContext:Landroid/content/Context;
.field private static final PREFS_NAME:Ljava/lang/String; = "instafree_prefs"


# Constructor
.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method


# public static void init(Context ctx)
# Stores the application context for later use
.method public static init(Landroid/content/Context;)V
    .locals 1

    # Get application context from the provided context
    invoke-virtual {p0}, Landroid/content/Context;->getApplicationContext()Landroid/content/Context;
    move-result-object v0

    # Store in static field
    sput-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;

    return-void
.end method


# private static SharedPreferences getPrefs()
.method private static getPrefs()Landroid/content/SharedPreferences;
    .locals 3

    # Get stored context
    sget-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;

    # Get SharedPreferences with our prefs name and MODE_PRIVATE (0)
    const-string v1, "instafree_prefs"
    const/4 v2, 0x0
    invoke-virtual {v0, v1, v2}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0

    return-object v0
.end method


# public static boolean isFeedDisabled()
# Returns true if feed content should be disabled
.method public static isFeedDisabled()Z
    .locals 3

    # Check if appContext is null
    sget-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;
    if-nez v0, :cond_not_null

    # appContext is null, return true (default)
    const/4 v0, 0x1
    return v0

    :cond_not_null
    # Get SharedPreferences
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getPrefs()Landroid/content/SharedPreferences;
    move-result-object v0

    # getBoolean("feed_disabled", true)
    const-string v1, "feed_disabled"
    const/4 v2, 0x1
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z
    move-result v0

    return v0
.end method


# public static boolean isStoriesDisabled()
# Returns true if stories tray should be disabled
.method public static isStoriesDisabled()Z
    .locals 3

    # Check if appContext is null
    sget-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;
    if-nez v0, :cond_not_null

    # appContext is null, return true (default)
    const/4 v0, 0x1
    return v0

    :cond_not_null
    # Get SharedPreferences
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getPrefs()Landroid/content/SharedPreferences;
    move-result-object v0

    # getBoolean("stories_disabled", true)
    const-string v1, "stories_disabled"
    const/4 v2, 0x1
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z
    move-result v0

    return v0
.end method


# public static boolean isReelsDisabled()
# Returns true if reels content should be disabled
.method public static isReelsDisabled()Z
    .locals 3

    # Check if appContext is null
    sget-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;
    if-nez v0, :cond_not_null

    # appContext is null, return true (default)
    const/4 v0, 0x1
    return v0

    :cond_not_null
    # Get SharedPreferences
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getPrefs()Landroid/content/SharedPreferences;
    move-result-object v0

    # getBoolean("reels_disabled", true)
    const-string v1, "reels_disabled"
    const/4 v2, 0x1
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z
    move-result v0

    return v0
.end method


# public static String getDefaultPage()
# Returns the default page/fragment to show
.method public static getDefaultPage()Ljava/lang/String;
    .locals 3

    # Check if appContext is null
    sget-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;
    if-nez v0, :cond_not_null

    # appContext is null, return default
    const-string v0, "fragment_profile"
    return-object v0

    :cond_not_null
    # Get SharedPreferences
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getPrefs()Landroid/content/SharedPreferences;
    move-result-object v0

    # getString("default_page", "fragment_profile")
    const-string v1, "default_page"
    const-string v2, "fragment_profile"
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0

    return-object v0
.end method


# public static String getReelsRedirect()
# Returns the fragment to redirect to when reels is accessed
.method public static getReelsRedirect()Ljava/lang/String;
    .locals 3

    # Check if appContext is null
    sget-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;
    if-nez v0, :cond_not_null

    # appContext is null, return default
    const-string v0, "fragment_direct_tab"
    return-object v0

    :cond_not_null
    # Get SharedPreferences
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getPrefs()Landroid/content/SharedPreferences;
    move-result-object v0

    # getString("reels_redirect", "fragment_direct_tab")
    const-string v1, "reels_redirect"
    const-string v2, "fragment_direct_tab"
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0

    return-object v0
.end method


# public static String getFeedRedirect()
# Returns the fragment to redirect to when feed is accessed
.method public static getFeedRedirect()Ljava/lang/String;
    .locals 3

    # Check if appContext is null
    sget-object v0, Lcom/instafree/InstaFreeConfig;->appContext:Landroid/content/Context;
    if-nez v0, :cond_not_null

    # appContext is null, return default
    const-string v0, "fragment_feed"
    return-object v0

    :cond_not_null
    # Get SharedPreferences
    invoke-static {}, Lcom/instafree/InstaFreeConfig;->getPrefs()Landroid/content/SharedPreferences;
    move-result-object v0

    # getString("feed_redirect", "fragment_feed")
    const-string v1, "feed_redirect"
    const-string v2, "fragment_feed"
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0

    return-object v0
.end method
