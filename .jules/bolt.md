## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.
## 2026-06-14 - [Flutter Stream Rendering Bottleneck]
**Learning:** Updating a stream buffer inside a  call during an  loop causes the entire screen to rebuild for every single chunk received, leading to severe UI jank.
**Action:** Use  and  to scope rebuilds only to the specific widget displaying the streaming text.

## 2026-06-14 - [Flutter Stream Rendering Bottleneck]
**Learning:** Updating a stream buffer inside a `setState()` call during an `await for` loop causes the entire screen to rebuild for every single chunk received, leading to severe UI jank.
**Action:** Use `ValueNotifier` and `ValueListenableBuilder` to scope rebuilds only to the specific widget displaying the streaming text.
