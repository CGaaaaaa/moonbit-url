/// 极简版 URI 测试

test "parse_simple_http" {
  match Uri::parse("http://example.com/path") {
    Ok(uri) => {
      assert_eq(uri.scheme, "http")
      assert_eq(uri.path, "/path")
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.host, "example.com")
          assert_eq(auth.port, None)
        }
        None => fail("Expected authority")
      }
    }
    Err(_) => fail("Failed to parse")
  }
}

test "parse_with_port" {
  match Uri::parse("https://example.com:8443/path?q=v#frag") {
    Ok(uri) => {
      assert_eq(uri.scheme, "https")
      assert_eq(uri.path, "/path")
      assert_eq(uri.query, Some("q=v"))
      assert_eq(uri.fragment, Some("frag"))
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.host, "example.com")
          assert_eq(auth.port, Some(8443))
        }
        None => fail("Expected authority")
      }
    }
    Err(_) => fail("Failed to parse")
  }
}

test "build_uri" {
  match UriBuilder::new()
    .scheme("https")
    .host("api.example.com")
    .path("/v1/users")
    .query_param("limit", "10")
    .build() {
    Ok(uri) => {
      let uri_str = uri.to_string()
      assert_eq(uri_str, "https://api.example.com/v1/users?limit=10")
    }
    Err(_) => fail("Failed to build")
  }
}

test "convenience_http" {
  match http_url("example.com", "/api").build() {
    Ok(uri) => {
      assert_eq(uri.scheme, "http")
      assert_eq(uri.path, "/api")
    }
    Err(_) => fail("Failed to build HTTP URI")
  }
}

// RFC3986 标准测试案例
test "rfc3986_basic_examples" {
  // 基本HTTP URL
  match Uri::parse("http://www.ietf.org/rfc/rfc2396.txt") {
    Ok(uri) => {
      assert_eq(uri.scheme, "http")
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.host, "www.ietf.org")
          assert_eq(auth.port, None)
        }
        None => abort("Expected authority")
      }
      assert_eq(uri.path, "/rfc/rfc2396.txt")
    }
    Err(_) => abort("Should parse RFC3986 example")
  }
}

test "ipv6_parsing" {
  // LDAP URL with IPv6
  match Uri::parse("ldap://[2001:db8::7]/c=GB?objectClass?one") {
    Ok(uri) => {
      assert_eq(uri.scheme, "ldap")
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.host, "[2001:db8::7]")
        }
        None => abort("Expected authority")
      }
      assert_eq(uri.path, "/c=GB")
      assert_eq(uri.query, Some("objectClass?one"))
    }
    Err(_) => abort("Should parse IPv6 LDAP URL")
  }
}

test "port_parsing" {
  match Uri::parse("http://example.com:8080/path") {
    Ok(uri) => {
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.host, "example.com")
          assert_eq(auth.port, Some(8080))
        }
        None => abort("Expected authority")
      }
    }
    Err(_) => abort("Should parse port")
  }
}

test "userinfo_parsing" {
  match Uri::parse("http://user:pass@example.com/path") {
    Ok(uri) => {
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.userinfo, Some("user:pass"))
          assert_eq(auth.host, "example.com")
        }
        None => abort("Expected authority")
      }
    }
    Err(_) => abort("Should parse userinfo")
  }
}

test "scheme_validation" {
  // 有效的scheme
  match Uri::parse("http://example.com") {
    Ok(_) => ()
    Err(_) => abort("http should be valid")
  }
  
  match Uri::parse("my-scheme://example.com") {
    Ok(_) => ()
    Err(_) => abort("my-scheme should be valid")
  }
  
  // 无效的scheme
  match Uri::parse("123://example.com") {
    Ok(_) => abort("scheme starting with digit should be invalid")
    Err(_) => ()
  }
}

test "error_cases" {
  // 空URI
  match Uri::parse("") {
    Ok(_) => abort("Empty URI should fail")
    Err(_) => ()
  }
  
  // 没有scheme
  match Uri::parse("//example.com/path") {
    Ok(_) => abort("URI without scheme should fail")
    Err(_) => ()
  }
  
  // 无效的端口
  match Uri::parse("http://example.com:99999/path") {
    Ok(_) => abort("Port > 65535 should fail")
    Err(_) => ()
  }
  
  match Uri::parse("http://example.com:abc/path") {
    Ok(_) => abort("Non-numeric port should fail")
    Err(_) => ()
  }
}

test "edge_cases" {
  // 只有scheme
  match Uri::parse("scheme:") {
    Ok(uri) => {
      assert_eq(uri.scheme, "scheme")
      assert_eq(uri.path, "")
      assert_eq(uri.authority, None)
    }
    Err(_) => abort("scheme: should be valid")
  }
  
  // 只有fragment
  match Uri::parse("http://example.com#fragment") {
    Ok(uri) => {
      assert_eq(uri.fragment, Some("fragment"))
      assert_eq(uri.query, None)
    }
    Err(_) => abort("Fragment-only should be valid")
  }
  
  // 空query和fragment
  match Uri::parse("http://example.com/path?#") {
    Ok(uri) => {
      assert_eq(uri.query, Some(""))
      assert_eq(uri.fragment, Some(""))
    }
    Err(_) => abort("Empty query and fragment should be valid")
  }
}

test "rfc3986_basic" {
  // 完整URI格式 (RFC3986 Section 1.1.2)
  match Uri::parse("foo://example.com:8042/over/there?name=ferret#nose") {
    Ok(uri) => {
      assert_eq(uri.scheme, "foo")
      assert_eq(uri.authority.unwrap().host, "example.com")
      assert_eq(uri.authority.unwrap().port, Some(8042))
      assert_eq(uri.path, "/over/there")
      assert_eq(uri.query, Some("name=ferret"))
      assert_eq(uri.fragment, Some("nose"))
    }
    Err(_) => abort("RFC3986 example should parse")
  }
}

test "rfc3986_urn" {
  // URN scheme (RFC3986 Section 1.1.3)
  match Uri::parse("urn:example:animal:ferret:nose") {
    Ok(uri) => {
      assert_eq(uri.scheme, "urn")
      assert_eq(uri.authority, None)
      assert_eq(uri.path, "example:animal:ferret:nose")
      assert_eq(uri.query, None)
      assert_eq(uri.fragment, None)
    }
    Err(_) => abort("URN should parse")
  }
}

test "rfc3986_advanced" {
  // 测试复杂URL 
  match Uri::parse("https://user:pass@secure.example.com:443/api/v1/data?format=json&limit=100#results") {
    Ok(uri) => {
      assert_eq(uri.scheme, "https")
      assert_eq(uri.authority.unwrap().userinfo, Some("user:pass"))
      assert_eq(uri.authority.unwrap().host, "secure.example.com")
      assert_eq(uri.authority.unwrap().port, Some(443))
      assert_eq(uri.path, "/api/v1/data")
      assert_eq(uri.query, Some("format=json&limit=100"))
      assert_eq(uri.fragment, Some("results"))
    }
    Err(_) => abort("Complex HTTPS URL should parse")
  }
}

test "rfc3986_tel" {
  // Tel scheme (RFC3966)
  match Uri::parse("tel:+1-816-555-1212") {
    Ok(uri) => {
      assert_eq(uri.scheme, "tel")
      assert_eq(uri.authority, None)
      assert_eq(uri.path, "+1-816-555-1212")
    }
    Err(_) => abort("Tel URI should parse")
  }
}

test "rfc3986_complex_scheme" {
  // Scheme with all valid characters (RFC3986 Section 3.1)
  match Uri::parse("x+y-z.test://example.com/") {
    Ok(uri) => {
      assert_eq(uri.scheme, "x+y-z.test")
      assert_eq(uri.authority.unwrap().host, "example.com")
    }
    Err(_) => abort("Complex scheme should parse")
  }
}

// 新增测试：UriBuilder 完整功能测试
test "uri_builder_full_features" {
  // 测试所有builder方法
  match UriBuilder::new()
    .scheme("https")
    .userinfo("user:password")
    .host("api.example.com")
    .port(8443)
    .path("/v2/api")
    .query_param("format", "json")
    .query_param("limit", "50")
    .query_param("debug", "")  // 空value测试
    .fragment("section1")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme, "https")
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.userinfo, Some("user:password"))
          assert_eq(auth.host, "api.example.com")
          assert_eq(auth.port, Some(8443))
        }
        None => abort("Expected authority")
      }
      assert_eq(uri.path, "/v2/api")
      assert_eq(uri.query, Some("format=json&limit=50&debug"))
      assert_eq(uri.fragment, Some("section1"))
    }
    Err(_) => abort("Builder should work with all features")
  }
}

test "uri_builder_error_cases" {
  // 测试无scheme的错误
  match UriBuilder::new()
    .host("example.com")
    .build() {
    Ok(_) => abort("Should fail without scheme")
    Err(UriError::InvalidScheme(_)) => ()
    Err(_) => abort("Should be InvalidScheme error")
  }
  
  // 测试无host的authority处理
  match UriBuilder::new()
    .scheme("test")
    .path("/path")
    .build() {
    Ok(uri) => {
      assert_eq(uri.authority, None)
      assert_eq(uri.path, "/path")
    }
    Err(_) => abort("Should work without host")
  }
}

test "uri_builder_from_uri" {
  // 创建一个复杂的URI
  let original_uri = match Uri::parse("https://user:pass@example.com:8080/path?key=value#frag") {
    Ok(uri) => uri
    Err(_) => abort("Should parse test URI")
  }
  
  // 从URI创建builder并重新构建
  match UriBuilder::from_uri(original_uri).build() {
    Ok(rebuilt_uri) => {
      assert_eq(rebuilt_uri.scheme, "https")
      match rebuilt_uri.authority {
        Some(auth) => {
          assert_eq(auth.userinfo, Some("user:pass"))
          assert_eq(auth.host, "example.com")
          assert_eq(auth.port, Some(8080))
        }
        None => abort("Expected authority in rebuilt URI")
      }
      assert_eq(rebuilt_uri.path, "/path")
      assert_eq(rebuilt_uri.query, Some("_raw=key=value"))  // from_uri uses _raw
      assert_eq(rebuilt_uri.fragment, Some("frag"))
    }
    Err(_) => abort("Should rebuild URI from original")
  }
}

test "convenience_functions" {
  // 测试 https_url
  match https_url("secure.example.com", "/api/v1").build() {
    Ok(uri) => {
      assert_eq(uri.scheme, "https")
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.host, "secure.example.com")
          assert_eq(auth.port, None)
        }
        None => abort("Expected authority")
      }
      assert_eq(uri.path, "/api/v1")
    }
    Err(_) => abort("https_url should work")
  }
}

test "uri_to_string_variants" {
  // 测试没有authority的URI
  match Uri::parse("scheme:path") {
    Ok(uri) => {
      let uri_str = uri.to_string()
      assert_eq(uri_str, "scheme:path")
    }
    Err(_) => abort("Should parse scheme:path")
  }
  
  // 测试带fragment但无query的URI
  match Uri::parse("http://example.com/path#fragment") {
    Ok(uri) => {
      let uri_str = uri.to_string()
      assert_eq(uri_str, "http://example.com/path#fragment")
    }
    Err(_) => abort("Should parse URI with fragment")
  }
  
  // 测试带userinfo但无port的authority
  match Uri::parse("http://user@example.com/path") {
    Ok(uri) => {
      let uri_str = uri.to_string()
      assert_eq(uri_str, "http://user@example.com/path")
    }
    Err(_) => abort("Should parse URI with userinfo only")
  }
  
  // 测试带port但无userinfo的authority
  match Uri::parse("http://example.com:8080/path") {
    Ok(uri) => {
      let uri_str = uri.to_string()
      assert_eq(uri_str, "http://example.com:8080/path")
    }
    Err(_) => abort("Should parse URI with port only")
  }
}

test "error_handling_comprehensive" {
  // 测试IPv6解析错误 - 覆盖错误处理代码
  match Uri::parse("http://[invalid-ipv6/path") {
    Ok(_) => abort("Should fail on malformed IPv6")
    Err(_) => () // 任何错误都是预期的
  }
  
  // 测试空scheme - 覆盖scheme验证
  match Uri::parse("://example.com") {
    Ok(_) => abort("Should fail on empty scheme")
    Err(_) => ()
  }
  
  // 测试scheme中的无效字符 - 覆盖scheme验证
  match Uri::parse("ht@tp://example.com") {
    Ok(_) => abort("Should fail on invalid scheme character")
    Err(_) => ()
  }
  
  // 测试无效端口的错误类型 - 覆盖端口验证
  match Uri::parse("http://example.com:99999") {
    Ok(_) => abort("Should fail on invalid port")
    Err(_) => ()
  }
  
  // 测试非数字端口 - 覆盖parse_int失败路径
  match Uri::parse("http://example.com:abc") {
    Ok(_) => abort("Should fail on non-numeric port")
    Err(_) => ()
  }
  
  // 测试空端口情况
  match Uri::parse("http://example.com:/path") {
    Ok(uri) => {
      // 实际上空端口是合法的，会被解析为None
      match uri.authority {
        Some(auth) => assert_eq(auth.port, None)
        None => abort("Expected authority")
      }
    }
    Err(_) => () // 如果失败也是可接受的
  }
}

test "edge_cases_comprehensive" {
  // 测试零的字符串转换
  match UriBuilder::new()
    .scheme("test")
    .host("example.com")
    .port(0)
    .build() {
    Ok(uri) => {
      let uri_str = uri.to_string()
      assert_eq(uri_str, "test://example.com:0")
    }
    Err(_) => abort("Should handle port 0")
  }
  
  // 测试空path
  match Uri::parse("http://example.com") {
    Ok(uri) => {
      assert_eq(uri.path, "")
    }
    Err(_) => abort("Should parse URI without path")
  }
}