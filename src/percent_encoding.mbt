/// 百分号编码实现（严格基于 UTF-8 字节）

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

///| 百分号编码字符串（基于 UTF-8 字节视角按字节编码）
pub fn percent_encode(input : String, encode_set : EncodeSet) -> String {
  let mut result = ""
  for i = 0; i < input.length(); i = i + 1 {
    let codepoint = input[i]
    if codepoint <= 0x7F {
      // ASCII 直接按单字节处理
      let byte = codepoint
      if should_percent_encode_byte(byte, encode_set) {
        result = result + "%" + byte_to_hex(byte)
      } else {
        result = result + Char::to_string(Int::unsafe_to_char(byte))
      }
    } else {
      // 非 ASCII：先转为 UTF-8 字节序列，再逐字节百分号编码
      let utf8_bytes = utf8_encode_codepoint(codepoint)
      for j = 0; j < utf8_bytes.length(); j = j + 1 {
        let b = utf8_bytes[j]
        result = result + "%" + byte_to_hex(b)
      }
    }
  }
  result
}

///| 将 Unicode 码点以 UTF-8 形式编码为字节串（以 String 保存每个字节）
fn utf8_encode_codepoint(codepoint : Int) -> String {
  // 不处理代理项范围（应不可能出现在有效的 Unicode 标量值中）
  if codepoint <= 0x7F {
    Char::to_string(Int::unsafe_to_char(codepoint))
  } else if codepoint <= 0x7FF {
    let b1 = 0xC0 + (codepoint >> 6)
    let b2 = 0x80 + (codepoint & 0x3F)
    Char::to_string(Int::unsafe_to_char(b1)) +
    Char::to_string(Int::unsafe_to_char(b2))
  } else if codepoint >= 0xD800 && codepoint <= 0xDFFF {
    // 代理项：返回替换字符 U+FFFD 的 UTF-8 编码
    utf8_encode_codepoint(0xFFFD)
  } else if codepoint <= 0xFFFF {
    let b1 = 0xE0 + (codepoint >> 12)
    let b2 = 0x80 + ((codepoint >> 6) & 0x3F)
    let b3 = 0x80 + (codepoint & 0x3F)
    Char::to_string(Int::unsafe_to_char(b1)) +
    Char::to_string(Int::unsafe_to_char(b2)) +
    Char::to_string(Int::unsafe_to_char(b3))
  } else if codepoint <= 0x10FFFF {
    let b1 = 0xF0 + (codepoint >> 18)
    let b2 = 0x80 + ((codepoint >> 12) & 0x3F)
    let b3 = 0x80 + ((codepoint >> 6) & 0x3F)
    let b4 = 0x80 + (codepoint & 0x3F)
    Char::to_string(Int::unsafe_to_char(b1)) +
    Char::to_string(Int::unsafe_to_char(b2)) +
    Char::to_string(Int::unsafe_to_char(b3)) +
    Char::to_string(Int::unsafe_to_char(b4))
  } else {
    // 超出 Unicode 范围，同样用替换字符
    utf8_encode_codepoint(0xFFFD)
  }
}

///| 判断ASCII字符是否需要编码
fn should_percent_encode_byte(byte : Int, encode_set : EncodeSet) -> Bool {
  // unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
  let is_alpha = (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
  let is_digit = byte >= 48 && byte <= 57
  let is_unreserved = is_alpha ||
    is_digit ||
    byte == 45 ||
    byte == 46 ||
    byte == 95 ||
    byte == 126
  if is_unreserved {
    return false
  }
  match encode_set {
    Component => true
    Query =>
      // 对查询使用严格 percent（空格编码为%20）
      // 需要编码的还包括保留分隔符 & = + % 等
      byte == 32 ||
      byte == 38 ||
      byte == 61 ||
      byte == 43 ||
      byte == 37 ||
      byte < 32 ||
      byte > 126
  }
}

///| 校验一个以字节视角表示的 String 是否为合法 UTF-8 序列
fn is_valid_utf8_bytes(bytes : String) -> Bool {
  let mut i = 0
  while i < bytes.length() {
    let b0 = bytes[i]
    // ASCII
    if b0 <= 0x7F {
      i = i + 1
      continue
    }
    // 2 字节: C2..DF 80..BF
    if b0 >= 0xC2 && b0 <= 0xDF {
      if i + 1 >= bytes.length() {
        return false
      }
      let b1 = bytes[i + 1]
      if !(b1 >= 0x80 && b1 <= 0xBF) {
        return false
      }
      i = i + 2
      continue
    }
    // 3 字节
    if b0 == 0xE0 {
      if i + 2 >= bytes.length() {
        return false
      }
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      if !(b1 >= 0xA0 && b1 <= 0xBF) {
        return false
      }
      if !(b2 >= 0x80 && b2 <= 0xBF) {
        return false
      }
      i = i + 3
      continue
    }
    if (b0 >= 0xE1 && b0 <= 0xEC) || (b0 >= 0xEE && b0 <= 0xEF) {
      if i + 2 >= bytes.length() {
        return false
      }
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      if !(b1 >= 0x80 && b1 <= 0xBF) {
        return false
      }
      if !(b2 >= 0x80 && b2 <= 0xBF) {
        return false
      }
      i = i + 3
      continue
    }
    if b0 == 0xED {
      if i + 2 >= bytes.length() {
        return false
      }
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      // 避免代理项 U+D800..U+DFFF
      if !(b1 >= 0x80 && b1 <= 0x9F) {
        return false
      }
      if !(b2 >= 0x80 && b2 <= 0xBF) {
        return false
      }
      i = i + 3
      continue
    }
    // 4 字节
    if b0 == 0xF0 {
      if i + 3 >= bytes.length() {
        return false
      }
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let b3 = bytes[i + 3]
      if !(b1 >= 0x90 && b1 <= 0xBF) {
        return false
      }
      if !(b2 >= 0x80 && b2 <= 0xBF) {
        return false
      }
      if !(b3 >= 0x80 && b3 <= 0xBF) {
        return false
      }
      i = i + 4
      continue
    }
    if b0 >= 0xF1 && b0 <= 0xF3 {
      if i + 3 >= bytes.length() {
        return false
      }
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let b3 = bytes[i + 3]
      if !(b1 >= 0x80 && b1 <= 0xBF) {
        return false
      }
      if !(b2 >= 0x80 && b2 <= 0xBF) {
        return false
      }
      if !(b3 >= 0x80 && b3 <= 0xBF) {
        return false
      }
      i = i + 4
      continue
    }
    if b0 == 0xF4 {
      if i + 3 >= bytes.length() {
        return false
      }
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let b3 = bytes[i + 3]
      if !(b1 >= 0x80 && b1 <= 0x8F) {
        return false
      }
      if !(b2 >= 0x80 && b2 <= 0xBF) {
        return false
      }
      if !(b3 >= 0x80 && b3 <= 0xBF) {
        return false
      }
      i = i + 4
      continue
    }
    // 其它起始字节均非法（包括 0x80..0xBF 单独出现、0xC0..0xC1 过短/过长编码、>0xF4）
    return false
  }
  true
}

///| 百分号解码字符串（严格按 UTF-8 返回；非法 UTF-8 报错）
pub fn percent_decode(input : String) -> Result[String, String] {
  let mut bytes = ""
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
          bytes = bytes + Char::to_string(Int::unsafe_to_char(h1 * 16 + h2))
          i = i + 3
        }
        _ => return Err("Invalid percent encoding at position " + i.to_string())
      }
    } else {
      bytes = bytes + Char::to_string(Int::unsafe_to_char(input[i]))
      i = i + 1
    }
  }
  match utf8_decode_bytes(bytes) {
    Ok(s) => Ok(s)
    Err(e) => Err(e)
  }
}

///| 将按字节存储的 String 按 UTF-8 解码为 Unicode 字符串
fn utf8_decode_bytes(bytes : String) -> Result[String, String] {
  if !is_valid_utf8_bytes(bytes) {
    return Err("Invalid UTF-8 sequence after percent-decoding")
  }
  let mut i = 0
  let mut out = ""
  while i < bytes.length() {
    let b0 = bytes[i]
    if b0 <= 0x7F {
      out = out + Int::unsafe_to_char(b0).to_string()
      i = i + 1
      continue
    }
    if b0 >= 0xC2 && b0 <= 0xDF {
      let b1 = bytes[i + 1]
      let codepoint = ((b0 & 0x1F) << 6) + (b1 & 0x3F)
      out = out + Int::unsafe_to_char(codepoint).to_string()
      i = i + 2
      continue
    }
    if b0 == 0xE0 {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let codepoint = ((b0 & 0x0F) << 12) + ((b1 & 0x3F) << 6) + (b2 & 0x3F)
      out = out + Int::unsafe_to_char(codepoint).to_string()
      i = i + 3
      continue
    }
    if (b0 >= 0xE1 && b0 <= 0xEC) || (b0 >= 0xEE && b0 <= 0xEF) {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let codepoint = ((b0 & 0x0F) << 12) + ((b1 & 0x3F) << 6) + (b2 & 0x3F)
      out = out + Int::unsafe_to_char(codepoint).to_string()
      i = i + 3
      continue
    }
    if b0 == 0xED {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let codepoint = ((b0 & 0x0F) << 12) + ((b1 & 0x3F) << 6) + (b2 & 0x3F)
      out = out + Int::unsafe_to_char(codepoint).to_string()
      i = i + 3
      continue
    }
    if b0 == 0xF0 {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let b3 = bytes[i + 3]
      let codepoint = ((b0 & 0x07) << 18) +
        ((b1 & 0x3F) << 12) +
        ((b2 & 0x3F) << 6) +
        (b3 & 0x3F)
      out = out + Int::unsafe_to_char(codepoint).to_string()
      i = i + 4
      continue
    }
    if b0 >= 0xF1 && b0 <= 0xF3 {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let b3 = bytes[i + 3]
      let codepoint = ((b0 & 0x07) << 18) +
        ((b1 & 0x3F) << 12) +
        ((b2 & 0x3F) << 6) +
        (b3 & 0x3F)
      out = out + Int::unsafe_to_char(codepoint).to_string()
      i = i + 4
      continue
    }
    if b0 == 0xF4 {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let b3 = bytes[i + 3]
      let codepoint = ((b0 & 0x07) << 18) +
        ((b1 & 0x3F) << 12) +
        ((b2 & 0x3F) << 6) +
        (b3 & 0x3F)
      out = out + Int::unsafe_to_char(codepoint).to_string()
      i = i + 4
      continue
    }
    // 其它情况不应发生，因为已通过 is_valid_utf8_bytes 验证
    return Err("Invalid UTF-8 sequence after percent-decoding")
  }
  Ok(out)
}

///| 编码URL查询参数（application/x-www-form-urlencoded：空格->+，其他按%HH）
pub fn encode_query_param(input : String) -> String {
  let mut result = ""
  for i = 0; i < input.length(); i = i + 1 {
    let byte = input[i]
    if byte == Char::to_int(' ') {
      result = result + "+"
    } else if byte == Char::to_int('+') ||
      byte == Char::to_int('&') ||
      byte == Char::to_int('=') ||
      byte == Char::to_int('%') ||
      byte < 32 ||
      byte > 126 {
      result = result + "%" + byte_to_hex(byte)
    } else {
      result = result + Char::to_string(Int::unsafe_to_char(byte))
    }
  }
  result
}

///| 解码URL查询参数（application/x-www-form-urlencoded）
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

  // 如果验证通过，进行解码并校验 UTF-8
  match percent_decode(input) {
    Ok(result) => Ok(result)
    Err(msg) => Err(InvalidPercentEncoding(msg))
  }
}

///| 仅对非 ASCII 字符进行百分号编码（保留 ASCII 原样）。
/// 用于 IRI -> URI 转换场景，避免对 '/'、':' 等 ASCII 保留字符误编码。
pub fn percent_encode_non_ascii(input : String) -> String {
  let mut result = ""
  for i = 0; i < input.length(); i = i + 1 {
    let codepoint = input[i]
    if codepoint <= 0x7F {
      result = result + Char::to_string(Int::unsafe_to_char(codepoint))
    } else {
      let utf8_bytes = utf8_encode_codepoint(codepoint)
      for j = 0; j < utf8_bytes.length(); j = j + 1 {
        let b = utf8_bytes[j]
        result = result + "%" + byte_to_hex(b)
      }
    }
  }
  result
}

///| 是否为 unreserved 字节（ALPHA / DIGIT / "-" / "." / "_" / "~"），按字节判断
pub fn is_unreserved_byte(byte : Int) -> Bool {
  let is_alpha = (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122)
  let is_digit = byte >= 48 && byte <= 57
  is_alpha || is_digit || byte == 45 || byte == 46 || byte == 95 || byte == 126
}
