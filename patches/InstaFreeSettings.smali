.class public Lcom/instafree/InstaFreeSettings;
.super Landroid/preference/PreferenceActivity;

# InstaFree Settings Activity
# A PreferenceActivity with programmatically created preferences.
# Allows user to configure content blocking and navigation behavior.


# Default constructor
.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/preference/PreferenceActivity;-><init>()V
    return-void
.end method


# protected void onCreate(Bundle savedInstanceState)
#
# Register plan:
#   v0 = scratch / PreferenceManager (early) / array index
#   v1 = screen (PreferenceScreen) -- preserved throughout
#   v2 = this (copy of p0) -- preserved for addSwitch range calls
#   v3 = category / addSwitch param1 (cat)
#   v4 = addSwitch param2 (key) / array scratch
#   v5 = addSwitch param3 (title) / ListPreference instance / array scratch
#   v6 = addSwitch param4 (summary) / string scratch
#   v7 = addSwitch param5 (bool default) / array scratch
#
# For addSwitch calls, range {v2 .. v7} maps to:
#   v2=this, v3=cat, v4=key, v5=title, v6=summary, v7=default
#
.method protected onCreate(Landroid/os/Bundle;)V
    .locals 8

    # super.onCreate(savedInstanceState)
    invoke-super {p0, p1}, Landroid/preference/PreferenceActivity;->onCreate(Landroid/os/Bundle;)V

    # Keep a copy of 'this' in v2 for contiguous range calls
    move-object v2, p0

    # PreferenceManager manager = getPreferenceManager()
    invoke-virtual {p0}, Landroid/preference/PreferenceActivity;->getPreferenceManager()Landroid/preference/PreferenceManager;
    move-result-object v0

    # manager.setSharedPreferencesName("instafree_prefs")
    const-string v3, "instafree_prefs"
    invoke-virtual {v0, v3}, Landroid/preference/PreferenceManager;->setSharedPreferencesName(Ljava/lang/String;)V

    # PreferenceScreen screen = manager.createPreferenceScreen(this)
    invoke-virtual {v0, p0}, Landroid/preference/PreferenceManager;->createPreferenceScreen(Landroid/content/Context;)Landroid/preference/PreferenceScreen;
    move-result-object v1
    # v1 = screen (preserved throughout)

    # ========================================
    # Content Blocking category
    # ========================================

    # PreferenceCategory blocking = new PreferenceCategory(this)
    new-instance v3, Landroid/preference/PreferenceCategory;
    invoke-direct {v3, p0}, Landroid/preference/PreferenceCategory;-><init>(Landroid/content/Context;)V

    # blocking.setTitle("Content Blocking")
    const-string v0, "Content Blocking"
    invoke-virtual {v3, v0}, Landroid/preference/PreferenceCategory;->setTitle(Ljava/lang/CharSequence;)V

    # screen.addPreference(blocking)
    invoke-virtual {v1, v3}, Landroid/preference/PreferenceScreen;->addPreference(Landroid/preference/Preference;)Z

    # v3 = blocking category, preserved for addSwitch calls

    # addSwitch(blocking, "feed_disabled", "Feed Posts", "Block the homepage feed posts", true)
    # range {v2..v7}: v2=this v3=cat v4=key v5=title v6=summary v7=default
    const-string v4, "feed_disabled"
    const-string v5, "Feed Posts"
    const-string v6, "Block the homepage feed posts"
    const/4 v7, 0x1
    invoke-direct/range {v2 .. v7}, Lcom/instafree/InstaFreeSettings;->addSwitch(Landroid/preference/PreferenceCategory;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V

    # addSwitch(blocking, "stories_disabled", "Stories Tray", "Block the stories tray on homepage", true)
    const-string v4, "stories_disabled"
    const-string v5, "Stories Tray"
    const-string v6, "Block the stories tray on homepage"
    const/4 v7, 0x1
    invoke-direct/range {v2 .. v7}, Lcom/instafree/InstaFreeSettings;->addSwitch(Landroid/preference/PreferenceCategory;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V

    # addSwitch(blocking, "reels_disabled", "Reels Content", "Block reels discovery content", true)
    const-string v4, "reels_disabled"
    const-string v5, "Reels Content"
    const-string v6, "Block reels discovery content"
    const/4 v7, 0x1
    invoke-direct/range {v2 .. v7}, Lcom/instafree/InstaFreeSettings;->addSwitch(Landroid/preference/PreferenceCategory;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V

    # ========================================
    # Navigation category
    # ========================================

    # PreferenceCategory nav = new PreferenceCategory(this)
    new-instance v3, Landroid/preference/PreferenceCategory;
    invoke-direct {v3, p0}, Landroid/preference/PreferenceCategory;-><init>(Landroid/content/Context;)V

    # nav.setTitle("Navigation")
    const-string v0, "Navigation"
    invoke-virtual {v3, v0}, Landroid/preference/PreferenceCategory;->setTitle(Ljava/lang/CharSequence;)V

    # screen.addPreference(nav)
    invoke-virtual {v1, v3}, Landroid/preference/PreferenceScreen;->addPreference(Landroid/preference/Preference;)Z

    # v3 = nav category (preserved for addPreference calls below)

    # ----------------------------------------
    # ListPreference: default_page
    # labels = {"Profile", "DM", "Search", "Feed"}
    # values = {"fragment_profile", "fragment_direct_tab", "fragment_search", "fragment_feed"}
    # default = "fragment_profile"
    # ----------------------------------------

    # Build labels array
    const/4 v0, 0x4
    new-array v4, v0, [Ljava/lang/CharSequence;
    const/4 v0, 0x0
    const-string v7, "Profile"
    aput-object v7, v4, v0
    const/4 v0, 0x1
    const-string v7, "DM"
    aput-object v7, v4, v0
    const/4 v0, 0x2
    const-string v7, "Search"
    aput-object v7, v4, v0
    const/4 v0, 0x3
    const-string v7, "Feed"
    aput-object v7, v4, v0
    # v4 = labels

    # Build values array
    const/4 v0, 0x4
    new-array v5, v0, [Ljava/lang/CharSequence;
    const/4 v0, 0x0
    const-string v7, "fragment_profile"
    aput-object v7, v5, v0
    const/4 v0, 0x1
    const-string v7, "fragment_direct_tab"
    aput-object v7, v5, v0
    const/4 v0, 0x2
    const-string v7, "fragment_search"
    aput-object v7, v5, v0
    const/4 v0, 0x3
    const-string v7, "fragment_feed"
    aput-object v7, v5, v0
    # v5 = values

    # Create and configure ListPreference
    new-instance v6, Landroid/preference/ListPreference;
    invoke-direct {v6, p0}, Landroid/preference/ListPreference;-><init>(Landroid/content/Context;)V

    const-string v0, "default_page"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setKey(Ljava/lang/String;)V

    const-string v0, "Default Page"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setTitle(Ljava/lang/CharSequence;)V

    const-string v0, "Page shown when opening Instagram"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setSummary(Ljava/lang/CharSequence;)V

    invoke-virtual {v6, v4}, Landroid/preference/ListPreference;->setEntries([Ljava/lang/CharSequence;)V
    invoke-virtual {v6, v5}, Landroid/preference/ListPreference;->setEntryValues([Ljava/lang/CharSequence;)V

    const-string v0, "fragment_profile"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setDefaultValue(Ljava/lang/Object;)V

    invoke-virtual {v3, v6}, Landroid/preference/PreferenceCategory;->addPreference(Landroid/preference/Preference;)Z

    # ----------------------------------------
    # ListPreference: reels_redirect
    # labels = {"DM", "Search", "Profile"}
    # values = {"fragment_direct_tab", "fragment_search", "fragment_profile"}
    # default = "fragment_direct_tab"
    # ----------------------------------------

    # Build labels array
    const/4 v0, 0x3
    new-array v4, v0, [Ljava/lang/CharSequence;
    const/4 v0, 0x0
    const-string v7, "DM"
    aput-object v7, v4, v0
    const/4 v0, 0x1
    const-string v7, "Search"
    aput-object v7, v4, v0
    const/4 v0, 0x2
    const-string v7, "Profile"
    aput-object v7, v4, v0
    # v4 = labels

    # Build values array
    const/4 v0, 0x3
    new-array v5, v0, [Ljava/lang/CharSequence;
    const/4 v0, 0x0
    const-string v7, "fragment_direct_tab"
    aput-object v7, v5, v0
    const/4 v0, 0x1
    const-string v7, "fragment_search"
    aput-object v7, v5, v0
    const/4 v0, 0x2
    const-string v7, "fragment_profile"
    aput-object v7, v5, v0
    # v5 = values

    # Create and configure ListPreference
    new-instance v6, Landroid/preference/ListPreference;
    invoke-direct {v6, p0}, Landroid/preference/ListPreference;-><init>(Landroid/content/Context;)V

    const-string v0, "reels_redirect"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setKey(Ljava/lang/String;)V

    const-string v0, "Reels Tab"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setTitle(Ljava/lang/CharSequence;)V

    const-string v0, "Where the Reels tab redirects to"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setSummary(Ljava/lang/CharSequence;)V

    invoke-virtual {v6, v4}, Landroid/preference/ListPreference;->setEntries([Ljava/lang/CharSequence;)V
    invoke-virtual {v6, v5}, Landroid/preference/ListPreference;->setEntryValues([Ljava/lang/CharSequence;)V

    const-string v0, "fragment_direct_tab"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setDefaultValue(Ljava/lang/Object;)V

    invoke-virtual {v3, v6}, Landroid/preference/PreferenceCategory;->addPreference(Landroid/preference/Preference;)Z

    # ----------------------------------------
    # ListPreference: feed_redirect
    # labels = {"Feed (empty)", "DM", "Search", "Profile"}
    # values = {"fragment_feed", "fragment_direct_tab", "fragment_search", "fragment_profile"}
    # default = "fragment_feed"
    # ----------------------------------------

    # Build labels array
    const/4 v0, 0x4
    new-array v4, v0, [Ljava/lang/CharSequence;
    const/4 v0, 0x0
    const-string v7, "Feed (empty)"
    aput-object v7, v4, v0
    const/4 v0, 0x1
    const-string v7, "DM"
    aput-object v7, v4, v0
    const/4 v0, 0x2
    const-string v7, "Search"
    aput-object v7, v4, v0
    const/4 v0, 0x3
    const-string v7, "Profile"
    aput-object v7, v4, v0
    # v4 = labels

    # Build values array
    const/4 v0, 0x4
    new-array v5, v0, [Ljava/lang/CharSequence;
    const/4 v0, 0x0
    const-string v7, "fragment_feed"
    aput-object v7, v5, v0
    const/4 v0, 0x1
    const-string v7, "fragment_direct_tab"
    aput-object v7, v5, v0
    const/4 v0, 0x2
    const-string v7, "fragment_search"
    aput-object v7, v5, v0
    const/4 v0, 0x3
    const-string v7, "fragment_profile"
    aput-object v7, v5, v0
    # v5 = values

    # Create and configure ListPreference
    new-instance v6, Landroid/preference/ListPreference;
    invoke-direct {v6, p0}, Landroid/preference/ListPreference;-><init>(Landroid/content/Context;)V

    const-string v0, "feed_redirect"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setKey(Ljava/lang/String;)V

    const-string v0, "Feed Tab"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setTitle(Ljava/lang/CharSequence;)V

    const-string v0, "Where the Feed tab redirects to"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setSummary(Ljava/lang/CharSequence;)V

    invoke-virtual {v6, v4}, Landroid/preference/ListPreference;->setEntries([Ljava/lang/CharSequence;)V
    invoke-virtual {v6, v5}, Landroid/preference/ListPreference;->setEntryValues([Ljava/lang/CharSequence;)V

    const-string v0, "fragment_feed"
    invoke-virtual {v6, v0}, Landroid/preference/ListPreference;->setDefaultValue(Ljava/lang/Object;)V

    invoke-virtual {v3, v6}, Landroid/preference/PreferenceCategory;->addPreference(Landroid/preference/Preference;)Z

    # setPreferenceScreen(screen)
    invoke-virtual {p0, v1}, Landroid/preference/PreferenceActivity;->setPreferenceScreen(Landroid/preference/PreferenceScreen;)V

    return-void
.end method


# private void addSwitch(PreferenceCategory cat, String key,
#                        String title, String summary, boolean def)
# Parameters: p0=this, p1=cat, p2=key, p3=title, p4=summary, p5=def
.method private addSwitch(Landroid/preference/PreferenceCategory;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V
    .locals 2

    # SwitchPreference p = new SwitchPreference(this)
    new-instance v0, Landroid/preference/SwitchPreference;
    invoke-direct {v0, p0}, Landroid/preference/SwitchPreference;-><init>(Landroid/content/Context;)V

    # p.setKey(key)
    invoke-virtual {v0, p2}, Landroid/preference/SwitchPreference;->setKey(Ljava/lang/String;)V

    # p.setTitle(title)
    invoke-virtual {v0, p3}, Landroid/preference/SwitchPreference;->setTitle(Ljava/lang/CharSequence;)V

    # p.setSummary(summary)
    invoke-virtual {v0, p4}, Landroid/preference/SwitchPreference;->setSummary(Ljava/lang/CharSequence;)V

    # p.setDefaultValue(Boolean.valueOf(def))
    invoke-static {p5}, Ljava/lang/Boolean;->valueOf(Z)Ljava/lang/Boolean;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/preference/SwitchPreference;->setDefaultValue(Ljava/lang/Object;)V

    # cat.addPreference(p)
    invoke-virtual {p1, v0}, Landroid/preference/PreferenceCategory;->addPreference(Landroid/preference/Preference;)Z

    return-void
.end method
