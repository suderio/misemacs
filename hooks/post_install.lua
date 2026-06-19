-- hooks/post_install.lua
function PLUGIN:PostInstall(ctx)
    local version = ctx.version or (ctx.sdkInfo and ctx.sdkInfo.version) or ctx.rootPath:match("([^/\\]+)$")

    if not version then
        error("Error: Could not determine Emacs version from rootPath.")
    end
    local os_type = RUNTIME.osType

    if os_type == "windows" then
        print("Pre-compiled Emacs for Windows detected. Skipping compilation hooks.")
        return
    end

    print("---------------------------------------------------------")
    print("Preparing configuration for Emacs " .. version .. "...")
    print("---------------------------------------------------------")

    local build_cmd = string.format([[
#!/bin/sh
set -e

# Basic tool verification
for cmd in make cc cut; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "Error: Missing required build tool: $cmd"
        exit 1
    fi
done

cd "%s"
SRC_DIR="emacs-%s"
if [ ! -d "$SRC_DIR" ]; then
    SRC_DIR="."
fi
cd "$SRC_DIR"

VERSION="%s"
MAJOR_VERSION=$(echo "$VERSION" | cut -d. -f1)

FINAL_OPTS=""

if [ -n "$MISE_EMACS_CONFIGURE_OPTS" ]; then
    echo "Override variable detected (MISE_EMACS_CONFIGURE_OPTS)."
    echo "Smart defaults are disabled. Strict mode enabled."
    FINAL_OPTS="--prefix=%s --enable-option-checking=fatal $MISE_EMACS_CONFIGURE_OPTS"
else
    echo "Evaluating Smart Defaults for Emacs v$MAJOR_VERSION.x..."
    FINAL_OPTS="--prefix=%s --with-gnutls=ifavailable"

    # Native Compilation (Emacs 28+)
    if [ "$MAJOR_VERSION" -ge 28 ]; then
        if echo "int main() { return 0; }" | cc -x c - -lgccjit -o /dev/null >/dev/null 2>&1; then
            echo "  [+] libgccjit detected. Enabling native compilation (--with-native-compilation)."
            FINAL_OPTS="$FINAL_OPTS --with-native-compilation"
        else
            echo "  [-] libgccjit not found. Skipping native compilation."
        fi
    fi

    # Tree-sitter Support (Emacs 29+)
    if [ "$MAJOR_VERSION" -ge 29 ]; then
        if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists tree-sitter; then
            echo "  [+] tree-sitter detected. Enabling tree-sitter support (--with-tree-sitter)."
            FINAL_OPTS="$FINAL_OPTS --with-tree-sitter"
        else
            echo "  [-] tree-sitter not found. Skipping tree-sitter support."
        fi
    fi

    # JSON Support (Emacs 27 to 29 only. Emacs 30+ uses built-in C parser)
    if [ "$MAJOR_VERSION" -ge 27 ] && [ "$MAJOR_VERSION" -lt 30 ]; then
        if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists jansson; then
            echo "  [+] jansson detected. Enabling fast JSON support (--with-json)."
            FINAL_OPTS="$FINAL_OPTS --with-json"
        else
            echo "  [-] jansson not found. Skipping."
        fi
    elif [ "$MAJOR_VERSION" -ge 30 ]; then
        echo "  [*] Emacs 30+ detected. Skipping --with-json (using new built-in JSON parser)."
    fi

    # Wayland/PGTK vs X11 vs Headless Auto-detection
    if command -v pkg-config >/dev/null 2>&1; then
        if ! pkg-config --exists x11 && ! pkg-config --exists gtk+-3.0; then
            echo "  [*] X11/GTK development libraries missing. Configuring headless build (--without-x)."
            FINAL_OPTS="$FINAL_OPTS --without-x"
        elif [ "$MAJOR_VERSION" -ge 29 ] && [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            echo "  [+] Wayland session detected. Enabling Pure GTK support (--with-pgtk)."
            FINAL_OPTS="$FINAL_OPTS --with-pgtk"
        fi
    fi

    # D-Bus Integration (Emacs 23+)
    if [ "$MAJOR_VERSION" -ge 23 ]; then
        if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists dbus-1; then
            echo "  [+] dbus-1 detected. Enabling desktop IPC integration (--with-dbus)."
            FINAL_OPTS="$FINAL_OPTS --with-dbus"
        else
            echo "  [-] dbus-1 not found. Skipping D-Bus integration."
        fi
    fi
fi

echo ""
echo "========================================================="
echo "EFFECTIVE CONFIGURE OPTIONS:"
echo "  $FINAL_OPTS"
echo "========================================================="
echo ""

echo "Running ./configure..."
if ! ./configure $FINAL_OPTS; then
    echo "Error: Configuration failed."
    exit 1
fi

CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
echo "Compiling Emacs with $CORES parallel jobs..."

if ! make -j$CORES; then
    echo "Error: Compilation failed."
    exit 1
fi

if ! make install; then
    echo "Error: Installation failed."
    exit 1
fi

if [ "$SRC_DIR" != "." ]; then
    cd ..
    rm -rf "$SRC_DIR"
fi

echo "Emacs compiled and installed successfully to %s"
    ]], ctx.rootPath, version, version, ctx.rootPath, ctx.rootPath, ctx.rootPath)

    local tmpfile = ctx.rootPath .. "/build_emacs.sh"
    local f = io.open(tmpfile, "w")
    f:write(build_cmd)
    f:close()

    local exit_code = os.execute("sh " .. tmpfile)
    os.remove(tmpfile)

    if type(exit_code) == "number" then
        if exit_code ~= 0 then
            error("Emacs build failed with exit code: " .. tostring(exit_code))
        end
    else
        local ok = exit_code
        if not ok then
            error("Emacs build failed.")
        end
    end
end
