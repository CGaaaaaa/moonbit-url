///| 测试修复的边界情况
/// 这个文件包含针对我们修复的问题的特定测试用例

///|
/// 测试百分号解码边界条件修复
test "percent_decode_boundary_fix" {
  // 测试百分号解码的边界条件修复：确保字符串末尾的百分号编码被正确处理
  match Uri::parse("http://example.com/test%41") {
    Ok(uri) => assert_eq(uri.path, "/test%41") // 路径中的%41应该被保留
    Err(_) => fail("Should parse URI with percent encoding at string end")
  }

  // 测试更复杂的末尾百分号编码
  match Uri::parse("http://example.com/path?query=value%2B%3D") {
    Ok(uri) => assert_eq(uri.query, Some("query=value%2B%3D"))
    Err(_) => fail("Should parse URI with percent encoding in query at end")
  }

  // 测试fragment中的末尾百分号编码
  match Uri::parse("http://example.com/path#fragment%20end") {
    Ok(uri) => assert_eq(uri.fragment, Some("fragment%20end"))
    Err(_) => fail("Should parse URI with percent encoding in fragment at end")
  }

  // 测试正好三个字符的百分号编码（之前的边界条件问题）
  match Uri::parse("scheme://host/path%20") {
    Ok(uri) => assert_eq(uri.path, "/path%20")
    Err(_) => fail("Should parse URI with percent encoding exactly at end")
  }
}

///|
/// 测试URI解析顺序修复
test "parsing_order_fix" {
  // 测试包含特殊字符的复杂URI，确保解析顺序正确
  match
    Uri::parse(
      "custom://user:pass@host.example.com:8080/path/with/special?query=1&other=2#frag",
    ) {
    Ok(uri) => {
      assert_eq(uri.scheme, "custom")
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.userinfo, Some("user:pass"))
          assert_eq(auth.host, "host.example.com")
          assert_eq(auth.port, Some(8080))
        }
        None => fail("Expected authority")
      }
      assert_eq(uri.path, "/path/with/special")
      assert_eq(uri.query, Some("query=1&other=2"))
      assert_eq(uri.fragment, Some("frag"))
    }
    Err(_) => fail("Should parse complex URI with all components")
  }

  // 测试边界情况：authority结束标记的正确检测
  match Uri::parse("scheme://host/path?query#fragment") {
    Ok(uri) => {
      assert_eq(uri.scheme, "scheme")
      match uri.authority {
        Some(auth) => assert_eq(auth.host, "host")
        None => fail("Expected authority")
      }
      assert_eq(uri.path, "/path")
      assert_eq(uri.query, Some("query"))
      assert_eq(uri.fragment, Some("fragment"))
    }
    Err(_) => fail("Should correctly parse authority boundaries")
  }

  // 测试无authority的URI解析
  match Uri::parse("scheme:path?query#fragment") {
    Ok(uri) => {
      assert_eq(uri.scheme, "scheme")
      assert_eq(uri.authority, None)
      assert_eq(uri.path, "path")
      assert_eq(uri.query, Some("query"))
      assert_eq(uri.fragment, Some("fragment"))
    }
    Err(_) => fail("Should parse scheme-only URI correctly")
  }

  // 测试scheme解析优先级：确保先找到scheme，再解析其他部分
  match Uri::parse("http://user@host:8080/path?query#fragment") {
    Ok(uri) => {
      assert_eq(uri.scheme, "http")
      // 确保所有组件都被正确解析
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.userinfo, Some("user"))
          assert_eq(auth.host, "host")
          assert_eq(auth.port, Some(8080))
        }
        None => fail("Should have authority")
      }
    }
    Err(_) => fail("Should parse URI with scheme-first order")
  }
}

///|
/// 测试增强的scheme验证
test "enhanced_scheme_validation" {
  // 测试过长的scheme会被拒绝
  let long_scheme = "a".repeat(65) + "://example.com"
  match Uri::parse(long_scheme) {
    Ok(_) => fail("Should reject overly long scheme")
    Err(_) => () // 应该失败
  }

  // 测试纯数字scheme会被拒绝
  match Uri::parse("123://example.com") {
    Ok(_) => fail("Should reject pure numeric scheme")
    Err(_) => () // 应该失败
  }

  // 测试有效的scheme（包含允许的特殊字符）
  match Uri::parse("http+ssh://example.com") {
    Ok(uri) => assert_eq(uri.scheme, "http+ssh")
    Err(_) => fail("Should accept scheme with plus")
  }
  match Uri::parse("git-ssh://example.com") {
    Ok(uri) => assert_eq(uri.scheme, "git-ssh")
    Err(_) => fail("Should accept scheme with hyphen")
  }
  match Uri::parse("scheme.v2://example.com") {
    Ok(uri) => assert_eq(uri.scheme, "scheme.v2")
    Err(_) => fail("Should accept scheme with dot")
  }

  // 测试大写scheme仍然被接受（为了兼容性）
  match Uri::parse("HTTP://example.com") {
    Ok(uri) => assert_eq(uri.scheme, "HTTP") // 保持原样
    Err(_) => fail("Should accept uppercase scheme for compatibility")
  }

  // 测试边界长度的scheme（应该被接受）
  let max_valid_scheme = "a".repeat(64) + "://example.com"
  match Uri::parse(max_valid_scheme) {
    Ok(uri) => assert_eq(uri.scheme.length(), 64)
    Err(_) => fail("Should accept scheme at maximum valid length")
  }

  // 测试scheme中的无效字符
  match Uri::parse("sch@me://example.com") {
    Ok(_) => fail("Should reject scheme with invalid characters")
    Err(_) => () // 应该失败
  }
}

///|
/// 测试authority解析的边界情况
test "authority_boundary_cases" {
  // 测试authority组件边界的正确检测（修复后应该能正确处理）
  match Uri::parse("scheme://host:9000/path") {
    Ok(uri) => {
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.host, "host")
          assert_eq(auth.port, Some(9000))
        }
        None => fail("Should have authority")
      }
      assert_eq(uri.path, "/path")
    }
    Err(_) => fail("Should parse authority boundaries correctly")
  }

  // 测试authority中多个分隔符的处理
  match Uri::parse("scheme://user:pass@host:8080/?query#frag") {
    Ok(uri) => {
      match uri.authority {
        Some(auth) => {
          assert_eq(auth.userinfo, Some("user:pass"))
          assert_eq(auth.host, "host")
          assert_eq(auth.port, Some(8080))
        }
        None => fail("Should parse complex authority")
      }
      assert_eq(uri.path, "/")
      assert_eq(uri.query, Some("query"))
      assert_eq(uri.fragment, Some("frag"))
    }
    Err(_) => fail("Should handle multiple authority delimiters")
  }
}
