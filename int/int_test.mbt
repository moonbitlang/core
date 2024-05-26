test "overflow" {
  // signed integer expected to be negative
  inspect(0xC2B2AE3D, content="-1028477379")?
  inspect(0x85EBCA77,content="-2048144777")?
}