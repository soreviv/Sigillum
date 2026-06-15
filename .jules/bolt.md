## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-06-11 - [Granular State Management for SSE Streams]
**Learning:** Monolithic `setState()` calls during high-frequency Server-Sent Events (SSE) streaming updates cause full widget tree rebuilds in Flutter. This results in significant UI jank, especially in deeply nested structures or when dealing with long lists like in a chat interface.
**Action:** Always use granular state management, like `ValueNotifier` and `ValueListenableBuilder`, to limit rebuilds exclusively to the widget displaying the incoming stream chunks (e.g., the specific chat bubble).
