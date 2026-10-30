# Feed integration

The setup script creates OpenWrt's active feeds.conf file (not feeds.conf.local). It uses the OpenWrt src-include directive to load the pinned release's feeds.conf.default and appends one local feed entry for this repository's custom-feed directory.

The OpenWrt feeds utility reads feeds.conf when present and otherwise falls back to feeds.conf.default. The generated file therefore preserves the exact package, LuCI, routing, telephony and video feed revisions selected by the pinned OpenWrt release.

Run from the OpenWrt source directory:

    ./scripts/feeds update -a
    ./scripts/feeds install router-core
    ./scripts/feeds install router-net
    ./scripts/feeds install router-dsa-sdk
    ./scripts/feeds install router-dsa-runtime
    ./scripts/feeds install router-tests
    ./scripts/feeds install router-ui

The package SDK workflow performs the feed update and package compilation automatically. Manual visual inspection of a feeds file is not considered proof that the packages build.
