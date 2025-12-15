# Usage

This project contains resources for tokenization, tagging, and translation. Additionally, it includes raw resources to assist with training your own natural language models.

## Swift Package

This project is currently formatted as a Swift Package that requires iOS 15.0+ or macOS 12.0+ (Monterey).

Swift Package Manager URL: [https://gitlab.com/HullBreach/navajokit](https://gitlab.com/HullBreach/navajokit)

### Package Format

* Sources
* - NavajoKit
* - - Classes
* - - - **NVPolysyntheticTokenizer.swift:** Early custom tokenizer for word components
* - - - **NVTagger.swift:** Applies parts-of-speech tags to tokens
* - - - **NVTokenizer.swift:** Divides text strings in tokens of various lengths
* - - - **NVTranslator.swift:** Replace Navajo words with English words
* - - Enums
* - - - **NVAspect.swift:** Verb aspects and tenses
* - - - **NVPerson.swift:** Grammatical person
* - - - **NVPlurality.swift:** Singular, dual, and plural
* - - Extensions
* - - - **Bundle.swift:** Helper to reference this bundle in an app project
* - - - **MLModel.swift:** Helper to load the NL model
* - - Resources
* - - - **NavajoTagger.mlmodel:** The word tagger model
* - - - **NVClauses.csv:** Spreadsheet of sentence and phrase training data
* - - - **NVCompoundWords.csv:** Spreadsheet of compound word training data
* - - - **NVPassages.csv:** Spreadsheet of long textual passage training data
* - - - **NVSingleWords:** Spreadsheet of single word training data
* - - - **training_data.json:** Training data combined into Create ML format
* - - Structs
* - - - **NVCompoundWord.swift:** Navajo compound word with metadata
* - - - **NVInflection.swift:** Grammatical person and plurality
* - - - **NVTaggedWord.swift:** Word with part-of-speech applied
* - - - **NVWord.swift:** Navajo single word with metadata
* - - - **NVWordToken.swift:** Navajo word with grammatical details
* Tests
* - NavajoKitTests 
* - - NVPolysyntheticTokenizer
* - - - **NVPTAdverbTests.swift:** Unit tests for adverb subtokenization
* - - - **NVPTNounTests.swift:** Unit tests for noun subtokenization
* - - - **NVPTPostpositionTests.swift:** Unit tests for postposition subtokenization
* - - - **NVPTTestCase.swift:** Structure used by unit tests
* - - **NVAspectTests.swift:** Unit tests for NVAspect enum
* - - **NVPersonTests.swift:** Unit tests for NVPerson enum
* - - **NVPluralityTests.swift:** Unit tests for NVPlurality enum

> Note: This package also includes the source files used to build the documentation.
