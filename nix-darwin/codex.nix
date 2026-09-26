# Temporary 0.157.1 source build on top of the daemon packaging fix in
# llm-agents PR #9889, pinned by flake.nix.
{ codex }:

codex.override {
  # Version and source hash from:
  # https://github.com/numtide/llm-agents.nix/commit/bfda5b8161d9e05bb3255a6f975628f4373209fc
  # That revision has the same cargoHash and librusty_v8 data as the pinned PR.
  # Use override (not overrideAttrs) so the source and package manifest both
  # receive the new version through the upstream package function.
  version = "0.157.1";
  hash = "sha256-HuNL5VGd2LenhbCdcz0i8b6lRw3sicwXytyfXgCgy88=";
}
