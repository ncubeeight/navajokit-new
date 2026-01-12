#  Welcome to the Navajo Translation Project!

## Purpose Statement

1. To honor the Codetalkers who bravely served during World War II
2. To fill gap that currently exists in lingustic studies and computer science
3. To provide knowledge for the benefit of humanity

## Goals

* This project's goal is to become a viable translation tool for the Navajo (Diné) language to convert any provided text into accurate American English.

* Eventually, the secondary goal would be to translate the other direction, as well.

## Resources

* Detailed project documentation [here](https://hullbreach.gitlab.io/navajokit/documentation/navajokit/)
* Support this project by donating [here](https://www.paypal.com/donate/?hosted_button_id=F4UD8QZYHHKTE)
* Patreon page [here](https://patreon.com/TheNavajoTranslationProject)

## Swift Package

This project is currently formatted as a Swift Package that requires iOS 15.0+ or macOS 12.0+ (Monterey).

Swift Package URL: [https://gitlab.com/HullBreach/navajokit](https://gitlab.com/HullBreach/navajokit)

## License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
* Credit must be given to Daniel Gump with a link to the [GitLab page](https://gitlab.com/HullBreach/navajokit). 
* Adaptations must be shared under the same terms.
* Commercial usage is permitted.

## Status

* **Part-of-speech tagger model:** Trained on 54,080 word-level tokens
* **Tokenizer:** Several configurations and can divide by syllables, words, sentences, and paragraphs
* **Data Formatter:** Data conversions between CSV, TSV, and JSON
* **Polysynthetic tokenizer:** Early in development to tokenize by Navajo word components
* **Text-to-Speech:** Supports most phonemes but sounds "robotic" and applies slight "R" sounds to long vowels

<!--
To build the documentation:
swift package --allow-writing-to-directory ./docs generate-documentation --transform-for-static-hosting --hosting-base-path navajokit --output-path ./docs
-->
