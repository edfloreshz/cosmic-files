name := 'cosmic-files'
export APPID := 'com.system76.CosmicFiles'

rootdir := ''
prefix := '/usr'

base-dir := absolute_path(clean(rootdir / prefix))

export INSTALL_DIR := base-dir / 'share'

bin-src := 'target' / 'release' / name
bin-dst := base-dir / 'bin' / name

desktop := APPID + '.desktop'
desktop-src := 'res' / desktop
desktop-dst := clean(rootdir / prefix) / 'share' / 'applications' / desktop

icons-src := 'res' / 'icons' / 'hicolor'
icons-dst := clean(rootdir / prefix) / 'share' / 'icons' / 'hicolor'

# Default recipe which runs `just build-release`
default: build-release

# Runs `cargo clean`
clean:
    cargo clean

# Removes vendored dependencies
clean-vendor:
    rm -rf .cargo vendor vendor.tar

# `cargo clean` and removes vendored dependencies
clean-dist: clean clean-vendor

# Compiles with debug profile
build-debug *args:
    cargo build {{args}}

# Compiles with release profile
build-release *args: (build-debug '--release' args)

# Compiles release profile with vendored dependencies
build-vendored *args: vendor-extract (build-release '--frozen --offline' args)

# Runs a clippy check
check *args:
    cargo clippy --all-features {{args}} -- -W clippy::pedantic

# Runs a clippy check with JSON message format
check-json: (check '--message-format=json')

# Developer target
dev *args:
    cargo fmt
    cargo test
    just run {{args}}

# Run with debug logs
run *args:
    cargo build --release
    env RUST_LOG=cosmic_files=debug RUST_BACKTRACE=full target/release/cosmic-files {{args}}

# Installs files
install:
    install -Dm0755 {{bin-src}} {{bin-dst}}
    install -Dm0644 {{desktop-src}} {{desktop-dst}}
    for size in `ls {{icons-src}}`; do \
        install -Dm0644 "{{icons-src}}/$size/apps/{{APPID}}.svg" "{{icons-dst}}/$size/apps/{{APPID}}.svg"; \
    done

# Uninstalls installed files
uninstall:
    rm {{bin-dst}}

# Vendor dependencies locally
vendor:
    mkdir -p .cargo
    cargo vendor --sync Cargo.toml \
        | head -n -1 > .cargo/config.toml
    echo 'directory = "vendor"' >> .cargo/config.toml
    echo >> .cargo/config.toml
    echo '[env]' >> .cargo/config.toml
    echo "VERGEN_GIT_COMMIT_DATE = \"$(git log -1 --pretty=format:'%cs' HEAD)\"" >> .cargo/config.toml
    echo "VERGEN_GIT_SHA = \"$(git rev-parse --short HEAD)\"" >> .cargo/config.toml
    tar pcf vendor.tar .cargo vendor
    rm -rf .cargo vendor

# Extracts vendored dependencies
vendor-extract:
    rm -rf vendor
    tar pxf vendor.tar
