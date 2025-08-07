/// 极简版 URI 构造器

pub struct UriBuilder {
  scheme : String?
  userinfo : String?
  host : String?
  port : Int?
  path : String
  query_params : Array[(String, String)]
  fragment : String?
}

pub fn UriBuilder::new() -> UriBuilder {
  {
    scheme: None,
    userinfo: None,
    host: None,
    port: None,
    path: "",
    query_params: [],
    fragment: None
  }
}

pub fn UriBuilder::scheme(self : UriBuilder, scheme : String) -> UriBuilder {
  { ..self, scheme: Some(scheme) }
}

pub fn UriBuilder::host(self : UriBuilder, host : String) -> UriBuilder {
  { ..self, host: Some(host) }
}

pub fn UriBuilder::port(self : UriBuilder, port : Int) -> UriBuilder {
  { ..self, port: Some(port) }
}

pub fn UriBuilder::userinfo(self : UriBuilder, userinfo : String) -> UriBuilder {
  { ..self, userinfo: Some(userinfo) }
}

pub fn UriBuilder::path(self : UriBuilder, path : String) -> UriBuilder {
  { ..self, path: path }
}

pub fn UriBuilder::query_param(self : UriBuilder, key : String, value : String) -> UriBuilder {
  self.query_params.push((key, value))
  self
}

pub fn UriBuilder::fragment(self : UriBuilder, fragment : String) -> UriBuilder {
  { ..self, fragment: Some(fragment) }
}

pub fn UriBuilder::build(self : UriBuilder) -> Result[Uri, UriError] {
  let scheme = match self.scheme {
    Some(s) => s
    None => return Err(UriError::InvalidScheme("Scheme is required"))
  }
  
  let authority = match self.host {
    Some(host) => Some({
      userinfo: self.userinfo,
      host: host,
      port: self.port
    })
    None => None
  }
  
  let query = if self.query_params.length() > 0 {
    let parts = []
    // 使用索引遍历避免解构问题
    for i = 0; i < self.query_params.length(); i = i + 1 {
      let (key, value) = self.query_params[i]
      if value.is_empty() {
        parts.push(key)
      } else {
        parts.push(key + "=" + value)
      }
    }
    Some(parts.join("&"))
  } else {
    None
  }
  
  Ok({
    scheme: scheme,
    authority: authority,
    path: self.path,
    query: query,
    fragment: self.fragment
  })
}

pub fn UriBuilder::from_uri(uri : Uri) -> UriBuilder {
  let mut builder = UriBuilder::new().scheme(uri.scheme)
  
  match uri.authority {
    Some(auth) => {
      builder = builder.host(auth.host)
      
      match auth.userinfo {
        Some(userinfo) => builder = builder.userinfo(userinfo)
        None => ignore(())
      }
      
      match auth.port {
        Some(port) => builder = builder.port(port)
        None => ignore(())
      }
    }
    None => ignore(())
  }
  
  if uri.path.length() > 0 {
    builder = builder.path(uri.path)
  }
  
  match uri.query {
    Some(query) => {
      builder = builder.query_param("_raw", query)
    }
    None => ignore(())
  }
  
  match uri.fragment {
    Some(fragment) => builder = builder.fragment(fragment)
    None => ignore(())
  }
  
  builder
}

pub fn http_url(host : String, path : String) -> UriBuilder {
  UriBuilder::new()
    .scheme("http")
    .host(host)
    .path(path)
}

pub fn https_url(host : String, path : String) -> UriBuilder {
  UriBuilder::new()
    .scheme("https")
    .host(host)
    .path(path)
}