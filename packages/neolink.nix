{
  pkgs ? import <nixpkgs> { },
  fetchFromGitHub,
}:

let
  rustPlatform = pkgs.rustPlatform;
in
rustPlatform.buildRustPackage rec {
  pname = "neolink";
  version = "v0.6.2"; # v0.6.2 release doesn't work with Rust 1.80 - time crate fun

  src = fetchFromGitHub {
    owner = "QuantumEntangledAndy";
    repo = pname;
    rev = version;
    hash = "sha256-O+CbxK0phdRFcPH+ELjxd5Ad5eZWz/FZrmnGvkFv1b8=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    protobuf
    installShellFiles
    makeBinaryWrapper
  ];

  buildInputs = with pkgs; [
    openssl
    glib
    gtk2
    gst_all_1.gstreamer
    gst_all_1.gstreamermm
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
    gst_all_1.gst-rtsp-server
    gst_all_1.gst-devtools
    gst_all_1.gst-plugins-rs
  ];

  propagatedBuildInputs = with pkgs; [
    gst_all_1.gstreamer
    gst_all_1.gstreamermm
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
    gst_all_1.gst-rtsp-server
    gst_all_1.gst-devtools
    gst_all_1.gst-plugins-rs
  ];

  postFixup = ''
    wrapProgram $out/bin/neolink \
      --set GST_PLUGIN_PATH ${
        pkgs.lib.makeSearchPath "lib/gstreamer-1.0" [
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
          pkgs.gst_all_1.gst-plugins-bad
          pkgs.gst_all_1.gst-libav
          pkgs.gst_all_1.gst-rtsp-server
        ]
      }
  '';
  meta = with pkgs.lib; {
    description = "Reolink camera to RTSP translator";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
  };
}
