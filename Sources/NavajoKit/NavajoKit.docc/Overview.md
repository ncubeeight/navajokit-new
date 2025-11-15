# The Navajo Translation Project

Yáʼátʼééh and Hello!

## Purpose Statement

1. To honor the Codetalkers who bravely fought during World War II
2. To fill gap that currently exists in lingustic studies and computer science
3. To provide knowledge for the benefit of humanity

## Goals

This project's goal is to become a viable translation tool for the Navajo (Diné) language to convert any provided text into accurate American English.

Eventually, the secondard goal would be to translate the other direction, as well.

## Status

* At the moment, this project is in the very early stages during the process of growing the dataset. There are currently over 9000 training records, which are a combination of individual words, compound words, longer sentences/phrases, and full text passages. This relatively small dataset does not yet allow for complex modeling, such as with transformers.

* It includes tokenization for a number of sizes but has been trained for word-based tokens at the moment. A polysynthetic tokenizer is very early in development for better helping with identifying word components.

* The ML model in the project at the moment is Apple's Core ML flavor of the part-of-speech (POS) tagger with the conditional random field (CRF) algorithm for applying the appropriate parts-of-speech to recognized or inferred words.

* The translation portion performs a direct, case-insensitive search for single words or compounds words, attempting by the tagged POS first with fallback to any match (and a flag to indicate that fallback). This serves well for interlinear translations but not end-to-end translation that models of more advanced architectures would provide.

* In the future, the project will include an image classification model for optical character recognition (OCR) of image files or camera feeds of Navajo text. That model is not included at the moment because of its low accuracy for vowels containing two diacriticals.
