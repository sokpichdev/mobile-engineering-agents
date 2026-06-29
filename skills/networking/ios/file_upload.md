---
platform: ios
---

# Skill: File Upload & Download

## Overview

Uploading/downloading files (images, documents, video) on iOS means handling multipart
form data or direct/pre-signed uploads, **streaming large payloads** instead of loading
them into memory, reporting **progress**, supporting **cancellation**, and (for big or
must-complete transfers) **background sessions** that continue when the app is suspended.
Keep transfers off the main thread and bounded in memory.

## Use Cases

- Profile photo / document / receipt upload.
- Large media upload to object storage (often via a pre-signed URL).
- Downloading attachments or offline content packs.

## Best Practices

- Use **multipart/form-data** for form uploads; **pre-signed URLs** (PUT) for object storage.
- **Stream from file URLs** (`upload(for:fromFile:)`) — don't load multi-MB files into `Data`.
- Report **progress** via `URLSession` delegate / `bytesSent` and expose it to the UI.
- Support **cancellation** and resumable downloads (`resumeData`) where possible.
- Use a **background `URLSession`** for large/critical transfers; validate file type/size first.

## Anti-Patterns

- ❌ Reading an entire large file into memory before upload (memory spike/termination).
- ❌ No progress reporting on long transfers (UI looks frozen).
- ❌ No cancellation, leaking transfers when the user leaves.
- ❌ Foreground-only transfers for large uploads that die on backgrounding.
- ❌ Trusting client-supplied MIME types without validation.

## Checklist

- [ ] Large files streamed from disk, not loaded into memory.
- [ ] Progress reported to the UI.
- [ ] Cancellation supported; downloads resumable where feasible.
- [ ] Background session for large/critical transfers.
- [ ] File type/size validated before upload.

## Swift Examples

```swift
// Multipart upload streamed from a file URL, with progress via async bytes
func uploadImage(fileURL: URL, to endpoint: URL, boundary: String = UUID().uuidString) async throws {
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    // Build a temporary multipart body file on disk (not in memory) for large payloads.
    let bodyFile = try MultipartBuilder(boundary: boundary)
        .appendFile(fieldName: "file", fileURL: fileURL, mimeType: "image/jpeg")
        .finishWritingToTemporaryFile()

    let (data, response) = try await URLSession.shared.upload(for: request, fromFile: bodyFile)
    try? FileManager.default.removeItem(at: bodyFile)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        throw NetworkError.invalidResponse
    }
    _ = data
}
```

```swift
// Pre-signed URL upload (PUT straight to object storage)
func upload(fileURL: URL, to presignedURL: URL) async throws {
    var request = URLRequest(url: presignedURL); request.httpMethod = "PUT"
    let (_, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        throw NetworkError.invalidResponse
    }
}
```

## Common Interview Questions

- How do you upload a large file without high memory usage?
- How do background `URLSession`s work and when do you need them?
- How do you report and cancel transfer progress?
- What is a pre-signed URL and why use one?
- How do you resume an interrupted download?

## AI Implementation Notes

- Stream from file URLs with `upload(for:fromFile:)`; never load big files into `Data`.
- Use a background session for large/critical transfers; surface progress and cancellation.
- Validate type/size before sending.
- Related: [`rest_api.md`](rest_api.md),
  [`../../performance/ios/memory_optimization.md`](../../performance/ios/memory_optimization.md).
