{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonAtLeast,
  setuptools,
  certifi,
  click,
  keyring,
  keyrings-alt,
  requests,
  tzlocal,
  pytest-mock,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pyicloud";
  version = "1.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "picklepete";
    repo = "pyicloud";
    rev = version;
    hash = "sha256-2E1pdHHt8o7CGpdG+u4xy5OyNCueUGVw5CY8oicYd5w=";
  };

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    certifi
    click
    keyring
    keyrings-alt
    requests
    tzlocal
  ];

  nativeCheckInputs = [
    pytest-mock
    pytestCheckHook
  ];

  disabledTests = lib.optionals (pythonAtLeast "3.12") [
    # https://github.com/picklepete/pyicloud/issues/446
    "test_storage"
  ];

  meta = with lib; {
    description = "PyiCloud is a module which allows pythonistas to interact with iCloud webservices";
    mainProgram = "icloud";
    homepage = "https://github.com/picklepete/pyicloud";
    license = licenses.mit;
    maintainers = [ maintainers.mic92 ];
  };
}
