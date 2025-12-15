{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  python3,
}:

let
  # Define the Python environment with just the requirements for this specific script
  pythonEnv = python3.withPackages (
    ps: with ps; [
      numpy
      onnx
    ]
  );

  # The conversion code repository
  src = fetchFromGitHub {
    owner = "NateMeyer";
    repo = "tensorrt_demos";
    rev = "master"; # You can pin a specific commit hash here for stability
    hash = "sha256-E+nuJZA8JQmLnEufMhyNQythPIc6z5G6g9KzHwc5HWo=";
  };

  # Pre-fetch the base config and weights needed for yolov7
  # These URLs come from the download_yolo.sh script
  yolov7Cfg = fetchurl {
    url = "https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov7.cfg";
    hash = "sha256-FuZvp6R7NxvjwfavuaiovNrW7fJEOwNmkYaKJfVrDLI=";
  };

  yolov7Weights = fetchurl {
    url = "https://github.com/AlexeyAB/darknet/releases/download/yolov4/yolov7.weights";
    hash = "sha256-Ts98oT7FA57Ht5sPJbFW/aXq+BnWwrtoKLpV/k+SgzI=";
  };

in
stdenv.mkDerivation {
  pname = "yolov7-320-onnx";
  version = "0.1";

  inherit src;

  nativeBuildInputs = [ pythonEnv ];

  # Patch the script to use np.prod instead of the deprecated np.product
  postPatch = ''
    substituteInPlace yolo/yolo_to_onnx.py \
      --replace "np.product" "np.prod"
  '';

  buildPhase = ''
    # Enter the yolo directory where the scripts expect to run
    cd yolo

    # 1. Setup the base files (replicating parts of download_yolo.sh)
    cp ${yolov7Cfg} yolov7.cfg
    cp ${yolov7Weights} yolov7.weights

    # 2. Create the specific 320x320 config (replicating download_yolo.sh logic)
    echo "Creating yolov7-320.cfg..."
    cat yolov7.cfg | \
      sed -e '6s/batch=64/batch=1/' | \
      sed -e '8s/width=640/width=320/' | \
      sed -e '9s/height=640/height=320/' > yolov7-320.cfg

    # Link the weights as the script expects
    ln -sf yolov7.weights yolov7-320.weights

    # 3. Run the python conversion script
    echo "Converting to ONNX..."
    python3 yolo_to_onnx.py -m yolov7-320
  '';

  installPhase = ''
    mkdir -p $out
    # The script produces a file named after the model argument
    cp yolov7-320.onnx $out/
    cp ${./coco-80.txt} $out/coco-80.txt
  '';

  meta = with lib; {
    description = "YOLOv7 320x320 ONNX model converted using tensorrt_demos";
    license = licenses.mit;
  };
}
