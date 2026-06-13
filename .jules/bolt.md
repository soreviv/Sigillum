## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-06-13 - Monolithic setState() blocks high-frequency SSE updates
**Learning:** Calling `setState()` synchronously in an `await for` stream listener loop during an SSE response causes a full widget tree rebuild for every token received. In a complex chat UI, this leads to significant main-thread blocking and UI jank.
**Action:** Always use granular state management like `ValueNotifier` + `ValueListenableBuilder` to scope rebuilds *only* to the specific widget rendering the streaming content.

## 2026-06-13 - Unintended pubspec.lock modifications
**Learning:** Running `flutter test` or `flutter analyze` might silently downgrade or update dependencies in `pubspec.lock` if the local Flutter SDK version differs from the one that generated the file. This violates the boundary against modifying lockfiles.
**Action:** Always check `git diff` after running tests and revert unintended `pubspec.lock` changes before creating a PR to ensure a clean optimization commit.
