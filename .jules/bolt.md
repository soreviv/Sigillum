## 2026-05-18 - [Optimizing SSE Stream Parsers in Dart]
**Learning:** Manual string concatenation (`StringBuffer` and `indexOf('\n')`) for parsing Server-Sent Events (SSE) from `http.StreamedResponse` is inefficient (creates many intermediate string objects and causes memory allocations/UI jank). Furthermore, manually decoding chunks with `utf8.decode(bytes)` incorrectly handles multi-byte UTF-8 characters (like 'ñ', 'ó') that happen to get split across TCP chunk boundaries, rendering as malformed bytes ().
**Action:** Use Dart's native stream transformers (`byteStream.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())`) instead. It is significantly faster, reduces garbage collection overhead, and correctly buffers multi-byte characters split across network chunks.

## 2026-05-18 - [Dart HTTP Client Connection Pooling]
**Learning:** Using `http.Request(...).send()` or `http.post(...)` creates a one-off HTTP client that is destroyed after the response body is read. This completely prevents TCP connection reuse (Keep-Alive), forcing every single API call to re-negotiate DNS resolution and the TLS handshake, which adds ~200-500ms of latency per request. This is a severe backend/network bottleneck for conversational AI features.
**Action:** Always instantiate and reuse a global/static `http.Client()` for repeated API calls to the same origin to leverage connection pooling and eliminate redundant TLS handshakes.

## 2026-06-04 - [Throttling setState in SSE Loops for Flutter]
**Learning:** Calling `setState()` and queuing scroll animations (like `_scrollToBottom()`) indiscriminately on *every single token/chunk* received from a fast Server-Sent Events (SSE) stream causes massive widget tree churn, especially when rebuilding expensive widgets like `MarkdownBody`. This leads to severe UI jank, high CPU utilization, and dropped frames, effectively starving the main thread.
**Action:** Throttle the UI updates (e.g. using a `Stopwatch`) inside high-frequency SSE consumption loops to roughly 50ms (~20fps). This preserves perfectly smooth visual streaming while drastically slashing the render workload and `postFrameCallback` overhead.

## 2026-06-14 - [Flutter Stream Rendering Bottleneck]
**Learning:** Updating a stream buffer inside a `setState()` call during an `await for` loop causes the entire screen to rebuild for every single chunk received, leading to severe UI jank.
**Action:** Use `ValueNotifier` and `ValueListenableBuilder` to scope rebuilds only to the specific widget displaying the streaming text.
