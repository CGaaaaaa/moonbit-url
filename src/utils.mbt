/// 通用工具函数模块
/// 集中管理重复使用的字符串处理、数组操作等工具函数

///|
/// 简单的整数解析
pub fn parse_int(s : String) -> Int? {
  if s.is_empty() {
    return None
  }
  let mut result = 0
  for i = 0; i < s.length(); i = i + 1 {
    let c = Int::unsafe_to_char(s[i])
    if c.is_ascii_digit() {
      result = result * 10 + (s[i] - 48) // 48 is '0' in ASCII
    } else {
      return None
    }
  }
  Some(result)
}

///|
/// 将字节转换为十六进制字符串
pub fn byte_to_hex(byte : Int) -> String {
  let hex_chars = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
  ]
  // 确保字节值在0-255范围内
  let safe_byte = byte % 256
  let positive_byte = if safe_byte < 0 { safe_byte + 256 } else { safe_byte }
  let high = hex_chars[positive_byte / 16]
  let low = hex_chars[positive_byte % 16]
  Char::to_string(high) + Char::to_string(low)
}

///|
/// 十六进制字符转数字
pub fn hex_char_to_int(c : Char) -> Int? {
  let code = Char::to_int(c)
  if code >= '0' && code <= '9' {
    Some(code - 48)
  } else if code >= 'A' && code <= 'F' {
    Some(code - 55) // 'A' is 65, so 65-55=10
  } else if code >= 'a' && code <= 'f' {
    Some(code - 87) // 'a' is 97, so 97-87=10
  } else {
    None
  }
}

// 删除: build_query_string 已不再使用，构造器根据编码策略自行处理

///|
/// 解析查询字符串
pub fn parse_query_string(query : String) -> Array[(String, String)] {
  if query.is_empty() {
    return []
  }
  let params : Array[(String, String)] = []
  let pairs = query.split("&")
  for pair in pairs {
    match pair.find("=") {
      Some(pos) => {
        let key = try! pair[0:pos].to_string()
        let value = try! pair[pos + 1:].to_string()
        params.push((key, value))
      }
      None => params.push((pair.to_string(), ""))
    }
  }
  params
}

///|
/// 检查字符是否为字母数字
pub fn is_alphanumeric_char(c : Char) -> Bool {
  c.is_ascii_alphabetic() || c.is_ascii_digit()
}

///|
/// 检查字符是否为unreserved字符（RFC 3986）
pub fn is_unreserved_char(c : Char) -> Bool {
  is_alphanumeric_char(c) || c == '-' || c == '.' || c == '_' || c == '~'
}

///|
/// 检查字符是否为sub-delims字符（RFC 3986）
pub fn is_sub_delim_char(c : Char) -> Bool {
  c == '!' ||
  c == '$' ||
  c == '&' ||
  c == '\'' ||
  c == '(' ||
  c == ')' ||
  c == '*' ||
  c == '+' ||
  c == ',' ||
  c == ';' ||
  c == '='
}

///|
/// 获取scheme的默认端口号
pub fn get_default_port(scheme : String) -> Int? {
  let lower_scheme = to_lowercase(scheme)
  match lower_scheme {
    "http" => Some(80)
    "https" => Some(443)
    "ftp" => Some(21)
    "ssh" => Some(22)
    "telnet" => Some(23)
    "smtp" => Some(25)
    "dns" => Some(53)
    "tftp" => Some(69)
    "pop3" => Some(110)
    "imap" => Some(143)
    "ldap" => Some(389)
    "ldaps" => Some(636)
    "ftps" => Some(990)
    "imaps" => Some(993)
    "pop3s" => Some(995)
    _ => None
  }
}

///|
/// 将字符串转换为小写
pub fn to_lowercase(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c >= Char::to_int('A') && c <= Char::to_int('Z') {
      result = result + Int::unsafe_to_char(c + 32).to_string()
    } else {
      result = result + Int::unsafe_to_char(c).to_string()
    }
  }
  result
}
