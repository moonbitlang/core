
fn split_string(input: String, sep: String) -> Array[String]
  parts = {}  // 初始化空数组
  start = 0  // 起始位置
  sep_len = #sep  // 获取分隔符长度
  self_len = #input  // 获取字符串长度

  if sep_len == 0
    for j = 1 to self_len
      table.insert(parts, input:sub(j, j))  // 将每个字符作为单独的分段插入
    return parts  // 返回结果

  i = 0
  while i <= self_len - sep_len
    if input:sub(i + 1, i + sep_len) == sep
      if i > start
        table.insert(parts, input:sub(start + 1, i))  // 添加分段，避免空字符串
      start = i + sep_len  // 更新起始位置
      i = start
    else
      i += 1  // 继续查找

  if self_len > start
    table.insert(parts, input:sub(start + 1, self_len))  // 添加最后一个分段，避免空字符串
  return parts  // 返回结果