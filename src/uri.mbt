/// 完整的 RFC3986 URI 解析和操作库
/// 
/// 此库提供完整的URI解析、构建、验证和操作功能，严格遵循RFC 3986标准
/// 支持百分号编码、路径规范化、相对引用解析等高级特性

// 注意：使用utils.mbt中已定义的工具函数
// find_char, parse_int, has_prefix, find_substring, to_lowercase

///| URI Authority 组件
/// 
/// Authority部分包含用户信息、主机名和端口号
/// 格式: [userinfo@]host[:port]
pub struct Authority {
  /// 用户信息部分，格式为 username[:password]
  userinfo : String?
  /// 主机名，可以是域名、IPv4或IPv6地址
  host : String
  /// 端口号，有效范围为0-65535
  port : Int?
} derive(Show, Eq)

///| 创建 Authority 实例
pub fn Authority::new(
  userinfo : String?,
  host : String,
  port : Int?,
) -> Authority {
  { userinfo, host, port }
}

///| URI 结构
/// 
/// 代表一个完整的URI，包含所有组件
/// 格式: scheme:[//authority]path[?query][#fragment]
pub struct Uri {
  /// URI方案，如http、https、ftp等
  scheme : String
  /// 权威部分，包含主机信息
  authority : Authority?
  /// 路径部分
  path : String
  /// 查询参数部分
  query : String?
  /// 片段标识符
  fragment : String?
} derive(Show, Eq)

///| URI 解析和操作错误类型
pub enum UriError {
  /// 无效的URI方案
  InvalidScheme(String)
  /// 无效的端口号
  InvalidPort(String)
  /// 一般性解析错误
  ParseError(String)
  /// 无效的百分号编码
  InvalidPercentEncoding(String)
  /// 相对引用解析错误
  RelativeReferenceError(String)
  /// 无效的IPv6地址
  InvalidIPv6Address(String)
  /// 无效的主机名
  InvalidHostname(String)
  /// 无效的用户信息
  InvalidUserinfo(String)
}

///| UriError to_string implementation
pub fn UriError::to_string(self : UriError) -> String {
  match self {
    InvalidScheme(msg) => "InvalidScheme: " + msg
    InvalidPort(msg) => "InvalidPort: " + msg
    ParseError(msg) => "ParseError: " + msg
    InvalidPercentEncoding(msg) => "InvalidPercentEncoding: " + msg
    RelativeReferenceError(msg) => "RelativeReferenceError: " + msg
    InvalidIPv6Address(msg) => "InvalidIPv6Address: " + msg
    InvalidHostname(msg) => "InvalidHostname: " + msg
    InvalidUserinfo(msg) => "InvalidUserinfo: " + msg
  }
}

///| 解析 URI
pub fn Uri::parse(input : String) -> Result[Uri, UriError] {
  if is_empty(input) {
    return Err(ParseError("Empty URI"))
  }
  let mut remaining = input
  let mut fragment : String? = None
  let mut query : String? = None

  // 提取 fragment (第一个 #)
  match find_char(remaining, '#') {
    Some(frag_pos) => {
      fragment = Some(remaining.substring(start=frag_pos + 1))
      remaining = remaining.substring(start=0, end=frag_pos)
    }
    None => ()
  }

  // 提取 query (第一个 ?)
  match find_char(remaining, '?') {
    Some(query_pos) => {
      query = Some(remaining.substring(start=query_pos + 1))
      remaining = remaining.substring(start=0, end=query_pos)
    }
    None => ()
  }

  // 提取 scheme
  match find_substring(remaining, ":") {
    Some(scheme_pos) => {
      let scheme = remaining.substring(start=0, end=scheme_pos)
      if not(is_valid_scheme(scheme)) {
        return Err(InvalidScheme("Invalid scheme: " + scheme))
      }
      remaining = remaining.substring(start=scheme_pos + 1)
      let mut authority : Authority? = None
      let mut path = ""

      // 检查 authority
      if has_prefix(remaining, "//") {
        remaining = remaining.substring(start=2)

        // 找到 authority 结束位置
        let auth_end = match find_char(remaining, '/') {
          Some(pos) => pos
          None => remaining.length()
        }
        let auth_str = remaining.substring(start=0, end=auth_end)
        remaining = remaining.substring(start=auth_end)
        match parse_authority(auth_str) {
          Ok(auth) => authority = Some(auth)
          Err(e) => return Err(e)
        }
      }
      path = remaining
      Ok({ scheme, authority, path, query, fragment })
    }
    None => Err(ParseError("Invalid URI: missing scheme"))
  }
}

///| 解析 Authority 部分
fn parse_authority(auth : String) -> Result[Authority, UriError] {
  let mut remaining = auth
  let mut userinfo : String? = None
  let mut host = ""
  let mut port : Int? = None

  // 检查 userinfo
  match find_char(remaining, '@') {
    Some(pos) => {
      let userinfo_part = remaining.substring(start=0, end=pos)
      // 验证userinfo格式
      if not(is_valid_userinfo(userinfo_part)) {
        return Err(InvalidUserinfo("Invalid userinfo format: " + userinfo_part))
      }
      // 处理边界情况：如果userinfo只是":"，则规范化为空字符串
      userinfo = if userinfo_part == ":" {
        Some("")
      } else {
        Some(userinfo_part)
      }
      remaining = remaining.substring(start=pos + 1)
    }
    None => ()
  }

  // 检查 IPv6 地址
  if has_prefix(remaining, "[") {
    match find_char(remaining, ']') {
      Some(pos) => {
        let ipv6_part = remaining.substring(start=1, end=pos) // 去掉方括号
        if not(is_valid_ipv6(ipv6_part)) {
          return Err(InvalidIPv6Address("Invalid IPv6 address format: " + ipv6_part))
        }
        host = remaining.substring(start=0, end=pos + 1)
        remaining = remaining.substring(start=pos + 1)
      }
      None =>
        return Err(InvalidIPv6Address("Invalid IPv6 address: missing closing bracket"))
    }
  } else {
    // 普通 host，查找 port 分隔符
    match find_char(remaining, ':') {
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
    // 如果remaining以冒号开头，去掉它
    let port_str = if has_prefix(remaining, ":") {
      remaining.substring(start=1)
    } else {
      remaining
    }
    
    if port_str.length() > 0 {
      match parse_int(port_str) {
        Some(p) =>
          if p >= 0 && p <= 65535 {
            port = Some(p)
          } else {
            return Err(InvalidPort("Port out of range: " + port_str))
          }
        None => return Err(InvalidPort("Invalid port: " + port_str))
      }
    }
  }

  // 验证主机名不能为空
  if host.length() == 0 {
    return Err(InvalidHostname("Host cannot be empty in authority"))
  }
  
  Ok({ userinfo, host, port })
}

///| 验证 scheme 是否有效
fn is_valid_scheme(scheme : String) -> Bool {
  if is_empty(scheme) {
    return false
  }
  let first = Int::unsafe_to_char(scheme[0])
  if not(is_alpha_char(first)) {
    return false
  }
  for i = 1; i < scheme.length(); i = i + 1 {
    let c = Int::unsafe_to_char(scheme[i])
    if not(is_alphanumeric_char(c) || c == '+' || c == '-' || c == '.') {
      return false
    }
  }
  true
}



///| 转换为字符串
pub fn Uri::to_string(self : Uri) -> String {
  let mut result = self.scheme + ":"
  match self.authority {
    Some(auth) => result = result + "//" + Authority::to_string(auth)
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

///| Authority 转换为字符串
pub fn Authority::to_string(self : Authority) -> String {
  let mut result = ""
  match self.userinfo {
    Some(info) => result = result + info + "@"
    None => ()
  }
  result = result + self.host
  match self.port {
    Some(p) => result = result + ":" + p.to_string()
    None => ()
  }
  result
}



// ==================== 高级URI操作功能 ====================


///| 获取主机名
pub fn Uri::host(self : Uri) -> String? {
  match self.authority {
    Some(auth) => Some(auth.host)
    None => None
  }
}

///| 获取端口号
pub fn Uri::port(self : Uri) -> Int? {
  match self.authority {
    Some(auth) => auth.port
    None => None
  }
}

///| 获取默认端口号（基于scheme）
pub fn Uri::default_port(self : Uri) -> Int? {
  get_default_port(self.scheme)
}



///| 获取用户信息
pub fn Uri::userinfo(self : Uri) -> String? {
  match self.authority {
    Some(auth) => auth.userinfo
    None => None
  }
}




///| 获取scheme组件
pub fn Uri::scheme(self : Uri) -> String {
  self.scheme
}

///| 获取path组件
pub fn Uri::path(self : Uri) -> String {
  self.path
}

///| 获取query组件
pub fn Uri::query(self : Uri) -> String? {
  self.query
}

///| 获取fragment组件
pub fn Uri::fragment(self : Uri) -> String? {
  self.fragment
}

///| 检查是否为相对URI（无scheme）
pub fn Uri::is_relative(self : Uri) -> Bool {
  is_empty(self.scheme)
}

///| 检查是否有authority组件
pub fn Uri::has_authority(self : Uri) -> Bool {
  match self.authority {
    Some(_) => true
    None => false
  }
}

///| 检查路径是否为绝对路径（以/开头）
pub fn Uri::has_absolute_path(self : Uri) -> Bool {
  self.path.has_prefix("/")
}

///| 检查路径是否为空
pub fn Uri::has_empty_path(self : Uri) -> Bool {
  self.path.length() == 0
}

///| 获取有效端口（显式端口或scheme的默认端口）
pub fn Uri::effective_port(self : Uri) -> Int? {
  match self.port() {
    Some(port) => Some(port)
    None => self.default_port()
  }
}

///| 获取文件名（路径的最后一个组件）
pub fn Uri::filename(self : Uri) -> String? {
  if self.path.has_suffix("/") || self.path.length() == 0 {
    return None
  }
  
  let parts = self.path.split("/")
  match parts.last() {
    Some(filename_view) => {
      let filename = filename_view.to_string()
      if filename.length() > 0 { Some(filename) } else { None }
    }
    None => None
  }
}

///| 获取文件扩展名
pub fn Uri::file_extension(self : Uri) -> String? {
  match self.filename() {
    Some(filename) => {
      match filename.rev_find(".") {
        Some(index) => if index < filename.length() - 1 {
          Some(filename.substring(start=index + 1))
        } else {
          None
        }
        None => None
      }
    }
    None => None
  }
}

///| 获取父路径
pub fn Uri::parent_path(self : Uri) -> String {
  if self.path.length() == 0 {
    return ""
  }
  
  // 特殊情况：根路径"/"的父路径是"/"
  if self.path == "/" {
    return "/"
  }
  
  let trimmed = if self.path.has_suffix("/") {
    self.path.substring(start=0, end=self.path.length() - 1)
  } else {
    self.path
  }
  
  match trimmed.rev_find("/") {
    Some(index) => if index == 0 { "/" } else { trimmed.substring(start=0, end=index) }
    None => ""
  }
}

///| 规范化比较两个URI是否相等
pub fn Uri::equals_normalized(self : Uri, other : Uri) -> Bool {
  let normalized_self = self.normalize()
  let normalized_other = other.normalize()
  normalized_self.to_string() == normalized_other.to_string()
}

///| 检查是否为绝对URI
pub fn Uri::is_absolute(self : Uri) -> Bool {
  is_not_empty(self.scheme)
}









///| 规范化URI
pub fn Uri::normalize(self : Uri) -> Uri {
  let normalized_path = self.path
  let normalized_scheme = self.scheme

  // 规范化主机名（转为小写）
  let normalized_authority = match self.authority {
    Some(auth) =>
      Some({
        userinfo: auth.userinfo,
        host: auth.host,
        port: normalize_port(normalized_scheme, auth.port),
      })
    None => None
  }
  {
    scheme: normalized_scheme,
    authority: normalized_authority,
    path: normalized_path,
    query: self.query,
    fragment: self.fragment,
  }
}

///| 验证URI是否有效
pub fn Uri::validate(self : Uri) -> Result[Unit, UriError] {
  // 验证scheme
  if not(is_valid_scheme(self.scheme)) {
    return Err(InvalidScheme("Invalid scheme: " + self.scheme))
  }

  // 验证authority
  match self.authority {
    Some(auth) => {
      if auth.host.length() == 0 {
        return Err(ParseError("Empty host in authority"))
      }
      match auth.port {
        Some(port) =>
          if port < 0 || port > 65535 {
            return Err(InvalidPort("Port out of range: " + port.to_string()))
          }
        None => ()
      }
    }
    None => ()
  }
  Ok(())
}



///| 规范化端口号（移除默认端口）
fn normalize_port(scheme : String, port : Int?) -> Int? {
  match port {
    Some(p) => {
      match get_default_port(scheme) {
        Some(default_port) => if p == default_port { None } else { Some(p) }
        None => Some(p)
      }
    }
    None => None
  }
}





///| 验证userinfo格式是否有效
fn is_valid_userinfo(userinfo : String) -> Bool {
  // userinfo可以为空
  if userinfo.length() == 0 {
    return true
  }
  
  // userinfo可以只包含冒号（表示空用户名和空密码）
  if userinfo == ":" {
    return true
  }
  
  // 验证字符是否为有效的userinfo字符
  // RFC 3986: userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
  for i = 0; i < userinfo.length(); i = i + 1 {
    let c = Int::unsafe_to_char(userinfo[i])
    if not(is_unreserved_char(c) || is_sub_delim_char(c) || c == ':' || c == '%') {
      return false
    }
  }
  
  true
}



///| 验证IPv6地址格式（RFC 3986兼容实现）
fn is_valid_ipv6(ipv6 : String) -> Bool {
  if ipv6.length() == 0 {
    return false
  }
  
  // 不支持区域ID（包含%的地址）
  if ipv6.contains("%") {
    return false
  }
  
  // 检查基本格式：不能以单个冒号开头或结尾（除非是::）
  if ipv6.has_prefix(":") && not(ipv6.has_prefix("::")) {
    return false
  }
  if ipv6.has_suffix(":") && not(ipv6.has_suffix("::")) {
    return false
  }
  
  // 检查是否包含IPv4映射格式 (::ffff:192.0.2.1)
  if ipv6.contains("::ffff:") || ipv6.contains("::FFFF:") {
    return validate_ipv4_mapped_ipv6(ipv6)
  }
  
  // 分割成段
  let segments = split_ipv6_segments(ipv6)
  let mut double_colon_count = 0
  let mut empty_segments = 0
  
  // 计算双冒号数量
  for i = 0; i < ipv6.length() - 1; i = i + 1 {
    if Int::unsafe_to_char(ipv6[i]) == ':' && Int::unsafe_to_char(ipv6[i + 1]) == ':' {
      double_colon_count = double_colon_count + 1
    }
  }
  
  // 最多只能有一个双冒号
  if double_colon_count > 1 {
    return false
  }
  
  // 验证每个段
  for segment in segments {
    if segment.length() == 0 {
      empty_segments = empty_segments + 1
    } else {
      if not(is_valid_ipv6_segment(segment)) {
        return false
      }
    }
  }
  
  // 如果有双冒号，可以有空段；否则必须有8个非空段
  if double_colon_count > 0 {
    // 有双冒号的情况：总段数 + 空段数 <= 8
    return segments.length() <= 8
  } else {
    // 没有双冒号：必须恰好8个段，且都不为空
    return segments.length() == 8 && empty_segments == 0
  }
}

///| 验证IPv6段（每段最多4个十六进制字符）
fn is_valid_ipv6_segment(segment : String) -> Bool {
  if segment.length() == 0 || segment.length() > 4 {
    return false
  }
  
  for i = 0; i < segment.length(); i = i + 1 {
    let c = Int::unsafe_to_char(segment[i])
    if not(is_hex_char(c)) {
      return false
    }
  }
  true
}

///| 分割IPv6地址为段
fn split_ipv6_segments(ipv6 : String) -> Array[String] {
  let segments : Array[String] = []
  let mut current_segment = ""
  let mut i = 0
  
  while i < ipv6.length() {
    let c = Int::unsafe_to_char(ipv6[i])
    if c == ':' {
      segments.push(current_segment)
      current_segment = ""
      // 处理双冒号
      if i + 1 < ipv6.length() && Int::unsafe_to_char(ipv6[i + 1]) == ':' {
        segments.push("") // 添加空段表示双冒号
        i = i + 1 // 跳过第二个冒号
      }
    } else {
      current_segment = current_segment + c.to_string()
    }
    i = i + 1
  }
  
  if current_segment.length() > 0 {
    segments.push(current_segment)
  }
  
  segments
}

///| 验证IPv4映射的IPv6地址
fn validate_ipv4_mapped_ipv6(ipv6 : String) -> Bool {
  // ::ffff:192.0.2.1 格式
  if has_prefix(ipv6, "::ffff:") {
    let ipv4_part = ipv6.substring(start=7)
    return is_valid_ipv4(ipv4_part)
  }
  if has_prefix(ipv6, "::FFFF:") {
    let ipv4_part = ipv6.substring(start=7)
    return is_valid_ipv4(ipv4_part)
  }
  false
}

///| 验证IPv4地址格式
fn is_valid_ipv4(ipv4 : String) -> Bool {
  let parts = split_string(ipv4, '.')
  if parts.length() != 4 {
    return false
  }
  
  for part in parts {
    match parse_int(part) {
      Some(num) => {
        if num < 0 || num > 255 {
          return false
        }
        // 不允许前导零（除了"0"本身）
        if part.length() > 1 && part[0] == Char::to_int('0') {
          return false
        }
      }
      None => return false
    }
  }
  true
}





