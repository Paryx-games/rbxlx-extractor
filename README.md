# rbxlx extractor - Supports **ONLY** rbxlx
This extracts rbxlx files into [Rojo](https://rojo.space/) compatible structures using [Lune](https://lune-org.github.io/docs/).

> [!NOTE]
> To extract the rbxlx files, put them under extraction/ otherwise they will not work. The script will return an error if you don't put one there.

> [!IMPORTANT]
> You cannot use a rbxl file, as it is binary, and I have not implemented support for that.

You may customize it in [extractor.luau](extraction/extract.luau) with these:

```luau
-- These are the services we want to extract from the place file
-- You can modify this list to include services as needed. Keep in mind that StarterPlayer includes
-- starterplayerscripts and startercharacterscripts as children, which are handled separately.
local SERVICES_TO_EXTRACT = {
	"Workspace",
	"Lighting",
	"ReplicatedFirst",
	"ReplicatedStorage",
	"ServerScriptService",
	"ServerStorage",
	"StarterGui",
	"StarterPack",
	"StarterPlayer",
	"SoundService",
}

-- You can remove one of these if you don't want to extract both
-- You must extract StarterPlayer itself first before extracting these children
local STARTER_PLAYER_CHILDREN = {
	"StarterPlayerScripts",
	"StarterCharacterScripts",
}

-- ANSI color codes for terminal output
-- You can customize these colors as desired
-- Don't change unless you know what you are doing
local COLORS = {
	reset = "\27[0m",
	red = "\27[91m",
	green = "\27[92m",
	yellow = "\27[93m",
	blue = "\27[94m",
	magenta = "\27[95m",
	cyan = "\27[96m",
	white = "\27[97m",
	orange = "\27[38;5;214m",
	gold = "\27[38;5;226m",
	purple = "\27[38;5;177m",
	pink = "\27[38;5;219m",
	lime = "\27[38;5;155m",
}
```

# Tutorial to make this work ✨
## Extract zip archive

### 1. Download the ZIP Archive
- Click [here](https://github.com/Paryx-games/rbxlx-extractor/archive/refs/tags/v1.zip) to download the `rbxlx-extractor-1.zip` file.

### 2. Extract the Files
- Once the ZIP file is downloaded, locate it in your file explorer (likely in your `Downloads` folder).
- Right-click the file and select **Extract All...**.
- Follow the on-screen instructions to unzip the folder.

### 3. Access the Extracted Files
- After extracting, open the folder you just unzipped.
- To get to the folder through the terminal, follow these steps:
  - **Windows:** Open Command Prompt (or PowerShell) and type the following command:
    ```bash
    cd Downloads\rbxlx-extractor-1
    ```
  - **Mac/Linux:** Open Terminal and type:
    ```bash
    cd ~/Downloads/rbxlx-extractor-1
    ```

### Extra Tips
- If you're unsure where the ZIP file went, check your browser's download location or look for a folder named `rbxlx-extractor-1`.

## Install Lune (if you havent already)

_Extracted from https://lune-org.github.io/docs/getting-started/1-installation/_

The preferred way of installing Lune is using [Rokit](https://github.com/rojo-rbx/rokit), a toolchain manager for Roblox projects. Rokit can manage your installed version of Lune and other ecosystem tools, and allows you to easily upgrade to newer versions as they become available.

<Steps>

1. ### Installing Rokit

   Follow the installation instructions on the [Rokit](https://github.com/rojo-rbx/rokit) page.

2. ### Installing Lune

   Navigate to your project directory using your terminal, and run the following command:

   ```bash title="Terminal"
   rokit add lune
   ```

3. ### Upgrading Lune

   When a new version of Lune becomes available, Rokit makes it easy to upgrade. Navigate to your project directory using your terminal again, and run the following command:

   ```bash title="Terminal"
   rokit update lune
   ```

</Steps>

If you prefer to install Lune globally and have it accessible on your entire system, instead of only in a specific project, you can do this with Rokit as well. Just add the `--global` option to the end of the commands above.

## Other Installation Options

<details>
<summary>Using GitHub Releases</summary>

You can download pre-built binaries for most systems directly from the [GitHub Releases](https://github.com/lune-org/lune/releases) page. There are many tools that can install binaries directly from releases, and it's up to you to choose what tool to use. Lune is compatible with both [Foreman](https://github.com/Roblox/foreman) and [Aftman](https://github.com/LPGhatguy/aftman).

</details>

<details>
<summary>Community-maintained</summary>

### Scoop

Windows users can use [Scoop](https://scoop.sh) to install Lune.

```sh filename="PowerShell"
# Add the bucket
scoop bucket add lune https://github.com/CompeyDev/lune-packaging.git

# Install the package
scoop install lune
```

### Homebrew

macOS and Linux users can use [Homebrew](https://brew.sh) to install Lune.

```bash title="Terminal"
# Installs latest stable precompiled binary
brew install lune
```

**_or_**

```bash title="Terminal"
# Builds from latest stable source
brew install lune --build-from-source
```

### APT

APT is a package manager for Debian-based Linux distributions that uses `dpkg` to install packages. Follow the instructions at the unofficial [lune-packaging](https://github.com/CompeyDev/lune-packaging#apt) repository to install Lune using APT.

<Aside type="caution">
  The APT repository is hosted by the community and is not endorsed by or
  affiliated with Lune.
</Aside>

### AppImage

AppImages are platform-independent sandboxed binaries that work out of the box. Go to the [GitHub Actions Page](https://github.com/CompeyDev/lune-packaging/actions/workflows/appimage.yaml), and download the artifact suitable for your architecture from the build artifacts.

### AUR (Arch User Repository)

There are a number of packages available on the AUR:

- `lune` - Builds from the latest stable release source
- `lune-git` - Builds from the latest commit in the repository (unstable)
- `lune-bin` - Installs a precompiled binary from GitHub Release artifacts

These can be installed with your preferred AUR package manager:

```bash title="Terminal"
paru -S [PACKAGE_NAME]
```

**_or_**

```bash title="Terminal"
yay -S [PACKAGE_NAME]
```

<Aside type="caution">
  Only one of these AUR packages should be installed at a time to prevent
  conflicts.
</Aside>

### Nix

macOS\* and Linux users can use [Nix](https://nixos.org/) to install Lune.

<Aside type="caution">
  *the macOS build is currently broken. Help is wanted debugging [this
  issue](https://github.com/NixOS/nixpkgs/blob/36f9963ac7ea0a471c1d408e90edec093a819d83/pkgs/development/interpreters/lune/default.nix).
</Aside>

<details>
<summary>Imperatively</summary>

**NixOS**

```bash title="Terminal"
nix-env -iA nixos.lune
```

**Non-NixOS**

```bash title="Terminal"
nix-env -iA nixpkgs.lune
# If you are using flakes
nix profile install nixpkgs#lune
```

</details>

<details>
<summary>Declaratively</summary>

**With [home-manager](https://github.com/nix-community/home-manager)**

```nix
home.packages = with pkgs; [
  lune
];
```

**System-wide NixOS configuration**

```nix
environment.systemPackages = with pkgs; [
  lune
];
```

</details>

<details>
<summary>Temporarily</summary>

You can temporarily use Lune in your shell. This is useful to try out Lune before deciding to permanently install it.

```bash title="Terminal"
nix-shell -p lune
```

</details>

</details>

<details>
<summary>Using crates.io</summary>

### Building from source

Building and installing from source requires the latest version of [Rust & Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html) to be installed on your system. Once installed, run the following command in your terminal:

```bash title="Terminal"
cargo install lune --locked
```

### Binstall

[`cargo binstall`](https://github.com/cargo-bins/cargo-binstall) provides a simple mechanism for installing Rust binaries from crates.io without compiling from source (unlike `cargo install`). Lune is packaged in a `binstall`-compatible way.

With `binstall` installed and in your path, run:

```bash title="Terminal"
cargo binstall lune
```

</details>

## Next Steps

Congratulations! You've installed Lune and are now ready to run the script.

After you have installed lune, run this in your terminal in the project folder:

```bash
lune run extraction/extract.luau
```

Make sure the **.rbxlx** file is in the extraction/ folder too! It should write everything to src/ in the root of the project.

It will show bars loading as it progresses. Enjoy!


