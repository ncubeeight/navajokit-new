# NavajoTagger Model

Part-of-speech tagger model for Navajo text

## Overview

**NavajoTagger.mlmoodel** is Apple's CoreML flavor of the part-of-speech tagger model, called the [word tagger](https://developer.apple.com/documentation/createml/creating-a-word-tagger-model) model. This model uses the conditional random field (CRF) algorithm for applying the appropriate parts-of-speech to recognize or inferred words. Alternate transfer-learning algorithems using BERT and ELMo are not possible for Navajo.

## Statistics

* 46,922 training tokens
* 11,897 training records
* 23 parts-of-speech
* 90.8% model accuracy

## Usage

The model is integrated into the classes of the NavajoKit framework so that no additional work is needed.

Note: > As a stand-alone, it will work on iOS 12.0+, macOS 10.14+ (Mojave), tvOS 12.0+, watchOS 5.0+, visionOS 1.0+.

## Format Conversion

If you would like to convert it to another format to use outside the Apple ecosystem, here are a few methods that _may_ work:

* **[Apache TVM](https://tvm.apache.org/docs/how_to/compile_models/index.html)** - From Apple Core ML to Relay
* **[Arcane ONNX ML Tools](https://github.com/onnx/onnxmltools)** - From Apple Core ML to ONNX
* **[Microsoft MMdnn](https://github.com/microsoft/MMdnn)** - Conversions between several model formats
