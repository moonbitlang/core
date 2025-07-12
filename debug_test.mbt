test "emoji debug" { inspect(try? @json.parse("\u{1F600}"), content="debug") }
