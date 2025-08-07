/// 简单但正确的 RFC3986 URI 解析器

/// URI Authority 组件
pub struct Authority {
  userinfo : String?
  host : String
  port : Int?
} derive(Show, Eq)

/// URI 结构
pub struct Uri {
  scheme : String
  authority : Authority?
  path : String
  query : String?
  fragment : String?
}

/// URI 解析错误类型
pub enum UriError {
  InvalidScheme(String)
  InvalidPort(String)
  ParseError(String)
}

/// UriError to_string implementation
pub fn UriError::to_string(self : UriError) -> String {
  match self {
    InvalidScheme(msg) => "InvalidScheme: " + msg
    InvalidPort(msg) => "InvalidPort: " + msg
    ParseError(msg) => "ParseError: " + msg
  }
}

/// 解析 URI
pub fn Uri::parse(input : String) -> Result[Uri, UriError] {
  if input.length() == 0 {
    return Err(ParseError("Empty URI"))
  }
  
  let mut remaining = input
  let mut fragment : String? = None
  let mut query : String? = None
  
  // 提取 fragment (最后一个 #)
  let mut frag_pos = -1
  for i = remaining.length() - 1; i >= 0; i = i - 1 {
    if remaining[i] == '#' {
      frag_pos = i
      break
    }
  }
  if frag_pos >= 0 {
    fragment = Some(remaining.substring(start=frag_pos + 1))
    remaining = remaining.substring(start=0, end=frag_pos)
  }
  
  // 提取 query (第一个 ?)
  let mut query_pos = -1
  for i = 0; i < remaining.length(); i = i + 1 {
    if remaining[i] == '?' {
      query_pos = i
      break
    }
  }
  if query_pos >= 0 {
    query = Some(remaining.substring(start=query_pos + 1))
    remaining = remaining.substring(start=0, end=query_pos)
  }
  
  // 提取 scheme
  match remaining.find(":") {
    Some(scheme_pos) => {
      let scheme = remaining.substring(start=0, end=scheme_pos)
      
      if not(is_valid_scheme(scheme)) {
        return Err(InvalidScheme("Invalid scheme: " + scheme))
      }
      
      remaining = remaining.substring(start=scheme_pos + 1)
      
      let mut authority : Authority? = None
      let mut path = ""
      
      // 检查 authority
      if remaining.has_prefix("//") {
        remaining = remaining.substring(start=2)
        
        // 找到 authority 结束位置
        let mut auth_end = remaining.length()
        
        match remaining.find("/") {
          Some(pos) => auth_end = pos
          None => ()
        }
        
        let auth_str = remaining.substring(start=0, end=auth_end)
        remaining = remaining.substring(start=auth_end)
        
        match parse_authority(auth_str) {
          Ok(auth) => authority = Some(auth)
          Err(e) => return Err(e)
        }
      }
      
      path = remaining
      
      Ok({
        scheme,
        authority, 
        path,
        query,
        fragment
      })
    }
    None => Err(ParseError("Invalid URI: missing scheme"))
  }
}

/// 解析 Authority 部分
fn parse_authority(auth : String) -> Result[Authority, UriError] {
  let mut remaining = auth
  let mut userinfo : String? = None
  let mut host = ""
  let mut port : Int? = None
  
  // 检查 userinfo
  match remaining.find("@") {
    Some(pos) => {
      userinfo = Some(remaining.substring(start=0, end=pos))
      remaining = remaining.substring(start=pos + 1)
    }
    None => ()
  }
  
  // 检查 IPv6 地址
  if remaining.has_prefix("[") {
    match remaining.find("]") {
      Some(pos) => {
        host = remaining.substring(start=0, end=pos + 1)
        remaining = remaining.substring(start=pos + 1)
      }
      None => return Err(ParseError("Invalid IPv6 address: missing closing bracket"))
    }
  } else {
    // 普通 host，查找 port 分隔符
    match remaining.find(":") {
      Some(pos) => {
        host = remaining.substring(start=0, end=pos)
        remaining = remaining.substring(start=pos + 1)
      }
      None => {
        host = remaining
        remaining = ""
      }
    }
  }
  
  // 解析 port
  if remaining.length() > 0 {
    match parse_int(remaining) {
      Some(p) => {
        if p >= 0 && p <= 65535 {
          port = Some(p)
        } else {
          return Err(InvalidPort("Port out of range: " + remaining))
        }
      }
      None => return Err(InvalidPort("Invalid port: " + remaining))
    }
  }
  
  Ok({ userinfo, host, port })
}

/// 验证 scheme 是否有效
fn is_valid_scheme(scheme : String) -> Bool {
  if scheme.length() == 0 {
    return false
  }
  
  let first = scheme[0]
  if not((first >= 'A' && first <= 'Z') || (first >= 'a' && first <= 'z')) {
    return false
  }
  
  for i = 1; i < scheme.length(); i = i + 1 {
    let c = scheme[i]
    if not((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || 
           (c >= '0' && c <= '9') || c == '+' || c == '-' || c == '.') {
      return false
    }
  }
  
  true
}

/// 简单的整数解析
fn parse_int(s : String) -> Int? {
  if s.length() == 0 {
    return None
  }
  
  let mut result = 0
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c >= '0' && c <= '9' {
      result = result * 10 + (c - 48) // 48 is '0' in ASCII
    } else {
      return None
    }
  }
  Some(result)
}

/// 转换为字符串
pub fn Uri::to_string(self : Uri) -> String {
  let mut result = self.scheme + ":"
  
  match self.authority {
    Some(auth) => {
      result = result + "//" + Authority::to_string(auth)
    }
    None => ()
  }
  
  result = result + self.path
  
  match self.query {
    Some(q) => result = result + "?" + q
    None => ()
  }
  
  match self.fragment {
    Some(f) => result = result + "#" + f
    None => ()
  }
  
  result
}

/// Authority 转换为字符串
pub fn Authority::to_string(self : Authority) -> String {
  let mut result = ""
  
  match self.userinfo {
    Some(info) => result = result + info + "@"
    None => ()
  }
  
  result = result + self.host
  
  match self.port {
    Some(p) => result = result + ":" + int_to_string(p)
    None => ()
  }
  
  result
}

/// 整数转字符串
fn int_to_string(n : Int) -> String {
  if n == 0 {
    return "0"
  }
  
  let mut result = ""
  let mut num = n
  
  while num > 0 {
    let digit = num % 10
    result = Char::to_string(Int::unsafe_to_char(Char::to_int('0') + digit)) + result
    num = num / 10
  }
  
  result
}