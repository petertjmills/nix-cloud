{
  lib,
  python3,
  fetchFromGitHub,
  nixosTests,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "plann";
  version = "1.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "tobixen";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-WJ7uSYk/esMTjNGAXkjSfqBoxbkOv28tL+PjFc3fwVk=";
  };

  build-system = with python3.pkgs; [
    setuptools
  ];

  dependencies = with python3.pkgs; [
    caldav
    click
    pyyaml
    sortedcontainers
    tzlocal
    python-dateutil
    icalendar
  ];

  # tests require networking
  doCheck = false;

  meta = {
    description = "Command-line interface to calendars";
    homepage = "https://github.com/tobixen/plann";
    license = lib.licenses.gpl3Plus;
    mainProgram = "${pname}";
  };
}
