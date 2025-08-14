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

///| 规范化选项
pub struct NormalizationOptions {
  /// 是否折叠路径中的重复斜杠（将多个 '/' 折叠为一个）
  fold_duplicate_slashes : Bool
  /// 是否启用 IDNA/Punycode（解析阶段保持原样，仅在规范化时应用）
  enable_idna : Bool
  /// 是否规范化百分号编码（%HH -> 大写；可选解码 unreserved）
  percent_normalize : Bool
  /// 在 percent_normalize 时，是否解码 unreserved 的 %HH
  decode_unreserved_pct : Bool
  /// 是否对 IPv6 字面量进行 RFC 5952 规范化
  ipv6_normalize : Bool
  /// 是否折叠主机中的连续点（web 兼容）
  host_collapse_dots : Bool
  /// 是否移除域名末尾点（web 兼容）
  host_strip_trailing_dot : Bool
  /// IDNA 处理配置（UTS-46 或 IDNA2008 严格）。仅在 enable_idna 时生效
  idna_profile : IDNAProfile
}

///| 默认规范化选项（保持当前库既有行为）：
/// - 不折叠重复斜杠（构建器层面已会折叠）
/// - 不启用 IDNA（仅小写化主机）
pub fn default_normalization_options() -> NormalizationOptions {
  {
    fold_duplicate_slashes: false,
    enable_idna: false,
    percent_normalize: false,
    decode_unreserved_pct: false,
    ipv6_normalize: false,
    host_collapse_dots: false,
    host_strip_trailing_dot: false,
    idna_profile: IDNAProfile::Uts46NonTransitional,
  }
}

///| 开启折叠重复斜杠选项，返回新的选项值
pub fn NormalizationOptions::with_fold_duplicate_slashes(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, fold_duplicate_slashes: true }
}

///| 开启 IDNA 选项，返回新的选项值
pub fn NormalizationOptions::with_enable_idna(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, enable_idna: true }
}

///| 启用百分号编码规范化（%HH 大写）
pub fn NormalizationOptions::with_percent_normalize(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, percent_normalize: true }
}

///| 在百分号规范化时解码 unreserved 的 %HH
pub fn NormalizationOptions::with_decode_unreserved_pct(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, decode_unreserved_pct: true }
}

///| 启用 IPv6 规范化（压缩零段、去前导零、小写）
pub fn NormalizationOptions::with_ipv6_normalize(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, ipv6_normalize: true }
}

///| 启用主机名点折叠（a..b...c -> a.b.c）
pub fn NormalizationOptions::with_host_collapse_dots(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, host_collapse_dots: true }
}

///| 启用移除末尾点（example.com. -> example.com）
pub fn NormalizationOptions::with_host_strip_trailing_dot(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, host_strip_trailing_dot: true }
}

///| 选择 IDNA UTS-46 非过渡模式
pub fn NormalizationOptions::use_idna_uts46_nontransitional(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, enable_idna: true, idna_profile: IDNAProfile::Uts46NonTransitional }
}

///| 选择 IDNA UTS-46 过渡模式（如将 ß -> ss 等）
pub fn NormalizationOptions::use_idna_uts46_transitional(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, enable_idna: true, idna_profile: IDNAProfile::Uts46Transitional }
}

///| 选择 IDNA2008 严格模式（启用更严格的校验，拒绝某些上下文字符）
pub fn NormalizationOptions::use_idna_2008_strict(
  self : NormalizationOptions,
) -> NormalizationOptions {
  { ..self, enable_idna: true, idna_profile: IDNAProfile::IDNA2008Strict }
}

///| 预设：Web 兼容
pub fn NormalizationOptions::web_compat() -> NormalizationOptions {
  default_normalization_options()
  .with_fold_duplicate_slashes()
  .use_idna_uts46_nontransitional()
  .with_percent_normalize()
  .with_decode_unreserved_pct()
  .with_ipv6_normalize()
  .with_host_collapse_dots()
  .with_host_strip_trailing_dot()
}

///| 预设：RFC 3986 严格
pub fn NormalizationOptions::rfc3986_strict() -> NormalizationOptions {
  // 不进行 IDNA；保留斜杠；仅进行 %HH 大写与 IPv6 规范化
  default_normalization_options().with_percent_normalize().with_ipv6_normalize()
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

  // RFC 3986 推荐的解析顺序：先解析 scheme，再解析其他组件
  // 首先找到 scheme 分隔符
  match find_substring(input, ":") {
    Some(scheme_pos) => {
      let scheme = input.substring(start=0, end=scheme_pos)
      if not(is_valid_scheme(scheme)) {
        return Err(InvalidScheme("Invalid scheme: " + scheme))
      }
      let mut remaining = input.substring(start=scheme_pos + 1)
      let mut authority : Authority? = None
      let mut path = ""
      let mut query : String? = None
      let mut fragment : String? = None

      // 检查是否有 authority（以 "//" 开头）
      if has_prefix(remaining, "//") {
        remaining = remaining.substring(start=2)

        // 找到 authority 结束位置（由 path、query 或 fragment 标记）
        let mut auth_end = remaining.length()
        for delimiter in ['/', '?', '#'] {
          match find_char(remaining, delimiter) {
            Some(pos) => if pos < auth_end { auth_end = pos }
            None => ()
          }
        }
        let auth_str = remaining.substring(start=0, end=auth_end)
        remaining = remaining.substring(start=auth_end)
        match parse_authority(auth_str) {
          Ok(auth) => {
            // 如果主机为空且scheme不是file，则视为错误
            if auth.host.length() == 0 && scheme != "file" {
              return Err(InvalidHostname("Host cannot be empty in authority"))
            }
            authority = Some(auth)
          }
          Err(e) => return Err(e)
        }
      }

      // 解析 path、query 和 fragment
      // 先提取 fragment（最后的 #）
      match find_char(remaining, '#') {
        Some(frag_pos) => {
          fragment = Some(remaining.substring(start=frag_pos + 1))
          remaining = remaining.substring(start=0, end=frag_pos)
        }
        None => ()
      }

      // 然后提取 query（最后的 ?）
      match find_char(remaining, '?') {
        Some(query_pos) => {
          query = Some(remaining.substring(start=query_pos + 1))
          remaining = remaining.substring(start=0, end=query_pos)
        }
        None => ()
      }

      // 剩余部分就是 path
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
      // 保留原样（包括仅":" 的情况），以便与 non-special://:@test/x 一致
      userinfo = Some(userinfo_part)
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
          return Err(
            InvalidIPv6Address("Invalid IPv6 address format: " + ipv6_part),
          )
        }
        host = remaining.substring(start=0, end=pos + 1)
        remaining = remaining.substring(start=pos + 1)
      }
      None =>
        return Err(
          InvalidIPv6Address("Invalid IPv6 address: missing closing bracket"),
        )
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
    // 兼容两种分支：非IPv6分支已消费冒号、IPv6分支保留冒号
    let port_str = if has_prefix(remaining, ":") {
      remaining.substring(start=1)
    } else {
      remaining
    }
    // 不允许额外冒号
    if port_str.contains(":") {
      return Err(InvalidPort("Invalid port: " + port_str))
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

  // 允许空 host（例如 file:/// 路径），在 file 等方案下是合法的
  // 其他方案仍由上层逻辑决定有效性
  Ok({ userinfo, host, port })
}

///| 验证 scheme 是否有效
/// 根据 RFC 3986，scheme 必须：
/// - 以字母开头
/// - 后续字符只能是字母、数字、'+'、'-'、'.'
/// - 长度合理（实际限制建议不超过64字符）
/// - 大小写不敏感（接受大写，但会标准化为小写）
fn is_valid_scheme(scheme : String) -> Bool {
  if is_empty(scheme) {
    return false
  }

  // 检查长度限制（避免过长的scheme）
  if scheme.length() > 64 {
    return false
  }

  // 第一个字符必须是字母
  let first = Int::unsafe_to_char(scheme[0])
  if not(is_alpha_char(first)) {
    return false
  }

  // 检查后续字符
  for i = 1; i < scheme.length(); i = i + 1 {
    let c = Int::unsafe_to_char(scheme[i])

    // 检查是否是有效字符（字母、数字、+、-、.）
    if not(is_alphanumeric_char(c) || c == '+' || c == '-' || c == '.') {
      return false
    }
  }

  // 额外的语义检查：确保不是纯数字（避免与端口混淆）
  let mut all_digits = true
  for i = 0; i < scheme.length(); i = i + 1 {
    let c = Int::unsafe_to_char(scheme[i])
    if not(c >= '0' && c <= '9') {
      all_digits = false
    }
  }
  if all_digits {
    return false
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
      if filename.length() > 0 {
        Some(filename)
      } else {
        None
      }
    }
    None => None
  }
}

///| 获取文件扩展名
pub fn Uri::file_extension(self : Uri) -> String? {
  match self.filename() {
    Some(filename) =>
      match filename.rev_find(".") {
        Some(index) =>
          if index < filename.length() - 1 {
            Some(filename.substring(start=index + 1))
          } else {
            None
          }
        None => None
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
    Some(index) =>
      if index == 0 {
        "/"
      } else {
        trimmed.substring(start=0, end=index)
      }
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
  // 绝对URI：拥有非空 scheme 即视为绝对（RFC 3986）
  is_not_empty(self.scheme)
}

///| 规范化URI
pub fn Uri::normalize(self : Uri) -> Uri {
  self.normalize_with(default_normalization_options())
}

///| 使用 Web 兼容预设进行规范化（启用 UTS-46 非过渡、折叠重复斜杠、% 编码规范化、IPv6 规范化、点折叠与去尾点）
pub fn Uri::normalize_web(self : Uri) -> Uri {
  self.normalize_with(NormalizationOptions::web_compat())
}

///| 使用 RFC 3986 严格预设进行规范化（不启用 IDNA，仅进行必要规范化）
pub fn Uri::normalize_rfc3986(self : Uri) -> Uri {
  self.normalize_with(NormalizationOptions::rfc3986_strict())
}

///| 使用自定义选项进行规范化
pub fn Uri::normalize_with(self : Uri, options : NormalizationOptions) -> Uri {
  let normalized_scheme = self.scheme

  // 处理主机名：
  let normalized_authority = match self.authority {
    Some(auth) => {
      let lowered_host = if auth.host.length() > 0 {
        to_lowercase(auth.host)
      } else {
        auth.host
      }
      let host_after_dots = if options.host_collapse_dots {
        collapse_host_dots(lowered_host)
      } else {
        lowered_host
      }
      let host_after_trailing = if options.host_strip_trailing_dot {
        strip_trailing_dot(host_after_dots)
      } else {
        host_after_dots
      }
      let host_after_idna = if options.enable_idna {
        normalize_host_with_profile(host_after_trailing, options.idna_profile)
      } else {
        host_after_trailing
      }
      let final_host = if options.ipv6_normalize &&
        has_prefix(host_after_idna, "[") {
        normalize_ipv6_literal(host_after_idna)
      } else {
        host_after_idna
      }
      // 百分号规范化 userinfo（不更改其语义，仅大小写/解码 unreserved）
      let mut new_userinfo = auth.userinfo
      if options.percent_normalize {
        match auth.userinfo {
          Some(ui) =>
            new_userinfo = Some(
              normalize_percent_encoding_in_string(
                ui,
                options.decode_unreserved_pct,
              ),
            )
          None => ()
        }
      }
      Some({
        userinfo: new_userinfo,
        host: final_host,
        port: normalize_port(normalized_scheme, auth.port),
      })
    }
    None => None
  }

  // 处理路径：
  let mut normalized_path = if options.fold_duplicate_slashes {
    fold_duplicate_slashes(self.path)
  } else {
    self.path
  }
  if options.percent_normalize {
    normalized_path = normalize_percent_encoding_in_string(
      normalized_path,
      options.decode_unreserved_pct,
    )
  }
  {
    scheme: normalized_scheme,
    authority: normalized_authority,
    path: normalized_path,
    query: match self.query {
      Some(q) =>
        if options.percent_normalize {
          Some(
            normalize_percent_encoding_in_string(
              q,
              options.decode_unreserved_pct,
            ),
          )
        } else {
          Some(q)
        }
      None => None
    },
    fragment: match self.fragment {
      Some(f) =>
        if options.percent_normalize {
          Some(
            normalize_percent_encoding_in_string(
              f,
              options.decode_unreserved_pct,
            ),
          )
        } else {
          Some(f)
        }
      None => None
    },
  }
}

///| 折叠路径中的重复斜杠（不改变其他字符）
fn fold_duplicate_slashes(path : String) -> String {
  if path.length() == 0 {
    return ""
  }
  let mut out = ""
  let mut prev_is_slash = false
  for i = 0; i < path.length(); i = i + 1 {
    let ch = Int::unsafe_to_char(path[i])
    let is_slash = ch == '/'
    if is_slash {
      if !prev_is_slash {
        out = out + "/"
      }
      prev_is_slash = true
    } else {
      out = out + ch.to_string()
      prev_is_slash = false
    }
  }
  out
}

// 已移除未使用的 is_domain_host

///| 折叠主机中的重复点（.. -> .）
fn collapse_host_dots(host : String) -> String {
  if host.length() == 0 {
    return host
  }
  if has_prefix(host, "[") {
    return host
  }
  let labels = split_string(host, '.')
  let filtered : Array[String] = []
  for l in labels {
    if l.length() > 0 {
      filtered.push(l)
    }
  }
  filtered.join(".")
}

///| 去掉主机末尾点（example.com. -> example.com）
fn strip_trailing_dot(host : String) -> String {
  if host.length() == 0 {
    return host
  }
  if has_prefix(host, "[") {
    return host
  }
  if host.has_suffix(".") {
    host.substring(start=0, end=host.length() - 1)
  } else {
    host
  }
}

// 已移除未使用的 normalize_host_idna（由 normalize_host_with_profile 取代）

///| IDNA 配置
pub enum IDNAProfile {
  /// UTS-46 非过渡（推荐现代浏览器行为，保留 ß 等）
  Uts46NonTransitional
  /// UTS-46 过渡（将 ß->ss 等替换）
  Uts46Transitional
  /// IDNA2008 严格（强校验，拒绝上下文敏感问题）
  IDNA2008Strict
} derive(Show, Eq)

///| 依据 profile 进行主机名 IDNA 规范化与 Punycode 编码
fn normalize_host_with_profile(host : String, profile : IDNAProfile) -> String {
  if host.length() == 0 {
    return host
  }
  if has_prefix(host, "[") {
    return host
  } // IPv6
  let preprocessed = map_alt_dots(host)
  let labels = split_string(preprocessed, '.')
  let out_labels : Array[String] = []
  for raw_label in labels {
    let lower = to_lowercase(raw_label)
    if lower.length() == 0 {
      out_labels.push("")
      continue
    }
    if has_prefix(lower, "xn--") {
      out_labels.push(lower)
      continue
    }
    if contains_non_ascii(lower) {
      // 1) TR46 映射 + NFKC（宽松/严格取决于 profile；当前为增强子集）
      let (mapped, had_contextj) = tr46_map_and_nfkc(lower, profile)
      // 若映射后全部为 ASCII，直接使用（过渡模式下常见：ß->ss）
      if !contains_non_ascii(mapped) {
        // 在严格模式下，若包含需要上下文的字符，则拒绝（此处采用保守回退策略）
        let reject_for_contextj = match profile {
          IDNAProfile::IDNA2008Strict => had_contextj
          _ => false
        }
        if reject_for_contextj {
          out_labels.push(lower)
          // 可选：在严格模式下应用 STD3 与连字符规则
        } else if !is_valid_uts46_label(mapped, profile, had_contextj) {
          out_labels.push(lower)
        } else {
          out_labels.push(mapped)
        }
        continue
      }
      // 2) 验证标签（长度、hyphen、bidi 等）— 目前实现 subset，保守放行
      if !is_valid_uts46_label(mapped, profile, had_contextj) {
        // 保守策略：返回原始小写标签（也可选择抛错）
        out_labels.push(lower)
        continue
      }
      // 3) Punycode 编码
      match punycode_encode_strict(mapped) {
        Some(puny) => out_labels.push("xn--" + puny)
        None => out_labels.push(lower)
      }
    } else {
      out_labels.push(lower)
    }
  }
  out_labels.join(".")
}

///| 依据 profile 进行主机名 IDNA 规范化（返回错误而非静默回退）。
/// 严格模式推荐使用；非严格模式亦可用以获取明确错误。
fn normalize_host_with_profile_strict(
  host : String,
  profile : IDNAProfile,
) -> String? {
  if host.length() == 0 {
    return Some(host)
  }
  if has_prefix(host, "[") {
    return Some(host)
  } // IPv6
  let preprocessed = map_alt_dots(host)
  let labels = split_string(preprocessed, '.')
  let out_labels : Array[String] = []
  for raw_label in labels {
    let lower = to_lowercase(raw_label)
    if lower.length() == 0 {
      out_labels.push("")
      continue
    }
    if has_prefix(lower, "xn--") {
      out_labels.push(lower)
      continue
    }
    if contains_non_ascii(lower) {
      // 使用 TR46 映射 + NFKC（当前实现为增强的子集）
      let (mapped_rough, had_contextj) = tr46_map_and_nfkc(lower, profile)
      // 校验标签（严格返回错误）
      if !validate_uts46_label(mapped_rough, profile, had_contextj) {
        return None
      }
      // Punycode 编码
      match punycode_encode_strict(mapped_rough) {
        Some(puny) => out_labels.push("xn--" + puny)
        None => return None
      }
      // ASCII 标签：严格模式下应用 STD3 等
    } else if !validate_uts46_label(lower, profile, false) {
      return None
    } else {
      out_labels.push(lower)
    }
  }
  Some(out_labels.join("."))
}

///| 将域名根据给定 IDNA 配置转换为 ASCII（可能包含 `xn--` 标签）。
/// 仅对 host 生效；IPv6 字面量原样返回。
pub fn domain_to_ascii(domain : String, profile : IDNAProfile) -> String {
  normalize_host_with_profile(domain, profile)
}

///| 严格版本：返回严格 IDNA 校验后 ASCII 域名（固定使用 IDNA2008Strict），失败返回 None
pub fn domain_to_ascii_strict(domain : String) -> String? {
  normalize_host_with_profile_strict(domain, IDNAProfile::IDNA2008Strict)
}

///| 兼容版本：允许指定 profile 的严格 ASCII 转换。建议优先使用无参严格版。
pub fn domain_to_ascii_strict_with_profile(
  domain : String,
  profile : IDNAProfile,
) -> String? {
  normalize_host_with_profile_strict(domain, profile)
}

///| 将域名从 ASCII/Punycode 转为 Unicode。会解码 `xn--` 标签，其余标签按小写返回。
/// - IPv6 字面量原样返回
/// - 会处理 U+3002/U+FF0E/U+FF61 作为分隔符
/// - 解码失败时保留原标签的小写形式
pub fn domain_to_unicode(domain : String) -> String {
  if domain.length() == 0 {
    return domain
  }
  if has_prefix(domain, "[") {
    return domain
  }
  let preprocessed = map_alt_dots(domain)
  let labels = split_string(preprocessed, '.')
  let out_labels : Array[String] = []
  for raw_label in labels {
    let lower = to_lowercase(raw_label)
    if lower.length() == 0 {
      out_labels.push("")
      continue
    }
    if has_prefix(lower, "xn--") {
      let puny = lower.substring(start=4)
      match punycode_decode_strict(puny) {
        Some(decoded) => {
          // 可选：对解码后的标签应用 TR46+NFKC 以获得规范化视图
          let (mapped, _) = tr46_map_and_nfkc(
            decoded,
            IDNAProfile::Uts46NonTransitional,
          )
          out_labels.push(mapped)
        }
        None => out_labels.push(lower)
      }
    } else {
      // 非 punycode：返回小写（可选映射以提升显示一致性）
      let (mapped_plain, _) = tr46_map_and_nfkc(
        lower,
        IDNAProfile::Uts46NonTransitional,
      )
      out_labels.push(mapped_plain)
    }
  }
  out_labels.join(".")
}

///| 将 U+3002、U+FF0E、U+FF61 映射为 '.'，以便统一分割
fn map_alt_dots(s : String) -> String {
  let mut out = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = Int::unsafe_to_char(s[i])
    let code = Char::to_int(c)
    if code == 0x3002 || code == 0xFF0E || code == 0xFF61 {
      out = out + "."
    } else {
      out = out + c.to_string()
    }
  }
  out
}

///| UTS-46 字符映射（增强的最小实现）：
/// - 非过渡：保留 ß (U+00DF)
/// - 过渡：ß -> ss
/// - 删除 ZWJ/ZWNJ（ContextJ：在严格模式下将导致校验失败）
/// - 将 U+FF01..U+FF5E 全角 ASCII 映射到半角 ASCII（宽度映射）
/// 返回：(mapped, had_contextj)
fn uts46_map(input : String, profile : IDNAProfile) -> (String, Bool) {
  let mut out = ""
  let mut had_contextj = false
  for i = 0; i < input.length(); i = i + 1 {
    let c = Int::unsafe_to_char(input[i])
    let code = Char::to_int(c)
    // 处理 ZWJ/ZWNJ（ContextJ）
    if code == 0x200D || code == 0x200C {
      had_contextj = true
      continue
    }
    // ß (U+00DF)
    if code == 0x00DF {
      match profile {
        IDNAProfile::Uts46Transitional => out = out + "ss"
        _ => out = out + Int::unsafe_to_char(0x00DF).to_string()
      }
      continue
    }
    // 全角 ASCII 映射：U+FF01..U+FF5E -> U+0021..U+007E
    if code >= 0xFF01 && code <= 0xFF5E {
      let mapped = code - 0xFEE0
      out = out + Int::unsafe_to_char(mapped).to_string()
      continue
    }
    // 默认复制
    out = out + c.to_string()
  }
  (out, had_contextj)
}

///| TR46 映射 + NFKC（增强子集）：
/// - 复用 uts46_map 的宽度映射、ß 处理、去除 ZWJ/ZWNJ（记录 had_contextj）
/// - 追加常见兼容字符归一：拉丁合字 U+FB00..U+FB06；全角已由上游处理
/// - 追加占位 NFKC：当前未实现完整 Unicode 数据表，仅覆盖常见场景
fn tr46_map_and_nfkc(input : String, profile : IDNAProfile) -> (String, Bool) {
  let (rough, had_ctxj) = uts46_map(input, profile)
  let after_nfkc = nfkc_lite(rough)
  (after_nfkc, had_ctxj)
}

///| 简化 NFKC：处理少量常见兼容等价字符（不完整）
fn nfkc_lite(input : String) -> String {
  let mut out = ""
  let mut i = 0
  while i < input.length() {
    let cp = Char::to_int(Int::unsafe_to_char(input[i]))
    // 拉丁合字 LIGATURES PRESENTATION FORMS
    if cp == 0xFB00 {
      out = out + "ff"
    } else if cp == 0xFB01 {
      out = out + "fi"
    } else if cp == 0xFB02 {
      out = out + "fl"
    } else if cp == 0xFB03 {
      out = out + "ffi"
    } else if cp == 0xFB04 {
      out = out + "ffl"
    } else if cp == 0xFB05 {
      out = out + "st"
    } else if cp == 0xFB06 {
      out = out + "st"
    } else {
      out = out + Int::unsafe_to_char(cp).to_string()
    }
    i = i + 1
  }
  out
}

///| 标签校验（保守实现）：长度/连字符；严格模式下附加 STD3、连字符 3-4、Bidi 与 ContextJ 检查
fn is_valid_uts46_label(
  label : String,
  profile : IDNAProfile,
  had_contextj : Bool,
) -> Bool {
  // 长度限制：1..63（不计算 xn-- 前缀，这里在编码前检查原 label）
  if label.length() == 0 || label.length() > 63 {
    return false
  }
  if label.has_prefix("-") || label.has_suffix("-") {
    return false
  }

  // 严格模式：禁止第 3、4 位为 "--"（U-label 阶段）
  match profile {
    IDNAProfile::IDNA2008Strict =>
      if label.length() >= 4 {
        let c2 = Int::unsafe_to_char(label[2])
        let c3 = Int::unsafe_to_char(label[3])
        if c2 == '-' && c3 == '-' {
          return false
        }
      }
    _ => ()
  }

  // 严格模式：STD3 ASCII 规则（仅当标签为 ASCII）
  if !contains_non_ascii(label) {
    match profile {
      IDNAProfile::IDNA2008Strict =>
        if !is_ascii_std3_compatible_label(label) {
          return false
        }
      _ => ()
    }
  }

  // 严格模式：ContextJ（若出现 ZWJ/ZWNJ，拒绝；完整上下文规则尚未实现）
  match profile {
    IDNAProfile::IDNA2008Strict => if had_contextj { return false }
    _ => ()
  }

  // 严格模式：基础 Bidi 子集检查（含 RTL 时禁止混合 L；且末尾为 RTL 范围）
  match profile {
    IDNAProfile::IDNA2008Strict =>
      if contains_rtl_codepoint(label) {
        if contains_ascii_ltr_letter(label) {
          return false
        }
        if !ends_with_rtl_codepoint(label) {
          return false
        }
      }
    _ => ()
  }
  true
}

///| 标签校验（返回错误类型）。严格模式建议使用本函数。
fn validate_uts46_label(
  label : String,
  profile : IDNAProfile,
  had_contextj : Bool,
) -> Bool {
  // 长度限制：1..63
  if label.length() == 0 || label.length() > 63 {
    return false
  }
  if label.has_prefix("-") || label.has_suffix("-") {
    return false
  }
  match profile {
    IDNAProfile::IDNA2008Strict =>
      if label.length() >= 4 {
        let c2 = Int::unsafe_to_char(label[2])
        let c3 = Int::unsafe_to_char(label[3])
        if c2 == '-' && c3 == '-' {
          return false
        }
      }
    _ => ()
  }
  if !contains_non_ascii(label) {
    match profile {
      IDNAProfile::IDNA2008Strict =>
        if !is_ascii_std3_compatible_label(label) {
          return false
        }
      _ => ()
    }
  }
  match profile {
    IDNAProfile::IDNA2008Strict => {
      if had_contextj {
        return false
      }
      if !check_contexto_ok(label) {
        return false
      }
      if contains_rtl_codepoint(label) {
        if contains_ascii_ltr_letter(label) {
          return false
        }
        if !ends_with_rtl_codepoint(label) {
          return false
        }
      }
    }
    _ => ()
  }
  true
}

///| ContextO 简化检查：
/// - U+00B7 仅允许出现在 "l·l" 中
/// - U+0375 仅允许其后跟希腊字母
/// - U+30FB 仅允许标签含有日文假名（Hiragana/Katakana）
/// - 禁止混用阿拉伯-印度数字与扩展阿拉伯-印度数字
fn check_contexto_ok(label : String) -> Bool {
  let mut has_arabic_indic = false
  let mut has_ext_arabic_indic = false
  let mut i = 0
  while i < label.length() {
    let codepoint = label[i]
    if codepoint >= 0xD800 && codepoint <= 0xDBFF {
      // 高代理项：需要与下一个低代理项组合
      if i + 1 < label.length() {
        let low_surrogate = label[i + 1]
        if low_surrogate >= 0xDC00 && low_surrogate <= 0xDFFF {
          // 计算完整的Unicode码点
          let full_codepoint = 0x10000 +
            ((codepoint - 0xD800) << 10) +
            (low_surrogate - 0xDC00)
          if full_codepoint == 0x00B7 { // MIDDLE DOT
            let prev_ok = if i > 0 {
              let prev_codepoint = label[i - 1]
              if prev_codepoint >= 0xD800 && prev_codepoint <= 0xDBFF {
                if i > 1 {
                  let prev_low = label[i - 2]
                  if prev_low >= 0xDC00 && prev_low <= 0xDFFF {
                    let prev_full = 0x10000 +
                      ((prev_codepoint - 0xD800) << 10) +
                      (prev_low - 0xDC00)
                    prev_full == 0x006C // 'l'
                  } else {
                    false
                  }
                } else {
                  false
                }
              } else {
                prev_codepoint == 0x006C // 'l'
              }
            } else {
              false
            }
            let next_ok = if i + 2 < label.length() {
              let next_codepoint = label[i + 2]
              if next_codepoint >= 0xD800 && next_codepoint <= 0xDBFF {
                if i + 3 < label.length() {
                  let next_low = label[i + 3]
                  if next_low >= 0xDC00 && next_low <= 0xDFFF {
                    let next_full = 0x10000 +
                      ((next_codepoint - 0xD800) << 10) +
                      (next_low - 0xDC00)
                    next_full == 0x006C // 'l'
                  } else {
                    false
                  }
                } else {
                  false
                }
              } else {
                next_codepoint == 0x006C // 'l'
              }
            } else {
              false
            }
            if !(prev_ok && next_ok) {
              return false
            }
          }
          if full_codepoint == 0x0375 { // GREEK LOWER NUMERAL SIGN (KERAIA)
            let next_is_greek = if i + 2 < label.length() {
              let next_codepoint = label[i + 2]
              if next_codepoint >= 0xD800 && next_codepoint <= 0xDBFF {
                if i + 3 < label.length() {
                  let next_low = label[i + 3]
                  if next_low >= 0xDC00 && next_low <= 0xDFFF {
                    let next_full = 0x10000 +
                      ((next_codepoint - 0xD800) << 10) +
                      (next_low - 0xDC00)
                    is_greek_letter(next_full)
                  } else {
                    false
                  }
                } else {
                  false
                }
              } else {
                is_greek_letter(next_codepoint)
              }
            } else {
              false
            }
            if !next_is_greek {
              return false
            }
          }
          if full_codepoint == 0x30FB { // KATAKANA MIDDLE DOT
            if !contains_kana(label) {
              return false
            }
          }
          if full_codepoint >= 0x0660 && full_codepoint <= 0x0669 {
            has_arabic_indic = true
          }
          if full_codepoint >= 0x06F0 && full_codepoint <= 0x06F9 {
            has_ext_arabic_indic = true
          }
          i = i + 2
        } else {
          i = i + 1
        }
      } else {
        i = i + 1
      }
    } else if codepoint >= 0xDC00 && codepoint <= 0xDFFF {
      // 孤立的低代理项
      i = i + 1
    } else {
      // 其他字符直接检查
      if codepoint == 0x00B7 { // MIDDLE DOT
        let prev_ok = if i > 0 {
          label[i - 1] == 0x006C // 'l'
        } else {
          false
        }
        let next_ok = if i + 1 < label.length() {
          label[i + 1] == 0x006C // 'l'
        } else {
          false
        }
        if !(prev_ok && next_ok) {
          return false
        }
      }
      if codepoint == 0x0375 { // GREEK LOWER NUMERAL SIGN (KERAIA)
        let next_is_greek = if i + 1 < label.length() {
          is_greek_letter(label[i + 1])
        } else {
          false
        }
        if !next_is_greek {
          return false
        }
      }
      if codepoint == 0x30FB { // KATAKANA MIDDLE DOT
        if !contains_kana(label) {
          return false
        }
      }
      if codepoint >= 0x0660 && codepoint <= 0x0669 {
        has_arabic_indic = true
      }
      if codepoint >= 0x06F0 && codepoint <= 0x06F9 {
        has_ext_arabic_indic = true
      }
      i = i + 1
    }
  }
  if has_arabic_indic && has_ext_arabic_indic {
    return false
  }
  true
}

///|
fn is_greek_letter(cp : Int) -> Bool {
  cp >= 0x0370 && cp <= 0x03FF
}

///|
fn contains_kana(s : String) -> Bool {
  let mut i = 0
  while i < s.length() {
    let codepoint = s[i]
    if codepoint >= 0xD800 && codepoint <= 0xDBFF {
      // 高代理项：需要与下一个低代理项组合
      if i + 1 < s.length() {
        let low_surrogate = s[i + 1]
        if low_surrogate >= 0xDC00 && low_surrogate <= 0xDFFF {
          // 计算完整的Unicode码点
          let full_codepoint = 0x10000 +
            ((codepoint - 0xD800) << 10) +
            (low_surrogate - 0xDC00)
          if (full_codepoint >= 0x3040 && full_codepoint <= 0x309F) ||
            (full_codepoint >= 0x30A0 && full_codepoint <= 0x30FF) {
            return true
          }
          i = i + 2
        } else {
          i = i + 1
        }
      } else {
        i = i + 1
      }
    } else if codepoint >= 0xDC00 && codepoint <= 0xDFFF {
      // 孤立的低代理项
      i = i + 1
    } else {
      // 其他字符直接检查
      if (codepoint >= 0x3040 && codepoint <= 0x309F) ||
        (codepoint >= 0x30A0 && codepoint <= 0x30FF) {
        return true
      }
      i = i + 1
    }
  }
  false
}

///|
fn is_ascii_std3_compatible_label(label : String) -> Bool {
  for i = 0; i < label.length(); i = i + 1 {
    let c = Int::unsafe_to_char(label[i])
    if !(is_ascii_lower_letter(c) || is_ascii_digit(c) || c == '-') {
      return false
    }
  }
  true
}

///|
fn is_ascii_lower_letter(c : Char) -> Bool {
  let code = Char::to_int(c)
  code >= 0x61 && code <= 0x7A
}

///|
fn is_ascii_digit(c : Char) -> Bool {
  let code = Char::to_int(c)
  code >= 0x30 && code <= 0x39
}

///|
fn contains_ascii_ltr_letter(s : String) -> Bool {
  for i = 0; i < s.length(); i = i + 1 {
    let c = Int::unsafe_to_char(s[i])
    if is_ascii_lower_letter(c) {
      return true
    }
  }
  false
}

///|
fn contains_rtl_codepoint(s : String) -> Bool {
  let mut i = 0
  while i < s.length() {
    let codepoint = s[i]
    if codepoint >= 0xD800 && codepoint <= 0xDBFF {
      // 高代理项：需要与下一个低代理项组合
      if i + 1 < s.length() {
        let low_surrogate = s[i + 1]
        if low_surrogate >= 0xDC00 && low_surrogate <= 0xDFFF {
          // 计算完整的Unicode码点
          let full_codepoint = 0x10000 +
            ((codepoint - 0xD800) << 10) +
            (low_surrogate - 0xDC00)
          if is_rtl_range(full_codepoint) {
            return true
          }
          i = i + 2
        } else {
          i = i + 1
        }
      } else {
        i = i + 1
      }
    } else if codepoint >= 0xDC00 && codepoint <= 0xDFFF {
      // 孤立的低代理项
      i = i + 1
    } else {
      // 其他字符直接检查
      if is_rtl_range(codepoint) {
        return true
      }
      i = i + 1
    }
  }
  false
}

///|
fn ends_with_rtl_codepoint(s : String) -> Bool {
  if s.length() == 0 {
    return false
  }
  let i = s.length() - 1
  let codepoint = s[i]
  if codepoint >= 0xDC00 && codepoint <= 0xDFFF {
    // 低代理项：需要与前一个高代理项组合
    if i > 0 {
      let high_surrogate = s[i - 1]
      if high_surrogate >= 0xD800 && high_surrogate <= 0xDBFF {
        // 计算完整的Unicode码点
        let full_codepoint = 0x10000 +
          ((high_surrogate - 0xD800) << 10) +
          (codepoint - 0xDC00)
        return is_rtl_range(full_codepoint)
      }
    }
    // 孤立的低代理项
    return false
  } else if codepoint >= 0xD800 && codepoint <= 0xDBFF {
    // 孤立的低代理项
    return false
  } else {
    // 其他字符直接检查
    return is_rtl_range(codepoint)
  }
}

///|
fn is_rtl_range(cp : Int) -> Bool {
  // 近似的 RTL 范围集合（Hebrew, Arabic, Syriac, Thaana, NKo, Samaritan, Mandaic, Arabic Ext-A）
  cp >= 0x0590 && cp <= 0x08FF
}

///| 完整 Punycode 编码实现（RFC 3492），针对单个 label
fn punycode_encode_strict(label : String) -> String? {
  // 将字符串拆为码点数组
  let codepoints = to_codepoints(label)
  // 基础参数
  let base = 36
  let t_min = 1
  let t_max = 26
  let initial_bias = 72
  let initial_n = 128

  // 输出缓冲
  let mut output = ""
  // 基本码点（< 0x80）直接复制
  let mut basic_count = 0
  for cp in codepoints {
    if cp < 0x80 {
      output = output + Int::unsafe_to_char(cp).to_string()
      basic_count = basic_count + 1
    }
  }
  let handled_basic = basic_count
  if handled_basic > 0 && handled_basic < codepoints.length() {
    output = output + "-"
  }

  // 初始化
  let mut n = initial_n
  let mut delta = 0
  let mut bias = initial_bias
  let input_len = codepoints.length()

  // 主循环
  let mut handled = handled_basic
  while handled < input_len {
    // 选取未处理的最小码点 m >= n
    let mut m = 0x10FFFF
    for cp in codepoints {
      if cp >= n && cp < m {
        m = cp
      }
    }
    if m < n {
      return None
    }
    let increment = m - n
    if increment > (0x7FFFFFFF - delta) / (handled + 1) {
      return None
    }
    delta = delta + increment * (handled + 1)
    n = m
    for cp in codepoints {
      if cp < n {
        delta = delta + 1
        if delta == 0 {
          return None
        }
      }
      if cp == n {
        // 编码 delta
        let mut q = delta
        let mut k = base
        while true {
          let t = if k <= bias {
            t_min
          } else if k >= bias + t_max {
            t_max
          } else {
            k - bias
          }
          if q < t {
            break
          }
          let code = t + (q - t) % (base - t)
          output = output + encode_digit(code)
          q = (q - t) / (base - t)
          k = k + base
        }
        output = output + encode_digit(q)
        bias = adapt_bias(delta, handled + 1, handled == basic_count)
        delta = 0
        handled = handled + 1
      }
    }
    delta = delta + 1
    n = n + 1
  }
  Some(output)
}

///| 适配函数（RFC 3492）
fn adapt_bias(delta : Int, num_points : Int, first_time : Bool) -> Int {
  let base = 36
  let t_min = 1
  let t_max = 26
  let skew = 38
  let mut d = if first_time { delta / 700 } else { delta / 2 }
  let mut k = 0
  d = d + d / num_points
  while d > (base - t_min) * t_max / 2 {
    d = d / (base - t_min)
    k = k + base
  }
  k + (base - t_min + 1) * d / (d + skew)
}

///| 将 0..35 的数字映射为 ASCII 字符（0-25 -> a-z, 26-35 -> 0-9）
fn encode_digit(d : Int) -> String {
  if d < 26 {
    Int::unsafe_to_char(Char::to_int('a') + d).to_string()
  } else {
    Int::unsafe_to_char(Char::to_int('0') + (d - 26)).to_string()
  }
}

///| 将 ASCII 字符解码为 punycode 数字（0..35）
fn decode_digit_char(c : Char) -> Int? {
  let code = Char::to_int(c)
  // a-z
  if code >= 0x61 && code <= 0x7A {
    return Some(code - 0x61)
  }
  // A-Z（容忍）
  if code >= 0x41 && code <= 0x5A {
    return Some(code - 0x41)
  }
  // 0-9
  if code >= 0x30 && code <= 0x39 {
    return Some(code - 0x30 + 26)
  }
  None
}

///| 将码点数组转为字符串
fn codepoints_to_string(cps : Array[Int]) -> String {
  let mut s = ""
  for cp in cps {
    s = s + Int::unsafe_to_char(cp).to_string()
  }
  s
}

///| Punycode 解码（RFC 3492），针对单个标签（不含前缀 `xn--`）
fn punycode_decode_strict(puny : String) -> String? {
  let base = 36
  let t_min = 1
  let t_max = 26
  let initial_bias = 72
  let initial_n = 128

  // 找最后一个连字符，之前为基本码点
  let mut b = -1
  for i = 0; i < puny.length(); i = i + 1 {
    if Int::unsafe_to_char(puny[i]) == '-' {
      b = i
    }
  }
  let output : Array[Int] = []
  if b != -1 {
    for i = 0; i < b; i = i + 1 {
      output.push(puny[i])
    }
  }
  let mut i = 0
  let mut n = initial_n
  let mut bias = initial_bias
  let mut idx = if b == -1 { 0 } else { b + 1 }
  while idx < puny.length() {
    let oldi = i
    let mut w = 1
    let mut k = base
    while true {
      if idx >= puny.length() {
        return None
      }
      let ch = Int::unsafe_to_char(puny[idx])
      idx = idx + 1
      match decode_digit_char(ch) {
        Some(digit) => {
          // i += digit * w （检查溢出）
          if digit > 0 && w > 0x7FFFFFFF / digit {
            return None
          }
          let add = digit * w
          if i > 0x7FFFFFFF - add {
            return None
          }
          i = i + add
          let t = if k <= bias {
            t_min
          } else if k >= bias + t_max {
            t_max
          } else {
            k - bias
          }
          if digit < t {
            break
          } else {
            if w > 0x7FFFFFFF / (base - t) {
              return None
            }
            w = w * (base - t)
            k = k + base
          }
        }
        None => return None
      }
    }
    let out_len = output.length() + 1
    bias = adapt_bias(i - oldi, out_len, oldi == 0)
    let q = i / out_len
    let r = i % out_len
    // n += q
    if n > 0x10FFFF - q {
      return None
    }
    n = n + q
    // 在位置 r 插入 n
    if r < 0 || r > output.length() {
      return None
    }
    let new_output : Array[Int] = []
    for p = 0; p < r; p = p + 1 {
      new_output.push(output[p])
    }
    new_output.push(n)
    for p = r; p < output.length(); p = p + 1 {
      new_output.push(output[p])
    }
    // 交换回 output（清空并逐个推入）
    while output.length() > 0 {
      let _discarded = output.pop()

    }
    for v in new_output {
      output.push(v)
    }
    i = r + 1
  }
  Some(codepoints_to_string(output))
}

///| 将字符串转为 Unicode 码点数组（正确处理UTF-16代理项对）
fn to_codepoints(s : String) -> Array[Int] {
  let cps : Array[Int] = []
  let mut i = 0
  while i < s.length() {
    let codepoint = s[i]
    if codepoint >= 0xD800 && codepoint <= 0xDBFF {
      // 高代理项：需要与下一个低代理项组合
      if i + 1 < s.length() {
        let low_surrogate = s[i + 1]
        if low_surrogate >= 0xDC00 && low_surrogate <= 0xDFFF {
          // 计算完整的Unicode码点
          let full_codepoint = 0x10000 +
            ((codepoint - 0xD800) << 10) +
            (low_surrogate - 0xDC00)
          cps.push(full_codepoint)
          i = i + 2
        } else {
          // 无效的低代理项，使用替换字符
          cps.push(0xFFFD)
          i = i + 1
        }
      } else {
        // 不完整的代理项对，使用替换字符
        cps.push(0xFFFD)
        i = i + 1
      }
    } else if codepoint >= 0xDC00 && codepoint <= 0xDFFF {
      // 孤立的低代理项，使用替换字符
      cps.push(0xFFFD)
      i = i + 1
    } else {
      // 其他字符直接添加
      cps.push(codepoint)
      i = i + 1
    }
  }
  cps
}

///| 检查字符串是否包含非 ASCII 字符（正确处理UTF-16代理项对）
fn contains_non_ascii(s : String) -> Bool {
  let mut i = 0
  while i < s.length() {
    let codepoint = s[i]
    if codepoint >= 0xD800 && codepoint <= 0xDBFF {
      // 高代理项：需要与下一个低代理项组合
      if i + 1 < s.length() {
        let low_surrogate = s[i + 1]
        if low_surrogate >= 0xDC00 && low_surrogate <= 0xDFFF {
          // 计算完整的Unicode码点
          let full_codepoint = 0x10000 +
            ((codepoint - 0xD800) << 10) +
            (low_surrogate - 0xDC00)
          if full_codepoint > 127 {
            return true
          }
          i = i + 2
        } else {
          // 无效的低代理项，使用替换字符
          return true
        }
      } else {
        // 不完整的代理项对，使用替换字符
        return true
      }
    } else if codepoint >= 0xDC00 && codepoint <= 0xDFFF {
      // 孤立的低代理项，使用替换字符
      return true
    } else {
      // 其他字符直接检查
      if codepoint > 127 {
        return true
      }
      i = i + 1
    }
  }
  false
}

///| 百分号编码规范化：将 %hh/%hH/%Hh 统一为大写；可选地解码 unreserved 的 %HH
fn normalize_percent_encoding_in_string(
  input : String,
  decode_unreserved : Bool,
) -> String {
  let mut out = ""
  let mut i = 0
  while i < input.length() {
    if i + 2 <= input.length() - 1 && input[i] == Char::to_int('%') {
      let h1 = Int::unsafe_to_char(input[i + 1])
      let h2 = Int::unsafe_to_char(input[i + 2])
      match (hex_char_to_int(h1), hex_char_to_int(h2)) {
        (Some(v1), Some(v2)) => {
          let byte = v1 * 16 + v2
          // 解码 unreserved
          if decode_unreserved && is_unreserved_byte(byte) {
            out = out + Int::unsafe_to_char(byte).to_string()
          } else {
            out = out + "%" + byte_to_hex(byte)
          }
          i = i + 3
        }
        _ => {
          // 非法的百分号序列，原样输出当前字符
          out = out + "%"
          i = i + 1
        }
      }
    } else {
      out = out + Int::unsafe_to_char(input[i]).to_string()
      i = i + 1
    }
  }
  out
}

// 移除本地 is_unreserved_byte，统一使用 percent_encoding.mbt 中的公开实现

///| 规范化 IPv6 字面量（基于 RFC 5952）：
/// - 小写十六进制
/// - 去掉每段的前导零
/// - 压缩最长的连续零段为 ::（仅一次，选择最左）
fn normalize_ipv6_literal(host_with_brackets : String) -> String {
  // 输入形如 "[2001:0DB8:0000:0000:0000:ff00:0042:8329]" 或带 zone-id
  if !has_prefix(host_with_brackets, "[") {
    return host_with_brackets
  }
  match find_char(host_with_brackets, ']') {
    Some(end_idx) => {
      let inside = host_with_brackets.substring(start=1, end=end_idx)
      // 保留可能的 zone-id（%25...）
      let mut core = inside
      let mut zone = ""
      if inside.contains("%") {
        match find_substring(inside, "%25") {
          Some(idx) => {
            core = inside.substring(start=0, end=idx)
            zone = inside.substring(start=idx) // 包含 %25...
          }
          None => return host_with_brackets
        }
      }

      // 解析 core 为段，统一小写、去前导零
      let segments = split_ipv6_segments(core)
      let cleaned : Array[String] = []
      for seg in segments {
        if seg.length() == 0 {
          cleaned.push("")
        } else {
          let mut j = 0
          while j < seg.length() && Int::unsafe_to_char(seg[j]) == '0' {
            j = j + 1
          }
          let trimmed = if j == seg.length() {
            "0"
          } else {
            seg.substring(start=j)
          }
          cleaned.push(to_lowercase(trimmed))
        }
      }
      // 找到最长的连续 "0" 段序列用于 :: 压缩
      let (start_idx, length) = find_longest_zero_run(cleaned)
      let mut out = ""
      if length >= 2 {
        // 拼接 start 之前
        for i = 0; i < start_idx; i = i + 1 {
          if i > 0 {
            out = out + ":"
          }
          out = out + cleaned[i]
        }
        out = if out.length() > 0 { out + "::" } else { "::" }
        // 跳过零段
        let after = start_idx + length
        let mut first = true
        for i = after; i < cleaned.length(); i = i + 1 {
          if !first {
            out = out + ":"
          } else {
            first = false
          }
          out = out + cleaned[i]
        }
        // 特殊：全零地址 -> ::
        if out.length() == 0 {
          out = "::"
        }
      } else {
        // 无需压缩
        for i = 0; i < cleaned.length(); i = i + 1 {
          if i > 0 {
            out = out + ":"
          }
          out = out + cleaned[i]
        }
      }
      "[" + out + zone + "]"
    }
    None => host_with_brackets
  }
}

///| 找到最长的连续零段
fn find_longest_zero_run(segments : Array[String]) -> (Int, Int) {
  let mut best_start = -1
  let mut best_len = 0
  let mut i = 0
  while i < segments.length() {
    if segments[i] == "0" || segments[i].length() == 0 {
      let mut j = i
      while j < segments.length() &&
            (segments[j] == "0" || segments[j].length() == 0) {
        j = j + 1
      }
      let len = j - i
      if len > best_len {
        best_len = len
        best_start = i
      }
      i = j
    } else {
      i = i + 1
    }
  }
  if best_len < 2 {
    (0, 0)
  } else {
    (best_start, best_len)
  }
}

// 已移除未使用的 punycode_encode_label（由 punycode_encode_strict 取代）

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
    Some(p) =>
      match get_default_port(scheme) {
        Some(default_port) => if p == default_port { None } else { Some(p) }
        None => Some(p)
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

  // 验证字符是否为有效的userinfo字符
  // RFC 3986: userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
  for i = 0; i < userinfo.length(); i = i + 1 {
    let c = Int::unsafe_to_char(userinfo[i])
    if not(
        is_unreserved_char(c) || is_sub_delim_char(c) || c == ':' || c == '%',
      ) {
      return false
    }
  }
  // 如果包含 '%', 验证其为合法 pct-encoded 序列，且整体为合法 UTF-8
  if userinfo.contains("%") {
    match validate_and_decode_percent_encoded(userinfo) {
      Ok(_) => ()
      Err(_) => return false
    }
  }
  true
}

///| 验证IPv6地址格式（RFC 3986兼容实现）
fn is_valid_ipv6(ipv6 : String) -> Bool {
  if ipv6.length() == 0 {
    return false
  }

  // 允许 RFC 6874 zone-id：形如 "%25zone"，仅校验百分号序列并在校验时忽略zone部分
  let mut core = ipv6
  if ipv6.contains("%") {
    match find_substring(ipv6, "%25") {
      Some(idx) =>
        // zone-id 可以为空或包含更多 pct-encoded/未编码的合法标识字符，这里仅对核心地址做校验
        core = ipv6.substring(start=0, end=idx)
      None => return false // 存在%但不是%25则非法
    }
  }

  // 检查基本格式：不能以单个冒号开头或结尾（除非是::）
  if core.has_prefix(":") && not(core.has_prefix("::")) {
    return false
  }
  if core.has_suffix(":") && not(core.has_suffix("::")) {
    return false
  }

  // 检查是否包含IPv4映射格式 (::ffff:192.0.2.1)
  if core.contains("::ffff:") || core.contains("::FFFF:") {
    return validate_ipv4_mapped_ipv6(core)
  }

  // 分割成段
  let segments = split_ipv6_segments(core)
  let mut double_colon_count = 0
  let mut empty_segments = 0

  // 计算双冒号数量
  for i = 0; i < core.length() - 1; i = i + 1 {
    if Int::unsafe_to_char(core[i]) == ':' &&
      Int::unsafe_to_char(core[i + 1]) == ':' {
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
    } else if not(is_valid_ipv6_segment(segment)) {
      return false
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
