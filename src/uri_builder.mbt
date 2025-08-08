/// 高级 URI 构造器

///| 查询参数编码方式
pub enum QueryEncoding {
  Percent
}

///| 构建器配置选项
pub struct BuilderOptions {
  query_encoding : QueryEncoding
  normalize_path : Bool
  validate : Bool
  remove_default_ports : Bool
}

///|
pub struct UriBuilder {
  scheme : String?
  userinfo : String?
  host : String?
  port : Int?
  path_segments : Array[String]
  query_params : Array[(String, String)]
  fragment : String?
  options : BuilderOptions
}

///| 默认构建器选项
pub fn default_builder_options() -> BuilderOptions {
  {
    query_encoding: QueryEncoding::Percent,
    normalize_path: true,
    validate: true,
    remove_default_ports: true,
  }
}

///| 创建新的URI构建器
pub fn UriBuilder::new() -> UriBuilder {
  {
    scheme: None,
    userinfo: None,
    host: None,
    port: None,
    path_segments: [],
    query_params: [],
    fragment: None,
    options: default_builder_options(),
  }
}

///| 使用自定义选项创建URI构建器
pub fn UriBuilder::with_options(options : BuilderOptions) -> UriBuilder {
  {
    scheme: None,
    userinfo: None,
    host: None,
    port: None,
    path_segments: [],
    query_params: [],
    fragment: None,
    options,
  }
}

///| 设置URI方案
pub fn UriBuilder::scheme(self : UriBuilder, scheme : String) -> UriBuilder {
  { ..self, scheme: Some(scheme) }
}

///| 设置主机名
pub fn UriBuilder::host(self : UriBuilder, host : String) -> UriBuilder {
  { ..self, host: Some(host) }
}

///| 设置端口号
pub fn UriBuilder::port(self : UriBuilder, port : Int) -> UriBuilder {
  { ..self, port: Some(port) }
}

///| 设置用户信息
pub fn UriBuilder::userinfo(self : UriBuilder, userinfo : String) -> UriBuilder {
  { ..self, userinfo: Some(userinfo) }
}

///| 设置用户名和密码
pub fn UriBuilder::credentials(
  self : UriBuilder,
  username : String,
  password : String,
) -> UriBuilder {
  let userinfo = username + ":" + password
  { ..self, userinfo: Some(userinfo) }
}

///| 设置片段
pub fn UriBuilder::fragment(self : UriBuilder, fragment : String) -> UriBuilder {
  { ..self, fragment: Some(fragment) }
}

///| 设置完整路径
pub fn UriBuilder::path(self : UriBuilder, path : String) -> UriBuilder {
  let segments = parse_path_segments(path)
  { ..self, path_segments: segments }
}

///| 添加路径段
pub fn UriBuilder::path_segment(
  self : UriBuilder,
  segment : String,
) -> UriBuilder {
  self.path_segments.push(segment)
  self
}

///| 添加多个路径段
pub fn UriBuilder::path_segments(
  self : UriBuilder,
  segments : Array[String],
) -> UriBuilder {
  for segment in segments {
    self.path_segments.push(segment)
  }
  self
}

///| 清除所有路径段
pub fn UriBuilder::clear_path(self : UriBuilder) -> UriBuilder {
  { ..self, path_segments: [] }
}

///| 添加查询参数
pub fn UriBuilder::query_param(
  self : UriBuilder,
  key : String,
  value : String,
) -> UriBuilder {
  self.query_params.push((key, value))
  self
}

///| 添加布尔查询参数（仅当值为true时）
pub fn UriBuilder::query_param_bool(self : UriBuilder, key : String, value : Bool) -> UriBuilder {
  if value {
    self.query_params.push((key, "true"))
  }
  self
}

///| 添加多个查询参数
pub fn UriBuilder::query_params(
  self : UriBuilder,
  params : Array[(String, String)],
) -> UriBuilder {
  for param in params {
    self.query_params.push(param)
  }
  self
}

///| 添加查询参数（仅当值不为空时）
pub fn UriBuilder::query_param_if_not_empty(
  self : UriBuilder,
  key : String,
  value : String,
) -> UriBuilder {
  if value.length() > 0 {
    self.query_params.push((key, value))
  }
  self
}





///| 移除指定的查询参数
pub fn UriBuilder::remove_query_param(self : UriBuilder, key : String) -> UriBuilder {
  let filtered_params = []
  for param in self.query_params {
    if param.0 != key {
      filtered_params.push(param)
    }
  }
  { ..self, query_params: filtered_params }
}

///| 清除所有查询参数
pub fn UriBuilder::clear_query_params(self : UriBuilder) -> UriBuilder {
  { ..self, query_params: [] }
}



///| 构建URI
pub fn UriBuilder::build(self : UriBuilder) -> Result[Uri, UriError] {
  let scheme = match self.scheme {
    Some(s) => {
      if s.length() == 0 {
        return Err(InvalidScheme("Scheme cannot be empty"))
      }
      s
    }
    None => return Err(InvalidScheme("Scheme is required"))
  }

  // 构建Authority
  let authority = match self.host {
    Some(host) => Some({ userinfo: self.userinfo, host, port: self.port })
    None => None
  }

  // 构建路径
  let path = build_path_unified(
    self.path_segments,
    scheme,
    authority is Some(_),
  )

  // 构建查询字符串
  let query = if self.query_params.length() > 0 {
    Some(build_query_string(self.query_params))
  } else {
    None
  }
  let uri = { scheme, authority, path, query, fragment: self.fragment }
  Ok(uri)
}

///| 构建URI并返回字符串
pub fn UriBuilder::build_string(self : UriBuilder) -> Result[String, UriError] {
  match self.build() {
    Ok(uri) => Ok(uri.to_string())
    Err(e) => Err(e)
  }
}





///| 克隆构建器
pub fn UriBuilder::clone(self : UriBuilder) -> UriBuilder {
  {
    scheme: self.scheme,
    host: self.host,
    port: self.port,
    userinfo: self.userinfo,
    path_segments: self.path_segments.copy(),
    query_params: self.query_params.copy(),
    fragment: self.fragment,
    options: self.options,
  }
}

///| 从现有URI创建构建器
pub fn UriBuilder::from_uri(uri : Uri) -> UriBuilder {
  let mut builder = UriBuilder::new().scheme(uri.scheme)
  match uri.authority {
    Some(auth) => {
      builder = builder.host(auth.host)
      match auth.userinfo {
        Some(userinfo) => builder = builder.userinfo(userinfo)
        None => ()
      }
      match auth.port {
        Some(port) => builder = builder.port(port)
        None => ()
      }
    }
    None => ()
  }
  if uri.path.length() > 0 {
    builder = builder.path(uri.path)
  }
  match uri.query {
    Some(query) => {
      let params = parse_query_string(query)
      builder = builder.query_params(params)
    }
    None => ()
  }
  match uri.fragment {
    Some(fragment) => builder = builder.fragment(fragment)
    None => ()
  }
  builder
}

///| 从URI字符串创建构建器
pub fn UriBuilder::from_string(
  uri_str : String,
) -> Result[UriBuilder, UriError] {
  match Uri::parse(uri_str) {
    Ok(uri) => Ok(UriBuilder::from_uri(uri))
    Err(e) => Err(e)
  }
}

///| 通用URL构建器创建函数
fn create_url_builder(scheme : String, host : String?, path : String) -> UriBuilder {
  let mut builder = UriBuilder::new().scheme(scheme)
  match host {
    Some(h) => builder = builder.host(h)
    None => ()
  }
  if path.length() > 0 {
    builder = builder.path(path)
  }
  builder
}

///| 创建HTTP URL构建器
pub fn http_url(host : String, path : String) -> UriBuilder {
  create_url_builder("http", Some(host), path)
}

///| 创建HTTPS URL构建器
pub fn https_url(host : String, path : String) -> UriBuilder {
  create_url_builder("https", Some(host), path)
}



// ==================== 辅助函数 ====================

///| 解析路径段
fn parse_path_segments(path : String) -> Array[String] {
  if path.length() == 0 {
    return [""] // 使用特殊标记表示显式的空路径
  }

  // 特殊处理只有"/"的情况
  if path == "/" {
    return ["/"] // 使用特殊标记表示根路径
  }
  let segments : Array[String] = []
  let mut current = ""
  let start = if path.has_prefix("/") { 1 } else { 0 }
  for i = start; i < path.length(); i = i + 1 {
    let char_code = path[i]
    if char_code == Char::to_int('/') {
      if current.length() > 0 {
        segments.push(current)
        current = ""
      }
    } else {
      current = current + Char::to_string(Int::unsafe_to_char(char_code))
    }
  }
  if current.length() > 0 {
    segments.push(current)
  }
  segments
}

///| 统一的路径构建函数
fn build_path_unified(
  segments : Array[String],
  scheme : String,
  has_authority : Bool
) -> String {
  // 检查是否是显式的空路径
  if segments.length() == 1 && segments[0] == "" {
    return ""
  }

  // 检查是否是显式的根路径
  if segments.length() == 1 && segments[0] == "/" {
    return "/"
  }

  // 对于特殊scheme（不需要authority），路径不需要前导斜杠
  if scheme == "mailto" || scheme == "tel" || scheme == "urn" || scheme == "data" {
    if segments.length() == 0 {
      return ""
    }
    return segments.join("/")
  }

  // 对于有authority的URI，如果没有显式路径，不要添加"/"
  if segments.length() == 0 && has_authority {
    return ""
  }

  // 对于没有authority的URI，空路径保持为空
  if segments.length() == 0 && !has_authority {
    return ""
  }

  // 对于HTTP等scheme，需要前导斜杠
  if segments.length() > 0 {
    "/" + segments.join("/")
  } else {
    "/"
  }
}










