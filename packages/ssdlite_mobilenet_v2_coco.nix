{
  pkgs ? import <nixpkgs> { },
}:

let
  # Python environment with OpenVINO
  pythonEnv = pkgs.python312.withPackages (ps: [
    ps.openvino
  ]);

  # Download the TensorFlow model
  modelTarball = pkgs.fetchurl {
    url = "http://download.tensorflow.org/models/object_detection/ssdlite_mobilenet_v2_coco_2018_05_09.tar.gz";
    sha256 = "sha256-VCRFzOg02/u33xmRQl1HXoWi1+xoxgpPJiuxiqwQyLI=";
  };

  # Build script for converting the model
  buildScript = pkgs.writeText "build_ov_model.py" ''
    import numpy as np
    import openvino as ov
    from openvino import Model, Type
    from openvino import opset8 as ops

    model_path = "/build/ssdlite_mobilenet_v2_coco_2018_05_09/frozen_inference_graph.pb"
    # Convert TF model to OpenVINO IR
    ov_model = ov.convert_model(input_model=model_path, input=[1, 300, 300, 3])


    # # Deterministic selection by shapes for this known model
    # outs = list(ov_model.outputs)
    # boxes = [o for o in outs if list(o.get_shape())[-1] == 4][0]
    # twod = [o for o in outs if len(list(o.get_shape())) == 2][:2]


    # We must grab the source output feeding the Result nodes, not the Result nodes themselves
    def get_source(output_port):
        # Get the Result node -> Get its input (0) -> Get the source output connected to that input
        return output_port.get_node().input_value(0)

    outs = list(ov_model.outputs)

    # Identify outputs by shape, but grab the SOURCE tensor
    boxes = [get_source(o) for o in outs if list(o.get_shape())[-1] == 4][0]
    # Find all rank-2 outputs
    twod = [get_source(o) for o in outs if len(list(o.get_shape())) == 2]

    scores = None
    classes = None

    # inspect names to assign correctly
    for t in twod:
        # Check names of the output node
        names = t.get_names()
        name_str = str(names).lower()

        if "score" in name_str:
            scores = t
        elif "class" in name_str:
            classes = t

    # Fallback: If names are missing (rare), assume standard TF Object Detection API order
    # Usually: [detection_boxes, detection_classes, detection_scores, num_detections]
    # But 'twod' only has the rank-2 ones.
    if scores is None or classes is None:
        print("Warning: Could not identify outputs by name. Falling back to index assumptions.")
        # If you were getting Class 0 before, it means twod[0] was Scores and twod[1] was Classes
        # So we swap the index access here to fix it:
        classes = twod[0]
        scores = twod[1]

    # Fixed N for this model (TF SSDLite MobileNet V2 COCO uses max_total_detections=100)
    N = 100
    # Reshape to [1, N, X]
    pat_1n4 = ops.constant(np.array([1, N, 4], dtype=np.int64))
    pat_1n1 = ops.constant(np.array([1, N, 1], dtype=np.int64))
    boxes_1n4 = ops.reshape(boxes, pat_1n4, False)
    scores_1n1 = ops.reshape(scores, pat_1n1, False)
    classes_1n1 = ops.reshape(classes, pat_1n1, False)
    # Ensure f32 for concat
    boxes_1n4 = ops.convert(boxes_1n4, Type.f32)
    scores_1n1 = ops.convert(scores_1n1, Type.f32)
    classes_1n1 = ops.convert(classes_1n1, Type.f32)
    # Reorder TF boxes [ymin, xmin, ymax, xmax] -> [xmin, ymin, xmax, ymax]
    # Use Gather with explicit i64 indices and axis=2
    reorder_idx = ops.constant(np.array([1, 0, 3, 2], dtype=np.int64))
    axis2 = ops.constant(np.array(2, dtype=np.int64))
    boxes_xyxy = ops.gather(boxes_1n4, reorder_idx, axis2)
    # image_id = 0 for all detections
    image_ids = ops.constant(np.zeros((1, N, 1), dtype=np.float32))
    # Build [1, N, 7] => [image_id, label, confidence, x_min, y_min, x_max, y_max]
    det_1n7 = ops.concat([image_ids, classes_1n1, scores_1n1, boxes_xyxy], axis=2)
    # Reshape to [1, 1, N, 7] and expose as single output
    det_11n7 = ops.reshape(
        det_1n7, ops.constant(np.array([1, 1, N, 7], dtype=np.int64)), False
    )
    det_11n7.set_friendly_name("DetectionOutput")
    ov_model = Model([det_11n7], ov_model.get_parameters(), "ssd_mobilenet_v2_detection")
    # Validate Frigate SSD expectations: 1 output; shape [1,1,N,7]
    outs = list(ov_model.outputs)
    shape0 = list(outs[0].get_shape())
    if not (
        len(outs) == 1
        and len(shape0) >= 4
        and shape0[0] == 1
        and shape0[1] == 1
        and shape0[3] == 7
    ):
        raise RuntimeError(
            f"Frigate SSD validation failed. outputs={len(outs)}, shape={shape0}"
        )
    # Save model (FP16 weights)
    ov.save_model(ov_model, "/build/output/ssdlite_mobilenet_v2.xml", compress_to_fp16=True)
  '';

  coco_91cl_bkgr = pkgs.fetchurl {
    url = "https://github.com/openvinotoolkit/open_model_zoo/raw/master/data/dataset_classes/coco_91cl_bkgr.txt";
    hash = "sha256-5Cj2vEiWR8Z9d2xBmVoLZuNRv4UOuxHSGZQWTJorXUQ=";
  };

in
pkgs.stdenv.mkDerivation {
  pname = "ssdlite-mobilenet-v2-openvino";
  version = "2018-05-09";

  src = modelTarball;

  nativeBuildInputs = [
    pythonEnv
    pkgs.wget
  ];

  unpackPhase = ''
    runHook preUnpack
    mkdir -p /build
    tar -xzf ${modelTarball} -C /build
    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild

    mkdir -p /build/output

    echo "Converting model with OpenVINO..."
    python3 ${buildScript}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp --no-preserve=mode /build/output/ssdlite_mobilenet_v2.xml $out/
    cp --no-preserve=mode /build/output/ssdlite_mobilenet_v2.bin $out/
    cp --no-preserve=mode ${coco_91cl_bkgr} $out/coco_91cl_bkgr.txt

    # Also copy the original model files for reference
    mkdir -p $out/original
    cp -r /build/ssdlite_mobilenet_v2_coco_2018_05_09/* $out/original/

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "SSDLite MobileNet V2 model converted to OpenVINO format";
    platforms = platforms.unix;
  };
}
