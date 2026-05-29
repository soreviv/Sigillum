## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-05-29 - [Optimizing List Views in Dart]
**Learning:** Using `List.unmodifiable(list)` inside a getter that is frequently accessed (like inside `ListView.builder` building the chat UI) creates a deep copy/recreation of the array on every single read, turning an O(1) property access into an O(N) allocation and copy.
**Action:** Use `UnmodifiableListView(list)` from `dart:collection` instead, which merely wraps the existing list without copying its contents, keeping the getter strictly O(1) and significantly reducing UI jank during rapid rebuilds (like streaming text).
