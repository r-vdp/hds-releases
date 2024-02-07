{
  outputs = { self }: {
    legacyPackages = import ./packages.nix;
  };
}
