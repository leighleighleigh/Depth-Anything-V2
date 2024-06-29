{
  venv-site-packages ? true, # build the python venv with --system-site-packages flag 
  cuda-support ? true # call with --arg cuda false, to install regular pytorch version. 
}:
let
  # check manually if a nvidia card is available
  cuda = (builtins.pathExists "/dev/nvidia0" && cuda-support);

  unstable_nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/16d1988121107729f71a84f1af07555be5a764d7";
  stable_nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import stable_nixpkgs { config = { allowUnfree = true; cudaSupport = cuda; };};
  unstable_pkgs = import unstable_nixpkgs { config = {allowUnfree = true; cudaSupport = cuda; };};


  initScript = pkgs.writeShellScriptBin "pytorch-venv" ''
    #!/usr/bin/env bash
    export WINIT_UNIX_BACKEND=wayland
    export WGPU_BACKEND=gl
    test -d .env || (python3 -m venv ${if venv-site-packages then "--system-site-packages" else ""} .env && (source ./.env/bin/activate;) || exit 1)
    . ./.env/bin/activate
    export PS1="(depth-env) $PS1"
    cd metric_depth
    '';

    # this package list is only added to buildInputs, if we detect that we are not running on NixOS.
    # in this case, we will use the system-wide python installation, which brings with it the system-wide pytorch,
    # which will have proper CUDA support :)
    nixosCheckPath = /usr/bin/python3;

    baseDeps = with unstable_pkgs; [
	    glib
	    libGL
	    libGLU
	    libxkbcommon
	    stdenv.cc.cc
	    wayland
	    xorg.libX11
	    xorg.libXcursor
	    xorg.libXi
	    xorg.libXrandr
    ];
in
pkgs.mkShell rec {
  name = "pytorch-env";

  buildInputs = baseDeps ++ [ initScript ] ++ pkgs.lib.optional (! builtins.pathExists nixosCheckPath) (import ./deps.nix { cuda = cuda; }).extraDeps;

  shellHook = if (builtins.pathExists nixosCheckPath) then ''
    . pytorch-venv
  '' else ''
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath baseDeps}"
    . pytorch-venv
  '';
}
