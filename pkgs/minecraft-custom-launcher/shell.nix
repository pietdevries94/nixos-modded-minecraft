{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_latest
    jdk17
    rustc
    cargo

    openssl
    pkgconfig
    glib
    cairo
    pango
    gdk-pixbuf
    atk
    libsoup
    gtk3
    webkitgtk
    wget
  ];
}
