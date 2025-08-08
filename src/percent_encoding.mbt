/// 简化的百分号编码实现

///| 编码集合类型
pub enum EncodeSet {
  Component
  Query
} derive(Show, Eq)

///| 创建Component编码集
pub fn EncodeSet::component() -> EncodeSet {
  Component
}

///| 创建Query编码集
pub fn EncodeSet::query() -> EncodeSet {
  Query
}

///| 百分号编码字符串
pub fn percent_encode(input : String, encode_set : EncodeSet) -> String {
  let mut result = ""
  for i = 0; i < input.length(); i = i + 1 {
    let char_code = input[i]
    // 对于非ASCII字符（>127）或需要编码的ASCII字符，都进行编码
    if char_code > 127 || should_encode_ascii(char_code, encode_set) {
      // 统一处理需要编码的字符
      result = result + "%" + byte_to_hex(char_code)
    } else {
      result = result + Char::to_string(Int::unsafe_to_char(char_code))
    }
  }
  result
}

///| 判断ASCII字符是否需要编码
fn should_encode_ascii(char_code : Int, encode_set : EncodeSet) -> Bool {
  // ASCII字母数字字符永远不编码
  if (char_code >= 65 && char_code <= 90) || // A-Z
    (char_code >= 97 && char_code <= 122) || // a-z
    (char_code >= 48 && char_code <= 57) { // 0-9
    return false
  }

  // 根据编码集合决定哪些字符需要编码
  match encode_set {
    Component =>
      // RFC 3986 unreserved characters: ALPHA / DIGIT / "-" / "." / "_" / "~"
      char_code != 45 && char_code != 46 && char_code != 95 && char_code != 126
    Query =>
      // 查询参数允许更多字符，但仍需编码空格、&、=等
      char_code == 32 ||
      char_code == 38 ||
      char_code == 61 ||
      char_code == 43 ||
      char_code < 32 ||
      char_code > 126
  }
}

///| 百分号解码字符串
pub fn percent_decode(input : String) -> Result[String, String] {
  let mut result = ""
  let mut i = 0
  while i < input.length() {
    if i + 2 < input.length() && input[i] == Char::to_int('%') {
      let hex1 = input[i + 1]
      let hex2 = input[i + 2]
      match
        (
          hex_char_to_int(Int::unsafe_to_char(hex1)),
          hex_char_to_int(Int::unsafe_to_char(hex2)),
        ) {
        (Some(h1), Some(h2)) => {
          result = result + Char::to_string(Int::unsafe_to_char(h1 * 16 + h2))
          i = i + 3
        }
        _ => return Err("Invalid percent encoding at position " + i.to_string())
      }
    } else {
      result = result + Char::to_string(Int::unsafe_to_char(input[i]))
      i = i + 1
    }
  }
  Ok(result)
}

///| 编码URL查询参数
pub fn encode_query_param(input : String) -> String {
  let mut result = ""
  for i = 0; i < input.length(); i = i + 1 {
    let char_code = input[i]
    if char_code == Char::to_int(' ') {
      result = result + "+"
    } else if char_code == Char::to_int('+') ||
      char_code == Char::to_int('&') ||
      char_code == Char::to_int('=') ||
      char_code == Char::to_int('%') ||
      char_code > 127 { // 添加对中文等非ASCII字符的编码
      result = result + "%" + byte_to_hex(char_code)
    } else {
      result = result + Char::to_string(Int::unsafe_to_char(char_code))
    }
  }
  result
}

///| 解码URL查询参数
pub fn decode_query_param(input : String) -> Result[String, String] {
  let mut converted = ""
  for i = 0; i < input.length(); i = i + 1 {
    if input[i] == Char::to_int('+') {
      converted = converted + " "
    } else {
      converted = converted + Char::to_string(Int::unsafe_to_char(input[i]))
    }
  }
  percent_decode(converted)
}

///| 验证百分号编码的字符串是否有效
pub fn validate_percent_encoded(input : String) -> Result[Unit, String] {
  let mut i = 0
  while i < input.length() {
    if input[i] == Char::to_int('%') {
      if i + 2 >= input.length() {
        return Err("Incomplete percent encoding at position " + i.to_string())
      }
      let hex1 = input[i + 1]
      let hex2 = input[i + 2]
      match
        (
          hex_char_to_int(Int::unsafe_to_char(hex1)),
          hex_char_to_int(Int::unsafe_to_char(hex2)),
        ) {
        (Some(_), Some(_)) => i = i + 3
        _ =>
          return Err(
            "Invalid hex digits in percent encoding at position " +
            i.to_string(),
          )
      }
    } else {
      i = i + 1
    }
  }
  Ok(())
}

///| 验证并解码百分号编码的字符串，使用UriError错误类型
pub fn validate_and_decode_percent_encoded(
  input : String,
) -> Result[String, UriError] {
  let mut i = 0
  while i < input.length() {
    if input[i] == Char::to_int('%') {
      if i + 2 >= input.length() {
        return Err(
          InvalidPercentEncoding(
            "Incomplete percent encoding at position " + i.to_string(),
          ),
        )
      }
      let hex1 = input[i + 1]
      let hex2 = input[i + 2]
      match
        (
          hex_char_to_int(Int::unsafe_to_char(hex1)),
          hex_char_to_int(Int::unsafe_to_char(hex2)),
        ) {
        (Some(_), Some(_)) => i = i + 3
        _ =>
          return Err(
            InvalidPercentEncoding(
              "Invalid hex digits in percent encoding at position " +
              i.to_string(),
            ),
          )
      }
    } else {
      // 检查字符是否有效
      let char_code = input[i]
      if char_code < 0 || char_code > 127 {
        // 对于非ASCII字符，需要检查是否是有效的UTF-8序列
        i = i + 1
      } else {
        i = i + 1
      }
    }
  }

  // 如果验证通过，进行解码
  match percent_decode(input) {
    Ok(result) => Ok(result)
    Err(msg) => Err(InvalidPercentEncoding(msg))
  }
}
