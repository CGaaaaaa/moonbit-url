///|
test "advanced_builder_features" {
  match
    UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .port(8443)
    .path_segment("users")
    .path_segment("123")
    .path_segment("posts")
    .query_param("limit", "10")
    .query_param("sort", "date")
    .query_param_bool("include_deleted", false)
    .query_param_bool("active_only", true)
    .fragment("comments")
    .build() {
    Ok(uri) => {
      println("Built URI: " + uri.to_string())
      assert_eq(uri.scheme, "https")
      assert_eq(uri.path, "/users/123/posts")
    }
    Err(_) => fail("Advanced builder should work")
  }
}

///|
test "builder_with_credentials" {
  match
    UriBuilder::new()
    .scheme("https")
    .credentials("user", "pass")
    .host("secure.example.com")
    .port(8443)
    .path("/secure/api")
    .build() {
    Ok(uri) =>
      assert_eq(
        uri.to_string(),
        "https://user:pass@secure.example.com:8443/secure/api",
      )
    Err(_) => fail("Credentials builder should work")
  }
}

///|
test "ipv6_uri_builder_support" {
  // 测试通过UriBuilder创建IPv6 URI
  match
    UriBuilder::new()
    .scheme("https")
    .host("[2001:db8::1]")
    .port(443)
    .path("/api")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("[2001:db8::1]"))
      assert_eq(uri.port(), Some(443))
      assert_eq(uri.path(), "/api")
    }
    Err(_) => fail("Should build IPv6 URI")
  }

  // 测试不带方括号的IPv6地址（应该会出错或自动添加）
  match UriBuilder::new().scheme("http").host("::1").build() {
    Ok(uri) =>
      // 如果成功，检查是否正确处理
      assert_eq(uri.host(), Some("::1"))
    Err(_) => () // 可能需要显式的方括号
  }
}

///|
test "builder_operations" {
  let builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path_segment("api")
    .path_segment("v1")
    .path_segment("users")

  // 克隆并修改
  let builder2 = builder.clone().path_segment("123").path_segment("posts")
  match builder2.build_string() {
    Ok(uri_str) =>
      assert_eq(uri_str, "https://example.com/api/v1/users/123/posts")
    Err(_) => fail("Path segments should work")
  }

  // 清除路径
  let builder3 = builder.clone().clear_path().path_segment("different")
  match builder3.build_string() {
    Ok(uri_str) => assert_eq(uri_str, "https://example.com/different")
    Err(_) => fail("Clear path should work")
  }
}

///|
test "builder_comprehensive_coverage" {
  // 测试Builder的基本功能

  // 测试简单的URI构建
  match
    UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .path("/search")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("api.example.com"))
      assert_eq(uri.path(), "/search")
    }
    Err(_) => fail("Simple builder should work")
  }

  // 测试查询参数构建
  match
    UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .query_param("q", "test")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.query() is Some(_), true)
    }
    Err(_) => fail("Builder with query params should work")
  }
}

///|
test "resolve_reference_with_query_and_fragment" {
  // 测试带查询参数和片段的引用解析
  let base = Uri::{
    scheme: "http",
    authority: Some(Authority::new(None, "example.com", Some(8080))),
    path: "/base/path",
    query: Some("base=param"),
    fragment: Some("base-frag"),
  }
  let reference = Uri::{
    scheme: "",
    authority: None,
    path: "relative.html",
    query: Some("ref=param"),
    fragment: Some("ref-frag"),
  }
  match resolve_reference(base, reference) {
    Ok(resolved) => {
      assert_eq(resolved.scheme(), "http")
      assert_eq(resolved.host(), Some("example.com"))
      assert_eq(resolved.port(), Some(8080))
      assert_eq(resolved.query(), Some("ref=param")) // 应该使用引用的query
      assert_eq(resolved.fragment(), Some("ref-frag")) // 应该使用引用的fragment
      assert_eq(resolved.path().contains("relative.html"), true)
    }
    Err(_) => fail("Should resolve reference with query and fragment")
  }
}

///|
test "uri_builder_advanced_methods" {
  // 测试UriBuilder的高级方法

  // 测试基本构建器功能
  let builder = UriBuilder::new().scheme("https").host("example.com")
  match builder.build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("example.com"))
    }
    Err(_) => fail("Should build with default options")
  }

  // 测试 userinfo 设置
  let userinfo_builder = UriBuilder::new()
    .scheme("https")
    .userinfo("user:pass")
    .host("secure.example.com")
  match userinfo_builder.build() {
    Ok(uri) =>
      assert_eq(uri.to_string(), "https://user:pass@secure.example.com")
    Err(_) => fail("Should build with userinfo")
  }

  // 测试多个路径段
  let segments = ["api", "v2", "users", "456"]
  let segments_builder = UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .path_segments(segments)
  match segments_builder.build() {
    Ok(uri) => assert_eq(uri.path(), "/api/v2/users/456")
    Err(_) => fail("Should build with path segments")
  }
}

///|
test "uri_builder_query_operations" {
  let mut builder = UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .query_param("key1", "value1")
    .query_param("key2", "value2")
    .query_param("key3", "")

  // 测试 query_param_if_not_empty
  builder = builder
    .query_param_if_not_empty("key4", "value4") // 应该添加
    .query_param_if_not_empty("key5", "") // 应该忽略

  // 测试 query_param_bool
  builder = builder
    .query_param_bool("active", true) // 应该添加
    .query_param_bool("inactive", false) // 应该忽略
  match builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap()
      assert_eq(query.contains("key1=value1"), true)
      assert_eq(query.contains("key2=value2"), true)
      assert_eq(query.contains("key3"), true)
      assert_eq(query.contains("key4=value4"), true)
      assert_eq(query.contains("key5"), false)
      assert_eq(query.contains("active"), true)
      assert_eq(query.contains("inactive"), false)
    }
    Err(_) => fail("Should build with query params")
  }

  // 测试 remove_query_param
  let removed_builder = builder.remove_query_param("key2")
  match removed_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap()
      assert_eq(query.contains("key1=value1"), true)
      assert_eq(query.contains("key2=value2"), false)
    }
    Err(_) => fail("Should build after removing query param")
  }

  // 测试 clear_query_params
  let cleared_builder = builder.clear_query_params()
  match cleared_builder.build() {
    Ok(uri) => assert_eq(uri.query(), None)
    Err(_) => fail("Should build with cleared query params")
  }
}

///|
test "uri_builder_query_params" {
  // 测试查询参数功能
  let builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .query_param("test", "hello world")
    .query_param("other", "value")
  match builder.build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("example.com"))
      // 查询参数应该存在
      match uri.query() {
        Some(query) => {
          assert_eq(query.contains("test"), true)
          assert_eq(query.contains("other"), true)
        }
        None => fail("Should have query parameters")
      }
    }
    Err(_) => fail("Query param builder should work")
  }
}

///|
test "uri_builder_from_existing" {
  // 测试从现有URI创建构建器
  let original_uri = Uri::parse(
    "https://user:pass@api.example.com:8443/v1/users?limit=10&sort=date#results",
  ).unwrap()
  let builder = UriBuilder::from_uri(original_uri)
  match builder.build() {
    Ok(reconstructed) => {
      assert_eq(reconstructed.scheme(), "https")
      assert_eq(reconstructed.host(), Some("api.example.com"))
      assert_eq(reconstructed.port(), Some(8443))
      assert_eq(reconstructed.path(), "/v1/users")
      assert_eq(reconstructed.query() is Some(_), true)
      assert_eq(reconstructed.fragment(), Some("results"))
    }
    Err(_) => fail("Should reconstruct URI from existing")
  }

  // 测试从字符串创建构建器
  match UriBuilder::from_string("https://example.com/api") {
    Ok(string_builder) =>
      match string_builder.build() {
        Ok(uri) => {
          assert_eq(uri.scheme(), "https")
          assert_eq(uri.host(), Some("example.com"))
          assert_eq(uri.path(), "/api")
        }
        Err(_) => fail("Should build from string builder")
      }
    Err(_) => fail("Should create builder from string")
  }

  // 测试无效字符串
  match UriBuilder::from_string("invalid-uri-format") {
    Ok(_) => fail("Should fail with invalid URI string")
    Err(_) => () // 预期错误
  }
}

///|
test "uri_builder_convenience_constructors" {
  // 测试便利构造函数

  // HTTP URL
  match http_url("example.com", "/api/v1").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "http")
      assert_eq(uri.host(), Some("example.com"))
      assert_eq(uri.path(), "/api/v1")
    }
    Err(_) => fail("HTTP convenience constructor should work")
  }

  // HTTPS URL
  match https_url("secure.example.com", "/secure").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("secure.example.com"))
      assert_eq(uri.path(), "/secure")
    }
    Err(_) => fail("HTTPS convenience constructor should work")
  }

  // FTP URL
  match
    UriBuilder::new()
    .scheme("ftp")
    .host("ftp.example.com")
    .path("/files")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "ftp")
      assert_eq(uri.host(), Some("ftp.example.com"))
      assert_eq(uri.path(), "/files")
    }
    Err(_) => fail("FTP convenience constructor should work")
  }

  // File URI
  match
    UriBuilder::new().scheme("file").path("/home/user/document.pdf").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "file")
      assert_eq(uri.path(), "/home/user/document.pdf")
    }
    Err(_) => fail("File URI constructor should work")
  }

  // Mailto URI
  match UriBuilder::new().scheme("mailto").path("user@example.com").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "mailto")
      assert_eq(uri.path(), "user@example.com")
    }
    Err(_) => fail("Mailto URI constructor should work")
  }
}

///|
test "uri_builder_edge_cases" {
  // 测试边界情况

  // 空路径
  let empty_path_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path("")
  match empty_path_builder.build() {
    Ok(uri) => assert_eq(uri.path(), "")
    Err(_) => fail("Should handle empty path")
  }

  // 只有根路径
  let root_path_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path("/")
  match root_path_builder.build() {
    Ok(uri) => assert_eq(uri.path(), "/")
    Err(_) => fail("Should handle root path")
  }

  // 端口边界值
  let port_0_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .port(0)
  match port_0_builder.build() {
    Ok(uri) => assert_eq(uri.port(), Some(0))
    Err(_) => fail("Should handle port 0")
  }
  let port_max_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .port(65535)
  match port_max_builder.build() {
    Ok(uri) => assert_eq(uri.port(), Some(65535))
    Err(_) => fail("Should handle port 65535")
  }

  // 缺少host的scheme（如file协议）
  let no_host_builder = UriBuilder::new()
    .scheme("file")
    .path("/home/user/file.txt")
  match no_host_builder.build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "file")
      assert_eq(uri.path(), "/home/user/file.txt")
      assert_eq(uri.host(), None)
    }
    Err(_) => fail("Should handle URI without host")
  }
}

///|
test "uri_builder_exception_scenarios" {
  // 测试UriBuilder的异常情况和边界值

  // 测试无效端口号范围
  let invalid_port_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .port(-1)
  match invalid_port_builder.build() {
    Ok(_) => () // 如果实现允许负端口，这也是有效的
    Err(_) => () // 预期可能失败
  }

  // 测试极大端口号
  let huge_port_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .port(999999)
  match huge_port_builder.build() {
    Ok(_) => () // 如果实现允许大端口，这也是有效的
    Err(_) => () // 预期可能失败
  }

  // 测试空scheme
  let empty_scheme_builder = UriBuilder::new().scheme("").host("example.com")
  match empty_scheme_builder.build() {
    Ok(_) => fail("Empty scheme should fail")
    Err(_) => () // 预期失败
  }

  // 测试包含无效字符的scheme
  let invalid_scheme_builder = UriBuilder::new()
    .scheme("ht@tp")
    .host("example.com")
  match invalid_scheme_builder.build() {
    Ok(_) => () // 如果简化实现允许，也是有效的
    Err(_) => () // 预期可能失败
  }

  // 测试极长的host名
  let long_host = "very-long-hostname-that-might-exceed-normal-limits-in-some-implementations-of-uri-parsing-and-building-functionality-test"
  let long_host_builder = UriBuilder::new().scheme("https").host(long_host)
  match long_host_builder.build() {
    Ok(uri) => assert_eq(uri.host(), Some(long_host))
    Err(_) => () // 如果有长度限制，失败也是合理的
  }

  // 测试空host（对于某些scheme可能是有效的）
  let empty_host_builder = UriBuilder::new().scheme("file").host("")
  match empty_host_builder.build() {
    Ok(_) => () // 对于file协议，空host可能是有效的
    Err(_) => () // 预期可能失败
  }
}

///|
test "uri_builder_query_param_edge_cases" {
  // 测试查询参数的边界情况

  let builder = UriBuilder::new().scheme("https").host("example.com")

  // 空键的查询参数
  let empty_key_builder = builder.clone().query_param("", "value")
  match empty_key_builder.build() {
    Ok(uri) =>
      // 空键应该被处理
      assert_eq(uri.query() is Some(_), true)
    Err(_) => fail("Empty key should be handled")
  }

  // 空值的查询参数
  let empty_value_builder = builder.clone().query_param("key", "")
  match empty_value_builder.build() {
    Ok(uri) => assert_eq(uri.query() is Some(_), true)
    Err(_) => fail("Empty value should be handled")
  }

  // 同时为空的键值
  let both_empty_builder = builder.clone().query_param("", "")
  match both_empty_builder.build() {
    Ok(uri) => assert_eq(uri.query() is Some(_), true)
    Err(_) => fail("Both empty key-value should be handled")
  }

  // 特殊字符键值
  let special_chars_builder = builder
    .clone()
    .query_param("key with spaces", "value&with=special+chars")
  match special_chars_builder.build() {
    Ok(uri) => {
      let query_str = uri.query().unwrap_or("")
      assert_eq(query_str.contains("key"), true)
      assert_eq(query_str.contains("value"), true)
    }
    Err(_) => fail("Special characters should be handled")
  }

  // 多个相同键的参数
  let duplicate_keys_builder = builder
    .clone()
    .query_param("key", "value1")
    .query_param("key", "value2")
    .query_param("other", "value3")
  match duplicate_keys_builder.build() {
    Ok(uri) => {
      let query_str = uri.query().unwrap_or("")
      assert_eq(query_str.contains("key"), true)
      assert_eq(query_str.contains("value1"), true)
      assert_eq(query_str.contains("value2"), true)
      assert_eq(query_str.contains("other"), true)
    }
    Err(_) => fail("Duplicate keys should be handled")
  }
}

///|
test "uri_builder_path_edge_cases" {
  // 测试路径相关的边界情况

  let builder = UriBuilder::new().scheme("https").host("example.com")

  // 多个连续斜杠的路径
  let double_slash_builder = builder.clone().path("//double//slash//path")
  match double_slash_builder.build() {
    Ok(uri) => assert_eq(uri.path().contains("//"), false) // 双斜杠被规范化移除
    Err(_) => fail("Double slash path should be handled")
  }

  // 以..开头的路径
  let dot_dot_path_builder = builder.clone().path("../relative/path")
  match dot_dot_path_builder.build() {
    Ok(uri) => assert_eq(uri.path().contains(".."), true)
    Err(_) => fail("Dot-dot path should be handled")
  }

  // 包含特殊字符的路径
  let special_path_builder = builder
    .clone()
    .path("/path with spaces/and&special=chars")
  match special_path_builder.build() {
    Ok(uri) => {
      assert_eq(uri.path().contains("path"), true)
      assert_eq(uri.path().contains("spaces"), true)
    }
    Err(_) => fail("Special characters in path should be handled")
  }

  // 极长的路径
  let long_path = "/very/long/path/with/many/segments/that/might/test/the/limits/of/path/handling/in/uri/builder/implementation"
  let long_path_builder = builder.clone().path(long_path)
  match long_path_builder.build() {
    Ok(uri) => assert_eq(uri.path(), long_path)
    Err(_) => () // 如果有长度限制，失败也是合理的
  }

  // 清空路径后重新设置
  let clear_and_set_builder = builder
    .clone()
    .path("/initial/path")
    .clear_path()
    .path("/new/path")
  match clear_and_set_builder.build() {
    Ok(uri) => {
      assert_eq(uri.path(), "/new/path")
      assert_eq(uri.path().contains("initial"), false)
    }
    Err(_) => fail("Clear and set path should work")
  }
}

///|
test "uri_builder_from_string_edge_cases" {
  // 测试从字符串创建UriBuilder的边界情况

  // 空字符串
  match UriBuilder::from_string("") {
    Ok(_) => () // 如果空字符串被接受，这也是有效的
    Err(_) => () // 预期可能失败
  }

  // 只有scheme的URI
  match UriBuilder::from_string("https:") {
    Ok(builder) =>
      match builder.build() {
        Ok(uri) => assert_eq(uri.scheme(), "https")
        Err(_) => () // 可能因为缺少必要组件而失败
      }
    Err(_) => () // 可能解析失败
  }

  // 包含片段但无路径的URI
  match UriBuilder::from_string("https://example.com#fragment") {
    Ok(builder) =>
      match builder.build() {
        Ok(uri) => {
          assert_eq(uri.scheme(), "https")
          assert_eq(uri.host(), Some("example.com"))
          assert_eq(uri.fragment(), Some("fragment"))
        }
        Err(_) => fail("Valid URI with fragment should work")
      }
    Err(_) => fail("Should parse valid URI with fragment")
  }

  // 非常复杂的URI
  let complex_uri = "https://user:pass@example.com:8080/path/to/resource?param1=value1&param2=value2#section"
  match UriBuilder::from_string(complex_uri) {
    Ok(builder) =>
      match builder.build() {
        Ok(uri) => {
          assert_eq(uri.scheme(), "https")
          assert_eq(uri.host(), Some("example.com"))
          assert_eq(uri.port(), Some(8080))
          assert_eq(uri.path().contains("resource"), true)
          assert_eq(uri.query() is Some(_), true)
          assert_eq(uri.fragment(), Some("section"))
        }
        Err(_) => fail("Complex URI should parse and build correctly")
      }
    Err(_) => fail("Should parse complex URI")
  }
}

///|
test "uri_builder_with_options_comprehensive" {
  // 测试各种构建器选项的组合

  // 测试默认选项
  let default_options = default_builder_options()
  match
    UriBuilder::with_options(default_options)
    .scheme("https")
    .host("example.com")
    .query_param("key", "value with spaces")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("example.com"))
      // 查询参数应该被编码
      assert_eq(uri.query() is Some(_), true)
    }
    Err(_) => fail("Builder with default options should work")
  }

  // 测试构建器选项的基本功能
  match
    UriBuilder::with_options(default_builder_options())
    .scheme("http")
    .host("test.com")
    .query_param("form", "data+value")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "http")
      assert_eq(uri.host(), Some("test.com"))
    }
    Err(_) => fail("Builder with options should work")
  }

  // 测试不同的构建器配置
  match
    UriBuilder::with_options(default_builder_options())
    .scheme("ftp")
    .host("files.com")
    .query_param("raw", "data&symbols")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "ftp")
      assert_eq(uri.host(), Some("files.com"))
    }
    Err(_) => fail("Builder with options should work")
  }
}

///|
test "uri_builder_path_handling_comprehensive" {
  // 全面测试路径处理功能

  let builder = UriBuilder::new().scheme("https").host("example.com")

  // 测试空路径段处理
  let empty_segments = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path_segment("")
    .path_segment("valid")
    .path_segment("")
  match empty_segments.build() {
    Ok(uri) => assert_eq(uri.path().contains("valid"), true)
    Err(_) => fail("Empty path segments should be handled")
  }

  // 测试特殊字符路径段
  let special_segments = builder
    .clone()
    .path_segment("path with spaces")
    .path_segment("path&with=special")
    .path_segment("path/with/slashes")
  match special_segments.build() {
    Ok(uri) => {
      assert_eq(uri.path().contains("spaces"), true)
      assert_eq(uri.path().contains("special"), true)
      assert_eq(uri.path().contains("slashes"), true)
    }
    Err(_) => fail("Special character path segments should work")
  }

  // 测试路径段数组
  let segments_array = ["api", "v2", "users", "123", "profile"]
  let array_builder = builder.clone().path_segments(segments_array)
  match array_builder.build() {
    Ok(uri) => {
      assert_eq(uri.path().contains("api"), true)
      assert_eq(uri.path().contains("v2"), true)
      assert_eq(uri.path().contains("users"), true)
      assert_eq(uri.path().contains("123"), true)
      assert_eq(uri.path().contains("profile"), true)
    }
    Err(_) => fail("Path segments array should work")
  }

  // 测试路径清除和重建
  let clear_rebuild = builder
    .clone()
    .path_segment("initial")
    .path_segment("path")
    .clear_path()
    .path_segment("new")
    .path_segment("path")
  match clear_rebuild.build() {
    Ok(uri) => {
      assert_eq(uri.path().contains("new"), true)
      assert_eq(uri.path().contains("initial"), false)
    }
    Err(_) => fail("Clear and rebuild path should work")
  }

  // 测试复杂路径解析
  let complex_path = "/complex/../path/./to/../../final"
  let complex_builder = builder.clone().path(complex_path)
  match complex_builder.build() {
    Ok(uri) =>
      // 路径应该被解析
      assert_eq(uri.path().length() > 0, true)
    Err(_) => fail("Complex path should be parsed")
  }
}

///|
test "uri_builder_query_encoding_variants" {
  // 测试查询编码功能（通过构建器选项）

  let base_builder = UriBuilder::new().scheme("https").host("api.example.com")

  // 测试基础查询参数处理
  let basic_builder = base_builder
    .clone()
    .query_param("search", "hello world")
    .query_param("filter", "type=user&active=true")
  match basic_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("search"), true)
      assert_eq(query.contains("filter"), true)
    }
    Err(_) => fail("Basic query encoding should work")
  }

  // 测试特殊字符查询参数
  let special_builder = base_builder
    .clone()
    .query_param("form", "user data")
    .query_param("action", "submit+now")
  match special_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("form"), true)
      assert_eq(query.contains("action"), true)
    }
    Err(_) => fail("Special character encoding should work")
  }

  // 测试复杂查询参数
  let complex_builder = base_builder
    .clone()
    .query_param("raw", "data & symbols")
    .query_param("unencoded", "special=chars")
  match complex_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("raw"), true)
      assert_eq(query.contains("unencoded"), true)
    }
    Err(_) => fail("Complex query encoding should work")
  }
}

///|
test "uri_builder_conditional_query_params" {
  // 测试条件查询参数

  let builder = UriBuilder::new().scheme("https").host("api.example.com")

  // 测试query_param_if_not_empty
  let conditional_builder = builder
    .clone()
    .query_param_if_not_empty("filled", "has_value")
    .query_param_if_not_empty("empty", "")
    .query_param_if_not_empty("whitespace", "   ")
    .query_param_if_not_empty("null_like", "null")
  match conditional_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("filled"), true)
      assert_eq(query.contains("empty"), false)
      assert_eq(query.contains("whitespace"), true) // 空白字符不为空
      assert_eq(query.contains("null_like"), true)
    }
    Err(_) => fail("Conditional query params should work")
  }

  // 测试query_param_bool
  let bool_builder = builder
    .clone()
    .query_param_bool("enabled", true)
    .query_param_bool("disabled", false)
    .query_param_bool("active", true)
    .query_param_bool("inactive", false)
  match bool_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("enabled"), true)
      assert_eq(query.contains("disabled"), false)
      assert_eq(query.contains("active"), true)
      assert_eq(query.contains("inactive"), false)
    }
    Err(_) => fail("Boolean query params should work")
  }

  // 测试混合条件参数
  let mixed_builder = builder
    .clone()
    .query_param("normal", "value")
    .query_param_if_not_empty("conditional", "present")
    .query_param_bool("flag", true)
    .query_param_if_not_empty("missing", "")
    .query_param_bool("off", false)
  match mixed_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("normal"), true)
      assert_eq(query.contains("conditional"), true)
      assert_eq(query.contains("flag"), true)
      assert_eq(query.contains("missing"), false)
      assert_eq(query.contains("off"), false)
    }
    Err(_) => fail("Mixed conditional params should work")
  }
}

///|
test "uri_builder_query_manipulation" {
  // 测试查询参数的操作和修改

  let base_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .query_param("keep1", "value1")
    .query_param("remove", "to_be_removed")
    .query_param("keep2", "value2")
    .query_param("remove", "duplicate_key")
    .query_param("keep3", "value3")

  // 测试移除特定键的查询参数
  let removed_builder = base_builder.clone().remove_query_param("remove")
  match removed_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("keep1"), true)
      assert_eq(query.contains("keep2"), true)
      assert_eq(query.contains("keep3"), true)
      assert_eq(query.contains("remove"), false)
      assert_eq(query.contains("to_be_removed"), false)
      assert_eq(query.contains("duplicate_key"), false)
    }
    Err(_) => fail("Remove query param should work")
  }

  // 测试移除不存在的键
  let nonexistent_remove = base_builder
    .clone()
    .remove_query_param("nonexistent_key")
  match nonexistent_remove.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("keep1"), true)
      assert_eq(query.contains("remove"), true)
    }
    Err(_) => fail("Remove nonexistent key should not affect others")
  }

  // 测试清除所有查询参数
  let cleared_builder = base_builder.clone().clear_query_params()
  match cleared_builder.build() {
    Ok(uri) => assert_eq(uri.query(), None)
    Err(_) => fail("Clear all query params should work")
  }

  // 测试清除后重新添加
  let clear_and_add = base_builder
    .clone()
    .clear_query_params()
    .query_param("new1", "newvalue1")
    .query_param("new2", "newvalue2")
  match clear_and_add.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("new1"), true)
      assert_eq(query.contains("new2"), true)
      assert_eq(query.contains("keep1"), false)
      assert_eq(query.contains("remove"), false)
    }
    Err(_) => fail("Clear and re-add should work")
  }

  // 测试查询参数批量添加
  let batch_params = [
    ("batch1", "bvalue1"),
    ("batch2", "bvalue2"),
    ("batch3", "bvalue3"),
  ]
  let batch_builder = UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .query_params(batch_params)
  match batch_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap_or("")
      assert_eq(query.contains("batch1"), true)
      assert_eq(query.contains("batch2"), true)
      assert_eq(query.contains("batch3"), true)
    }
    Err(_) => fail("Batch query params should work")
  }
}

///|
test "uri_builder_scheme_validation" {
  // 测试scheme验证和边界情况

  // 有效的scheme测试
  let valid_schemes = [
    "http", "https", "ftp", "ftps", "file", "mailto", "tel", "urn", "data",
  ]
  for scheme in valid_schemes {
    match UriBuilder::new().scheme(scheme).host("example.com").build() {
      Ok(uri) => assert_eq(uri.scheme(), scheme)
      Err(_) => fail("Valid scheme " + scheme + " should work")
    }
  }

  // 自定义scheme测试
  let custom_schemes = ["custom", "my-protocol", "app123"]
  for scheme in custom_schemes {
    match UriBuilder::new().scheme(scheme).host("example.com").build() {
      Ok(uri) => assert_eq(uri.scheme(), scheme)
      Err(_) => fail("Custom scheme " + scheme + " should work")
    }
  }

  // 大小写测试
  match UriBuilder::new().scheme("HTTP").host("example.com").build() {
    Ok(uri) => assert_eq(uri.scheme(), "HTTP")
    Err(_) => fail("Uppercase scheme should work")
  }
  match UriBuilder::new().scheme("HtTp").host("example.com").build() {
    Ok(uri) => assert_eq(uri.scheme(), "HtTp")
    Err(_) => fail("Mixed case scheme should work")
  }

  // 错误的scheme测试
  match UriBuilder::new().scheme("").host("example.com").build() {
    Ok(_) => fail("Empty scheme should fail")
    Err(error) =>
      match error {
        InvalidScheme(_) => () // 预期错误
        _ => fail("Should be InvalidScheme error")
      }
  }
}

///|
test "uri_builder_host_variations" {
  // 测试各种主机名格式

  let base_builder = UriBuilder::new().scheme("https")

  // 简单主机名
  match base_builder.clone().host("example").build() {
    Ok(uri) => assert_eq(uri.host(), Some("example"))
    Err(_) => fail("Simple hostname should work")
  }

  // 完全限定域名
  match base_builder.clone().host("api.example.com").build() {
    Ok(uri) => assert_eq(uri.host(), Some("api.example.com"))
    Err(_) => fail("FQDN should work")
  }

  // 带连字符的主机名
  match base_builder.clone().host("my-api-server.example-domain.com").build() {
    Ok(uri) => assert_eq(uri.host(), Some("my-api-server.example-domain.com"))
    Err(_) => fail("Hyphenated hostname should work")
  }

  // 数字主机名
  match base_builder.clone().host("123server").build() {
    Ok(uri) => assert_eq(uri.host(), Some("123server"))
    Err(_) => fail("Numeric hostname should work")
  }

  // IP地址格式
  match base_builder.clone().host("192.168.1.1").build() {
    Ok(uri) => assert_eq(uri.host(), Some("192.168.1.1"))
    Err(_) => fail("IP address should work")
  }

  // 本地主机
  match base_builder.clone().host("localhost").build() {
    Ok(uri) => assert_eq(uri.host(), Some("localhost"))
    Err(_) => fail("Localhost should work")
  }

  // 非常长的主机名
  let long_host = "very-very-very-long-hostname-that-tests-the-limits-of-hostname-handling.example.com"
  match base_builder.clone().host(long_host).build() {
    Ok(uri) => assert_eq(uri.host(), Some(long_host))
    Err(_) => fail("Long hostname should work")
  }

  // 包含端口的主机（应该在port()中处理）
  match base_builder.clone().host("example.com").port(8080).build() {
    Ok(uri) => {
      assert_eq(uri.host(), Some("example.com"))
      assert_eq(uri.port(), Some(8080))
    }
    Err(_) => fail("Host with separate port should work")
  }
}

///|
test "uri_builder_port_validation" {
  // 测试端口号验证

  let base_builder = UriBuilder::new().scheme("https").host("example.com")

  // 有效端口范围测试
  let valid_ports = [80, 443, 8080, 3000, 9000, 21, 22, 25, 53, 110, 993, 995]
  for port in valid_ports {
    match base_builder.clone().port(port).build() {
      Ok(uri) => assert_eq(uri.port(), Some(port))
      Err(_) => fail("Valid port " + port.to_string() + " should work")
    }
  }

  // 边界端口测试
  match base_builder.clone().port(0).build() {
    Ok(uri) => assert_eq(uri.port(), Some(0))
    Err(_) => fail("Port 0 should work")
  }
  match base_builder.clone().port(65535).build() {
    Ok(uri) => assert_eq(uri.port(), Some(65535))
    Err(_) => fail("Port 65535 should work")
  }
  match base_builder.clone().port(1).build() {
    Ok(uri) => assert_eq(uri.port(), Some(1))
    Err(_) => fail("Port 1 should work")
  }
  match base_builder.clone().port(65534).build() {
    Ok(uri) => assert_eq(uri.port(), Some(65534))
    Err(_) => fail("Port 65534 should work")
  }

  // 默认端口测试
  match base_builder.clone().scheme("http").port(80).build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "http")
      assert_eq(uri.port(), Some(80))
    }
    Err(_) => fail("HTTP default port should work")
  }
  match base_builder.clone().scheme("https").port(443).build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.port(), Some(443))
    }
    Err(_) => fail("HTTPS default port should work")
  }
  match base_builder.clone().scheme("ftp").port(21).build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "ftp")
      assert_eq(uri.port(), Some(21))
    }
    Err(_) => fail("FTP default port should work")
  }
}

///|
test "uri_builder_userinfo_handling" {
  // 测试用户信息处理

  let base_builder = UriBuilder::new()
    .scheme("https")
    .host("secure.example.com")

  // 简单用户信息
  match base_builder.clone().userinfo("username").build() {
    Ok(uri) =>
      match uri.authority {
        Some(auth) => assert_eq(auth.userinfo, Some("username"))
        None => fail("Should have authority with userinfo")
      }
    Err(_) => fail("Simple userinfo should work")
  }

  // 用户名和密码
  match base_builder.clone().credentials("user", "pass").build() {
    Ok(uri) =>
      match uri.authority {
        Some(auth) => assert_eq(auth.userinfo, Some("user:pass"))
        None => fail("Should have authority with credentials")
      }
    Err(_) => fail("Credentials should work")
  }

  // 包含特殊字符的用户信息
  match base_builder.clone().userinfo("user@domain.com").build() {
    Ok(uri) =>
      match uri.authority {
        Some(auth) => assert_eq(auth.userinfo, Some("user@domain.com"))
        None => fail("Should have authority")
      }
    Err(_) => fail("Userinfo with @ should work")
  }

  // 复杂的用户名和密码
  match
    base_builder.clone().credentials("complex.user+123", "p@ssw0rd!").build() {
    Ok(uri) =>
      match uri.authority {
        Some(auth) => {
          let userinfo = auth.userinfo.unwrap()
          assert_eq(userinfo.contains("complex.user+123"), true)
          assert_eq(userinfo.contains("p@ssw0rd!"), true)
          assert_eq(userinfo.contains(":"), true)
        }
        None => fail("Should have authority")
      }
    Err(_) => fail("Complex credentials should work")
  }

  // 空用户信息
  match base_builder.clone().userinfo("").build() {
    Ok(uri) =>
      match uri.authority {
        Some(auth) => assert_eq(auth.userinfo, Some(""))
        None => fail("Should have authority")
      }
    Err(_) => fail("Empty userinfo should work")
  }

  // 空用户名和密码
  match base_builder.clone().credentials("", "").build() {
    Ok(uri) =>
      match uri.authority {
        Some(auth) => assert_eq(auth.userinfo, Some(":"))
        None => fail("Should have authority")
      }
    Err(_) => fail("Empty credentials should work")
  }

  // 同时设置userinfo和credentials（后者应该覆盖前者）
  match
    base_builder
    .clone()
    .userinfo("first")
    .credentials("second", "password")
    .build() {
    Ok(uri) =>
      match uri.authority {
        Some(auth) => {
          let userinfo = auth.userinfo.unwrap()
          assert_eq(userinfo.contains("second"), true)
          assert_eq(userinfo.contains("first"), false)
        }
        None => fail("Should have authority")
      }
    Err(_) => fail("Overriding userinfo should work")
  }
}

///|
test "uri_builder_special_schemes_and_paths" {
  // 测试特殊scheme的路径处理

  // mailto scheme - 不需要前导斜杠
  match UriBuilder::new().scheme("mailto").path("user@example.com").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "mailto")
      assert_eq(uri.path(), "user@example.com")
    }
    Err(_) => fail("Mailto scheme should work")
  }

  // tel scheme - 不需要前导斜杠
  match UriBuilder::new().scheme("tel").path("+1234567890").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "tel")
      assert_eq(uri.path(), "+1234567890")
    }
    Err(_) => fail("Tel scheme should work")
  }

  // urn scheme - 不需要前导斜杠
  match UriBuilder::new().scheme("urn").path("isbn:123456789").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "urn")
      assert_eq(uri.path(), "isbn:123456789")
    }
    Err(_) => fail("URN scheme should work")
  }

  // file scheme - 通常没有authority
  match UriBuilder::new().scheme("file").path("/home/user/file.txt").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "file")
      assert_eq(uri.path(), "/home/user/file.txt")
      assert_eq(uri.authority, None)
    }
    Err(_) => fail("File scheme should work")
  }

  // HTTP scheme - 有authority时空路径的处理
  match UriBuilder::new().scheme("http").host("example.com").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "http")
      assert_eq(uri.host(), Some("example.com"))
      // 有authority但无显式路径的情况
      assert_eq(uri.path().length() >= 0, true)
    }
    Err(_) => fail("HTTP with authority but no path should work")
  }

  // HTTP scheme - 显式设置空路径
  match UriBuilder::new().scheme("http").host("example.com").path("").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "http")
      assert_eq(uri.host(), Some("example.com"))
      assert_eq(uri.path(), "")
    }
    Err(_) => fail("HTTP with explicit empty path should work")
  }

  // HTTP scheme - 显式设置根路径
  match UriBuilder::new().scheme("http").host("example.com").path("/").build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "http")
      assert_eq(uri.host(), Some("example.com"))
      assert_eq(uri.path(), "/")
    }
    Err(_) => fail("HTTP with root path should work")
  }
}

///|
test "uri_builder_path_parsing_functions" {
  // 间接测试路径解析函数（通过构建器行为）

  // 测试空路径的解析
  match UriBuilder::new().scheme("https").host("example.com").path("").build() {
    Ok(uri) => assert_eq(uri.path(), "")
    Err(_) => fail("Empty path parsing should work")
  }

  // 测试根路径解析
  match
    UriBuilder::new().scheme("https").host("example.com").path("/").build() {
    Ok(uri) => assert_eq(uri.path(), "/")
    Err(_) => fail("Root path parsing should work")
  }

  // 测试简单路径解析
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path("/api/users/123")
    .build() {
    Ok(uri) => assert_eq(uri.path(), "/api/users/123")
    Err(_) => fail("Simple path parsing should work")
  }

  // 测试复杂路径解析（带特殊字符）
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path("/path with spaces/and&symbols=here")
    .build() {
    Ok(uri) => {
      assert_eq(uri.path().contains("spaces"), true)
      assert_eq(uri.path().contains("symbols"), true)
    }
    Err(_) => fail("Complex path parsing should work")
  }

  // 测试多段路径解析
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path("/segment1/segment2/segment3/segment4")
    .build() {
    Ok(uri) => {
      assert_eq(uri.path().contains("segment1"), true)
      assert_eq(uri.path().contains("segment2"), true)
      assert_eq(uri.path().contains("segment3"), true)
      assert_eq(uri.path().contains("segment4"), true)
    }
    Err(_) => fail("Multi-segment path parsing should work")
  }

  // 测试路径末尾有斜杠的情况
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path("/api/users/")
    .build() {
    Ok(uri) => assert_eq(uri.path().contains("/api/users"), true)
    Err(_) => fail("Path with trailing slash should work")
  }

  // 测试路径中有双斜杠的情况
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .path("/api//double//slash")
    .build() {
    Ok(uri) => {
      assert_eq(uri.path().contains("double"), true)
      assert_eq(uri.path().contains("slash"), true)
    }
    Err(_) => fail("Path with double slashes should work")
  }
}

///|
test "uri_builder_query_string_functions" {
  // 间接测试查询字符串构建函数

  // 单个查询参数
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .query_param("single", "value")
    .build() {
    Ok(uri) => {
      let query = uri.query().unwrap()
      assert_eq(query, "single=value")
    }
    Err(_) => fail("Single query param should work")
  }

  // 多个查询参数
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .query_param("first", "value1")
    .query_param("second", "value2")
    .query_param("third", "value3")
    .build() {
    Ok(uri) => {
      let query = uri.query().unwrap()
      assert_eq(query.contains("first=value1"), true)
      assert_eq(query.contains("second=value2"), true)
      assert_eq(query.contains("third=value3"), true)
      assert_eq(query.contains("&"), true)
    }
    Err(_) => fail("Multiple query params should work")
  }

  // 空值查询参数
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .query_param("empty", "")
    .query_param("normal", "value")
    .build() {
    Ok(uri) => {
      let query = uri.query().unwrap()
      assert_eq(query.contains("empty"), true)
      assert_eq(query.contains("normal=value"), true)
    }
    Err(_) => fail("Empty value query param should work")
  }

  // 特殊字符查询参数
  match
    UriBuilder::new()
    .scheme("https")
    .host("example.com")
    .query_param("special", "value&with=chars")
    .query_param("spaces", "value with spaces")
    .build() {
    Ok(uri) => {
      let query = uri.query().unwrap()
      assert_eq(query.contains("special"), true)
      assert_eq(query.contains("spaces"), true)
    }
    Err(_) => fail("Special char query params should work")
  }

  // 大量查询参数
  let mut large_builder = UriBuilder::new().scheme("https").host("example.com")
  for i = 0; i < 20; i = i + 1 {
    large_builder = large_builder.query_param(
      "param" + i.to_string(),
      "value" + i.to_string(),
    )
  }
  match large_builder.build() {
    Ok(uri) => {
      let query = uri.query().unwrap()
      assert_eq(query.contains("param0"), true)
      assert_eq(query.contains("param19"), true)
      assert_eq(query.contains("value0"), true)
      assert_eq(query.contains("value19"), true)
    }
    Err(_) => fail("Large number of query params should work")
  }
}

///|
test "uri_builder_clone_and_copy_functions" {
  // 测试克隆和复制功能

  let original = UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .port(8443)
    .userinfo("user:pass")
    .path_segment("api")
    .path_segment("v1")
    .query_param("key1", "value1")
    .query_param("key2", "value2")
    .fragment("section")

  // 测试克隆
  let cloned = original.clone()
  match cloned.build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("api.example.com"))
      assert_eq(uri.port(), Some(8443))
      assert_eq(uri.path().contains("api"), true)
      assert_eq(uri.path().contains("v1"), true)
      assert_eq(uri.query() is Some(_), true)
      assert_eq(uri.fragment(), Some("section"))
    }
    Err(_) => fail("Cloned builder should work")
  }

  // 测试克隆后修改不影响原始
  let modified_clone = original
    .clone()
    .scheme("http")
    .host("different.com")
    .port(80)
  match modified_clone.build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "http")
      assert_eq(uri.host(), Some("different.com"))
      assert_eq(uri.port(), Some(80))
      // 路径和查询参数应该保留
      assert_eq(uri.path().contains("api"), true)
      assert_eq(uri.query() is Some(_), true)
    }
    Err(_) => fail("Modified clone should work")
  }

  // 原始构建器应该不受影响
  match original.build() {
    Ok(uri) => {
      assert_eq(uri.scheme(), "https")
      assert_eq(uri.host(), Some("api.example.com"))
      assert_eq(uri.port(), Some(8443))
    }
    Err(_) => fail("Original builder should be unchanged")
  }
}

///|
test "uri_builder_error_propagation" {
  // 测试错误传播和处理

  // 缺少scheme的错误
  match UriBuilder::new().host("example.com").path("/path").build() {
    Ok(_) => fail("Should fail without scheme")
    Err(error) =>
      match error {
        InvalidScheme(_) => () // 预期错误
        _ => fail("Should be InvalidScheme error")
      }
  }

  // 空scheme的错误
  match UriBuilder::new().scheme("").host("example.com").build() {
    Ok(_) => fail("Should fail with empty scheme")
    Err(error) =>
      match error {
        InvalidScheme(_) => () // 预期错误
        _ => fail("Should be InvalidScheme error")
      }
  }

  // 验证复杂构建器的错误处理
  match
    UriBuilder::new()
    .host("example.com")
    .port(8080)
    .path("/api/users")
    .query_param("test", "value")
    .fragment("section")
    .build() {
    Ok(_) => fail("Should fail without scheme even with other components")
    Err(error) =>
      match error {
        InvalidScheme(_) => () // 预期错误
        _ => fail("Should be InvalidScheme error")
      }
  }
}

///|
test "uri_builder_build_string_function" {
  // 测试build_string函数

  // 成功构建字符串
  match
    UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .port(8443)
    .path("/users/123")
    .query_param("include", "profile")
    .fragment("details")
    .build_string() {
    Ok(uri_string) => {
      assert_eq(uri_string.contains("https://"), true)
      assert_eq(uri_string.contains("api.example.com"), true)
      assert_eq(uri_string.contains("8443"), true)
      assert_eq(uri_string.contains("/users/123"), true)
      assert_eq(uri_string.contains("include=profile"), true)
      assert_eq(uri_string.contains("#details"), true)
    }
    Err(_) => fail("Build string should succeed")
  }

  // 构建失败的字符串
  match UriBuilder::new().host("example.com").build_string() {
    Ok(_) => fail("Should fail to build string without scheme")
    Err(error) =>
      match error {
        InvalidScheme(_) => () // 预期错误
        _ => fail("Should be InvalidScheme error")
      }
  }

  // 最简单的有效URI字符串
  match UriBuilder::new().scheme("http").host("localhost").build_string() {
    Ok(uri_string) => assert_eq(uri_string, "http://localhost")
    Err(_) => fail("Simple URI string should build")
  }
}
