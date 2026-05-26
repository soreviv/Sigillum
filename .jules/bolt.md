## 2024-06-25 - Static Dataset Optimization in RagRetriever
**Learning:** In Dart/Flutter, repeated dynamic string normalization and tokenization on static dataset entries inside a search hot path will significantly degrade performance.
**Action:** When searching over static, predefined data (like embedded JSON assets), always pre-calculate and cache tokenization sets and normalized keywords. This avoids redundant computational overhead on every query.
