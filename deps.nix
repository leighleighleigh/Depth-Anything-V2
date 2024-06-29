{
    cuda ? true,
    pkgs ? import <nixpkgs> { config = { allowUnfree = true; cudaSupport = cuda; };},
}:
{
    extraDeps= [
        pkgs.python3Packages.pip
        (if cuda then pkgs.python3Packages.torchWithCuda else pkgs.python3Packages.torch)
        pkgs.python3Packages.torchvision
        pkgs.python3Packages.numpy
        # packaged python311 pandas is 2.1.1,
        # but we want 1.5.3
        #pkgs.python3Packages.pandas
        pkgs.python3Packages.rich
        pkgs.python3Packages.wheel
        pkgs.python3Packages.pybind11
    ];
}

