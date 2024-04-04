brew install go bzt jq pkg-config rustup hwloc

brew install go bzt jq pkg-config hwloc

export LIBRARY_PATH=/opt/homebrew/lib
export FFI_BUILD_FROM_SOURCE=1
rustup-init (This should install cargo)
Follow the next steps as per the docs.

kill -9 $(pgrep lotus)
