# Overview

Yáʼátʼééh and Hello!

## Purpose Statement

1. To honor the Codetalkers who bravely served during World War II
2. To fill gap that currently exists in lingustic studies and computer science
3. To provide knowledge for the benefit of humanity

## Goals

This project's goal is to become a viable translation tool for the Navajo (Diné) language to convert any provided text into accurate American English.

Eventually, the secondary goal would be to translate the other direction, as well.

## License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
* Credit must be given to Daniel Gump with a link to the [GitLab page](https://gitlab.com/HullBreach/navajokit). 
* Adaptations must be shared under the same terms.
* Commercial usage is permitted.

## Statistics

* 30,820 training tokens
* 10,063 training records
* 23 parts-of-speech
* 87.5% model accuracy

## Status

* At the moment, this project is in the very early stages during the process of growing the dataset, which combines individual words, compound words, longer sentences/phrases, and full text passages. This relatively small dataset does not yet allow for complex modeling, such as with transformers.

* It includes tokenization for a number of sizes but has been trained for word-based tokens at the moment. The tokenizer has several options, such as handling of Unicode characters and ignoring the lead glottal stops.

* A polysynthetic tokenizer is very early in development for better helping with identifying word components. Its initial focus is on prefixes and suffixes for several parts-of-speech.

* The ML model in the project is Apple's Core ML flavor of the part-of-speech (POS) tagger with the conditional random field (CRF) algorithm for applying the appropriate parts-of-speech to recognize or inferred words. Alternate transfer-learning algorithems using BERT and ELMo are not possible for Navajo.

* The translation portion performs a direct, case-insensitive search for single words or compounds words/phrases, attempting by the tagged POS first with "miss" fallback to any match (and a flag to indicate that suggested fallback). This serves well for interlinear translations but not yet for end-to-end translation that models of more advanced architectures would provide.

* In the future, the project will include an image classification model for optical character recognition (OCR) of image files or camera feeds of Navajo text. That model is not included at the moment because of its low accuracy for vowels containing two diacriticals, italicized vowels following glottal stops, etc.
