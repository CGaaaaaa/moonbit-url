# MoonBit URI Library

English | [简体中文](README_zh_CN.md)

A comprehensive URI parsing and manipulation library for MoonBit, implementing RFC 3986 with additional utilities for modern web development.

## Features

### Core Functionality
- ✅ **RFC 3986 Compliant** - Full URI parsing and validation
- ✅ **Builder Pattern** - Fluent API for URI construction
- ✅ **Error Handling** - Comprehensive error reporting
- ✅ **Authority Support** - Complete authority component handling
- ✅ **Query Parameters** - Easy query string manipulation

### Advanced Features (Coming Soon)
- 🔄 **URL Encoding/Decoding** - Percent encoding support
- 🔄 **Path Normalization** - Clean and resolve path segments
- 🔄 **Relative URI Resolution** - Resolve relative URIs against base URIs
- 🔄 **Query Parameter Parsing** - Parse and manipulate query strings
- 🔄 **Validation** - Strict URI component validation

## Quick Start

### Basic URI Parsing

```moonbit
// Parse a URI
let uri_result = Uri::parse("https://user:pass@example.com:8080/path?query=value#fragment")

match uri_result {
  Ok(uri) => {
    println("Scheme: " + uri.scheme)
    println("Host: " + uri.authority?.host ?? "none")
    println("Path: " + uri.path)
    println("Query: " + uri.query ?? "none")
  }
  Err(error) => println("Parse error: " + error.to_string())
}
```

### Using the Builder Pattern

```moonbit
// Build a URI fluently
let uri = UriBuilder::new()
  .scheme("https")
  .host("api.example.com")
  .port(443)
  .path("/v1/users")
  .query_param("limit", "10")
  .query_param("page", "1")
  .fragment("section1")
  .build()

match uri {
  Ok(u) => println(u.to_string())  // https://api.example.com:443/v1/users?limit=10&page=1#section1
  Err(e) => println("Build error: " + e.to_string())
}
```

### Quick HTTP/HTTPS URLs

```moonbit
// Quick HTTP URL creation
let http_uri = http_url("example.com", "/api/data")
  .query_param("format", "json")
  .build()

// Quick HTTPS URL creation  
let https_uri = https_url("secure.example.com", "/auth/login")
  .port(8443)
  .build()
```

## API Reference

### Core Types

#### `Uri`
Main URI structure containing all components:
- `scheme: String` - URI scheme (http, https, ftp, etc.)
- `authority: Authority?` - Authority component (optional)
- `path: String` - Path component
- `query: String?` - Query string (optional)
- `fragment: String?` - Fragment identifier (optional)

#### `Authority`
Authority component structure:
- `userinfo: String?` - User information (optional)
- `host: String` - Host name or IP address
- `port: Int?` - Port number (optional)

#### `UriError`
Error types for URI operations:
- `InvalidScheme(String)` - Invalid scheme format
- `InvalidPort(String)` - Invalid port number
- `ParseError(String)` - General parsing errors

### Methods

#### `Uri::parse(input: String) -> Result[Uri, UriError]`
Parse a URI string into a Uri structure.

#### `Uri::to_string(self) -> String`
Convert a Uri back to its string representation.

#### `UriBuilder::new() -> UriBuilder`
Create a new URI builder instance.

#### Builder Methods
- `scheme(scheme: String) -> UriBuilder`
- `host(host: String) -> UriBuilder`
- `port(port: Int) -> UriBuilder`
- `userinfo(userinfo: String) -> UriBuilder`
- `path(path: String) -> UriBuilder`
- `query_param(key: String, value: String) -> UriBuilder`
- `fragment(fragment: String) -> UriBuilder`
- `build() -> Result[Uri, UriError]`

## Examples

### Complex URI Parsing

```moonbit
let complex_uri = "ftp://user:password@ftp.example.com:21/files/document.pdf?version=latest#page2"
let result = Uri::parse(complex_uri)

match result {
  Ok(uri) => {
    // Access components
    println("Scheme: " + uri.scheme)                    // "ftp"
    println("User: " + uri.authority?.userinfo ?? "")   // "user:password"
    println("Host: " + uri.authority?.host ?? "")       // "ftp.example.com"
    println("Port: " + (uri.authority?.port?.to_string() ?? "")) // "21"
    println("Path: " + uri.path)                        // "/files/document.pdf"
    println("Query: " + uri.query ?? "")                // "version=latest"
    println("Fragment: " + uri.fragment ?? "")          // "page2"
  }
  Err(e) => println("Error: " + e.to_string())
}
```

### Building REST API URLs

```moonbit
// Build REST API endpoint
let api_uri = UriBuilder::new()
  .scheme("https")
  .host("api.github.com")
  .path("/repos/owner/repo/issues")
  .query_param("state", "open")
  .query_param("labels", "bug,priority:high")
  .query_param("sort", "created")
  .query_param("direction", "desc")
  .build()

// Result: https://api.github.com/repos/owner/repo/issues?state=open&labels=bug,priority:high&sort=created&direction=desc
```

### Working with Different Schemes

```moonbit
// Database connection URI
let db_uri = UriBuilder::new()
  .scheme("postgresql")
  .userinfo("user:password")
  .host("localhost")
  .port(5432)
  .path("/mydb")
  .build()

// File URI
let file_uri = UriBuilder::new()
  .scheme("file")
  .path("/home/user/documents/file.txt")
  .build()

// WebSocket URI
let ws_uri = UriBuilder::new()
  .scheme("wss")
  .host("realtime.example.com")
  .path("/chat")
  .query_param("room", "general")
  .build()
```

## Installation

Add this library to your MoonBit project:

```json
{
  "deps": {
    "moonbit-uri": "github:username/moonbit-uri"
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Roadmap

- [ ] URL encoding/decoding (percent encoding)
- [ ] Path normalization and resolution
- [ ] Relative URI resolution (RFC 3986 Section 5)
- [ ] Query parameter utilities
- [ ] International domain name support
- [ ] Performance optimizations
- [ ] Extended validation options

## Related Standards

- [RFC 3986](https://tools.ietf.org/html/rfc3986) - Uniform Resource Identifier (URI): Generic Syntax
- [RFC 3987](https://tools.ietf.org/html/rfc3987) - Internationalized Resource Identifiers (IRIs)
- [WHATWG URL Standard](https://url.spec.whatwg.org/) - Modern URL specification