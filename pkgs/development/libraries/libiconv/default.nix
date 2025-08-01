{
  fetchurl,
  stdenv,
  lib,
  updateAutotoolsGnuConfigScriptsHook,
  enableStatic ? stdenv.hostPlatform.isStatic,
  enableShared ? !stdenv.hostPlatform.isStatic,
  enableDarwinABICompat ? false,
}:

# assert !stdenv.hostPlatform.isLinux || stdenv.hostPlatform != stdenv.buildPlatform; # TODO: improve on cross

stdenv.mkDerivation rec {
  pname = "libiconv";
  version = "1.17";

  src = fetchurl {
    url = "mirror://gnu/libiconv/${pname}-${version}.tar.gz";
    sha256 = "sha256-j3QhO1YjjIWlClMp934GGYdx5w3Zpzl3n0wC9l2XExM=";
  };

  enableParallelBuilding = true;

  # necessary to build on FreeBSD native pending inclusion of
  # https://git.savannah.gnu.org/cgit/config.git/commit/?id=e4786449e1c26716e3f9ea182caf472e4dbc96e0
  nativeBuildInputs = [ updateAutotoolsGnuConfigScriptsHook ];

  # https://github.com/NixOS/nixpkgs/pull/192630#discussion_r978985593
  hardeningDisable = lib.optional (stdenv.hostPlatform.libc == "bionic") "fortify";

  setupHooks = [
    ../../../build-support/setup-hooks/role.bash
    ./setup-hook.sh
  ];

  postPatch =
    lib.optionalString
      (
        (stdenv.hostPlatform != stdenv.buildPlatform && stdenv.hostPlatform.isMinGW) || stdenv.cc.nativeLibc
      )
      ''
        sed '/^_GL_WARN_ON_USE (gets/d' -i srclib/stdio.in.h
      ''
    + lib.optionalString (!enableShared) ''
      sed -i -e '/preload/d' Makefile.in
    ''
    # The system libiconv is based on libiconv 1.11 with some ABI differences. The following changes
    # build a compatible libiconv on Darwin, allowing it to be sustituted in place of the system one
    # using `install_name_tool`. This removes the need to for a separate, Darwin-specific libiconv
    # derivation and allows Darwin to benefit from upstream updates and fixes.
    + lib.optionalString enableDarwinABICompat ''
      for iconv_h_in in iconv.h.in iconv.h.build.in; do
        substituteInPlace "include/$iconv_h_in" \
          --replace-fail "#define iconv libiconv" "" \
          --replace-fail "#define iconv_close libiconv_close" "" \
          --replace-fail "#define iconv_open libiconv_open" "" \
          --replace-fail "#define iconv_open_into libiconv_open_into" "" \
          --replace-fail "#define iconvctl libiconvctl" "" \
          --replace-fail "#define iconvlist libiconvlist" ""
      done
    '';

  # This is hacky, but `libiconv.dylib` needs to reexport `libcharset.dylib` to match the behavior
  # of the system libiconv on Darwin. Trying to do this by modifying the `Makefile` results in an
  # error linking `iconv` because `libcharset.dylib` is not at its final path yet. Avoid the error
  # by building without the reexport then clean and rebuild `libiconv.dylib` with the reexport.
  #
  # For an explanation why `libcharset.dylib` is reexported, see:
  # https://github.com/apple-oss-distributions/libiconv/blob/a167071feb7a83a01b27ec8d238590c14eb6faff/xcodeconfig/libiconv.xcconfig
  postBuild = lib.optionalString enableDarwinABICompat ''
    make clean -C lib
    NIX_CFLAGS_COMPILE+=" -Wl,-reexport-lcharset -L. " make -C lib -j$NIX_BUILD_CORES SHELL=$SHELL
  '';

  configureFlags = [
    (lib.enableFeature enableStatic "static")
    (lib.enableFeature enableShared "shared")
  ]
  ++ lib.optional stdenv.hostPlatform.isFreeBSD "--with-pic";

  passthru = { inherit setupHooks; };

  meta = {
    description = "Iconv(3) implementation";

    longDescription = ''
      Some programs, like mailers and web browsers, must be able to convert
      between a given text encoding and the user's encoding.  Other programs
      internally store strings in Unicode, to facilitate internal processing,
      and need to convert between internal string representation (Unicode)
      and external string representation (a traditional encoding) when they
      are doing I/O.  GNU libiconv is a conversion library for both kinds of
      applications.
    '';

    homepage = "https://www.gnu.org/software/libiconv/";
    license = lib.licenses.lgpl2Plus;

    maintainers = [ ];
    mainProgram = "iconv";

    # This library is not needed on GNU platforms.
    hydraPlatforms = with lib.platforms; cygwin ++ darwin ++ freebsd;
  };
}
