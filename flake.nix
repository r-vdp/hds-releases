{
  outputs = { self }: {
    packages = import ./packages.nix;
  };
}
