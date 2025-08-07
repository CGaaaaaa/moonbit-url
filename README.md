# MoonBit URI Library

English | [简体中文](README_zh_CN.md)

A comprehensive and RFC 3986 compliant URI parsing and manipulation library for MoonBit, featuring advanced URI operations, percent encoding, reference resolution, and much more.

## ✨ Features

### 🔍 **Complete URI Parsing**
- **RFC 3986 Compliant**: Strict compliance with URI standard
- **Full Component Support**: Parse scheme, authority (userinfo, host, port), path, query, and fragment
- **IPv6 Support**: Handle IPv6 addresses in authority section
- **Validation**: Comprehensive URI validation with detailed error messages

### 🛠️ **Advanced URI Operations**
- **Normalization**: Automatic path normalization and case-insensitive comparison
- **Component Access**: Easy access to URI components with helper methods
- **File Operations**: Extract filename, extension, and parent path
- **Port Handling**: Default port detection for common schemes (HTTP, HTTPS, FTP, etc.)

### 🔗 **Reference Resolution**
- **Relative References**: Full RFC 3986 reference resolution algorithm
- **Base URI Support**: Resolve relative URIs against base URIs
- **Dot Segment Removal**: Proper handling of `.` and `..` in paths
- **Batch Operations**: Resolve multiple references efficiently

### 🏗️ **Powerful Builder Pattern**
- **Fluent API**: Chain method calls for intuitive URI construction
- **Path Segments**: Add individual path segments with automatic encoding
- **Query Parameters**: Flexible query parameter management
- **Encoding Options**: Multiple encoding strategies (percent, form-urlencoded, none)
- **Validation**: Built-in validation during construction

### 🔐 **Percent Encoding**
- **Multiple Contexts**: Component, query, path segment, and userinfo encoding
- **RFC Compliant**: Proper encoding/decoding according to RFC 3986
- **Custom Encode Sets**: Define custom character sets for encoding
- **Validation**: Validate percent-encoded strings
- **Form Encoding**: Support for application/x-www-form-urlencoded

### 🎯 **Error Handling**
- **Detailed Errors**: Specific error types for different failure modes
- **Validation**: Runtime validation with clear error messages
- **Recovery**: Graceful handling of malformed URIs

## 🚀 Quick Start

### Basic URI Parsing

```moonbit
// Parse a complete URI
let uri_result = Uri::parse("https://user:pass@example.com:8080/path?query=value#fragment")

match uri_result {
  Ok(uri) => {
    println("Scheme: " + uri.scheme())
    println("Host: " + uri.host().unwrap_or("none"))
    println("Port: " + uri.port().map(Int::to_string).unwrap_or("default"))
    println("Path: " + uri.path())
    println("Query: " + uri.query().unwrap_or("none"))
    println("Fragment: " + uri.fragment().unwrap_or("none"))
  }
  Err(error) => println("Parse error: " + error.to_string())
}
```

### Advanced URI Component Access

```moonbit
let uri = Uri::parse("https://api.example.com:8443/users/123/posts/456.json?format=json#comments").unwrap()

// Component access
println("Scheme: " + uri.scheme())                    // "https"
println("Host: " + uri.host().unwrap())               // "api.example.com"
println("Effective Port: " + uri.effective_port().unwrap().to_string()) // "8443"
println("Default Port: " + uri.default_port().unwrap().to_string())     // "443"

// File operations
println("Filename: " + uri.filename().unwrap())       // "456.json"
println("Extension: " + uri.file_extension().unwrap()) // "json"
println("Parent Path: " + uri.parent_path())          // "/users/123/posts"

// Status checks
println("Is Absolute: " + uri.is_absolute().to_string()) // "true"
println("Has Authority: " + uri.has_authority().to_string()) // "true"
```

### URI Normalization and Comparison

```moonbit
let uri1 = Uri::parse("HTTP://Example.COM:80/path/../file.html").unwrap()
let uri2 = Uri::parse("http://example.com/file.html").unwrap()

// Raw comparison
println("Equal (raw): " + (uri1.to_string() == uri2.to_string()).to_string()) // "false"

// Normalized comparison
println("Equal (normalized): " + uri1.equals_normalized(uri2).to_string()) // "true"

// Explicit normalization
let normalized = uri1.normalize()
println("Normalized: " + normalized.to_string()) // "http://example.com/file.html"
```

## 🏗️ Builder Pattern

### Basic URI Construction

```moonbit
// Build a URI fluently
let uri = UriBuilder::new()
  .scheme("https")
  .host("api.example.com")
  .port(8443)
  .path("/v1/users")
  .query_param("limit", "10")
  .query_param("sort", "name")
  .fragment("results")
  .build()

match uri {
  Ok(u) => println(u.to_string()) // "https://api.example.com:8443/v1/users?limit=10&sort=name#results"
  Err(e) => println("Build error: " + e.to_string())
}
```

### Advanced Builder Features

```moonbit
// Path segments and advanced query parameters
let builder = UriBuilder::new()
  .scheme("https")
  .host("api.example.com")
  .path_segment("api")
  .path_segment("v2")
  .path_segment("users")
  .path_segment("123")
  .query_param("include", "profile,posts")
  .query_param_bool("active_only", true)   // Adds "active_only" (no value)
  .query_param_bool("include_deleted", false) // Skipped
  .query_param_if_not_empty("optional", "")  // Skipped (empty value)
  .query_param_if_not_empty("category", "tech") // Added

let uri = builder.build_string().unwrap()
println(uri) // "https://api.example.com/api/v2/users/123?include=profile,posts&active_only&category=tech"
```

### Credentials and Advanced Authority

```moonbit
// URI with credentials
let secure_uri = UriBuilder::new()
  .scheme("https")
  .credentials("admin", "secret123")
  .host("secure.example.com")
  .port(8443)
  .path("/admin/panel")
  .build_string()
  .unwrap()

println(secure_uri) // "https://admin:secret123@secure.example.com:8443/admin/panel"
```

### Convenience Constructors

```moonbit
// HTTP/HTTPS shortcuts
let api_url = https_url("api.example.com", "/v1/data")
  .query_param("format", "json")
  .build_string()
  .unwrap()

// File URI
let file_path = file_uri("/home/user/documents/file.pdf")
  .build_string()
  .unwrap()
println(file_path) // "file:///home/user/documents/file.pdf"

// Email URI
let email = mailto_uri("support@example.com")
  .build_string()
  .unwrap()
println(email) // "mailto:support@example.com"

// FTP URI
let download_url = ftp_url("files.example.com", "/pub/software/app.zip")
  .build_string()
  .unwrap()
println(download_url) // "ftp://files.example.com/pub/software/app.zip"
```

## 🔐 Percent Encoding

### Basic Encoding/Decoding

```moonbit
// Component encoding
let encoded = percent_encode("hello world/path", Component)
println(encoded) // "hello%20world/path" (space encoded, slash preserved)

// Query parameter encoding (form-style)
let query_encoded = encode_query_param("hello world+test&more")
println(query_encoded) // "hello+world%2Btest%26more"

// Decoding
match percent_decode("hello%20world") {
  Ok(decoded) => println(decoded) // "hello world"
  Err(e) => println("Decode error: " + e)
}

match decode_query_param("hello+world%26test") {
  Ok(decoded) => println(decoded) // "hello world&test"
  Err(e) => println("Decode error: " + e)
}
```

### Encoding Validation

```moonbit
// Validate percent-encoded strings
match validate_percent_encoded("hello%20world%2Fpath") {
  Ok(_) => println("Valid encoding")
  Err(e) => println("Invalid: " + e)
}

// Check for invalid sequences
match validate_percent_encoded("hello%ZZ") {
  Ok(_) => println("Valid")
  Err(e) => println("Invalid: " + e) // "Invalid percent encoding: non-hex characters at position 5"
}
```

### Custom Encoding in Builder

```moonbit
// Different encoding strategies
let builder = UriBuilder::new()
  .scheme("https")
  .host("example.com")
  .path("/search")
  .query_param("q", "hello world & more")
  .query_encoding(QueryEncoding::FormUrlEncoded) // Use form encoding

let uri1 = builder.build_string().unwrap()
println(uri1) // Space becomes '+', '&' becomes '%26'

// Switch to percent encoding
let uri2 = builder.query_encoding(QueryEncoding::Percent)
  .build_string()
  .unwrap()
println(uri2) // Space becomes '%20', '&' becomes '%26'
```

## 🔗 Reference Resolution

### Basic Reference Resolution

```moonbit
// Base URI
let base = Uri::parse("http://example.com/dir/file.html").unwrap()

// Resolve relative references
let refs = [
  "page2.html",        // Relative to current directory
  "../other/page.html", // Parent directory
  "/absolute/path.html", // Absolute path
  "./current/page.html"  // Current directory explicit
]

for ref_str in refs {
  let reference = Uri::parse(ref_str).unwrap()
  match resolve_reference(base, reference) {
    Ok(resolved) => println(ref_str + " -> " + resolved.to_string())
    Err(e) => println("Resolution error: " + e.to_string())
  }
}

// Output:
// page2.html -> http://example.com/dir/page2.html
// ../other/page.html -> http://example.com/other/page.html
// /absolute/path.html -> http://example.com/absolute/path.html
// ./current/page.html -> http://example.com/dir/current/page.html
```

### Reference Resolver

```moonbit
// Create a reference resolver for batch operations
let base = Uri::parse("https://api.example.com/v1/users/123").unwrap()

match ReferenceResolver::new(base) {
  Ok(resolver) => {
    // Resolve single reference
    match resolver.resolve("posts/456") {
      Ok(resolved) => println(resolved.to_string()) // "https://api.example.com/v1/users/123/posts/456"
      Err(e) => println("Error: " + e.to_string())
    }
    
    // Batch resolution
    let references = ["posts", "../456/comments", "/admin/users"]
    let results = resolver.resolve_batch(references)
    
    for result in results {
      match result {
        Ok(uri) => println("Resolved: " + uri.to_string())
        Err(e) => println("Failed: " + e.to_string())
      }
    }
  }
  Err(e) => println("Resolver error: " + e.to_string())
}
```

### Path Normalization

```moonbit
// Complex path normalization
let paths = [
  "/a/b/c/./../../g",    // -> "/a/g"
  "/../g",               // -> "/g"
  "/./g",                // -> "/g"
  "g.",                  // -> "g." (no change)
  "../../../g"           // -> "g"
]

for path in paths {
  let normalized = remove_dot_segments(path)
  println(path + " -> " + normalized)
}
```

## 🎯 Error Handling

### Comprehensive Error Types

```moonbit
// Different error scenarios
let test_uris = [
  "123://invalid-scheme.com",    // Invalid scheme
  "http://example.com:99999",    // Invalid port
  "",                            // Empty URI
  "http://[invalid-ipv6",        // Malformed IPv6
  "http://example.com:abc"       // Non-numeric port
]

for uri_str in test_uris {
  match Uri::parse(uri_str) {
    Ok(uri) => println("Parsed: " + uri.to_string())
    Err(error) => {
      match error {
        InvalidScheme(msg) => println("Scheme error: " + msg)
        InvalidPort(msg) => println("Port error: " + msg)
        ParseError(msg) => println("Parse error: " + msg)
        InvalidCharacter(msg) => println("Character error: " + msg)
        _ => println("Other error: " + error.to_string())
      }
    }
  }
}
```

### Validation

```moonbit
let uri = Uri::parse("https://example.com/path?query=value").unwrap()

// Validate the URI
match uri.validate() {
  Ok(_) => println("URI is valid")
  Err(error) => println("Validation failed: " + error.to_string())
}

// Builder validation
let result = UriBuilder::new()
  .scheme("https")
  .host("example.com")
  .port(99999)  // Invalid port
  .validate(true)  // Enable validation
  .build()

match result {
  Ok(uri) => println("Built: " + uri.to_string())
  Err(error) => println("Build failed: " + error.to_string())
}
```

## 🔧 Advanced Usage

### Custom Builder Options

```moonbit
// Create builder with custom options
let options = {
  query_encoding: QueryEncoding::FormUrlEncoded,
  normalize_path: true,
  validate: true,
  remove_default_ports: true
}

let builder = UriBuilder::with_options(options)
  .scheme("https")
  .host("example.com")
  .port(443)  // Will be removed (default HTTPS port)
  .path_segment("api")
  .path_segment("..")  // Will be normalized out
  .path_segment("v1")
  .query_param("search", "hello world")  // Form-encoded

match builder.build_string() {
  Ok(uri) => println(uri) // "https://example.com/v1?search=hello+world"
  Err(e) => println("Error: " + e.to_string())
}
```

### URI Manipulation

```moonbit
// Start with an existing URI
let original = Uri::parse("https://api.example.com:8080/v1/users?limit=10").unwrap()

// Create a modified version using the builder
let modified = UriBuilder::from_uri(original)
  .port(443)  // Change port
  .path_segment("posts")  // Add path segment
  .query_param("format", "json")  // Add query parameter
  .remove_query_param("limit")  // Remove existing parameter
  .build_string()
  .unwrap()

println("Original: " + original.to_string())
println("Modified: " + modified)
```

### URI Utilities

```moonbit
// Check if one URI is a subpath of another
let parent = Uri::parse("https://example.com/api/v1").unwrap()
let child = Uri::parse("https://example.com/api/v1/users/123").unwrap()
let unrelated = Uri::parse("https://other.com/api/v1/test").unwrap()

println("Is subpath: " + is_subpath(parent, child).to_string())     // true
println("Is subpath: " + is_subpath(parent, unrelated).to_string()) // false

// Join URIs easily
match join_uri("https://example.com/base/", "../other/file.html") {
  Ok(joined) => println("Joined: " + joined) // "https://example.com/other/file.html"
  Err(e) => println("Join error: " + e)
}
```

## 📚 API Reference

### Core Types

- `Uri` - Represents a parsed URI with all components
- `Authority` - Represents the authority component (userinfo, host, port)
- `UriError` - Error types for parsing and validation failures
- `UriBuilder` - Fluent builder for constructing URIs

### Main Functions

#### Uri Methods
- `Uri::parse(String) -> Result[Uri, UriError]` - Parse URI from string
- `uri.scheme() -> String` - Get scheme component
- `uri.host() -> String?` - Get host component
- `uri.port() -> Int?` - Get port component
- `uri.default_port() -> Int?` - Get default port for scheme
- `uri.effective_port() -> Int?` - Get port or default port
- `uri.userinfo() -> String?` - Get userinfo component
- `uri.path() -> String` - Get path component
- `uri.query() -> String?` - Get query component
- `uri.fragment() -> String?` - Get fragment component
- `uri.filename() -> String?` - Extract filename from path
- `uri.file_extension() -> String?` - Extract file extension
- `uri.parent_path() -> String` - Get parent directory path
- `uri.is_absolute() -> Bool` - Check if URI is absolute
- `uri.is_relative() -> Bool` - Check if URI is relative
- `uri.has_authority() -> Bool` - Check if URI has authority
- `uri.has_absolute_path() -> Bool` - Check if path is absolute
- `uri.has_empty_path() -> Bool` - Check if path is empty
- `uri.equals_normalized(Uri) -> Bool` - Compare normalized URIs
- `uri.normalize() -> Uri` - Get normalized URI
- `uri.validate() -> Result[Unit, UriError]` - Validate URI
- `uri.to_string() -> String` - Convert to string representation

#### UriBuilder Methods
- `UriBuilder::new() -> UriBuilder` - Create new builder
- `UriBuilder::with_options(BuilderOptions) -> UriBuilder` - Create builder with options
- `UriBuilder::from_uri(Uri) -> UriBuilder` - Create builder from existing URI
- `UriBuilder::from_string(String) -> Result[UriBuilder, UriError]` - Create builder from URI string
- `builder.scheme(String) -> UriBuilder` - Set scheme
- `builder.host(String) -> UriBuilder` - Set host
- `builder.port(Int) -> UriBuilder` - Set port
- `builder.userinfo(String) -> UriBuilder` - Set userinfo
- `builder.credentials(String, String) -> UriBuilder` - Set username and password
- `builder.path(String) -> UriBuilder` - Set complete path
- `builder.path_segment(String) -> UriBuilder` - Add path segment
- `builder.path_segments(Array[String]) -> UriBuilder` - Add multiple path segments
- `builder.clear_path() -> UriBuilder` - Clear all path segments
- `builder.query_param(String, String) -> UriBuilder` - Add query parameter
- `builder.query_params(Array[(String, String)]) -> UriBuilder` - Add multiple query parameters
- `builder.query_param_if_not_empty(String, String) -> UriBuilder` - Add parameter if value not empty
- `builder.query_param_bool(String, Bool) -> UriBuilder` - Add boolean parameter
- `builder.remove_query_param(String) -> UriBuilder` - Remove query parameter
- `builder.clear_query_params() -> UriBuilder` - Clear all query parameters
- `builder.query_encoding(QueryEncoding) -> UriBuilder` - Set query encoding method
- `builder.fragment(String) -> UriBuilder` - Set fragment
- `builder.build() -> Result[Uri, UriError]` - Build URI
- `builder.build_string() -> Result[String, UriError]` - Build URI string
- `builder.clone() -> UriBuilder` - Clone builder

#### Percent Encoding
- `percent_encode(String, EncodeSet) -> String` - Encode string
- `percent_decode(String) -> Result[String, String]` - Decode string
- `encode_query_param(String) -> String` - Form-encode parameter
- `decode_query_param(String) -> Result[String, String]` - Form-decode parameter

#### Reference Resolution
- `resolve_reference(Uri, Uri) -> Result[Uri, UriError]` - Resolve reference
- `ReferenceResolver::new(Uri) -> Result[ReferenceResolver, UriError]` - Create resolver
- `resolver.resolve(String) -> Result[Uri, UriError]` - Resolve single reference
- `resolver.resolve_batch(Array[String]) -> Array[Result[Uri, UriError]]` - Resolve multiple references
- `remove_dot_segments(String) -> String` - Normalize path
- `join_uri(String, String) -> Result[String, UriError]` - Join base URI with reference

#### Convenience Constructors
- `http_url(String, String) -> UriBuilder` - Create HTTP URL builder
- `https_url(String, String) -> UriBuilder` - Create HTTPS URL builder
- `ftp_url(String, String) -> UriBuilder` - Create FTP URL builder
- `file_uri(String) -> UriBuilder` - Create file URI builder
- `mailto_uri(String) -> UriBuilder` - Create mailto URI builder

## 📁 Project Structure

```
moonbit-uri/
├── moon.mod.json      # Project configuration
├── README.md          # Project documentation
├── README_zh_CN.md    # Chinese documentation  
├── LICENSE            # MIT License
└── src/               # Source code directory
    ├── uri.mbt                 # Core URI parsing and manipulation
    ├── uri_builder.mbt         # Fluent builder pattern implementation
    ├── percent_encoding.mbt    # RFC 3986 percent encoding/decoding
    ├── reference_resolution.mbt # RFC 3986 reference resolution
    └── uri_test.mbt           # Comprehensive test suite
```

## 🧪 Testing & Quality

The library includes a comprehensive test suite with **90%+ code coverage**, covering:

- **89 test cases** ensuring RFC 3986 compliance
- Edge cases and error conditions  
- Performance scenarios
- Real-world usage patterns
- All major functions and error paths

### Test Coverage by Module
- `reference_resolution.mbt`: 92% coverage
- `uri_builder.mbt`: 92% coverage  
- `percent_encoding.mbt`: 87% coverage
- `uri.mbt`: 87% coverage

Run tests with:
```bash
moon test --target wasm-gc --enable-coverage
```

## 📖 Standards Compliance

This library implements:
- **RFC 3986** - Uniform Resource Identifier (URI): Generic Syntax
- **RFC 3987** - Internationalized Resource Identifiers (IRIs) - Partial support
- **HTML Living Standard** - URL API compatibility where applicable

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.