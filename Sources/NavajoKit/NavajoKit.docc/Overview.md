# NavajoKit Overview

Yáʼátʼééh and Hello!

## Purpose Statement

1. To honor the Codetalkers who bravely served during World War II
2. To fill gap that currently exists in lingustic studies and computer science
3. To provide knowledge for the benefit of humanity

## Goals

This project's goal is to become a viable translation tool for the Navajo (Diné) language to convert any provided text into accurate American English.

Eventually, the secondary goal would be to translate the other direction, as well.

## Resources

* Support this project by donating [here](https://www.paypal.com/donate/?hosted_button_id=F4UD8QZYHHKTE)
* View the Patreon page [here](https://patreon.com/TheNavajoTranslationProject)

## License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
* Credit must be given to Daniel Gump with a link to the [GitLab page](https://gitlab.com/HullBreach/navajokit). 
* Adaptations must be shared under the same terms.
* Commercial usage is permitted.

## Status

* At the moment, this project's primary focus is growing the datasets to train the part-of-speech tagger model and the transformer encoder/decoder models.

* It includes tokenization for a number of sizes and support for handling of Unicode characters and ignoring the lead glottal stops.

* A polysynthetic tokenizer is very early in development for better helping with identifying word components. Its initial focus is on prefixes and suffixes for several parts-of-speech.

* The part-of-speech tagger model is Apple's Core ML flavor (called the "word tagger") with the conditional random field (CRF) algorithm for applying the appropriate parts-of-speech to recognize or inferred words. Alternate transfer-learning algorithems using BERT and ELMo are not possible for Navajo.

* The interlinear translation portion performs a direct, case-insensitive search for single words or compounds words/phrases, attempting by the tagged POS first with "miss" fallback to any match (and a flag to indicate that suggested fallback).

* End-to-end translation uses a pair of encoder-decoder transformer models with a shared vocabulary of 10,000 tokens. The shell script and Python script for training in PyTorch and converting to Core ML are both included. Raw training data are also included, where possible.

* The text-to-speech feature is very early in development. It works but sounds very robotic yet and applies American English inflection to long vowel sounds, producing a faint "R".

* In the future, the project will include an image classification model for optical character recognition (OCR) of image files or camera feeds of Navajo text. That model is not included at the moment because of its low accuracy for vowels containing two diacriticals, italicized vowels following glottal stops, etc.
