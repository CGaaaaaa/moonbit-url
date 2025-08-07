# MoonBit URI 库

[English](README.md) | 简体中文

一个全面的 URI 解析和操作库，专为 MoonBit 设计，实现 RFC 3986 标准，并提供现代 Web 开发所需的实用工具。

## 功能特性

### 核心功能
- ✅ **符合 RFC 3986 标准** - 完整的 URI 解析和验证
- ✅ **构建器模式** - 流畅的 API 用于 URI 构造
- ✅ **错误处理** - 全面的错误报告机制
- ✅ **权限组件支持** - 完整的权限组件处理
- ✅ **查询参数** - 便捷的查询字符串操作

### 高级功能（即将推出）
- 🔄 **URL 编码/解码** - 百分号编码支持
- 🔄 **路径规范化** - 清理和解析路径段
- 🔄 **相对 URI 解析** - 相对于基础 URI 解析相对 URI
- 🔄 **查询参数解析** - 解析和操作查询字符串
- 🔄 **验证** - 严格的 URI 组件验证

## 快速开始

### 基础 URI 解析

```moonbit
// 解析 URI
let uri_result = Uri::parse("https://user:pass@example.com:8080/path?query=value#fragment")

match uri_result {
  Ok(uri) => {
    println("协议: " + uri.scheme)
    println("主机: " + uri.authority?.host ?? "无")
    println("路径: " + uri.path)
    println("查询: " + uri.query ?? "无")
  }
  Err(error) => println("解析错误: " + error.to_string())
}
```

### 使用构建器模式

```moonbit
// 流畅地构建 URI
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
  Err(e) => println("构建错误: " + e.to_string())
}
```

### 快速 HTTP/HTTPS URL 创建

```moonbit
// 快速创建 HTTP URL
let http_uri = http_url("example.com", "/api/data")
  .query_param("format", "json")
  .build()

// 快速创建 HTTPS URL
let https_uri = https_url("secure.example.com", "/auth/login")
  .port(8443)
  .build()
```

## API 参考

### 核心类型

#### `Uri`
包含所有组件的主要 URI 结构：
- `scheme: String` - URI 协议（http、https、ftp 等）
- `authority: Authority?` - 权限组件（可选）
- `path: String` - 路径组件
- `query: String?` - 查询字符串（可选）
- `fragment: String?` - 片段标识符（可选）

#### `Authority`
权限组件结构：
- `userinfo: String?` - 用户信息（可选）
- `host: String` - 主机名或 IP 地址
- `port: Int?` - 端口号（可选）

#### `UriError`
URI 操作的错误类型：
- `InvalidScheme(String)` - 无效的协议格式
- `InvalidPort(String)` - 无效的端口号
- `ParseError(String)` - 通用解析错误

### 方法

#### `Uri::parse(input: String) -> Result[Uri, UriError]`
将 URI 字符串解析为 Uri 结构。

#### `Uri::to_string(self) -> String`
将 Uri 转换回其字符串表示。

#### `UriBuilder::new() -> UriBuilder`
创建新的 URI 构建器实例。

#### 构建器方法
- `scheme(scheme: String) -> UriBuilder`
- `host(host: String) -> UriBuilder`
- `port(port: Int) -> UriBuilder`
- `userinfo(userinfo: String) -> UriBuilder`
- `path(path: String) -> UriBuilder`
- `query_param(key: String, value: String) -> UriBuilder`
- `fragment(fragment: String) -> UriBuilder`
- `build() -> Result[Uri, UriError]`

## 示例

### 复杂 URI 解析

```moonbit
let complex_uri = "ftp://user:password@ftp.example.com:21/files/document.pdf?version=latest#page2"
let result = Uri::parse(complex_uri)

match result {
  Ok(uri) => {
    // 访问组件
    println("协议: " + uri.scheme)                    // "ftp"
    println("用户: " + uri.authority?.userinfo ?? "")   // "user:password"
    println("主机: " + uri.authority?.host ?? "")       // "ftp.example.com"
    println("端口: " + (uri.authority?.port?.to_string() ?? "")) // "21"
    println("路径: " + uri.path)                        // "/files/document.pdf"
    println("查询: " + uri.query ?? "")                // "version=latest"
    println("片段: " + uri.fragment ?? "")          // "page2"
  }
  Err(e) => println("错误: " + e.to_string())
}
```

### 构建 REST API URL

```moonbit
// 构建 REST API 端点
let api_uri = UriBuilder::new()
  .scheme("https")
  .host("api.github.com")
  .path("/repos/owner/repo/issues")
  .query_param("state", "open")
  .query_param("labels", "bug,priority:high")
  .query_param("sort", "created")
  .query_param("direction", "desc")
  .build()

// 结果: https://api.github.com/repos/owner/repo/issues?state=open&labels=bug,priority:high&sort=created&direction=desc
```

### 使用不同协议

```moonbit
// 数据库连接 URI
let db_uri = UriBuilder::new()
  .scheme("postgresql")
  .userinfo("user:password")
  .host("localhost")
  .port(5432)
  .path("/mydb")
  .build()

// 文件 URI
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

## 安装

将此库添加到您的 MoonBit 项目：

```json
{
  "deps": {
    "moonbit-uri": "github:username/moonbit-uri"
  }
}
```

## 贡献

1. Fork 仓库
2. 创建功能分支
3. 为新功能添加测试
4. 提交拉取请求

## 许可证

此项目使用 MIT 许可证 - 有关详细信息，请参阅 LICENSE 文件。

## 路线图

- [ ] URL 编码/解码（百分号编码）
- [ ] 路径规范化和解析
- [ ] 相对 URI 解析（RFC 3986 第 5 节）
- [ ] 查询参数实用工具
- [ ] 国际化域名支持
- [ ] 性能优化
- [ ] 扩展验证选项

## 相关标准

- [RFC 3986](https://tools.ietf.org/html/rfc3986) - 统一资源标识符 (URI)：通用语法
- [RFC 3987](https://tools.ietf.org/html/rfc3987) - 国际化资源标识符 (IRI)
- [WHATWG URL 标准](https://url.spec.whatwg.org/) - 现代 URL 规范

## 使用场景

### Web 开发
```moonbit
// API 端点构建
let api_endpoint = https_url("api.myservice.com", "/v2/users")
  .query_param("filter", "active")
  .query_param("sort", "name")
  .build()

// OAuth 回调 URL
let oauth_callback = https_url("myapp.com", "/auth/callback")
  .query_param("code", "authorization_code")
  .query_param("state", "random_state")
  .build()
```

### 配置管理
```moonbit
// 数据库连接字符串
let db_config = UriBuilder::new()
  .scheme("mysql")
  .userinfo("user:pass")
  .host("db.example.com")
  .port(3306)
  .path("/production_db")
  .query_param("charset", "utf8mb4")
  .query_param("timeout", "30s")
  .build()
```

### 微服务通信
```moonbit
// 服务发现
let service_url = https_url("service-registry.internal", "/services/user-service")
  .query_param("version", "v1")
  .query_param("region", "us-east-1")
  .build()
```

这个 URI 库设计为既简单易用又功能强大，适合现代 MoonBit 应用程序的各种需求。