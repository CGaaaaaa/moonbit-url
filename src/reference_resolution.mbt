/// 简化的 URI 引用解析实现

///| 解析引用，将相对引用与基URI结合
pub fn resolve_reference(base : Uri, reference : Uri) -> Result[Uri, UriError] {
  // 验证基URI必须是绝对的
  if not(base.is_absolute()) {
    return Err(RelativeReferenceError("Base URI must be absolute"))
  }

  // 如果引用是绝对URI，直接返回
  if reference.is_absolute() {
    return Ok(reference)
  }

  // 简化的相对引用解析
  let resolved_path = if reference.path.has_prefix("/") {
    // 绝对路径，直接使用
    reference.path
  } else {
    // 相对路径，与基路径合并
    let base_parent = base.parent_path()
    if base_parent.is_empty() {
      "/" + reference.path
    } else if reference.path.is_empty() {
      base_parent
    } else {
      base_parent + "/" + reference.path
    }
  }

  // 规范化路径，移除点段
  let normalized_path = remove_dot_segments(resolved_path)
  Ok({
    scheme: base.scheme,
    authority: base.authority,
    path: normalized_path,
    query: reference.query,
    fragment: reference.fragment,
  })
}

///| 移除路径中的点段（RFC 3986标准实现）
pub fn remove_dot_segments(path : String) -> String {
  if path.is_empty() {
    return ""
  }
  let mut input = path
  let mut output = ""
  while input.length() > 0 {
    let mut handled = false

    // A. 如果输入以 "../" 或 "./" 开头，移除这些前缀
    if input.has_prefix("../") {
      input = input.substring(start=3)
      handled = true
    } else if input.has_prefix("./") {
      input = input.substring(start=2)
      handled = true
    }

    // B. 如果输入以 "/./" 或 "/." 开头
    if !handled && input.has_prefix("/./") {
      input = "/" + input.substring(start=3)
      handled = true
    } else if !handled && input == "/." {
      input = "/"
      handled = true
    }

    // C. 如果输入以 "/../" 开头或等于 "/.."
    if !handled && input.has_prefix("/../") {
      input = "/" + input.substring(start=4)
      output = remove_last_segment(output)
      handled = true
    } else if !handled && input == "/.." {
      input = "/"
      output = remove_last_segment(output)
      handled = true
    }

    // D. 如果输入是 "." 或 ".."，移除它们
    if !handled && (input == "." || input == "..") {
      input = ""
      handled = true
    }

    // E. 移除第一个路径段并添加到输出
    if !handled {
      if input.has_prefix("/") {
        // 查找第一个 / 后的下一个 /
        let remaining = input.substring(start=1)
        let slash_pos = remaining.find("/")
        match slash_pos {
          Some(pos) => {
            let actual_pos = pos + 1
            output = output + input.substring(start=0, end=actual_pos)
            input = input.substring(start=actual_pos)
          }
          None => {
            output = output + input
            input = ""
          }
        }
      } else {
        let slash_pos = input.find("/")
        match slash_pos {
          Some(pos) => {
            output = output + input.substring(start=0, end=pos)
            input = input.substring(start=pos)
          }
          None => {
            output = output + input
            input = ""
          }
        }
      }
    }
  }
  output
}

///| 移除输出路径中的最后一个段
fn remove_last_segment(path : String) -> String {
  if path.is_empty() {
    return ""
  }

  // 找到最后一个 / 的位置
  let mut last_slash = -1
  let len = path.length()
  let mut i = len - 1
  while i >= 0 {
    if path.get(i) == Some('/') {
      last_slash = i
      break
    }
    i = i - 1
  }
  if last_slash >= 0 {
    path.substring(start=0, end=last_slash)
  } else {
    ""
  }
}

///| URI连接工具
pub fn join_uri(base : String, reference : String) -> Result[String, UriError] {
  // 检查基URI是否包含无效模式
  if base.contains(":::") {
    return Err(ParseError("Invalid base URI format"))
  }
  match Uri::parse(base) {
    Ok(base_uri) =>
      // 检查引用是否是绝对URI
      if reference.contains("://") {
        // 如果引用是绝对URI，直接解析并返回
        match Uri::parse(reference) {
          Ok(ref_uri) => Ok(ref_uri.to_string())
          Err(e) => Err(e)
        }
      } else {
        // 检查相对引用是否包含无效模式
        if reference.contains(":::") {
          return Err(ParseError("Invalid reference format"))
        }

        // 相对引用，手动构造相对URI对象
        let relative_uri = Uri::{
          scheme: "",
          authority: None,
          path: reference,
          query: None,
          fragment: None,
        }
        match resolve_reference(base_uri, relative_uri) {
          Ok(resolved) => Ok(resolved.to_string())
          Err(e) => Err(e)
        }
      }
    Err(e) => Err(e)
  }
}

///| 检查URI是否为另一个URI的子路径
pub fn is_subpath(parent : Uri, child : Uri) -> Bool {
  // 检查scheme和authority是否相同
  if parent.scheme != child.scheme {
    return false
  }
  match (parent.authority, child.authority) {
    (Some(parent_auth), Some(child_auth)) =>
      if parent_auth.host != child_auth.host {
        return false
      }
    (None, None) => ()
    _ => return false
  }

  // 简单的路径前缀检查
  child.path.has_prefix(parent.path)
}

///| 引用解析器
pub struct ReferenceResolver {
  base : Uri
}

///|
pub fn ReferenceResolver::new(
  base : Uri,
) -> Result[ReferenceResolver, UriError] {
  if not(base.is_absolute()) {
    Err(RelativeReferenceError("Base URI must be absolute"))
  } else {
    Ok({ base, })
  }
}

///|
pub fn ReferenceResolver::resolve(
  self : ReferenceResolver,
  reference : String,
) -> Result[Uri, UriError] {
  // 特殊处理空引用（指向当前文档）
  if reference.is_empty() {
    return Ok({
      scheme: self.base.scheme,
      authority: self.base.authority,
      path: self.base.path,
      query: None,
      fragment: None,
    })
  }

  // 检查是否是绝对URI
  if reference.contains("://") {
    // 绝对URI，直接解析
    match Uri::parse(reference) {
      Ok(ref_uri) => Ok(ref_uri)
      Err(e) => Err(e)
    }
  } else {
    // 检查相对引用是否包含无效模式
    if reference.contains(":::") {
      return Err(ParseError("Invalid reference format"))
    }

    // 相对引用，手动构造相对URI对象
    let relative_uri = Uri::{
      scheme: "",
      authority: None,
      path: reference,
      query: None,
      fragment: None,
    }
    resolve_reference(self.base, relative_uri)
  }
}

///|
pub fn ReferenceResolver::resolve_batch(
  self : ReferenceResolver,
  references : Array[String],
) -> Array[Result[Uri, UriError]] {
  let results : Array[Result[Uri, UriError]] = []
  for ref_str in references {
    results.push(self.resolve(ref_str))
  }
  results
}
