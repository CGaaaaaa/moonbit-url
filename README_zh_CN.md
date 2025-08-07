# MoonBit URI 库

[English](README.md) | **简体中文**

一个全面且符合 RFC 3986 标准的 MoonBit URI 解析和操作库，提供高级 URI 操作、百分号编码、引用解析等丰富功能。

## ✨ 特性

### 🔍 **完整的 URI 解析**
- **RFC 3986 兼容**: 严格遵循 URI 标准
- **完整组件支持**: 解析 scheme、authority（userinfo、host、port）、path、query 和 fragment
- **IPv6 支持**: 处理 authority 部分的 IPv6 地址
- **验证功能**: 全面的 URI 验证和详细错误信息

### 🛠️ **高级 URI 操作**
- **规范化**: 自动路径规范化和大小写不敏感比较
- **组件访问**: 便捷访问 URI 组件的辅助方法
- **文件操作**: 提取文件名、扩展名和父路径
- **端口处理**: 常见协议（HTTP、HTTPS、FTP等）的默认端口检测

### 🔗 **引用解析**
- **相对引用**: 完整的 RFC 3986 引用解析算法
- **基础 URI 支持**: 基于基础 URI 解析相对 URI
- **点段移除**: 正确处理路径中的 `.` 和 `..`
- **批量操作**: 高效解析多个引用

### 🏗️ **强大的构建器模式**
- **流畅 API**: 链式方法调用，直观的 URI 构建
- **路径段**: 添加单独路径段，自动编码
- **查询参数**: 灵活的查询参数管理
- **编码选项**: 多种编码策略（百分号、表单编码、无编码）
- **验证**: 构建过程中的内置验证

### 🔐 **百分号编码**
- **多种上下文**: 组件、查询、路径段和用户信息编码
- **RFC 兼容**: 根据 RFC 3986 进行正确的编码/解码
- **自定义编码集**: 定义自定义字符集进行编码
- **验证**: 验证百分号编码的字符串
- **表单编码**: 支持 application/x-www-form-urlencoded

### 🎯 **错误处理**
- **详细错误**: 针对不同失败模式的特定错误类型
- **验证**: 运行时验证和清晰的错误信息
- **恢复**: 优雅处理格式错误的 URI

## 🚀 快速开始

### 基础 URI 解析

```moonbit
// 解析完整的 URI
let uri_result = Uri::parse("https://user:pass@example.com:8080/path?query=value#fragment")

match uri_result {
  Ok(uri) => {
    println("协议: " + uri.scheme())
    println("主机: " + uri.host().unwrap_or("无"))
    println("端口: " + uri.port().map(Int::to_string).unwrap_or("默认"))
    println("路径: " + uri.path())
    println("查询: " + uri.query().unwrap_or("无"))
    println("片段: " + uri.fragment().unwrap_or("无"))
  }
  Err(error) => println("解析错误: " + error.to_string())
}
```

### 高级 URI 组件访问

```moonbit
let uri = Uri::parse("https://api.example.com:8443/users/123/posts/456.json?format=json#comments").unwrap()

// 组件访问
println("协议: " + uri.scheme())                    // "https"
println("主机: " + uri.host().unwrap())             // "api.example.com"
println("有效端口: " + uri.effective_port().unwrap().to_string()) // "8443"
println("默认端口: " + uri.default_port().unwrap().to_string())   // "443"

// 文件操作
println("文件名: " + uri.filename().unwrap())       // "456.json"
println("扩展名: " + uri.file_extension().unwrap()) // "json"
println("父路径: " + uri.parent_path())             // "/users/123/posts"

// 状态检查
println("是绝对URI: " + uri.is_absolute().to_string()) // "true"
println("有权威部分: " + uri.has_authority().to_string()) // "true"
```

### URI 规范化和比较

```moonbit
let uri1 = Uri::parse("HTTP://Example.COM:80/path/../file.html").unwrap()
let uri2 = Uri::parse("http://example.com/file.html").unwrap()

// 原始比较
println("相等(原始): " + (uri1.to_string() == uri2.to_string()).to_string()) // "false"

// 规范化比较
println("相等(规范化): " + uri1.equals_normalized(uri2).to_string()) // "true"

// 显式规范化
let normalized = uri1.normalize()
println("规范化后: " + normalized.to_string()) // "http://example.com/file.html"
```

## 🏗️ 构建器模式

### 基础 URI 构建

```moonbit
// 流畅地构建 URI
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
  Err(e) => println("构建错误: " + e.to_string())
}
```

### 高级构建器功能

```moonbit
// 路径段和高级查询参数
let builder = UriBuilder::new()
  .scheme("https")
  .host("api.example.com")
  .path_segment("api")
  .path_segment("v2")
  .path_segment("users")
  .path_segment("123")
  .query_param("include", "profile,posts")
  .query_param_bool("active_only", true)     // 添加 "active_only"（无值）
  .query_param_bool("include_deleted", false) // 跳过
  .query_param_if_not_empty("optional", "")    // 跳过（空值）
  .query_param_if_not_empty("category", "tech") // 添加

let uri = builder.build_string().unwrap()
println(uri) // "https://api.example.com/api/v2/users/123?include=profile,posts&active_only&category=tech"
```

### 认证信息和高级权威部分

```moonbit
// 带认证信息的 URI
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

### 便捷构造函数

```moonbit
// HTTP/HTTPS 快捷方式
let api_url = https_url("api.example.com", "/v1/data")
  .query_param("format", "json")
  .build_string()
  .unwrap()

// 文件 URI
let file_path = file_uri("/home/user/documents/file.pdf")
  .build_string()
  .unwrap()
println(file_path) // "file:///home/user/documents/file.pdf"

// 邮件 URI
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

## 🔐 百分号编码

### 基础编码/解码

```moonbit
// 组件编码
let encoded = percent_encode("hello world/path", Component)
println(encoded) // "hello%20world/path"（空格编码，斜杠保留）

// 查询参数编码（表单样式）
let query_encoded = encode_query_param("hello world+test&more")
println(query_encoded) // "hello+world%2Btest%26more"

// 解码
match percent_decode("hello%20world") {
  Ok(decoded) => println(decoded) // "hello world"
  Err(e) => println("解码错误: " + e)
}

match decode_query_param("hello+world%26test") {
  Ok(decoded) => println(decoded) // "hello world&test"
  Err(e) => println("解码错误: " + e)
}
```

### 编码验证

```moonbit
// 验证百分号编码的字符串
match validate_percent_encoded("hello%20world%2Fpath") {
  Ok(_) => println("有效编码")
  Err(e) => println("无效: " + e)
}

// 检查无效序列
match validate_percent_encoded("hello%ZZ") {
  Ok(_) => println("有效")
  Err(e) => println("无效: " + e) // "Invalid percent encoding: non-hex characters at position 5"
}
```

### 构建器中的自定义编码

```moonbit
// 不同的编码策略
let builder = UriBuilder::new()
  .scheme("https")
  .host("example.com")
  .path("/search")
  .query_param("q", "hello world & more")
  .query_encoding(QueryEncoding::FormUrlEncoded) // 使用表单编码

let uri1 = builder.build_string().unwrap()
println(uri1) // 空格变为 '+'，'&' 变为 '%26'

// 切换到百分号编码
let uri2 = builder.query_encoding(QueryEncoding::Percent)
  .build_string()
  .unwrap()
println(uri2) // 空格变为 '%20'，'&' 变为 '%26'
```

## 🔗 引用解析

### 基础引用解析

```moonbit
// 基础 URI
let base = Uri::parse("http://example.com/dir/file.html").unwrap()

// 解析相对引用
let refs = [
  "page2.html",          // 相对于当前目录
  "../other/page.html",  // 父目录
  "/absolute/path.html", // 绝对路径
  "./current/page.html"  // 明确的当前目录
]

for ref_str in refs {
  let reference = Uri::parse(ref_str).unwrap()
  match resolve_reference(base, reference) {
    Ok(resolved) => println(ref_str + " -> " + resolved.to_string())
    Err(e) => println("解析错误: " + e.to_string())
  }
}

// 输出:
// page2.html -> http://example.com/dir/page2.html
// ../other/page.html -> http://example.com/other/page.html
// /absolute/path.html -> http://example.com/absolute/path.html
// ./current/page.html -> http://example.com/dir/current/page.html
```

### 引用解析器

```moonbit
// 为批量操作创建引用解析器
let base = Uri::parse("https://api.example.com/v1/users/123").unwrap()

match ReferenceResolver::new(base) {
  Ok(resolver) => {
    // 解析单个引用
    match resolver.resolve("posts/456") {
      Ok(resolved) => println(resolved.to_string()) // "https://api.example.com/v1/users/123/posts/456"
      Err(e) => println("错误: " + e.to_string())
    }
    
    // 批量解析
    let references = ["posts", "../456/comments", "/admin/users"]
    let results = resolver.resolve_batch(references)
    
    for result in results {
      match result {
        Ok(uri) => println("已解析: " + uri.to_string())
        Err(e) => println("失败: " + e.to_string())
      }
    }
  }
  Err(e) => println("解析器错误: " + e.to_string())
}
```

### 路径规范化

```moonbit
// 复杂路径规范化
let paths = [
  "/a/b/c/./../../g",    // -> "/a/g"
  "/../g",               // -> "/g"
  "/./g",                // -> "/g"
  "g.",                  // -> "g."（无变化）
  "../../../g"           // -> "g"
]

for path in paths {
  let normalized = remove_dot_segments(path)
  println(path + " -> " + normalized)
}
```

## 🎯 错误处理

### 全面的错误类型

```moonbit
// 不同的错误场景
let test_uris = [
  "123://invalid-scheme.com",    // 无效协议
  "http://example.com:99999",    // 无效端口
  "",                            // 空 URI
  "http://[invalid-ipv6",        // 格式错误的 IPv6
  "http://example.com:abc"       // 非数字端口
]

for uri_str in test_uris {
  match Uri::parse(uri_str) {
    Ok(uri) => println("已解析: " + uri.to_string())
    Err(error) => {
      match error {
        InvalidScheme(msg) => println("协议错误: " + msg)
        InvalidPort(msg) => println("端口错误: " + msg)
        ParseError(msg) => println("解析错误: " + msg)
        InvalidCharacter(msg) => println("字符错误: " + msg)
        _ => println("其他错误: " + error.to_string())
      }
    }
  }
}
```

### 验证

```moonbit
let uri = Uri::parse("https://example.com/path?query=value").unwrap()

// 验证 URI
match uri.validate() {
  Ok(_) => println("URI 有效")
  Err(error) => println("验证失败: " + error.to_string())
}

// 构建器验证
let result = UriBuilder::new()
  .scheme("https")
  .host("example.com")
  .port(99999)  // 无效端口
  .validate(true)  // 启用验证
  .build()

match result {
  Ok(uri) => println("构建成功: " + uri.to_string())
  Err(error) => println("构建失败: " + error.to_string())
}
```

## 🔧 高级用法

### 自定义构建器选项

```moonbit
// 使用自定义选项创建构建器
let options = {
  query_encoding: QueryEncoding::FormUrlEncoded,
  normalize_path: true,
  validate: true,
  remove_default_ports: true
}

let builder = UriBuilder::with_options(options)
  .scheme("https")
  .host("example.com")
  .port(443)  // 将被移除（默认 HTTPS 端口）
  .path_segment("api")
  .path_segment("..")  // 将被规范化移除
  .path_segment("v1")
  .query_param("search", "hello world")  // 表单编码

match builder.build_string() {
  Ok(uri) => println(uri) // "https://example.com/v1?search=hello+world"
  Err(e) => println("错误: " + e.to_string())
}
```

### URI 操作

```moonbit
// 从现有 URI 开始
let original = Uri::parse("https://api.example.com:8080/v1/users?limit=10").unwrap()

// 使用构建器创建修改版本
let modified = UriBuilder::from_uri(original)
  .port(443)  // 更改端口
  .path_segment("posts")  // 添加路径段
  .query_param("format", "json")  // 添加查询参数
  .remove_query_param("limit")  // 移除现有参数
  .build_string()
  .unwrap()

println("原始: " + original.to_string())
println("修改后: " + modified)
```

### URI 实用工具

```moonbit
// 检查一个 URI 是否是另一个的子路径
let parent = Uri::parse("https://example.com/api/v1").unwrap()
let child = Uri::parse("https://example.com/api/v1/users/123").unwrap()
let unrelated = Uri::parse("https://other.com/api/v1/test").unwrap()

println("是子路径: " + is_subpath(parent, child).to_string())     // true
println("是子路径: " + is_subpath(parent, unrelated).to_string()) // false

// 轻松连接 URI
match join_uri("https://example.com/base/", "../other/file.html") {
  Ok(joined) => println("连接后: " + joined) // "https://example.com/other/file.html"
  Err(e) => println("连接错误: " + e)
}
```

## 📚 API 参考

### 核心类型

- `Uri` - 表示解析后的 URI，包含所有组件
- `Authority` - 表示权威组件（userinfo、host、port）
- `UriError` - 解析和验证失败的错误类型
- `UriBuilder` - 用于构建 URI 的流畅构建器

### 主要函数

#### Uri 方法
- `Uri::parse(String) -> Result[Uri, UriError]` - 从字符串解析 URI
- `uri.scheme() -> String` - 获取协议组件
- `uri.host() -> String?` - 获取主机组件
- `uri.port() -> Int?` - 获取端口组件
- `uri.default_port() -> Int?` - 获取协议的默认端口
- `uri.effective_port() -> Int?` - 获取端口或默认端口
- `uri.userinfo() -> String?` - 获取用户信息组件
- `uri.path() -> String` - 获取路径组件
- `uri.query() -> String?` - 获取查询组件
- `uri.fragment() -> String?` - 获取片段组件
- `uri.filename() -> String?` - 从路径提取文件名
- `uri.file_extension() -> String?` - 提取文件扩展名
- `uri.parent_path() -> String` - 获取父目录路径
- `uri.is_absolute() -> Bool` - 检查是否为绝对 URI
- `uri.is_relative() -> Bool` - 检查是否为相对 URI
- `uri.has_authority() -> Bool` - 检查是否有权威部分
- `uri.has_absolute_path() -> Bool` - 检查路径是否为绝对路径
- `uri.has_empty_path() -> Bool` - 检查路径是否为空
- `uri.equals_normalized(Uri) -> Bool` - 比较规范化的 URI
- `uri.normalize() -> Uri` - 获取规范化的 URI
- `uri.validate() -> Result[Unit, UriError]` - 验证 URI
- `uri.to_string() -> String` - 转换为字符串表示

#### UriBuilder 方法
- `UriBuilder::new() -> UriBuilder` - 创建新构建器
- `UriBuilder::with_options(BuilderOptions) -> UriBuilder` - 使用选项创建构建器
- `UriBuilder::from_uri(Uri) -> UriBuilder` - 从现有 URI 创建构建器
- `UriBuilder::from_string(String) -> Result[UriBuilder, UriError]` - 从 URI 字符串创建构建器
- `builder.scheme(String) -> UriBuilder` - 设置协议
- `builder.host(String) -> UriBuilder` - 设置主机
- `builder.port(Int) -> UriBuilder` - 设置端口
- `builder.userinfo(String) -> UriBuilder` - 设置用户信息
- `builder.credentials(String, String) -> UriBuilder` - 设置用户名和密码
- `builder.path(String) -> UriBuilder` - 设置完整路径
- `builder.path_segment(String) -> UriBuilder` - 添加路径段
- `builder.path_segments(Array[String]) -> UriBuilder` - 添加多个路径段
- `builder.clear_path() -> UriBuilder` - 清除所有路径段
- `builder.query_param(String, String) -> UriBuilder` - 添加查询参数
- `builder.query_params(Array[(String, String)]) -> UriBuilder` - 添加多个查询参数
- `builder.query_param_if_not_empty(String, String) -> UriBuilder` - 添加非空参数
- `builder.query_param_bool(String, Bool) -> UriBuilder` - 添加布尔参数
- `builder.remove_query_param(String) -> UriBuilder` - 移除查询参数
- `builder.clear_query_params() -> UriBuilder` - 清除所有查询参数
- `builder.query_encoding(QueryEncoding) -> UriBuilder` - 设置查询编码方式
- `builder.fragment(String) -> UriBuilder` - 设置片段
- `builder.build() -> Result[Uri, UriError]` - 构建 URI
- `builder.build_string() -> Result[String, UriError]` - 构建 URI 字符串
- `builder.clone() -> UriBuilder` - 克隆构建器

#### 百分号编码
- `percent_encode(String, EncodeSet) -> String` - 编码字符串
- `percent_decode(String) -> Result[String, String]` - 解码字符串
- `encode_query_param(String) -> String` - 表单编码参数
- `decode_query_param(String) -> Result[String, String]` - 表单解码参数

#### 引用解析
- `resolve_reference(Uri, Uri) -> Result[Uri, UriError]` - 解析引用
- `ReferenceResolver::new(Uri) -> Result[ReferenceResolver, UriError]` - 创建解析器
- `resolver.resolve(String) -> Result[Uri, UriError]` - 解析单个引用
- `resolver.resolve_batch(Array[String]) -> Array[Result[Uri, UriError]]` - 批量解析引用
- `remove_dot_segments(String) -> String` - 规范化路径
- `join_uri(String, String) -> Result[String, UriError]` - 连接基础 URI 和引用

#### 便捷构造函数
- `http_url(String, String) -> UriBuilder` - 创建 HTTP URL 构建器
- `https_url(String, String) -> UriBuilder` - 创建 HTTPS URL 构建器
- `ftp_url(String, String) -> UriBuilder` - 创建 FTP URL 构建器
- `file_uri(String) -> UriBuilder` - 创建文件 URI 构建器
- `mailto_uri(String) -> UriBuilder` - 创建邮件 URI 构建器

## 📁 项目结构

```
moonbit-uri/
├── moon.mod.json      # 项目配置
├── README.md          # 项目文档
├── README_zh_CN.md    # 中文文档
├── LICENSE            # MIT 许可证
└── src/               # 源代码目录
    ├── uri.mbt                 # 核心 URI 解析和操作
    ├── uri_builder.mbt         # 流畅构建器模式实现
    ├── percent_encoding.mbt    # RFC 3986 百分号编码/解码
    ├── reference_resolution.mbt # RFC 3986 引用解析
    └── uri_test.mbt           # 全面测试套件
```

## 🧪 测试与质量

该库包含全面的测试套件，**代码覆盖率达90%+**，涵盖：

- **89个测试用例** 确保 RFC 3986 兼容性
- 边界情况和错误条件
- 性能场景  
- 实际使用模式
- 所有主要功能和错误路径

### 模块测试覆盖率
- `reference_resolution.mbt`: 92% 覆盖率
- `uri_builder.mbt`: 92% 覆盖率
- `percent_encoding.mbt`: 87% 覆盖率
- `uri.mbt`: 87% 覆盖率

运行测试：
```bash
moon test --target wasm-gc --enable-coverage
```

## 📖 标准兼容性

该库实现：
- **RFC 3986** - 统一资源标识符（URI）：通用语法
- **RFC 3987** - 国际化资源标识符（IRI）- 部分支持
- **HTML 活动标准** - URL API 兼容性（适用时）

## 🤝 贡献

欢迎贡献！请随时提交问题和拉取请求。

## 📄 许可证

该项目基于 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。